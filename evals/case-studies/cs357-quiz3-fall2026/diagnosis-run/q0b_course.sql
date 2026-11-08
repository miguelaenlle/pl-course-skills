SELECT c.id, c.short_name, c.title, c.uuid, c.repository, c.deleted_at IS NULL AS live FROM courses c WHERE c.short_name ILIKE '%357%' OR c.uuid::text LIKE '28d7be8c%';
SELECT ci.id, ci.course_id, ci.short_name, ci.uuid FROM course_instances ci WHERE ci.uuid = '15ac02d3-2532-418e-a625-1b3002c4a640';
