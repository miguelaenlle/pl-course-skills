-- Per-test pass rates on each student's best-scoring graded submission (coding slots 11-12),
-- Spring 2025, Fall 2025, Spring 2026, Fall 2026. Aggregate only.
WITH iqs AS (
  SELECT ci.short_name AS offering, ci.id AS ci_id, q.qid, iq.id AS iq_id
  FROM assessments a
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND ag.number IN (11, 12)
),
best AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.offering, iqs.ci_id, iqs.qid, s.feedback
  FROM iqs
  JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.score DESC NULLS LAST, s.date DESC
)
SELECT offering, qid, t->>'name' AS test_name,
  MAX((t->>'max_points')::numeric) AS max_pts,
  COUNT(*) AS n_students,
  ROUND(100 * AVG(((t->>'points')::numeric >= (t->>'max_points')::numeric)::int), 1) AS pass_pct
FROM best, jsonb_array_elements(best.feedback->'results'->'tests') AS t
GROUP BY ci_id, offering, qid, t->>'name'
ORDER BY qid, ci_id, MIN(t->>'name');
