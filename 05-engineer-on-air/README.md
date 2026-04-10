# Engineer On Air — Interactive Podcast Page

AI-voiced interactive podcast player built to narrate Tega Eshareturi's career arc across seven chapters — from BAE Systems to Oracle GenAI to the next frontier.

Live: [engineer-on-air.vercel.app](https://engineer-on-air.vercel.app)

## What It Does

A single HTML page that functions as a fully navigable podcast episode. Browser-native TTS (Web Speech API) reads each chapter's script aloud. The player includes:

- Play/pause/resume controls
- Real-time progress bar with seek-by-click
- Volume control
- Chapter-level navigation (click any chapter to jump)
- Animated waveform (pauses when audio pauses)
- Estimated elapsed and remaining time

## Chapters

| # | Title | Topic |
|---|-------|-------|
| 1 | The Origin Story | Texas Southern MIS, BAE Systems cybersecurity assessments |
| 2 | Lockheed Martin & The NextGen Awards | Defense finance, NSBE leadership, two NextGen Awards |
| 3 | Joining Oracle & Rising Through the Ranks | Oracle NetSuite, dashboard standardization, team leadership |
| 4 | Building GenAI at Oracle | OCI GenAI Services, LLM pipelines, incident management |
| 5 | The Side Hustle Stack | LeadOps CRM, web dev business, MMA app |
| 6 | The MS in Data Science | UHCL credential — not a pivot, fluency catching up to the field |
| 7 | The AI Obsession | Adjunct professor candidacy, enterprise AI product, scaling AI tools |

## Technical Notes

- Zero dependencies — no frameworks, no npm, no build step
- Web Speech API for TTS (works in Chrome, Edge, Safari)
- Voice selection: prefers Google US English or Microsoft natural voices
- Duration estimated at ~145 wpm; progress bar tracks proportionally across chapters
- Deployed on Vercel as a static file

## Stack

HTML · CSS · Vanilla JavaScript · Web Speech API · Vercel

## Files

- [`podcast.html`](podcast.html) — complete self-contained page
