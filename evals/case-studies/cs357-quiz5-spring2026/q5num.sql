WITH iq AS (
  SELECT
    iq.*,
    EXISTS (
      SELECT 1 FROM variants AS v JOIN submissions AS s ON s.variant_id = v.id
      WHERE v.instance_question_id = iq.id
    ) AS submitted
  FROM instance_questions AS iq
)
SELECT
  ci.short_name AS offering,
  z.number AS zone,
  z.title AS zone_title,
  CASE
    WHEN (SELECT COUNT(*) FROM assessment_questions AS x
          WHERE x.alternative_group_id = ag.id AND x.deleted_at IS NULL) = 1
      THEN ag.number::text
    ELSE ag.number || '.' || aq.number_in_alternative_group
  END AS question_number,
  q.qid,
  aq.max_points,
  COUNT(*) AS n_assigned,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS mean_final_pct,
  ROUND((100 * AVG((iq.score_perc >= 100)::int))::numeric, 1) AS full_credit_pct,
  ROUND((100 * AVG((NOT iq.submitted)::int))::numeric, 1) AS no_submission_pct,
  ROUND((100 * AVG(iq.first_submission_score) FILTER (WHERE iq.submitted))::numeric, 1) AS mean_first_pct,
  ROUND((100 * AVG(iq.max_submission_score) FILTER (WHERE iq.submitted))::numeric, 1) AS mean_best_pct,
  ROUND((AVG(iq.number_attempts) FILTER (WHERE iq.submitted))::numeric, 2) AS mean_attempts,
  ROUND(((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM iq.duration))
    FILTER (WHERE iq.submitted)) / 60)::numeric, 1) AS median_minutes
FROM course_instances AS ci
JOIN assessments AS a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions AS aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups AS ag ON ag.id = aq.alternative_group_id
JOIN zones AS z ON z.id = ag.zone_id
JOIN questions AS q ON q.id = aq.question_id
JOIN iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = :course_id
  AND ci.deleted_at IS NULL
  AND a.tid = 'quiz5' AND ci.short_name = 'Spring2026'
  AND aq.max_points > 0
  AND COALESCE(iq.used_for_grade, true)
GROUP BY ci.id, ci.short_name, z.number, z.title, ag.id, ag.number, aq.id,
  aq.number_in_alternative_group, q.qid, aq.max_points
ORDER BY ci.id, z.number, ag.number, aq.number_in_alternative_group;
