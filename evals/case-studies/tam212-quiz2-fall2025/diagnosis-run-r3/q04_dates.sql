-- Assignment by exam day (America/Chicago) and overall instance info for Fall2025 quiz02
SELECT (ai.date AT TIME ZONE 'America/Chicago')::date AS day, ag.number AS slot, q.qid, COUNT(*) AS n
FROM assessment_instances ai
JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
JOIN questions q ON q.id = aq.question_id
WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND aq.max_points > 0 AND ag.number IN (4,5,6,7,8)
GROUP BY 1,2,3 ORDER BY 2,3,1;
