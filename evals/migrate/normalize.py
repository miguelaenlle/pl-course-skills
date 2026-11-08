import json, os, glob, datetime as dt, sys
def D(s): return dt.datetime.fromisoformat(s[:19].replace(" ", "T")) if s else None
def norm(d):
    """Return dict(kind, release, due, late=[(date,credit)], early=[...], end, exams=n, overrides=n)."""
    r = {'kind': None, 'release': None, 'due': None, 'late': [], 'early': [], 'end': None, 'exams': 0, 'overrides': 0}
    if 'accessControl' in d and d['accessControl']:
        r['kind'] = 'ac'; base = d['accessControl'][0]; dc = base.get('dateControl') or {}
        r['release'] = D((dc.get('release') or {}).get('date')); r['due'] = D((dc.get('due') or {}).get('date'))
        r['late'] = [(D(x['date']), x['credit']) for x in dc.get('lateDeadlines') or []]
        r['early'] = [(D(x['date']), x['credit']) for x in dc.get('earlyDeadlines') or []]
        r['exams'] = len(((base.get('integrations') or {}).get('prairieTest') or {}).get('exams') or [])
        r['overrides'] = len(d['accessControl']) - 1
    elif d.get('allowAccess'):
        r['kind'] = 'aa'; rules = d['allowAccess']
        pub = [x for x in rules if not x.get('uids') and not x.get('examUuid') and x.get('mode') != 'Exam' and x.get('startDate')]
        r['exams'] = sum(1 for x in rules if x.get('examUuid'))
        r['overrides'] = sum(1 for x in rules if x.get('uids'))
        if pub:
            r['release'] = min(D(x['startDate']) for x in pub)
            tiers = sorted([(D(x['endDate']), x.get('credit', 0)) for x in pub if x.get('endDate')])
            full = [t for t in tiers if t[1] == 100]
            if full: r['due'] = full[0][0]
            r['early'] = [t for t in tiers if t[1] > 100]
            r['late'] = [t for t in tiers if 0 < t[1] < 100]
            zero = [t for t in tiers if t[1] == 0]
            if zero: r['end'] = zero[-1][0]
    return r
def load(ci):
    out = {}
    for f in glob.glob(f'{ci}/assessments/**/infoAssessment.json', recursive=True):
        tid = os.path.relpath(os.path.dirname(f), f'{ci}/assessments'); out[tid] = norm(json.load(open(f)))
    return out
if __name__ == '__main__':
    A, B = load(sys.argv[1]), load(sys.argv[2])
    W = 'MTWRFSU'
    f = lambda x: f"{x:%m-%d}{W[x.weekday()]} {x:%H:%M}" if x else '-'
    print(f"{'tid':22} {'old rel':>14} {'new rel':>14} {'old due':>14} {'new due':>14} dDays relD dueD  ex ov")
    for t in sorted(set(A) | set(B)):
        a, b = A.get(t), B.get(t)
        if not a or not b: print(t, 'only in', 'A' if a else 'B'); continue
        rd = (b['release'] - a['release']).days if a['release'] and b['release'] else ''
        dd = (b['due'] - a['due']).days if a['due'] and b['due'] else ''
        la = (a['due'] - a['release']).days if a['due'] and a['release'] else ''
        lb = (b['due'] - b['release']).days if b['due'] and b['release'] else ''
        print(f"{t:22} {f(a['release']):>14} {f(b['release']):>14} {f(a['due']):>14} {f(b['due']):>14} {rd!s:>4} {la!s:>3}->{lb!s:<3} {a['exams']}/{b['exams']} {a['overrides']}/{b['overrides']}")
