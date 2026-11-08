-- Per-test results for the coding slots (last graded submission per assigned question),
-- Spring2025..Spring2026. Aggregates only.
WITH iqs AS (
  SELECT ci.short_name AS offering, split_part(q.qid, '/', 2) AS qid, iq.id AS iq_id
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026') AND ag.number IN (9, 10)
), last_sub AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.offering, iqs.qid, s.feedback
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.date DESC
)
SELECT qid, offering, t->>'name' AS test_name,
  COUNT(*) AS n,
  ROUND(100 * AVG((t->>'points')::numeric / NULLIF((t->>'max_points')::numeric, 0)), 1) AS mean_test_pct,
  ROUND(100 * AVG(((t->>'points')::numeric >= (t->>'max_points')::numeric)::int), 1) AS full_pct
FROM last_sub, jsonb_array_elements(feedback->'results'->'tests') AS t
GROUP BY 1, 2, 3 ORDER BY 1, 2, 3;
