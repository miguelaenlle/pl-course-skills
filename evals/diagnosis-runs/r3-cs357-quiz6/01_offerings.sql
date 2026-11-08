SELECT ci.id AS ci_id, ci.short_name, a.id AS a_id, a.tid, a.uuid, a.title,
  COUNT(ai.id) FILTER (WHERE ai.include_in_statistics) AS n_students,
  MIN(ai.date) FILTER (WHERE ai.include_in_statistics)::date AS first_start,
  MAX(ai.date) FILTER (WHERE ai.include_in_statistics)::date AS last_start,
  ROUND(AVG(ai.score_perc) FILTER (WHERE ai.include_in_statistics)::numeric,1) AS mean_score,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration)) FILTER (WHERE ai.include_in_statistics)/60)::numeric,1) AS med_total_min,
  ROUND((PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration)) FILTER (WHERE ai.include_in_statistics)/60)::numeric,1) AS p90_total_min
FROM course_instances ci
JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL
LEFT JOIN assessment_instances ai ON ai.assessment_id=a.id
WHERE ci.course_id=114 AND ci.deleted_at IS NULL AND a.tid ILIKE 'quiz%'
GROUP BY ci.id, ci.short_name, a.id, a.tid, a.uuid, a.title
ORDER BY ci.id, a.tid;
