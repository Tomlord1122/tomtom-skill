---
name: ai-daily-digest
description: "Fetches RSS feeds from 90 top Hacker News blogs (curated by Karpathy), then uses the AI agent to score, filter, summarize, and generate a daily digest in Markdown with translated titles (Traditional Chinese or English), category grouping, trend highlights, and visual statistics (Mermaid charts + tag cloud). No external API key required. Use when user mentions 'daily digest', 'RSS digest', 'blog digest', 'AI blogs', 'tech news summary', or asks to run /digest command. Trigger command: /digest."
---

# AI Daily Digest

Fetches the latest articles from 90 popular tech blogs recommended by Karpathy, then the Agent (you) will score them, filter by quality, and generate a curated daily digest with summaries and trend analysis.

## Command

### `/digest`

Run the daily digest generator.

**Usage**: Type `/digest`, and follow the interactive guide to collect parameters, then the Agent will process everything.

---

## How It Works

**Two-Phase Architecture:**

1. **Phase 1 - Script (Fetch Only)**: `digest.ts` fetches RSS feeds, filters by time, outputs raw JSON
2. **Phase 2 - Agent (Intelligence)**: You (the Agent) score articles, summarize them, generate trends, build the Markdown report

**No external API keys needed** — everything uses the Agent's own intelligence.

---

## Script Directory

All scripts are in `scripts/` subdirectory.

| Script | Purpose |
|--------|---------|
| `scripts/digest.ts` | Fetch-only script - RSS fetching + time filtering → JSON output |

---

## Configuration Persistence

Configuration file path: `~/.tomtom-daily-digest/config.json`

**Agent must check** this file before execution:
1. If exists, ask user whether to reuse saved config
2. After execution, save current config to this file

**Configuration structure**:
```json
{
  "timeRange": 48,
  "topN": 15,
  "language": "zh-tw",
  "lastUsed": "2026-02-14T12:00:00Z"
}
```

Note: Language options are `zh-tw` (Traditional Chinese) or `en` (English) only.

---

## Interactive Flow

### Usage Notice

Output this notice at the beginning **every time** `/digest` is run:


### Step 0: Check Saved Configuration

```bash
cat ~/.tomtom-daily-digest/config.json 2>/dev/null || echo "NO_CONFIG"
```

If configuration exists, ask whether to reuse:

```
question({
  questions: [{
    header: "Use saved config",
    question: "A previously used configuration was detected:\n\n• Time range: ${config.timeRange} hours\n• Selection count: ${config.topN} articles\n• Output language: ${config.language === 'zh-tw' ? '繁體中文' : 'English'}\n\nPlease choose an action:",
    options: [
      { label: "Use last config and run (Recommended)", description: "Use all saved parameters and start immediately" },
      { label: "Reconfigure", description: "Configure all parameters from scratch" }
    ]
  }]
})
```

### Step 1: Collect Parameters

Use `question()` to collect all at once:

```
question({
  questions: [
    {
      header: "Time range",
      question: "How far back should articles be fetched?",
      options: [
        { label: "24 hours", description: "Last day only" },
        { label: "48 hours (Recommended)", description: "Last two days, broader coverage" },
        { label: "72 hours", description: "Last three days" },
        { label: "7 days", description: "Articles from the past week" }
      ]
    },
    {
      header: "Selection count",
      question: "How many articles to keep after AI filtering?",
      options: [
        { label: "10 articles", description: "Compact version" },
        { label: "15 articles (Recommended)", description: "Standard recommendation" },
        { label: "20 articles", description: "Extended version" }
      ]
    },
    {
      header: "Output language",
      question: "What language should the digest be in?",
      options: [
        { label: "繁體中文 (Recommended)", description: "Summaries translated to Traditional Chinese" },
        { label: "English", description: "Keep original English text" }
      ]
    }
  ]
})
```

### Step 2: Execute Fetch Script

Run the script to fetch articles and save JSON to a temp file:

```bash
SKILL_DIR="<path to this SKILL.md's directory>"
TEMP_JSON="/tmp/digest-articles-$(date +%s).json"

npx -y bun ${SKILL_DIR}/scripts/digest.ts \
  --hours <timeRange> \
  --output "$TEMP_JSON"
```

