SELECT width_bucket(EXTRACT(EPOCH FROM ai.duration)/60, 0, 120, 24)*5 AS upto_min, COUNT(*) AS n
FROM assessment_instances ai WHERE ai.assessment_id = 2574213 AND ai.include_in_statistics GROUP BY 1 ORDER BY 1;
