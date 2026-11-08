-- Per-question aggregates for Quiz 4: Spring2025, Fall2025, Spring2026, Fall2026
SELECT
  ci.short_name AS offering,
  ag.number AS slot,
  q.qid,
  aq.max_points,
  COUNT(iq.id) AS n_assigned,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS mean_final_pct,
  ROUND(100 * AVG((iq.score_perc >= 100)::int)::numeric, 1) AS full_credit_pct,
  ROUND(100 * AVG((NOT COALESCE(iq.some_submission, false))::int)::numeric, 1) AS no_sub_pct,
  ROUND(100 * AVG(iq.first_submission_score) FILTER (WHERE iq.some_submission)::numeric, 1) AS first_pct,
  ROUND(100 * AVG(iq.max_submission_score) FILTER (WHERE iq.some_submission)::numeric, 1) AS best_pct,
  ROUND(AVG(iq.score_perc) FILTER (WHERE iq.some_submission)::numeric, 1) AS final_pct_submitters,
  ROUND(AVG(iq.number_attempts) FILTER (WHERE iq.some_submission)::numeric, 2) AS attempts,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM iq.duration))
    FILTER (WHERE iq.some_submission) / 60)::numeric, 1) AS med_min,
  COUNT(*) FILTER (WHERE iq.score_perc >= 100 AND COALESCE(iq.max_submission_score,0) < 1) AS n_override_like,
  COUNT(*) FILTER (WHERE iq.used_for_grade = false) AS n_not_used
FROM course_instances AS ci
JOIN assessments AS a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions AS aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups AS ag ON ag.id = aq.alternative_group_id
JOIN questions AS q ON q.id = aq.question_id
JOIN instance_questions AS iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE a.id IN (2491230, 2557979, 2619946, 2713999)
GROUP BY ci.id, 1, 2, 3, 4
ORDER BY slot, q.qid, ci.id;
