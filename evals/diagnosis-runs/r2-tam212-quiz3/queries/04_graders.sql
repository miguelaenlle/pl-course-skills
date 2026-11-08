-- Manual grading by grader (anonymized G1.. per offering by volume) for the written slot.
WITH iqs AS (
  SELECT ci.short_name AS offering, q.qid, iq.last_grader, iq.score_perc
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id=aq.question_id AND q.qid IN ('massFromCurveRadWritten','polyDistCurveAccWritten')
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  WHERE ci.course_id=:course_id AND ci.short_name IN ('Fall2025','Spring2026','Fall2026')
),
g AS (
  SELECT offering, last_grader, 'G' || ROW_NUMBER() OVER (PARTITION BY offering ORDER BY COUNT(*) DESC, last_grader) AS grader
  FROM iqs WHERE last_grader IS NOT NULL GROUP BY offering, last_grader
)
SELECT iqs.offering, COALESCE(g.grader,'none') AS grader, iqs.qid, COUNT(*) AS n,
  ROUND(AVG(iqs.score_perc)::numeric,1) AS mean_pct,
  ROUND((100*AVG((iqs.score_perc>=100)::int))::numeric,1) AS full_pct
FROM iqs LEFT JOIN g ON g.offering=iqs.offering AND g.last_grader=iqs.last_grader
GROUP BY iqs.offering, COALESCE(g.grader,'none'), iqs.qid
ORDER BY iqs.offering, grader, iqs.qid;
