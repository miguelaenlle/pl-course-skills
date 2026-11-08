#!/usr/bin/env python3
"""Inventory and calendar-shift the dates in a PrairieLearn course instance.

    shift_dates.py scan  COURSE_INSTANCE_DIR [--calendar TERM.json]
    shift_dates.py plan  COURSE_INSTANCE_DIR --from FROM.json --to TO.json [--csv PLAN.csv]
    shift_dates.py apply COURSE_INSTANCE_DIR --plan PLAN.csv

`scan` lists every date and every other item that belongs to one term (UIDs,
PrairieTest exams, student-specific overrides, dates mentioned in text).
`plan` maps each date to the target term and writes a reviewable CSV.
`apply` rewrites the JSON files from the (possibly hand-edited) `new` column,
changing only the date strings so the diff stays small.

A calendar is a JSON file:

    {"term": "Fall 2026", "instructionBegins": "2026-08-24", "instructionEnds": "2026-12-09",
     "breaks": [{"name": "Fall break", "start": "2026-11-21", "end": "2026-11-29"}],
     "holidays": [{"name": "Labor Day", "date": "2026-09-07"}],
     "finals": {"start": "2026-12-11", "end": "2026-12-17"}}

Only `instructionBegins` is required. Without `instructionEnds`, `breaks` and
`finals`, the mapping is a whole-week shift that keeps weekdays.

Mapping rule: a date in the source term is located by instructional week
(weeks counted from the week instruction begins, skipping weeks that are
entirely break) and weekday, and placed at the same instructional week and
weekday in the target term. Time of day is kept. Dates before week 1, in the
reading days, in finals, or after finals keep their day offset from that
anchor. Anything that lands on a holiday, in a break, outside instruction, or
that started outside the source term is flagged rather than silently moved.
"""

import argparse
import csv
import datetime as dt
import json
import os
import re
import sys

DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}")
QUOTED_DATE_RE = re.compile(r'"(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}[^"]*)"')
WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
STALE_WEEKS = 10
MONTH_RE = re.compile(
    r"\b(Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(t|tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)\.?\s+\d{1,2}\b"
)


def day(s):
    return dt.date.fromisoformat(s[:10])


def monday(d):
    return d - dt.timedelta(days=d.weekday())


