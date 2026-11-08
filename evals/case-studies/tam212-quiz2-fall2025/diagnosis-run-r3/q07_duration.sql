-- Instance-level totals and durations for Fall2025 quiz02 (aggregate only)
WITH x AS (
  SELECT ai.score_perc, ai.points, EXTRACT(EPOCH FROM ai.duration)/60 AS mins,
    EXTRACT(EPOCH FROM (ai.closed_at - ai.date))/60 AS open_mins
  FROM assessment_instances ai WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics
)
SELECT COUNT(*) AS n, ROUND(AVG(score_perc)::numeric,1) AS mean_score,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY mins)::numeric,1) AS p50_dur_min,
  ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY mins)::numeric,1) AS p90_dur_min,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY mins)::numeric,1) AS p95_dur_min,
  ROUND(MAX(mins)::numeric,1) AS max_dur_min,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY open_mins)::numeric,1) AS p50_open_min,
  ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY open_mins)::numeric,1) AS p90_open_min,
  COUNT(*) FILTER (WHERE mins >= 45) AS n_ge45, COUNT(*) FILTER (WHERE mins >= 50) AS n_ge50, COUNT(*) FILTER (WHERE mins >= 55) AS n_ge55
FROM x;
