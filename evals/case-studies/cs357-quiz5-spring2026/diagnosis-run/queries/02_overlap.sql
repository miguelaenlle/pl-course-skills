-- Question overlap between each past Quiz 5 (graded, non-practice) and the current Fall2026 definition
WITH cur AS (
  SELECT q.qid FROM assessment_questions aq JOIN questions q ON q.id = aq.question_id
  WHERE aq.assessment_id = 2714001 AND aq.deleted_at IS NULL
), past AS (
  SELECT a.id AS a_id, ci.short_name, a.tid, q.qid
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  WHERE ci.course_id = 114 AND ci.deleted_at IS NULL
    AND a.tid IN ('quiz5','quiz5M','quiz5N','quiz5-ZJUI','quiz5_copy1')
)
SELECT short_name, tid, COUNT(*) AS n_q,
  COUNT(*) FILTER (WHERE qid IN (SELECT qid FROM cur)) AS n_shared_with_current,
  (SELECT COUNT(*) FROM cur) - COUNT(*) FILTER (WHERE qid IN (SELECT qid FROM cur)) AS n_current_missing,
  string_agg(qid, ', ' ORDER BY qid) FILTER (WHERE qid NOT IN (SELECT qid FROM cur)) AS not_in_current
FROM past GROUP BY a_id, short_name, tid ORDER BY a_id;
