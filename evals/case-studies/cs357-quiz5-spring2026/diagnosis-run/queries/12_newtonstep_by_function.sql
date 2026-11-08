-- Slot 6 (1D Newton optimization step): first-submission score and final score grouped by the generated
-- function family (params.f with digits removed). Spring2025..Spring2026. Aggregates only.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) split_part(q.qid, '/', 2) AS qid,
    regexp_replace(v.params->>'f', '[0-9]', 'k', 'g') AS f_family, s.score, iq.score_perc
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id AND q.qid IN ('15-Optimization/Optimization1D-NewtonStep','15-Optimization/Optimization1D-NewtonStepv2')
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026')
  ORDER BY iq.id, v.date, s.date
)
SELECT qid, f_family, COUNT(*) AS n, ROUND((100*AVG(score))::numeric,1) AS first_pct, ROUND(AVG(score_perc)::numeric,1) AS final_pct
FROM firsts GROUP BY 1, 2 ORDER BY 1, 2;
