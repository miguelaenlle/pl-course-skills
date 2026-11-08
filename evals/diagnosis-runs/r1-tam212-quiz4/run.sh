#!/bin/bash
# usage: run.sh NN_name   (runs queries/NN_name.sql, writes results/NN_name.txt)
R=/private/tmp/claude-501/-Users-miguel-PrairieLearn-repos-PrairieLearn--claude-worktrees-course-agent-navigation/e82d327b-2578-4663-bbbe-dbb0a160124e/scratchpad/runs/r1-tam212-quiz4
cd /Users/miguel/PrairieLearn/repos/sysconf && pnpm -s alma rds us-prod --access readonly -- -v ON_ERROR_STOP=1 -P pager=off -f $R/queries/$1.sql 2>&1 | grep -v -E "^\\$|Injecting|Opening|Starting session|Port .* opened|Waiting for|Access level|^$" > $R/results/$1.txt
cat $R/results/$1.txt