class Calendar:
    def __init__(self, path):
        j = json.load(open(path))
        self.term = j.get("term", os.path.basename(path))
        self.begin = day(j["instructionBegins"])
        self.end = day(j["instructionEnds"]) if j.get("instructionEnds") else None
        self.breaks = [(day(b["start"]), day(b["end"]), b.get("name", "break")) for b in j.get("breaks", [])]
        self.holidays = {day(h["date"]): h.get("name", "holiday") for h in j.get("holidays", [])}
        f = j.get("finals")
        self.finals = (day(f["start"]), day(f["end"])) if f else None
        self.w1 = monday(self.begin)
        last = monday(self.end) if self.end else self.w1 + dt.timedelta(weeks=60)
        n = (last - self.w1).days // 7 + 1
        self.break_weeks = {
            k for k in range(n) if all(self.in_break(self.w1 + dt.timedelta(days=7 * k + i)) for i in range(5))
        }
        self.inst_weeks = [k for k in range(n) if k not in self.break_weeks]
        self.break_week_list = sorted(self.break_weeks)

    def in_break(self, d):
        return next((name for s, e, name in self.breaks if s <= d <= e), None)

    def term_end(self):
        return self.finals[1] if self.finals else self.end

    def locate(self, d):
        if d < self.w1:
            return ("pre", (d - self.w1).days)
        if self.end and d > self.end:
            if self.finals and d > self.finals[1]:
                return ("post", (d - self.finals[1]).days)
            if self.finals and d >= self.finals[0]:
                return ("finals", (d - self.finals[0]).days)
            return ("gap", (d - self.end).days)
        k = (d - self.w1).days // 7
        if k in self.break_weeks:
            following = sum(1 for w in self.inst_weeks if w < k)
            return ("break", self.break_week_list.index(k), d.weekday(), following)
        return ("week", self.inst_weeks.index(k), d.weekday())

    def describe(self, loc):
        kind = loc[0]
        if kind == "week":
            return f"week {loc[1] + 1} {WEEKDAYS[loc[2]]}"
        if kind == "break":
            return f"break week {loc[1] + 1} {WEEKDAYS[loc[2]]}"
        if kind == "pre":
            return f"{-loc[1]} days before week 1"
        if kind == "gap":
            return f"{loc[1]} days after instruction ends"
        if kind == "finals":
            return f"finals day {loc[1] + 1}"
        return f"{loc[1]} days after finals" if self.finals else f"{loc[1]} days after term"

    def place(self, loc):
        """Return (date, flags) for a location from another calendar."""
        flags = []
        kind = loc[0]
        if kind == "pre":
            return self.w1 + dt.timedelta(days=loc[1]), flags
        if kind in ("gap", "finals", "post") and not self.end:
            flags.append("target calendar has no end of instruction")
            return None, flags
        if kind == "gap":
            return self.end + dt.timedelta(days=loc[1]), flags
        if kind == "finals":
            if not self.finals:
                flags.append("target calendar has no finals period")
                return self.end + dt.timedelta(days=loc[1] + 2), flags
            d = self.finals[0] + dt.timedelta(days=loc[1])
            if d > self.finals[1]:
                flags.append("past the end of target finals")
            return d, flags
        if kind == "post":
            return self.term_end() + dt.timedelta(days=loc[1]), flags
        if kind == "break":
            if loc[1] < len(self.break_week_list):
                k = self.break_week_list[loc[1]]
                flags.append("source date was during a break")
                return self.w1 + dt.timedelta(days=7 * k + loc[2]), flags
            flags.append("source date was during a break the target term does not have")
            loc = ("week", loc[3], loc[2])
        i, wd = loc[1], loc[2]
        if i < len(self.inst_weeks):
            k = self.inst_weeks[i]
        else:
            k = self.inst_weeks[-1] + (i - len(self.inst_weeks) + 1)
            flags.append("beyond the target term's instructional weeks")
        return self.w1 + dt.timedelta(days=7 * k + wd), flags

    def check(self, d):
        flags = []
        if d in self.holidays:
            flags.append(f"lands on {self.holidays[d]}")
        b = self.in_break(d)
        if b:
            flags.append(f"lands in {b}")
        if self.end and self.end < d and (not self.finals or d < self.finals[0]):
            flags.append("lands between end of instruction and finals")
        return flags

    def stale(self, d):
        lo = self.w1 - dt.timedelta(weeks=STALE_WEEKS)
        hi = (self.term_end() or self.w1 + dt.timedelta(weeks=20)) + dt.timedelta(weeks=STALE_WEEKS)
        return not (lo <= d <= hi)


def walk(o, path=""):
    if isinstance(o, dict):
        for k, v in o.items():
            yield from walk(v, f"{path}.{k}" if path else k)
    elif isinstance(o, list):
        for i, v in enumerate(o):
            yield from walk(v, f"{path}[{i}]")
    else:
        yield path, o


def json_files(ci):
    yield "infoCourseInstance.json", os.path.join(ci, "infoCourseInstance.json")
    root = os.path.join(ci, "assessments")
    for dirpath, _, files in sorted(os.walk(root)):
        if "infoAssessment.json" in files:
            p = os.path.join(dirpath, "infoAssessment.json")
            yield os.path.relpath(p, ci), p


def dates_in(path):
    data = json.load(open(path))
    return [(p, v) for p, v in walk(data) if isinstance(v, str) and DATE_RE.match(v)], data


