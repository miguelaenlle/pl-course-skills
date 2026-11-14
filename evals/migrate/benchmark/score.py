"""Score benchmark runs. Usage: score.py WORKDIR COURSES_DIR SCHEMAS_DIR [--json OUT]

Checks each run's migrated course instance against the skill's own success
criteria, without using shift_dates.py, so no arm is graded by its own tool:

- week:     release and due dates in the same week of instruction as the source
- slot:     release and due dates on the same weekday and at the same time
- conflict: deadlines on a holiday or in a break of the target term
- stale:    dates still before the target term (synced assessments only)
- order:    assessments whose release is after their due date
- uid:      per-student (UID) rules left in the copy
- outside:  files changed outside the new course instance
- invalid:  files that fail PrairieLearn's JSON schemas
- actual:   release and due dates within 3 days of the instance the instructor really made

COURSES_DIR holds the real course checkouts (for `actual`); SCHEMAS_DIR is
apps/prairielearn/src/schemas/schemas in a PrairieLearn checkout.
"""

import datetime as dt
import glob
import json
import os
import re
import subprocess
import sys

import jsonschema

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from normalize import load, norm  # noqa: E402

DATE = re.compile(r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}")


def day(s):
    return dt.date.fromisoformat(s)


def monday(d):
    return d - dt.timedelta(days=d.weekday())


class Calendar:
    def __init__(self, path):
        c = json.load(open(path))
        self.begin = day(c["instructionBegins"])
        self.holidays = {day(h["date"]) for h in c.get("holidays", [])}
        self.breaks = [(day(b["start"]), day(b["end"])) for b in c.get("breaks", [])]
        self.end = day(c["finals"]["end"]) if c.get("finals") else day(c["instructionEnds"])

    def in_break(self, d):
        return any(a <= d <= b for a, b in self.breaks)

    def off(self, d):
        return d in self.holidays or self.in_break(d)

    def week(self, d):
        """Index of d's week among the weeks that have instruction, or None in a break week."""

        def teaching(m):
            return not all(self.in_break(m + dt.timedelta(days=i)) for i in range(5))

        m, target = monday(self.begin), monday(d)
        if not teaching(target):
            return None
        n, step = 0, 1 if target >= m else -1
        while m != target:
            if step == 1:
                n += teaching(m)
                m += dt.timedelta(days=7)
            else:
                m -= dt.timedelta(days=7)
                n -= teaching(m)
        return n


def all_dates(o, in_uid=False):
    if isinstance(o, dict):
        in_uid = in_uid or bool(o.get("uids"))
        for v in o.values():
            yield from all_dates(v, in_uid)
    elif isinstance(o, list):
        for v in o:
            yield from all_dates(v, in_uid)
    elif isinstance(o, str) and DATE.match(o) and not in_uid:
        yield dt.datetime.fromisoformat(o[:19].replace(" ", "T"))


def count_uid_rules(o):
    if isinstance(o, dict):
        return bool(o.get("uids")) + sum(count_uid_rules(v) for v in o.values())
    if isinstance(o, list):
        return sum(count_uid_rules(v) for v in o)
    return 0


def usage(run):
    u = {"input": 0, "cached": 0, "output": 0, "commands": 0, "searches": 0, "used_script": False}
    path = os.path.join(run, "events.jsonl")
    if not os.path.exists(path):
        return u
    for line in open(path):
        if "shift_dates.py" in line:
            u["used_script"] = True
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        if e.get("type") == "turn.completed":
            x = e.get("usage", {})
            u["input"] += x.get("input_tokens", 0)
            u["cached"] += x.get("cached_input_tokens", 0)
            u["output"] += x.get("output_tokens", 0)
        if e.get("type") == "item.completed":
            kind = e.get("item", {}).get("type")
            u["commands"] += kind == "command_execution"
            u["searches"] += kind == "web_search"
    return u


