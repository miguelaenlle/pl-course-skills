\echo == SurveyElevations: original vs 2026-10-25 regrade score per submission (bucketed counts)
WITH j AS (
  SELECT gj.submission_id, gj.date, gj.score, gj.feedback,
    ROW_NUMBER() OVER (PARTITION BY gj.submission_id ORDER BY gj.date) AS rn,
    COUNT(*) OVER (PARTITION BY gj.submission_id) AS nj
  FROM grading_jobs gj JOIN submissions s ON s.id = gj.submission_id JOIN variants v ON v.id = s.variant_id
  JOIN instance_questions iq ON iq.id = v.instance_question_id JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id = 2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations')
SELECT ROUND(100*a.score/5)*5 AS orig_b, ROUND(100*b.score/5)*5 AS regrade_b, COUNT(*)
FROM j a JOIN j b ON a.submission_id = b.submission_id AND a.rn = 1 AND b.rn = b.nj AND b.nj > 1
GROUP BY 1,2 ORDER BY 1,2;
\echo == A-test message category: original vs regrade
WITH j AS (
  SELECT gj.submission_id, gj.feedback,
    ROW_NUMBER() OVER (PARTITION BY gj.submission_id ORDER BY gj.date) AS rn,
    COUNT(*) OVER (PARTITION BY gj.submission_id) AS nj
  FROM grading_jobs gj JOIN submissions s ON s.id = gj.submission_id JOIN variants v ON v.id = s.variant_id
  JOIN instance_questions iq ON iq.id = v.instance_question_id JOIN assessment_questions aq ON aq.id = iq.assessment_question_id JOIN questions q ON q.id = aq.question_id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  WHERE aq.assessment_id = 2713997 AND q.qid='09-Linsys/Linsys-SurveyElevations'),
m AS (SELECT submission_id, rn, nj, (SELECT LEFT(regexp_replace(t->>'message','[0-9]+','#','g'),60) FROM jsonb_array_elements(feedback->'results'->'tests') t WHERE t->>'name'='Coefficient matrix A') AS amsg FROM j)
SELECT a.amsg AS orig, b.amsg AS regrade, COUNT(*) FROM m a JOIN m b ON a.submission_id=b.submission_id AND a.rn=1 AND b.rn=b.nj AND b.nj>1 GROUP BY 1,2 ORDER BY 3 DESC;
