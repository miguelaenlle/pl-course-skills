#!/bin/sh
# Run one benchmark cell: the course agent's model in Codex on one task, in one arm.
#   run.sh WORKDIR TASK ARM REP
# WORKDIR holds fixtures/TASK (from build_fixture.py) and gets runs/TASK/ARM/REP.
# Arms: none (no skill), docs (skill text without the script), full (skill as in the PR).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$1 TASK=$2 ARM=$3 REP=$4
MODEL=${MODEL:-gpt-6-luna}
RUN=$WORK/runs/$TASK/$ARM/$REP
PROMPT=$(cat "$HERE/tasks/$TASK.txt")

rm -rf "$RUN"
mkdir -p "$RUN/codex" "$RUN/home/migration"
# APFS clone, so each run's copy of the course costs no disk.
cp -Rc "$WORK/fixtures/$TASK" "$RUN/course"

ln -s "$HOME/.codex/auth.json" "$RUN/codex/auth.json"
cat > "$RUN/codex/config.toml" <<EOF
model = "$MODEL"
web_search = "live"
[skills.bundled]
enabled = false
EOF
if [ "$ARM" != none ]; then
  mkdir -p "$RUN/codex/skills"
  cp -R "$HERE/arms/$ARM/migrate-course-instance" "$RUN/codex/skills/"
  # The skill names the script by its path in the sandbox image.
  # The script needs Python 3.10+ (the image has 3.11); macOS's own python3 is 3.9.
  sed -i '' "s|python3 /etc/codex/skills|${PYTHON:-python3} /etc/codex/skills|g; s|/etc/codex/skills|$RUN/codex/skills|g" \
    "$RUN/codex/skills/migrate-course-instance/SKILL.md"
fi

START=$(date +%s)
cd "$RUN/course"
HOME="$RUN/home" CODEX_HOME="$RUN/codex" codex exec --json -s workspace-write \
  --add-dir "$RUN/home" -o "$RUN/final.md" "$PROMPT" \
  < /dev/null > "$RUN/events.jsonl" 2> "$RUN/stderr.log" || echo "exit $?" > "$RUN/failed"
echo $(($(date +%s) - START)) > "$RUN/seconds"
