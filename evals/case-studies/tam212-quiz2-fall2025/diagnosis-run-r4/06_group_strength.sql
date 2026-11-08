-- For each alternative: mean points on everything EXCEPT this slot, to check whether drawers were weaker/stronger
WITH x AS (
  SELECT ai.id AS ai_id, ai.assessment_id, ag.number AS slot, aq.id AS aq_id, q.qid, aq.number_in_alternative_group AS alt, iq.points, aq.max_points
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id AND aq.max_points > 0
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  WHERE ai.include_in_statistics AND ai.assessment_id IN (2434746, 2497144, 2574213, 2634479, 2716830)
)
SELECT ci.short_name AS offering, x.slot || '.' || x.alt AS question_number, x.qid, COUNT(DISTINCT x.ai_id) AS n,
  ROUND(AVG(x.points)::numeric, 2) AS mean_points_this_slot,
  ROUND(AVG(o.other_points)::numeric, 2) AS mean_points_other_slots,
  ROUND(AVG(o.fixed_points)::numeric, 2) AS mean_points_q3
FROM x
JOIN LATERAL (
  SELECT SUM(y.points) FILTER (WHERE y.slot <> x.slot) AS other_points,
         SUM(y.points) FILTER (WHERE y.slot = 3) AS fixed_points
  FROM x y WHERE y.ai_id = x.ai_id
) o ON true
JOIN assessments a ON a.id = x.assessment_id
JOIN course_instances ci ON ci.id = a.course_instance_id
WHERE x.slot >= 4
GROUP BY ci.id, 1, x.slot, x.alt, 3 ORDER BY ci.id, x.slot, x.alt;
