# AI Daily Digest

For details on how this skill was made, see ➡️ https://mp.weixin.qq.com/s/rkQ28KTZs5QeZqjwSCvR4Q

Fetches the latest articles from 90 top Hacker News tech blogs recommended by [Andrej Karpathy](https://x.com/karpathy), then uses the OpenCode Agent (Claude) to score, filter, and generate a structured daily curated digest.

![AI Daily Digest Overview](assets/overview.png)

> Sources from [Hacker News Popularity Contest 2025](https://refactoringenglish.com/tools/hn-popularity/), covering simonwillison.net, paulgraham.com, overreacted.io, gwern.net, krebsonsecurity.com, and more.

## Usage

Use as an OpenCode Skill — type `/digest` in the conversation to start the interactive guided flow:

```
/digest
```

The Agent will ask for the following:

| Parameter | Options | Default |
|-----------|---------|---------|
| Time range | 24h / 48h / 72h / 7 days | 48h |
| Selection count | 10 / 15 / 20 articles | 15 articles |
| Output language | 繁體中文 / English | 繁體中文 |

Configuration is automatically saved to `~/.tomtom-daily-digest/config.json` and can be reused with one click on subsequent runs.

### Direct Command Line Usage

```bash
npx -y bun scripts/digest.ts --hours 48 --output /tmp/articles.json
```

This only fetches and filters articles. The Agent then handles scoring, summarization, and report generation.

## Features

### Two-Phase Processing Pipeline

```
Phase 1 (Script): RSS Fetching → Time Filtering → JSON Output
Phase 2 (Agent):  AI Scoring → Summarization → Trend Analysis → Markdown Report
```

**Phase 1 - Fetch Script:**
1. **RSS Fetching** — Concurrent fetching from 90 sources (10 concurrent connections, 15s timeout), compatible with RSS 2.0 and Atom formats
2. **Time Filtering** — Filters recent articles by the specified time window
3. **JSON Output** — Outputs structured JSON with metadata and article list

**Phase 2 - Agent Processing:**
4. **AI Scoring** — Agent scores articles on three dimensions: relevance, quality, and timeliness (1-10), while performing classification and keyword extraction
5. **AI Summarization** — Generates structured summaries (4-6 sentences) for the Top N articles, with translated titles (Traditional Chinese or English) and recommendation reasons
6. **Trend Summary** — Agent identifies 2-3 macro trends in the tech world for the day
7. **Markdown Report** — Builds complete digest with visualizations and categorized article lists

### Digest Structure

The generated Markdown file contains the following sections:

| Section | Content |
|---------|---------|
| 📝 Today's Highlights | 3-5 sentence macro trend summary |
| 🏆 Today's Must-Read | Top 3 in-depth showcase: bilingual titles, summaries, recommendation reasons, keywords |
| 📊 Data Overview | Statistics table + Mermaid pie chart (category distribution) + Mermaid bar chart (frequent keywords) + ASCII plain text chart + topic tag cloud |
| Categorized Article List | Grouped by 6 categories, each article includes translated title, source, relative time, score, summary, keywords |

### Six-Category System

| Category | Coverage |
|----------|----------|
| 🤖 AI / ML | AI, machine learning, LLM, deep learning |
| 🔒 Security | Security, privacy, vulnerabilities, encryption |
| ⚙️ Engineering | Software engineering, architecture, programming languages, system design |
| 🛠 Tools / Open Source | Dev tools, open source projects, newly released libraries/frameworks |
| 💡 Opinions / Miscellaneous | Industry opinions, personal reflections, career development |
| 📝 Other | Content not fitting the above categories |

## Highlights

- **Zero External Dependencies** — No Gemini API or other external API keys needed; the Agent handles all AI processing using its own intelligence
- **Bilingual Support** — Traditional Chinese (繁體中文) or English summaries and titles
- **Structured Summaries** — Not just a one-liner, but 4-6 sentences covering core problem → key arguments → conclusions, enabling a 30-second assessment of whether an article is worth reading
- **Visual Statistics** — Mermaid charts (native rendering on GitHub/Obsidian) + ASCII bar charts (terminal-friendly) + tag cloud, covering all reading scenarios with three visualization methods
- **Smart Classification** — AI automatically categorizes articles into 6 categories; browsing by category is far more efficient than a flat list
- **Trend Insights** — Not just an article list, but also identifies macro trends in the tech world for the day, helping you see the big picture
- **Configuration Memory** — Preference parameters are automatically persisted to `~/.tomtom-daily-digest/config.json`; daily use is a one-click operation

## Environment Requirements

- [Bun](https://bun.sh) runtime (auto-installed via `npx -y bun`)
- OpenCode with Claude agent (you're already using it!)
- Network connection

## Information Sources

90 RSS feeds curated from the most popular independent tech blogs in the Hacker News community, including but not limited to:

> Simon Willison · Paul Graham · Dan Abramov · Gwern · Krebs on Security · Antirez · John Gruber · Troy Hunt · Mitchell Hashimoto · Steve Blank · Eli Bendersky · Fabien Sanglard ...

The complete list is embedded in `scripts/digest.ts`.

## How Is This Different?

**Original Version** (v1):
- Required Gemini API key
- Script did all AI work (scoring, summarization, trends)
- User had to manage API keys and quotas

**This Version** (v2):
- No external API keys needed
- Script only fetches RSS feeds
- Agent (Claude in OpenCode) handles all AI work
- Simpler setup, leverages the AI you're already using

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ User triggers /digest command                       │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ Agent collects parameters via interactive questions │
│ • Time range (24h / 48h / 72h / 7d)                │
│ • Selection count (10 / 15 / 20)                   │
│ • Language (繁體中文 / English)                     │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ Phase 1: Run digest.ts script                       │
│ • Fetches 90 RSS feeds concurrently                 │
│ • Filters by time range                             │
│ • Outputs JSON to /tmp/articles.json                │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ Phase 2: Agent AI Processing                        │
│ • Reads JSON file                                   │
│ • Scores articles (relevance, quality, timeliness)  │
│ • Classifies into 6 categories                      │
│ • Extracts keywords                                 │
│ • Selects top N by score                            │
│ • Generates summaries + translations                │
│ • Identifies macro trends                           │
│ • Builds Markdown report with visualizations        │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ Output                                              │
│ • Saves to ./output/digest-YYYYMMDD.md              │
│ • Saves config to ~/.tomtom-daily-digest/config.json│
│ • Shows preview of top 3 articles to user           │
└─────────────────────────────────────────────────────┘
```
