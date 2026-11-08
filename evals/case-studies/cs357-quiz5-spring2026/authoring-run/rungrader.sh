#!/bin/bash
# usage: rungrader.sh QUESTION_DIR SUBMISSION.py OUTNAME
set -e
Q=$1; S=$2; N=$3
D=$(pwd)/jobs/$N; rm -rf $D; mkdir -p $D/student $D/data
cp -r $Q/tests $D/tests; cp $S $D/student/user_code.py
python3 - "$Q" "$D" <<'PY'
import json, sys, importlib.util
q, d = sys.argv[1], sys.argv[2]
spec = importlib.util.spec_from_file_location("s", q + "/server.py"); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
data = m.generate({"params": {}, "correct_answers": {}})
json.dump({"params": data["params"], "correct_answers": {}, "submitted_answers": {}, "format_errors": {}, "partial_scores": {}, "score": 0, "feedback": {}, "variant_seed": 1, "options": {}, "raw_submitted_answers": {}, "gradable": True}, open(d + "/data/data.json", "w"))
PY
docker run --rm -v $D:/grade prairielearn/grader-python /python_autograder/run.sh > $D/stdout.txt 2>&1
python3 -c "
import json,sys; r=json.load(open('$D/results/results.json'))
print('$N', 'score=%.4f'%r.get('score',-1), [(t['name'], t['points'], t['max_points']) for t in r.get('tests',[])])
for t in r.get('tests',[]):
    if t.get('output'): print('   ', t['name'], repr(t['output'][:200]))
if r.get('output'): print('   output:', repr(r['output'][:300]))
"
