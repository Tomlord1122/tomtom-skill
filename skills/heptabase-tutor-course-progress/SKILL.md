---
name: heptabase-tutor-course-progress
description: Review Heptabase AI Tutor goals, courses, and where study stopped. Use when the user asks what courses they prepared, current progress, which lesson is open, or where to continue. Do not use for which cards a course cites, whiteboard layout, or consolidating lesson notes.
tags:
  - heptabase
metadata:
  cometline:
    origin: self-improvement
---

# Review Heptabase AI Tutor course progress

Progress is not on `goal list` or `course list`. It lives in syllabus subtopic status and in lesson plan parts, and those two layers can disagree. A tool result that cuts off mid-dump is not a short course.

## 1. Confirm the CLI, then list the landscape

1. Load the Heptabase CLI skill. Check `heptabase --version` against its range, then run `heptabase system-manual read concepts` and `heptabase space-instructions read` before other reads.
2. Run `heptabase goal --help`, `heptabase course --help`, and `heptabase lesson --help`. Expect `goal list`, `course list`, `course read`, `lesson list`, `lesson read`, and `lesson list-messages`. Do not invent a progress flag.
3. If a command cannot connect, follow the CLI skill: `heptabase start`, then retry. If start says the CLI server is not ready, stop and ask the user to enable CLI in Settings > AI Features.
4. `heptabase goal list` returns root goals with nested `{ id, title }` courses and no subtopic status. `heptabase course list` adds `description`, `goalId`, and `createdTime`. Use both for the map. `goalId` null means the course is itself a root goal.

## 2. Summarize syllabus status from full stdout

1. Do not print `heptabase course read` into the conversation and then count from that text. Large syllabi are cut off mid-JSON, later topics and later courses disappear, and a `STATUS COUNTS` line at the tail belongs only to whatever course was still printing.
2. Call the CLI from a script, `json.loads` the full stdout, and print a compact summary only: per-course counts, in-progress titles, and one line per topic.

```python
import json, subprocess

def walk(subs, acc=None):
    if acc is None:
        acc = []
    for s in subs or []:
        acc.append((s.get("title"), s.get("status") or "none"))
        walk(s.get("subtopics"), acc)
    return acc

courses = json.loads(subprocess.check_output(
    ["heptabase", "course", "list"], text=True))["courses"]
for c in courses:
    data = json.loads(subprocess.check_output(
        ["heptabase", "course", "read", c["id"]], text=True))
    counts, active = {}, []
    print("=" * 72)
    print(data.get("title"))
    for t in data.get("topics") or []:
        topic_counts = {}
        for title, st in walk(t.get("subtopics")):
            counts[st] = counts.get(st, 0) + 1
            topic_counts[st] = topic_counts.get(st, 0) + 1
            if st == "inProgress":
                active.append((t.get("title"), title))
        print(f"  {t.get('title')}: {topic_counts}")
    print("counts", counts)
    for topic, title in active:
        print("inProgress:", topic, ">", title)
```

3. Subtopics nest. A non-recursive walk under-counts. Status values are `notStarted`, `inProgress`, and `covered`. Intro topics can have an empty `sources` array; that is not "no progress".
4. If the compact print is still cut off, the visible head is incomplete for later courses. Re-run one course per call, or drop topic lines and print only counts plus in-progress titles. Do not add `coveredSummary` text unless the user asked what was learned. That text is what blows the cap.
5. Zero `inProgress` is not "not started". A course can be entirely `notStarted` (syllabus prepared, no study) or mostly `notStarted` with a small `covered` set and no open subtopic.

## 3. Cross-check lessons before saying where they stopped

1. For each course, `heptabase lesson list <courseId>`. Lessons are chronological tutor chats: `lessonNumber`, `lessonId`, `title`, `createdTime`, `isEnded`, `hasLessonPlan`.
2. Read every lesson with `isEnded` false, plus the latest ended lesson if you need the handoff. `heptabase lesson read <lessonId>` returns `lessonPlan` (`overview`, `parts`, `nextLessonSummary`) and `aiArtifacts`. Each part has `status` and `isReview`.
3. Treat syllabus status and lesson-plan status as different layers.
   - An `inProgress` subtopic often matches an `inProgress` plan part. Report that as the live stop.
   - Teaching parts can be `covered` while a Review part is `notStarted` and `isEnded` is false. The syllabus may show those subtopics `covered` with no `inProgress`. The lesson is not closed.
   - A lesson can exist with a full plan and every part `notStarted`, matching an all-`notStarted` syllabus. That course is prepared, not started.
4. Use `nextLessonSummary` as the plan's stated next step, and label it that way. It is not evidence the next topic was started.
5. Do not read `lesson list-messages` unless the plan is missing or the user asks what was said. Chat text is not required to place them on the syllabus.

## 4. Report both layers

1. Group courses under their goal. For each course, give topic and subtopic counts, the three status counts, the in-progress subtopic if any, and the open lesson with part statuses.
2. Say which layer each claim comes from: syllabus subtopic versus lesson plan. Do not merge lesson artifacts into "cards this course uses".
3. Name the next unfinished syllabus item and, when present, the plan's next-lesson summary. Ask which course to continue only after both layers are stated.

## Pitfalls

- Truncated tool output is not a short syllabus. Counting from the cut-off text drops later courses and attributes the tail counts to the wrong course. Parse full CLI stdout and print the summary.
- Printing every subtopic title and `coveredSummary` recreates the truncation. Counts, in-progress rows, and topic heads fit; the full tree usually does not.
- `goal list` and `course list` have no progress. Skipping `course read` and `lesson read` reports the catalog, not where study stopped.
- Syllabus `covered` with no `inProgress` can still hide an open lesson whose review is undone. Lesson `notStarted` with a written plan means prepared, not finished and not in progress.
- Repeated `cardId` values on topic sources are citations, not progress events. This review does not answer which courses use a card.