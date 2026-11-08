\echo == Vector projection: more hypotheses for wrong first-submission cos(theta), and relative-error buckets
WITH aqs AS (
  SELECT aq.id, q.qid FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id
  WHERE aq.assessment_id IN (2491228, 2557977, 2619944, 2713997) AND aq.deleted_at IS NULL
    AND q.qid IN ('08-Vector-Matrices-Norms/Norm-Vector-Projection-v1','08-Vector-Matrices-Norms/Norm-Vector-Projection-v2')),
firsts AS (
  SELECT DISTINCT ON (iq.id) aqs.qid, s.submitted_answer, s.partial_scores, v.params, s.true_answer
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.partial_scores ? 'angle'
  ORDER BY iq.id, s.date ASC),
vals AS (
  SELECT qid, (partial_scores->'angle'->>'score')::numeric AS sc,
    CASE WHEN submitted_answer->>'angle' ~ '^\s*-?[0-9]*\.?[0-9]+([eE]-?[0-9]+)?\s*$' THEN (submitted_answer->>'angle')::float8 END AS x,
    submitted_answer->>'angle' AS raw,
    (true_answer->>'angle')::float8 AS t,
    (params->'a'->'_value'->0->>0)::float8 a1, (params->'a'->'_value'->0->>1)::float8 a2, (params->'a'->'_value'->0->>2)::float8 a3,
    (params->'b'->'_value'->0->>0)::float8 b1, (params->'b'->'_value'->0->>1)::float8 b2
  FROM firsts)
SELECT qid, COUNT(*) FILTER (WHERE sc<1) AS n_wrong,
  COUNT(*) FILTER (WHERE sc<1 AND (raw IS NULL OR raw ~ '^\s*$')) AS blank,
  COUNT(*) FILTER (WHERE sc<1 AND x IS NULL AND NOT (raw IS NULL OR raw ~ '^\s*$')) AS non_numeric_text,
  COUNT(*) FILTER (WHERE sc<1 AND abs(x - (a1*b1+a2*b2)/(sqrt(a1*a1+a2*a2)*sqrt(b1*b1+b2*b2))) <= 0.01*abs(t)) AS ignored_a3,
  COUNT(*) FILTER (WHERE sc<1 AND abs(x - t) <= 0.02*abs(t)) AS within_2pct,
  COUNT(*) FILTER (WHERE sc<1 AND abs(x - t) > 0.02*abs(t) AND abs(x-t) <= 0.10*abs(t)) AS within_2_10pct,
  COUNT(*) FILTER (WHERE sc<1 AND abs(x - t) > 0.10*abs(t)) AS off_gt_10pct,
  COUNT(*) FILTER (WHERE sc<1 AND abs(x - sqrt(1-t*t)) <= 0.01*sqrt(1-t*t)) AS gave_sin
FROM vals GROUP BY qid ORDER BY qid;
