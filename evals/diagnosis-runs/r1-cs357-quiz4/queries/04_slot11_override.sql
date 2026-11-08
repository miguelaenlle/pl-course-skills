-- Spring 2026 Quiz 4 (2619946), coding slot 11: how final scores were set, aggregated per question
WITH iq AS (
  SELECT q.qid, iq.*
  FROM assessment_questions aq
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id = 2619946 AND aq.deleted_at IS NULL
    AND q.qid IN ('12-Eigenvalues/Eigen-TwoLargestEig','12-Eigenvalues/Eigen-Power-Matrix-and-Transpose')
)
SELECT qid, COUNT(*) AS n,
  COUNT(*) FILTER (WHERE points = 4) AS n_points_4,
  ROUND(AVG(auto_points)::numeric,2) AS mean_auto_points,
  ROUND(AVG(manual_points)::numeric,2) AS mean_manual_points,
  ROUND(AVG(points)::numeric,2) AS mean_points,
  COUNT(*) FILTER (WHERE last_grader IS NOT NULL) AS n_with_last_grader,
  MIN(modified_at)::date AS min_modified, MAX(modified_at)::date AS max_modified
FROM iq GROUP BY qid;

-- score-log entries that were not produced by a grading job (i.e., manual/staff score changes), by day
SELECT q.qid, l.date::date AS day, COUNT(*) AS n_logs, COUNT(DISTINCT l.instance_question_id) AS n_iq,
  COUNT(DISTINCT l.auth_user_id) AS n_distinct_actors, ROUND(AVG(l.points)::numeric,2) AS mean_points_set
FROM assessment_questions aq
JOIN questions q ON q.id = aq.question_id
JOIN instance_questions iq ON iq.assessment_question_id = aq.id
JOIN question_score_logs l ON l.instance_question_id = iq.id AND l.grading_job_id IS NULL
WHERE aq.assessment_id = 2619946 AND aq.deleted_at IS NULL
  AND q.qid IN ('12-Eigenvalues/Eigen-TwoLargestEig','12-Eigenvalues/Eigen-Power-Matrix-and-Transpose')
GROUP BY 1, 2 ORDER BY 1, 2;

-- audit events touching this assessment's instance questions (actions only, aggregated)
SELECT ae.table_name, ae.action, ae.action_detail, ae.date::date AS day, COUNT(*) AS n
FROM audit_events ae
WHERE ae.assessment_id = 2619946
GROUP BY 1,2,3,4 ORDER BY 4,1,2;

-- Assessment-level: quiz total score by which slot-11 alternative was assigned
SELECT q.qid AS slot11_alternative, COUNT(*) AS n,
  ROUND(AVG(ai.score_perc)::numeric,1) AS mean_quiz_pct,
  ROUND(AVG(ai.points)::numeric,2) AS mean_quiz_points, MAX(ai.max_points) AS quiz_max_points
FROM assessment_instances ai
JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN questions q ON q.id = aq.question_id
WHERE ai.assessment_id = 2619946 AND ai.include_in_statistics
  AND q.qid IN ('12-Eigenvalues/Eigen-TwoLargestEig','12-Eigenvalues/Eigen-Power-Matrix-and-Transpose')
GROUP BY 1;

-- Slot 11 points each group would have had from best submissions alone (points list is a flat 4 per try,
-- so best submission score x 4 is the auto-graded value), counting students with no submission as 0.
SELECT q.qid, COUNT(*) AS n,
  ROUND(AVG(4 * COALESCE(iq.max_submission_score, 0))::numeric, 2) AS mean_points_from_best_submission,
  ROUND(AVG(iq.points)::numeric, 2) AS mean_points_recorded
FROM assessment_questions aq
JOIN questions q ON q.id = aq.question_id
JOIN instance_questions iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE aq.assessment_id = 2619946 AND aq.deleted_at IS NULL
  AND q.qid IN ('12-Eigenvalues/Eigen-TwoLargestEig','12-Eigenvalues/Eigen-Power-Matrix-and-Transpose')
GROUP BY 1;
