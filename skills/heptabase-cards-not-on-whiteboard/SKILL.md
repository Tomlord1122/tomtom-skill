---
name: heptabase-cards-not-on-whiteboard
description: Find Heptabase library cards that are not placed on any whiteboard, excluding journals and cards still cited by living AI Tutor courses. Use when the user asks which cards are missing from whiteboards, which human-written cards are off-canvas, which cards might be deleted after courses finish, or for a cleanup candidate list. Do not trash cards unless the user explicitly asks to delete the reviewed list. Do not use for tagging leftover notes from deleted courses (hb-orphan).
tags:
  - heptabase
metadata:
  cometline:
    origin: self-improvement
---

# Find cards not on any whiteboard

The CLI has no orphan index. `whiteboard cards` is whiteboard-to-card. A card is unplaced only when its id is absent from every whiteboard's card list. This scan excludes journals and cards still cited by living courses. The result is a cleanup candidate list, not a delete command. A connection error is not an empty library.

When the user asks for human-written cards that are not on a whiteboard, do not start a second scan and do not retag. Run this scan across every non-journal type, then report the unplaced rows whose ids are not in the living-course citation set. Leave tutor residue to `hb-orphan`.

## 1. Confirm the interface, then the server

1. Load the Heptabase CLI skill and check `heptabase --version` against its compatibility range before any read. Read `metadata.heptabase-cli-version-range` from that skill. If `--version` is outside that range, stop and ask the user to update the app or the CLI skill. Do not invent flags. Do not stop only because an older copy of this skill named `0.8.x`.
2. Run `heptabase whiteboard list --help`, `heptabase whiteboard cards --help`, `heptabase card list --help`, `heptabase course --help`, `heptabase lesson --help`, `heptabase object read --help`, and `heptabase note --help`. Expect `whiteboard list`, `whiteboard cards`, `card list --card-types`, `course list`, `course read`, `lesson list`, and `lesson read`. Do not invent a `card whiteboards` flag.
3. If a command returns "cannot connect to the desktop app", read the CLI skill's sandbox note, then run `heptabase start`.
4. If start says the CLI server is not ready, stop. Only the user can enable CLI in Settings > AI Features. Do not keep relaunching, and do not read local app databases.
5. When the user says the CLI is available, retry the original read. Do not repeat `start` first.

## 2. Build the placed set from every whiteboard

1. Page `heptabase whiteboard list --limit 100 --offset N` until `offset` reaches `total`. The page cap is 100. A default page of 20 hides child boards.
2. For each whiteboard id, run `heptabase whiteboard cards <whiteboardId>`. Collect `cards[].cardId`. Also keep `title`, `cardType`, and the whiteboard name.
3. Do not parse a truncated tool result. Call the CLI from a script, `json.loads` the full stdout, and print only the summary. One card can sit on several boards; count unique ids.
4. `whiteboard cards` returns placed card instances (`cardInstance`, `pdfCardInstance`, `videoCardInstance`, and other `*CardInstance` types). It does not list whiteboard shortcuts, sections, or connections. A nested whiteboard is its own board in `whiteboard list`; scanning every board already covers cards placed only on a child board.
5. Ignore rows with no `cardId`. Do not treat `whiteboardObjectId` as the library card id.

## 3. Exclude journals, then subtract living-course citations

1. Page `heptabase card list --card-types note,pdf,highlightElement,source,image,video,audio,web --limit 100 --offset N` until `offset` reaches `total`. Keep `id`, `objectType`, `title`, and `createdTime`. Omit `journal` from `--card-types`. Also drop any row whose `objectType` is `journal`.
2. Unplaced cards are the remaining library rows whose `id` is not in the placed set. Notes-only (`--card-types note`) is not enough when the user asked for cards. PDF, image, highlight, source, video, audio, and web rows can also be off-canvas.
3. Build the living-course citation set the same way `hb-orphan` builds its whitelist. `heptabase course list`, then `course read` and `lesson list` for each course, then `lesson read` for each lesson. Collect `cardId` only: course topic sources, lesson parts, lesson notes, and topic sources. Do not collect bare `id`, `lessonId`, or topic ids.
4. Subtract that citation set from the unplaced set before calling anything a cleanup candidate. A living course can cite a card that is not on a whiteboard. That card is held, not a candidate.
5. A course with zero lessons is not an empty citation set. `course read` can still name source cards. Collect those.
6. Also record which courses are still in progress (`isEnded: false`, or a subtopic `status` of `notStarted` or `inProgress`) so the report can say how many held cards belong to unfinished courses. Do not use that flag as the only hold rule.
7. On a real library this mattered twice: 152 non-journal cards were unplaced and 59 were lesson artifacts from courses still in progress, so reporting 152 as deletable included live course notes. Later, 21 unplaced notes remained and 20 were still cited by living courses, including a course with no in-progress signal. Reporting those 20 as human-written would have been wrong.