def term_items(rel, data):
    """Things other than dates that belong to one term."""
    items = []
    for i, rule in enumerate(data.get("allowAccess") or []):
        if rule.get("uids"):
            items.append((rel, f"allowAccess[{i}]", f"legacy rule for {len(rule['uids'])} specific UIDs"))
        if rule.get("examUuid"):
            items.append((rel, f"allowAccess[{i}].examUuid", "PrairieTest exam UUID"))
        if rule.get("password"):
            items.append((rel, f"allowAccess[{i}].password", "assessment password"))
        if rule.get("institution") == "LTI":
            items.append((rel, f"allowAccess[{i}]", "LTI 1.1 access rule"))
    ac = data.get("accessControl") or []
    for i, rule in enumerate(ac):
        exams = ((rule.get("integrations") or {}).get("prairieTest") or {}).get("exams") or []
        for j, _ in enumerate(exams):
            items.append((rel, f"accessControl[{i}].integrations.prairieTest.exams[{j}].examUuid", "PrairieTest exam UUID"))
        if (rule.get("dateControl") or {}).get("password"):
            items.append((rel, f"accessControl[{i}].dateControl.password", "assessment password"))
        if i > 0 and "labels" not in rule:
            items.append((rel, f"accessControl[{i}]", "student-specific override (students are stored in PrairieLearn, not here)"))
        elif i > 0:
            items.append((rel, f"accessControl[{i}]", f"override for student labels {rule['labels']}"))
    text = data.get("text") or ""
    if MONTH_RE.search(text) or re.search(r"\b20\d\d\b", text):
        items.append((rel, "text", "assessment text mentions a date or year"))
    return items


def text_mentions(ci, years):
    """Files under clientFiles* whose names or contents mention a year or term."""
    hits = []
    pat = re.compile(r"\b(" + "|".join(sorted(years)) + r")\b") if years else None
    for dirpath, _, files in os.walk(ci):
        if "clientFiles" not in dirpath:
            continue
        for f in files:
            p = os.path.join(dirpath, f)
            rel = os.path.relpath(p, ci)
            if pat and pat.search(f):
                hits.append((rel, "file name", "mentions the term's year"))
                continue
            if f.lower().endswith((".html", ".md", ".txt", ".json")):
                try:
                    s = open(p, encoding="utf-8", errors="ignore").read()
                except OSError:
                    continue
                if (pat and pat.search(s)) or MONTH_RE.search(s):
                    hits.append((rel, "contents", "mentions a date or the term's year"))
    return hits


def short(rel):
    if rel.startswith("assessments/"):
        return os.path.dirname(rel)[len("assessments/") :] or rel
    return rel


def group_dates(rows):
    out = {}
    for rel, _, v in rows:
        out.setdefault(short(rel), []).append(v[:10])
    return {k: sorted(set(v)) for k, v in out.items()}


def cmd_scan(args):
    cal = Calendar(args.from_) if args.from_ else None
    n_dates, years, items, stale, conflicts = 0, set(), [], [], []
    for rel, path in json_files(args.ci):
        dates, data = dates_in(path)
        n_dates += len(dates)
        for p, v in dates:
            years.add(v[:4])
            if cal and cal.stale(day(v)):
                stale.append((rel, p, v))
            elif cal:
                for flag in cal.check(day(v)):
                    conflicts.append((rel, p, v, flag))
        items += term_items(rel, data)
        if rel == "infoCourseInstance.json":
            items.append((rel, "uuid", "course instance UUID (a copy in the same course needs a new one)"))
            items.append((rel, "longName", f"name: {data.get('longName')!r}"))
            if data.get("allowAccess"):
                items.append((rel, "allowAccess", "legacy course instance access (PrairieLearn's copy switches to publishing)"))
    items += text_mentions(args.ci, years)
    print(f"{n_dates} dates in {args.ci} (years: {', '.join(sorted(years))})")
    if cal:
        print(f"\n{len(stale)} dates outside {cal.term} (more than {STALE_WEEKS} weeks before or after it):")
        for rel, ds in group_dates(stale).items():
            print(f"  {rel}: {', '.join(ds)}")
        print(f"\n{len(conflicts)} dates on a holiday, in a break, or between instruction and finals:")
        for rel, p, v, flag in conflicts:
            print(f"  {short(rel)} {p} {v} ({flag})")
    groups = {}
    for rel, path, what in items:
        key = re.sub(r"\d+ specific UIDs", "specific UIDs", what)
        groups.setdefault(key, []).append((rel, path, what))
    print(f"\n{len(items)} other term-specific items:")
    for key, rows in groups.items():
        where = sorted({short(r[0]) for r in rows})
        shown = ", ".join(where[:12]) + (f", ... ({len(where) - 12} more)" if len(where) > 12 else "")
        print(f"  {key} ({len(rows)}): {shown}")


