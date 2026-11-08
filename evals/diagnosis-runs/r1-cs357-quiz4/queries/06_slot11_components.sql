-- Slot 11 coding questions: which component of the given-matrix test students fail, on each student's
-- best graded submission. Spring 2025, Fall 2025, Spring 2026. Aggregate counts only.
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
SELECT offering, qid, COUNT(*) AS n,
  COUNT(*) FILTER (WHERE pts = 0) AS pts_0,
  COUNT(*) FILTER (WHERE pts > 0 AND pts < 0.5) AS pts_25,
  COUNT(*) FILTER (WHERE pts >= 0.5 AND pts < 0.75) AS pts_50,
  COUNT(*) FILTER (WHERE pts >= 0.75 AND pts < 1) AS pts_75,
  COUNT(*) FILTER (WHERE pts >= 1) AS pts_100,
  COUNT(*) FILTER (WHERE msg ~* '(v_max|vR) is inaccurate') AS first_vec_wrong,
  COUNT(*) FILTER (WHERE msg ~* '(v_2nd|vL) is inaccurate') AS second_vec_wrong,
  COUNT(*) FILTER (WHERE msg ~* 'must return|returns None') AS bad_return,
  COUNT(*) FILTER (WHERE msg ~* 'not allowed') AS used_disallowed
FROM t GROUP BY ci_id, offering, qid ORDER BY qid, ci_id;


