-- constrainedMotionPistonVelo: classify incorrect graded submissions against predicted mistakes (aggregates only).
-- Correct: v = omega * d/dtheta [ l1 cos th + sqrt(l2^2 - l1^2 sin^2 th) ]
WITH s AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, s.score,
    (s.submitted_answer->>'ansValue') AS ans_txt,
    (v.params->>'l1')::float8 AS l1, (v.params->>'l2')::float8 AS l2,
    (v.params->>'omega')::float8 AS w, (v.params->>'thetaD')::float8 AS td,
    (s.true_answer->>'ansValue')::float8 AS truth
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id AND q.qid = 'constrainedMotionPistonVelo'
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026','Fall2026')
), c AS (
  SELECT *, CASE WHEN ans_txt ~ '^\s*-?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$' THEN ans_txt::float8 END AS ans,
    w*(-l1*sin(radians(td)) - l1*l1*sin(radians(td))*cos(radians(td))/sqrt(l2*l2 - power(l1*sin(radians(td)),2))) AS chk_correct,
    w*(-l1*sin(td) - l1*l1*sin(td)*cos(td)/sqrt(l2*l2 - power(l1*sin(td),2))) AS deg_as_rad,
    -w*l1*sin(radians(td)) AS vB_x_only,
    w*l1 AS vB_mag
  FROM s
), m AS (
  SELECT *, (ans IS NOT NULL AND abs(ans - x) <= 0.01*abs(x)) AS dummy FROM c, LATERAL (SELECT 0::float8 AS x) z
)
SELECT offering,
  COUNT(*) AS n_graded_subs,
  COUNT(*) FILTER (WHERE score < 1) AS n_incorrect,
  ROUND(100*AVG((abs(chk_correct - truth) <= 1e-6*abs(truth))::int)::numeric,1) AS formula_check_pct,
  ROUND(100.0*COUNT(*) FILTER (WHERE score < 1 AND ans IS NULL)/NULLIF(COUNT(*) FILTER (WHERE score<1),0),1) AS unparsable_pct_of_incorrect,
  ROUND(100.0*COUNT(*) FILTER (WHERE score < 1 AND abs(ans - deg_as_rad) <= 0.01*abs(deg_as_rad))/NULLIF(COUNT(*) FILTER (WHERE score<1),0),1) AS degrees_as_radians_pct,
  ROUND(100.0*COUNT(*) FILTER (WHERE score < 1 AND abs(ans + deg_as_rad) <= 0.01*abs(deg_as_rad))/NULLIF(COUNT(*) FILTER (WHERE score<1),0),1) AS degrees_as_radians_neg_pct,
  ROUND(100.0*COUNT(*) FILTER (WHERE score < 1 AND abs(abs(ans) - abs(vB_x_only)) <= 0.01*abs(vB_x_only))/NULLIF(COUNT(*) FILTER (WHERE score<1),0),1) AS vB_x_only_pct,
  ROUND(100.0*COUNT(*) FILTER (WHERE score < 1 AND abs(abs(ans) - abs(vB_mag)) <= 0.01*abs(vB_mag))/NULLIF(COUNT(*) FILTER (WHERE score<1),0),1) AS vB_magnitude_pct,
  ROUND(100.0*COUNT(*) FILTER (WHERE score < 1 AND abs(ans) > 0 AND abs(truth) > 0 AND abs(ans/truth) BETWEEN 0.98 AND 1.02)/NULLIF(COUNT(*) FILTER (WHERE score<1),0),1) AS within_2pct_pct_of_incorrect
FROM c GROUP BY ci_id, offering ORDER BY ci_id;
