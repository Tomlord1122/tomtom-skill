---
name: split-mindset-into-skill-family
description: Turn a video, essay, or operating mindset into a small family of mutually exclusive agent skills instead of one essay skill. Use when the user wants mindset, principles, or a talk made into skills, a t- prefixed skill set, or co-located knowledge packs for the next agent. Do not use for a single procedure that already has one trigger and one artifact.
tags:
  - skills
  - authoring
  - knowledge
metadata:
  cometline:
    origin: self-improvement
---

# Split a mindset into a skill family

A mindset is not a skill. Write skills only for jobs that have a trigger and an artifact. Keep principles in a short contract. Do not collapse the family into one "write more docs and trust them" skill.

## 1. Split before drafting

1. Sort every idea from the source into three piles:
   - **Principle.** Explains why. No trigger, no artifact. Stays in the contract, not a skill body.
   - **Convention or schedule.** A layout rule or a cron job. A skill may enforce it later. Do not make the convention itself a skill, and do not build the scanner until the file format is stable.
   - **Procedure.** Has a moment it fires and a thing it hands back. This is the only pile that becomes a skill.
2. Merge sections of one artifact into one skill. A flowchart section and a scenario section are parts of the pack, not sibling skills, when another skill already draws diagrams.
3. Name the dangerous neighbor: an existing skill that does the adjacent job and would poison this one if copied. State the boundary in one sentence. Example: a reverse-engineering skill may infer Why so a human can understand; a handoff pack must not, because the next session will treat that guess as law.
4. Resolve the fork that every other skill hangs on before writing files. If the user has not answered it, pick the conservative rule, say you picked it, and leave it reversible.

## 2. Make triggers mutually exclusive

1. Each description states when to use the skill and when not to. The negative clause names the sibling that owns that job.
2. The user-facing flow is not the skill pipeline. If the user said they will just state a requirement, the skills are internal checkpoints. Do not make them call the sequence.
3. Separate bootstrap from the daily loop. Creating or completing the pack is not a step on every change. Running a gate on every typo trains the agent to invent decisions.
4. One skill owns questions. Siblings call it. They do not invent their own interview. A blocking question is one gap that would change this diff, one question per turn, with two concrete outcomes. "I don't know" becomes `unknown` plus the reversible path, not a second question.
5. Label claims. `attested` has a source. `inferred` describes the present and cannot allow or forbid. `unknown` is not a decision. Do not promote an inference because the code looks intentional.
6. Do not add a master skill to route the family. Selection uses each description. A router either fires on every task and becomes a ritual, or rarely fires and never routes. Sibling calls belong in the skill that needs them.

## 3. Draft the family without clobbering siblings

1. Write each skill with the draft writer, not a workspace file edit. Skill drafts live outside the workspace, so a path edit is rejected even when the absolute path is readable.
2. Include `name`, `description`, and real `tags` in the same frontmatter. The writer does not invent tags. System origin is not a filter tag. If the user asked for an origin flag, put it in `metadata.cometline.origin` and keep the real tags.
3. Expect a same-prefix sibling to be flagged as a similar name. That overlap is the family, not a duplicate. Do not merge them to satisfy the checker.
4. If a write is blocked, read that draft before retrying. A blocked call may already have landed. If the body is already complete, do not write it again.
5. A second blocked sibling is not proof the first write failed. Retry only the missing or incomplete name.
6. Same-name rewrite of a sibling still hits the similar-name check. `overwrite=true` alone does not pass it. When the user already asked to update that existing draft, and the overlap is a sibling with a different job, resend the full file with `overwrite=true` and `force=true` together. `force=true` acknowledges the overlap. It does not invent permission to create a near-duplicate or replace a draft the user did not ask to change.
7. Do not promote, and do not copy into a repo skill pack, until the user says the drafts are fine.

## 4. Copy a promoted family into a repo pack

1. Copy only after the user says the skills are promoted, or asks to add them to the pack. Read the promoted files, not the earlier drafts.
2. Match the pack's real layout, not its template if the two disagree. Look at a sibling directory that has no scripts. If instruction-only skills are a single `SKILL.md`, do not invent an empty `scripts/` directory or a zip.
3. Preserve frontmatter, including tags and origin. A trailing newline is fine. Do not treat a newline-only diff as a content mismatch.
4. Do not commit unless the user asks.

## Pitfalls

- One skill for the whole talk becomes "write markdown and trust it," which is the failure mode the source warned about.
- Putting bootstrap in the daily order makes the agent fill empty Why cells from code.
- Letting every sibling ask questions asks the same gap three times and breaks the user's normal flow.
- A master skill re-glues the family the descriptions already split.
- Treating a similar-name block as "write failed" and retrying the whole family creates duplicates or overwrites a finished sibling.
- Editing a draft by absolute path fails because the editor is workspace-scoped. Use the draft writer.
- `overwrite=true` without `force=true` still loses to a sibling similar-name block on a same-name rewrite.
- Naming the pack file the same as the repo's agent-operations file makes both get read for the wrong purpose.
- Following a pack template that requires scripts and zips produces fake packaging for instruction-only skills.