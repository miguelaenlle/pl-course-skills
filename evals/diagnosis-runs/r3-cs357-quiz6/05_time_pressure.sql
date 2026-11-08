-- Total assessment duration distribution, quizzes 4-6, recent offerings
SELECT ci.short_name AS offering, a.tid, a.max_points, COUNT(*) AS n,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration))/60)::numeric,1) AS med_min,
  ROUND((PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration))/60)::numeric,1) AS p90_min,
  ROUND((100*AVG((ai.duration >= interval '45 minutes')::int))::numeric,1) AS pct_ge45,
  ROUND((100*AVG((ai.duration >= interval '48 minutes')::int))::numeric,1) AS pct_ge48,
  ROUND(AVG(ai.score_perc)::numeric,1) AS mean_score
FROM assessments a JOIN course_instances ci ON ci.id=a.course_instance_id
JOIN assessment_instances ai ON ai.assessment_id=a.id AND ai.include_in_statistics
WHERE ci.course_id=114 AND a.tid IN ('quiz4','quiz5','quiz6') AND ci.id >= 129442
GROUP BY ci.id, ci.short_name, a.tid, a.max_points ORDER BY ci.id, a.tid;
