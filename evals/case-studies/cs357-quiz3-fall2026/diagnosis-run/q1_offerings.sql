SELECT c.id, c.short_name, c.uuid FROM courses c WHERE c.id = 114;
SELECT ci.id AS ci_id, ci.short_name, a.id AS a_id, a.tid, a.title, a.type,
  (SELECT COUNT(*) FROM assessment_instances ai WHERE ai.assessment_id = a.id AND ai.include_in_statistics) AS n_inst,
  (SELECT MIN(ai.date)::date FROM assessment_instances ai WHERE ai.assessment_id = a.id AND ai.include_in_statistics) AS first_start,
  (SELECT MAX(ai.date)::date FROM assessment_instances ai WHERE ai.assessment_id = a.id AND ai.include_in_statistics) AS last_start
FROM course_instances ci JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
WHERE ci.course_id = 114 AND ci.deleted_at IS NULL AND (a.tid ILIKE 'quiz3%' )
ORDER BY ci.id, a.tid;
