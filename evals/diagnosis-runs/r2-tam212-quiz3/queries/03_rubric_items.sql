-- Rubric item application rates for the manually graded slot.
-- Uses the most recent rubric grading on each instance question's submissions.
WITH iqs AS (
  SELECT ci.short_name AS offering, q.qid, aq.id AS aq_id, iq.id AS iq_id
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id=aq.question_id AND q.qid IN ('massFromCurveRadWritten','polyDistCurveAccWritten')
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id=:course_id AND ci.short_name IN ('Fall2025','Spring2026','Fall2026')
),
rg AS (
  SELECT DISTINCT ON (iqs.iq_id) iqs.iq_id, s.manual_rubric_grading_id AS rg_id
  FROM iqs JOIN variants v ON v.instance_question_id=iqs.iq_id
  JOIN submissions s ON s.variant_id=v.id AND s.manual_rubric_grading_id IS NOT NULL
  ORDER BY iqs.iq_id, s.date DESC, s.id DESC
),
sub AS (
  SELECT iqs.iq_id, COUNT(s.id) AS n_sub
  FROM iqs LEFT JOIN variants v ON v.instance_question_id=iqs.iq_id
  LEFT JOIN submissions s ON s.variant_id=v.id
  GROUP BY iqs.iq_id
),
tot AS (
  SELECT iqs.offering, iqs.qid, iqs.aq_id, COUNT(*) n_assigned,
    COUNT(*) FILTER (WHERE sub.n_sub>0) n_with_submission,
    COUNT(rg.rg_id) n_rubric_graded
  FROM iqs JOIN sub USING (iq_id) LEFT JOIN rg USING (iq_id) GROUP BY 1,2,3
)
SELECT t.offering, t.qid, t.n_assigned, t.n_with_submission, t.n_rubric_graded,
  ri.number AS item_no, ri.points, ri.description, ri.deleted_at IS NOT NULL AS item_deleted,
  COUNT(rgi.id) AS n_applied,
  ROUND((100.0*COUNT(rgi.id)/NULLIF(t.n_rubric_graded,0))::numeric,1) AS applied_pct
FROM tot t
JOIN assessment_questions aq ON aq.id=t.aq_id
JOIN rubric_items ri ON ri.rubric_id=aq.manual_rubric_id
LEFT JOIN iqs ON iqs.aq_id=t.aq_id
LEFT JOIN rg ON rg.iq_id=iqs.iq_id
LEFT JOIN rubric_grading_items rgi ON rgi.rubric_grading_id=rg.rg_id AND rgi.rubric_item_id=ri.id
GROUP BY t.offering, t.qid, t.n_assigned, t.n_with_submission, t.n_rubric_graded, ri.id, ri.number, ri.points, ri.description, ri.deleted_at
ORDER BY t.offering, t.qid, ri.number;
