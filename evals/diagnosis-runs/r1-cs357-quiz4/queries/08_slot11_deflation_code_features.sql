-- TwoLargestEig: does the best submission's code build the deflation with np.outer, or with a transpose of a 1-D vector?
-- Grouped by result pattern on the given-matrix test. Spring 2025, Fall 2025, Spring 2026 pooled. Counts only.
WITH iqs AS (
  SELECT iq.id AS iq_id FROM assessment_questions aq JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id IN (2491230, 2557979, 2619946) AND aq.deleted_at IS NULL
    AND q.qid = '12-Eigenvalues/Eigen-TwoLargestEig'),
best AS (
  SELECT DISTINCT ON (iqs.iq_id) s.feedback->'results'->'tests'->0->>'message' AS msg,
    convert_from(decode(s.submitted_answer->'_files'->0->>'contents', 'base64'), 'UTF8') AS code
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.score DESC NULLS LAST, s.date DESC),
g AS (
  SELECT CASE
      WHEN msg LIKE '%''lambda_max'' looks good%''lambda_2nd'' looks good%v_max looks good%v_2nd looks good%' THEN 'A: all four correct'
      WHEN msg LIKE '%''lambda_max'' looks good%''lambda_2nd'' is inaccurate%v_max looks good%v_2nd is inaccurate%' THEN 'B: first pair ok, second pair wrong'
      ELSE 'C: other' END AS pattern,
    code ~ 'outer' AS uses_outer,
    code ~ '(@|dot\()\s*\(?\s*\w+\.T' AS matmul_with_transpose,
    code ~ '\w\s*\*\s*\(?\s*\w+\.T' AS elementwise_transpose,
    code ~ 'reshape|\[:\s*,\s*None\]|\[None|newaxis|atleast_2d' AS makes_2d
  FROM best)
SELECT pattern, COUNT(*) AS n,
  COUNT(*) FILTER (WHERE uses_outer) AS n_uses_outer,
  COUNT(*) FILTER (WHERE NOT uses_outer AND matmul_with_transpose) AS n_matmul_transpose_no_outer,
  COUNT(*) FILTER (WHERE NOT uses_outer AND makes_2d) AS n_reshape_no_outer,
  COUNT(*) FILTER (WHERE NOT uses_outer AND NOT makes_2d AND (matmul_with_transpose OR elementwise_transpose)) AS n_transpose_of_1d_no_outer,
  COUNT(*) FILTER (WHERE NOT uses_outer AND elementwise_transpose) AS n_elementwise_transpose_no_outer
FROM g GROUP BY 1 ORDER BY 1;
