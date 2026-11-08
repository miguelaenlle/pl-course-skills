-- Quiz 5 assessment records across course instances of course 114, with instance counts
SELECT ci.id AS ci_id, ci.short_name, a.id AS a_id, a.tid, a.title, a.type,
  (SELECT COUNT(*) FROM assessment_instances ai WHERE ai.assessment_id = a.id AND ai.include_in_statistics) AS n_ai_stats,
  (SELECT COUNT(*) FROM assessment_instances ai WHERE ai.assessment_id = a.id) AS n_ai_all,
  (SELECT COUNT(*) FROM assessment_questions aq WHERE aq.assessment_id = a.id AND aq.deleted_at IS NULL) AS n_aq
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
WHERE ci.course_id = 114 AND ci.deleted_at IS NULL
  AND (a.tid ILIKE 'quiz5%' OR a.title ILIKE 'Quiz 5%')
ORDER BY ci.id, a.tid;
