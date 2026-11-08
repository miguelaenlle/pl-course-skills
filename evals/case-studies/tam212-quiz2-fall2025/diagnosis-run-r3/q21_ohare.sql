-- OhareTrackComputeA/R (Fall2025 quiz02): first graded submission categories with full denominators
WITH s AS (
  SELECT q.qid, v.params p, v.true_answer ta, sub.submitted_answer sa,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.date) AS rn
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions sub ON sub.variant_id = v.id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND sub.score IS NOT NULL AND q.qid LIKE 'OhareTrack%'
), f AS (
  SELECT qid,
    CASE WHEN qid='OhareTrackComputeA' THEN (sa->>'AVal')::float8 ELSE (sa->>'R')::float8 END sub,
    CASE WHEN qid='OhareTrackComputeA' THEN (ta->>'AVal')::float8 ELSE (ta->>'R')::float8 END tru,
    CASE WHEN qid='OhareTrackComputeA' THEN (p->>'radius')::float8 ELSE (p->>'A')::float8 END given
  FROM s WHERE rn = 1
)
SELECT qid, COUNT(*) n_first,
  ROUND(100*AVG((abs(sub-tru) <= 1e-5+0.01*abs(tru))::int),1) correct_pct,
  ROUND(100*AVG((abs(sub) < 1e-6)::int),1) entered_zero_pct,
  ROUND(100*AVG((abs(sub-given) <= 0.01*abs(given))::int),1) entered_given_value_pct,
  ROUND(100*AVG((abs(sub-tru/2) <= 0.01*abs(tru)/2 OR abs(sub-2*tru) <= 0.02*abs(tru))::int),1) off_by_factor2_pct
FROM f GROUP BY qid ORDER BY qid;
