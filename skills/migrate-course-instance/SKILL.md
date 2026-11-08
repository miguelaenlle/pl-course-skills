---
name: migrate-course-instance
description: >-
  Set up a PrairieLearn course instance for a new term from an existing one:
  copy it, move every assessment date onto the new term's academic calendar,
  clear what belonged to the old term's students, and verify the result. Use for
  requests such as "Set up Spring 2027 from Fall 2026", "Copy last semester's
  course for the summer", or "Shift all our deadlines to next term's calendar".
---

# Migrate a course instance to a new term

When you're done, the instructor should have a new course instance that:

- opens and closes on the new term's dates
- schedules every assessment in the same week of instruction, on the same
  weekday and time of day, as the old one, unless the instructor asked otherwise
- has no deadline on a holiday or during a break that nobody approved
- carries nothing tied to the old term's students: UID rules, per-student
  overrides, or old PrairieTest exams
- syncs without errors

Moving dates is mechanical, and the script does it. Your job is to get the
calendars right and to surface every decision the instructor needs to make,
then present them all in one review.

## Boundaries

- **Never edit the source course instance.** Work on the copy, in the course
  checkout you were given. Don't push, publish, or sync to production without
  the instructor's go-ahead.
- **Don't copy student information forward.** Drop UID lists and per-student
  overrides, and report only how many there were. Never print the UIDs.
- **Don't invent what you can't know.** You can't create PrairieTest exams, and
  you can't know this term's accommodations. List these for the instructor.
- **Questions are shared by every course instance.** A migration changes course
  instance and assessment files only. Leave questions alone.
- **Ask once, together.** Gather every decision into the plan review in step 5,
  with a sensible default for each. Ask earlier only if you can't find the
  source instance or the target term.

