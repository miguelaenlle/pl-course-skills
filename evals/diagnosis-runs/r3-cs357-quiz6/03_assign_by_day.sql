-- Alternative assignment by exam start day, for slots with alternatives (recent offerings)
SELECT ci.short_name AS offering, z.number AS zone, ag.number AS slot, q.qid,
  (ai.date AT TIME ZONE 'America/Chicago')::date AS start_day, COUNT(*) AS n
FROM assessments a
JOIN course_instances ci ON ci.id=a.course_instance_id
JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
JOIN alternative_groups ag ON ag.id=aq.alternative_group_id
JOIN zones z ON z.id=ag.zone_id
JOIN questions q ON q.id=aq.question_id
JOIN instance_questions iq ON iq.assessment_question_id=aq.id
JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
WHERE a.id IN (2491236,2557983,2619950) AND aq.max_points>0
GROUP BY 1,2,3,4,5 ORDER BY 1,2,3,5,4;