The script will output JSON like:
```json
{
  "metadata": {
    "totalFeeds": 90,
    "successfulFeeds": 85,
    "totalArticles": 450,
    "filteredArticles": 120,
    "timeRangeHours": 48,
    "fetchedAt": "2026-02-14T..."
  },
  "articles": [
    {
      "title": "...",
      "link": "...",
      "pubDate": "2026-02-14T...",
      "description": "...",
      "sourceName": "simonwillison.net",
      "sourceUrl": "https://..."
    }
  ]
}
```

### Step 3: Read and Parse JSON

Use the Read tool to load the JSON:

```
Read($TEMP_JSON)
```

Parse the JSON and extract the articles array.

### Step 4: Agent Scoring (You Do This)

**IMPORTANT**: You (the Agent) will now score all articles.

For each article, assign scores (1-10) on three dimensions:

#### Scoring Dimensions

**1. Relevance** - Value to tech/programming/AI/internet professionals
- 10: Major event/breakthrough everyone should know
- 7-9: Valuable to most tech practitioners
- 4-6: Valuable to specific tech domains
- 1-3: Low relevance to tech industry

**2. Quality** - Article depth and writing quality
- 10: Deep analysis, original insights, rich citations
- 7-9: Has depth, unique perspective
- 4-6: Accurate info, clear expression
- 1-3: Shallow or purely reposting

**3. Timeliness** - Whether worth reading now
- 10: Major ongoing event / just-released important tool
- 7-9: Related to recent hot topics
- 4-6: Evergreen content, not outdated
- 1-3: Outdated or no timeliness value

#### Category Assignment

Assign one category to each article:
- `ai-ml`: AI, machine learning, LLM, deep learning
- `security`: Security, privacy, vulnerabilities, encryption
- `engineering`: Software engineering, architecture, programming languages, system design
- `tools`: Dev tools, open source projects, newly released libraries/frameworks
- `opinion`: Industry opinions, personal reflections, career development, cultural commentary
- `other`: None of the above fit well

#### Keyword Extraction

Extract 2-4 keywords that best represent the article's topic (use English, short, like "Rust", "LLM", "database", "performance").

#### Processing Strategy

**If >50 articles**: Process in batches of 15-20 to avoid context overflow. Score batch 1, then batch 2, etc.

**If ≤50 articles**: Score all at once.

**Output format** (internal, keep in memory):
```
Article scores = [
  {
    index: 0,
    relevance: 8,
    quality: 7,
    timeliness: 9,
    category: "engineering",
    keywords: ["Rust", "compiler", "performance"],
    totalScore: 24
  },
  ...
]
```

### Step 5: Select Top N Articles

Sort all scored articles by `totalScore` (sum of relevance + quality + timeliness) descending.

