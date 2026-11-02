---
name: b2-english-writing
description: Write or edit English at CEFR B2 level while preserving technical accuracy. Use when the user asks for B2-level English, clear English for international readers, or simpler wording in technical documentation without losing meaning.
---

# B2 English Writing

Write clear, natural English for an independent English user. B2 is a practical target, not a promise of a certified reading level. Keep the reader's knowledge and the purpose of the document in mind.

## Thinking Process

### Step 1: Understand the reader and task

**Goal:** Match the writing to what readers need to know and do.

- Identify the audience, purpose, requested format, language, and constraints. Ask only when a missing detail would change the result.
- Decide whether the user wants a new document, a rewrite, or a style applied to part of a document. Preserve the requested outline and existing content unless asked to change it.
- For a technical document, identify the source of truth and its version. Check the current code, contracts, or primary material when the request depends on current behavior.

**Decision point:** You can explain who the reader is, what the document should help them do, and which source supports it.

### Step 2: Find the message before choosing words

**Goal:** Make the purpose clear before listing details.

- Start with the problem, who it affects, and what the system or proposal does about it.
- Organize information in the order readers need it: context, main flow, decisions, exceptions, then implementation or reference details. Adapt to the user's outline.
- Separate facts, recommendations, assumptions, and open questions. Do not present intended behavior as current implementation.

**Decision point:** Each section has a clear purpose and the reader can follow the main idea without already knowing the implementation.

### Step 3: Write simple, natural English

**Goal:** Reduce language difficulty without talking down to the reader.

- Prefer familiar, direct words: use “use” instead of “utilize”, “start” instead of “initiate”, and “help” instead of “facilitate” when the meaning stays the same.
- Prefer short or medium-length sentences with one main idea. Split long sentences when it improves clarity; vary length so the text remains natural.
- Use active voice when the actor is known: “The service stores the result.” Use passive voice when the actor is unknown or not important.
- Use clear subjects and transitions. Say who does what, when, and why. Avoid vague pronouns, stacked nouns, idioms, filler, and unnecessary formal words.
- Use short paragraphs and meaningful headings. Use lists or tables when they make flows, options, or responsibilities easier to scan. Do not force a format that conflicts with the user's request.

**Decision point:** A non-native English reader can follow the main point without decoding long or formal sentences.

### Step 4: Keep technical meaning exact

**Goal:** Make language simpler, not the system itself.

- Keep exact identifiers, API paths, field values, state names, thresholds, units, conditions, ordering, timeouts, and error behavior. Format identifiers as code where appropriate.
- Keep necessary technical terms such as Temporal, callback, and workflow. Briefly define a term or acronym at first use when the audience may not know it; do not replace it with an inaccurate everyday word.
- Keep important exceptions and uncertainty. If a fact is not verified, say so or leave it out. Distinguish code behavior from deployment configuration and observed production behavior.
- Link to source material where useful. If code and comments disagree, check the implementation and describe the difference when it matters.

**Decision point:** A technical reviewer can trace important claims to evidence and no condition has been lost in simplification.

### Step 5: Review with a before-and-after mindset

**Goal:** Check clarity and accuracy together.

Examples:

- Before: “The orchestration layer facilitates the asynchronous execution of downstream remediation operations.”
- After: “The service starts remediation and waits for the result.” Use this only if the source confirms both actions.
- Before: “In the event that confidence is insufficient, the aforementioned case is subsequently transitioned to the solution-ready state.”
- After: “If confidence is low, the service marks the case `solution_ready`.” Keep the exact condition and state from the source.
- Before: “The callback always resumes the workflow.”
- After: “The callback tries to signal the workflow. If the signal fails, the service may use the legacy path.” Use only when supported by the implementation.

**Review checklist:**
- [ ] The document follows the user's requested outline, audience, and scope.
- [ ] The opening explains the problem and purpose in plain English.
- [ ] Each flow has clear actors, sequence, decisions, and relevant exceptions.
- [ ] Technical names and exact behavior are preserved; unsupported claims are removed or marked uncertain.
- [ ] Jargon is explained when needed, without replacing precise terms with misleading ones.
- [ ] Sentences and paragraphs are easy to scan, but not unnaturally short or repetitive.
- [ ] Links, version references, and existing rich content are preserved when relevant.
- [ ] The result is B2-oriented, not claimed to be formally CEFR-certified.

### Step 6: Deliver and communicate

**Goal:** Give the user the requested artifact, not just writing advice.

- Write or update the requested file or page. For shared documents, follow the destination's editing rules and preserve unrelated content.
- Briefly report what changed, where it is, and the source version if current code was reviewed. Mention important limitations without overstating verification.
- If another requested house style applies, combine it with B2 wording; explicit user instructions take priority over this skill's defaults.

## Optional review aid

```bash
bash /mnt/skills/user/b2-english-writing/scripts/review-length.sh document.md
```

The script counts prose lines over 35 words, not sentences. It is a rough prompt for manual review, not a CEFR test or a rule that all long lines must be changed. Markdown can wrap several sentences on one line, so the count may not reflect sentence length.

## Installation

- **Claude Code:** `cp -r skills/b2-english-writing ~/.claude/skills/`
- **claude.ai:** Add `SKILL.md` to project knowledge or paste it into the conversation. The optional script requires a compatible execution environment.
