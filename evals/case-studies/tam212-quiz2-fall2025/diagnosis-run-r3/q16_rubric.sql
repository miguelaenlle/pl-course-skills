-- Slot 5 rubric item usage on the final manual grading (Fall2025 quiz02)
WITH x AS (
  SELECT q.qid, iq.id iq_id, rg.id rg_id
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN LATERAL (SELECT s.manual_rubric_grading_id FROM variants v JOIN submissions s ON s.variant_id=v.id
                WHERE v.instance_question_id = iq.id AND s.manual_rubric_grading_id IS NOT NULL ORDER BY s.date DESC LIMIT 1) ls ON true
  JOIN rubric_gradings rg ON rg.id = ls.manual_rubric_grading_id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND ag.number = 5
)
SELECT x.qid, ri.number, ri.points, ri.description, COUNT(DISTINCT x.iq_id) n_applied,
  ROUND(100.0*COUNT(DISTINCT x.iq_id)/(SELECT COUNT(*) FROM x x2 WHERE x2.qid=x.qid),1) AS pct_of_graded
FROM x JOIN rubric_grading_items rgi ON rgi.rubric_grading_id = x.rg_id JOIN rubric_items ri ON ri.id = rgi.rubric_item_id
GROUP BY x.qid, ri.number, ri.points, ri.description ORDER BY x.qid, ri.number;
