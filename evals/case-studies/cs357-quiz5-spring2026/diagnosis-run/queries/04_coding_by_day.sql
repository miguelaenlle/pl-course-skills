-- Coding-slot alternatives by exam day (America/Chicago), Spring2025..Spring2026.
-- Checks whether pools were balanced on each day (an unbalanced pool hints at a mid-window change).
SELECT ci.short_name AS offering,
  (ai.date AT TIME ZONE 'America/Chicago')::date AS exam_day,
  ag.number AS slot, split_part(q.qid, '/', 2) AS qid,
  COUNT(*) AS n,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS mean_final_pct,
  ROUND(100 * AVG((NOT COALESCE(iq.some_submission,false))::int)::numeric, 1) AS no_sub_pct
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
JOIN questions q ON q.id = aq.question_id
JOIN instance_questions iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026') AND ag.number IN (9, 10)
GROUP BY ci.id, 1, 2, 3, 4
HAVING COUNT(*) >= 1
ORDER BY ci.id, slot, exam_day, qid;
