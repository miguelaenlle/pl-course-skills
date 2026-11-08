-- Offerings of quiz4 (and similarly titled) across course instances of course 114
SELECT ci.id AS ci_id, ci.short_name, a.id AS assessment_id, a.tid, a.title, a.type, a.number,
  (SELECT COUNT(*) FROM assessment_instances ai WHERE ai.assessment_id = a.id AND ai.include_in_statistics) AS n_ai_stats,
  (SELECT COUNT(*) FROM assessment_instances ai WHERE ai.assessment_id = a.id) AS n_ai_all,
  (SELECT COUNT(DISTINCT ai.user_id) FROM assessment_instances ai WHERE ai.assessment_id = a.id AND ai.include_in_statistics) AS n_users_stats,
  a.multiple_instance
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
WHERE ci.course_id = 114 AND ci.deleted_at IS NULL
  AND (a.tid ILIKE 'quiz4%' OR a.title ILIKE 'Quiz 4%')
ORDER BY ci.id, a.tid;
