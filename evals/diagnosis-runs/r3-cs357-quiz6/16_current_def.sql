-- Current (Fall2026) and Spring2026 Quiz 6 definitions as synced, plus assessment max points
SELECT a.id AS a_id, a.max_points AS assessment_max_points, z.number AS zone, ag.number AS slot, q.qid, aq.max_points, aq.points_list::text
FROM assessments a
JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
JOIN alternative_groups ag ON ag.id=aq.alternative_group_id JOIN zones z ON z.id=ag.zone_id
JOIN questions q ON q.id=aq.question_id
WHERE a.id IN (2714003, 2619950) ORDER BY a.id, z.number, ag.number, q.qid;
