-- quiz03: points-weighted score on the slots that did not change (everything except Group 1 slot 3), per offering.
SELECT ci.short_name AS offering, COUNT(DISTINCT ai.id) n,
  ROUND((100*SUM(iq.points)/SUM(aq.max_points))::numeric,1) AS pct_unchanged_slots
FROM course_instances ci
JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL AND aq.max_points > 0
JOIN alternative_groups ag ON ag.id=aq.alternative_group_id
JOIN zones z ON z.id=ag.zone_id
JOIN instance_questions iq ON iq.assessment_question_id=aq.id
JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id=:course_id AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
  AND NOT (z.number=2 AND ag.number=5)
GROUP BY ci.id, ci.short_name ORDER BY ci.id;
