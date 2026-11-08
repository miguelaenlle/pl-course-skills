-- thetaFunTAccln1-3 (Fall2025 quiz02): first graded submission, ratio of submitted to correct per input, binned (aggregate)
WITH s AS (
  SELECT q.qid, v.true_answer ta, sub.submitted_answer sa,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.date) AS rn
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions sub ON sub.variant_id = v.id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND sub.score IS NOT NULL AND q.qid LIKE 'thetaFunTAccln%'
), r AS (
  SELECT qid, k AS input, (sa->>k)::float8 / NULLIF((ta->>k)::float8,0) AS ratio
  FROM s, unnest(ARRAY['ansValue1','ansValue2']) k WHERE rn = 1
)
SELECT qid, input, COUNT(*) n,
  ROUND(100*AVG((abs(ratio-1) <= 0.01)::int),1) AS within_1pct,
  ROUND(100*AVG((abs(ratio-1) > 0.01 AND abs(ratio-1) <= 0.10)::int),1) AS near_miss_1_10pct,
  ROUND(100*AVG((abs(ratio+1) <= 0.01)::int),1) AS sign_flip,
  ROUND(100*AVG((abs(ratio) < 0.01)::int),1) AS near_zero,
  ROUND(100*AVG((abs(ratio-1) > 0.10 AND abs(ratio+1) > 0.01 AND abs(ratio) >= 0.01)::int),1) AS other
FROM r GROUP BY 1,2 ORDER BY 1,2;
