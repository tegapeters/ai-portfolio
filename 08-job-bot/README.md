# Job Bot — AI-Powered Job Application Engine

**Automated job search pipeline: scrape → score → cover letter → track → apply**

End-to-end job application system that sources listings from multiple job boards, scores each one against a target resume using Claude AI, generates tailored cover letters, and surfaces qualified jobs in a Streamlit dashboard for review and one-click status tracking.

---

## Architecture

```
LinkedIn · Indeed · Remotive
         │
         ▼
    Scraper Layer
    (Python · Playwright · BeautifulSoup)
         │
         ▼
  Claude Sonnet Scorer
  - Resume-fit score 1–10
  - Seniority classification
  - Salary match detection
         │
    Score ≥ 7?
    /         \
  Yes          No → saved to skip list (never re-scored)
   │
   ▼
Claude Sonnet Cover Letter
  - Role-specific, 3 paragraphs
  - Pulls most relevant experience per posting
         │
         ▼
  Supabase (PostgreSQL)
  - Full application tracking
  - Status lifecycle: new → applied → interview → rejected
         │
         ▼
  Streamlit Dashboard
  - Dashboard · Review Queue · All Applications · Run Pipeline
```

---

## Features

- **Multi-source scraping** — LinkedIn public job search, Indeed, Remotive
- **AI pipeline** — Claude Sonnet for scoring and cover letter generation
- **Deduplication** — jobs already scored are never re-processed (no wasted API calls)
- **Streamlit UI** — score distribution charts, filterable job table, inline status updates, one-click pipeline trigger
- **MCP server** — exposes all tools so Claude can orchestrate the full workflow via natural language
- **LaunchAgent scheduling** — macOS-native daily automation (no cron reliability issues)

---

## Stack

Python · Anthropic SDK (Claude Sonnet) · Playwright · Supabase · Streamlit · MCP

---

## Key Files

| File | Purpose |
|------|---------|
| `agent.py` | Claude scoring + cover letter generation |
| `scrapers/` | LinkedIn, Indeed, Remotive scrapers |
| `tracker.py` | Supabase read/write layer |
| `ui.py` | Streamlit dashboard |
| `mcp_server.py` | MCP tool server for Claude orchestration |
| `main.py` | CLI entry point |
