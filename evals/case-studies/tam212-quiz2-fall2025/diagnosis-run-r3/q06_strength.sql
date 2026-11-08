-- For each alternative in slots 4-8: mean points on that question, and mean points the same students earned on the rest of the quiz
-- (excluding that slot) as a check on group strength. Also total score and duration summaries.
WITH per AS (
  SELECT ai.id AS ai_id, ag.number AS slot, q.qid, iq.points, aq.max_points
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND aq.max_points > 0
), tot AS (SELECT ai_id, SUM(points) AS total FROM per GROUP BY ai_id)
SELECT p.slot, p.qid, COUNT(*) AS n, ROUND(AVG(p.points)::numeric,2) AS mean_pts, p.max_points,
  ROUND(AVG(t.total - p.points)::numeric,2) AS mean_rest_of_quiz_pts,
  ROUND(AVG(t.total)::numeric,2) AS mean_total
FROM per p JOIN tot t USING (ai_id)
GROUP BY p.slot, p.qid, p.max_points ORDER BY p.slot, p.qid;
