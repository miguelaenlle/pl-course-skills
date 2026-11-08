-- Slot 6 Eigenvalues-ShiftedInverseConverge-v2: first-submission score by sign of the shift shown (A - sI vs A + sI).
-- Pooled over Spring 2025, Fall 2025, Spring 2026, Fall 2026.
WITH fs AS (
  SELECT DISTINCT ON (iq.id) v.params, s.score
  FROM assessments a
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND q.qid = '12-Eigenvalues/Eigenvalues-ShiftedInverseConverge-v2'
  ORDER BY iq.id, s.date ASC)
SELECT CASE WHEN params->>'mat' LIKE '%+%' THEN 'B = (A + sI)^-1' ELSE 'B = (A - sI)^-1' END AS form,
  COUNT(*) AS n, ROUND(100 * AVG(score)::numeric, 1) AS first_sub_pct
FROM fs GROUP BY 1 ORDER BY 1;
