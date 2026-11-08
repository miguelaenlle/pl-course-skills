-- Per-input credit on the best graded submission, auto-graded multi-input questions
WITH best AS (
  SELECT DISTINCT ON (iq.id) iq.assessment_question_id AS aq_id, s.partial_scores
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.score IS NOT NULL AND s.partial_scores IS NOT NULL
  WHERE ai.assessment_id IN (2434746, 2497144, 2574213, 2634479, 2716830)
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC
)
SELECT ci.short_name AS offering, q.qid, k AS input_name, COUNT(*) AS n,
  ROUND((100 * AVG((ps->>'score')::numeric))::numeric, 1) AS mean_credit_pct
FROM best b
JOIN assessment_questions aq ON aq.id = b.aq_id
JOIN assessments a ON a.id = aq.assessment_id
JOIN course_instances ci ON ci.id = a.course_instance_id
JOIN questions q ON q.id = aq.question_id,
LATERAL jsonb_each(b.partial_scores) AS e(k, ps)
WHERE q.grading_method::text <> 'Manual'
GROUP BY 1,2,3 ORDER BY 1,2,3;
