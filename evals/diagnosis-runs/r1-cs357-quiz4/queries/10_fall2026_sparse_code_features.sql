-- Fall 2026 new sparse coding questions: crude text features of each student's best graded submission,
-- grouped by outcome of the final (40%) test. Counts only; no code is output.
WITH iqs AS (
  SELECT q.qid, iq.id AS iq_id FROM assessment_questions aq JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id = 2713999 AND aq.deleted_at IS NULL AND q.qid LIKE '11-Sparse/Sparse-COO-%'),
best AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.qid, s.feedback,
    convert_from(decode(s.submitted_answer->'_files'->0->>'contents', 'base64'), 'UTF8') AS code
  FROM iqs JOIN variants v ON v.instance_question_id = iqs.iq_id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  ORDER BY iqs.iq_id, s.score DESC NULLS LAST, s.date DESC),
f AS (
  SELECT qid,
    (SELECT t->>'message' FROM jsonb_array_elements(feedback->'results'->'tests') t ORDER BY (t->>'max_points')::numeric DESC NULLS LAST LIMIT 1) AS final_msg,
    (SELECT t->>'message' FROM jsonb_array_elements(feedback->'results'->'tests') t WHERE t->>'name' LIKE '%row and column%' LIMIT 1) AS coord_msg,
    code ~ '(mixed_signal|totals|net_change)\s*=\s*\.\.\.' AS task2_placeholder_left,
    code ~ 'enumerate\(\s*(sorted\()?\s*(channel_index|nutrient_index|center_index)(\.keys\(\))?\s*\)?\s*\)|list\(\s*(channel_index|nutrient_index|center_index)(\.keys\(\))?\s*\)|(channel_index|nutrient_index|center_index)\.keys\(\)\s*\)?\s*\.index' AS uses_dict_position,
    code ~ 'max\(\s*row' AS sizes_by_max_row
  FROM best)
SELECT
  CASE WHEN final_msg LIKE 'Correct % for 5 of 5%' THEN '1 final test: all 5 cases'
       WHEN final_msg LIKE 'Correct % for 1 of 5%' THEN '2 final test: only 1 of 5 cases'
       WHEN final_msg LIKE '%must be one-dimensional%' THEN '3 final test: output not a 1-D array'
       WHEN final_msg LIKE 'Task 2 must compute%' THEN '4 final test: dense-operation check'
       WHEN final_msg LIKE '%skipped%' OR coord_msg LIKE '%failed with an exception%' THEN '5 exception / skipped'
       ELSE '6 other' END AS outcome,
  COUNT(*) AS n,
  COUNT(*) FILTER (WHERE task2_placeholder_left) AS n_task2_placeholder_left,
  COUNT(*) FILTER (WHERE uses_dict_position) AS n_uses_dict_position,
  COUNT(*) FILTER (WHERE sizes_by_max_row) AS n_sizes_by_max_row,
  COUNT(*) FILTER (WHERE coord_msg LIKE 'Correct COO coordinates for 1 of 4%') AS n_coords_only_example_case
FROM f GROUP BY 1 ORDER BY 1;
