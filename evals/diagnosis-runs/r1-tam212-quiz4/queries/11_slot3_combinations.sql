-- Slot 3 (choose 3 of 5): points earned in the slot by which 3 questions a student drew. Spring2026 and pooled other offerings.
WITH iq AS (
  SELECT ci.short_name AS offering, iq.assessment_instance_id AS ai_id, q.qid, iq.points, iq.duration, iq.score_perc
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id AND ag.number = 3
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 1 AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
), per AS (
  SELECT CASE WHEN offering = 'Spring2026' THEN 'Spring2026' ELSE 'Sp24-Fall2026 excl. Spring2026' END AS grp,
    ai_id, COUNT(*) AS k,
    COUNT(*) FILTER (WHERE qid IN ('twoPointVAlg','rbmAccelNum')) AS n_single_body,
    SUM(points) AS pts, SUM(EXTRACT(EPOCH FROM duration))/60 AS mins
  FROM iq GROUP BY 1, 2
)
SELECT grp, n_single_body AS single_body_questions_drawn, COUNT(*) AS n_students,
  ROUND(AVG(pts)::numeric,1) AS mean_slot_points_of_51,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY mins))::numeric,1) AS median_slot_minutes
FROM per WHERE k = 3 GROUP BY 1, 2 ORDER BY 1, 2;