Take the top N articles (based on user's selection: 10, 15, or 20).

### Step 6: Generate Summaries for Top Articles

For each of the top N articles, generate:

1. **Translated Title** (`titleTranslated`): 
   - If language is `zh-tw`: Translate the English title to natural Traditional Chinese (繁體中文)
   - If language is `en`: Keep the original English title
   - If original is already in the target language, keep unchanged

2. **Summary** (4-6 sentences): Structured summary that lets readers understand the core content without clicking. Include:
   - Core problem or topic the article discusses (1 sentence)
   - Key arguments, technical solutions, or findings (2-3 sentences)
   - Conclusion or author's core viewpoint (1 sentence)

3. **Recommendation Reason** (`reason`): One sentence explaining "why worth reading", distinct from summary (summary says "what", reason says "why").

**Language**: Use the language specified by user (`zh-tw` or `en`).

**Summary requirements**:
- Directly state key points, don't use openings like "This article discusses..." or "本文討論了..."
- Include specific technical terms, data, solution names, or viewpoints
- Preserve key numbers and metrics (like performance improvement percentages, user counts, version numbers, etc.)
- If article involves comparison/selection, point out comparison objects and conclusion
- Goal: Reader spends 30 seconds reading summary and can decide whether worth spending 10 minutes on original

**Output format** (internal):
```
Article summaries = [
  {
    index: 0,
    titleTranslated: "翻譯後的標題" or "Original Title",
    summary: "Summary content...",
    reason: "Recommendation reason..."
  },
  ...
]
```

### Step 7: Generate Today's Highlights

Based on the top 10 articles, write a 3-5 sentence "Today's Highlights" summary.

**Requirements**:
- Extract 2-3 main trends or topics in today's tech world
- Don't list article by article, do macro summarization
- Style: concise and powerful, like news lead
- Language: Use the language specified by user (`zh-tw` or `en`)

**Output**: Plain text string (not JSON, not markdown formatting).

### Step 8: Build Markdown Report

Generate a complete Markdown report with the following structure:

#### Report Structure

```markdown
# 📰 AI 部落格每日精選 — YYYY-MM-DD
(or "# 📰 AI Blog Daily Digest — YYYY-MM-DD" if language is en)

> 來自 Karpathy 推薦的 ${metadata.totalFeeds} 個頂級技術部落格，AI 精選 Top ${articles.length}
(or "> From ${metadata.totalFeeds} top tech blogs recommended by Karpathy, AI-selected Top ${articles.length}" if language is en)

## 📝 今日看點
(or "## 📝 Today's Highlights" if language is en)

${highlights}

---

## 🏆 今日必讀
(or "## 🏆 Today's Must-Read" if language is en)

${top 3 articles with medals 🥇🥈🥉, each showing:
  - Translated title (bold)
  - English title (link) — source · relative time · category emoji + label
  - Summary (blockquote)
  - Recommendation reason
  - Keywords
}

---

## 📊 數據概覽
(or "## 📊 Data Overview" if language is en)

| 掃描來源 | 抓取文章 | 時間範圍 | 精選 |
(or "| Scanned Sources | Fetched Articles | Time Range | Selected |" if language is en)
|:---:|:---:|:---:|:---:|
| ${successFeeds}/${totalFeeds} | ${totalArticles} → ${filteredArticles} | ${hours}h | **${selected} 篇** |
(or "**${selected} articles**" if language is en)

### 分類分佈
(or "### Category Distribution" if language is en)

${Mermaid pie chart showing category distribution}

### 高頻關鍵詞
(or "### Frequent Keywords" if language is en)

${Mermaid bar chart showing top 12 keywords}

<details>
<summary>📈 純文字關鍵詞圖（終端機友善）</summary>
(or "<summary>📈 Plain Text Keyword Chart (Terminal-Friendly)</summary>" if language is en)

${ASCII bar chart with █ and ░ characters}

</details>

### 🏷️ 話題標籤
(or "### 🏷️ Topic Tags" if language is en)

${Tag cloud: top 20 keywords, top 3 bold with counts}

---

## ${Category emoji} ${Category label}

${For each category group, list all articles:
  ### N. ${titleTranslated}
  
  [${title}](${link}) — **${sourceName}** · ${relative time} · ⭐ ${totalScore}/30
  
  > ${summary}
  
  🏷️ ${keywords}
  
  ---
}

${Repeat for all categories sorted by article count descending}


```

#### Helper Functions You Need

**Relative Time**:
- For `zh-tw`:
  - <60 min: "X 分鐘前"
  - <24 hours: "X 小時前"
  - <7 days: "X 天前"
  - ≥7 days: ISO date (YYYY-MM-DD)
- For `en`:
  - <60 min: "X minutes ago"
  - <24 hours: "X hours ago"
  - <7 days: "X days ago"
  - ≥7 days: ISO date (YYYY-MM-DD)

**Mermaid Pie Chart** (category distribution):
```mermaid
pie showData
    title "文章分類分佈" (or "Article Category Distribution" if en)
    "🤖 AI / ML" : ${count}
    "🔒 安全 / Security" : ${count}
    ...
```

**Mermaid Bar Chart** (top 12 keywords):
```mermaid
xychart-beta horizontal
    title "高頻關鍵詞" (or "Frequent Keywords" if en)
    x-axis ["keyword1", "keyword2", ...]
    y-axis "出現次數" 0 --> ${maxCount + 2} (or "Occurrences" if en)
    bar [count1, count2, ...]
```

**ASCII Bar Chart** (top 10 keywords, terminal-friendly):
```
keyword1  │ ████████████████████ 15
keyword2  │ ████████████░░░░░░░░ 12
...
```

**Tag Cloud** (top 20 keywords):
```
**keyword1**(15) · **keyword2**(12) · **keyword3**(10) · keyword4(8) · keyword5(7) · ...
```
(First 3 bold)

**Category Metadata**:
- For `zh-tw`:
  ```
  ai-ml       → 🤖 AI / ML
  security    → 🔒 安全
  engineering → ⚙️ 工程
  tools       → 🛠 工具 / 開源
  opinion     → 💡 觀點 / 雜談
  other       → 📝 其他
  ```
- For `en`:
  ```
  ai-ml       → 🤖 AI / ML
  security    → 🔒 Security
  engineering → ⚙️ Engineering
  tools       → 🛠 Tools / Open Source
  opinion     → 💡 Opinions / Miscellaneous
  other       → 📝 Other
  ```

### Step 9: Write Report to File

Save the Markdown report:

```bash
mkdir -p ./output
OUTPUT_FILE="./output/digest-$(date +%Y%m%d).md"

# Use Write tool to create the file
Write($OUTPUT_FILE, <markdown content>)
```

### Step 10: Save Configuration

Save the current parameters to config file:

```bash
mkdir -p ~/.tomtom-daily-digest
cat > ~/.tomtom-daily-digest/config.json << 'EOF'
{
  "timeRange": <hours>,
  "topN": <topN>,
  "language": "<zh-tw|en>",
  "lastUsed": "<ISO timestamp>"
}
EOF
```

### Step 11: Present Results to User

Show a summary:

For `zh-tw`:
```
✅ 每日精選已成功生成！

📁 報告：${outputPath}

📊 統計：
• 掃描 ${successFeeds}/${totalFeeds} 個來源
• 抓取 ${totalArticles} 篇文章
• 篩選至 ${filteredArticles} 篇近期文章
• 精選 ${selectedCount} 篇頂尖文章

🏆 今日前三名預覽：
1. ${titleTranslated1}
   ${summary1.slice(0, 80)}...

2. ${titleTranslated2}
   ${summary2.slice(0, 80)}...

3. ${titleTranslated3}
   ${summary3.slice(0, 80)}...
```

For `en`:
```
✅ Daily digest generated successfully!

📁 Report: ${outputPath}

📊 Stats:
• Scanned ${successFeeds}/${totalFeeds} sources
• Fetched ${totalArticles} articles
• Filtered to ${filteredArticles} recent articles
• Selected ${selectedCount} top articles

🏆 Today's Top 3 Preview:
1. ${titleTranslated1}
   ${summary1.slice(0, 80)}...

2. ${titleTranslated2}
   ${summary2.slice(0, 80)}...

3. ${titleTranslated3}
   ${summary3.slice(0, 80)}...
```

---

## Parameter Mapping

| Interactive Option | Script Parameter |
|--------------------|------------------|
| 24 hours | `--hours 24` |
| 48 hours | `--hours 48` |
| 72 hours | `--hours 72` |
| 7 days | `--hours 168` |
| 10 articles | N/A (agent filters to 10) |
| 15 articles | N/A (agent filters to 15) |
| 20 articles | N/A (agent filters to 20) |
| 繁體中文 | `zh-tw` (for agent processing) |
| English | `en` (for agent processing) |

---

## Environment Requirements

- `bun` runtime (auto-installed via `npx -y bun`)
- Network access (requires access to RSS sources)
- **No external API keys needed** - the Agent (you) handles all AI processing

---

## Information Sources

90 RSS feeds sourced from [Hacker News Popularity Contest 2025](https://refactoringenglish.com/tools/hn-popularity/), recommended by [Andrej Karpathy](https://x.com/karpathy).

Includes: simonwillison.net, paulgraham.com, overreacted.io, gwern.net, krebsonsecurity.com, antirez.com, daringfireball.net, and other top tech blogs.

The complete list is embedded in the script.

---

## Troubleshooting

### "No articles fetched"
Network connection issue or all RSS sources are down. Check internet connection.

### "No articles found in time range"
Try expanding the time range (e.g., from 24 hours to 48 hours).

### Script execution fails
Make sure `bun` is available (it's auto-installed via `npx` on first run).
