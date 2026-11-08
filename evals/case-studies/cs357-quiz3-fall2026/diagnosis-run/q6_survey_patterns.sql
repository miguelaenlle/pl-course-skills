\echo == SurveyElevations: code patterns on best submission, by A-test outcome (counts only)
WITH aqs AS (SELECT aq.id FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id WHERE aq.assessment_id=2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations'),
best AS (
  SELECT DISTINCT ON (iq.id) s.feedback, s.submitted_answer
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.feedback ? 'results'
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC),
code AS (
  SELECT b.feedback, convert_from(decode(f->>'contents','base64'),'UTF8') AS src
  FROM best b, LATERAL jsonb_array_elements(b.submitted_answer->'_files') f WHERE f->>'name'='user_code.py'),
cls AS (
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM jsonb_array_elements(feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A' AND t->>'message' LIKE 'A is correct%') THEN 'A correct'
    WHEN EXISTS (SELECT 1 FROM jsonb_array_elements(feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A' AND t->>'message' ~ '^0 of') THEN 'A 0 rows'
    WHEN EXISTS (SELECT 1 FROM jsonb_array_elements(feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A' AND t->>'message' ~ '^[0-9]+ of') THEN 'A some rows'
    ELSE 'A other' END AS a_cls, src FROM code)
SELECT a_cls, COUNT(*) AS n,
  SUM((src ~ 'A\s*\[\s*0\s*[,\]]')::int) AS writes_row0_literal,
  SUM((src ~ 'A\s*\[\s*(-1|n\s*-\s*1|len\([a-z_]+\)\s*-\s*1|num[a-z_]*\s*-\s*1)\s*[,\]]')::int) AS writes_last_row,
  SUM((src ~ '(vstack|insert|append|concatenate|r_\[)')::int) AS stacks_rows,
  SUM((src ~ '\.T\b|transpose')::int) AS uses_transpose,
  SUM((src ~ '\[\s*[a-z_]+\s*\[\s*start\s*\]\s*\]\s*=\s*-\s*1|\[\s*[a-z_]+\s*,\s*[a-z_]*\[?\s*start\s*\]?\s*\]\s*=\s*-\s*1|index\(\s*start\s*\)\s*\]\s*=\s*-\s*1')::int) AS start_gets_minus1,
  SUM((src ~ 'index\(\s*end\s*\)\s*\]\s*=\s*-\s*1|\[\s*[a-z_]+\s*,\s*[a-z_]*\[?\s*end\s*\]?\s*\]\s*=\s*-\s*1')::int) AS end_gets_minus1,
  SUM((src ~ '(for|in)[^\n]*(sorted|sort\()' OR src ~ '\.sort\(')::int) AS sorts_something,
  SUM((src ~ 'enumerate\(\s*measurements')::int) AS enumerate_measurements,
  SUM((src ~ 'measurements\s*\[')::int) AS indexes_measurements
FROM cls GROUP BY a_cls ORDER BY a_cls;
