-- Does the written-slot rubric carry grader guidance? (rubric metadata only)
SELECT ci.short_name AS offering, q.qid, r.id IS NOT NULL AS has_rubric,
  length(COALESCE(r.grader_guidelines,'')) AS guidelines_chars,
  COUNT(ri.id) FILTER (WHERE ri.deleted_at IS NULL) AS n_items,
  COUNT(ri.id) FILTER (WHERE ri.deleted_at IS NULL AND length(COALESCE(ri.explanation,'')) > 0) AS items_with_explanation,
  COUNT(ri.id) FILTER (WHERE ri.deleted_at IS NULL AND length(COALESCE(ri.grader_note,'')) > 0) AS items_with_grader_note
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN questions q ON q.id = aq.question_id
LEFT JOIN rubrics r ON r.id = aq.manual_rubric_id
LEFT JOIN rubric_items ri ON ri.rubric_id = r.id
WHERE ci.course_id = 1 AND ci.short_name IN ('Fall2025','Spring2026','Fall2026')
  AND q.qid IN ('rigidBodyPinAccelWritten','fourBarAngVelSimpleWritten')
GROUP BY ci.id, ci.short_name, q.qid, r.id, r.grader_guidelines ORDER BY ci.id, q.qid;
