SELECT ci.id, ci.course_id, ci.short_name, ci.long_name, ci.uuid, ci.deleted_at IS NULL AS live
FROM course_instances ci
WHERE ci.course_id = (SELECT course_id FROM course_instances WHERE uuid = 'd025f803-1969-45fe-8818-edaab27aff1e')
ORDER BY ci.id;
