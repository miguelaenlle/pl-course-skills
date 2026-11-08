-- Fall2025 quiz02: per-student "draw effect" = sum over randomized slots (4-8) of (mean points of the drawn alternative - mean points of the slot).
-- Output only the distribution (buckets), never per-student values.
WITH per AS (
  SELECT ai.id ai_id, ag.number slot, q.qid, iq.points
  FROM assessment_instances ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics AND ag.number BETWEEN 4 AND 8
), alt AS (SELECT slot, qid, AVG(points) m FROM per GROUP BY 1,2),
slotm AS (SELECT slot, AVG(points) m FROM per GROUP BY 1),
eff AS (
  SELECT p.ai_id,
    SUM(a.m - s.m) AS eff_all,
    SUM(a.m - s.m) FILTER (WHERE p.slot IN (6,7,8)) AS eff_678
  FROM per p JOIN alt a USING (slot, qid) JOIN slotm s USING (slot) GROUP BY p.ai_id
)
SELECT 'slots 4-8' AS scope, COUNT(*) n, ROUND(MIN(eff_all)::numeric,1) min_eff, ROUND(MAX(eff_all)::numeric,1) max_eff,
  ROUND(100*AVG((eff_all <= -5)::int),1) pct_le_minus5, ROUND(100*AVG((eff_all <= -8)::int),1) pct_le_minus8,
  ROUND(100*AVG((eff_all >= 5)::int),1) pct_ge_plus5,
  ROUND(PERCENTILE_CONT(0.1) WITHIN GROUP (ORDER BY eff_all)::numeric,1) p10, ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY eff_all)::numeric,1) p90
FROM eff
UNION ALL
SELECT 'slots 6-8', COUNT(*), ROUND(MIN(eff_678)::numeric,1), ROUND(MAX(eff_678)::numeric,1),
  ROUND(100*AVG((eff_678 <= -5)::int),1), ROUND(100*AVG((eff_678 <= -8)::int),1), ROUND(100*AVG((eff_678 >= 5)::int),1),
  ROUND(PERCENTILE_CONT(0.1) WITHIN GROUP (ORDER BY eff_678)::numeric,1), ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY eff_678)::numeric,1)
FROM eff;
