\echo == SurveyElevations & MenuPrices: per-submission code features (best submission), aggregated by A outcome
WITH aqs AS (SELECT aq.id, q.qid FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id WHERE aq.assessment_id=2713997 AND q.qid IN ('09-Linsys/Linsys-SurveyElevations','09-Linsys/Linsys-MenuPrices')),
best AS (
  SELECT DISTINCT ON (iq.id) iq.id AS iq_id, aqs.qid, s.feedback, s.submitted_answer
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.feedback ? 'results'
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC),
code AS (SELECT b.iq_id, b.qid, b.feedback, convert_from(decode(f->>'contents','base64'),'UTF8') AS src
  FROM best b, LATERAL jsonb_array_elements(b.submitted_answer->'_files') f WHERE f->>'name'='user_code.py'),
lines AS (SELECT iq_id, l FROM code, LATERAL regexp_split_to_table(src, E'\n') l WHERE l !~ '^\s*#'),
feat AS (SELECT iq_id,
   bool_or(l ~ 'A\s*\[[^=]*benchmark') AS bench_in_A,
   bool_or(l ~ '=\s*-\s*1\s*$|-=\s*1' AND l ~ '(start|\[\s*0\s*\])') AS minus_start,
   bool_or(l ~ '=\s*-\s*1\s*$|-=\s*1' AND l ~ '(end|\[\s*1\s*\])') AS minus_end,
   bool_or(l ~ 'np\.(zeros|empty)\s*\(\s*\(?\s*[a-z_()]+\s*-\s*1') AS alloc_n_minus_1
  FROM lines GROUP BY iq_id),
cls AS (SELECT c.iq_id, c.qid, CASE
    WHEN (SELECT t->>'message' FROM jsonb_array_elements(c.feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A') LIKE 'A is correct%' THEN '1 A correct'
    WHEN (SELECT t->>'message' FROM jsonb_array_elements(c.feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A') ~ '^0 of' THEN '2 A 0 rows'
    WHEN (SELECT t->>'message' FROM jsonb_array_elements(c.feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A') ~ '^[0-9]+ of' THEN '3 A some rows'
    WHEN (SELECT t->>'message' FROM jsonb_array_elements(c.feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A') ~ 'shape' THEN '4 A wrong shape'
    WHEN NOT EXISTS (SELECT 1 FROM jsonb_array_elements(c.feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A') THEN '5 exception'
    ELSE '6 other' END AS a_cls FROM code c)
SELECT cls.qid, a_cls, COUNT(*) AS n, SUM(bench_in_A::int) AS bench_in_A, SUM(minus_start::int) AS minus_start, SUM(minus_end::int) AS minus_end, SUM(alloc_n_minus_1::int) AS alloc_n_minus_1
FROM cls LEFT JOIN feat USING (iq_id) GROUP BY 1,2 ORDER BY 1,2;
