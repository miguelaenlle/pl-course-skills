-- (a) Slot 7 Eigen-ShiftedInversePowerItErrorEst: outcomes grouped by which other eigenvalue is closest to the shift.
--     Spring 2025, Fall 2025, Spring 2026, Fall 2026. First submission on each student's first variant.
WITH fs AS (
  SELECT DISTINCT ON (iq.id) ci.id AS ci_id, ci.short_name AS offering, v.params, s.score, iq.score_perc
  FROM assessments a
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND q.qid = '12-Eigenvalues/Eigen-ShiftedInversePowerItErrorEst'
  ORDER BY iq.id, s.date ASC
), g AS (
  SELECT offering, ci_id, score, score_perc,
    CASE WHEN abs((params->>'lm_1')::numeric - (params->>'shift')::numeric) < abs((params->>'lm_2')::numeric - (params->>'shift')::numeric)
         THEN 'lambda_1 closest to shift' ELSE 'lambda_2 closest to shift' END AS competitor
  FROM fs)
SELECT competitor, COUNT(*) AS n,
  ROUND(100 * AVG(score)::numeric, 1) AS first_sub_pct,
  ROUND(AVG(score_perc)::numeric, 1) AS final_pct
FROM g GROUP BY 1 ORDER BY 1;

-- same, per offering
WITH fs AS (
  SELECT DISTINCT ON (iq.id) ci.id AS ci_id, ci.short_name AS offering, v.params, s.score
  FROM assessments a
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND q.qid = '12-Eigenvalues/Eigen-ShiftedInversePowerItErrorEst'
  ORDER BY iq.id, s.date ASC)
SELECT offering,
  COUNT(*) FILTER (WHERE abs((params->>'lm_1')::numeric - (params->>'shift')::numeric) < abs((params->>'lm_2')::numeric - (params->>'shift')::numeric)) AS n_l1,
  ROUND(100 * AVG(score) FILTER (WHERE abs((params->>'lm_1')::numeric - (params->>'shift')::numeric) < abs((params->>'lm_2')::numeric - (params->>'shift')::numeric))::numeric, 1) AS first_pct_l1,
  COUNT(*) FILTER (WHERE abs((params->>'lm_1')::numeric - (params->>'shift')::numeric) >= abs((params->>'lm_2')::numeric - (params->>'shift')::numeric)) AS n_l2,
  ROUND(100 * AVG(score) FILTER (WHERE abs((params->>'lm_1')::numeric - (params->>'shift')::numeric) >= abs((params->>'lm_2')::numeric - (params->>'shift')::numeric))::numeric, 1) AS first_pct_l2
FROM fs GROUP BY ci_id, offering ORDER BY ci_id;

-- (b) Slot 1 Cond-ErrorBound-v1: what wrong first answers equal. Pooled over the four offerings.
WITH fs AS (
  SELECT DISTINCT ON (iq.id) v.params, s.score, (s.submitted_answer->>'delta_b_norm')::float AS ans
  FROM assessments a
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND q.qid = '10-Linsys-Conditioning/Cond-ErrorBound-v1'
    AND s.submitted_answer->>'delta_b_norm' ~ '^-?[0-9.]+(e-?[0-9]+)?$'
  ORDER BY iq.id, s.date ASC
), x AS (
  SELECT score, ans, (params->>'x_error')::float AS e, (params->>'b_norm')::float AS b, (params->>'cond_number')::float AS k FROM fs)
SELECT COUNT(*) AS n_first_subs,
  COUNT(*) FILTER (WHERE score >= 1) AS correct,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - e*b*k) <= 0.01*abs(e*b*k)) AS eq_err_times_b_times_cond,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - e*k) <= 0.01*abs(e*k)) AS eq_err_times_cond,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - e/k) <= 0.01*abs(e/k)) AS eq_err_over_cond,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - e*k/b) <= 0.01*abs(e*k/b)) AS eq_err_cond_over_b,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - e*b) <= 0.01*abs(e*b)) AS eq_err_times_b,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - b*k/e) <= 0.01*abs(b*k/e)) AS eq_b_cond_over_err,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - e/(k*b)) <= 0.01*abs(e/(k*b))) AS eq_err_over_cond_b
FROM x;

-- (c) same for Cond-ErrorBound-v2 for comparison
WITH fs AS (
  SELECT DISTINCT ON (iq.id) v.params, s.score, (s.submitted_answer->>'deltax_norm')::float AS ans
  FROM assessments a
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND q.qid = '10-Linsys-Conditioning/Cond-ErrorBound-v2'
    AND s.submitted_answer->>'deltax_norm' ~ '^-?[0-9.]+(e-?[0-9]+)?$'
  ORDER BY iq.id, s.date ASC
), x AS (
  SELECT score, ans, (params->>'r_norm')::float AS r, (params->>'cond_number')::float AS k FROM fs)
SELECT COUNT(*) AS n_first_subs, COUNT(*) FILTER (WHERE score >= 1) AS correct,
  COUNT(*) FILTER (WHERE score < 1 AND abs(ans - r/k) <= 0.01*abs(r/k)) AS eq_r_over_cond,
  COUNT(*) FILTER (WHERE score < 1 AND r = 0) AS r_is_zero_variants
FROM x;
