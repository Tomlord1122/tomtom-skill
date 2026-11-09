---
name: skill-from-completed-workflow
description: Reconstruct an agent skill from a completed workflow by reading the real artifact, not the memory summary. Use when the user asks to turn a past task, card, or output into a skill, or when a remembered procedure and the live artifact disagree. Do not use for splitting a talk or mindset into a skill family, or for frontmatter tags alone.
tags:
  - skills
  - authoring
metadata:
  cometline:
    origin: self-improvement
---

# Reconstruct a skill from a completed workflow

A memory of a past task is a lead. The artifact that task left behind is the spec. Draft a new procedure skill only after those two disagree or agree in writing.

This is not `split-mindset-into-skill-family`. That skill splits a talk into mutually exclusive jobs. This skill recovers one job that already has a trigger and an artifact. Tag rules stay in `skill-authoring`.

## 1. Name the neighbor before writing

1. Search installed skills and memories for the job the user named. Report the closest skill and what it does not do. Do not claim a skill exists because a related one almost fits.
2. If the user then says to turn that workflow into a skill, write a new skill. Do not extend the neighbor. A neighbor that organizes a board, maps citations, or lists orphans is a different job from maintaining one summary artifact.
3. Put the boundary in the description: when to use this skill, and when not to, naming the neighbor.
4. If the neighbor's origin is not self-improvement, do not overwrite it. Stop that write.

## 2. Read the artifact, then diff it against memory

1. Find the canonical output of the past run: the card, file, page, or command result the user still uses. A chat summary and a memory row are not that output.
2. Read it with the tool that owns the data. If the reader returns a structured document, save the full stdout to a file and parse that file. A truncated tool result drops the tail, and the tail is often the section you are about to specify.
3. List the artifact's real shape: heading levels, link targets, section order, what is grouped, and what is absent. Count sections from the parse, not from memory.
4. Diff that list against the memory summary before drafting. When they disagree, the artifact wins. Write down what you dropped. Typical drift: memory says "grouped by lesson" or "one section per source" when the file is a flat list; memory invents filler for empty cases the file simply omits.
5. Do not draft until that diff is done. A skill that says "match the existing card" and then copies the memory's grouping teaches the next session the wrong format.

## 3. Draft the procedure, not the incident

1. Steps in order. Include the commands and flags that actually returned the fields you used. Say where ids live in the JSON. Do not invent a reverse-lookup flag the help text does not have.
2. Search for an existing artifact before create. Reuse and replace it. Append-only updates duplicate the tail section.
3. A worked example may show shape. Do not hardcode that example's ids, dates, or board as required steps. The next run must resolve the target by title or by the user's link. Hardcoded ids update the wrong object.
4. Pitfalls are general rules plus why. "Truncated output drops the last section" is a rule. A session log is not.
5. Include `name`, `description`, and real `tags` in the same frontmatter. The writer does not invent tags. On overwrite, resend tags or they disappear.
6. Write a draft when the user asked for a skill but has not asked to install it. Do not promote until they say the draft is fine.
7. Use the draft writer. A workspace file edit is rejected for skill drafts even when the absolute path is readable.

## Pitfalls

- Memory compresses structure. "Q&A at the bottom by lesson" can be a flat list under one heading. Copying the summary into the skill locks in the compression.
- Stopping at the first page or the truncated tool view makes a long artifact look short. The missing tail becomes a false "this section does not exist."
- Folding the new job into the neighbor poisons both triggers. The neighbor will start maintaining summaries, or the new skill will start rewiring the board.
- Putting one course's ids in the steps makes every later run edit that course.
- Promoting before the user reviews the artifact diff skips the only check that the procedure matches the file.
- `overwrite=true` on a skill whose origin is not self-improvement is not allowed. Similar name is not permission.