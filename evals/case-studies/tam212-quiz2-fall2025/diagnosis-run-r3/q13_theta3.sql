-- thetaFunTAccln3 (Fall2025 quiz02): first graded submission vs correct answer and the answer predicted if angular acceleration (theta-double-dot) is dropped
WITH s AS (
  SELECT v.params p, v.true_answer ta, sub.submitted_answer sa,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.date) AS rn
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions sub ON sub.variant_id = v.id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND sub.score IS NOT NULL AND q.qid = 'thetaFunTAccln3'
), b AS (
  SELECT *, (p->>'constantO')::float8 c0, (p->>'constantI')::float8 ci, (p->>'coeff1')::float8 c1, (p->>'coeff2')::float8 c2,
    (p->>'power')::float8 pw, (p->>'time')::float8 t FROM s WHERE rn = 1
), d AS (
  SELECT *, c2*exp(pw*t) th, c2*pw*exp(pw*t) thd, c2*pw*pw*exp(pw*t) thdd FROM b
), e AS (
  SELECT *, c0*(ci+sin(c1*th)) r, c0*c1*cos(c1*th) r1, -c0*c1*c1*sin(c1*th) r2 FROM d
), f AS (
  SELECT *, (r1*thdd + r2*thd*thd) - r*thd*thd AS ar, r*thdd + 2*r1*thd*thd AS ath,
    r2*thd*thd - r*thd*thd AS ar_no, 2*r1*thd*thd AS ath_no,
    (sa->>'ansValue1')::float8 s1, (sa->>'ansValue2')::float8 s2, (ta->>'ansValue1')::float8 t1, (ta->>'ansValue2')::float8 t2
  FROM e
)
SELECT COUNT(*) n_first,
  ROUND(100*AVG((abs(ar-t1) <= 1e-6*greatest(1,abs(t1)) AND abs(ath-t2) <= 1e-6*greatest(1,abs(t2)))::int),1) AS recompute_matches_pct,
  ROUND(100*AVG((abs(s1-t1) <= 1e-5+0.01*abs(t1))::int),1) AS ar_correct_pct,
  ROUND(100*AVG((abs(s2-t2) <= 1e-5+0.01*abs(t2))::int),1) AS ath_correct_pct,
  ROUND(100*AVG((abs(s1-ar_no) <= 1e-5+0.01*abs(ar_no) AND abs(s1-t1) > 1e-5+0.01*abs(t1))::int),1) AS ar_matches_no_thetaddot_pct,
  ROUND(100*AVG((abs(s2-ath_no) <= 1e-5+0.01*abs(ath_no) AND abs(s2-t2) > 1e-5+0.01*abs(t2))::int),1) AS ath_matches_no_thetaddot_pct,
  ROUND(100*AVG((abs(t1) < 0.01 AND abs(t2) < 0.01)::int),1) AS tiny_answer_pct
FROM f;
