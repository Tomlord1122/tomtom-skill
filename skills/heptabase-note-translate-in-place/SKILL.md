---
name: heptabase-note-translate-in-place
description: Translate a Heptabase note fully into another language while keeping ProseMirror structure, marks, and formulas. Use when the user shares an app.heptabase.com card URL and asks to translate the card, fully into English, or rewrite the note body in another language. Do not use for a whole whiteboard, dead-link cleanup alone, whiteboard layout, or translating a wiki page.
tags:
  - heptabase
  - translation
metadata:
  cometline:
    origin: self-improvement
---

# Translate a Heptabase note in place

The user gives one card URL and a target language. Edit that note's ProseMirror JSON. Do not round-trip through Markdown. Markdown save drops marks, math, tables, and media.

If the same request also asks to clear dead links, load the dead-link skill and apply that cleanup in the same document before save. Do not expand a card URL to the rest of the whiteboard. If the user says the whole whiteboard, every card, or to spawn parallel subagents, use the board B2 rewrite skill instead of this one.

## 1. Read the note to a file

1. Load the Heptabase CLI skill. Run `heptabase --version` before any read. Accept the range that skill pins. `0.9.x` is valid when that is what `--version` prints and the CLI skill allows it. Do not stop because this note once expected `0.8.x`. If the CLI cannot connect, follow that skill and stop when the user must enable CLI.
2. Parse the URL. Do not open it in a browser. On `https://app.heptabase.com/<whiteboardId>/card/<cardId>`, the card id is the last UUID before the query string. Drop `_agentLine`, `pdfPage`, and `playbackStart`.
3. `mkdir` the real scratch directory first, then redirect. `@runtime` is a file-tool alias, not a shell path. `run_command` does not expand it, so `mkdir @runtime/tmp/...` creates a literal `<workspace>/@runtime` folder and never reaches `~/.cometmind`.

```bash
mkdir -p "$HOME/.cometmind/agent-tmp/hb-note-translate"
heptabase note read <cardId> > "$HOME/.cometmind/agent-tmp/hb-note-translate/note.json"
```

A redirect to a missing directory fails before the CLI runs. If you already redirected into a missing path, create the directory and read again. Do not treat the shell error as "card not found". File tools may read the same file as `@runtime/tmp/hb-note-translate/note.json`. That alias maps to `agent-tmp`, not `~/.cometmind/tmp`.

4. `json.loads` the file. Keep `contentMd5`. `content` is a JSON string. Parse it a second time into the document. If the card is not a note, stop.

## 2. Index every text node, including empties

Walk the document and print every `text` node with its index and marks. Empty strings are real nodes. A tree printer that truncates at 80 characters will hide the Chinese you still have to translate. Use `repr` so newlines inside a node stay visible.

Translate only `type: text` strings, plus the card title when it is in the source language. Leave these unchanged:

- `code` mark text, PromQL, Go identifiers, and other literals (`rate()`, `slice[0]`, `user_id`)
- `math_inline` / math source
- `href`, `src`, `fileId`, node `id`, color, and media `reference` attrs
- image, table, list, and heading structure

Proper nouns that are already in the target language stay as they are (`Prometheus`, `Grafana`, `Cache Line` when used as the term). Translate the surrounding prose. If the user asked for B2 rather than a literal translation, simplify wording in the same node without dropping numbers, thresholds, or conditions.

## 3. Match full node strings, then prove nothing is left

1. Build a map from each source text node to its translation. Match the full string, not a substring. The same English word can appear in several nodes with different surrounding punctuation.
2. Walk again. If the node is in the map, replace `text`. If it still contains source-language characters and was not intentionally kept, record the index and stop the save. A truncated first pass is the usual cause. Re-print from that index and add the missing keys.
3. Do not join nodes to translate, then split the translation back by guessing. Marks are per node. A `strong` word and the sentence around it are separate nodes. Translate each one so the mark still wraps the same idea.
4. Preserve leading and trailing spaces and newlines on the node that had them. The next node often starts flush. Dropping a trailing space glues `rate()` to the following word.

## 4. Save once, then verify the file

1. Read `references/card-content-schema.md` in the Heptabase CLI skill before the first save.
2. `note read` again. If `contentMd5` changed, rebuild the translation on the new document. Do not save over a newer edit.
3. Write the document JSON to a file under `$HOME/.cometmind/agent-tmp/hb-note-translate/`. Save with `heptabase note save <cardId> --content-md5 <contentMd5> --content-file <path>`. Pass that real path to the shell. Do not pass `@runtime/...`.
4. The CLI returns JSON whose `title` is the first heading, not a separate title field you must set. A translated H1 becomes the card title. Confirm that is intended. If the title stays in the source language, run `heptabase object rename --help` and rename only if that command exists.
5. Read the note back from a file. Confirm source-language characters are gone except kept terms, code, and math. Confirm internal `link` marks you meant to keep are still present, and dead-link marks you removed are gone. Confirm an unrelated external link in the same note is unchanged. Confirm highlight, color, and image counts did not drop.

Do not `note append`. Do not create a second card for the translation unless the user asks for a copy. Do not `card trash`. If save says the card is already trashed, stop. Do not restore it.

## 5. Report

Lead with the card URL, old title, new title, and that the body was saved in place. Say which node types were preserved. If dead links were removed in the same edit, report those separately under the dead-link skill's format. Do not claim a link was removed just because its label was translated.

## Pitfalls

- Redirecting CLI stdout before `mkdir` writes nothing and prints a shell error. The card may still exist. Create the directory, then read.
- A failed `note read` can print `{"error":"Card not found: ..."}` on stderr while the redirected stdout file stays empty. Read stderr before classifying a target as missing.
- `@runtime/tmp` in a shell redirect is a literal workspace directory, not `~/.cometmind/agent-tmp`. Never put the alias in `run_command`.
- Printing the joined note text hides node boundaries. Translation has to follow the node list, or marks land on the wrong words.
- A citation marker such as `[1]` is a text node with a `link` mark. Translating the card does not decide whether that link is dead. Use the dead-link skill for that decision.
- `card list -q <uuid>` can miss a live card. Existence for a link target still needs a successful read or a full paged list.
- Saving Markdown instead of the JSON file drops color, code marks, tables, and math. Always `--content-file` the document JSON.
- A copied `0.8.x` pin is stale when `heptabase --version` is `0.9.x` and the CLI skill allows that range. Trust `--version`, not the old sentence.