-- Offerings of Quiz 4 (tid quiz04 / quiz04r) in course 1, with instance counts.
SELECT current_setting('transaction_read_only') AS read_only;
SELECT ci.id AS ci_id, ci.short_name, a.id AS assessment_id, a.tid, a.title, a.type, a.number,
       a.deleted_at IS NOT NULL AS deleted,
       COUNT(ai.id) FILTER (WHERE ai.include_in_statistics) AS n_stat_instances,
       COUNT(ai.id) AS n_all_instances,
       MIN(ai.date)::date AS first_date, MAX(ai.date)::date AS last_date
FROM course_instances ci
JOIN assessments a ON a.course_instance_id = ci.id
LEFT JOIN assessment_instances ai ON ai.assessment_id = a.id
WHERE ci.course_id = 1 AND ci.deleted_at IS NULL
  AND a.tid IN ('quiz04','quiz04r','quiz04p')
  AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Su26','Fall2026','ZJUI-Spring2026','ZJUI-Spring2025')
GROUP BY 1,2,3,4,5,6,7,8
ORDER BY ci.id, a.tid;
