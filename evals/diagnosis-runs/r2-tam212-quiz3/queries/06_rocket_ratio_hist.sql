-- polarForceRocket first submissions (Sp24..Fall2026 pooled): histogram of the submitted answer
-- relative to the correct answer and to its pieces. Aggregate buckets only.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) iq.id,
    (v.params->>'m')::float8 AS m, (v.params->>'c1')::float8 AS c1, (v.params->>'omega')::float8 AS w,
    (v.params->>'gf')::float8 AS gf, (v.params->>'thetaD')::float8 AS th,
    CASE WHEN s.submitted_answer->>'ansValue' ~ '^\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$'
         THEN (s.submitted_answer->>'ansValue')::float8 END AS x
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id=aq.question_id AND q.qid='polarForceRocket'
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  JOIN submissions s ON s.variant_id=v.id
  WHERE ci.course_id=:course_id AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
  ORDER BY iq.id, s.date, s.id
),
c AS (SELECT *, m*(10 + c1*radians(th))*w*w/1000 AS cent, 2*m*c1*w*w/1000 AS tang FROM firsts WHERE x IS NOT NULL),
b AS (
  SELECT 'x / correct' AS measure, ROUND((x/(gf-cent))::numeric,1)::text AS bucket FROM c
  UNION ALL SELECT 'x / gf', ROUND((x/gf)::numeric,1)::text FROM c
  UNION ALL SELECT '(x - gf) / -m*r*w^2', ROUND(((x-gf)/(-cent))::numeric,1)::text FROM c
  UNION ALL SELECT 'x / tangential m*a_theta', ROUND((x/tang)::numeric,1)::text FROM c
  UNION ALL SELECT 'sign(x)', sign(x)::text FROM c
)
SELECT measure, bucket, COUNT(*) AS n FROM b GROUP BY measure, bucket HAVING COUNT(*) >= 8 ORDER BY measure, n DESC;
