-- Outcomes grouped by generated parameters (category derived from variant params), Quiz 4.
WITH base AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, q.qid, iq.*, v.params AS p
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN LATERAL (SELECT v.params FROM variants v WHERE v.instance_question_id = iq.id ORDER BY v.number DESC NULLS LAST, v.id DESC LIMIT 1) v ON true
  WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026','Fall2026')
    AND q.qid IN ('twoBarAPoint','twoBarOmegaFromV','rbmAccelNum','twoAccChoosePoint','rbmTwoCornerConstraints',
                  'rbmCircleChordConstraint','rodVelCircleConstraint','constrainedMotionPistonVelo',
                  'rigidBodyPinAccelWritten','fourBarAngVelSimpleWritten','rigidBodyPinAccel','fourBarAngVelSimple')
), cat AS (
  SELECT *, CASE qid
    WHEN 'twoBarAPoint' THEN 'find ' || (p->>'findVar')
    WHEN 'twoBarOmegaFromV' THEN 'find ' || (p->>'findVar')
    WHEN 'rbmAccelNum' THEN 'omega ' || CASE WHEN p->>'omega_vec' = '0' THEN '=0' ELSE '<>0' END || ', alpha ' || CASE WHEN p->>'alpha_vec' = '0' THEN '=0' ELSE '<>0' END
    WHEN 'twoAccChoosePoint' THEN 'zero ' || (p->>'zeroVar')
    WHEN 'rbmTwoCornerConstraints' THEN 'find v_' || (p->>'ansCorner')
    WHEN 'rbmCircleChordConstraint' THEN 'P moves ' || (p->>'pDirection')
    WHEN 'rodVelCircleConstraint' THEN CASE WHEN (p->>'vPx')::numeric = 0 OR (p->>'vPy')::numeric = 0 THEN 'vP axis-aligned' ELSE 'vP oblique' END
    WHEN 'constrainedMotionPistonVelo' THEN CASE WHEN (p->>'omega')::numeric < 0 THEN 'omega negative (CW)' ELSE 'omega positive (CCW)' END
    WHEN 'rigidBodyPinAccelWritten' THEN 'find ' || (p->>'findVar')
    WHEN 'rigidBodyPinAccel' THEN 'find ' || (p->>'findVar')
    WHEN 'fourBarAngVelSimpleWritten' THEN
      CASE WHEN (p->'rAD'->'_value'->>0) = (p->'rBC'->'_value'->>0) THEN 'parallelogram' ELSE 'non-parallel' END
      || ', given w' || (p->>'givenIndex') || ' find w' || (p->>'findIndex')
    WHEN 'fourBarAngVelSimple' THEN
      CASE WHEN (p->'rAD'->'_value'->>0) = (p->'rBC'->'_value'->>0) THEN 'parallelogram' ELSE 'non-parallel' END
    END AS category
  FROM base
)
SELECT offering, qid, category, COUNT(*) AS n,
  ROUND(AVG(score_perc)::numeric,1) AS final_pct,
  ROUND(100*AVG((score_perc>=100)::int)::numeric,1) AS full_pct,
  ROUND(100*AVG(first_submission_score) FILTER (WHERE some_submission)::numeric,1) AS first_pct,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM duration)) FILTER (WHERE some_submission)/60)::numeric,1) AS med_min
FROM cat
GROUP BY ci_id, offering, qid, category
ORDER BY qid, category, ci_id;
