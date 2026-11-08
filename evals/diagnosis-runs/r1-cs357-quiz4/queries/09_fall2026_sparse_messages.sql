-- Fall 2026 Quiz 4 (2713999) new sparse coding questions: grader message patterns on each student's best graded submission.
-- Numbers other than case counts are not present in these messages. Counts only.
WITH iqs AS (
  SELECT q.qid, iq.id AS iq_id FROM assessment_questions aq JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id = 2713999 AND aq.deleted_at IS NULL AND q.qid LIKE '11-Sparse/Sparse-COO-%'),
best AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.qid, s.feedback
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.score DESC NULLS LAST, s.date DESC)
SELECT qid, t->>'name' AS test_name,
  CASE WHEN t->>'message' LIKE 'Task 2 must compute%' THEN 'dense-operation check triggered (score 0)'
       ELSE LEFT(regexp_replace(t->>'message', '\s+', ' ', 'g'), 70) END AS message,
  COUNT(*) AS n
FROM best, jsonb_array_elements(best.feedback->'results'->'tests') AS t
WHERE t->>'name' NOT LIKE 'Your code raised%'
GROUP BY 1, 2, 3 ORDER BY 1, 2, 4 DESC;

-- Which dense operations triggered the check (pooled over the three questions)
WITH iqs AS (
  SELECT q.qid, iq.id AS iq_id FROM assessment_questions aq JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id = 2713999 AND aq.deleted_at IS NULL AND q.qid LIKE '11-Sparse/Sparse-COO-%'),
best AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.qid, s.feedback
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.score DESC NULLS LAST, s.date DESC)
SELECT regexp_replace(t->>'message', '^.*Your function contains ', '') AS violations, COUNT(*) AS n
FROM best, jsonb_array_elements(best.feedback->'results'->'tests') AS t
WHERE t->>'message' LIKE 'Task 2 must compute%'
GROUP BY 1 ORDER BY 2 DESC;
