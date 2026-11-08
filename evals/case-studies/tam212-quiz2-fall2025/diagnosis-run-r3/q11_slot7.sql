-- Slot 7 pinSlotAcclnMag vs polarAcclnTelescopicArm (same generator, magnitude vs components), Fall2025 quiz02.
-- Recompute the answer from params, plus predicted wrong answers; aggregate first graded submission categories.
WITH s AS (
  SELECT q.qid, iq.id AS iq_id, iq.score_perc, v.params p, sub.submitted_answer sa, v.true_answer ta, sub.score,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.date) AS rn
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions sub ON sub.variant_id = v.id
  WHERE ai.assessment_id = :aid AND ai.include_in_statistics AND sub.score IS NOT NULL
    AND q.qid IN ('pinSlotAcclnMag','polarAcclnTelescopicArm')
), b AS (
  SELECT *, radians((p->>'theta')::float8) th, (p->>'coefficient')::float8 c, (p->>'coeff')::float8 k, (p->>'constant')::float8 c0,
    (p->>'thetadot')::float8 w, (p->>'thetaddot')::float8 al_mag, p->>'rate' rate, p->>'fun' fun
  FROM s WHERE rn = 1
), d AS (
  SELECT *,
    CASE WHEN fun='sin' THEN c0 + k*sin(c*th) ELSE c0 + k*cos(c*th) END r,
    CASE WHEN fun='sin' THEN k*c*cos(c*th) ELSE -k*c*sin(c*th) END r1,
    CASE WHEN fun='sin' THEN -k*c*c*sin(c*th) ELSE -k*c*c*cos(c*th) END r2,
    CASE WHEN rate='increasing' THEN al_mag ELSE -al_mag END al
  FROM b
), e AS (
  SELECT *,
    (r1*al + r2*w*w) - r*w*w AS ar, r*al + 2*r1*w*w AS ath,
    (r1*(-al) + r2*w*w) - r*w*w AS ar_flip, r*(-al) + 2*r1*w*w AS ath_flip,
    (r2*w*w) - r*w*w AS ar_noal, 2*r1*w*w AS ath_noal
  FROM d
), m AS (
  SELECT qid, rate, score,
    CASE WHEN qid='pinSlotAcclnMag' THEN (sa->>'ansValue')::float8 END AS mag_sub,
    sqrt(ar*ar+ath*ath) mag, sqrt(ar_flip*ar_flip+ath_flip*ath_flip) mag_flip, sqrt(ar_noal*ar_noal+ath_noal*ath_noal) mag_noal,
    CASE WHEN qid='polarAcclnTelescopicArm' THEN (sa->>'ansValue1')::float8 END AS ar_sub,
    CASE WHEN qid='polarAcclnTelescopicArm' THEN (sa->>'ansValue2')::float8 END AS ath_sub,
    ar, ath, ar_flip, ath_flip, (ta->>'ansValue')::float8 ta_mag, (ta->>'ansValue1')::float8 ta_ar,
    (r < 0) AS neg_r
  FROM e
)
SELECT qid, rate, COUNT(*) n_first,
  ROUND(100*AVG((score >= 1)::int),1) AS first_all_correct_pct,
  ROUND(100*AVG(CASE WHEN qid='pinSlotAcclnMag' THEN (abs(mag - ta_mag) < 1e-6)::int ELSE (abs(ar-ta_ar) < 1e-6)::int END),1) AS recompute_matches_pct,
  ROUND(100*AVG(CASE WHEN qid='pinSlotAcclnMag' THEN (abs(mag_sub - mag_flip) <= 0.01*mag_flip AND abs(mag_flip-mag) > 0.01*mag)::int
                     ELSE (abs(ath_sub - ath_flip) <= 0.01*abs(ath_flip) AND abs(ath_flip-ath) > 0.01*abs(ath))::int END),1) AS alpha_sign_flip_pct,
  ROUND(100*AVG(CASE WHEN qid='pinSlotAcclnMag' THEN (abs(mag_sub - mag_noal) <= 0.01*mag_noal)::int
                     ELSE NULL END),1) AS alpha_ignored_pct,
  ROUND(100*AVG(neg_r::int),1) AS neg_r_pct
FROM m GROUP BY ROLLUP(qid, rate) HAVING qid IS NOT NULL ORDER BY qid, rate;
