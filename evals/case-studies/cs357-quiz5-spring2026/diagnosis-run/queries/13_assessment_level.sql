-- Assessment-level picture per offering: total score, time on the assessment (first to last activity),
-- and how often students left coding questions without any submission. Fall2023..Spring2026.
WITH ai AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, ai.id, ai.score_perc,
    EXTRACT(EPOCH FROM (ai.modified_at - ai.date)) / 60 AS span_min,
    EXTRACT(EPOCH FROM ai.duration) / 60 AS dur_min
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_instances ai ON ai.assessment_id = a.id AND ai.include_in_statistics
  WHERE ci.course_id = 114 AND ci.short_name IN ('Fall2023','Spring2024','Fall2024','Spring2025','Fall2025','Spring2026')
), coding AS (
  SELECT iq.assessment_instance_id AS ai_id,
    COUNT(*) FILTER (WHERE NOT COALESCE(iq.some_submission,false)) AS n_coding_nosub,
    SUM(EXTRACT(EPOCH FROM iq.duration)) / 60 AS coding_min
  FROM instance_questions iq
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  WHERE ag.number IN (9, 10) AND iq.assessment_instance_id IN (SELECT id FROM ai)
  GROUP BY 1
)
SELECT offering, COUNT(*) AS n_students,
  ROUND(AVG(score_perc)::numeric, 1) AS mean_quiz_pct,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dur_min)::numeric, 0) AS med_duration_min,
  ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY dur_min)::numeric, 0) AS p90_duration_min,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY coding_min)::numeric, 0) AS med_coding_min,
  ROUND(100 * AVG((n_coding_nosub >= 1)::int)::numeric, 1) AS pct_skip_any_coding,
  ROUND(100 * AVG((n_coding_nosub = 2)::int)::numeric, 1) AS pct_skip_both_coding
FROM ai LEFT JOIN coding c ON c.ai_id = ai.id
GROUP BY ci_id, offering ORDER BY ci_id;
