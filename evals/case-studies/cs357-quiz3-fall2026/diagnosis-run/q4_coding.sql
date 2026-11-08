\echo == per-test pass on best submission
WITH aqs AS (SELECT aq.id, q.qid FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id WHERE aq.assessment_id=2713997 AND aq.deleted_at IS NULL AND q.qid IN ('07-Random-MonteCarlo/MC-ArcadePrizeProbability','07-Random-MonteCarlo/MC-TreasureKeyProbability','09-Linsys/Linsys-MenuPrices','09-Linsys/Linsys-SurveyElevations')),
best AS (
  SELECT DISTINCT ON (iq.id) aqs.qid, s.feedback, s.score
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.feedback ? 'results'
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC)
SELECT qid, t->>'name' AS test, COUNT(*) AS n,
  ROUND((100*AVG(((t->>'points')::numeric >= (t->>'max_points')::numeric)::int))::numeric,1) AS passed_pct,
  ROUND((100*AVG((t->>'points')::numeric/NULLIF((t->>'max_points')::numeric,0)))::numeric,1) AS mean_pct,
  ROUND((100*AVG(((t->>'points')::numeric = 0)::int))::numeric,1) AS zero_pct
FROM best, LATERAL jsonb_array_elements(feedback->'results'->'tests') t GROUP BY qid, test ORDER BY qid, test;

\echo == submissions without test results / grading problems
WITH aqs AS (SELECT aq.id, q.qid FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id WHERE aq.assessment_id=2713997 AND aq.deleted_at IS NULL AND q.qid IN ('07-Random-MonteCarlo/MC-ArcadePrizeProbability','07-Random-MonteCarlo/MC-TreasureKeyProbability','09-Linsys/Linsys-MenuPrices','09-Linsys/Linsys-SurveyElevations'))
SELECT aqs.qid, COUNT(*) AS n_subs, SUM((s.feedback ? 'results')::int) AS with_results,
  SUM((s.feedback->'results'->>'succeeded' = 'false')::int) AS not_succeeded,
  SUM((s.gradable = false)::int) AS ungradable, SUM((s.score IS NULL)::int) AS null_score,
  SUM((s.feedback->'results'->>'message' ILIKE '%timed out%' OR s.feedback->'results'->>'message' ILIKE '%timeout%')::int) AS timeouts
FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
JOIN variants v ON v.instance_question_id = iq.id JOIN submissions s ON s.variant_id = v.id
GROUP BY aqs.qid ORDER BY 1;
