# Changelog

All notable changes to TenderPro AI are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [1.0.0] — 2025

### Added
- **Dashboard** — at-a-glance stats: total projects, active tenders, pipeline value, win rate
- **AI BOQ Extraction** — upload PDF/DOCX/TXT or paste text; Claude extracts every line item with Kenyan market unit rates (KES)
- **BOQ Editor** — add, edit, delete, reorder line items; live auto-calculated totals
- **Quotation Builder** — configurable VAT (16%) and profit margin; full quotation summary
- **PDF Export** — generate and share professional quotation PDFs
- **Project Management** — create, update, delete projects; status tracking (Draft → Active → Completed → Archived)
- **Offline-first persistence** — all data stored locally with `shared_preferences`
- **Deep Navy + Gold theme** — professional brand palette with Plus Jakarta Sans typography
- **Bottom navigation shell** — animated tab transitions between 5 screens
- **GitHub Actions CI/CD** — automated lint, test, APK, iOS, and web builds on every push to `main`
- **Flutter Web support** — PWA manifest, CanvasKit renderer, GitHub Pages auto-deploy
- **Secure API key management** — `--dart-define` injection; no keys in source control

### Tech Stack
- Flutter 3.22 / Dart 3
- Provider 6 (state management)
- Claude claude-sonnet-4 (AI extraction)
- `http`, `pdf`, `fl_chart`, `data_table_2`, `google_fonts`, `flutter_animate`
