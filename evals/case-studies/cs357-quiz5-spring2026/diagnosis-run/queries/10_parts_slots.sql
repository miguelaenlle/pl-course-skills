-- Per-part credit (partial_scores) on first and best-scoring submission per assigned question,
-- for non-coding slots, Spring2025..Spring2026 (identical definitions). Aggregates only.
WITH subs AS (
  SELECT iq.id AS iq_id, ag.number AS slot, split_part(q.qid, '/', 2) AS qid, s.partial_scores AS ps, s.score, s.date,
    row_number() OVER (PARTITION BY iq.id ORDER BY s.date) AS rn_first,
    row_number() OVER (PARTITION BY iq.id ORDER BY s.score DESC NULLS LAST, s.date DESC) AS rn_best
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz5'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.graded_at IS NOT NULL
  WHERE ci.course_id = 114 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026') AND ag.number BETWEEN 1 AND 8
)
SELECT slot, qid, p.key AS part,
  COUNT(*) FILTER (WHERE rn_first = 1) AS n,
  ROUND(100 * AVG((p.value->>'score')::numeric) FILTER (WHERE rn_first = 1), 1) AS first_part_pct,
  ROUND(100 * AVG((p.value->>'score')::numeric) FILTER (WHERE rn_best = 1), 1) AS best_part_pct
FROM subs, jsonb_each(ps) AS p
WHERE rn_first = 1 OR rn_best = 1
GROUP BY 1, 2, 3 ORDER BY 1, 2, 3;
