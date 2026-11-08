-- Which params / true_answer keys exist per question (structure only, no values)
SELECT q.qid, k AS key, jsonb_typeof(v.params->k) AS type, COUNT(*) AS n
FROM variants v
JOIN instance_questions iq ON iq.id = v.instance_question_id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN questions q ON q.id = aq.question_id,
LATERAL jsonb_object_keys(v.params) AS k
WHERE aq.assessment_id = 2574213 AND q.qid IN ('rotPointLoc','thetaFunTAccln3','pinSlotAcclnMag','polarAcclnTelescopicArm','particleVelonTriCurveSpeed','particleVelOnExpnCurveSpeed','OhareTrackComputeA','OhareTrackComputeR')
GROUP BY 1,2,3 ORDER BY 1,2;
