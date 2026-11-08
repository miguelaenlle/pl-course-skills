-- Probe: shape of generated params for a few Quiz 4 questions (one variant each, Spring2026; no student data).
SELECT q.qid, v.params->'rAD' AS rAD, v.params->>'findIndex' AS findIndex, v.params->>'givenIndex' AS givenIndex, v.params->>'omega' AS omega, v.params->>'theta' AS theta
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id AND a.tid='quiz04'
JOIN assessment_questions aq ON aq.assessment_id = a.id
JOIN questions q ON q.id = aq.question_id
JOIN LATERAL (SELECT v.params FROM instance_questions iq JOIN variants v ON v.instance_question_id = iq.id WHERE iq.assessment_question_id = aq.id LIMIT 1) v ON true
WHERE ci.course_id=1 AND ci.short_name='Spring2026' AND q.qid IN ('fourBarAngVelSimpleWritten','constrainedMotionPistonVelo','rigidBodyPinAccelWritten');
