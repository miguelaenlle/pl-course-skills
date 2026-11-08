-- Squirrels best submissions: code-feature counts by M-test outcome (code decoded in-database; never output)
WITH best AS (
  SELECT DISTINCT ON (iq.id) s.feedback, s.submitted_answer
  FROM instance_questions AS iq
  JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
  JOIN questions q ON q.id=aq.question_id
  JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants AS v ON v.instance_question_id = iq.id
  JOIN submissions AS s ON s.variant_id = v.id AND s.feedback ? 'results'
  WHERE aq.assessment_id IN (2491236,2557983,2619950)
    AND q.qid = '17-LinearLeastSquares/LeastSquares-Squirrels'
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC
), coded AS (
  SELECT
    (SELECT CASE WHEN t->>'message' LIKE '%inaccurate%' THEN 'M inaccurate'
                 WHEN (t->>'points')::numeric >= (t->>'max_points')::numeric THEN 'M correct'
                 ELSE 'M other failure' END
     FROM jsonb_array_elements(feedback->'results'->'tests') t WHERE t->>'name'='Check matrix M') AS m_outcome,
    regexp_replace(convert_from(decode(f->>'contents','base64'),'UTF8'), '\s+', '', 'g') AS code
  FROM best, LATERAL jsonb_array_elements(submitted_answer->'_files') f
  WHERE f->>'name' = 'user_code.py'
)
SELECT m_outcome, COUNT(*) AS n,
  COUNT(*) FILTER (WHERE code ~ 'features\[[^]]*,0\]-features\[[^]]*,1\]') AS peanuts_minus_students,
  COUNT(*) FILTER (WHERE code ~ 'features\[[^]]*,1\]-features\[[^]]*,0\]') AS students_minus_peanuts,
  COUNT(*) FILTER (WHERE code ~ '(column_stack|vstack|hstack|array)\(\[?\(?(np\.)?ones') AS ones_column_first,
  COUNT(*) FILTER (WHERE code ~ 'squirrel_minutes\[1:\]') AS b_from_day2,
  COUNT(*) FILTER (WHERE code ~ 'lstsq') AS uses_lstsq
FROM coded GROUP BY 1 ORDER BY 1;
