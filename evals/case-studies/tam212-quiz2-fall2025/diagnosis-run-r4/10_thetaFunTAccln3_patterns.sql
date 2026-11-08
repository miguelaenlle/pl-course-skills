-- thetaFunTAccln3 (theta = c2*exp(p*t), so theta-double-dot is not zero) vs the predicted mistake of dropping theta-double-dot terms
WITH first_sub AS (
  SELECT DISTINCT ON (iq.id) ci.id AS ci_id, ci.short_name AS offering, v.params p, v.true_answer ta, s.submitted_answer sa, iq.score_perc
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.score IS NOT NULL
  WHERE a.id IN (2434746, 2497144, 2574213, 2634479, 2716830) AND q.qid = 'thetaFunTAccln3'
  ORDER BY iq.id, s.date
), k AS (
  SELECT *, (p->>'constantO')::float8 O, (p->>'constantI')::float8 I, (p->>'coeff1')::float8 n,
    (p->>'coeff2')::float8 c2, (p->>'power')::float8 pw, (p->>'time')::float8 t,
    (ta->>'ansValue1')::float8 tar, (ta->>'ansValue2')::float8 tat,
    CASE WHEN sa->>'ansValue1' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ansValue1')::float8 END sar,
    CASE WHEN sa->>'ansValue2' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ansValue2')::float8 END sat
  FROM first_sub
), d AS (
  SELECT *, c2*exp(pw*t) th, c2*pw*exp(pw*t) thd, c2*pw*pw*exp(pw*t) thdd FROM k
), e AS (
  SELECT *, O*(I+sin(n*th)) r, O*n*cos(n*th) r1, -O*n*n*sin(n*th) r2 FROM d
), f AS (
  SELECT *,
    (r1*thdd + r2*thd*thd) - r*thd*thd AS ar_code, r*thdd + 2*r1*thd*thd AS at_code,
    r2*thd*thd - r*thd*thd AS ar_nothdd, 2*r1*thd*thd AS at_nothdd
  FROM e
)
SELECT offering,
  COUNT(*) AS n_first_submissions,
  SUM((abs(ar_code-tar) < 1e-6*(1+abs(tar)) AND abs(at_code-tat) < 1e-6*(1+abs(tat)))::int) AS n_key_matches_recomputed,
  ROUND(100*AVG((sar IS NOT NULL AND sat IS NOT NULL AND abs(sar-tar) <= 1e-5+0.01*abs(tar) AND abs(sat-tat) <= 1e-5+0.01*abs(tat))::int),1) AS pct_both_correct,
  ROUND(100*AVG((sar IS NOT NULL AND sat IS NOT NULL AND abs(sar-ar_nothdd) <= 1e-5+0.01*abs(ar_nothdd) AND abs(sat-at_nothdd) <= 1e-5+0.01*abs(at_nothdd)
       AND NOT (abs(sar-tar) <= 1e-5+0.01*abs(tar) AND abs(sat-tat) <= 1e-5+0.01*abs(tat)))::int),1) AS pct_match_dropped_thetaddot,
  ROUND(100*AVG((abs(ar_nothdd-tar) <= 1e-5+0.01*abs(tar) AND abs(at_nothdd-tat) <= 1e-5+0.01*abs(tat))::int),1) AS pct_variants_where_mistake_still_correct,
  ROUND(100*AVG((abs(tar) < 1e-3 AND abs(tat) < 1e-3)::int),1) AS pct_variants_answer_near_zero,
  ROUND(AVG(score_perc) FILTER (WHERE t = 1)::numeric,1) AS mean_final_t1,
  ROUND(AVG(score_perc) FILTER (WHERE t = 2)::numeric,1) AS mean_final_t2,
  ROUND(AVG(score_perc) FILTER (WHERE t >= 3)::numeric,1) AS mean_final_t3to4
FROM f GROUP BY ci_id, offering ORDER BY ci_id;
