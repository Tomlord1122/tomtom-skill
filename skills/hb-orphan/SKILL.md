---
name: hb-orphan
description: Tag Heptabase notes that look like leftover AI Tutor cards from deleted courses. Use when the user asks to find AI residue, retag orphan tutor cards, mark unplaced notes that no longer belong to a living course, or invokes /hb-orphan. Do not use for a plain unplaced-card list (heptabase-cards-not-on-whiteboard), organizing a whiteboard, or trashing cards the user has not reviewed.
tags:
  - heptabase
  - cleanup
metadata:
  cometline:
    origin: self-improvement
---

# Tag leftover AI Tutor cards

Deleted courses leave generated notes in the library. Living courses must stay protected. Build a whitelist of artifact card ids from courses that still exist, subtract notes already on a whiteboard, drop handwriting, and tag only the AI-like remainder `orphan`. Always reuse that exact name. Do not invent a dated, numbered, descriptive, or course-specific tag. Do not trash.

`heptabase-cards-not-on-whiteboard` only lists unplaced cards and holds artifacts from courses still in progress. This skill is the next job: mark AI-looking orphans from courses that are already gone. Do not extend that neighbor.

## 1. Confirm the CLI, then dump full JSON

1. Load the Heptabase CLI skill and run `heptabase --version` and `heptabase help` before any read.
2. Expect `course list`, `course read`, `lesson list`, `lesson read`, `whiteboard list`, `whiteboard cards`, `card list`, `object read`, `tag list`, `tag add`, and `tag remove`. Confirm each with `--help`. Do not invent a whiteboard filter on `card list`, and do not read the app database.
3. Version gate is the loaded CLI skill, not a minor pinned in this file. Read `metadata.heptabase-cli-version-range` from that skill. If `heptabase --version` is outside that range, stop and ask the user to update the app or the CLI skill. If it is inside that range, continue. Do not stop only because an older copy of this skill named an older minor. If a required command or flag is missing from `--help`, stop. Do not invent flags. In particular, re-read `tag remove --help`: remove takes `--tag-id`, not `--tag-name`.
4. If a command returns "cannot connect to the desktop app", follow the CLI skill's sandbox note and run `heptabase start`. If start says the CLI server is not ready, stop. Only the user can enable CLI in Settings > AI Features.
5. Write every CLI stdout to a file and `json.loads` that file. A truncated tool result drops artifact ids, and a dropped id lets a living course card into the delete tag. `tag list` is the exception: its stdout is JSON with a `content` string, not a `tags` array. Read that string. Do not expect `tags[].name` or `tags[].id`.

## 2. Build the living-course whitelist

1. `heptabase course list`. For each `courses[].id`, run `heptabase course read <courseId>` and `heptabase lesson list <courseId>`.
2. For each `lessons[].lessonId`, run `heptabase lesson read <lessonId>`.
3. Collect card ids only from `cardId` fields, from both files:
   - `course read`: `topics[].sources[].cardId` and any other `cardId` under `topics`
   - `lesson read`: `aiArtifacts.lessonParts[].cardId`, `aiArtifacts.lessonNotes[].cardId`, and any `cardId` under that lesson's `topics`
4. A course with zero lessons is not an empty whitelist. `course read` topics and sources can still name living cards. Collect those, say the lesson count is zero, and do not invent lesson artifacts.
5. Do not treat a bare `id` as a card. `lessonId`, topic ids, and subtopic ids are also UUIDs. Putting them in the whitelist does not protect cards; it only inflates the set.
6. `aiArtifacts` is a dict of `lessonParts` and `lessonNotes`, not a flat id list.
7. Keep course and lesson titles for the report. Do not require a title match to protect a card. The id whitelist is the protection.

## 3. Unplaced notes, then the difference

1. Page `heptabase whiteboard list --limit 100 --offset N` until `offset` reaches `total`. For every whiteboard, including children, run `heptabase whiteboard cards <whiteboardId>` and keep `cards[].cardId`. Ignore rows with no `cardId`. `whiteboardObjectId` is not the library card id.
2. Page `heptabase card list --card-types note --limit 100 --offset N` until `offset` reaches `total`. Keep `id`, `title`, `createdTime`. Journals are not in this type list. Drop any row whose id is already placed.
3. Candidates are unplaced notes whose id is not in the whitelist. Unplaced notes that are in the whitelist are living tutor output. Report their count and titles, and do not tag them.
4. Script the scan. A library can be hundreds of notes and dozens of boards. Do not parse a truncated tool view as a short list.
5. Placed ids will usually outnumber notes. Boards hold PDFs and other card types. That is not a short page. Completeness is `offset >= total` on both lists, not `placed <= notes`.

## 4. Score candidates before tagging

Read visible text with the command `--help` names, not the command an older copy of this skill remembered.

1. Run `heptabase object read --help` and `heptabase note --help`.
2. On CLI `>=0.10.0`, `heptabase object read card <cardId>` returns line-numbered Hepta Markdown. Score that string. It is already visible text. `_agentLine` and tutor phrases appear in that markdown.
3. Use `heptabase note read <cardId>` only when `--help` still says it is the content read. On that older path, `content` is a JSON string. `json.loads` it, then walk `text` nodes. Walking the string finds nothing, so every note looks blank and the AI score collapses to zero.
4. Do not feed `note read` JSON into the prose checks below just because this file once said to. A JSON dump makes tutor phrases and `_agentLine` look absent.

A candidate is AI-like when any of these hold:

