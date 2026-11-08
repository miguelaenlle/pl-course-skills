-- Fall 2025: share of students who also took the Quiz 2 retake (quiz02r), by slot-6 alternative drawn on Quiz 2
SELECT q.qid AS slot6_alternative, COUNT(*) AS n,
  ROUND(100*AVG((r.id IS NOT NULL)::int),1) AS pct_took_retake,
  ROUND(AVG(ai.score_perc)::numeric,1) AS mean_quiz2_pct,
  ROUND(AVG(r.score_perc)::numeric,1) AS mean_retake_pct_if_taken
FROM assessment_instances ai
JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id AND ag.number = 6
JOIN questions q ON q.id = aq.question_id
LEFT JOIN assessment_instances r ON r.assessment_id = 2574215 AND r.user_id = ai.user_id AND r.include_in_statistics
WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics
GROUP BY q.qid ORDER BY q.qid;
