-- RankDeficient-v2a: wrong first submissions, ratio submitted/correct and other candidate matches (aggregate only)
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) a.course_instance_id AS ci, v.params, v.true_answer, s.submitted_answer, s.score,
    s.partial_scores
  FROM instance_questions iq
  JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
  JOIN assessments a ON a.id=aq.assessment_id
  JOIN questions q ON q.id=aq.question_id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  JOIN submissions s ON s.variant_id=v.id AND s.gradable
  WHERE a.id IN (2355373,2388044,2444565,2491236,2557983,2619950) AND q.qid='17-LinearLeastSquares/LeastSquares-RankDeficient-v2a'
  ORDER BY iq.id, s.date ASC
), vals AS (
  SELECT ci, score,
    (true_answer->>'residual')::float8 AS r,
    CASE WHEN submitted_answer->>'residual' ~ '^\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$' THEN (submitted_answer->>'residual')::float8 END AS s,
    (params->'y'->'_value'->0->>0)::float8 AS y0, (params->'y'->'_value'->1->>0)::float8 AS y1,
    params->'u'->'_value' AS u, (params->>'sv0')::float8 AS sv0, (params->>'sv1')::float8 AS sv1
  FROM firsts
), d AS (
  SELECT ci, score, r, s, y0, y1,
    sqrt(y0*y0+y1*y1) AS ynorm,
    abs(y0*(u->0->>0)::float8 + y1*(u->1->>0)::float8) AS p1,
    abs(y0*(u->0->>1)::float8 + y1*(u->1->>1)::float8) AS p2,
    sqrt(power(y0*(u->0->>0)::float8 + y1*(u->1->>0)::float8,2) + power(y0*(u->0->>1)::float8 + y1*(u->1->>1)::float8,2)) AS p12
  FROM vals
)
SELECT ROUND((s/r)::numeric,2) AS ratio, COUNT(*) AS n
FROM d WHERE score < 1 AND s IS NOT NULL AND r > 0
GROUP BY 1 HAVING COUNT(*) >= 4 ORDER BY n DESC LIMIT 25;
