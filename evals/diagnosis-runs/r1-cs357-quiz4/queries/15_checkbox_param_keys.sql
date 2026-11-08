-- Structure check: keys stored for checkbox options in variant params / true_answer (no values printed)
SELECT 'params option keys' AS what, k, COUNT(*) FROM (
  SELECT jsonb_object_keys(v.params->'student'->0) AS k
  FROM assessment_questions aq JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN variants v ON v.instance_question_id = iq.id
  WHERE aq.assessment_id = 2619946 AND q.qid = '12-Eigenvalues/Eigen-PowerIterationConvergence') x GROUP BY 1, 2
UNION ALL
SELECT 'true_answer type', jsonb_typeof(v.true_answer->'student'), COUNT(*)
  FROM assessment_questions aq JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN variants v ON v.instance_question_id = iq.id
  WHERE aq.assessment_id = 2619946 AND q.qid = '12-Eigenvalues/Eigen-PowerIterationConvergence' GROUP BY 1, 2;
