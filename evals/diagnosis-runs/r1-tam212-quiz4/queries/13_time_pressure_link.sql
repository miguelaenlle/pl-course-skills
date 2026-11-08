-- Does drawing the slower slot-3 questions go with skipping the last questions? Aggregates by draw type.
WITH iq AS (
  SELECT ci.short_name AS offering, iq.assessment_instance_id AS ai_id, q.qid, ag.number AS slot, iq.some_submission
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id = 1 AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
), per AS (
  SELECT CASE WHEN offering = 'Spring2026' THEN 'Spring2026' ELSE 'other 5 offerings' END AS grp, ai_id,
    COUNT(*) FILTER (WHERE slot = 3 AND qid IN ('twoPointVAlg','rbmAccelNum')) AS n_single_body,
    BOOL_OR(qid = 'constrainedMotionPistonVelo' AND NOT COALESCE(some_submission,false)) AS skipped_piston,
    BOOL_OR(slot = 6 AND NOT COALESCE(some_submission,false)) AS skipped_slot6
  FROM iq GROUP BY 1, 2
)
SELECT grp, n_single_body AS single_body_drawn, COUNT(*) AS n,
  ROUND(100*AVG(skipped_piston::int)::numeric,1) AS skipped_piston_pct,
  ROUND(100*AVG(skipped_slot6::int)::numeric,1) AS skipped_slot6_pct
FROM per GROUP BY 1, 2 ORDER BY 1, 2;
