-- Per-question statistics for Quiz 4 (tid quiz04) across recent offerings, course 1.
-- Slot = alternative group (alternatives competing for the same slot), with number_choose.
SELECT
  ci.short_name AS offering,
  ag.number AS slot_no,
  ag.number_choose AS choose,
  q.qid,
  aq.max_points AS maxp,
  aq.max_manual_points AS man_p,
  COUNT(iq.id) AS n,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS final_pct,
  ROUND(100 * AVG((iq.score_perc >= 100)::int)::numeric, 1) AS full_pct,
  ROUND(100 * AVG((NOT COALESCE(iq.some_submission, false))::int)::numeric, 1) AS nosub_pct,
  ROUND(100 * AVG(iq.first_submission_score) FILTER (WHERE iq.some_submission)::numeric, 1) AS first_pct,
  ROUND(100 * AVG(iq.max_submission_score) FILTER (WHERE iq.some_submission)::numeric, 1) AS best_pct,
  ROUND(AVG(iq.number_attempts) FILTER (WHERE iq.some_submission)::numeric, 2) AS attempts,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM iq.duration))
    FILTER (WHERE iq.some_submission) / 60)::numeric, 1) AS med_min
FROM course_instances AS ci
JOIN assessments AS a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions AS aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups AS ag ON ag.id = aq.alternative_group_id
JOIN questions AS q ON q.id = aq.question_id
JOIN instance_questions AS iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = 1
  AND ci.deleted_at IS NULL
  AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
  AND a.tid = 'quiz04'
  AND COALESCE(iq.used_for_grade, true)
GROUP BY ci.id, 1, 2, 3, 4, 5, 6
ORDER BY 2, 4, ci.id;
