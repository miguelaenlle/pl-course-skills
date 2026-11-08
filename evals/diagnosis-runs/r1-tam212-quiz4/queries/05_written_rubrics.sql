-- Rubric items for the written slot and how often each was applied (latest rubric grading per instance question).
WITH iq AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, q.qid, aq.manual_rubric_id, iq.id AS iq_id
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 1 AND ci.short_name IN ('Fall2025','Spring2026','Fall2026')
    AND q.qid IN ('rigidBodyPinAccelWritten','fourBarAngVelSimpleWritten')
), last_grading AS (
  SELECT DISTINCT ON (iq.iq_id) iq.iq_id, iq.ci_id, iq.offering, iq.qid, s.manual_rubric_grading_id AS rg_id
  FROM iq JOIN variants v ON v.instance_question_id = iq.iq_id
  JOIN submissions s ON s.variant_id = v.id
  WHERE s.manual_rubric_grading_id IS NOT NULL
  ORDER BY iq.iq_id, s.date DESC, s.id DESC
), denom AS (SELECT ci_id, qid, COUNT(*) AS n_graded FROM last_grading GROUP BY 1,2)
SELECT lg.offering, lg.qid, ri.number AS item_no, ri.points, ri.description,
       COUNT(*) AS n_applied, d.n_graded,
       ROUND(100.0*COUNT(*)/d.n_graded,1) AS pct_applied,
       ri.deleted_at IS NOT NULL AS item_deleted
FROM last_grading lg
JOIN rubric_grading_items rgi ON rgi.rubric_grading_id = lg.rg_id
JOIN rubric_items ri ON ri.id = rgi.rubric_item_id
JOIN denom d ON d.ci_id = lg.ci_id AND d.qid = lg.qid
GROUP BY lg.ci_id, lg.offering, lg.qid, ri.number, ri.points, ri.description, d.n_graded, ri.deleted_at
ORDER BY lg.qid, lg.ci_id, ri.number;
-- Grading adjustments outside rubric items
WITH iq AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, q.qid, iq.id AS iq_id
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 1 AND ci.short_name IN ('Fall2025','Spring2026','Fall2026')
    AND q.qid IN ('rigidBodyPinAccelWritten','fourBarAngVelSimpleWritten')
), last_grading AS (
  SELECT DISTINCT ON (iq.iq_id) iq.iq_id, iq.ci_id, iq.offering, iq.qid, s.manual_rubric_grading_id AS rg_id
  FROM iq JOIN variants v ON v.instance_question_id = iq.iq_id
  JOIN submissions s ON s.variant_id = v.id
  WHERE s.manual_rubric_grading_id IS NOT NULL
  ORDER BY iq.iq_id, s.date DESC, s.id DESC
)
SELECT lg.offering, lg.qid, COUNT(*) AS n_graded, r.starting_points,
       COUNT(*) FILTER (WHERE rg.adjust_points <> 0) AS n_adjusted,
       ROUND(AVG(rg.adjust_points)::numeric,2) AS mean_adjust,
       ROUND(AVG(rg.computed_points)::numeric,2) AS mean_points
FROM last_grading lg JOIN rubric_gradings rg ON rg.id = lg.rg_id JOIN rubrics r ON r.id = rg.rubric_id
GROUP BY lg.ci_id, lg.offering, lg.qid, r.starting_points ORDER BY lg.qid, lg.ci_id;
