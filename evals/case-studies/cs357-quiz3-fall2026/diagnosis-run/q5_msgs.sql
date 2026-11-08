\echo == masked test messages on best submission (counts >= 3)
WITH aqs AS (SELECT aq.id, q.qid FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id WHERE aq.assessment_id=2713997 AND aq.deleted_at IS NULL AND q.qid IN ('07-Random-MonteCarlo/MC-ArcadePrizeProbability','07-Random-MonteCarlo/MC-TreasureKeyProbability','09-Linsys/Linsys-MenuPrices','09-Linsys/Linsys-SurveyElevations')),
best AS (
  SELECT DISTINCT ON (iq.id) aqs.qid, s.feedback
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.feedback ? 'results'
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC)
SELECT qid, t->>'name' AS test, LEFT(regexp_replace(regexp_replace(COALESCE(t->>'message',''), '\s+', ' ', 'g'), '[0-9]+(\.[0-9]+)?', '#', 'g'), 160) AS msg, COUNT(*) AS n
FROM best, LATERAL jsonb_array_elements(feedback->'results'->'tests') t
WHERE t->>'name' <> 'Your code raised an Exception'
GROUP BY 1,2,3 HAVING COUNT(*) >= 3 ORDER BY 1,2,4 DESC;

\echo == SurveyElevations: rows-correct count on best submission, by n locations
WITH aqs AS (SELECT aq.id FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id WHERE aq.assessment_id=2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations'),
best AS (
  SELECT DISTINCT ON (iq.id) s.feedback, jsonb_array_length(v.params->'locations') AS n_loc
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.feedback ? 'results'
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC)
SELECT n_loc, substring(t->>'message' from '([0-9]+) of [0-9]+ rows') AS rows_correct, (t->>'points')::numeric > 0 AS some_pts, COUNT(*)
FROM best, LATERAL jsonb_array_elements(feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A'
GROUP BY 1,2,3 ORDER BY 1,2,3;
