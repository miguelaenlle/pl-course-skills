SELECT
  ci.short_name AS offering,
  z.number AS zone,
  ag.number AS slot,
  q.qid,
  aq.id AS aq_id,
  aq.max_points,
  aq.max_manual_points,
  COUNT(*) AS n_assigned,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS mean_final_pct,
  ROUND((100 * AVG((iq.score_perc >= 100)::int))::numeric, 1) AS full_credit_pct,
  ROUND((100 * AVG((NOT COALESCE(iq.some_submission, false))::int))::numeric, 1) AS no_submission_pct,
  ROUND((100 * AVG(iq.first_submission_score) FILTER (WHERE iq.some_submission))::numeric, 1) AS mean_first_pct,
  ROUND((100 * AVG(iq.max_submission_score) FILTER (WHERE iq.some_submission))::numeric, 1) AS mean_best_pct,
  ROUND((AVG(iq.number_attempts) FILTER (WHERE iq.some_submission))::numeric, 2) AS mean_attempts,
  ROUND(((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM iq.duration))
    FILTER (WHERE iq.some_submission)) / 60)::numeric, 1) AS median_minutes
FROM course_instances AS ci
JOIN assessments AS a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions AS aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups AS ag ON ag.id = aq.alternative_group_id
JOIN zones AS z ON z.id = ag.zone_id
JOIN questions AS q ON q.id = aq.question_id
JOIN instance_questions AS iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = :course_id
  AND ci.deleted_at IS NULL
  AND a.tid = :'assessment_tid'
  AND ci.short_name IN ('Sp24','Fa24','Spring2025','ZJUI-Spring2025','Fall2025','ZJUI-Spring2026','Spring2026','Fall2026')
  AND COALESCE(iq.used_for_grade, true)
  AND COALESCE(aq.max_points,0) > 0
GROUP BY ci.id, ci.short_name, z.number, ag.number, q.qid, aq.id, aq.max_points, aq.max_manual_points
ORDER BY ci.id, zone, slot, q.qid;
