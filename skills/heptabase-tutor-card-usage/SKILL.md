---
name: heptabase-tutor-card-usage
description: Map Heptabase cards to the AI Tutor courses that cite them. Use when the user asks which cards a course uses, which course uses a card, or whether the CLI can reverse-lookup AI Tutor sources. Do not use for section deep links or whiteboard card traces.
tags:
  - heptabase
metadata:
  cometline:
    origin: self-improvement
---

# Map cards used by Heptabase AI Tutor courses

The CLI is course-to-card, not card-to-course. There is no used-in-courses command. Syllabus sources and lesson artifacts are different relations. A connection error is not proof that the lookup is unsupported.

## 1. Confirm the interface, then the server

1. Load the Heptabase CLI skill and check `heptabase --version` against its compatibility range before any read.
2. Run `heptabase course --help`, `heptabase lesson --help`, and `heptabase goal --help`. Expect `course list`, `course read`, `lesson list`, `lesson read`, and `goal list`. Do not invent a reverse-lookup flag.
3. If a command returns "cannot connect to the desktop app", read the CLI skill's sandbox note, then run `heptabase start`.
4. If start says the CLI server is not ready, stop. Only the user can enable CLI in Settings > AI Features. Do not keep relaunching, and do not read local app databases.
5. When the user says the CLI is available, retry the original read. Do not repeat `start` first.

## 2. Build the map from complete course JSON

1. `heptabase course list` returns `{ courses: [{ id, title, description, goalId, createdTime }] }`. `goal list` only nests course titles; it has no card ids.
2. For each course id, run `heptabase course read <courseId>`. Sources live at `topics[].sources[]` as `{ text, cardId }`. `sources` may be an empty array on intro topics.
3. Do not parse a truncated tool result. Large syllabi are cut off mid-JSON, so later topics disappear and the card set looks smaller than it is. Call the CLI from a script, `json.loads` the full stdout, and print only the deduped map.

```python
import json, subprocess
data = json.loads(subprocess.check_output(
    ["heptabase", "course", "read", course_id], text=True))
cards = {}
for topic in data.get("topics") or []:
    for source in topic.get("sources") or []:
        card_id = source.get("cardId")
        if not card_id:
            continue
        cards.setdefault(card_id, set()).add(topic.get("title"))
```

4. The same `cardId` is often cited many times for different page ranges, and one card can be the only source for every topic in a course. Count unique ids. Keep the topic titles so the answer says where the card is used.
5. To answer "which courses use this card", scan every course and keep the courses whose source set contains that id. Do not search `card list -q` for the UUID.

## 3. Resolve titles, and keep lesson cards separate

1. `heptabase card properties <cardId>` returns `title` and `cardType`. `card list` cannot filter by id and caps a page at 100, so do not page the library to resolve known ids.
2. Syllabus `sources` are the cards the course cites. They are not the notes the tutor later generated.
3. Only if the user also wants generated lesson cards: `heptabase lesson list <courseId>`, then `heptabase lesson read <lessonId>`. `aiArtifacts` lists `lessonParts` and `lessonNotes` card ids. Read those with `note read`. Label them as lesson artifacts, not syllabus sources.
4. Report the direction of the scan: course to card, syllabus only, unless lesson artifacts were included.

## Pitfalls

- Truncated course-read output is not a short syllabus. The tool cuts large JSON, so extracting from that text drops sources. Parse the CLI's full stdout.
- Repeated `cardId` values are page-range citations, not extra cards. Counting mentions inflates "cards used".
- A connect or "CLI server is not ready" error means the desktop server is down or CLI is disabled. The missing reverse index is a separate fact, visible only in `--help` after the server answers.
- `goal list` and course descriptions do not contain source cards. Skipping `course read` misses the only card ids the syllabus exposes.
- Lesson artifact ids are generated notes. Mixing them into the syllabus map answers a different question than "which cards does this course use".