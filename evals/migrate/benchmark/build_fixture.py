"""Build a benchmark fixture: a course checkout without the target course instance.

Usage: build_fixture.py COURSE_REPO OUT_DIR --remove CI [--remove CI ...]

Exports HEAD without `questions/` or git history, removes the held-out course
instances, replaces every UID in access rules and every other personal address
with a made-up one (so no student identifiers leave this machine), and commits the result as a new repository.
"""

import argparse
import glob
import io
import json
import os
import re
import shutil
import subprocess
import tarfile

p = argparse.ArgumentParser()
p.add_argument("repo")
p.add_argument("out")
p.add_argument("--remove", action="append", default=[])
p.add_argument("--drop", action="append", default=[], help="other paths to delete")
args = p.parse_args()

shutil.rmtree(args.out, ignore_errors=True)
os.makedirs(args.out)
tar = subprocess.run(
    ["git", "-C", args.repo, "archive", "HEAD", "--", ".", ":(exclude)questions"],
    check=True,
    capture_output=True,
).stdout
tarfile.open(fileobj=io.BytesIO(tar)).extractall(args.out, filter="data")
for ci in args.remove:
    shutil.rmtree(os.path.join(args.out, "courseInstances", ci))
for path in args.drop:
    full = os.path.join(args.out, path)
    shutil.rmtree(full) if os.path.isdir(full) else os.remove(full)

files = glob.glob(os.path.join(args.out, "courseInstances", "**", "info*.json"), recursive=True)
uids: dict[str, str] = {}


def collect(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == "uids" and isinstance(v, list):
                for u in v:
                    if isinstance(u, str):
                        uids.setdefault(u, f"student{len(uids) + 1:04d}@example.edu")
            else:
                collect(v)
    elif isinstance(o, list):
        for v in o:
            collect(v)


texts = {}
for f in files:
    with open(f, newline="") as fh:
        texts[f] = fh.read()
    try:
        collect(json.loads(texts[f]))
    except json.JSONDecodeError:
        pass
if uids:
    pattern = re.compile("|".join(re.escape(json.dumps(u)) for u in sorted(uids, key=len, reverse=True)))
    for f, text in texts.items():
        new = pattern.sub(lambda m: json.dumps(uids[json.loads(m.group(0))]), text)
        if new != text:
            with open(f, "w", newline="") as fh:
                fh.write(new)

# Addresses outside access rules (staff lists, old data files, notebooks).
PERSONAL = re.compile(
    rb"[A-Za-z0-9._+-]+@(?:illinois\.edu|illinos\.edu|uiuc\.edu|gmail\.com|(?:intl\.)?zju\.edu\.cn)"
)
others: dict[bytes, bytes] = {}
for root, dirs, names in os.walk(args.out):
    for name in names:
        path = os.path.join(root, name)
        if os.path.islink(path) or os.path.getsize(path) > 20_000_000:
            continue
        with open(path, "rb") as fh:
            raw = fh.read()
        new = PERSONAL.sub(
            lambda m: others.setdefault(m.group(0), b"person%04d@example.edu" % (len(others) + 1)), raw
        )
        if new != raw:
            with open(path, "wb") as fh:
                fh.write(new)

git = ["git", "-C", args.out, "-c", "user.name=fixture", "-c", "user.email=fixture@example.edu"]
subprocess.run(["git", "-C", args.out, "init", "-q", "-b", "master"], check=True)
subprocess.run([*git, "add", "-A"], check=True)
subprocess.run([*git, "commit", "-q", "-m", "Course at the start of the task"], check=True)
print(f"{args.out}: removed {args.remove}, replaced {len(uids)} UIDs and {len(others)} other addresses")
