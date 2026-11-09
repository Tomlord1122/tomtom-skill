---
name: delegated-skill-missing-primitive
description: Recover a procedure when an installed skill only tells you to load another skill that is not installed. Use when load_skill returns unknown skill, or the loaded SKILL.md body is only a one-line delegation such as "Call the Skill tool with X". Do not use for updating an already-installed skill, installing a family from a multi-skill repo, or authoring frontmatter.
tags:
  - skills
  - recovery
metadata:
  cometline:
    origin: self-improvement
---

# Follow a missing skill the stub names

Some installed skills are wrappers. Their whole body is "load this other skill." If that primitive is not installed, a successful load of the wrapper is not the procedure. Do not improvise it.

## 1. Confirm it is a delegation, not a short procedure

1. Load the skill the user named. Read the body, not only the description.
2. If the body is a real procedure, follow that. Stop.
3. If the body only names another skill (`Call the Skill tool with "<name>"`), load that name.
4. `unknown skill` means the primitive is absent. Check both `~/.cometmind/skills/<name>` and `~/.agents/skills/<name>` before assuming a second copy exists. A symlink is one copy.

## 2. Resolve the primitive from the same source as the stub

1. Read the stub's entry in `~/.agents/.skill-lock.json`. Use `source`, `sourceUrl`, and `skillPath`. Do not guess the GitHub repo from the skill text.
2. The primitive is usually in that same repo, under a different directory. Do not invent the folder (`engineering/` vs `productivity/`). A guessed raw URL 404s.
3. Search `site:github.com/<owner>/<repo> <primitive-name> SKILL.md`. Fetch the hit:

```text
https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<path-from-search>
```

4. If the upstream stub is also a one-liner, read the vendor's explainer page linked from search. It names the real skill path. Then fetch that SKILL.md. A blog summary of the technique is not a substitute for the skill text.
5. Follow the fetched primitive for this session. Do not rewrite the installed stub, and do not `write_skill` a copy of the upstream skill.

## 3. Say the primitive is missing, then interview or act from the fetched text

1. Tell the user the wrapper loaded and the named skill is not installed, in one sentence.
2. Run the fetched procedure. Decisions in that procedure stay with the user. Do not answer them because the wrapper failed to load.
3. Installing the primitive is a separate request. Use `skills-cli-update-installed` or `skills-cli-family-install` only if the user asks to install or update it.

## Pitfalls

- A loaded skill with a one-line body is not a license to invent the interview, checklist, or workflow it names. The missing primitive is the procedure.
- Guessing `skills/<category>/<name>/SKILL.md` before searching the lock's repo wastes a fetch. Search, then fetch the raw URL from the hit.
- Hand-copying the fetched SKILL.md into the local skills directory diverges from the lock. Follow it in session; install only when asked.
- An explainer page can describe the mechanism and still omit the question format or the confirmation gate. Fetch the SKILL.md before starting the session.