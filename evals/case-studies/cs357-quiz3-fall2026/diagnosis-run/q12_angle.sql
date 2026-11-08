\echo == Vector projection: classify first-submission cos(theta) answers that got no credit (both versions, 4 offerings)
WITH aqs AS (
  SELECT aq.id, q.qid FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id
  WHERE aq.assessment_id IN (2491228, 2557977, 2619944, 2713997) AND aq.deleted_at IS NULL
    AND q.qid IN ('08-Vector-Matrices-Norms/Norm-Vector-Projection-v1','08-Vector-Matrices-Norms/Norm-Vector-Projection-v2')),
firsts AS (
  SELECT DISTINCT ON (iq.id) aqs.qid, s.submitted_answer, s.partial_scores, v.params
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.partial_scores ? 'angle'
  ORDER BY iq.id, s.date ASC),
vals AS (
  SELECT qid, (partial_scores->'angle'->>'score')::numeric AS sc,
    CASE WHEN submitted_answer->>'angle' ~ '^\s*-?[0-9]*\.?[0-9]+([eE]-?[0-9]+)?\s*$' THEN (submitted_answer->>'angle')::float8 END AS x,
    (params->'a'->'_value'->0->>0)::float8 a1, (params->'a'->'_value'->0->>1)::float8 a2, (params->'a'->'_value'->0->>2)::float8 a3,
    (params->'b'->'_value'->0->>0)::float8 b1, (params->'b'->'_value'->0->>1)::float8 b2
  FROM firsts),
calc AS (SELECT qid, sc, x, (a1*b1+a2*b2) AS dot, sqrt(a1*a1+a2*a2+a3*a3) AS na, sqrt(b1*b1+b2*b2) AS nb FROM vals),
cls AS (SELECT qid, sc, x, dot/(na*nb) AS c, dot, na, nb FROM calc)
SELECT qid,
  COUNT(*) AS n_first, SUM((sc >= 1)::int) AS correct,
  SUM((sc < 1 AND x IS NULL)::int) AS not_numeric,
  SUM((sc < 1 AND abs(x - acos(c)) <= 0.01*abs(acos(c)))::int) AS gave_theta_radians,
  SUM((sc < 1 AND abs(x - degrees(acos(c))) <= 0.01*degrees(acos(c)))::int) AS gave_theta_degrees,
  SUM((sc < 1 AND abs(x - dot/nb) <= 0.01*abs(dot/nb))::int) AS gave_scalar_projection,
  SUM((sc < 1 AND abs(x - dot) <= 0.01*abs(dot))::int) AS gave_dot,
  SUM((sc < 1 AND abs(x - c) <= 0.05*abs(c) AND abs(x - c) > 0.01*abs(c))::int) AS within_1_to_5pct,
  SUM((sc < 1 AND abs(x - nb/na) <= 0.01*abs(nb/na))::int) AS gave_nb_over_na,
  SUM((sc < 1 AND abs(x - dot/(na*na)) <= 0.01*abs(dot/(na*na)))::int) AS gave_dot_over_na2
FROM cls GROUP BY qid ORDER BY qid;
