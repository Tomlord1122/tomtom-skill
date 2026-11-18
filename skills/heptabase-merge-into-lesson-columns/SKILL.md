---
name: heptabase-merge-into-lesson-columns
description: Move cards from child Heptabase whiteboards onto a parent board whose lesson notes already form columns, and drop connections when the user wants cards under the matching lesson rather than a preserved graph. Use when the user asks to 整理到這張白板, sort same-topic cards into an existing lesson column, or says 連線可以先刪除 and to place source cards under the corresponding lesson. Do not use for tutor-artifact columns, splitting notes into concept cards, or stacking section frames by chapter color.
tags:
  - heptabase
  - whiteboard
  - layout
metadata:
  cometline:
    origin: self-improvement
---

# Merge child-board cards into lesson columns

Load `heptabase-cli` and check `heptabase --version` against its range. Read `references/whiteboard.md` before any layout write. This skill decides which cards move and where they sit. The CLI skill decides the mutation shape.

This is not `heptabase-course-notes` (tutor `lessonParts` under a lesson note). It is not `hb-order-layout` (stack existing section frames by chapter). It is not `heptabase-whiteboard-organize` (atomize notes and draw concept arrows).

## When to stop arranging and just place

If the user says connections can be deleted, and the destination already has one column per lesson, do not preserve the source graph and do not invent new sections.

Place each source card in the column of the lesson it belongs to, below the cards already in that column. Reading order inside the column is enough. A vertical stack makes "this belongs to that lesson" visible. Side-attached arrows and a two-column grid do not, and old curves then cross cards.

Confirm the match from titles already on both boards (lesson note title vs source section or card topic). Do not open every note to reclassify when the column map is already on the canvas.

## Identify boards before any move

1. An `app.heptabase.com` URL is `/{workspaceId}/whiteboard/{whiteboardId}`. The CLI argument is the segment after `whiteboard/`.
2. `heptabase whiteboard read <id> --mode structure` on the destination and each source. A source whose parent is the destination is a child board, not a second copy of the same cards.
3. Save each JSON body to a file and print `content`. A truncated tool result hides later sections. Do not plan from the first page of a tool result.
4. Read destination geometry with tiled viewports, not one huge viewport. A default or oversized `read-layout` lists a few objects and hides the rest as peripheral counts with no ids. Tile about 4000x3000, step smaller than the window, and merge by card id.

The destination column key is the shared `x` of `Lesson N note`. Sort lesson numbers numerically. "Lesson 10" is not between "Lesson 1" and "Lesson 2".

## Move the child board, then place cards

`move-objects-across` with `selection.type: all` moves cards, sections, and internal connections onto the destination and keeps relative layout. It does not line cards up under lesson notes. Use it only as the transfer. Then arrange.

Move the deepest child first, then its parent. A parent `all` selection also moves the child-board shortcut. After the transfer, that shortcut is an empty pointer. Leave it. Do not delete the source whiteboard or the cards.

```json
{
  "sourceWhiteboardId": "<childWhiteboardId>",
  "destinationWhiteboardId": "<parentWhiteboardId>",
  "selection": { "type": "all" }
}
```

Check `status` and per-item results. A top-level success can still contain item failures.

`arrange-objects` and `move-objects` accept the card UUID from `whiteboard read`, with `objectType: card` (or `videoCard`). They do not require `inst:` ids. `place-objects` is the wrong command here: these cards are already placed after the cross-board move.

## Drop connections before stacking

Do this only when the user said connections can go. Do not delete connections to "clean up" a board they still want related.

1. Connection ids are not in the default layout listing. `read --mode structure` truncates a large board and omits the connection block.
2. Tile `read-layout` with `--include-connection-ids` at about 1600x2800. A focus or viewport that covers the whole board returns a count (`connection: 44`) and no bracketed ids.
3. Parse lines shaped `[<connectionId>] <fromCardId> -> <toCardId>`. Merge until the unique id count matches the structure header count.
4. Remove them in one `remove-objects` call. `objectType` is `connection`. This removes the canvas route, not the cards.

```json
{
  "whiteboardId": "<parentWhiteboardId>",
  "removals": [{ "id": "<connectionId>", "objectType": "connection" }]
}
```

Empty section frames left behind by the move are the same kind of leftover. `remove-objects` with `objectType: section` removes the frame and leaves members. Do that only after the cards have already been arranged out of those frames. Never `remove-card` a user note.

## Stack under the lesson, not beside it

1. Map each incoming card to one destination column from the topic already visible in titles. One card, one column.
2. Find the bottom of that column from a tiled read: max `y + height` among cards that share the lesson `x`. Start the new stack one gap below that, about 80px. Do not reuse a fixed `y` from an earlier read after you have moved other cards.
3. `arrange-objects` that column's incoming cards only, in reading order, as a column with `gap` about 40 and `alignment: left`. Anchor `x` is the lesson note's `x`.

```json
{
  "whiteboardId": "<parentWhiteboardId>",
  "objects": [
    { "id": "<cardId>", "objectType": "card" }
  ],
  "layout": { "type": "column", "gap": 40, "alignment": "left" },
  "anchor": { "type": "point", "x": 5880, "y": 4100 }
}
```

4. `status: unchanged` on a card that is already at that anchor means the move landed. Do not retry with the other id form. If a later card in the same call overlaps the one above it, reread heights and arrange that column again. A tall card (design-review, auto-height) is not 720px; the next `y` must use the measured height.
5. Video cards use `objectType: videoCard`. Put them at the bottom of the column they belong to, not between the note and the concept cards.
6. Move emptied whiteboard shortcuts to the right of the last lesson column with `move-objects` and `destination.type: point`. They are not lesson cards.

## Verify

1. Tile the destination again. Every moved card shares a lesson-column `x`. No card remains at the old source coordinates.
2. Within a column, each card's bottom is above the next card's top. A clean lint is not this check.
3. `heptabase whiteboard lint <whiteboardId>`. Mention leftover issues. Do not restack the board to chase pre-existing noise.
4. Screenshot a few column viewports, not one whole-board PNG. A zoomed-out schematic shrinks open cards to title strips and hides whether a card sits under the lesson note.
5. Tell the user which lesson received which source group, that connections were removed because they asked, and that the empty child-board shortcuts were left in place.