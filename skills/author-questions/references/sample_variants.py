"""Generate many variants of a question and summarize what students would see.

Runs the question's server.py generate() (and prepare(), if present) for many
seeds, the way PrairieLearn does, and summarizes every value in params and
correct_answers: ranges, distinct values, zeros, and non-finite numbers. Use it
to catch variants that are degenerate (answer 0, division by zero), lopsided
(one case far more common), or out of the intended range.

Usage:
    python3 sample_variants.py QUESTION_DIR [--course COURSE_DIR] [-n 500]
        [--pl-python PRAIRIELEARN_REPO/apps/prairielearn/python] [--show KEY ...]

QUESTION_DIR contains server.py. COURSE_DIR defaults to the directory that
contains questions/. --pl-python adds PrairieLearn's Python helpers (the
`prairielearn` package) to the import path, which many server.py files need.
Run the script with PrairieLearn's Python environment so their dependencies
import, for example `PRAIRIELEARN_REPO/.venv/bin/python sample_variants.py ...`.
"""

import argparse
import collections
import importlib.util
import json
import math
import os
import random
import sys
import traceback

try:
    import numpy as np
except ImportError:  # numpy is optional for questions that don't use it
    np = None


def find_course_dir(question_dir: str) -> str:
    path = os.path.abspath(question_dir)
    while path != os.path.dirname(path):
        if os.path.basename(path) == "questions":
            return os.path.dirname(path)
        path = os.path.dirname(path)
    raise SystemExit("Couldn't find the course directory; pass --course.")


def load_server(question_dir: str):
    spec = importlib.util.spec_from_file_location(
        "question_server", os.path.join(question_dir, "server.py")
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def flatten(prefix: str, value, out: dict) -> None:
    """Flatten nested dicts; summarize lists and arrays by their contents."""
    if isinstance(value, dict) and value.get("_type") == "ndarray":
        value = value.get("_value")
    if isinstance(value, dict):
        for key, inner in value.items():
            flatten(f"{prefix}.{key}" if prefix else str(key), inner, out)
    else:
        out[prefix] = value


def to_jsonable(value):
    if np is not None and isinstance(value, np.ndarray):
        return value.tolist()
    if np is not None and isinstance(value, np.generic):
        return value.item()
    return value


def summarize(name: str, values: list, show: bool) -> str:
    values = [to_jsonable(v) for v in values]
    numbers = []
    for v in values:
        if isinstance(v, bool):
            continue
        if isinstance(v, (int, float)):
            numbers.append(float(v))
        elif isinstance(v, list):
            flat = []
            stack = list(v)
            while stack:
                item = stack.pop()
                if isinstance(item, list):
                    stack.extend(item)
                elif isinstance(item, (int, float)) and not isinstance(item, bool):
                    flat.append(float(item))
            numbers.extend(flat)
    keys = [json.dumps(v, sort_keys=True, default=str) for v in values]
    counts = collections.Counter(keys)
    parts = [f"{name}: {len(counts)} distinct"]
    if numbers:
        finite = [x for x in numbers if math.isfinite(x)]
        nonfinite = len(numbers) - len(finite)
        if finite:
            parts.append(f"range {min(finite):.6g} to {max(finite):.6g}")
        scale = max((abs(x) for x in finite), default=0.0)
        tolerance = max(1e-12, 1e-9 * scale)
        zeros = sum(1 for x in finite if abs(x) <= tolerance)
        if zeros:
            parts.append(f"{zeros} zero values ({100 * zeros / len(numbers):.0f}%)")
        if nonfinite:
            parts.append(f"{nonfinite} NaN/inf")
    line = "; ".join(parts)
    if show or len(counts) <= 6:
        common = ", ".join(
            f"{k[:40]} ({100 * c / len(values):.0f}%)" for k, c in counts.most_common(6)
        )
        line += f"\n    most common: {common}"
    return line


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("question_dir")
    parser.add_argument("--course")
    parser.add_argument("-n", type=int, default=500)
    parser.add_argument("--pl-python")
    parser.add_argument("--show", nargs="*", default=[])
    args = parser.parse_args()

    question_dir = os.path.abspath(args.question_dir)
    course_dir = os.path.abspath(args.course or find_course_dir(question_dir))
    for path in [args.pl_python, os.path.join(course_dir, "serverFilesCourse"), question_dir]:
        if path:
            sys.path.insert(0, os.path.abspath(path))
    os.chdir(question_dir)
    server = load_server(question_dir)
    if not hasattr(server, "generate"):
        raise SystemExit("server.py has no generate(); nothing to sample.")

    options = {
        "question_path": question_dir,
        "client_files_question_path": os.path.join(question_dir, "clientFilesQuestion"),
        "client_files_course_path": os.path.join(course_dir, "clientFilesCourse"),
        "server_files_course_path": os.path.join(course_dir, "serverFilesCourse"),
        "course_extensions_path": os.path.join(course_dir, "elementExtensions"),
    }
    collected = collections.defaultdict(list)
    errors = []
    for seed in range(args.n):
        random.seed(seed)
        if np is not None:
            np.random.seed(seed)
        data = {
            "params": {},
            "correct_answers": {},
            "variant_seed": seed,
            "options": dict(options),
            "preferences": {},
        }
        try:
            server.generate(data)
            if hasattr(server, "prepare"):
                server.prepare(data)
        except Exception:
            errors.append((seed, traceback.format_exc()))
            continue
        flat = {}
        flatten("params", data["params"], flat)
        flatten("correct_answers", data["correct_answers"], flat)
        for key, value in flat.items():
            collected[key].append(value)

    print(f"{args.n} seeds, {len(errors)} raised errors")
    if errors:
        seed, trace = errors[0]
        print(f"first error (seed {seed}):\n{trace}")
    for key in sorted(collected):
        print(summarize(key, collected[key], key in args.show))


if __name__ == "__main__":
    main()
