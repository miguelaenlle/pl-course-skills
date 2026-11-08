SELECT (l.date AT TIME ZONE 'America/Chicago')::date AS day, (l.grading_job_id IS NULL) AS manual, COUNT(*) AS n,
  ROUND(AVG(iq.score_perc)::numeric,1) AS current_mean
FROM question_score_logs l
JOIN instance_questions iq ON iq.id = l.instance_question_id
JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
JOIN questions q ON q.id = aq.question_id
JOIN assessments a ON a.id = aq.assessment_id
JOIN course_instances ci ON ci.id = a.course_instance_id
WHERE ci.course_id = 114 AND ci.short_name = 'Fall2026' AND a.tid = 'quiz3'
  AND q.qid LIKE '%SurveyElevations' AND l.date > '2026-10-19'
GROUP BY 1,2 ORDER BY 1;
