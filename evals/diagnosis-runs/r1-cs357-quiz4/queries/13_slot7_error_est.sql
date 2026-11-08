-- Slot 7 inverse-iteration error questions: first-submission outcomes by initial error e_0 = ||x0 - u||_inf (1 or 2),
-- and what wrong first answers equal. Pooled over Spring 2025, Fall 2025, Spring 2026, Fall 2026.
WITH fs AS (
  SELECT DISTINCT ON (iq.id) q.qid, v.params, v.true_answer, s.score,
    (COALESCE(s.submitted_answer->>'sol_1', s.submitted_answer->>'sol_2')) AS ans_txt
  FROM assessments a
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999)
    AND q.qid IN ('12-Eigenvalues/Eigen-InversePowerItErrorEst', '12-Eigenvalues/Eigen-ShiftedInversePowerItErrorEst')
  ORDER BY iq.id, s.date ASC
), x AS (
  SELECT qid, score,
    CASE WHEN ans_txt ~ '^-?[0-9.]+(e-?[0-9]+)?$' THEN ans_txt::float END AS ans,
    GREATEST(abs((params->>'x1')::int - (params->>'u1')::int), 1, abs((params->>'x3')::int - (params->>'u3')::int)) AS e0,
    (true_answer->>'sol_1')::float AS sol_1, (true_answer->>'sol_2')::float AS sol_2,
    (params->>'iters')::int AS k
  FROM fs)
SELECT qid, e0, COUNT(*) AS n,
  ROUND(100 * AVG(score)::numeric, 1) AS first_sub_pct,
  COUNT(*) FILTER (WHERE score < 1) AS n_wrong,
  COUNT(*) FILTER (WHERE score < 1 AND e0 = 2 AND abs(ans - CASE WHEN qid LIKE '%Shifted%' THEN sol_2 ELSE sol_1 END / 2) <= 1e-3 * abs(CASE WHEN qid LIKE '%Shifted%' THEN sol_2 ELSE sol_1 END / 2)) AS wrong_eq_missing_e0,
  COUNT(*) FILTER (WHERE score < 1 AND qid LIKE '%Shifted%' AND abs(ans - sol_1) <= 1e-3 * abs(sol_1)) AS wrong_eq_unshifted_ratio,
  COUNT(*) FILTER (WHERE score < 1 AND qid LIKE '%Shifted%' AND e0 = 2 AND abs(ans - sol_1 / 2) <= 1e-3 * abs(sol_1 / 2)) AS wrong_eq_unshifted_missing_e0
FROM x GROUP BY qid, e0 ORDER BY qid, e0;
