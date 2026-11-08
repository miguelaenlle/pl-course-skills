\echo == Fall2026 coding slots: assignment and pre-override best score by start day group
SELECT q.qid, CASE WHEN ai.date::date <= '2026-10-13' THEN 'a: Oct 6-13' WHEN ai.date::date = '2026-10-14' THEN 'b: Oct 14' ELSE 'c: Oct 15-17' END AS days,
  COUNT(*) AS n, ROUND((100*AVG(COALESCE(iq.max_submission_score,0)))::numeric,1) AS mean_best_pct, ROUND(AVG(iq.score_perc)::numeric,1) AS mean_final_pct,
  ROUND((100*AVG((NOT COALESCE(iq.some_submission,false))::int))::numeric,1) AS no_sub_pct
FROM instance_questions iq JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE aq.assessment_id = 2713997 AND q.qid IN ('07-Random-MonteCarlo/MC-ArcadePrizeProbability','07-Random-MonteCarlo/MC-TreasureKeyProbability','09-Linsys/Linsys-MenuPrices','09-Linsys/Linsys-SurveyElevations')
GROUP BY 1,2 ORDER BY 1,2;
\echo == Fall2026: did students with no submission on SurveyElevations receive the bump?
SELECT COALESCE(iq.some_submission,false) AS submitted, ROUND(iq.score_perc/5)*5 AS final_b, COUNT(*)
FROM instance_questions iq JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE aq.assessment_id = 2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations' GROUP BY 1,2 ORDER BY 1,2;
