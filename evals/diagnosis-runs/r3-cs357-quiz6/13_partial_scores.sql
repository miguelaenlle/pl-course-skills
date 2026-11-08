-- Per-input credit on first submission (TimeComplexityComparison) and option-selection rates (PseudoInv), offerings Fall2023-Spring2026
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) q.qid, s.partial_scores, s.submitted_answer, v.true_answer, s.score
  FROM instance_questions iq
  JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
  JOIN questions q ON q.id=aq.question_id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  JOIN submissions s ON s.variant_id=v.id AND s.gradable
  WHERE aq.assessment_id IN (2355373,2388044,2444565,2491236,2557983,2619950)
    AND q.qid IN ('16-SVD/SVD-TimeComplexityComparison','16-SVD/SVD-APP-PseudoInv','16-SVD/SVD-APP-PropertiesMulti')
  ORDER BY iq.id, s.date ASC
)
SELECT qid, k AS input, COUNT(*) AS n,
  ROUND(100.0*AVG(((partial_scores->k->>'score')::float8 >= 1)::int),1) AS pct_input_correct,
  ROUND(100.0*AVG((score>=1)::int),1) AS pct_question_correct
FROM firsts, LATERAL jsonb_object_keys(partial_scores) k
GROUP BY 1,2 ORDER BY 1,2;
