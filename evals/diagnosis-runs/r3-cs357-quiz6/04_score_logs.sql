-- Staff score changes (grading_job_id IS NULL) by question and offering
SELECT ci.short_name AS offering, q.qid,
  COUNT(*) AS n_changes, COUNT(DISTINCT qsl.instance_question_id) AS n_iqs,
  COUNT(*) FILTER (WHERE qsl.score_perc >= 100) AS n_to_full,
  MIN(qsl.date)::date AS first_day, MAX(qsl.date)::date AS last_day,
  ROUND(AVG(qsl.score_perc)::numeric,1) AS mean_new_score_perc
FROM question_score_logs qsl
JOIN instance_questions iq ON iq.id=qsl.instance_question_id
JOIN assessment_questions aq ON aq.id=iq.assessment_question_id
JOIN assessments a ON a.id=aq.assessment_id
JOIN course_instances ci ON ci.id=a.course_instance_id
JOIN questions q ON q.id=aq.question_id
JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
WHERE a.id IN (2323467,2324012,2355373,2388044,2444565,2491236,2557983,2619950)
  AND qsl.grading_job_id IS NULL
GROUP BY 1,2 ORDER BY 1,2;
