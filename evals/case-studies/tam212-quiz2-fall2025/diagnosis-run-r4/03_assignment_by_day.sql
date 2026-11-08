-- Alternatives drawn per exam day (start date), Fall 2025 and Fall 2026 quiz02
SELECT ci.short_name AS offering,
  ag.number || CASE WHEN (SELECT COUNT(*) FROM assessment_questions x WHERE x.alternative_group_id = ag.id AND x.deleted_at IS NULL) > 1 THEN '.' || aq.number_in_alternative_group ELSE '' END AS question_number,
  q.qid, (ai.date AT TIME ZONE 'America/Chicago')::date AS exam_day, COUNT(*) AS n
FROM assessments a
JOIN course_instances ci ON ci.id = a.course_instance_id
JOIN assessment_instances ai ON ai.assessment_id = a.id AND ai.include_in_statistics
JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id AND aq.max_points > 0
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
JOIN questions q ON q.id = aq.question_id
WHERE a.id IN (2574213, 2716830) AND ag.number >= 4
GROUP BY 1,2,3,4 ORDER BY 1,2,4;
