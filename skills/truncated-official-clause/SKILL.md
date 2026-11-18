---
name: truncated-official-clause
description: Extract one operative clause from a long official regulation, gazette, or FAQ after web_fetch stops before that clause. Use when a statute or government Q&A starts in the tool result and ends before the deadline, limit, or numbered point you need, or when blogs invent a shorter SLA. Do not use for site chrome, HTTP 403, Big5 mojibake, or vendor docs that have a markdown mirror.
tags:
  - research
  - web
metadata:
  cometline:
    origin: self-improvement
---

# Read the clause the fetch cut off

`web_fetch` often returns the start of a long official page and stops before the numbered point that answers the question. That is a window limit, not an incomplete statute and not a nav-only page. Fetching the same URL again repeats the cutoff. Round-number summaries on SEO sites are not the rule.

## 1. Recognize a cut-off official read

Treat the fetch as unread for the clause you need when all of these are true:

1. The body is the real document: title, early articles, and readable Chinese or English, not a menu, login wall, or charset garbage.
2. The result ends, or is marked truncated, before the point you searched for (審查期限, 補正, 撥款, a numbered 點 or 條).
3. A second `web_fetch` of that URL ends in the same place.

Do not raise `max_chars` on that URL as the recovery. Do not quote a 7-day, 15-day, or 30-working-day figure from a blog that ranked for the question.

## 2. Search text you already have

Before another query, search the official FAQ or gazette text already returned for the question heading (多久, 期限, 審查結果). A long dump can contain the answer after the truncation point you assumed. If that sentence is present, stop and quote it.

## 3. Download the HTML and search the stripped text

Save the official URL, then strip tags. Do not open a PDF that comes back as a binary stream.

```bash
curl -fsSL -A "Mozilla/5.0" -o /tmp/official.html "https://example.gov/law"
python3 - << 'PY'
import re
from pathlib import Path
raw = Path("/tmp/official.html").read_text(errors="ignore")
raw = re.sub(r"<script[\s\S]*?</script>", " ", raw, flags=re.I)
raw = re.sub(r"<style[\s\S]*?</style>", " ", raw, flags=re.I)
text = re.sub(r"<br\s*/?>", "\n", raw, flags=re.I)
text = re.sub(r"</(p|div|tr|li|h\d)>", "\n", text, flags=re.I)
text = re.sub(r"<[^>]+>", "", text)
text = text.replace("&nbsp;", " ")
Path("/tmp/official.txt").write_text(text)
for key in ("審查", "補正", "工作日", "三個月"):
    print(key, text.count(key))
idx = text.find("完成審查")
print(text[max(0, idx-400): idx+800])
PY
```

Quote the sentence that states the limit, including any escape hatch such as 必要時得視實際情形延長. If the stripped text has no 工作日 figure, the answer is the month or day limit that is actually written. Do not keep searching until a shorter SLA appears.

## 4. Reconcile statute and official FAQ only after both are read

If the 作業規定 and the agency Q&A differ by a phrase (審查作業 versus 審查作業及核發核定函), report both wordings and which page each came from. A blog that collapses them into one round number is not a third source.

## Pitfalls

- `HTMLParser.feed` returns `None`. `"".join(Parser().feed(html) or "")` then `"".join(Parser().parts)` reads a new empty instance. Keep one parser and read its `parts`, or strip tags with regex as above.
- Re-fetching the same long URL does not move the window. Download once and search the file.
- A PDF fetch that is a `%PDF` stream is not text. Use the HTML law page you already saved.
- SEO pages titled 審核多久 often invent a working-day SLA the statute does not use. Prefer the numbered point in the official text.
- Several time limits live on one page (補正 7 日, 審查 3 個月, 核定函 1 個月, 撥款按月). Do not merge them into one "how long until the money arrives" figure.