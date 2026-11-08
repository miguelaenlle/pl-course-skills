-- TimeComplexityComparison ranking part: which option is chosen on first submission, by requested order
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) v.params, s.submitted_answer
  FROM instance_questions iq
  JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
  JOIN questions q ON q.id=aq.question_id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  JOIN submissions s ON s.variant_id=v.id AND s.gradable
  WHERE aq.assessment_id IN (2355373,2388044,2444565,2491236,2557983,2619950)
    AND q.qid = '16-SVD/SVD-TimeComplexityComparison'
  ORDER BY iq.id, s.date ASC
)
SELECT params->>'order' AS requested_order, o->>'html' AS chosen_option, (o->>'correct') AS is_correct, COUNT(*) AS n
FROM firsts, LATERAL jsonb_array_elements(params->'students') o
WHERE o->>'key' = submitted_answer->>'students'
GROUP BY 1,2,3 ORDER BY 1, 4 DESC;
