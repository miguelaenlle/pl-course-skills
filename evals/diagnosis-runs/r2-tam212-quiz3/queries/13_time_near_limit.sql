-- Share of quiz03 instances whose total duration is close to the apparent ~50-minute window (inferred, not from PrairieTest).
SELECT ci.short_name AS offering, COUNT(*) n,
  ROUND(100*AVG((EXTRACT(EPOCH FROM ai.duration)/60 >= 45)::int)::numeric,1) AS pct_45min_plus,
  ROUND(100*AVG((EXTRACT(EPOCH FROM ai.duration)/60 >= 48)::int)::numeric,1) AS pct_48min_plus,
  ROUND((PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration))/60)::numeric,1) AS p99_min
FROM course_instances ci
JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
JOIN assessment_instances ai ON ai.assessment_id=a.id AND ai.include_in_statistics
WHERE ci.course_id=:course_id AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
GROUP BY ci.id, ci.short_name ORDER BY ci.id;