- The visible text contains `_agentLine`.
- The body is tutor prose: 上一章, 下一章, Topic N, Lesson N, 本章, 本課, 學習目標, 課程導引, 課程導覽, 課程定位, or the same tone in English course notes (course roadmap, lesson note, chapter framing).
- `createdTime` clusters with other tutor-titled notes in the same hour, and the body is long generated prose rather than a scratch note.

Exclude, and say why:

- Titles that are user instructions (`Instructions:` and similar), even if the body is long.
- Empty or near-empty notes that do not cluster with a tutor batch. Do not tag them just because they are unplaced.
- Anything whose id is in the whitelist. Never override the whitelist with a title guess.

`_agentLine` is sufficient, not necessary. Deleted-course prose often has no agent mark. The whitelist plus tutor prose is what catches those. There is no official "created by AI" flag on `card list`.

Boundary batches still get the review tag, but call them out so the user can untag in the app. That includes interview drills, mixed English course notes, and a same-timestamp cluster of short `_agentLine` cards that are learning-method excerpts with citation numbers rather than chapter notes. Do not invent a second tag unless the user asks. Do not skip the cluster just because the prose is not "上一章 / Lesson N".

## 5. Tag, do not trash

1. Search first: `heptabase tag list -n 'orphan' --limit 50`. The command returns `{ content }` text, pages top-level tags (default 20, max 50), and `-n` is a case-insensitive substring. If `content` says no tags matched, the name does not exist. If it names a next offset, page before deciding.
2. Keep only a line whose quoted name is exactly `orphan`, shaped like `tag "orphan" [<tagId>] <N> cards`. A hit on `orphan-2026` or `AI殘留-可審核刪除` is not the tag to reuse. The UUID in brackets is the id for `tag cards` and `tag remove`. There is no `tags[].id` field to parse.
3. If nothing scored as AI-like this run, stop. Do not call `tag add` or `tag create`. `tag add` creates the tag when the name is new, so an empty run that "ensures the tag exists" leaves an empty tag the user did not ask for. Report that the fixed name does not exist yet.
4. When at least one card should be tagged, reuse the exact `orphan` tag if the search found it. Never create `orphan-YYYY-MM-DD`, `orphan-2`, a Chinese review name, or any other variant. Do not also `tag create` unless you need the id before adding. `tag create` fails with 409 if the name exists. `tag create` returns two ids; other tag commands take `tagId`, not `id`.
5. Add with `heptabase tag add --card-id <id> --tag-name 'orphan'`. One card at a time. Record failures and continue. Cards already on `orphan` stay there; do not remove the tag just because this run did not re-score them.
6. After the adds, list again and take the exact-name `tagId` from `content`. Verify with `heptabase tag cards <tagId>`. Newly tagged cards must not intersect the whitelist or the placed set. If the user named a deleted-course title, spot-check that it is tagged only when it is unplaced and not in the whitelist.
7. Do not run `heptabase card trash`. Trash only after the user reviews this tag in the app and names the ids to delete. Trash is recoverable with `card restore`.
8. If a card was tagged by mistake, `heptabase tag remove --card-id <id> --tag-id <tagId>`. Do not pass `--tag-name`; that flag is not on `tag remove`. Do not tell the user that membership cannot be removed.

## 6. Report what you did

Lead with counts: living courses, whitelist card ids, whiteboards, placed ids, unplaced notes, protected tutor notes, newly tagged, already tagged, excluded. Then list titles newly tagged this run. Name the excluded notes and why. Call out boundary batches by title so the user can untag them. If a living course had zero lessons, say so and still report any card ids whitelisted from `course read`. If nothing was newly tagged, say so and say whether a tag named exactly `orphan` already existed. Do not tell the user to open a tag this run did not create, and do not mention a newly created tag name. Do not claim cards were deleted.

## Pitfalls

- A page cap of 100 on `whiteboard list` and `card list` hides boards and notes. Stopping early makes placed cards look orphaned. `tag list` caps at 50, not 100.
- Parsing truncated stdout drops `cardId`s from `lesson read`. Those living notes then look deletable.
- Collecting every UUID in `lesson read` pollutes the whitelist with lesson and topic ids. Collect `cardId` only.
- Skipping `course read` card ids when `lesson list` is empty leaves living source cards unprotected.
- Scoring `note read` JSON as if it were visible text hides `_agentLine` and tutor phrases, so the AI score collapses. On CLI `>=0.10.0`, score `object read card`. The second `json.loads` applies only when `--help` still says `note read` is the content read.
- Unplaced is not unused. Tags, mentions, and highlight parents are invisible to `whiteboard cards`. The tag is a review queue.
- Living-course artifacts can also be unplaced. They stay out of this tag even when the prose looks generated.
- A title like `Instructions:` is a user instruction even when the body is long tutor-adjacent prose. Exclude it; do not tag it to make the run look productive.
- `tag add` creates a missing tag. Calling it, or `tag create`, when the scored set is empty creates an empty `orphan` the user then has to ignore.
- `tag list -n` is a substring filter and returns `{ content }` text. Reusing the first hit, or JSON-parsing a `tags` array that is not there, attaches cards to the wrong tag or drops the id needed for `tag cards` and `tag remove`.
- `tag remove --tag-name` is stale. Remove needs the tag UUID from the `content` line. A failed remove leaves a mistaken tag on the card.
- A hardcoded stop at an old CLI minor aborts a valid run once the loaded CLI skill and `heptabase --version` have both moved on. Gate on the loaded skill's range, then confirm flags with `--help`.