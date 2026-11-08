-- particleVelComponentOnCurve (Fall2025 quiz02): final score by which component was asked (last variant per instance question)
WITH x AS (
  SELECT DISTINCT ON (iq.id) iq.score_perc, v.params->>'velocType' vt
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND q.qid = 'particleVelComponentOnCurve'
  ORDER BY iq.id, v.date DESC
)
SELECT vt, COUNT(*) n, ROUND(AVG(score_perc)::numeric,1) mean_final_pct FROM x GROUP BY vt ORDER BY vt;
