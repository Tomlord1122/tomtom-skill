---
name: heptabase-course-notes
description: Work a Heptabase AI Tutor course whiteboard from lesson artifacts. Consolidate per-lesson short notes and Q&A into one Short Note and QA card, or place each lesson's part cards in a column under that lesson note. Use when the user asks to 整理課程筆記, 排 course note, consolidate lesson notes and Q&A, organize a tutor course whiteboard, line cards under lesson notes, or says the course cards were not pulled onto the board (課程卡片沒抓出來). Do not use for splitting notes into concept cards, mapping which course cites a card, or listing cards missing from whiteboards.
tags:
  - heptabase
  - notes
  - whiteboard
metadata:
  cometline:
    origin: self-improvement
---

# Course notes and tutor lesson columns

Load `heptabase-cli` and check `heptabase --version` against its range. Read `references/whiteboard.md` before any layout write. This skill decides the artifact. The CLI skill decides the mutation shape.

Pick the job from the user's correction, not from the word "organize":

- **Summary card** — they want short notes and Q&A consolidated, or they name `Short Note and QA`. Follow "Consolidate into one card". Leave the rest of the board alone.
- **Lesson columns** — they want cards lined under each lesson note, or they correct a pass that split or regrouped the notes. Follow "Line parts under each lesson note". Do not write a summary.
- **Course cards not pulled** — they correct a pass that only arranged notes, or say the course cards were not brought onto the board (課程卡片沒抓出來 / 沒有把卡片抓上來). That is the column job, not a new summary and not a syllabus scan. Follow "Line parts under each lesson note", including "Pull missing lesson parts". Do not stop after rearranging notes already on the board.
- If they only said "organize this tutor whiteboard" and did not correct you, ask which of summary or columns they want. Do not start the concept-split pass.

This is not `heptabase-whiteboard-organize` (atomize oversized cards and regroup by concept). It is not `heptabase-tutor-card-usage` (which course cites a card) and not `heptabase-cards-not-on-whiteboard` (cleanup candidates).

Shared reads:

1. If a command returns "cannot connect to the desktop app", follow the CLI skill: `heptabase start`, then retry the original read. If start says the CLI server is not ready, stop.
2. `heptabase course list`. Match the board or the user's title. If several match, ask. Do not guess across courses.
3. `heptabase lesson list <courseId>` is the order: `{ lessonNumber, lessonId, title, isEnded, hasLessonPlan }`. A missing lesson stays a gap. Do not renumber. Sort by `lessonNumber`, not by title. "Lesson 10" sorts before "Lesson 2" as text.
4. Save full CLI JSON to a file and `json.loads` it. A truncated tool result drops later lessons.

## Line parts under each lesson note

The job is spatial. Each lesson's existing cards sit under that lesson's note, left to right by lesson number. Do not split notes, rewrite titles, invent concept cards, or delete sources.

### 1. Bind the board

1. Extract the whiteboard id from the URL. The workspace segment is not a CLI argument.
2. `heptabase whiteboard read <id> --mode structure` and `read-layout`. Titles like `Lesson N note` are the row.

### 2. Take children from lesson artifacts, not from ProseMirror

1. For each lesson, `heptabase lesson read <lessonId>`. Children are `aiArtifacts.lessonParts` in returned order: `{ cardId, title }`. The note is `aiArtifacts.lessonNotes[0].cardId` when that list is non-empty.
2. `note read` returns ProseMirror JSON as a **string** in `content`. Tutor headings are markdown-style links (`link` marks whose `href` contains `/card/<uuid>`), not `card` mention nodes. Walking the tree for `type: card` finds nothing. Do not use that walk to decide the column.
3. Syllabus `topics[].sources[]` are cited literature, not the cards to line up. Use them only if the user asked for sources, 來源, or 教材. After a note-only layout, "課程卡片" means `lessonParts`, not those sources.
4. If `lessonNotes` is empty but a part title is `Lesson N note`, that part is the note. Do not also place it as a child.
5. A card already on the board that is not a lesson part (a diagram standing in for a missing note) stays. Put it at the bottom of that lesson's column. Say so. Do not treat it as the note. Do not use this rule for a real `lessonParts` card from a lesson that has no note — that card gets its own column. See "Lesson with parts but no note".