Use PrairieLearn's terms, and link the docs when explaining:
[course instances](https://docs.prairielearn.com/courseInstance/),
[access control](https://docs.prairielearn.com/assessment/accessControl/) (and
its [legacy `allowAccess`
format](https://docs.prairielearn.com/assessment/accessControlLegacy/)), and
[UUIDs](https://docs.prairielearn.com/uuid/).

## 1. Scope

Work out the following from the request and the repository, and ask only for
what you can't find:

- **Source course instance.** Default to the most recent offering. If the course
  has a same-season offering (last fall for this fall) whose schedule differs,
  such as a summer session, mention it as an alternative.
- **Target term.** Pick a name and directory that follow the course's own
  convention (`Fall2026`, `Fa26`).
- **Institution and timezone.** Check `infoCourse.json` and
  `infoCourseInstance.json` for the timezone; the institution usually follows
  from the course or the instructor's email domain. All dates in these files are
  local times in the course instance's timezone. If the timezone changes, ask.

## 2. Calendars

You need a calendar for the source term and one for the target term. Write each
as a small JSON file (format below, examples in
[references/calendars/](references/calendars/)).

1. **Look up the official academic calendar** on the registrar's site for both
   terms. Record the first and last day of instruction, holidays with no
   classes, breaks, and finals, plus the source URL. Note that published future
   calendars are often marked tentative.
2. **If you can't find the official calendar,** ask for the first day of
   instruction and any breaks, but don't wait on the answer. Infer what you can
   from the course's own history: the same term last year usually starts in the
   same week and has the same breaks. Say which dates are inferred.
3. **With only a start date,** the script falls back to a whole-week shift that
   keeps weekdays, and says that breaks weren't accounted for.

```json
{
  "term": "Fall 2026",
  "source": "https://registrar.example.edu/fall-2026-academic-calendar/",
  "instructionBegins": "2026-08-24",
  "instructionEnds": "2026-12-09",
  "holidays": [{ "name": "Labor Day", "date": "2026-09-07" }],
  "breaks": [{ "name": "Fall break", "start": "2026-11-21", "end": "2026-11-29" }],
  "finals": { "start": "2026-12-11", "end": "2026-12-17" }
}
```

Only `instructionBegins` is required. If the two terms differ in length by more
than a week (semester to summer, semester to quarter), the week-by-week mapping
no longer fits. Say so, propose a compressed schedule, and make it a decision in
the review.

## 3. Make the copy

Make the copy first. Leave its dates unchanged at this point; you'll plan and
rewrite them on the copy itself.

- If the instructor used PrairieLearn's **Make a copy of this course instance**
  (Settings tab), work on that copy. It already has:
  - a new UUID
  - publishing dates and enrollment settings
  - per-student rules removed
  - possibly access control migrated to the modern format

  It does not move assessment dates; that's this skill's job.
- Otherwise copy the directory yourself, including `clientFilesCourseInstance`,
  and in `infoCourseInstance.json`:
  - generate a new `uuid` and set `longName`
  - replace legacy `allowAccess` with `publishing`, using the start and end of
    the old rule (they get mapped with everything else), unless the course uses
    LTI 1.1
  - remove `shareSourcePublicly`

  Assessment UUIDs can stay the same; they only need to be unique within a
  course instance.

Keep the access-control format the copy has. If it uses legacy `allowAccess`,
mention that each assessment's **Access** tab can migrate it to the modern
format.

## 4. Inventory and plan

Run [references/shift_dates.py](references/shift_dates.py) on the copy. It needs
only the Python standard library.

```sh
python3 shift_dates.py scan COPY_DIR --calendar source.json
python3 shift_dates.py plan COPY_DIR --from source.json --to target.json --csv plan.csv
```

- `scan` lists every date, plus anything else that belongs to one term:
  - dates already outside the source term (leftovers from earlier copies)
  - dates on holidays or in breaks
  - UID rules and per-student overrides
  - PrairieTest exam UUIDs and passwords
  - text and client files that mention dates
- `plan` places each date in the same week of instruction, on the same weekday
  and at the same time, skipping breaks. Dates before instruction, in finals, or
  after the term keep their offset from that boundary. A deadline that spans
  spring break in the source term spans one fewer week in a fall term that has
  no break at that point. That is intended. The script flags what it can't place
  cleanly and leaves dates from outside the source term unchanged.

Read the flagged rows yourself, and spot-check a few assessments of each kind
against the course's pattern, for example "homework opens Tuesday at 08:00 and
is due the next Tuesday at 23:59".

## 5. Review with the instructor, then apply

Give one compact review. Don't paste the CSV. Include:

1. **Calendars used,** with their sources and anything inferred.
2. **The schedule by assessment set.** List each set's pattern and the weeks it
   covers, then a table with one row per assessment: old and new release, old
   and new due date. Use PrairieLearn's assessment names.
3. **Decisions,** each with your default. Include only the ones that apply:
   - **Conflicts.** Default: move a deadline that lands on a holiday or in a
     break to the next day of instruction. Releases there are usually fine.
   - **Dates already outside the source term,** such as practice assessments
     still set to 2024. Ask whether that was on purpose. Default: tie each one to
     the assessment it belongs with (a practice quiz opens with its quiz).
   - **PrairieTest exams.** These need new exams in PrairieTest for the new term.
     Default: keep the assessments, and list the exam UUIDs to replace once the
     instructor creates the exams.
   - **UID rules and per-student overrides.** Default: drop them. If a group
     recurs every term (extra time, a section), suggest a [student
     label](https://docs.prairielearn.com/courseInstance/#student-labels)
     override instead.
   - **Policy changes.** Ask "Anything different this term?" Common changes
     include deadline weekday, late-credit windows, and dropped or added
     assessments. Apply them as rules ("every homework due Friday 23:59"), not
     one row at a time.

Then apply, in this order:

1. Record each date decision in the `new` column of `plan.csv`, then rewrite the
   dates. `apply` changes only date strings, so the diff stays small. It refuses
   to run if the file changed since the plan was made; if that happens, re-run
   `plan`.
   ```sh
   python3 shift_dates.py apply COPY_DIR --plan plan.csv
   ```
2. Carry out the other decisions:
   - remove UID rules and per-student overrides
   - replace exam UUIDs the instructor gave you
   - set `selfEnrollment.beforeDate` if the old instance had one (the add
     deadline is a good default)
   - update dates written in assessment `text` and client files

## 6. Verify

- Run `scan COPY_DIR --calendar target.json`. It should report:
  - no dates outside the target term, except ones the instructor kept on purpose
  - no conflicts other than the ones the instructor approved
  - no UID rules or per-student overrides
- Sync the course (on local PrairieLearn, **Load from disk**) and confirm the new
  instance has no sync errors or warnings.
- Open the new instance's **Assessments** page and the **Access** tab for two or
  three assessments, and check that the dates read as expected.
- Diff the copy against the source. The only differences should be dates, the
  course instance header, and the decisions you applied.

## Handoff

Keep it short:

- **Result:** the new course instance, its dates, and how many assessment dates
  moved
- **Calendars:** the sources, and anything inferred
- **Decisions applied:** each with its outcome
- **Still to do in PrairieLearn:**
  - PrairieTest exams to create, with the UUIDs to replace
  - students to add to labels
  - staff permissions
  - enrollment code or link
  - LMS links
- **Not verified:** anything you couldn't check, such as a sync or PrairieTest
  linkage
