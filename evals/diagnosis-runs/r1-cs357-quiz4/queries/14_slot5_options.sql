-- Slot 5 checkbox questions: selection rate of each option on first submissions, with whether the option is correct.
-- Pooled over Spring 2025, Fall 2025, Spring 2026, Fall 2026. Option text truncated.
WITH fs AS (
  SELECT DISTINCT ON (iq.id) q.qid, v.params, v.true_answer, s.submitted_answer, s.score
  FROM assessments a
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999)
    AND q.qid IN ('12-Eigenvalues/Eigen-PowerIterationConvergence', '12-Eigenvalues/Iteration-Mixed-Concepts')
  ORDER BY iq.id, s.date ASC
), opts AS (
  SELECT fs.qid, o->>'key' AS key, (fs.true_answer->(CASE WHEN fs.qid LIKE '%Mixed%' THEN 'students' ELSE 'student' END)) @> jsonb_build_array(jsonb_build_object('key', o->>'key')) AS correct,
    LEFT(regexp_replace(o->>'html', '\s+', ' ', 'g'), 110) AS option_text,
    COALESCE(fs.submitted_answer->(CASE WHEN fs.qid LIKE '%Mixed%' THEN 'students' ELSE 'student' END), '[]'::jsonb) AS chosen
  FROM fs, jsonb_array_elements(fs.params->(CASE WHEN fs.qid LIKE '%Mixed%' THEN 'students' ELSE 'student' END)) AS o
)
SELECT qid, option_text, correct, COUNT(*) AS n_shown,
  ROUND(100 * AVG((chosen ? key)::int)::numeric, 1) AS pct_selected,
  ROUND(100 * AVG(((chosen ? key) = correct)::int)::numeric, 1) AS pct_marked_right
FROM opts GROUP BY 1, 2, 3 ORDER BY 1, 6;
