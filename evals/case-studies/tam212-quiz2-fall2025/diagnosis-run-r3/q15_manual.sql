-- Slot 5 manual grading (Fall2025 quiz02): mean score by alternative and anonymized grader (G1.. by volume)
WITH x AS (
  SELECT q.qid, iq.last_grader, iq.score_perc
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND ag.number = 5
), g AS (
  SELECT last_grader, 'G' || ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, last_grader) AS grader FROM x WHERE last_grader IS NOT NULL GROUP BY last_grader
)
SELECT COALESCE(g.grader,'none') grader, x.qid, COUNT(*) n, ROUND(AVG(score_perc)::numeric,1) mean_pct,
  ROUND(100*AVG((score_perc>=100)::int),1) full_pct
FROM x LEFT JOIN g USING (last_grader) GROUP BY ROLLUP(g.grader, x.qid) ORDER BY 1,2;
