-- Share of graded submissions whose numeric answer is the exact negative of the correct answer (sign error),
-- for selected Quiz 4 questions. Aggregates only; no answers are output.
WITH s AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, q.qid, s.score, s.submitted_answer AS sa, s.true_answer AS ta
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026','Fall2026')
    AND q.qid IN ('constrainedMotionPistonVelo','rbmCircleChordConstraint','rodVelCircleConstraint','rbmTwoCornerConstraints')
), f AS (
  SELECT ci_id, offering, qid, score,
    CASE qid
      WHEN 'constrainedMotionPistonVelo' THEN
        (sa->>'ansValue') ~ '^-?[0-9.eE+-]+$' AND abs((sa->>'ansValue')::float8 + (ta->>'ansValue')::float8) <= 0.01*abs((ta->>'ansValue')::float8)
      WHEN 'rbmTwoCornerConstraints' THEN
        (sa->>'ansVelx') ~ '^-?[0-9.eE+-]+$' AND (sa->>'ansVely') ~ '^-?[0-9.eE+-]+$'
        AND abs((sa->>'ansVelx')::float8 + (ta->>'ansVelx')::float8) <= 0.01*abs((ta->>'ansVelx')::float8) + 1e-5
        AND abs((sa->>'ansVely')::float8 + (ta->>'ansVely')::float8) <= 0.01*abs((ta->>'ansVely')::float8) + 1e-5
        AND (abs((ta->>'ansVelx')::float8) + abs((ta->>'ansVely')::float8)) > 1e-9
      ELSE
        (sa->>'vQx') ~ '^-?[0-9.eE+-]+$' AND (sa->>'vQy') ~ '^-?[0-9.eE+-]+$'
        AND abs((sa->>'vQx')::float8 + (ta->>'vQx')::float8) <= 0.01*abs((ta->>'vQx')::float8) + 1e-5
        AND abs((sa->>'vQy')::float8 + (ta->>'vQy')::float8) <= 0.01*abs((ta->>'vQy')::float8) + 1e-5
        AND (abs((ta->>'vQx')::float8) + abs((ta->>'vQy')::float8)) > 1e-9
    END AS sign_flip,
    CASE WHEN qid = 'constrainedMotionPistonVelo' THEN
      (sa->>'ansValue') ~ '^-?[0-9.eE+-]+$' AND abs(abs((sa->>'ansValue')::float8) - abs((ta->>'ansValue')::float8)) > 0.01*abs((ta->>'ansValue')::float8)
    END AS piston_wrong_magnitude
  FROM s
)
SELECT offering, qid, COUNT(*) AS n_graded_subs,
  ROUND(100*AVG((score >= 1)::int)::numeric,1) AS correct_pct,
  ROUND(100*AVG((score < 1 AND sign_flip)::int)::numeric,1) AS exact_sign_flip_pct,
  ROUND(100*AVG((score < 1 AND piston_wrong_magnitude)::int)::numeric,1) AS piston_wrong_magnitude_pct
FROM f GROUP BY ci_id, offering, qid ORDER BY qid, ci_id;
