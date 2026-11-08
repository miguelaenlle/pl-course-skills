#!/bin/bash
# usage: run.sh query.sql out.csv [extra psql args]; strips connection log lines
q=$1; out=$2; shift 2
cd /Users/miguel/PrairieLearn/repos/sysconf && pnpm -s alma rds us-prod --access readonly -- -X -q -A -F ',' -v ON_ERROR_STOP=1 -v course_id=1 "$@" -f "$q" 2>&1 \
 | grep -v -E '^\$ |^Injecting|^Opening|^Waiting|^Access level|^\[WARN\]|^Starting session|^Port |^Connection|^$|@' > "$out"
