-- Manual / staff score changes in Fall2026 quiz3, aggregated per question and day
SELECT q.qid, qsl.date::date AS day, COUNT(*) AS n_changes, COUNT(DISTINCT qsl.instance_question_id) AS n_iq,
  ROUND(AVG(qsl.score_perc)::numeric,1) AS mean_new_pct,
  ROUND(AVG(qsl.score_perc - COALESCE(prev.score_perc,0))::numeric,1) AS mean_delta_pct
FROM question_score_logs qsl
JOIN instance_questions iq ON iq.id = qsl.instance_question_id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN questions q ON q.id = aq.question_id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
LEFT JOIN LATERAL (SELECT p.score_perc FROM question_score_logs p WHERE p.instance_question_id = qsl.instance_question_id AND p.date < qsl.date ORDER BY p.date DESC LIMIT 1) prev ON true
WHERE aq.assessment_id = 2713997 AND qsl.grading_job_id IS NULL
GROUP BY q.qid, day ORDER BY q.qid, day;

-- Instances with more than one question in slot 9 / 10 / any slot
SELECT z.number AS zone, ag.number AS slot, cnt, COUNT(*) AS n_instances FROM (
  SELECT ai.id, ag.id AS agid, COUNT(*) AS cnt
  FROM assessment_instances ai JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  WHERE ai.assessment_id = 2713997 AND ai.include_in_statistics GROUP BY ai.id, ag.id) x
JOIN alternative_groups ag ON ag.id = x.agid JOIN zones z ON z.id = ag.zone_id
GROUP BY z.number, ag.number, cnt HAVING cnt > 1 ORDER BY 1,2;

-- assessment-instance-level: score, duration distribution, number per start day, multiple instances per user
SELECT ai.date::date AS start_day, COUNT(*) AS n, ROUND(AVG(ai.score_perc)::numeric,1) AS mean_score,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration))/60)::numeric,1) AS med_dur_min,
  ROUND((PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration))/60)::numeric,1) AS p90_dur_min
FROM assessment_instances ai WHERE ai.assessment_id = 2713997 AND ai.include_in_statistics GROUP BY 1 ORDER BY 1;
SELECT COUNT(*) AS n_inst, COUNT(DISTINCT ai.user_id) AS n_users, COUNT(DISTINCT ai.team_id) AS n_teams, MAX(ai.number) AS max_number, ROUND(AVG(ai.score_perc)::numeric,1) AS mean, MAX(ai.max_points) AS max_points FROM assessment_instances ai WHERE ai.assessment_id = 2713997 AND ai.include_in_statistics;
SELECT width_bucket(EXTRACT(EPOCH FROM ai.duration)/60, 0, 120, 12) AS bucket10min, COUNT(*) FROM assessment_instances ai WHERE ai.assessment_id = 2713997 AND ai.include_in_statistics GROUP BY 1 ORDER BY 1;