### 3. Pull missing lesson parts before arranging

A tidy note row is not evidence the course cards are on the board. Parts are often library cards, or instances on another whiteboard.

1. `heptabase whiteboard cards <whiteboardId>`. Build the set of `cardId` values already on this board. Compare it to every `lessonParts[].cardId` and every `lessonNotes[].cardId`. A note being present does not imply its parts are present.
2. Place every missing part, and any missing note, in one `place-objects` call. `objectType` is `card`. `destination` is `{ "type": "auto" }`. Pass card ids, never `inst:` ids. Pipe JSON on stdin:

```bash
heptabase whiteboard place-objects --input -
```

```json
{
  "whiteboardId": "<whiteboardId>",
  "objects": [
    { "id": "<cardId>", "objectType": "card" }
  ],
  "destination": { "type": "auto" }
}
```

3. Inspect `results[].status`. `placed` is success. A top-level `completed` can still hide item failures. Save the result: later arrange calls need `whiteboardObjectId` / `instanceId` as `inst:<id>`, not the card id.
4. Do not `course read` to fill this gap. Syllabus sources are a different set. Placing them leaves the lesson parts off the board.

### 4. Place, then arrange notes, then arrange each column

`place-objects` with `destination: auto` drops new cards far from the notes, often unmeasured (`520x?`). Place first, arrange second. Do not place each child with `nextTo` in one shot. Arranging the note row before the columns will overlap the auto-placed parts. That overlap is expected. Clear it with the column pass. Do not stop at the note row.

1. If the lesson note is not on this board, `place-objects` it `nextTo` the previous lesson note, side `right`, gap `0`, alignment `center`. `nextTo` sides are `above`, `below`, `left`, `right` — not `top` or `bottom`. If lint reports `overlap` with the card that occupied that slot, `move-objects` the cards to the right by about one card width (`delta` `dx`) before arranging. A move only moves the objects you list.
2. Arrange the lesson notes only, as a row, gap about `48`, alignment `top`, anchored at a point clear of other content. Input order is lesson order. Do not include children. Arranging a parent does not carry cards that are not section members. Use `inst:` ids from the board, not card ids.

```json
{
  "whiteboardId": "<whiteboardId>",
  "objects": [
    { "id": "inst:<lesson1NoteInstance>", "objectType": "card" },
    { "id": "inst:<lesson2NoteInstance>", "objectType": "card" }
  ],
  "layout": { "type": "row", "gap": 48, "alignment": "top" },
  "anchor": { "type": "point", "x": 1148, "y": -1595 }
}
```

3. For each lesson that has a note, `arrange-objects` the children as a column, gap `40`, alignment `center`, anchor `nextTo` the note, side `below`, gap `80`, alignment `center`. A handful of lessons per call. Re-run this after the note row moves. Children keep absolute positions when only the notes are arranged, so a note-row arrange without a second column pass leaves the children behind and they overlap the next lesson.
4. Do not wrap a Section unless the user asked. Do not create arrows from the note to every child. Proximity is the relation. Existing star arrows through a vertical stack lint as `connectionCrossesObject`. Remove those connections with `remove-objects` (`objectType: connection`). That removes the arrow, not the cards. Do not `remove-card` user notes.

### 5. Lesson with parts but no note

`lessonNotes` empty, and no part titled `Lesson N note`, is not "skip this lesson" and not "append under the previous column". Do not create a note card to fill the gap.

1. Finish the note row first.
2. One orphan part: arrange it on the note row, to the right of the previous lesson note. It stands in for the missing note. Same-row alignment is `center`.

```bash
heptabase whiteboard arrange-objects --input -
```

```json
{
  "whiteboardId": "<whiteboardId>",
  "objects": [
    { "id": "inst:<partInstanceId>", "objectType": "card" }
  ],
  "layout": { "type": "column", "gap": 40, "alignment": "center" },
  "anchor": {
    "type": "nextTo",
    "objectId": "inst:<previousLessonNoteInstance>",
    "objectType": "card",
    "side": "right",
    "gap": 48,
    "alignment": "center"
  }
}
```

