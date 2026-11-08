-- polarForceRocket: classify each instance question's FIRST submission against predicted mistakes.
-- Aggregate counts only.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) ci.short_name AS offering, iq.id AS iq_id,
    (v.params->>'m')::float8 AS m, (v.params->>'c1')::float8 AS c1, (v.params->>'omega')::float8 AS w,
    (v.params->>'gf')::float8 AS gf, (v.params->>'thetaD')::float8 AS th,
    (v.true_answer->>'ansValue')::float8 AS truth,
    CASE WHEN s.submitted_answer->>'ansValue' ~ '^\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$'
         THEN (s.submitted_answer->>'ansValue')::float8 END AS x,
    s.score
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id=aq.question_id AND q.qid='polarForceRocket'
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  JOIN submissions s ON s.variant_id=v.id
  WHERE ci.course_id=:course_id AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
  ORDER BY iq.id, s.date, s.id
),
c AS (
  SELECT *,
    10 + c1*radians(th) AS r, 10 + c1*th AS r_deg FROM firsts
),
k AS (
  SELECT offering, x, score, truth,
    -m*r*w*w/1000 + gf AS correct,
    -m*r_deg*w*w/1000 + gf AS theta_in_degrees,
    -m*r*w*w/1000 - gf AS gravity_sign_flipped,
    -m*r*w*w/1000 AS gravity_omitted,
    m*r*w*w/1000 + gf AS centripetal_sign_flipped,
    m*r*w*w/1000 - gf AS overall_sign_flipped,
    -m*r*w*w + gf AS n_plus_kn_mixed,
    (-m*r*w*w + gf*1000) AS answer_in_newtons,
    gf AS thrust_equals_gravity,
    gf - m*((c1*w)^2 + (r*w)^2)/r/1000 AS uses_v2_over_r
  FROM c
)
SELECT offering, COUNT(*) AS n_first_submissions,
  ROUND(100*AVG((score>=1)::int)::numeric,1) AS first_correct_pct,
  ROUND(100*AVG((abs(correct-truth) <= 1e-6+1e-6*abs(truth))::int)::numeric,1) AS recompute_matches_truth_pct,
  ROUND(100*AVG((x IS NULL)::int)::numeric,1) AS non_numeric_pct,
  ROUND(100*AVG((abs(x-theta_in_degrees) <= 0.01*abs(theta_in_degrees)+1e-5)::int)::numeric,1) AS theta_in_degrees_pct,
  ROUND(100*AVG((abs(x-gravity_sign_flipped) <= 0.01*abs(gravity_sign_flipped)+1e-5)::int)::numeric,1) AS gravity_sign_flipped_pct,
  ROUND(100*AVG((abs(x-gravity_omitted) <= 0.01*abs(gravity_omitted)+1e-5)::int)::numeric,1) AS gravity_omitted_pct,
  ROUND(100*AVG((abs(x-centripetal_sign_flipped) <= 0.01*abs(centripetal_sign_flipped)+1e-5)::int)::numeric,1) AS centripetal_sign_flipped_pct,
  ROUND(100*AVG((abs(x-overall_sign_flipped) <= 0.01*abs(overall_sign_flipped)+1e-5)::int)::numeric,1) AS overall_sign_flipped_pct,
  ROUND(100*AVG((abs(x-n_plus_kn_mixed) <= 0.01*abs(n_plus_kn_mixed)+1e-5)::int)::numeric,1) AS n_plus_kn_mixed_pct,
  ROUND(100*AVG((abs(x-answer_in_newtons) <= 0.01*abs(answer_in_newtons)+1e-5)::int)::numeric,1) AS answer_in_newtons_pct,
  ROUND(100*AVG((abs(x-thrust_equals_gravity) <= 0.01*abs(thrust_equals_gravity)+1e-5)::int)::numeric,1) AS thrust_equals_gravity_pct,
  ROUND(100*AVG((abs(x-uses_v2_over_r) <= 0.01*abs(uses_v2_over_r)+1e-5)::int)::numeric,1) AS uses_v2_over_r_pct,
  ROUND(100*AVG((x>0)::int)::numeric,1) AS submitted_positive_pct,
  ROUND(100*AVG((correct<0)::int)::numeric,1) AS correct_answer_negative_pct
FROM k GROUP BY ROLLUP(offering) ORDER BY offering NULLS LAST;
