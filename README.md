# Tega Eshareturi — AI / Data Science Portfolio

**Senior NES Global Improvement Engineer · Oracle NetSuite · Houston, TX**
MS Computer Information Systems, Data Science · University of Houston Clear Lake · 2025
OCI Data Science Professional · OCI GenAI Professional · AI Foundations · 12 Certifications

---

## Projects

| # | Project | Domain | Stack | Highlights |
|---|---------|--------|-------|------------|
| 01 | [Skin Cancer Detection](#01-skin-cancer-detection) | Computer Vision / Deep Learning | Python · TensorFlow · ResNet50 | 86.8% accuracy on benign/malignant classification |
| 02 | [Dallas Crime Prediction](#02-dallas-crime-prediction) | ML / Classification | Python · scikit-learn · Socrata API | 10-year dataset, 3 models, 2024 holdout evaluation |
| 03 | [LeadOps CRM](#03-leadops-crm) | AI-Powered Product | Python · Supabase · Next.js · Google Maps API | ~2,000 leads, AI engine, automated Keep-Alive agent |
| 04 | [VisionConnect](#04-visionconnect) | Spatial Computing / visionOS | Swift · RealityKit · GroupActivities (SharePlay) | Apple Vision Pro multiplayer spatial app — MS capstone |
| 06 | [ShutterMuse.Co Portal](#06-shuttermuse-portal) | AI-Assisted Web Build | HTML · CSS · Vanilla JS · Supabase | Photography client delivery portal built from a flyer |
| 07 | [Techturi](https://techturi.org) | Full-Stack Platform | Next.js · TypeScript · Vercel | Free tech education platform + web dev studio. 8 cert roadmaps, /book, /intake, Vercel Analytics. Live at techturi.org |
| 08 | [Job Pal](#08-job-pal) | AI Automation / Agentic | Python · Claude Sonnet · Supabase · Streamlit | Agentic job engine: parallel scraping, AI scoring + cover letters, Gmail rejection scanning, networking events — [live app](https://jobpal.streamlit.app) · [overview](https://job-pal-overview.vercel.app) |
| 09 | [Zillow SQL Prep](#09-zillow-sql-prep) | SQL / Interview Prep | PostgreSQL 16 · Python · Next.js · Claude Code | 50-question Zillow interview environment: 9-table schema, `zql` CLI tutor, auto-grader, Next.js UI — built to prep for a Senior BI role |

---

## 01 Skin Cancer Detection

**Deep learning binary classifier — benign vs. malignant skin lesion detection**

Transfer learning pipeline using a frozen ResNet50 backbone + custom dense layers, trained on the ISIC 2018 & 2024 dermatoscopy datasets.

- **Accuracy:** 86.8% · **Malignant Precision:** 71.6%
- Data augmentation (flip, rotation, zoom) + 80/20 train-val split
- Early stopping restores best weights; training stabilized without overfitting
- Designed for mobile health deployment (TensorFlow Lite pathway)

**Stack:** Python · TensorFlow/Keras · ResNet50 · AdamW · Matplotlib
**[View code →](01-skin-cancer-detection/training_code.py)** | **[Full report →](01-skin-cancer-detection/report.pdf)**

---

## 02 Dallas Crime Prediction

**Multi-class crime location classification using 10 years of Dallas PD open data**

Pulled 10,000+ records via the Socrata API (2014–2024), cleaned to 9,790, trained on 2014–2023 data, and evaluated against a 2024 holdout set.

- Compared Logistic Regression, KNN, and Random Forest
- AUC up to 0.7175 (Logistic Regression, all classes)
- Top-5 location filtering improved holdout accuracy to 42.1%
- 3-fold cross-validation throughout training

**Stack:** Python · scikit-learn · sodapy (Socrata API) · pandas · Matplotlib
**[View notebook →](02-dallas-crime-prediction/analysis.ipynb)** | **[Full report →](02-dallas-crime-prediction/report.pdf)**

---

## 03 LeadOps CRM

**AI-powered lead generation and CRM engine targeting Houston small businesses**

Three-layer architecture that identifies businesses without a web presence, scores them by opportunity value, and surfaces them in a clean sales dashboard.

- **Layer 1:** Python scraper using Google Maps Places API — identifies businesses with no website
- **Layer 2:** Supabase (PostgreSQL) — stores, deduplicates, and scores leads
- **Layer 3:** Next.js frontend — industry-specific battlecards, lead scoring display, 3-tier pricing

Built as a real product, not a demo. Proprietary lead scoring algorithm.
Live demo available upon request.

> **Early-stage caveat:** Google Maps and Google Search are not a 1-to-1 relationship. A business can appear in Maps with no website field populated, yet still have a web presence discoverable via search — and vice versa. The current scraping layer relies solely on the Places API `website` field, which means lead quality varies by industry and region. Improving precision requires cross-referencing Maps results against Search to validate true web absence. This is an active area of iteration.

**Stack:** Python · Google Maps Places API · Supabase · PostgreSQL · Next.js · Vercel
**[View project overview →](03-leadops-crm/README.md)**

---

## 04 VisionConnect

**Apple Vision Pro spatial multiplayer app — MS capstone project**

Collaborative spatial computing experience built for visionOS using RealityKit and Apple's GroupActivities framework (SharePlay). Two users share the same spatial environment in real time via FaceTime.

- Real-time multiplayer sync via SharePlay / GroupSessionMessenger
- Coordinate frame alignment between devices using ARKit world tracking
- 3D spatial chess board rendered in RealityKit with physics collision detection
- Full spatial environment: immersive road scene, ambient audio, collision HUD
- Role-based experience (roles assigned on entry, enforced throughout session)

**Stack:** Swift · visionOS · RealityKit · GroupActivities (SharePlay) · ARKit · Xcode
**[View source →](04-visionconnect/src/)**

---

## 06 ShutterMuse.Co Portal

**AI-assisted full-stack web build for a Houston-based photography business**

Built from a single photo of a printed flyer — extracted brand identity, layout, and package details to produce a complete, deployable client delivery portal. Iterated with real photographers to solve production upload problems.

- Password-protected photographer portal with drag-and-drop upload, session management, and one-click session delete
- RAW photo format support (CR2, CR3, NEF, ARW, DNG, ORF, and more) — full sensor data preserved for post-processing
- Parallel upload engine (4 concurrent uploads) with live progress counter — significantly reduces upload time for large RAW files
- Per-session upload limit with real-time limit bar and slot counter visible to the photographer
- Clients retrieve and download photos by name or session code from any device — no login required
- Supabase Storage backend — fully static site, zero server infrastructure
- Responsive layout engineered for iPhone portrait: touch-friendly gallery, 2-column grid, stacked inputs, iOS zoom prevention

**Stack:** HTML · CSS · Vanilla JS · Supabase Storage · Netlify
**Live:** [shuttermuseco.netlify.app](https://shuttermuseco.netlify.app)

---

## 08 Job Pal

**Agentic AI job search engine — scrape, score, apply, track, network**

End-to-end pipeline that sources job listings in parallel across 5 boards, scores each one against an uploaded resume using Claude Sonnet, generates tailored cover letters for qualified matches, and surfaces everything in a branded Streamlit dashboard. Deployed live as a beta SaaS product with multi-user auth.

- **Parallel 5-source scraping:** LinkedIn, Indeed, Remotive, We Work Remotely, Jobicy — deduplicated across all sources, runs concurrently
- **Resume upload:** PDF, DOCX, or TXT — text extracted via PyMuPDF and python-docx; full resume sent via prompt caching for token efficiency
- **Claude Sonnet pipeline:** 1–10 resume-fit scoring (seniority, salary match, one-line reason) + role-specific 3-paragraph cover letters for 8+ matches
- **Gmail rejection scanning:** IMAP-based scan auto-runs on Applied page load — surfaces rejection emails, matches to applied jobs, one-click mark as rejected
- **Networking events:** 3-source event scraper (Meetup RSS, Luma city JSON, AllEvents.in) → 95+ events/city; Interested/Attending tracking with status persistence across re-scrapes
- **Application lifecycle:** Review Queue → Applied → Interviews → Rejected — full tracking with response rate and pipeline timing
- **Pipeline timing:** Per-stage duration tracking; company research via DuckDuckGo enriches job context at scoring time
- Supabase multi-user backend — each user's resume, scores, and pipeline are fully isolated
- MCP server exposes all tools so Claude can orchestrate the full workflow via natural language

**Stack:** Python · Claude Sonnet · Supabase · Streamlit · PyMuPDF · imaplib · ddgs · Playwright · MCP
**Live:** [jobpal.streamlit.app](https://jobpal.streamlit.app) | **[Overview →](https://job-pal-overview.vercel.app)** | **[View repo →](https://github.com/tegapeters/job-bot)**

---

## 09 Zillow SQL Prep

**50-question SQL interview environment built for a Senior BI Analyst role at Zillow**

Local PostgreSQL 16 practice environment with a realistic 9-table Zillow schema (~50K synthetic events), a CLI tutor, an auto-grader, and a Next.js UI. Claude Code acts as the in-session tutor — no external API calls or costs.

- **9-table schema:** users, listings, events, sessions, agents, markets, subscriptions, lead_assignments, saved_searches — full join graph covering the Zillow data model
- **`zql` CLI:** `list`, `show`, `run`, `grade`, `solution`, `explain`, `sample` — full interview workflow from a single command
- **Auto-grader:** psycopg2 row-set comparison against reference SQL; handles ORDER BY-insensitive matching
- **50 questions across 5 categories:** funnel analysis, window functions, cohort retention, marketplace health, forecasting — weighted to actual interview frequency
- **Next.js 14 UI:** browse questions, run queries, view results and explanations in-browser
- Claude Code as LLM tutor: picks questions, explains mistakes, builds solutions on demand — operates entirely on local context

**Stack:** PostgreSQL 16 · Python · psycopg2 · Next.js 14 · Claude Code
**[View repo →](https://github.com/tegapeters/zillow-sql-prep)**

---

## Background

Tega's career spans defense (BAE Systems, Lockheed Martin), cybersecurity, and enterprise cloud (Oracle NetSuite). At Oracle he leads GenAI automation engineering — designing LLM pipelines for ticket QA, root cause analysis, and Jira-based incident management using OCI GenAI Services. His work sits at the intersection of ML systems engineering and enterprise product development.

**Contact:** techturi.org@gmail.com · Houston, TX · [LinkedIn](https://www.linkedin.com/in/tega-p-eshareturi-014002142/) · [techturi.org](https://techturi.org)