def score(run, task, courses, schemas):
    course = os.path.join(run, "course")
    r = {"finished": not os.path.exists(os.path.join(run, "failed"))}
    r.update(usage(run))
    seconds = os.path.join(run, "seconds")
    r["minutes"] = round(int(open(seconds).read()) / 60, 1) if os.path.exists(seconds) else None

    changed = subprocess.run(
        ["git", "-C", course, "status", "--porcelain", "-uall"], capture_output=True, text=True, check=True
    ).stdout.splitlines()
    paths = [line[3:].strip('"') for line in changed]
    new = sorted({p.split("/")[1] for p in paths if p.startswith("courseInstances/") and line_is_new(course, p)})
    new = [n for n in new if not os.path.exists(os.path.join(courses_fixture(run), "courseInstances", n))]
    r["instance"] = ",".join(new) or None
    if len(new) != 1:
        return r
    ci = os.path.join(course, "courseInstances", new[0])
    r["outside"] = sum(not p.startswith(f"courseInstances/{new[0]}/") for p in paths)

    src_cal = Calendar(os.path.join(HERE, "calendars", task["from"]))
    dst_cal = Calendar(os.path.join(HERE, "calendars", task["to"]))
    src = load(os.path.join(course, "courseInstances", task["source"]))

    invalid = uid = stale = 0
    pred = {}
    for f in glob.glob(f"{ci}/**/info*.json", recursive=True):
        name = os.path.basename(f)
        if name not in ("infoAssessment.json", "infoCourseInstance.json"):
            continue
        try:
            data = json.load(open(f))
            jsonschema.validate(data, json.load(open(os.path.join(schemas, name))))
        except (json.JSONDecodeError, jsonschema.ValidationError):
            invalid += 1
            continue
        uid += count_uid_rules(data)
        # Folders PrairieLearn doesn't sync (assessments-not-used/) are meant to be left alone.
        if name == "infoCourseInstance.json" or "/assessments/" in f:
            stale += sum(d.date() < dst_cal.begin - dt.timedelta(days=30) for d in all_dates(data))
        if name == "infoAssessment.json" and "/assessments/" in f:
            pred[os.path.relpath(os.path.dirname(f), f"{ci}/assessments")] = norm(data)
    r.update(invalid=invalid, uid=uid, stale=stale, assessments=len(pred), source_assessments=len(src))

    week = slot = pairs = order = conflict = 0
    for tid, p in pred.items():
        if p["release"] and p["due"] and p["release"] > p["due"]:
            order += 1
        deadlines = [p["due"], p["end"], *[d for d, _ in p["late"]], *[d for d, _ in p["early"]]]
        conflict += sum(dst_cal.off(d.date()) for d in deadlines if d)
        s = src.get(tid)
        if not s:
            continue
        for field in ("release", "due"):
            a, b = s[field], p[field]
            if not a or not b or not (src_cal.begin - dt.timedelta(days=14) <= a.date() <= src_cal.end):
                continue
            pairs += 1
            wa = src_cal.week(a.date())
            week += wa is not None and wa == dst_cal.week(b.date())
            slot += (a.weekday(), a.time()) == (b.weekday(), b.time())
    r.update(pairs=pairs, week=week, slot=slot, order=order, conflict=conflict)

    if task["actual"]:
        actual = load(os.path.join(courses, task["actual"]))
        near = total = 0
        for tid in set(pred) & set(actual):
            for field in ("release", "due"):
                a, b = pred[tid][field], actual[tid][field]
                if a and b:
                    total += 1
                    near += abs((a.date() - b.date()).days) <= 3
        r.update(actual_pairs=total, actual_near=near)
    return r


def courses_fixture(run):
    work = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(run))))
    return os.path.join(work, "fixtures", os.path.basename(os.path.dirname(os.path.dirname(run))))


def line_is_new(course, path):
    return os.path.exists(os.path.join(course, path))


def main():
    work, courses, schemas = sys.argv[1:4]
    tasks = json.load(open(os.path.join(HERE, "tasks", "tasks.json")))
    rows = []
    for run in sorted(glob.glob(os.path.join(work, "runs", "*", "*", "*"))):
        task, arm, rep = run.split(os.sep)[-3:]
        if not os.path.exists(os.path.join(run, "seconds")):
            continue
        rows.append({"task": task, "arm": arm, "rep": rep, **score(run, tasks[task], courses, schemas)})
    if "--json" in sys.argv:
        json.dump(rows, open(sys.argv[sys.argv.index("--json") + 1], "w"), indent=1)
    cols = [
        "task", "arm", "rep", "finished", "instance", "week", "slot", "pairs", "conflict", "stale", "order",
        "uid", "outside", "invalid", "actual_near", "actual_pairs", "minutes", "input", "output", "commands",
        "searches", "used_script",
    ]  # fmt: skip
    print("\t".join(cols))
    for row in rows:
        print("\t".join(str(row.get(c, "")) for c in cols))


if __name__ == "__main__":
    main()
