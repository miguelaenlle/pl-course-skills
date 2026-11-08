-- Most common grader messages on zero-credit tests in slot 10 (last graded submission),
-- normalized (digits removed, first 90 chars, newlines collapsed); only patterns seen >= 5 times.
WITH iqs AS (
  SELECT split_part(q.qid, '/', 2) AS qid, iq.id AS iq_id
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026') AND ag.number = :slot
), last_sub AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.qid, s.feedback
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.date DESC
)
SELECT qid, left(regexp_replace(regexp_replace(COALESCE(x->>'message',''), '[0-9.e+-]+', '#', 'g'), '\s+', ' ', 'g'), 90) AS msg, COUNT(*) AS n
FROM last_sub, jsonb_array_elements(feedback->'results'->'tests') x
WHERE (x->>'points')::numeric = 0
GROUP BY 1, 2 HAVING COUNT(*) >= 5 ORDER BY 1, 3 DESC;
