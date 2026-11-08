-- Aggregate profile of assessment instances for quiz04 / quiz04r, by offering and date.
SELECT ci.short_name, a.tid, (ai.date AT TIME ZONE 'America/Chicago')::date AS day,
       COUNT(*) AS n_instances, COUNT(DISTINCT COALESCE(ai.user_id, ai.team_id)) AS n_distinct_owners,
       ROUND(AVG(ai.score_perc)::numeric,1) AS mean_score, COUNT(*) FILTER (WHERE ai.open) AS n_open,
       ROUND(AVG(ai.number)::numeric,2) AS mean_instance_number
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_instances ai ON ai.assessment_id = a.id AND ai.include_in_statistics
WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2026','Fall2025','Spring2025','Fall2026','Su26')
  AND a.tid IN ('quiz04','quiz04r')
GROUP BY 1,2,3 ORDER BY 1,2,3;
-- Owners with more than one instance (count only)
SELECT ci.short_name, a.tid, COUNT(*) AS owners_with_multiple_instances
FROM (SELECT ai.assessment_id, ai.user_id FROM assessment_instances ai WHERE ai.include_in_statistics GROUP BY 1,2 HAVING COUNT(*)>1) x
JOIN assessments a ON a.id = x.assessment_id JOIN course_instances ci ON ci.id = a.course_instance_id
WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2026','Fall2025','Spring2025','Fall2026') AND a.tid IN ('quiz04','quiz04r')
GROUP BY 1,2;
