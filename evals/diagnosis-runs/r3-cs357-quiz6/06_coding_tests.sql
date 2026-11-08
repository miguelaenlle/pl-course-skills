-- Per-test pass rate on each student's best graded submission, coding questions
WITH best AS (
  SELECT DISTINCT ON (iq.id) iq.assessment_question_id AS aq_id, s.feedback, s.score
  FROM instance_questions AS iq
  JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants AS v ON v.instance_question_id = iq.id
  JOIN submissions AS s ON s.variant_id = v.id AND s.feedback ? 'results'
  WHERE iq.assessment_question_id IN (1574901765,1648711431,1986540840,1574901766,1648711433,1986540841,1582508050,1648711434,1986540842,1375473215,1648711438)
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC
)
SELECT aq_id, t->>'name' AS test, t->>'max_points' AS max_points, COUNT(*) AS n,
  ROUND((100 * AVG(((t->>'points')::numeric >= (t->>'max_points')::numeric)::int))::numeric, 1) AS passed_pct
FROM best, LATERAL jsonb_array_elements(feedback->'results'->'tests') AS t
GROUP BY aq_id, test, t->>'max_points' ORDER BY aq_id, test;
