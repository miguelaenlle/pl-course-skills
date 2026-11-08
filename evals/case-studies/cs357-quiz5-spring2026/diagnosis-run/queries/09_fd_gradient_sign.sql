-- Slot 2 (FD gradient): classify each student's FIRST graded submission as correct, sign-flipped
-- (every component equals minus the correct value, within the question's tolerance), or other.
-- Fall2023..Spring2026. Aggregates only.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) iq.id AS k, split_part(q.qid, '/', 2) AS qid,
    s.submitted_answer AS sa, s.true_answer->'vec'->'_value' AS tv, s.score
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id AND q.qid IN ('06-TaylorSeries/FiniteDiff-Gradient', '06-TaylorSeries/FiniteDiff-Gradient-v2')
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 114 AND ci.short_name IN ('Fall2023','Spring2024','Fall2024','Spring2025','Fall2025','Spring2026')
  ORDER BY iq.id, s.date
), comp AS (
  SELECT k, qid, score,
    CASE WHEN (sa->>('vec' || i)) ~ '^\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$' THEN (sa->>('vec' || i))::float8 END AS s_val,
    (tv->(i-1)->>0)::float8 AS t_val
  FROM firsts, generate_series(1, 3) AS i
), per_sub AS (
  SELECT k, qid, score,
    bool_and(s_val IS NOT NULL AND abs(s_val - t_val) <= 1e-2 + 1e-3 * abs(t_val)) AS all_ok,
    bool_and(s_val IS NOT NULL AND abs(s_val + t_val) <= 1e-2 + 1e-3 * abs(t_val)) AND bool_or(abs(t_val) > 1e-2) AS all_flipped
  FROM comp GROUP BY k, qid, score
)
SELECT qid, COUNT(*) AS n_first_subs,
  ROUND(100 * AVG(all_ok::int), 1) AS first_all_correct_pct,
  ROUND(100 * AVG(all_flipped::int), 1) AS first_sign_flipped_pct,
  ROUND((100 * AVG(score))::numeric, 1) AS mean_first_score_pct
FROM per_sub GROUP BY qid ORDER BY qid;