3. Several orphan parts: same anchor, but alignment `top`, layout `column`, gap `40`. The first part sits on the note row. The rest stack below, parallel to the other columns, without mixing into the previous lesson.
4. Say in the report that this lesson has no note yet, and name the cards parked in its place. Do not call that card the lesson note.

### 6. Verify the columns

1. `heptabase whiteboard lint <id>`. `overlap` between two columns means a child column was anchored before the note row moved, or a diagram was left in the old slot. Re-arrange that column. Do not shrink cards to hide overlap. Overlap reported on the note-row arrange, before the column pass, is the auto-place collision. Run the column pass before treating it as a layout bug.
2. Read layout around the note row and confirm every `lessonParts` card id is on this board, in lesson order, under its note (or on the note row if that lesson has no note). `whiteboard cards` is the identity check. A screenshot is not.
3. Screenshot the whole board. A schematic is enough to see columns. Confirm card identity from structure, not from the screenshot.
4. Report what was placed, which note was missing, and any non-part card parked at the bottom of a column. Do not report the job done if only the notes moved.

## Consolidate into one card

The artifact is one note titled `Short Note and QA`. Concept sections come first. A single `Q&A` section comes last, grouped by lesson. Do not create a new card when that summary already exists. Update it. Do not reflow the board as part of this job.

### 1. Find the existing summary

1. Find the course whiteboard from the user's link, or from cards the course already cites. `heptabase course read <courseId>` has `topics[].sources[].cardId`. `heptabase card properties <cardId>` does not list whiteboards. Use a known board URL, or scan `heptabase whiteboard list` and `heptabase whiteboard cards <id>` until the cited cards and any existing `Short Note and QA` card appear together.
2. Reuse the existing summary card on that board if its title is `Short Note and QA`. Search before creating. Create with `heptabase note create` only when no summary card exists, then place it. Mark it Created-by-AI. Do not delete the old card to "start clean".

### 2. Collect short notes and Q&A per lesson

1. For each lesson, `heptabase lesson read <lessonId>`. `aiArtifacts` may be a dict of `lessonParts` and `lessonNotes`, or a list of ids or `{ cardId }` objects. Read each id with `heptabase note read`.
2. Also read `heptabase lesson list-messages <lessonId>` when the user asked for Q&A, or when artifact cards have notes but no questions. Page with `offset` until `hasMore` is false. Keep user questions and the tutor's direct answer. Skip greetings, "continue", and tool chatter.
3. Short notes are the condensed lesson takeaways, not the full lesson dump and not the syllabus source PDF. Prefer a card whose title or body is already a short note. If the only artifact is a long lesson note, compress it. Do not paste the lesson transcript into the summary.
4. Concept headings already on the board are the link targets. Read those cards before writing a heading. Link a heading only when a real concept card exists. A heading with no card stays plain text. Do not invent a concept card just to have a link.
5. Lessons with no Q&A are omitted from the Q&A section. Say so in the chat report. Do not write "No questions" filler into the card.

### 3. Write one card, notes first, Q&A last

Use Markdown via `heptabase note create` or a full replace. Prefer Markdown over hand-built ProseMirror. Read `references/card-content-schema.md` before any JSON save.

Shape:

```markdown
# Short Note and QA

### Why Helm Exists

- **To solve YAML explosion and configuration drift**
  - Across Dev/Staging/Prod, copying YAML by hand makes maintenance grow linearly with environment count.

### Q&A

- **Lesson 1 — Why Helm Exists**
  - **Q:** Is there a helm lint command or a debug mode?
    - **A:** `helm lint` does static checks. `--debug` renders the chart and checks the final YAML.
- **Lesson 2 — Chart, Values, Release**
  - **Q:** Does a Chart uploaded to OCI include values for every environment?
    - **A:** No. The chart carries templates and defaults. Environment values stay in Git.
```

