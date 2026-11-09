---
name: vendor-docs-markdown-mirror
description: Recover truncated vendor documentation by fetching the markdown mirror or llms.txt index instead of re-fetching the HTML page. Use when web_fetch of official API, SDK, or protocol docs returns a docs-site shell, a "Responses are generated using AI" banner, or cuts off mid-section. Do not use for news, forums, or ranking pages that return only navigation.
tags:
  - research
  - web
metadata:
  cometline:
    origin: self-improvement
---

# Read vendor docs from the markdown mirror

Mintlify and similar docs sites render a long chrome shell before the article. `web_fetch` of the HTML URL often returns navigation, an AI-assistant banner, and a truncated body. Raising `max_chars` or fetching the same URL again repeats that failure. Many of these sites publish a plain-text mirror. Normative MUST/SHOULD text often lives only in the spec source, not in the overview.

## 1. Recognize a docs-shell read

Treat the fetch as incomplete when any of these is true:

1. The body opens with "Documentation Index", "Fetch the complete documentation index at: /llms.txt", or "Responses are generated using AI".
2. The article starts, then the tool result ends with `[truncated]` inside a section you still need (thresholds, request fields, response items, RFC 2119 requirements).
3. The page is mostly sidebar links (Specification, SDK, Changelog) and the mechanism you searched for never appears.

A search snippet that names the feature is a lead, not the spec. Do not quote thresholds, default flags, or field names from it.

## 2. Switch to the text mirror before searching again

1. Do not call `web_fetch` again on the HTML URL.
2. Append `.md` to the same path and fetch that. Official Claude and OpenAI docs both serve the article as markdown this way: `https://host/docs/.../page.md`.
3. If `.md` 404s, fetch the index named in the shell (`/llms.txt` or `/docs/llms.txt` on that host) and take the canonical page URL from there.
4. Prefer the vendor's own spec or API page over a blog that restates it. Use the blog only for host-specific defaults the spec does not define (CLI version, env var, activation threshold).
5. If the markdown mirror is also truncated, fetch the next section URL from its table of contents. Do not return to the HTML page.

## 3. If the normative body is still missing, fetch the spec source

An overview can name the feature and still never include the MUST/SHOULD lines. SDK TypeDoc, example hosts, and blog posts are not that text.

1. Do not fill requirements from TypeDoc optionality, an example sandbox string, or a third-party guide. Label those as unread-as-spec.
2. Search the vendor repo for the spec file, not a guessed path: `site:github.com/<org>/<repo> <feature> specification`. A guessed folder (`engineering/` vs `productivity/`, or `docs/` vs `specification/`) 404s.
3. Fetch the hit as raw text: `https://raw.githubusercontent.com/<org>/<repo>/<ref>/<path>`. Spec sources are often `specification/<date>/*.mdx`, not the published overview URL.
4. If that file truncates, fetch the next heading's raw URL or the draft path linked at the top of the file. Stop when the requirement lines you need have actually been read.
5. Keep protocol, host, and blog separate. A host capability that is optional in the type list is not a protocol MUST. A blog restatement is history, not the current requirement.

## 4. Separate protocol, host, and blog

When the user corrects the subject ("the protocol, not our product", or "how do these hosts do it"):

1. Read the current spec page first and state what the protocol actually requires.
2. Read each host's own docs for the client-side behavior. A third-party writeup is supporting color; label numbers you did not see on the vendor page.
3. Do not invent a protocol feature because a host implements it. If the spec's list endpoint still returns full schemas, deferred loading lives in the host, not the protocol.

## Pitfalls

- Re-fetching the HTML docs URL with a larger `max_chars` still pays for the shell first. The article you need is the `.md` mirror.
- A docs page that starts correctly and then truncates is still a non-read of the missing section. Do not fill thresholds or field names from memory.
- Blog posts often lag the default (tool search "on by default" vs "auto at 10%"). Cite the vendor page for the current default, and the blog only for history.
- An overview that explains the feature is not the requirement list. If MUST/SHOULD never appeared in the fetched text, you have not read the spec yet.
- SDK field optionality and example iframe flags are implementation notes. Quoting them as host requirements overstates what the spec requires.