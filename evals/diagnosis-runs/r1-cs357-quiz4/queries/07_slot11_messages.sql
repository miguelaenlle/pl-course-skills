-- TwoLargestEig: message patterns on the given-matrix test (numbers masked), pooled over Spring 2025, Fall 2025, Spring 2026
WITH iqs AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, q.qid, iq.id AS iq_id
  FROM assessments a
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE a.id IN (2491230, 2557979, 2619946)
    AND q.qid IN ('12-Eigenvalues/Eigen-TwoLargestEig', '12-Eigenvalues/Eigen-Power-Matrix-and-Transpose')
),
best AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.ci_id, iqs.offering, iqs.qid, s.feedback
  FROM iqs
  JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.score DESC NULLS LAST, s.date DESC
),
t AS (
  SELECT ci_id, offering, qid, x->>'message' AS msg, (x->>'points')::numeric AS pts
  FROM best, jsonb_array_elements(best.feedback->'results'->'tests') AS x
  WHERE x->>'name' IN ('Test deflation on given matrix M', 'Test function on given matrix M')
)
SELECT LEFT(regexp_replace(regexp_replace(msg, '[-0-9.e+]+', '#', 'g'), '\s+', ' ', 'g'), 200) AS msg_pattern, COUNT(*) AS n
FROM t WHERE qid = '12-Eigenvalues/Eigen-TwoLargestEig'
GROUP BY 1 ORDER BY 2 DESC LIMIT 12;
