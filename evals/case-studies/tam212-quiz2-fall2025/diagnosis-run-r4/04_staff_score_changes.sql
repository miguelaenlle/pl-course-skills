-- Score changes not made by an auto-grading job, per question (auto-graded questions only meaningful)
WITH logs AS (
  SELECT qsl.*, iq.assessment_question_id,
    qsl.points - LAG(qsl.points) OVER (PARTITION BY qsl.instance_question_id ORDER BY qsl.date, qsl.id) AS delta_points
  FROM question_score_logs qsl
  JOIN instance_questions iq ON iq.id = qsl.instance_question_id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ai.assessment_id IN (2434746, 2497144, 2574213, 2634479, 2716830)
)
SELECT ci.short_name AS offering, q.qid, aq.max_points,
  (q.grading_method::text) AS grading_method,
  COUNT(DISTINCT l.instance_question_id) AS n_iq_with_staff_change,
  COUNT(*) AS n_staff_rows,
  ROUND(AVG(l.delta_points)::numeric, 2) AS mean_delta_points,
  MIN(l.date)::date AS first_change, MAX(l.date)::date AS last_change
FROM logs l
JOIN assessment_questions aq ON aq.id = l.assessment_question_id
JOIN assessments a ON a.id = aq.assessment_id
JOIN course_instances ci ON ci.id = a.course_instance_id
JOIN questions q ON q.id = aq.question_id
WHERE l.grading_job_id IS NULL
GROUP BY 1,2,3,4 ORDER BY 1,2;
