---
name: background-odds-from-local-sources
description: Estimate interview or hiring odds from the user's actual background, and collect public interview writeups when sites block fetches. Use when the user asks "what are my chances", "am I a fit", or to find interview experiences for a company/role.
metadata:
  cometline:
    origin: self-improvement
---

# Background odds from local sources

Do not invent a probability from memory hits or search snippets. Read the background artifact, then separate resume-screen odds from offer odds.

## 1. Load the background

1. `search_memories` for education, employer, years, and the target company or role.
2. Treat memory as a pointer, not the source. Open the resume the user already pointed at (`resume.md` before PDF/HTML).
3. If the resume path is unknown, ask. Do not reconstruct a résumé from memories.

## 2. Collect interview evidence

1. Search recent public writeups for that company and role, not the whole company.
2. `web_fetch` the pages you will cite. Prefer first-person timelines (blog, HackMD, PTT, GoodJob) over aggregator listicles.
3. If a site returns 403, do not retry the same URL. Keep the link, say it was blocked, and use mirrors or other primary pages.
4. Ignore pages that are a different function (equipment, process, IMC) unless the user asked for the company in general.
5. Label each source with date, role, and outcome. Department variance is the finding, not noise.

## 3. Answer the odds question

1. State what artifact you used.
2. Split the estimate: screen / hard gate (coding test, language, clearance) / interview / offer.
3. Name what the résumé helps, what it cannot predict, and the largest unknown.
4. Give a range, not a point estimate. Say the range collapses if the role family is wrong.
5. Do not coach the user to invent metrics, seniority, or open-source impact they do not have.

## Pitfalls

- Memory similarity is not a résumé. A job-search task outcome does not mean they applied to this company.
- A blocked Dcard/Glassdoor page is not evidence. Cite only pages whose text you actually read.
- School prestige does not clear a hard coding gate. Keep that gate as its own probability.
- Old process details (score cutoffs, retest limits, on-call rules) go stale. Date them and do not treat one post as the current rule.