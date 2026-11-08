-- Which part of each coding test fails (last graded submission per assigned question).
-- Messages are classified by grader-generated substrings only; no message text is output.
WITH iqs AS (
  SELECT ci.short_name AS offering, split_part(q.qid, '/', 2) AS qid, iq.id AS iq_id
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026') AND ag.number = 10
), last_sub AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.qid, s.feedback
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.date DESC
), t AS (
  SELECT qid, x->>'name' AS test_name, COALESCE(x->>'message','') AS m, (x->>'points')::numeric AS p, (x->>'max_points')::numeric AS mp
  FROM last_sub, jsonb_array_elements(feedback->'results'->'tests') x
  WHERE x->>'name' <> 'Your code raised an Exception'
)
SELECT qid, test_name, COUNT(*) AS n,
  ROUND(100*AVG((m ILIKE '%''coords'' looks good%')::int),1) AS coords_ok,
  ROUND(100*AVG((m ~* '''(elevation|temperature)'' looks good')::int),1) AS value_ok,
  ROUND(100*AVG((m ~* 'type \(3rd value in tuple\) is correct')::int),1) AS type_ok,
  ROUND(100*AVG((m ILIKE '%not a string%')::int),1) AS type_not_str,
  ROUND(100*AVG((m ILIKE '%did not return a tuple%')::int),1) AS bad_tuple,
  ROUND(100*AVG((p = 0)::int),1) AS zero_pct
FROM t GROUP BY 1, 2 ORDER BY 1, 2;
