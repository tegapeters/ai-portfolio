# Tega Eshareturi — AI / Data Science Portfolio

**Senior NES Global Improvement Engineer · Oracle NetSuite · Houston, TX**
MS Computer Information Systems, Data Science · University of Houston Clear Lake · 2025
OCI GenAI Professional · AI Foundations · 11+ Certifications

---

## Projects

| # | Project | Domain | Stack | Highlights |
|---|---------|--------|-------|------------|
| 01 | [Skin Cancer Detection](#01-skin-cancer-detection) | Computer Vision / Deep Learning | Python · TensorFlow · ResNet50 | 86.8% accuracy on benign/malignant classification |
| 02 | [Dallas Crime Prediction](#02-dallas-crime-prediction) | ML / Classification | Python · scikit-learn · Socrata API | 10-year dataset, 3 models, 2024 holdout evaluation |
| 03 | [LeadOps CRM](#03-leadops-crm) | AI-Powered Product | Python · Supabase · Next.js · Google Maps API | ~2,000 leads, AI engine, automated Keep-Alive agent |
| 04 | [VisionConnect](#04-visionconnect) | Spatial Computing / visionOS | Swift · RealityKit · GroupActivities (SharePlay) | Apple Vision Pro multiplayer spatial app — MS capstone |
| 05 | [Engineer On Air](#05-engineer-on-air) | AI + Web | Vanilla JS · Web Speech API | AI-voiced interactive podcast page |
| 06 | [ShutterMuse.Co Portal](#06-shuttermuse-portal) | AI-Assisted Web Build | HTML · CSS · Vanilla JS · Supabase | Photography client delivery portal built from a flyer |
| 07 | [Techturi](https://techturi.org) | Full-Stack Platform | Next.js · TypeScript · Vercel | Free tech education platform + web dev studio. 8 cert roadmaps, /book, /intake, Vercel Analytics. Live at techturi.org |
| 08 | [Job Bot](#08-job-bot) | AI Automation / Agentic | Python · Claude API · Supabase · Streamlit | End-to-end job application engine: multi-source scraping, Haiku scoring, Sonnet cover letters, Streamlit dashboard, MCP server |

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

## 05 Engineer On Air

**AI-voiced interactive podcast page — built to narrate Tega's career arc**

Single-page podcast player using the Web Speech API for browser-native TTS narration. Seven chapters, full progress bar, volume control, chapter-level seek.

Live: [engineer-on-air.vercel.app](https://engineer-on-air.vercel.app)

**Stack:** HTML · CSS · Vanilla JS · Web Speech API · Vercel
**[View source →](05-engineer-on-air/podcast.html)**

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

## 08 Job Bot

**AI-powered job application engine — scrape, score, cover letter, track, apply**

End-to-end pipeline that sources job listings from LinkedIn, Indeed, and Remotive, scores each one against a target resume using Claude AI, generates tailored cover letters for qualified matches, and surfaces everything in a Streamlit dashboard for review.

- Multi-source scraping with LinkedIn session-cookie auth, Indeed, and Remotive
- **Dual-model AI pipeline:** Claude Haiku for fast 1–10 resume-fit scoring (seniority, salary match, reason); Claude Sonnet for role-specific 3-paragraph cover letters
- Deduplication layer — already-scored jobs are never re-processed, preventing repeated API spend
- Supabase backend tracks full application lifecycle: `new → applied → interview → rejected`
- Streamlit dashboard with score distribution charts, filterable job table, and inline status updates
- MCP server exposes all tools so Claude can orchestrate the full workflow via natural language
- macOS LaunchAgent for daily automated scraping runs

**Stack:** Python · Anthropic SDK · Claude Haiku + Sonnet · Playwright · Supabase · Streamlit · MCP
**[View project overview →](08-job-bot/README.md)**

---

## Background

Tega's career spans defense (BAE Systems, Lockheed Martin), cybersecurity, and enterprise cloud (Oracle NetSuite). At Oracle he leads GenAI automation engineering — designing LLM pipelines for ticket QA, root cause analysis, and Jira-based incident management using OCI GenAI Services. His work sits at the intersection of ML systems engineering and enterprise product development.

**Contact:** techturi.org@gmail.com · Houston, TX · [LinkedIn](https://www.linkedin.com/in/tega-p-eshareturi-014002142/) · [techturi.org](https://techturi.org)
