---
name: hb-dead-links
description: Remove unused or invalid Heptabase card references from notes on a whiteboard or card the user links. Use when the user shares an app.heptabase.com whiteboard or card URL and asks to clear dead links, broken mentions, invalid refs, or unused internal links, or asks to remove 引用編號, or invokes /hb-dead-links. Do not use for wiki [[links]], whiteboard layout lint, tagging unplaced cards, or rewriting a whiteboard into another language.
tags:
  - heptabase
  - cleanup
metadata:
  cometline:
    origin: self-improvement
---

# Clear dead Heptabase card links

The user gives one whiteboard URL or one card URL. Edit only note bodies in that scope. Remove internal references whose target card or whiteboard is gone, or whose target is not placed on the whiteboard being cleaned. If the visible text is only a citation number (引用編號) such as `[1]` or `[7]`, delete that text too. If the visible text is a real title or phrase, leave it as plain text. Do not trash cards, do not remove whiteboard connections, and do not rewrite prose.

If the same request also rewrites the board into B2 or another language, load the board rewrite skill and do both edits in one save per note. This skill still decides which links are invalid.

## 1. Confirm the CLI, then parse the URL

1. Load the Heptabase CLI skill. Run `heptabase --version` and `heptabase help` before any read. Expect `note read`, `note save`, `card list`, `journal read`, `pdf metadata`, `whiteboard list`, `whiteboard cards`, and `whiteboard read`. Confirm each with `--help`.
2. Accept the version range the CLI skill pins. `0.9.x` is valid when `--version` prints it and that skill allows it. Do not stop because this skill once said `0.8.x`. If a required command is missing, stop. Do not invent flags.
3. If a command returns "cannot connect to the desktop app", follow the CLI skill and run `heptabase start`. If start says the CLI server is not ready, stop. Only the user can enable CLI in Settings > AI Features.
4. Parse the URL. Do not open it in a browser.
   - `https://app.heptabase.com/<whiteboardId>` is a whiteboard. The first UUID is the whiteboard id.
   - `https://app.heptabase.com/<whiteboardId>/card/<cardId>` is one card. Ignore the whiteboard id in the path for scope. The card id is the last UUID before the query string.
   - `https://app.heptabase.com/<whiteboardId>/section/<sectionId>` is not a card. Stop and ask for a whiteboard or card URL.
   - A bare UUID is a card id only if the user says it is a card. Otherwise ask.
5. Drop the query string before parsing. `_agentLine`, `pdfPage`, and `playbackStart` are locations inside a target, not a different target.

## 2. Build the scope

Whiteboard URL:

1. `heptabase whiteboard cards <whiteboardId>` and `json.loads` the full stdout from a file. Keep every `cards[].cardId`. `whiteboardObjectId` is not the library card id.
2. Also run `heptabase whiteboard read <whiteboardId> --mode structure` and collect UUIDs in brackets. That catches section-nested cards if `whiteboard cards` is short. Union the two sets. If the whiteboard is not found, stop.
3. Scope notes are those card ids whose `card list` / `note read` type is `note`. Skip pdf, image, video, audio, and web cards as edit targets. They can still be valid link targets.
4. If agents will edit for a long time, list the whiteboard again before the last deletion pass. A card that left the board during the job is unused now even if it was placed at the start.

Card URL:

1. Scope is that one card. `heptabase note read <cardId>`. If it is not a note, stop and say this skill only edits note bodies.
2. Do not expand to the rest of the whiteboard.

## 3. Find references in note JSON

`note read` returns `content` as a JSON string. `json.loads` it before walking. Write every CLI stdout to a file first. A truncated tool view drops ids.

Walk the ProseMirror doc. A reference is only one of these:

- An inline node whose `type` is `card`, `pdf_card`, or `whiteboard`. Its id is `attrs.cardId`, `attrs.pdfCardId`, or `attrs.whiteboardId`.
- A block node whose `type` is `mention` or `embed`. Its id is `attrs.objectId`. Its kind is `attrs.objectType`.
- A `link` mark on a text node, or a `link` node, whose `attrs.href` matches `https://app.heptabase.com/<uuid>/card/<uuid>` or `https://app.heptabase.com/<uuid>`. The target is the card UUID when `/card/` is present, otherwise the whiteboard UUID.

Ignore external `http` links, `{{date}}` mentions, image `src`, video URLs, and `data-internal-href` unless the `href` itself matches the patterns above.

## 4. Classify, do not guess

Resolve each target once. Cache the result. On a whiteboard job, the fresh placed set is enough to mark a card link unused. Do not treat "not in an old valid-ids file" as proof if you have not re-listed the board.

