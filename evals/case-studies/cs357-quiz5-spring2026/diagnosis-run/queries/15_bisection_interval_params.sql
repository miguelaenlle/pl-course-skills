-- Nonlinear1D-BisectionMethod-DetermineIntervalSize: first-submission score grouped by number of
-- significant digits in the exact answer (R-L)/2^n. Spring2025..Spring2026. Aggregates only.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) (v.params->>'R')::int - (v.params->>'L')::int AS w, (v.params->>'n')::int AS n, s.score
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id AND q.qid = '14-NonlinearSystems/Nonlinear1D-BisectionMethod-DetermineIntervalSize'
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026')
  ORDER BY iq.id, s.date
)
SELECT length(rtrim(replace(replace(trim(to_char(w / 2.0 ^ n, '9999.999999')), '.', ''), '-', ''), '0')) - CASE WHEN w / 2.0 ^ n < 1 THEN 1 ELSE 0 END AS exact_sig_digits,
  COUNT(*) AS n, ROUND((100 * AVG(score))::numeric, 1) AS first_pct
FROM firsts GROUP BY 1 ORDER BY 1;
