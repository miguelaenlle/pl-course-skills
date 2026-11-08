-- Structure of Quiz 4 in Spring 2026 (2619946), Fall 2025 (2557979), Spring 2025 (2491230), Fall 2026 (2713999)
SELECT a.id AS assessment_id, z.number AS zone, z.title AS zone_title, z.number_choose AS zone_choose, z.best_questions,
  ag.number AS slot, ag.number_choose AS slot_choose, q.qid, aq.max_points, array_length(aq.points_list,1) AS n_tries, aq.points_list[1:3] AS first_pts, q.grading_method, q.type
FROM assessments a
JOIN zones z ON z.assessment_id = a.id
JOIN alternative_groups ag ON ag.zone_id = z.id
JOIN assessment_questions aq ON aq.alternative_group_id = ag.id AND aq.deleted_at IS NULL
JOIN questions q ON q.id = aq.question_id
WHERE a.id IN (2619946, 2557979, 2491230, 2713999)
ORDER BY a.id, z.number, ag.number, aq.number;