1. One H1: `Short Note and QA`.
2. Each concept is an H3. The heading text is the concept name. When a source concept card exists, the heading is a link to `https://app.heptabase.com/<whiteboardId>/card/<cardId>`.
3. Under each concept, bullets only. The first line of a bullet is the claim in bold. Nested bullets are the one-sentence support. No paragraphs between sections.
4. After every concept section, one H3 `Q&A`. Group by lesson in `lessonNumber` order. Bold the lesson label. Each question is `Q:` and its answer is a nested bullet starting with `A:`.
5. Keep the user's language. If the source notes are Chinese, write Chinese. Do not translate unless asked.
6. Compress. A section that pastes the source card is not a short note. If two lessons teach the same concept, keep one concept section and mention both lessons only in Q&A.
7. On update, rewrite the whole summary from the lessons just read. Do not append a second `Q&A` under the old one. Preserve wording you did not re-read only by leaving those lessons unchanged, and say which lessons you skipped.

Markdown links are enough for headings. `{{card UUID}}` mentions are for inline references, not for the heading itself. Do not put a video or image line in this card.

### 4. Save without clobbering an edit in progress

1. `heptabase note read <summaryId>` and keep `contentMd5`.
2. Write the markdown to a temp file. Append-only is wrong for a rebuild. If the CLI can replace from markdown, use that. Otherwise convert through the documented save path and pass `--content-md5`.
3. If save conflicts, re-read, reapply only the lesson sections you changed, and save again once. If it conflicts again, stop and show the user both versions' headings. Do not keep retrying.
4. Do not edit, move, or trash the source lesson cards, syllabus cards, or concept cards. Linking is the only mutation those cards receive, and only as an outbound URL from the summary.
5. If the summary card is not on the whiteboard, place it. Do not reflow the rest of the board as part of the summary job.

### 5. Report what changed

Tell the user:

- course title, whiteboard id, summary card id, and the app URL
- lessons included, and lessons skipped because they had no short note or no Q&A
- concept headings added or updated, and which headings are linked
- whether the card was created or replaced

Do not claim a lesson was read if `lesson read` failed. A connection error is not an empty course.

## Pitfalls

- A note-only arrange looks finished because the row is tidy. The user who says the course cards were not pulled is asking for `lessonParts` that `lesson read` lists and `whiteboard cards` does not. Stopping after the note row is the miss.
- "課程卡片" after a layout pass is lesson parts. `course read` `topics[].sources[]` is cited literature. Placing sources answers a different question and still leaves the parts off the board.
- A lesson with parts and an empty `lessonNotes` is its own column to the right of the previous note. Appending those parts under the previous lesson mixes two lessons. Inventing a `Lesson N note` card adds a card the tutor did not generate.
- `note read` `content` is a JSON string. Parse the outer result, then parse `content` again if you need the tree. A walk that never parses the inner string reports zero mentions.
- Tutor lesson headings link with `marks[].attrs.href`, not `card` nodes. For columns, artifact order from `lesson read` is the order to arrange. Link order inside the note can repeat the same card and can omit a diagram already on the canvas.
- `arrange-objects` anchor side `bottom` fails validation. The enum is `below`.
- `place-objects` `auto` is not a layout. Cards land in a long row at the edge of the board. Always arrange after place. Overlap lint on the note-row pass, before columns, is that auto-place collision, not a reason to undo the place.
- Arranging notes and arranging children are two passes. The second pass must happen after the first, or columns stay at the old coordinates and overlap the next lesson.
- `place-objects` takes card ids. `arrange-objects` and `move-objects` take `inst:` instance ids from the place result or the board. Passing a card id to arrange does not move the instance you just placed.
- `aiArtifacts` is not a flat list of card ids. Skipping `lesson read` and guessing from `card list -q` pulls the wrong notes.
- Syllabus `sources` are the materials the tutor cited. They are not the short notes and not the column children.
- A truncated `note read` in the tool result drops the Q&A tail. Parse the CLI's full stdout from a file.
- Appending a new Q&A block onto an existing summary duplicates every prior lesson. Replace, or surgically replace the `Q&A` heading and everything after it.
- Creating a second `Short Note and QA` card because search missed the first one is the failure the summary path exists to prevent. Search the board before `note create`.
- Do not run the whiteboard organize split pass on the summary card or on lesson notes as part of either job. The summary is allowed to be long. Lesson columns reuse existing cards.