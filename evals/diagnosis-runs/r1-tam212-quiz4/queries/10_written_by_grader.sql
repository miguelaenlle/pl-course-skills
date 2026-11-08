-- Written slot: score by grader (graders anonymized as G1..Gn by volume within offering), graded items only.
WITH iq AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, q.qid, iq.score_perc, iq.last_grader
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 1 AND ci.short_name IN ('Fall2025','Spring2026','Fall2026')
    AND q.qid IN ('rigidBodyPinAccelWritten','fourBarAngVelSimpleWritten')
    AND iq.last_grader IS NOT NULL
), g AS (
  SELECT ci_id, last_grader, 'G' || ROW_NUMBER() OVER (PARTITION BY ci_id ORDER BY COUNT(*) DESC, last_grader) AS grader
  FROM iq GROUP BY ci_id, last_grader
)
SELECT iq.offering, g.grader,
  COUNT(*) FILTER (WHERE qid='fourBarAngVelSimpleWritten') AS n_fourbar,
  ROUND(AVG(score_perc) FILTER (WHERE qid='fourBarAngVelSimpleWritten')::numeric,1) AS fourbar_pct,
  COUNT(*) FILTER (WHERE qid='rigidBodyPinAccelWritten') AS n_pin,
  ROUND(AVG(score_perc) FILTER (WHERE qid='rigidBodyPinAccelWritten')::numeric,1) AS pin_pct
FROM iq JOIN g ON g.ci_id = iq.ci_id AND g.last_grader = iq.last_grader
GROUP BY iq.ci_id, iq.offering, g.grader ORDER BY iq.ci_id, g.grader;
