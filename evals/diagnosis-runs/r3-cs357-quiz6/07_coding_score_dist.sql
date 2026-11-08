-- Distribution of best score per assigned student, coding questions
SELECT iq.assessment_question_id AS aq_id, COUNT(*) AS n_assigned,
  COUNT(*) FILTER (WHERE iq.score_perc = 0 OR iq.score_perc IS NULL) AS n_zero,
  COUNT(*) FILTER (WHERE iq.score_perc > 0 AND iq.score_perc < 100) AS n_partial,
  COUNT(*) FILTER (WHERE iq.score_perc >= 100) AS n_full,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY iq.number_attempts) FILTER (WHERE iq.number_attempts>0))::numeric,1) AS med_attempts
FROM instance_questions iq
JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
WHERE iq.assessment_question_id IN (1574901765,1648711431,1986540840,1574901766,1648711433,1986540841,1582508050,1648711434,1986540842,1375473215,1648711438)
GROUP BY 1 ORDER BY 1;
