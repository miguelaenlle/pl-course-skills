-- Probe: JSON key names (not values) of submitted_answer / true_answer for FiniteDiff-Gradient-v2 in Spring2026.
SELECT DISTINCT (SELECT string_agg(k, ',' ORDER BY k) FROM jsonb_object_keys(s.submitted_answer) k) AS sub_keys,
  (SELECT string_agg(k, ',' ORDER BY k) FROM jsonb_object_keys(s.true_answer) k) AS true_keys,
  jsonb_typeof(s.true_answer->'vec') AS true_vec_type
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.tid = 'quiz5' AND a.deleted_at IS NULL
JOIN assessment_questions aq ON aq.assessment_id = a.id
JOIN questions q ON q.id = aq.question_id AND q.qid = '06-TaylorSeries/FiniteDiff-Gradient-v2'
JOIN instance_questions iq ON iq.assessment_question_id = aq.id
JOIN variants v ON v.instance_question_id = iq.id
JOIN submissions s ON s.variant_id = v.id
WHERE ci.course_id = 114 AND ci.short_name = 'Spring2026'
LIMIT 5;
