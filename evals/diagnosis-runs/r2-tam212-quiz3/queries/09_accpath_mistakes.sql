-- accelerationFromPath first submissions: classify against predicted mistakes. Aggregate only.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) ci.short_name AS offering,
    (v.params->>'c1')::float8 AS c1, (v.params->>'p1')::float8 AS p, (v.params->>'rho')::float8 AS rho,
    (v.params->>'distance')::float8 AS d,
    CASE WHEN s.submitted_answer->>'ansValue' ~ '^\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$'
         THEN (s.submitted_answer->>'ansValue')::float8 END AS x, s.score
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id=aq.question_id AND q.qid='accelerationFromPath'
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  JOIN submissions s ON s.variant_id=v.id
  WHERE ci.course_id=:course_id AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
  ORDER BY iq.id, s.date, s.id
),
c AS (
  SELECT *, power(d*(p+1)/c1, 1/(p+1)) AS tt FROM firsts
),
k AS (
  SELECT offering, x, score,
    sqrt(power(c1*p*power(tt,p-1),2) + power(power(c1*power(tt,p),2)/rho,2)) AS correct,
    sqrt(power(c1*p*power(d,p-1),2) + power(power(c1*power(d,p),2)/rho,2)) AS used_t_equals_s,
    power(c1*power(tt,p),2)/rho AS normal_only,
    c1*p*power(tt,p-1) AS tangential_only
  FROM c
)
SELECT COALESCE(offering,'ALL') AS offering, COUNT(*) n_first,
  ROUND(100*AVG((score>=1)::int)::numeric,1) AS first_correct_pct,
  ROUND(100*AVG((abs(x-correct) <= 0.01*abs(correct)+1e-5)::int)::numeric,1) AS matches_correct_pct,
  ROUND(100*AVG((abs(x-used_t_equals_s) <= 0.01*abs(used_t_equals_s)+1e-5)::int)::numeric,1) AS used_t_equals_s_pct,
  ROUND(100*AVG((abs(x-normal_only) <= 0.01*abs(normal_only)+1e-5)::int)::numeric,1) AS normal_only_pct,
  ROUND(100*AVG((abs(x-tangential_only) <= 0.01*abs(tangential_only)+1e-5)::int)::numeric,1) AS tangential_only_pct
FROM k GROUP BY ROLLUP(offering) ORDER BY offering NULLS LAST;
