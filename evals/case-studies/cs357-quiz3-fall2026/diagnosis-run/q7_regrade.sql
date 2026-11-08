\echo == SurveyElevations 2026-10-25 manual changes: before -> after (bucketed to 5 pct), counts
WITH ch AS (
  SELECT qsl.instance_question_id, qsl.date, qsl.score_perc AS new_pct, qsl.auth_user_id,
    (SELECT p.score_perc FROM question_score_logs p WHERE p.instance_question_id = qsl.instance_question_id AND p.date < qsl.date ORDER BY p.date DESC LIMIT 1) AS old_pct
  FROM question_score_logs qsl
  JOIN instance_questions iq ON iq.id = qsl.instance_question_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id = 2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations' AND qsl.grading_job_id IS NULL)
SELECT ROUND(COALESCE(old_pct,0)/5)*5 AS old_b, ROUND(new_pct/5)*5 AS new_b, COUNT(*) AS n FROM ch GROUP BY 1,2 ORDER BY 1,2;
\echo == number of distinct staff making those changes, time span
SELECT COUNT(DISTINCT qsl.auth_user_id) AS n_staff, MIN(qsl.date)::time AS first_t, MAX(qsl.date)::time AS last_t
FROM question_score_logs qsl JOIN instance_questions iq ON iq.id = qsl.instance_question_id JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
WHERE aq.assessment_id = 2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations' AND qsl.grading_job_id IS NULL;
\echo == regrades (grading jobs) after the exam window, per coding question
SELECT q.qid, gj.date::date AS day, COUNT(*) AS n_jobs
FROM grading_jobs gj JOIN submissions s ON s.id = gj.submission_id JOIN variants v ON v.id = s.variant_id
JOIN instance_questions iq ON iq.id = v.instance_question_id JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
WHERE aq.assessment_id = 2713997 AND gj.date > '2026-10-18' GROUP BY 1,2 ORDER BY 1,2;
\echo == all instances of SurveyElevations: final vs max_submission (bucketed)
SELECT ROUND(100*COALESCE(iq.max_submission_score,0)/5)*5 AS best_sub_b, ROUND(iq.score_perc/5)*5 AS final_b, COUNT(*)
FROM instance_questions iq JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE aq.assessment_id = 2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations' GROUP BY 1,2 ORDER BY 1,2;