Invalid — remove:

- `note read <id>` returns "Card not found", and the same id is absent from a paged `heptabase card list` of all types. Page with `--limit 100` until `offset` reaches `total`. Search is not enough. A keyword miss is not proof the card is gone.
- `pdf metadata <id>` returns not found, and the id is absent from that full card list.
- `whiteboard list` pages do not contain that whiteboard id, and `whiteboard read <id>` returns not found.
- `journal read <YYYY-MM-DD>` returns not found for a journal mention. Do not treat a missing journal as a card.

Unused — remove only when the user gave a whiteboard URL, or asked to clean the whiteboard that contains the linked card:

- The target card exists, but its id is not in that whiteboard's placed set from step 2.
- A whiteboard mention whose id is not this whiteboard and not a child listed by `whiteboard list` (`parentWhiteboardId` equals this whiteboard). Child whiteboards are used. Do not strip them.
- On a single-card URL, do not apply the unused rule. Existence is the only test. A card can legally mention something that lives on another board.

Never invalid just because a query string looks stale. If the card id exists, keep the link, including `_agentLine` and `pdfPage`.

If a check errors for a reason other than not found (connection, timeout, unexpected shape), skip that reference and report it. Do not delete on an uncertain check.

## 5. Edit the JSON, then save

Read `references/card-content-schema.md` in the Heptabase CLI skill before the first save.

For each note that has a removable reference:

1. Keep the original `content` string and `contentMd5` from `note read`.
2. Remove the reference node. For a `link` mark, remove the mark. Then remove the 引用編號, not just the link:
   - If that text node is only a citation number matching `[1]`, `[7]`, or `^\s*\[\d+\]\s*$`, delete the whole text node.
   - Also delete a sibling text node in the same block that is only that citation number, even when the link mark sat on a different node. Tutor notes often split the marker from the link.
   - A real label stays: `課程導引` becomes plain text `課程導引`.
   - Do not delete code or prose that merely contains brackets, such as `slice[0]`, `rate(http_requests_total[5m])`, or a sentence with a number in it.
3. If a paragraph, heading, or list item becomes empty because its only content was the removed node, delete that block too. Do not leave an empty `content` array on a block that requires content. A `doc` must still contain at least one block. If the note would become empty, leave a single empty paragraph `{"type":"paragraph","attrs":{"id":null},"content":[]}` only if the schema allows it. If save rejects that, stop that note and report it. Do not invent filler prose.
4. Preserve every other node, mark, `id`, and media `reference` attr. Do not re-serialize through Markdown. Markdown save drops structure.
5. Write the new document JSON to a file. Save with `heptabase note save <cardId> --content-md5 <contentMd5> --content-file <path>`.
6. If save conflicts on md5, `note read` again. Re-apply the same removals on the new doc. Retry once. If it still conflicts, skip that note and report it.
7. If save says the card is already trashed, skip it. Do not restore it.
8. Read the note again. Confirm each removed href or node is gone, and that an unrelated link in the same note is still present.

Do not run `note append`. Do not create a new card. Do not `card trash`.

## 6. Report

Lead with the URL scope, notes scanned, references removed, and references kept. Group removals as invalid or unused. For each removal, give the source note title, the label text, and the target id. List skipped notes and why. Say no cards were trashed and no whiteboard connections were removed. A color or highlight count may drop when the mark lived only on a deleted citation node. Say that. Do not claim a sentence highlight was preserved if you did not re-read it.

## Pitfalls

- The first UUID in a Heptabase URL is often a whiteboard id, not a card id. `note read` on it returns not found. That does not mean the link is dead.
- `card list -q <uuid>` can miss a live card. Only a full paged list, or a successful `note read` / `pdf metadata` / `whiteboard read`, proves existence.
- Placed cards and mentioned cards are different sets. A mention of a card that exists only in the library is unused on this whiteboard, not invalid.
- A 引用編號 such as `[1]` or `[7]` is not a label. Delete the marker with the dead link, including a sibling text node that is only the marker. A real title or phrase stays as plain text. `slice[0]` and PromQL ranges like `[5m]` are not citation numbers.
- Whiteboard `connection` objects are geometry. This skill does not remove them, even when they point at a missing card.
- Do not scan the whole library unless the user gave a whiteboard and you are resolving targets. Edit scope stays the linked whiteboard or the linked card.
- A copied `0.8.x` pin is stale when `heptabase --version` is `0.9.x` and the CLI skill allows that range. Trust `--version`, not the old sentence.
- An old valid-id snapshot goes stale while other agents edit. Re-list the whiteboard before the last deletion pass.