\echo == Vector projection: value buckets for wrong first-submission cos(theta), and relative-error buckets
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
SELECT qid, CASE WHEN x IS NULL THEN 'null' WHEN x < 0 THEN 'neg' WHEN x <= 1 THEN '0-1' WHEN x <= 2 THEN '1-2' WHEN x <= 10 THEN '2-10' WHEN x<=100 THEN '10-100' ELSE '>100' END AS xb,
  CASE WHEN x IS NULL OR t = 0 THEN 'na' ELSE (ROUND((x/t*10)::numeric)/10)::text END AS ratio_b, COUNT(*)
FROM vals WHERE sc < 1 GROUP BY 1,2,3 HAVING COUNT(*) >= 5 ORDER BY 1,4 DESC;
