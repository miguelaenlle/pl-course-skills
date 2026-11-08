-- Share of assigned instance questions with any fully correct graded submission, and mean graded submissions, Fall2025 quiz02
SELECT ag.number AS slot, q.qid, COUNT(*) AS n_assigned,
  ROUND(100*AVG((EXISTS (SELECT 1 FROM variants v JOIN submissions s ON s.variant_id=v.id WHERE v.instance_question_id=iq.id AND s.score >= 1))::int),1) AS ever_fully_correct_pct,
  ROUND(100*AVG((iq.points > 0 AND NOT EXISTS (SELECT 1 FROM variants v JOIN submissions s ON s.variant_id=v.id WHERE v.instance_question_id=iq.id AND s.score >= 1))::int),1) AS partial_only_pct
FROM assessment_instances ai
JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
JOIN questions q ON q.id = aq.question_id
WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND ag.number IN (4,6,7,8)
GROUP BY 1,2 ORDER BY 1,2;
