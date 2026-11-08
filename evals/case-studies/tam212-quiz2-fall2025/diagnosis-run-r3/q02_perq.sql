WITH iq AS (
  SELECT iq.*,
    EXISTS (SELECT 1 FROM variants AS v JOIN submissions AS s ON s.variant_id = v.id
            WHERE v.instance_question_id = iq.id) AS submitted,
    (SELECT COUNT(*) FROM variants AS v JOIN submissions AS s ON s.variant_id = v.id
            WHERE v.instance_question_id = iq.id) AS n_subs
  FROM instance_questions AS iq
)
SELECT ci.short_name AS offering, a.tid, z.number AS zone, ag.number AS slot, q.qid, aq.max_points,
  aq.max_manual_points, aq.max_auto_points,
  COUNT(*) AS n_assigned,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS mean_final_pct,
  ROUND((100 * AVG((iq.score_perc >= 100)::int))::numeric, 1) AS full_credit_pct,
  ROUND((100 * AVG((NOT iq.submitted)::int))::numeric, 1) AS no_submission_pct,
  ROUND((100 * AVG(iq.first_submission_score) FILTER (WHERE iq.submitted))::numeric, 1) AS mean_first_pct,
  ROUND((100 * AVG(iq.max_submission_score) FILTER (WHERE iq.submitted))::numeric, 1) AS mean_best_pct,
  ROUND((AVG(iq.number_attempts) FILTER (WHERE iq.submitted))::numeric, 2) AS mean_attempts,
  ROUND((AVG(iq.n_subs) FILTER (WHERE iq.submitted))::numeric, 2) AS mean_subs,
  ROUND(((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM iq.duration)) FILTER (WHERE iq.submitted)) / 60)::numeric, 1) AS median_minutes
FROM course_instances AS ci
JOIN assessments AS a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions AS aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups AS ag ON ag.id = aq.alternative_group_id
JOIN zones AS z ON z.id = ag.zone_id
JOIN questions AS q ON q.id = aq.question_id
JOIN iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = 1 AND ci.deleted_at IS NULL AND ci.id IN (158221,173734,190462,206303,225310)
  AND a.tid IN ('quiz02','quiz02r') AND aq.max_points > 0 AND COALESCE(iq.used_for_grade, true)
GROUP BY ci.id, ci.short_name, a.tid, z.number, ag.number, q.qid, aq.max_points, aq.max_manual_points, aq.max_auto_points
ORDER BY ci.id, a.tid, zone, slot, q.qid;
