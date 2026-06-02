---
name: pr-writer
description: 'Write pull request titles and descriptions in Tom''s house style. Use when the user asks to create a PR, open a pull request, or write a PR description. Trigger phrases include "make a PR", "create a PR", "write a PR description", "open a pull request".'
---

# PR Writer

Writes pull request descriptions in the project's established style: short background prose, one paragraph per commit, a reference section. No bullet lists in the body. No em dashes. No AI-sounding filler.

## Thinking Process

### Step 1: Gather context

Before writing anything:
1. Run `git log --oneline <base>..<HEAD>` to list commits in this PR.
2. Run `git show <hash>` for each commit to understand what changed and why.
3. Check the base branch (ask the user if unclear).
4. Look up the Jira ticket or design doc URL if the user mentions one.

### Step 2: Draft the title

Format: `[base-branch] type: short description`

- `base-branch` is the target branch in square brackets, e.g. `[dev]`
- `type` follows conventional commits: `feat`, `fix`, `refactor`, `chore`, `docs`
- Description is lowercase, imperative, under 60 characters
- Include a Jira ticket if provided: `[dev] (CTCS-1234) feat: add AU retry logic`

### Step 3: Write the body

The body has three parts:

**## Background**

One or two sentences explaining why this PR exists. State the context or problem being solved. Do not describe what the code does line by line. Write in plain English. No bullet points. No em dashes.

**Per-commit paragraphs**

For each meaningful commit, write one paragraph:
- Start with the short commit hash as a hyperlink: `[abc1234](full-github-url-to-commit)`
- Follow with a plain sentence describing what the commit does and why.
- Skip pure chore commits (vendor updates, gitignore) unless they need explanation.
- Keep each paragraph to 1-3 sentences.

Format for the commit URL:
`https://github.com/<org>/<repo>/commit/<full-hash>`

**### Reference**

List relevant links: design doc, Jira ticket, related PRs. One item per line, as a markdown link. Omit this section if there are no references.

### Step 4: Check style

Before finalizing, verify:
- No em dashes (`—`). Replace with a comma, period, or rewrite the sentence.
- No phrases like "This PR introduces", "This commit implements", "In this PR we". Start sentences with the subject directly.
- No summary bullets at the top.
- No "Test plan" section unless the user asks for one.
- Language is direct and concise. If a sentence can be cut, cut it.

## Example Output

```
Title: [dev] (CTCS-4259) refactor: init go project and remove C++ code

## Background

This is the first PR about refactoring of the mail scan service. In this PR, we remove the legacy C++ code and init the go project with external dependency like `go-tmase`. Then we run `go mod vendor` to check in the package.

[0b5aa00](https://github.com/trend-ctcs/app-tlx-mail-scan-server/pull/9/commits/0b5aa00): We migrated the proto definitions from Library-MailScanService into this repository to centralize ownership. In the future we'll setup cicd or check in the client code in the codebase.

### Reference

[Design doc](https://trendmicro.atlassian.net/wiki/spaces/CTCS/pages/...)
```

## Rules Summary

| Rule | Detail |
|------|--------|
| Title format | `[base-branch] (ticket) type: description` |
| Body opener | `## Background` |
| Commit format | `[short-hash](url): one sentence why` |
| References | `### Reference` with markdown links |
| No em dashes | Use comma or period instead |
| No bullet lists | Prose only in Background and commit paragraphs |
| No AI filler | No "This PR introduces", no "In summary", no "Overall" |
| Length | Short. If it needs more than 3 commit paragraphs, the PR is probably too large |
