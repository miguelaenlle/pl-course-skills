-- Share of students using nearly all of the (inferred ~50 min) time, by slot-6 alternative
SELECT ci.short_name AS offering, q.qid AS slot6_alternative, COUNT(*) AS n,
  ROUND((100 * AVG((ai.duration >= interval '47 minutes')::int))::numeric, 1) AS pct_47min_or_more,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration)) / 60)::numeric, 1) AS median_total_min,
  ROUND(AVG(ai.score_perc)::numeric, 1) AS mean_assessment_pct
FROM assessment_instances ai
JOIN assessments a ON a.id = ai.assessment_id
JOIN course_instances ci ON ci.id = a.course_instance_id
JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id AND ag.number = 6
JOIN questions q ON q.id = aq.question_id
WHERE ai.include_in_statistics AND ai.assessment_id IN (2434746, 2497144, 2574213, 2634479, 2716830)
GROUP BY ci.id, 1, 2 ORDER BY ci.id, 2;
