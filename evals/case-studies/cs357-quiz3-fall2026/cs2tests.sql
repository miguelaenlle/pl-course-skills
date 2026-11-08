WITH best AS (
  SELECT DISTINCT ON (iq.id) q.qid, s.feedback
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.feedback ? 'results'
  WHERE ci.course_id = 114 AND ci.short_name = 'Fall2026' AND a.tid = 'quiz3'
    AND q.qid IN ('09-Linsys/Linsys-SurveyElevations','09-Linsys/Linsys-MenuPrices')
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC
)
SELECT split_part(qid,'-',3) AS q, t->>'name' AS test, count(*) AS n,
  round((100*avg(((t->>'points')::numeric >= (t->>'max_points')::numeric)::int))::numeric,1) AS passed_pct
FROM best, LATERAL jsonb_array_elements(feedback->'results'->'tests') t
GROUP BY 1,2 ORDER BY 1,2;
