-- Coding slot 12 (sparse): how many students were assigned each alternative, by day the quiz instance was created.
SELECT ci.short_name AS offering, ai.date::date AS day, q.qid, COUNT(*) AS n
FROM assessment_instances ai
JOIN assessments a ON a.id = ai.assessment_id
JOIN course_instances ci ON ci.id = a.course_instance_id
JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
JOIN questions q ON q.id = aq.question_id
WHERE a.id IN (2491230, 2557979, 2619946) AND ai.include_in_statistics AND ag.number = 12
GROUP BY ci.id, 1, 2, 3 ORDER BY ci.id, 2, 3;
