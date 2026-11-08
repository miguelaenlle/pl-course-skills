-- Staff score changes (grading_job_id IS NULL) on Fall2025 quiz02, by question
SELECT q.qid, ag.number AS slot, COUNT(*) AS n_changes, COUNT(DISTINCT qsl.instance_question_id) AS n_iq,
  ROUND(AVG(qsl.score_perc - COALESCE(qsl.max_points,0)*0)::numeric,1) AS mean_new_score_perc,
  MIN((qsl.date AT TIME ZONE 'America/Chicago')::date) AS first_day, MAX((qsl.date AT TIME ZONE 'America/Chicago')::date) AS last_day,
  COUNT(*) FILTER (WHERE q.grading_method <> 'Manual') AS n_on_auto_q
FROM question_score_logs qsl
JOIN instance_questions iq ON iq.id = qsl.instance_question_id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
JOIN questions q ON q.id = aq.question_id
WHERE ai.assessment_id = 2574213 AND qsl.grading_job_id IS NULL
GROUP BY q.qid, ag.number ORDER BY slot, q.qid;
