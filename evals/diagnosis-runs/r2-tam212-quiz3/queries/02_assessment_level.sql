-- Assessment-level summary per offering (quiz03 and quiz03r)
SELECT ci.short_name AS offering, a.tid, a.max_points,
  COUNT(*) AS n_instances,
  ROUND(AVG(ai.score_perc)::numeric,1) AS mean_pct,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ai.score_perc))::numeric,1) AS median_pct,
  ROUND((100*AVG((ai.score_perc < 70)::int))::numeric,1) AS below70_pct,
  ROUND(((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration)))/60)::numeric,1) AS median_total_min,
  ROUND(((PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration)))/60)::numeric,1) AS p90_total_min,
  MIN(ai.date)::date AS first_start, MAX(ai.date)::date AS last_start,
  COUNT(DISTINCT ai.date::date) AS n_days
FROM course_instances ci
JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL
JOIN assessment_instances ai ON ai.assessment_id=a.id AND ai.include_in_statistics
WHERE ci.course_id=:course_id AND ci.deleted_at IS NULL
  AND a.tid IN ('quiz03','quiz03r','quiz02','quiz04')
  AND ci.short_name IN ('Sp24','Fa24','Spring2025','ZJUI-Spring2025','Fall2025','ZJUI-Spring2026','Spring2026','Fall2026')
GROUP BY ci.id, ci.short_name, a.tid, a.max_points
ORDER BY a.tid, ci.id;
