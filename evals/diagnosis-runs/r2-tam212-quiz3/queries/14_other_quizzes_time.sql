-- All six quizzes: mean score and time near the inferred 50-minute window, per offering.
SELECT a.tid, ci.short_name AS offering, COUNT(*) n,
  ROUND(AVG(ai.score_perc)::numeric,1) mean_pct,
  ROUND(((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration)))/60)::numeric,1) median_min,
  ROUND(100*AVG((EXTRACT(EPOCH FROM ai.duration)/60 >= 45)::int)::numeric,1) pct_45plus,
  ROUND(100*AVG((EXTRACT(EPOCH FROM ai.duration)/60 >= 48)::int)::numeric,1) pct_48plus
FROM course_instances ci
JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL
JOIN assessment_instances ai ON ai.assessment_id=a.id AND ai.include_in_statistics
WHERE ci.course_id=:course_id AND ci.short_name IN ('Sp24','Spring2025','Fall2025','Spring2026')
  AND a.tid IN ('quiz01','quiz02','quiz03','quiz04','quiz05','quiz06')
GROUP BY a.tid, ci.id, ci.short_name ORDER BY a.tid, ci.id;