## 4. Split human-looking rows from cleanup candidates

Use this split only when the user asks for human-written, hand-written, or 人寫 cards that are not on a whiteboard. Otherwise stop at the cleanup candidate list in section 5.

1. Human-looking unplaced cards are unplaced rows whose id is not in the living-course citation set. Do not also subtract a residue tag and call that authorship. An empty residue tag means a previous cleanup already removed those notes, or they were never tagged. It does not prove the remainder is human.
2. There is no official Created by AI field on `card list`. The create-time mark in the CLI skill is for new `note create` / `journal create` calls. It is not a filter you can page. Do not invent `--created-by-ai`.
3. For each remaining note, read visible text with the command `--help` names. On CLI `>=0.10.0`, `heptabase object read card <cardId>` returns line-numbered Hepta Markdown. Score that string. Use `heptabase note read <cardId>` only when `--help` still says it is the content read. On that older path, `content` is a JSON string. `json.loads` it, then walk `text` nodes. Walking the string finds nothing, so every note looks blank. Do not score the JSON dump.
4. Call a note human-looking when the citation set does not contain it and the body is not tutor prose (上一章, 下一章, Topic N, Lesson N, 本章, 本課, 學習目標, 課程導引, 課程導覽, 課程定位, course roadmap, lesson note, chapter framing) and the document has no `_agentLine`. A title like `Instructions:` is user-owned even when the body is long. Read it before recommending a move.
5. If a remainder note is tutor prose or has `_agentLine`, do not call it human. Point the user at `hb-orphan` for deleted-course residue. Do not tag it from this skill.
6. Do not place, tag, or trash the human-looking list unless the user names that action. A space-instruction note is often meant to stay in the card library.

## 5. Report candidates, do not delete them

1. Lead with counts: whiteboards, unique placed ids, library cards, unplaced cards by `objectType`, held living-course citations, and (only if section 4 ran) human-looking remainder. Then titles and ids. Say journals were excluded.
2. Call the non-human remainder cleanup candidates, not cards safe to delete. `whiteboard cards` does not see mentions inside note text, tags, or whiteboard connections. A candidate can still be a highlight, an attachment parent, or a note the user wants off-canvas.
3. Do not run `heptabase card trash`. Trashing is allowed only after the user reviews a concrete id list and explicitly asks to trash those ids. Even then, trash only that reviewed list, and remind the user that trash is recoverable with `card restore`.
4. If the user asks for one card, check that id against the placed set and the held set, and name the boards or the course. Do not rescan only the root whiteboards.
5. Keep living-course citations out of the candidate list even when every course looks finished. Ask before folding finished-course lesson notes into candidates. Do not merge that ask into the human-looking list.

## Pitfalls

- `whiteboard list` and `card list` both cap a page at 100. Stopping after the first page under-counts boards and makes placed cards look orphaned.
- Truncated tool output is not a short board or a short lesson. Extracting ids from cut-off JSON drops placements and artifacts. Parse the CLI's full stdout.
- Journal dates are cards. Leaving `journal` in `--card-types` inflates the orphan list. Exclude them unless the user asks.
- Lesson artifact ids are easy to miss because `aiArtifacts` is not a flat `cardId` list. Skipping `lesson read` leaves living course notes in the human list.
- Collecting every UUID in `lesson read` pollutes the citation set with lesson and topic ids. Collect `cardId` only.
- A card placed only on a child whiteboard is still placed. Filtering to `parentWhiteboardId == null` misses those boards.
- Holding citations only while a course looks active drops notes that a finished-looking living course still cites.
- An empty residue tag is not an authorship signal. Subtract living-course `cardId`s, then read the remainder.
- Scoring `note read` JSON as visible text hides tutor phrases and `_agentLine`, so generated notes look blank or human. On CLI `>=0.10.0`, score `object read card`. The second `json.loads` applies only when `--help` still says `note read` is the content read.
- A connect or "CLI server is not ready" error means the desktop server is down or CLI is disabled. An empty diff is a separate result, visible only after both lists finish.
- Not being on a whiteboard is not proof a card is unused. This skill answers canvas placement minus journals and living-course citations. It does not answer backlinks.