def cmd_plan(args):
    src, dst = Calendar(args.from_), Calendar(args.to)
    rows = []
    for rel, path in json_files(args.ci):
        dates, _ = dates_in(path)
        for p, v in dates:
            d = day(v)
            flags = []
            if src.stale(d):
                rows.append([rel, p, v, v, "outside source term; left unchanged", "outside source term"])
                continue
            loc = src.locate(d)
            nd, f = dst.place(loc)
            flags += f
            if nd is None:
                rows.append([rel, p, v, v, src.describe(loc), "; ".join(flags)])
                continue
            flags += dst.check(nd)
            if loc[0] in ("pre", "gap", "finals", "post") and nd.weekday() != d.weekday():
                flags.append(f"weekday changes {WEEKDAYS[d.weekday()]}->{WEEKDAYS[nd.weekday()]}")
            rows.append([rel, p, v, nd.isoformat() + v[10:], src.describe(loc), "; ".join(flags)])
    out = open(args.csv, "w", newline="") if args.csv else sys.stdout
    w = csv.writer(out)
    w.writerow(["file", "path", "old", "new", "position in source term", "flags"])
    w.writerows(rows)
    if args.csv:
        out.close()
        flagged = [r for r in rows if r[5]]
        print(f"{len(rows)} dates mapped {src.term} -> {dst.term}; {len(flagged)} flagged. Plan: {args.csv}")
        for r in flagged:
            print("  ", r[0], r[1], r[2], "->", r[3], "|", r[5])


def cmd_apply(args):
    plan = {}
    for r in csv.DictReader(open(args.plan)):
        plan.setdefault(r["file"], {})[r["path"]] = (r["old"], r["new"])
    changed = 0
    for rel, edits in plan.items():
        path = os.path.join(args.ci, rel)
        text = open(path).read()
        dates, _ = dates_in(path)
        occurrences = list(QUOTED_DATE_RE.finditer(text))
        if [m.group(1) for m in occurrences] != [v for _, v in dates]:
            sys.exit(f"{rel}: date strings in the file don't line up with the parsed JSON; edit it by hand")
        out, last = [], 0
        for (p, v), m in zip(dates, occurrences):
            old, new = edits.get(p, (v, v))
            if old != v:
                sys.exit(f"{rel} {p}: plan says {old} but file has {v}; re-run plan")
            out.append(text[last : m.start(1)])
            out.append(new)
            last = m.end(1)
            changed += new != v
        out.append(text[last:])
        open(path, "w").write("".join(out))
    print(f"Rewrote {changed} dates in {len(plan)} files")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("scan")
    s.add_argument("ci")
    s.add_argument("--calendar", "--from", dest="from_", help="calendar of the term this instance is for")
    p = sub.add_parser("plan")
    p.add_argument("ci")
    p.add_argument("--from", dest="from_", required=True)
    p.add_argument("--to", required=True)
    p.add_argument("--csv")
    a = sub.add_parser("apply")
    a.add_argument("ci")
    a.add_argument("--plan", required=True)
    args = ap.parse_args()
    {"scan": cmd_scan, "plan": cmd_plan, "apply": cmd_apply}[args.cmd](args)


if __name__ == "__main__":
    main()
