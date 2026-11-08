-- Failed "Check matrix M" on best submission: grader message pattern (numbers masked, truncated), counts only
WITH best AS (
  SELECT DISTINCT ON (iq.id) q.qid, s.feedback
  FROM instance_questions AS iq
  JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
  JOIN questions q ON q.id=aq.question_id
  JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants AS v ON v.instance_question_id = iq.id
  JOIN submissions AS s ON s.variant_id = v.id AND s.feedback ? 'results'
  WHERE aq.assessment_id IN (2491236,2557983,2619950)
    AND q.qid IN ('17-LinearLeastSquares/LeastSquares-Geese','17-LinearLeastSquares/LeastSquares-Squirrels')
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC
)
SELECT qid, LEFT(regexp_replace(regexp_replace(COALESCE(t->>'message',''), '[-+]?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?', '#', 'g'), '\s+', ' ', 'g'), 90) AS msg_pattern, COUNT(*) AS n
FROM best, LATERAL jsonb_array_elements(feedback->'results'->'tests') AS t
WHERE t->>'name' = 'Check matrix M' AND (t->>'points')::numeric < (t->>'max_points')::numeric
GROUP BY 1,2 HAVING COUNT(*) >= 3 ORDER BY 1, 3 DESC;
