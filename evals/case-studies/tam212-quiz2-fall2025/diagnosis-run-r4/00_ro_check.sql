SELECT current_setting('transaction_read_only') AS ro;
SELECT id, course_id, short_name, long_name, uuid FROM course_instances WHERE uuid IN ('d025f803-1969-45fe-8818-edaab27aff1e','69c02cd6-9105-432f-8ce8-22e173a950d6','a68b940a-8775-4df4-bad9-862c39db7fa1','94c2a68e-cfee-4cd1-9d71-b7843957a759');
