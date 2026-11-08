-- Manual grading state for the written-response slot (slot 4), Quiz 4, recent offerings. Aggregates only.
WITH iq AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, q.qid, aq.id AS aq_id, iq.*
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 1 AND ci.short_name IN ('Fall2025','Spring2026','Fall2026')
    AND q.qid IN ('rigidBodyPinAccelWritten','fourBarAngVelSimpleWritten')
), subs AS (
  SELECT iq.id AS iq_id, COUNT(s.id) AS n_subs, COUNT(s.manual_rubric_grading_id) AS n_rubric_subs
  FROM iq LEFT JOIN variants v ON v.instance_question_id = iq.id
  LEFT JOIN submissions s ON s.variant_id = v.id
  GROUP BY iq.id
)
SELECT offering, qid, COUNT(*) AS n,
  COUNT(*) FILTER (WHERE subs.n_subs > 0) AS with_pl_submission,
  COUNT(*) FILTER (WHERE subs.n_rubric_subs > 0) AS with_rubric_grading,
  COUNT(*) FILTER (WHERE requires_manual_grading) AS still_needs_grading,
  COUNT(*) FILTER (WHERE last_grader IS NOT NULL) AS has_grader,
  COUNT(DISTINCT last_grader) AS n_graders,
  COUNT(*) FILTER (WHERE is_ai_graded) AS ai_graded,
  ROUND(AVG(score_perc)::numeric,1) AS final_pct,
  ROUND(AVG(score_perc) FILTER (WHERE NOT requires_manual_grading)::numeric,1) AS final_pct_graded_only,
  COUNT(*) FILTER (WHERE score_perc = 0) AS n_zero,
  COUNT(*) FILTER (WHERE score_perc > 0 AND score_perc < 50) AS n_1_49,
  COUNT(*) FILTER (WHERE score_perc >= 50 AND score_perc < 100) AS n_50_99,
  COUNT(*) FILTER (WHERE score_perc >= 100) AS n_100,
  string_agg(DISTINCT status::text, ',') AS statuses
FROM iq JOIN subs ON subs.iq_id = iq.id
GROUP BY ci_id, offering, qid ORDER BY ci_id, qid;
