-- Why the 'roots' test fails on the secant coding slot (last graded submission per assigned question).
-- Classified by grader-generated substrings; no message text is output.
WITH iqs AS (
  SELECT ci.short_name AS offering, split_part(q.qid, '/', 2) AS qid, iq.id AS iq_id
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026') AND ag.number = 9
), last_sub AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.qid, s.feedback
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.date DESC
), t AS (
  SELECT qid, COALESCE(x->>'message','') AS m, (x->>'points')::numeric AS p
  FROM last_sub, jsonb_array_elements(feedback->'results'->'tests') x
  WHERE x->>'name' = 'roots'
)
SELECT qid, COUNT(*) AS n_graded,
  COUNT(*) FILTER (WHERE p > 0) AS n_pass,
  COUNT(*) FILTER (WHERE p = 0 AND m ILIKE '%wrong length%') AS fail_wrong_length,
  COUNT(*) FILTER (WHERE p = 0 AND m ILIKE '%wrong length%' AND m NOT ILIKE '%INCORRECT%') AS fail_length_only_all_entries_ok,
  COUNT(*) FILTER (WHERE p = 0 AND m NOT ILIKE '%wrong length%' AND m ILIKE '%INCORRECT%') AS fail_values_same_length,
  COUNT(*) FILTER (WHERE p = 0 AND m ~* 'roots\[0\] is INCORRECT') AS fail_first_entry_wrong,
  COUNT(*) FILTER (WHERE p = 0 AND m ~* '(is None|not defined|not a list|is empty)') AS fail_missing_or_empty,
  COUNT(*) FILTER (WHERE p = 0 AND m NOT ILIKE '%wrong length%' AND m NOT ILIKE '%INCORRECT%' AND m !~* '(is None|not defined|not a list|is empty)') AS fail_other
FROM t GROUP BY 1 ORDER BY 1;
