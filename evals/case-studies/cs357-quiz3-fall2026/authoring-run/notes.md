Survey Elevations = question 911, Menu Prices = 897 on localhost:3020 (course 1).
Baseline grader checks (Docker, before edit): missing benchmark row -> A is (n-1)x n, la.solve raises, whole submission 0
with only a numpy traceback. Benchmark-first ordering -> 20% (elevations right, every A row/b entry "wrong").
Menu ignoring quantities -> 25-34%, or 0 when the resulting A is singular (seeds 3, 14, 15).
After edit: correct ref solution 100% on seeds 1-3, 7, 11-15 for both; mistakes score as before, feedback now names rows.
