---
name: recover-garbled-cjk-fetch
description: Recover Traditional Chinese pages when web_fetch returns Big5 or CP950 mojibake. Use when a .tw or other legacy CJK page is dense replacement characters or Latin-1 garbage while English and digits survive, or when a quoted Chinese rule must come from that page.
metadata:
  cometline:
    origin: self-improvement
---

# Recover garbled CJK fetches

`web_fetch` often decodes legacy Traditional Chinese pages as UTF-8 or Latin-1. The body looks like `���` / `�`, while ASCII survives. That is a charset miss, not an empty page and not a transient error. A second `web_fetch` of the same URL will garble the same way.

## 1. Recognize it

1. Dense replacement characters or CP1252 garbage, with intact English sentences, dates, phone numbers, and digits.
2. Common on older Taiwan PHP sites that declare `big5` / `cp950` or declare nothing.
3. Do not quote Chinese from the garbage, and do not guess the sentence from character shapes.

## 2. Harvest anchors, then find the right subpage

1. Copy every surviving English sentence, date, address, and number. These are leads only.
2. `web_search` the site plus the fact. DuckDuckGo titles and snippets are often already UTF-8 even when the origin page is Big5. Use them to find the notice or FAQ URL, not as the only citation.
3. If several numbers survive on one page (check-in cutoff, counter open, group, security), do not attach a digit to a rule until that clause is decoded.

## 3. Decode the raw bytes

Do this before stating a Chinese rule. Prefer Python; `iconv` from `big5` fails on some Taiwan vendor bytes.

```bash
python3 -c '
import urllib.request
url = "https://example.tw/page.php"
raw = urllib.request.urlopen(url, timeout=30).read()
text = None
for enc in ("cp950", "big5hkscs", "big5"):
    try:
        text = raw.decode(enc)
        break
    except UnicodeDecodeError:
        continue
if text is None:
    text = raw.decode("cp950", errors="replace")
print(text)
'
```

Fallback when iconv is enough:

```bash
curl -fsSL "https://example.tw/page.php" | iconv -f CP950 -t UTF-8
```

If the first encoding still has `�` in the clause you need, try the next encoding in that list. Do not stop at the first decode that merely prints something.

## 4. Cite only recovered text

1. Quote the rule from the decoded official page. Prefer a dated banner on that page over an older FAQ line and over a travel blog when they conflict.
2. If raw fetch or decode is unavailable, answer only where a surviving ASCII anchor and a UTF-8 snippet state the same rule. Say the official HTML was mis-decoded and you did not recover the surrounding Chinese.
3. Do not treat search-snippet Chinese as the official wording when the decoded page is available.

## Pitfalls

- Retrying `web_fetch` does not fix charset detection. Decode bytes, or use UTF-8 search text as a lead only.
- One page often has several time limits. A surviving `40` next to a surviving `60` is not one rule.
- Facebook and blog mirrors in search results lag the homepage banner. A dated English sentence on the official page beats an undated snippet.
- `iconv -f big5` drops or fails on CP950 extensions. Try `cp950`, then `big5hkscs`, then `big5`.
- Mojibake is not evidence you read the page. Unrecovered clauses stay unquoted.