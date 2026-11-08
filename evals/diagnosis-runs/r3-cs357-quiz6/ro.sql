SELECT current_setting('transaction_read_only') AS ro;
SELECT ci.id, ci.short_name, ci.uuid, ci.course_id, c.short_name AS course FROM course_instances ci JOIN courses c ON c.id=ci.course_id WHERE ci.uuid IN ('15ac02d3-2532-418e-a625-1b3002c4a640','8f6e7316-47f0-4bb9-ac9a-ed9724e7d491','2a5d1565-f927-4d50-ab06-bed362abfc4f');
