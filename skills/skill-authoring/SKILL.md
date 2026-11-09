---
name: skill-authoring
description: Author or update an Agent Skill so optional frontmatter tags actually appear, and so a requested rename becomes a legal directory name. Use when writing SKILL.md, creating a skill, renaming a skill the user invokes with a slash, or explaining why a new skill has no filter tags.
metadata:
  cometline:
    origin: self-improvement
---

# Skill authoring

Skill writes persist the SKILL.md you supply. They do not invent optional frontmatter. `name` and `description` are required. `tags` is optional and only exists if the written file contains it.

The directory name and the frontmatter `name` must be the same legal identifier. A leading slash is how the user invokes a skill, not part of that name.

## 1. Confirm the write path before claiming auto-tags

1. Read the writer, not the UI filter. Check `WriteSkill` / `write_skill`, draft promotion, and any synthesis or review prompt that returns a full SKILL.md.
2. Required frontmatter is `name` and `description`. A missing `tags` field is valid and stays empty.
3. Do not treat discovery flags as tags. Symlink, read-only, pinned, origin, and curator status are computed from the file and registry. They are not written into frontmatter.

## 2. Put tags in the file you write

1. When the skill should be filterable, include tags in the same frontmatter block as name and description:

```yaml
---
name: example-skill
description: Short trigger-focused description.
tags:
  - go
  - architecture
---
```

2. Use short lowercase labels. The reader trims, drops blanks, and dedupes case-insensitively while keeping first-seen order.
3. Leave `tags` out when there is no real label. Do not add an `untagged` tag or an empty list to force a chip.
4. On overwrite, resend the tags you want to keep. A replacement SKILL.md that omits `tags` clears them.

## 3. Check the prompt, not only the schema

1. If a creator prompt shows a frontmatter example with only `name` and `description`, new skills from that path will not have tags. The example is the template.
2. Add `tags` to that example only when the authoring task is supposed to emit them. Do not expect the parser to fill them later.

## 4. Rename to a legal name, then drop the old copy

1. Strip a leading `/` from the name the user asked for. `/hb-orphan` is the invoke form; the directory and frontmatter `name` are `hb-orphan`. Keep other characters only if `ValidSkillName` accepts them: letters, digits, `-`, and `_`. Do not invent a longer name when the user already chose a short legal one.
2. See whether the old skill is a pending draft or an installed directory under `~/.cometmind/skills`. A draft list that says none does not mean the skill is missing. `list_dir` the installed path before treating the request as a draft rename.
3. Copy the existing procedure. Change only the frontmatter `name` to the new directory name. Mention the invoke form in `description` (`Invoke as /hb-orphan`) so the slash still triggers the skill. Keep tags and `metadata.cometline.origin`. Do not rewrite the procedure as part of a rename.
4. For an installed skill, copy the directory on disk, then edit the new `SKILL.md`. `write_skill` only creates or overwrites one name; it does not rename, and a near-copy of an installed skill is blocked as an overlap with no force flag. The file tool cannot edit `~/.cometmind`, so use the shell for the copy and the one-line name change. Delete the old directory only after the new file is on disk and its frontmatter `name` matches the directory.
5. For a pending draft, write the new name first. A similarity check will block a near-copy of the old draft. That block is correct: do not leave two drafts of the same procedure. Tell the user the overlap, then after they already asked for this rename, write the new name with the draft writer's force flag and delete the old draft directory. Do not promote from a rename alone. Promotion waits until the user has checked the skill's real side effect.
6. Search installed skills for the old name and update those cross-references the same way, one line at a time. Leave history and wiki pages alone.
7. Verify by reading the new frontmatter `name` and confirming the old directory is gone. A rename is not done while both names still exist.

## Pitfalls

- A skills page filter reads tags; it does not create them. An empty filter means the written files have no tags.
- System badge chips and frontmatter tag chips share a bar but come from different sources. Editing one does not populate the other.
- Requiring only name and description is intentional. Optional metadata stays absent until someone writes it.
- A slash in a requested skill name is an invoke prefix. Using it as a directory name fails, and dropping the slash without saying so makes the user think the skill was not renamed.
- An empty draft list is not proof the skill is a draft. Installed skills live in `~/.cometmind/skills`, and copying that directory is the rename. Writing a second copy through the skill writer hits the overlap guard, which has no force flag on the installed path.
- Creating the new copy while the old copy remains leaves a near-duplicate the next write will block again. Delete the old directory only after the new file is on disk.
- Force on a draft write skips the duplicate guard. Use it only when the user already asked to replace that overlapping draft, not to publish a second copy of the same procedure.