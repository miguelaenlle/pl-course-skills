-- Trap check: autograded instance questions whose final score exceeds the best submission (manual override / blanket credit).
SELECT ci.short_name AS offering, q.qid, COUNT(*) AS n,
  COUNT(*) FILTER (WHERE iq.score_perc > 100*COALESCE(iq.max_submission_score,0) + 0.5) AS final_above_best,
  COUNT(*) FILTER (WHERE iq.score_perc >= 100 AND COALESCE(iq.max_submission_score,0) < 1) AS full_without_full_submission
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL AND COALESCE(aq.max_manual_points,0) = 0 AND aq.max_points > 0
JOIN questions q ON q.id = aq.question_id
JOIN instance_questions iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026','Fall2026')
GROUP BY ci.id, ci.short_name, q.qid
HAVING COUNT(*) FILTER (WHERE iq.score_perc > 100*COALESCE(iq.max_submission_score,0) + 0.5) > 0
ORDER BY ci.id, q.qid;
