-- Fall2025: share of Quiz 2 takers who also took the Quiz 2 retake, by slot-6 draw (users matched in SQL; no identifiers output)
WITH q2 AS (
  SELECT ai.user_id, ai.score_perc,
    (SELECT q.qid FROM instance_questions iq JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
       JOIN alternative_groups ag ON ag.id=aq.alternative_group_id JOIN questions q ON q.id=aq.question_id
     WHERE iq.assessment_instance_id = ai.id AND ag.number = 6) AS slot6
  FROM assessment_instances ai WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics
), r AS (
  SELECT ai.user_id, ai.score_perc FROM assessment_instances ai WHERE ai.assessment_id = 2574215 AND ai.include_in_statistics
)
SELECT CASE WHEN slot6 LIKE 'Ohare%' THEN 'Ohare (A or R)' ELSE 'thetaFunTAccln1-3' END AS slot6_group,
  COUNT(*) n, ROUND(AVG(q2.score_perc)::numeric,1) quiz2_mean,
  ROUND(100*AVG((r.user_id IS NOT NULL)::int),1) took_retake_pct,
  ROUND(AVG(r.score_perc)::numeric,1) retake_mean
FROM q2 LEFT JOIN r USING (user_id) GROUP BY ROLLUP(1) ORDER BY 1;
