\echo == TreasureKey: masked grader messages by grading day (all graded submissions)
SELECT gj.date::date AS day, LEFT(regexp_replace(regexp_replace(COALESCE(t->>'message',''), '\s+', ' ', 'g'), '[0-9]+(\.[0-9]+)?', '#', 'g'), 90) AS msg, COUNT(*) AS n
FROM grading_jobs gj JOIN submissions s ON s.id = gj.submission_id JOIN variants v ON v.id = s.variant_id
JOIN instance_questions iq ON iq.id = v.instance_question_id JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics,
LATERAL jsonb_array_elements(gj.feedback->'results'->'tests') t
WHERE aq.assessment_id = 2713997 AND q.qid='07-Random-MonteCarlo/MC-TreasureKeyProbability' AND t->>'name' <> 'Your code raised an Exception'
GROUP BY 1,2 ORDER BY 1,3 DESC;
\echo == TreasureKey / Arcade by generated parameters (final score, all assigned)
SELECT q.qid, COALESCE(v.params->>'total_keys', v.params->>'lower_score') AS p1, v.params->>'win_on_match' AS win_on_match, COUNT(DISTINCT iq.id) AS n,
  ROUND(AVG(iq.score_perc)::numeric,1) AS mean_final, ROUND((100*AVG(COALESCE(iq.max_submission_score,0)))::numeric,1) AS mean_best
FROM instance_questions iq JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
JOIN LATERAL (SELECT v.params FROM variants v WHERE v.instance_question_id = iq.id ORDER BY v.date LIMIT 1) v ON true
WHERE aq.assessment_id = 2713997 AND q.qid IN ('07-Random-MonteCarlo/MC-TreasureKeyProbability')
GROUP BY 1,2,3 ORDER BY 1,2,3;
