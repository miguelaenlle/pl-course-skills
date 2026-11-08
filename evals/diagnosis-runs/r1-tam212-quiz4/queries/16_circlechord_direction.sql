-- rbmCircleChordConstraint: first-submission outcome and sign-flip rate by direction of P (aggregates only).
WITH s AS (
  SELECT ci.id AS ci_id, v.params->>'pDirection' AS dir, s.score, s.submitted_answer AS sa, s.true_answer AS ta,
         ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY s.date, s.id) AS k
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id AND q.qid = 'rbmCircleChordConstraint'
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026','Fall2026')
)
SELECT dir, COUNT(*) AS n_first_subs,
  ROUND(100*AVG((score >= 1)::int)::numeric,1) AS first_correct_pct,
  ROUND(100*AVG((score < 1
    AND (sa->>'vQx') ~ '^\s*-?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$' AND (sa->>'vQy') ~ '^\s*-?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$'
    AND abs((sa->>'vQx')::float8 + (ta->>'vQx')::float8) <= 0.01*abs((ta->>'vQx')::float8) + 1e-5
    AND abs((sa->>'vQy')::float8 + (ta->>'vQy')::float8) <= 0.01*abs((ta->>'vQy')::float8) + 1e-5)::int)::numeric,1) AS first_sub_sign_flip_pct
FROM s WHERE k = 1 GROUP BY dir ORDER BY dir;
