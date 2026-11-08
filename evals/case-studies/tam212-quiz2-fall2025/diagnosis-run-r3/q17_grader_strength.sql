-- Slot 5: grader (anonymized) vs the same students' autograded points on the rest of Quiz 2 (strength check), and the "final answer" rubric item rate
WITH x AS (
  SELECT ai.id ai_id, iq.last_grader, iq.score_perc, iq.id iq_id
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND ag.number = 5 AND iq.last_grader IS NOT NULL
), g AS (
  SELECT last_grader, 'G' || ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC, last_grader) AS grader FROM x GROUP BY last_grader
), rest AS (
  SELECT iq.assessment_instance_id ai_id, SUM(iq.points) pts
  FROM instance_questions iq JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  WHERE aq.assessment_id = 2574213 AND ag.number <> 5 GROUP BY 1
), fa AS (
  SELECT x.iq_id, bool_or(ri.description = 'Correct final answer') AS final_ok
  FROM x JOIN LATERAL (SELECT s.manual_rubric_grading_id FROM variants v JOIN submissions s ON s.variant_id=v.id
                WHERE v.instance_question_id = x.iq_id AND s.manual_rubric_grading_id IS NOT NULL ORDER BY s.date DESC LIMIT 1) ls ON true
  JOIN rubric_grading_items rgi ON rgi.rubric_grading_id = ls.manual_rubric_grading_id JOIN rubric_items ri ON ri.id = rgi.rubric_item_id
  GROUP BY x.iq_id
)
SELECT g.grader, COUNT(*) n, ROUND(AVG(x.score_perc)::numeric,1) slot5_mean_pct, ROUND(AVG(rest.pts)::numeric,1) rest_of_quiz_pts_of_80,
  ROUND(100*AVG(fa.final_ok::int),1) final_answer_item_pct
FROM x JOIN g USING (last_grader) JOIN rest USING (ai_id) LEFT JOIN fa USING (iq_id)
GROUP BY g.grader HAVING COUNT(*) >= 5 ORDER BY g.grader;
