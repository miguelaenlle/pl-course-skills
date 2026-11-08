-- Zone 1 (non-coding) mean score by exam-day group: the single busiest start day vs all other days
WITH ai AS (
  SELECT ai.id, ai.assessment_id, (ai.date AT TIME ZONE 'America/Chicago')::date AS d
  FROM assessment_instances ai WHERE ai.assessment_id IN (2491236,2557983,2619950) AND ai.include_in_statistics
), main AS (
  SELECT DISTINCT ON (assessment_id) assessment_id, d FROM ai GROUP BY assessment_id, d ORDER BY assessment_id, COUNT(*) DESC
)
SELECT ci.short_name AS offering, CASE WHEN ai.d = main.d THEN 'main day' ELSE 'other days' END AS day_group,
  COUNT(DISTINCT ai.id) AS n_students,
  ROUND(AVG(iq.score_perc)::numeric,1) AS zone1_mean_pct
FROM ai JOIN main USING (assessment_id)
JOIN assessments a ON a.id=ai.assessment_id JOIN course_instances ci ON ci.id=a.course_instance_id
JOIN instance_questions iq ON iq.assessment_instance_id=ai.id
JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
JOIN alternative_groups ag ON ag.id=aq.alternative_group_id JOIN zones z ON z.id=ag.zone_id
WHERE z.number=1 AND aq.max_points>0
GROUP BY 1,2 ORDER BY 1,2;
