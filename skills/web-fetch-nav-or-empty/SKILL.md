---
name: web-fetch-nav-or-empty
description: Recover a web answer when web_fetch returns site navigation, an empty JS shell, HTTP 403, or a search URL instead of the article. Use when a news, review, ranking, or forum fetch is mostly menus and the fact you need never appears, or when a second fetch of the same URL repeats that failure. Do not use for Big5 or CP950 mojibake. Do not use when the empty page is an app whose source is in the workspace; use empty-page-production-api.
tags:
  - research
  - web
metadata:
  cometline:
    origin: self-improvement
---

# Switch sources when a fetch is nav or empty

`web_fetch` can return a 200 whose body is the site chrome, a near-empty JS shell, or an error page. That is not a partial read of the article. Calling the same URL again with a similar `max_chars` repeats the failure. Charset garbage is a different failure; use the CJK decode skill for that.

If the empty page belongs to an app whose frontend is in the workspace, this skill is the wrong next step. The rows are on the production API named in deploy config, not on Wikipedia. Use `empty-page-production-api`.

## 1. Recognize a non-read

Treat the fetch as unread when any of these is true:

1. The text is global nav: region pickers, Login, News, Newsfeed, convention lists, footer columns, and the headline you searched for never appears.
2. The body is a few lines, a login wall, or `${ keyword }` style template leftovers (common on forum and list sites).
3. The tool returns HTTP 403 or another hard error (ranking dashboards often do this).
4. A search backend returns only the search-engine URL, with no titles or snippets.
5. An arXiv HTML page starts (abstract, TOC, introduction) and the results section never appears before the truncation. That is a non-read of the numbers. Do not treat the abstract's claim as the results table.

Do not quote a review score, rank, hours-viewed figure, or plot point from that result. Do not raise `max_chars` on the same URL as the first retry unless you already saw the article start and it was cut mid-sentence. A long TOC plus introduction is not "cut mid-sentence"; switch pages or fetch the PDF.

## 2. Stop, then switch source class

1. Do not call `web_fetch` again on that URL.
2. Keep any DuckDuckGo or search snippet that already states the fact (title, date, rank, score). Snippets are leads. They are not a substitute for a page whose body you actually got, and they are not official wording.
3. `web_search` for a page that puts the fact in the first screen, then `web_fetch` that URL:
   - Production status, season count, "still airing": Wikipedia (or the equivalent encyclopedia) production section, plus the studio or distributor press release.
   - Scores and list size: a database stats page (MyAnimeList, AniList, or the field's equivalent), not a review column.
   - Dated commercial activity: a news reprint or press release whose article text appears before the site footer.
4. If the only pages that mention a chart are chrome-truncated, say the chart number was not recovered. Do not invent hours viewed, a weekly rank, or a "most watched" placement from a headline that does not contain the number.

## 3. Separate announcement from forecast

1. Search for an explicit completion or renewal commitment (`entire` / `until the end` / 完結 / 最後まで, or a named final season) on the encyclopedia production section and the press release.
2. A fan or SEO page that says the episode count or ending volume is 未発表, then offers 予想 / 本命, is evidence the plan is unannounced. Cite the unannounced fact. Do not promote the guess into the schedule.
3. Renewal cadence (next season announced only after the previous one ends) is the plan until a completion commitment exists. Pace math (volumes per cour, years at the current gap) is an estimate. Label it as one.
4. Database "members" or list size on a new season entry is a new page, not a time series of the previous season. A drop versus season 1 is not by itself a collapse. Compare score and scored-by, and say when the airing sample is still small.
5. A premiere-week chart mention is not current heat. Current heat needs a dated signal from this run: still airing, a recent collab or press cycle, or a fresh score sample. Attribute unnamed "industry writer says it ranked first" claims as reported, not as the platform's chart.

## 4. Compare forecasts only at the same cutoff

When a page gives accuracy numbers (Brier score, eve-of-event price, polling average):

1. Record the timestamp of the snapshot before citing it. An election-evening or post-close snapshot is not a pre-event forecast. A comment that asks "on what day?" means the writeup omitted the cutoff; do not fill that gap.
2. Do not mix an eve-of-event price from one page with a during-event score from another and call them one comparison.
3. A vendor scorecard's rounded prices (`~61¢`) are that page's figures. They are not the results table of a paper whose HTML never reached Results. Cite the abstract's qualitative claim only as the abstract, and say the numeric results were not in the fetch.
4. A 403 on a newspaper page means that article was not read. Do not infer its thesis from the headline.

## Pitfalls

- Retrying the chrome URL wastes the turn. The article, if it exists, is behind JS or after a nav block longer than `max_chars`. Switch pages.
- Search-fallback output that is only a Google URL is a failed search. Run another query or another backend; do not cite it.
- One page often mixes a confirmed broadcast date with a guessed episode count. Confirmed lines and forecast lines are not one fact.
- A 403 on a ranking site is not "the show has no ranking." It means that dashboard was not readable. Say so, and use a source you actually fetched.
- Fetching the same arXiv HTML URL again, even with a smaller `max_chars`, repeats the introduction. It does not reveal the results section.
---