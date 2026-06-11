# DarasaDrive Mobile

Flutter mobile app for **DarasaDrive** — shares the same Supabase backend and M-Pesa API as the web app at `drivingacademydarasahub`.

## Architecture

```
lib/
├── core/           # config, theme, errors
├── domain/         # entities + repository interfaces
├── data/           # Supabase & HTTP implementations
└── presentation/   # Riverpod providers, go_router, screens
```

- **State:** Riverpod
- **Navigation:** go_router (bottom nav shell)
- **Backend:** Supabase (auth + Postgres RLS)
- **Payments:** `POST /api/public/mpesa/stk` on the published web app

## Setup

```bash
cd darasadrive_mobile
flutter pub get
flutter run
```

Supabase URL and anon key are in `lib/core/config/app_config.dart` (same publishable key as the web `.env`).

## Features

| Screen | Description |
|--------|-------------|
| Home | Quick actions + unlock CTA |
| Tests | 16 NTSA units, quiz runner, score tracking |
| Materials | PDFs/videos (RLS + free preview) |
| Booking | Search schools, multi-step booking |
| Profile | Account, bookings, M-Pesa unlock |
| Unlock | STK push + poll `profiles.has_paid` |

## M-Pesa checklist

- [ ] Web app published at stable URL (not preview)
- [ ] `MPESA_CALLBACK_URL` set on server
- [ ] Test: sign up → STK → `has_paid` → premium content
