# LeadOps CRM

AI-powered lead generation engine and CRM built for Houston-area small businesses. Identifies businesses with no web presence, scores them by opportunity value, and surfaces them in a sales dashboard with industry-specific battlecards.

Built as a real product with a three-tier pricing model. Not a demo.

## Architecture

```
Google Maps Places API
        │
        ▼
  Python Scraper
  (no-website filter)
        │
        ▼
Supabase (PostgreSQL)
  - Lead storage (~2,000 leads)
  - Deduplication
  - Proprietary scoring algorithm
  - Keep-Alive Agent (Vercel Cron)
        │
        ▼
Next.js Frontend (Vercel)
  - Lead dashboard
  - Industry battlecards
  - Tier-based access control
```

## Core Features

**Lead Discovery Engine**
- Queries Google Maps Places API by industry category and geographic radius
- Filters for businesses with no website or a low-quality web presence
- Deduplicates against existing pipeline
- **Dataset Scale:** Successfully ingested ~2,000 verified Houston-area leads.

**Supabase Keep-Alive Agent**
- Custom Vercel Cron agent implemented to prevent database pausing during development gaps.
- Executes automated queries every 72 hours to maintain persistent database connectivity.

**Lead Scoring Algorithm**
- Proprietary scoring model weighing: category competition density, review volume, business age signals, and contact availability
- Scores surfaced as a priority tier in the dashboard

**CRM Dashboard**
- Industry-specific battlecards (pitch talking points per vertical)
- Lead status tracking (new → contacted → closed)
- Three-tier pricing framework for end-user access

## Stack

| Layer | Technology |
|-------|-----------|
| Data collection | Python · Google Maps Places API |
| Database | Supabase · PostgreSQL |
| Backend logic | Python (scoring, deduplication) |
| Frontend | Next.js · Tailwind CSS |
| Deployment | Vercel |

## Business Context

Targets Houston-area SMBs across verticals — restaurants, contractors, service businesses — that lack a digital presence. The model assumes that business owners without websites are underserved prospects for both web services and digital outreach.

Live demo available upon request.

## What This Demonstrates

- End-to-end AI product architecture (not just a model, a full system)
- Production-grade data pipeline design
- API integration + database + frontend in a single deployable product
- Entrepreneurial application of enterprise-level data engineering skills
