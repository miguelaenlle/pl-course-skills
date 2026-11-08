-- Manually graded written questions (slot 5): rubric item use and scores by grader (graders anonymized)
WITH graded AS (
  SELECT DISTINCT ON (iq.id) ci.id ci_id, ci.short_name offering, q.qid, iq.id iq_id, iq.score_perc, iq.last_grader, s.manual_rubric_grading_id rg
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.manual_rubric_grading_id IS NOT NULL
  WHERE a.id IN (2574213, 2634479, 2716830) AND q.qid IN ('fcnPosSpeedWritten','distFromVelWritten')
  ORDER BY iq.id, s.date DESC
), items AS (
  SELECT g.ci_id, g.offering, g.qid, ri.number, ri.description, ri.points, COUNT(DISTINCT g.iq_id) n_applied
  FROM graded g JOIN rubric_grading_items rgi ON rgi.rubric_grading_id = g.rg
  JOIN rubric_items ri ON ri.id = rgi.rubric_item_id
  GROUP BY 1,2,3,4,5,6
), tot AS (SELECT ci_id, qid, COUNT(*) n_graded FROM graded GROUP BY 1,2)
SELECT 'rubric_item' AS kind, i.offering, i.qid, i.number::text AS item_or_grader, i.description, i.points, t.n_graded, i.n_applied,
  ROUND(100.0*i.n_applied/t.n_graded,1) AS pct, NULL::numeric AS mean_score
FROM items i JOIN tot t USING (ci_id, qid)
UNION ALL
SELECT 'grader', g.offering, g.qid, 'G' || DENSE_RANK() OVER (PARTITION BY g.ci_id ORDER BY g.last_grader), NULL, NULL, NULL, COUNT(*), NULL, ROUND(AVG(g.score_perc)::numeric,1)
FROM graded g GROUP BY g.ci_id, g.offering, g.qid, g.last_grader
ORDER BY 2, 3, 1 DESC, 4;
