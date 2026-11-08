-- Rubric item text for the written slot, Spring2026 (instructor-authored rubric; no student data).
SELECT q.qid, ri.number, ri.points, ri.description, left(regexp_replace(COALESCE(ri.explanation,''), '\s+', ' ', 'g'), 200) AS explanation,
       left(regexp_replace(COALESCE(ri.grader_note,''), '\s+', ' ', 'g'), 300) AS grader_note
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN questions q ON q.id = aq.question_id
JOIN rubric_items ri ON ri.rubric_id = aq.manual_rubric_id AND ri.deleted_at IS NULL
WHERE ci.course_id = 1 AND ci.short_name = 'Spring2026'
  AND q.qid IN ('rigidBodyPinAccelWritten','fourBarAngVelSimpleWritten')
ORDER BY q.qid, ri.number;
