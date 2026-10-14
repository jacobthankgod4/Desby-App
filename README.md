# Desby OS

Tailoring and fabric-commerce platform. Flutter app (web + mobile), Supabase
backend, Flutterwave payments, multi-carrier shipping.

Four role dashboards, each with its own navigation and quick actions: **tailor**,
**client**, **apprentice**, **fabric seller**.

---

## ⚠️ Read this before deploying anything

**This repository is public.** Two things must never be committed, and both have
been before:

- `supabase/config.toml` carried a **live Brevo SMTP password**. GitHub push
  protection blocked it; the config now uses `${BREVO_SMTP_USER}` /
  `${BREVO_SMTP_PASS}` and the key was rewritten out of history.
- `FEZ_DELIVERY_API.md` still contains a **live Fez Delivery secret key**.
  That key can book real, paid shipments. It is tracked, the repo is public,
  and it needs rotating.

See [docs/SECRETS.md](docs/SECRETS.md). If you find another one, rotate it
first and rewrite history second — deleting it from git does not un-expose it.

---

## Status: honest summary

| Area | State |
|---|---|
| Tests | 327 passing |
| Analyzer | 0 errors (250 pre-existing infos/warnings) |
| CI/CD | **none** — deploy is one hand-run script |
| Android release build | **signed with the debug key** — not Play-shippable |
| iOS build | no signing team, no App Store Connect config |
| Backend migrations | 37 files, **but 8 more SQL files sit outside `migrations/`** |
| Vimeo uploads | **broken** — hardcoded empty access token |
| Body scan | symbolic mannequin, not a real mesh |
| PDF / CSV export | buttons that display "coming soon" |

Do not assume a feature works because its screen renders. The "coming soon"
SnackBars are real and customer-visible.

---

## Stack

- **App** — Flutter, Riverpod, clean architecture (`presentation/` `domain/` `data/`)
- **Backend** — Supabase: Postgres + Auth + Storage + Edge Functions
- **Payments** — Flutterwave only. Any `Paystack*` class in the tree is dead code
- **Shipping** — Terminal Shipping (42 carriers) and Fez Logistics. Uber Direct is
  **not implemented**; the repository behind it is dead
- **AI** — ZOE chat with four-provider failover (Gemini, Groq, Mistral, DeepSeek),
  plus an external service for body measurement, EachLabs for try-on and Magic
  Hour for clothes swap

---

## Running it locally

```bash
cp .env.example .env      # then fill in from docs/SECRETS.md
flutter pub get
flutter run -d chrome
```

**There is no local build step for secrets.** Everything in `.env` is bundled as
a Flutter asset and read at runtime by `lib/config/environment.dart`. There is
exactly one `--dart-define` and it is a no-op: `ENV=production`, read by nothing.

`.env.example` declares 30 variables; the code reads **63**. Copying the example
untouched produces an app that cannot authenticate, pay, or chat.

### Database

```bash
supabase login
supabase link --project-ref <ref>
supabase db push
```

**There is no seed script.** A fresh database has zero reference data — no
Nigerian states or banks, no curriculum, no service catalogue. And eight SQL
files live outside `supabase/migrations/`, including
`supabase_schema_fix.sql`, which creates the base `public.users` table by
hand-paste. `supabase db push` against a blank project **will not reproduce
production**. See [docs/HANDOVER.md](docs/HANDOVER.md).

---

## Deploying

```bash
bash scripts/deploy_desby.sh
```

Builds Flutter web with `--base-href /app/`, backs up the live bundle, rsyncs to
`/var/www/desby/app`, fixes ownership, and verifies five URLs.

**The script is currently host-specific**: it hardcodes an SSH identity file at
an absolute path under one developer's home directory, and targets a host that
also runs unrelated production workloads. That shared host is the reason for the
migration described in [docs/HANDOVER.md](docs/HANDOVER.md).

---

## The documents that are actually worth reading

`opencode.json` lists four docs, but two of the most useful are not in it:

| Document | Why |
|---|---|
| [docs/HANDOVER.md](docs/HANDOVER.md) | Infrastructure inventory and the EC2 migration runbook |
| [docs/SECRETS.md](docs/SECRETS.md) | Secret handling. **Its claim that keys arrive via `--dart-define` is wrong** — see "Running it locally" |
| `AGENTS.md` | The most accurate document in the repo. Corrects several stale docs and records two hard-won traps |
| `ARCHITECTURE.md` | Layering and directory map |
| `CODING_STANDARDS.md` | Naming and structure |
| `LAUNCH_CHECKLIST.md` | Still mostly unchecked, and still accurate |

Roughly 130 other `.md` files sit at the repo root. Many are dated "Phase 3" and
no longer describe the code. `PROJECT_STATUS.md` claims *"Last Updated: May 5,
2024 — READY FOR IMPLEMENTATION"*; the app is in production. Treat anything not
listed above as unverified.

---

## Known traps recorded in `AGENTS.md`

- **`postgrest >= 2.9` removed `PostgrestResponse.error`.** Failed RPCs now throw
  `PostgrestException`. A check that tests `.error` silently passes on nothing.
  Guarded by `test/postgrest_no_error_field_test.dart`.
- **`orders.id` is a uuid; `orders.reference` is the human handle.** Mixing them
  produces queries that return no rows rather than an error.
- **dart2js mangles private members.** Symptom and debugging procedure are in
  `AGENTS.md`; do not spend hours rediscovering it.

---

## Tests

```bash
flutter test
```

No coverage threshold is enforced and there are no goldens. Two suites read the
real `.env` and behave differently depending on whether it contains live
credentials — see `HANDOVER.md`.