#!/bin/bash
# usage: run.sh queryname  -> runs queries/NAME.sql, writes results/NAME.txt
R=/private/tmp/claude-501/-Users-miguel-PrairieLearn-repos-PrairieLearn--claude-worktrees-course-agent-navigation/e82d327b-2578-4663-bbbe-dbb0a160124e/scratchpad/runs/r1-cs357-quiz4
cd /Users/miguel/PrairieLearn/repos/sysconf && pnpm -s alma rds us-prod --access readonly -- -v ON_ERROR_STOP=1 -P pager=off -A -F "|" -f $R/queries/$1.sql 2>&1 | sed -n '/^Access level/,$p' > $R/results/$1.txt
cat $R/results/$1.txt
