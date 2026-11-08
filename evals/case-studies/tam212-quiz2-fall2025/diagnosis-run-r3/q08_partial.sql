-- Per-input success on first and best graded submissions, Fall2025 quiz02, autograded slots 4,6,7,8
WITH s AS (
  SELECT iq.id AS iq_id, q.qid, ag.number AS slot, sub.partial_scores, sub.score, sub.date,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.date) AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY iq.id ORDER BY sub.score DESC NULLS LAST, sub.date DESC) AS rn_best
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions sub ON sub.variant_id = v.id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND ag.number IN (4,6,7,8) AND sub.gradable AND sub.score IS NOT NULL
)
SELECT slot, qid, which, ps.key AS input, COUNT(*) AS n,
  ROUND((100*AVG(((ps.value->>'score')::numeric >= 1)::int))::numeric,1) AS correct_pct
FROM (
  SELECT *, 'first' AS which FROM s WHERE rn_first = 1
  UNION ALL SELECT *, 'best' FROM s WHERE rn_best = 1
) x, LATERAL jsonb_each(x.partial_scores) ps
GROUP BY slot, qid, which, ps.key ORDER BY slot, qid, which DESC, input;
