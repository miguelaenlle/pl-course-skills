#!/bin/bash
# usage: q3.sh query.sql out.csv [psql -v args...]
SQL=$1; OUT=$2; shift 2
cd /Users/miguel/PrairieLearn/repos/sysconf && pnpm -s alma rds us-prod --access readonly -- -X -q --csv -v ON_ERROR_STOP=1 "$@" -f "$SQL" -o "$OUT" 2>&1 | grep -E 'ERROR|LINE|^\s+\^|HINT|DETAIL' | head -10
