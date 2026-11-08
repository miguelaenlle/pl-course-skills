SELECT ci.short_name, a.tid, a.id AS assessment_id, a.type, a.max_points AS a_max_points, z.number AS zone, z.title AS zone_title,
  z.max_points AS zone_max, z.best_questions, ag.number AS slot, ag.number_choose, aq.id AS aq_id, q.qid, aq.max_points, aq.max_auto_points, aq.max_manual_points, aq.points_list, q.grading_method
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
JOIN zones z ON z.id = ag.zone_id
JOIN questions q ON q.id = aq.question_id
WHERE ci.id IN (190462) AND a.tid IN ('quiz02','quiz02r')
ORDER BY a.tid, z.number, ag.number, q.qid;
