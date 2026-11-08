-- Assessment-level summary per offering
SELECT ci.short_name AS offering, COUNT(*) AS n,
  ROUND(AVG(ai.score_perc)::numeric, 1) AS mean_score_pct,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ai.score_perc))::numeric, 1) AS median_score_pct,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM ai.duration)) / 60)::numeric, 1) AS median_minutes,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (ai.date_limit - ai.date))) / 60)::numeric, 1) AS median_time_limit_min,
  COUNT(*) FILTER (WHERE ai.date_limit IS NULL) AS n_no_time_limit,
  MAX(ai.max_points) AS max_points
FROM assessment_instances ai
JOIN assessments a ON a.id = ai.assessment_id
JOIN course_instances ci ON ci.id = a.course_instance_id
WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND ai.include_in_statistics
GROUP BY ci.id, ci.short_name ORDER BY ci.id;

-- Coding zone: share of students who submitted nothing on each coding slot, and on both
WITH s AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, ai.id AS ai_id, ag.number AS slot, COALESCE(iq.some_submission, false) AS sub
  FROM assessment_instances ai
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  WHERE a.id IN (2491230, 2557979, 2619946, 2713999) AND ai.include_in_statistics AND ag.number IN (11, 12)
), p AS (
  SELECT ci_id, offering, ai_id, bool_or(sub) FILTER (WHERE slot = 11) AS sub11, bool_or(sub) FILTER (WHERE slot = 12) AS sub12
  FROM s GROUP BY 1, 2, 3)
SELECT offering, COUNT(*) AS n,
  ROUND(100 * AVG((NOT sub11)::int)::numeric, 1) AS no_sub_slot11_pct,
  ROUND(100 * AVG((NOT sub12)::int)::numeric, 1) AS no_sub_slot12_pct,
  ROUND(100 * AVG((NOT sub11 AND NOT sub12)::int)::numeric, 1) AS no_sub_both_pct
FROM p GROUP BY ci_id, offering ORDER BY ci_id;
