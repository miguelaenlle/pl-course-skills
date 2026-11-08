WITH aqs AS (
  SELECT aq.id AS aq_id, q.qid,
    ag.number || CASE WHEN (SELECT count(*) FROM assessment_questions x WHERE x.alternative_group_id = ag.id AND x.deleted_at IS NULL) > 1
                      THEN '.' || aq.number_in_alternative_group ELSE '' END AS question_number,
    ci.short_name, a.tid, a.title
  FROM assessment_questions aq
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  JOIN assessments a ON a.id = aq.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  WHERE ci.course_id = 114 AND ci.short_name = 'Fall2026' AND a.tid = 'quiz3' AND aq.deleted_at IS NULL
    AND q.qid IN ('09-Linsys/Linsys-SurveyElevations','09-Linsys/Linsys-MenuPrices')
)
SELECT aqs.short_name, aqs.tid, aqs.title, aqs.question_number, aqs.qid, count(*) AS n,
  round(avg(iq.score_perc)::numeric,1) AS final_now,
  round((100*avg(coalesce(iq.max_submission_score,0)))::numeric,1) AS best_all_assigned,
  round((100*avg((coalesce(iq.max_submission_score,0) >= 1)::int))::numeric,1) AS full_credit_best,
  round((100*avg((NOT EXISTS (SELECT 1 FROM variants v JOIN submissions s ON s.variant_id=v.id WHERE v.instance_question_id=iq.id))::int))::numeric,1) AS no_sub,
  round((100*avg(iq.first_submission_score) FILTER (WHERE iq.first_submission_score IS NOT NULL))::numeric,1) AS first_sub
FROM aqs JOIN instance_questions iq ON iq.assessment_question_id = aqs.aq_id
JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
GROUP BY 1,2,3,4,5 ORDER BY 4;
