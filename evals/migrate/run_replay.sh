#!/bin/sh
# Replay a real term-to-term migration: calendar-shift SOURCE and compare it to the
# instance the instructor actually made. Usage:
#   run_replay.sh COURSE_INSTANCES_DIR SOURCE ACTUAL SOURCE_CAL TARGET_CAL WORKDIR
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
SCRIPT=$HERE/../../skills/migrate-course-instance/references/shift_dates.py
rm -rf "$6"; mkdir -p "$6"; cp -R "$1/$2" "$6/pred"
python3 "$SCRIPT" plan "$6/pred" --from "$4" --to "$5" --csv "$6/plan.csv" > "$6/plan.log"
python3 "$SCRIPT" apply "$6/pred" --plan "$6/plan.csv" > /dev/null
head -1 "$6/plan.log"
python3 "$HERE/evaluate.py" "$6/pred" "$1/$3"
