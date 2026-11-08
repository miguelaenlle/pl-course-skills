-- Slot 8 final points by whether the variant's correct answer is zero (last variant of each instance question)
WITH x AS (
  SELECT DISTINCT ON (iq.id) q.qid, iq.score_perc, (v.true_answer->>(SELECT key FROM jsonb_object_keys(v.true_answer) AS key LIMIT 1))::float8 AS ta
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  WHERE ai.assessment_id = :aid AND ai.include_in_statistics
    AND q.qid IN ('particleVelOnExpnCurveSpeed','particleVelonTriCurveSpeed','particleVelComponentOnCurve')
  ORDER BY iq.id, v.date DESC
)
SELECT qid, (abs(ta) < 1e-9) AS answer_is_zero, COUNT(*) AS n, ROUND(AVG(score_perc)::numeric,1) AS mean_final_pct
FROM x GROUP BY 1,2 ORDER BY 1,2;
