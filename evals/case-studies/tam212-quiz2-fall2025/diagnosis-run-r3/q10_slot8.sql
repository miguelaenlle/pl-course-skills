-- Slot 8 (Fall2025 quiz02): first graded submission categories, split by whether the correct answer is zero
WITH s AS (
  SELECT q.qid, iq.id AS iq_id, iq.points, aq.max_points,
    (sub.submitted_answer->>k.key) AS sa_txt, (v.true_answer->>k.key)::float8 AS ta,
    COALESCE((v.params->>'speed')::float8, (v.params->>'veloc')::float8) AS speed,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.date) AS rn
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions sub ON sub.variant_id = v.id
  CROSS JOIN LATERAL (SELECT key FROM jsonb_object_keys(v.true_answer) AS key LIMIT 1) AS k
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND sub.score IS NOT NULL
    AND q.qid IN ('particleVelOnExpnCurveSpeed','particleVelonTriCurveSpeed','particleVelComponentOnCurve')
), f AS (
  SELECT *, CASE WHEN sa_txt ~ '^\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$' THEN sa_txt::float8 END AS sa FROM s WHERE rn = 1
)
SELECT qid, (abs(ta) < 1e-9) AS answer_is_zero, COUNT(*) AS n_first,
  ROUND(100*AVG((abs(sa-ta) <= 1e-5 + 0.01*abs(ta))::int),1) AS first_correct_pct,
  ROUND(100*AVG((abs(ta) > 1e-9 AND abs(sa+ta) <= 1e-5 + 0.01*abs(ta))::int),1) AS sign_flip_pct,
  ROUND(100*AVG((abs(abs(sa)-speed) <= 0.01*speed AND abs(abs(ta)-speed) > 0.01*speed)::int),1) AS gave_speed_pct
FROM f GROUP BY 1,2 ORDER BY 1,2;
