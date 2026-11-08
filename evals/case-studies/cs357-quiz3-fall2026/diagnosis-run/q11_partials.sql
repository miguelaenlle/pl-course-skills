\echo == per-input credit on best submission, selected questions, four offerings
WITH aqs AS (
  SELECT aq.id, q.qid, ci.short_name AS offering FROM assessment_questions aq JOIN questions q ON q.id=aq.question_id
  JOIN assessments a ON a.id = aq.assessment_id JOIN course_instances ci ON ci.id = a.course_instance_id
  WHERE aq.assessment_id IN (2491228, 2557977, 2619944, 2713997) AND aq.deleted_at IS NULL
    AND q.qid IN ('08-Vector-Matrices-Norms/Norm-Vector-Projection-v1','08-Vector-Matrices-Norms/Norm-Vector-Projection-v2',
      '09-Linsys/LinearSystem-TimeComplexityLU-v1','09-Linsys/LinearSystem-TimeComplexityLU-v2',
      '08-Vector-Matrices-Norms/Norm-InducedNorm-v2','07-Random-MonteCarlo/MC-ErrorConvergence-v3',
      '09-Linsys/Linsys-Choose-Partial-Pivot','07-Random-MonteCarlo/MC-EstimateErrorGivenArea-v1','08-Vector-Matrices-Norms/Norm-VectorNormProperties-v2')),
best AS (
  SELECT DISTINCT ON (iq.id) aqs.offering, aqs.qid, s.partial_scores
  FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.partial_scores IS NOT NULL
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC)
SELECT qid, offering, p.key AS input, COUNT(*) AS n, ROUND((100*AVG((p.value->>'score')::numeric))::numeric,1) AS mean_pct
FROM best, LATERAL jsonb_each(partial_scores) p
GROUP BY 1,2,3 ORDER BY 1,3,2;
