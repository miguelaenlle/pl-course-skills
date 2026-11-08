SELECT current_setting('transaction_read_only') AS ro;
SELECT c.id, c.short_name FROM courses c WHERE c.uuid = '28d7be8c-4e01-41e0-bd6b-6827ef18aef9' AND c.deleted_at IS NULL;
