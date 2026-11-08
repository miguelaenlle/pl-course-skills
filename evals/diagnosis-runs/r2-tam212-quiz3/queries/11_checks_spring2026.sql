-- Spring2026 quiz03 checks: (a) alternatives by exam day, (b) staff score changes, (c) finals set to 100 above best submission.
WITH base AS (
  SELECT ag.number AS slot, q.qid, ai.date::date AS day, iq.id AS iq_id, iq.score_perc, iq.max_submission_score, iq.some_submission
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL AND aq.max_points > 0
  JOIN alternative_groups ag ON ag.id=aq.alternative_group_id
  JOIN questions q ON q.id=aq.question_id
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id=:course_id AND ci.short_name='Spring2026'
)
SELECT 'a_by_day' AS check_name, slot::text, qid, day::text AS detail, COUNT(*) AS n, ROUND(AVG(score_perc)::numeric,1) AS mean_final_pct
FROM base WHERE slot IN (4,5,6,7,8) GROUP BY slot, qid, day
UNION ALL
SELECT 'b_staff_score_changes', b.slot::text, b.qid, 'iq with manual/staff score log rows', COUNT(DISTINCT b.iq_id), NULL
FROM base b JOIN question_score_logs l ON l.instance_question_id=b.iq_id AND l.grading_job_id IS NULL
GROUP BY b.slot, b.qid
UNION ALL
SELECT 'c_final_100_above_best', slot::text, qid, 'score 100 but best submission < 1', COUNT(*), NULL
FROM base WHERE score_perc >= 100 AND some_submission AND max_submission_score < 1 GROUP BY slot, qid
ORDER BY 1,2,3,4;
