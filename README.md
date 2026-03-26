# TenderPro AI 🏗️

**Smart Tender Management for Kenyan Contractors & Suppliers**

TenderPro AI is a Flutter mobile app that lets contractors upload tender documents (PDF/DOCX/TXT) or paste text, then uses Claude AI to automatically extract a **Bill of Quantities (BOQ)** with realistic Kenyan market prices — saving hours of manual estimation work.

---

## Features

- **AI BOQ Extraction** — Upload a tender PDF or paste text; Claude parses every line item and suggests current Nairobi market unit rates (KES)
- **BOQ Editor** — Add, edit, delete, and reorder line items with live totals
- **Quotation Builder** — Applies configurable VAT (16%) and profit margin to produce a final quote
- **Project Management** — Save unlimited projects, track status (Draft → Active → Completed → Archived)
- **Dashboard** — At-a-glance stats: total projects, active tenders, pipeline value, win rate
- **PDF Export** — Generate and share professional quotation PDFs
- **Offline-first** — All data persisted locally with `shared_preferences`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.22 / Dart 3 |
| State management | Provider 6 |
| AI | Anthropic Claude (claude-sonnet-4) |
| Networking | `http` package |
| Persistence | `shared_preferences` |
| PDF | `pdf` + `path_provider` |
| Charts | `fl_chart` |
| Tables | `data_table_2` |
| Fonts | `google_fonts` (Plus Jakarta Sans) |

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.22 ([install guide](https://docs.flutter.dev/get-started/install))
- Dart SDK ≥ 3.0
- An [Anthropic API key](https://console.anthropic.com/)

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/tenderpro_ai.git
cd tenderpro_ai
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure your API key

**Option A — `env.dart` (local dev only, never commit):**

Edit `lib/config/env.dart` and replace `YOUR_ANTHROPIC_API_KEY`:

```dart
static const String anthropicApiKey = String.fromEnvironment(
  'ANTHROPIC_API_KEY',
  defaultValue: 'sk-ant-YOUR_REAL_KEY_HERE',
);
```

**Option B — `--dart-define` (recommended, CI-safe):**

```bash
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

### 4. Run the app

```bash
flutter run
```

---

## Project Structure

```
lib/
├── config/
│   └── env.dart              # API key & feature constants
├── models/
│   └── models.dart           # BoqItem, Quotation, Project, enums
├── providers/
│   └── app_provider.dart     # Central state + Claude API integration
├── screens/
│   ├── dashboard_screen.dart
│   ├── upload_tender_screen.dart
│   ├── boq_screen.dart
│   ├── quotation_screen.dart
│   └── projects_screen.dart
├── theme/
│   └── app_theme.dart        # Navy + Gold palette, typography
├── utils/
│   └── formatters.dart       # KES formatting, dates, number helpers
├── widgets/
│   └── common_widgets.dart   # StatCard, SectionHeader, EmptyState, etc.
└── main.dart                 # Entry point, AppShell (bottom nav)
```

---

## CI / CD

GitHub Actions workflows live in `.github/workflows/build.yml`:

| Job | Trigger | Output |
|---|---|---|
| Lint & Test | push / PR to main | Pass / fail |
| Android APK | push to main | `tenderpro-release.apk` artifact |
| iOS build | push to main | `tenderpro-ios.app` artifact |

### Required GitHub Secret

Add this in **Settings → Secrets → Actions**:

| Secret name | Value |
|---|---|
| `ANTHROPIC_API_KEY` | `sk-ant-...` |

---

## Environment Variables

| Variable | Used in | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | `lib/config/env.dart` | Anthropic API key for BOQ extraction |

Pass at build time:
```bash
flutter build apk --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit: `git commit -m 'feat: add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request against `main`

Please run `flutter analyze` and `flutter test` before submitting.

---

## Security

- **Never commit API keys.** `lib/config/env.dart`'s `defaultValue` is for local dev only — rotate your key if it gets pushed accidentally.
- The `.gitignore` excludes `**/secrets.dart` and `.env*` files.
- In production, inject the key via `--dart-define` or a secrets manager.

---

## License

MIT © 2025 TenderPro AI
