SELECT ci.short_name, a.id, a.tid, (SELECT MIN((ai.date AT TIME ZONE 'America/Chicago')::date) FROM assessment_instances ai WHERE ai.assessment_id=a.id AND ai.include_in_statistics) first_day,
 (SELECT MAX((ai.date AT TIME ZONE 'America/Chicago')::date) FROM assessment_instances ai WHERE ai.assessment_id=a.id AND ai.include_in_statistics) last_day
FROM assessments a JOIN course_instances ci ON ci.id=a.course_instance_id
WHERE ci.id IN (158221,173734,190462,206303,225310) AND a.tid='quiz02' AND a.deleted_at IS NULL ORDER BY ci.id;
