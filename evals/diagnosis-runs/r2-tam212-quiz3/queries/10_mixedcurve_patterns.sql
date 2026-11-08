-- RadCurveMixedCurve: how the x-component appears in the copyable Python inputs (digits masked), with mean final score.
WITH v1 AS (
  SELECT DISTINCT ON (iq.id) ci.short_name AS offering, iq.score_perc,
    regexp_replace(v.params->>'xcomp', '[0-9]+', 'N', 'g') AS pattern
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id=aq.question_id AND q.qid='RadCurveMixedCurve'
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  WHERE ci.course_id=:course_id AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
  ORDER BY iq.id, v.date DESC
)
SELECT offering, pattern, COUNT(*) n, ROUND(AVG(score_perc)::numeric,1) mean_final_pct
FROM v1 GROUP BY offering, pattern ORDER BY offering, n DESC;
