-- NonlinearSolveND-NewtonSolve: first-submission Jacobian/iterate credit grouped by generated parameters
-- (number of nonzero x1*x2 cross-term coefficients; whether the start point uses +-2). Spring2025..Spring2026.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) v.params AS p, s.partial_scores AS ps
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id AND q.qid = '14-NonlinearSystems/NonlinearSolveND-NewtonSolve'
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026')
  ORDER BY iq.id, s.date
), g AS (
  SELECT
    ((p->'coeffs'->'_value'->0->>5)::int <> 0)::int + ((p->'coeffs'->'_value'->1->>5)::int <> 0)::int AS n_cross_terms,
    (abs((p->>'x')::int) = 2 OR abs((p->>'y')::int) = 2) AS start_has_2,
    (ps->'jac'->>'score')::numeric AS jac, (ps->'iterate'->>'score')::numeric AS it
  FROM firsts
)
SELECT 'cross_terms' AS grouping, n_cross_terms::text AS value, COUNT(*) AS n,
  ROUND(100*AVG(jac),1) AS first_jac_pct, ROUND(100*AVG(it),1) AS first_iterate_pct FROM g GROUP BY 1, 2
UNION ALL
SELECT 'start_has_2', start_has_2::text, COUNT(*), ROUND(100*AVG(jac),1), ROUND(100*AVG(it),1) FROM g GROUP BY 1, 2
ORDER BY 1, 2;
