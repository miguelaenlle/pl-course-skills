#!/bin/bash
# usage: run.sh query.sql result.csv [psql -v args...]
q=$1; o=$2; shift 2
cd /Users/miguel/PrairieLearn/repos/sysconf && pnpm -s alma rds us-prod --access readonly -- -X -q --csv -v ON_ERROR_STOP=1 "$@" -f "$q" -o "$o" 2>&1 | grep -E "ERROR|error|FATAL" || true
