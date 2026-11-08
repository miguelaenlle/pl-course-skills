-- First graded submission: ratio of submitted answer to correct answer, rounded, top patterns per single-input question (aggregate counts only)
WITH s AS (
  SELECT q.qid, sub.submitted_answer, v.true_answer, v.params,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.date) AS rn
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions sub ON sub.variant_id = v.id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND sub.score IS NOT NULL
    AND q.qid IN ('OhareTrackComputeA','OhareTrackComputeR','particleVelOnExpnCurveSpeed','particleVelonTriCurveSpeed','particleVelComponentOnCurve','pinSlotAcclnMag')
), k AS (
  SELECT qid, (SELECT key FROM jsonb_object_keys(true_answer) AS key LIMIT 1) AS ans FROM s LIMIT 0
), r AS (
  SELECT qid, ans.key AS input,
    CASE WHEN (s.true_answer->>ans.key)::float8 = 0 THEN NULL
         ELSE ROUND(((s.submitted_answer->>ans.key)::float8 / (s.true_answer->>ans.key)::float8)::numeric, 2) END AS ratio
  FROM s, LATERAL jsonb_object_keys(s.true_answer) AS ans(key)
  WHERE s.rn = 1 AND (s.submitted_answer->>ans.key) ~ '^\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?\s*$'
)
SELECT qid, input, ratio, n, ROUND(100.0*n/SUM(n) OVER (PARTITION BY qid, input),1) AS pct FROM (
  SELECT qid, input, ratio, COUNT(*) AS n FROM r GROUP BY qid, input, ratio) x
WHERE n >= 2 ORDER BY qid, input, n DESC;
