# ShutterMuse.Co — Photography Client Portal

**AI-assisted full-stack web build for a Houston-based photography business**

A responsive client delivery portal built from a single brand flyer. The photographer uploads session photos through a password-protected portal; clients retrieve and download their photos by entering their name or session code — from any device, anywhere.

---

## What It Does

- **Photographer Portal** — password-protected upload interface with drag-and-drop, file preview, session management, and delete controls
- **Client Gallery** — clients enter their session name/code to view and download their photos individually or all at once
- **Cloud Storage** — photos stored in Supabase Storage so uploads and downloads work across different devices
- **Packages Page** — branded display of photography packages matching the business's existing flyer design

---

## Technical Highlights

- Built from a photo of a printed flyer — extracted brand colors, layout, and package details to produce a fully styled site
- Supabase Storage used as the backend — no server required, fully static deployment
- Responsive layout engineered for iPhone portrait use: touch-friendly overlays, 2-column gallery grid, stacked form inputs, tab navigation scaled to narrow screens, iOS zoom-on-focus prevention (`font-size: 1rem` on all inputs)
- Deployed to Netlify via drag-and-drop with zero config

---

## Stack

HTML · CSS · Vanilla JS · Supabase Storage · Netlify
