# Desby — Operations Handover

> **Audience:** whoever operates this product next, human or AI.
> **Read this first:** the product is one Flutter codebase, but running it in production touches **eleven** distinct systems across four vendors, three deployment targets, and two operating systems. Almost nothing is automatic. The order of operations matters more than any individual step.
>
> **How to use this document.** Sections 1–4 are orientation; read them once, in order, before touching anything. Sections 5–14 are procedures; each one is self-contained but assumes you have the orientation. Section 15 is the dependency graph, Section 16 is the troubleshooting index, and Section 17 is the "if you only remember five things" page.
>
> **A warning about this document's length.** This is long on purpose. The previous handover was short and that was the problem: it omitted ordering constraints, and anyone following it literally would have caused an outage within a week. Every "gotcha" below represents a real thing that has actually gone wrong. **Do not skim it.** If you are an AI agent, read Section 15 (dependency graph) and Section 17 (top five) before acting on anything, then read the specific procedure in full.

---

## Table of contents

| # | Section | What it covers |
|---|---------|----------------|
| 1 | [What Desby is](#1-what-desby-is) | Product shape in one page |
| 2 | [Repository layout](#2-repository-layout) | Where code lives, what to ignore |
| 3 | [The eleven systems](#3-the-eleven-systems) | Every platform, and why it exists |
| 4 | [How a request actually flows](#4-how-a-request-actually-flows) | End-to-end traces through the stack |
| 5 | [Prerequisites and first-time setup](#5-prerequisites-and-first-time-setup) | Toolchain install |
| 6 | [Secrets and configuration](#6-secrets-and-configuration) | Every credential, and where it lives |
| 7 | [Running locally](#7-running-locally) | Full local stack |
| 8 | [Testing](#8-testing) | 43 Dart tests + integration checks |
| 9 | [Deploying the web app](#9-deploying-the-web-app) | Flutter web → nginx |
| 10 | [The server](#10-the-server) | EC2 operations without collateral damage |
| 11 | [nginx and TLS](#11-nginx-and-tls) | Routing, caching, certificates |
| 12 | [The API dependency](#12-the-api-dependency) | The container Desby depends on |
| 13 | [Store builds (iOS / Android)](#13-store-builds-ios--android) | Signing, provisioning, release |
| 14 | [Incident playbooks](#14-incident-playbooks) | What to do when things break |
| 15 | [Dependency graph](#15-dependency-graph) | Read this before any change |
| 16 | [Troubleshooting index](#16-troubleshooting-index) | Symptom → section |
| 17 | [If you only remember five things](#17-if-you-only-remember-five-things) | The compressed version |

---

## 1. What Desby is

Desby is a **Flutter** application for tailoring businesses in Nigeria. One codebase compiles to three targets:

| Target | Audience | Distribution |
|--------|----------|--------------|
| **Web (PWA)** | Tailors, clients, apprentices, fabric sellers | `https://desby.app/app/` — served from nginx |
| **iOS** | Business owners | Apple App Store |
| **Android** | Business owners | Google Play |

The four user roles each see a different dashboard:

| Role | Primary job | Sees |
|------|-------------|------|
| **Tailor** | Take measurements, manage clients, produce patterns | Clients, measurements, orders |
| **Client** | Submit / review measurements, order fabric | Own measurements, orders |
| **Apprentice** | Learn, assist a tailor | Limited client view |
| **Fabric seller** | List and sell fabric | Inventory, orders |

### 1.1 The single most important thing to understand

**Desby does not own its production backend.** The Flutter app is the entire Desby codebase, but at runtime it depends on:

- A **Supabase project** (database, auth, realtime, file storage)
- A **shared Docker container** on the same server, owned and maintained by a *different* product team (referred to throughout as `BACKEND_API`)
- A **payments gateway** (Flutterwave)
- A **shipping/logistics API** (Fez)
- A **transactional email provider** (Brevo)

Desby is a *client* of these systems, not the owner of most of them. This single fact explains most of the complexity in this document: you cannot fix most production problems from inside the Desby repository.

> ### ⚠️ The single most dangerous operational fact
>
> **`BACKEND_API` and several other services on the server belong to other products.** They share a CPU, a disk, an nginx instance, and a TLS certificate store. A command that "looks harmless" — a `docker restart`, a `systemctl restart nginx`, a broad `rm -rf /var/www/*`, a disk cleanup — can take down a product you have never heard of. **Never restart a service you have not first confirmed belongs to Desby.** See Section 10.3.

---

## 2. Repository layout

```
desby_app/
├── lib/
│   ├── core/                 # config, network, storage, providers, services
│   │   ├── config/           # environment config, Supabase keys
│   │   ├── network/          # API client, interceptors, endpoints
│   │   ├── providers/        # Riverpod state (theme, preferences)
│   │   ├── services/         # payments, notifications, device
│   │   └── widgets/          # shared UI primitives
│   ├── features/             # one folder per feature area
│   │   ├── clients/
│   │   ├── payments/
│   │   └── ...
│   ├── l10n/                 # localisation
│   └── main.dart
├── test/                     # 43 Dart test files
├── web/                      # Flutter web shell (index.html, manifest)
├── android/                  # Android project (Gradle)
├── ios/                      # iOS project (Xcode)
├── assets/                   # images, icons, bundled card art
├── scripts/                  # deploy_desby.sh, build_dashboard_cards.py
└── pubspec.yaml
```

### 2.1 Things that are NOT in this repository

| Thing | Where it actually lives |
|-------|--------------------------|
| nginx vhost | server: `/etc/nginx/sites-available/desby.app` |
| TLS certificate | server: `/etc/letsencrypt/live/desby.app` |
| Deployed web bundle | server: `/var/www/desby/app` |
| Landing page | server: `/var/www/desby/landing` + `desby-landing.service` |
| Payments proxy | server: `/opt/desby-proxy/server.js` |
| Database schema | Supabase dashboard, **not** version-controlled |
| API code | a **separate repository**, deployed as `BACKEND_API_CONTAINER` |

> **There is no migration history in this repository.** The database schema is managed by the owning team. If you need a schema change, you are not making it in this repo.

---

## 3. The eleven systems

Every one of these is required for a signed-in user to complete a single order.

| # | System | Role | Failure looks like |
|---|--------|------|--------------------|
| 1 | **GitHub** (public) | Source of truth | Cannot deploy |
| 2 | **Local macOS** | Build host | Cannot deploy |
| 3 | **Flutter SDK / Dart** | Compiler | Build fails |
| 4 | **AWS EC2** (t3.micro) | All server-side runtime | App is a white page |
| 5 | **nginx** | TLS termination + routing | App is unreachable |
| 6 | **Docker** (`BACKEND_API_CONTAINER`) | `BACKEND_API` | App loads, every API call fails |
| 7 | **Supabase** (Postgres + Auth + Realtime + Storage) | Data + identity | Cannot sign in |
| 8 | **Flutterwave** | Card / bank payments | Payment button does nothing |
| 9 | **Fez** | Shipping, delivery quotes | Shipping cost blank |
| 10 | **Brevo** | Transactional email | No verification email |
| 11 | **Let's Encrypt / certbot** | Certificate renewal | Site expires in ~90 days |

### 3.1 Which of these are shared with other products

This is the part that is easy to get wrong.

| System | Shared? | Consequence |
|--------|---------|-------------|
| AWS EC2 instance | **Yes** | Low CPU, high disk — shared |
| nginx | **Yes** | Reloading it affects every vhost |
| Docker daemon | **Yes** | Container names are global |
| `/etc/letsencrypt` | **Yes** | `certbot` renews all certs |
| `BACKEND_API` container | **Yes** | Owned by another team |
| `SIDE_SERVICE_A` / `SIDE_SERVICE_B` | **Yes** | Unrelated; never touch |
| `SIDE_SERVICE_C` | **Yes** | Unrelated; never touch |
| `desby.app` vhost | No | Yours |
| `desby-landing` / `desby-proxy` | No | Yours |
| `/var/www/desby` | No | Yours |
| The Desby repository | No | Yours |

**The instance also carries unrelated long-running services** (`SIDE_SERVICE_A`, `SIDE_SERVICE_B`, `SIDE_SERVICE_C`). They are not Desby's. They are listed here only so that you do not accidentally kill them while chasing a Desby problem.

---

## 4. How a request actually flows

### 4.1 Cold page load

```
User opens https://desby.app/app/
  │
  ├─ DNS: desby.app → 13.60.215.88 (static A record — you must update BOTH A and AAAA)
  │
  ├─ TLS: nginx presents /etc/letsencrypt/live/desby.app
  │
  ├─ nginx location ^~ /app/  → root /var/www/desby
  │     • index.html, main.dart.js, flutter_bootstrap.js → no-cache (see §11.3)
  │     • /app/assets/, /app/icons/                        → 30d cache
  │     • /app/canvaskit/                                   → 7d cache
  │     • everything else under /app/                       → SPA fallback
  │
  └─ Browser downloads ~40–60 MB of Flutter runtime on first visit
```

The Flutter runtime is large and cached per-browser, not per-CDN. A first-time visitor on mobile data waits.

### 4.2 Sign-in

```
Flutter app → Supabase Auth (email + password)
              → access token cached in flutter_secure_storage
Flutter app → BACKEND_API  POST /api/v2/auth/...     via nginx → 127.0.0.1:8080
```

Both must succeed. Supabase can issue a token while `BACKEND_API` refuses it — the app then behaves as if signed-in but every data call fails.

### 4.3 Reading data (clients, measurements)

```
Flutter → GET /api/v2/clients
   → nginx location /api/
   → rate limit zone=desby_api (30 req/s per IP, burst 20, 429 on exceed)
   → proxy_pass → 127.0.0.1:8080 (docker: BACKEND_API_CONTAINER)
   → Postgres (via BACKEND_API's own Supabase project, NOT Desby's)
```

> **Two databases.** Desby has a Supabase project (used for auth and some client-side storage). `BACKEND_API` has its own Postgres. They are different databases. A row created through one is invisible to the other.

### 4.4 Taking a payment

```
Flutter → Flutterwave (inline, via lib/core/services/flutterwave_service.dart)
  → success → Flutter → GET /api/v2/payments/verify → BACKEND_API
  → BACKEND_API calls Flutterwave to confirm before marking the order paid
```

There is a `desby-proxy.service` on the server (Node, `/opt/desby-proxy/server.js`) that talks to `https://api.flutterwave.com/v3/payments`. It exists to keep the Flutterwave secret server-side. **Do not move that secret into the Flutter app** — it is extractable from a compiled bundle.

> **Legacy naming trap.** The codebase still contains `paystack` references in `api_endpoints.dart`, `nigerian_banks.dart`, and `plan_registry.dart`. **Flutterwave is the live provider.** Those files are legacy naming, not a second integration. Editing them expecting them to change payment behaviour will waste a day.

### 4.5 Shipping quote

```
Flutter → Fez API → shipping options
```

If Fez is unreachable the app should degrade to "shipping unavailable" — it must not block checkout. See §14.7.

### 4.6 Email

```
Supabase Auth (or BACKEND_API) → Brevo → user inbox
```

Email is the account-recovery path. If Brevo is down, users who forget passwords are locked out.

---

## 5. Prerequisites and first-time setup

### 5.1 On your Mac

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | stable channel | `flutter --version` must match `.metadata` or the web bundle drifts |
| Dart | ships with Flutter | |
| Xcode | 15+ | macOS only; required for iOS builds |
| Android Studio | Ladybug+ | required for Android builds |
| rsync | any | used by `deploy_desby.sh` |
| SSH key | — | `~/Downloads/<key>.pem`, mode `600` |

```bash
flutter doctor
```

Expect warnings about Chrome and connected devices; you only need **Flutter** and **Xcode** green to build.

### 5.2 Access you must be granted

| Access | Needed for | Ask |
|--------|-----------|-----|
| GitHub write | Pushing code | Repo owner |
| SSH to the server | Deploys, log reading | Infrastructure |
| `sudo` on the server | nginx, certbot, `/var/www` | Infrastructure |
| Supabase project access | Config | Product owner |
| Flutterwave dashboard | Verify payments | Finance |
| Fez dashboard | Shipping | Operations |
| Brevo dashboard | Email | Marketing |
| Apple Developer | iOS signing | Product owner |
| Google Play Console | Android release | Product owner |

> **Nine separate grants.** There is no single "prod access" bundle. Expect this to take days, not hours.

### 5.3 Clone

```bash
git clone <repo-url> ~/desby_app
cd ~/desby_app
flutter pub get
```

### 5.4 Local configuration

Local config lives in `lib/core/config/`. It is **not** an `.env` file — see §6.4 for why that matters.

---

## 6. Secrets and configuration

### 6.1 Principles

1. **Never commit a secret.** The repository is public.
2. **Never put a server-side secret in the Flutter app.** Anything in `lib/` ships to every user's device in plaintext.
3. **Server-side secrets stay in `/etc/` or an environment file** with mode `600`, owned by `ubuntu`.
4. **Payment and email secrets never leave the server.**

### 6.2 Where each secret lives

| Secret | Held by | Location | Never in |
|--------|---------|----------|----------|
| Supabase anon key | Client + server | dart-define / nginx | — |
| Supabase service-role key | Server only | server env | `lib/` |
| `BACKEND_API` credentials | Server | `/etc/desby/` | `lib/` |
| Flutterwave secret key | Server | `/opt/desby-proxy/` | `lib/`, git |
| Fez delivery API key | Server + repo doc | `FEZ_DELIVERY_API.md` ⚠️ | public chat |
| Brevo API key | Server | server env | `lib/`, git |
| TLS private key | Server | `/etc/letsencrypt/` | anywhere |

### 6.3 ⚠️ Known exposure — Fez key

A live Fez delivery API key has been committed to a **public** document in the repository.

| Item | Detail |
|------|--------|
| File | `FEZ_DELIVERY_API.md` |
| Risk | Live third-party credential in a public repo |
| Immediate action | **Rotate in the Fez dashboard** |
| Then | Replace in every consumer, redeploy |
| Then | Purge from git history (Section 14.9) |
| Then | Add to secret scanning |

> **This is not theoretical.** A public repository is indexed within minutes. Rotation is the only fix that actually removes risk — git history rewrites do not un-publish anything already cloned or cached. Treat rotation as the priority, history purge as cleanup.

### 6.4 Configuration is not `.env`

Desby does **not** use a bundled `.env`. Configuration is compiled in via `--dart-define`:

```bash
flutter build web --release --dart-define=ENV=production
```

This has two consequences that regularly confuse people:

- **Changing config requires a rebuild and redeploy.** Editing a file on the server changes nothing.
- **The compiled values are public.** Treat anything you pass via `--dart-define` as visible to every user. Only pass public values (URLs, anon keys).

### 6.5 Rotating a credential

1. Generate the new credential in the provider's dashboard.
2. Update it **on the server** (`/etc/desby/…`), mode `600`, owner `ubuntu`.
3. Restart only the affected service (Section 10.3).
4. If the client needs it too, rebuild with `--dart-define`.
5. Revoke the old credential in the provider dashboard.
6. Confirm with a real end-to-end action (sign in, pay, ship).

Never skip step 5. A live credential you forgot to revoke is still live.

---

## 7. Running locally

### 7.1 Prerequisites

You need a reachable `BACKEND_API`. Two options.

| Option | How | Trade-off |
|--------|-----|-----------|
| **A. Tunnel to the server** | SSH reverse tunnel to `127.0.0.1:8080` | Real data, touches a shared host |
| **B. Point at production** | dart-define the production URL | Easy, **but you are writing to production** |

Option B is the default trap. Reads are fine; **any write mutates production.**

### 7.2 Tunnel (recommended)

```bash
# On your Mac — forwards local 8080 to the server's API container
ssh -i ~/Downloads/<key>.pem -R 8080:127.0.0.1:8080 ubuntu@<host>

# Then, in another terminal
cd ~/desby_app
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080 \
  --dart-define=ENV=development
```

Leave the tunnel open. If it drops, the app fails with network errors that look like a code bug. They are not.

### 7.3 Common local failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| `SocketException` on every call | Tunnel closed | Re-establish SSH |
| Works locally, 401 in production | Wrong dart-define | Compare §6.4 |
| Blank white page | `flutter run` not completed | Check browser console |
| Assets 404 | Wrong base href | See §9.2 |

---

## 8. Testing

### 8.1 Run the suite

```bash
cd ~/desby_app
flutter test
```

**43 test files.** They cover providers, theme, preferences, models, and widget logic.

They do **not** cover: networking against a real backend, payments, auth flows, or any store build. A fully green `flutter test` is necessary and **not sufficient**.

### 8.2 Manual verification matrix

Run this after any change that touches more than `lib/features/<one area>`.

| # | Check | How | Pass condition |
|---|-------|-----|----------------|
| 1 | App loads | open `/app/` | Dashboard renders |
| 2 | Sign in | log in | Land on role dashboard |
| 3 | Data reads | open Clients | List populates |
| 4 | Measurements | open a client | Measurements render |
| 5 | Payment | start a payment | Flutterwave opens, cancel cleanly |
| 6 | Shipping | request a quote | Options render |
| 7 | Role switch | sign out, sign in as each role | Correct dashboard each time |
| 8 | Mobile layout | narrow viewport | No overflow, drawer works |
| 9 | API health | `curl https://desby.app/api/v2/health` | `200` |

### 8.3 Asset optimisation

Card artwork is generated, not hand-edited:

```bash
python3 scripts/build_dashboard_cards.py
```

Assets must stay **under 50 KB each**. A regression here slows first paint on mobile data. Verify after regenerating:

```bash
find assets/cards -name "*.webp" -size +50k
```

Must print nothing.

---

## 9. Deploying the web app

### 9.1 The script

```bash
bash scripts/deploy_desby.sh
```

### 9.2 ⚠️ The base-href trap

The app is served under `/app/`, not `/`. Flutter must be told this at build time:

```bash
flutter build web --release \
  --dart-define=ENV=production \
  --base-href /app/
```

If `--base-href` is omitted, the built `index.html` gets `<base href="/">`. The browser then requests `main.dart.js`, `manifest.json`, and `logo.png` from the **domain root** — which is the landing page directory and contains none of them. Every asset 404s and the app is a blank page.

The deploy script sets this and then **verifies a `<base>` tag exists in the built `index.html`**. If that check is ever removed, the failure returns silently.

### 9.3 What the script does, in order

The order is deliberate. Do not reorder.

| Step | Action | Why it is here |
|------|--------|----------------|
| 0 | `flutter build web` | Build first, so a failure never consumes a backup slot |
| 0.5 | Verify `<base>` tag | Catch §9.2 before touching the server |
| 1 | `tar` the **current** live bundle | There is no second copy |
| 2 | `rsync` new bundle over `/var/www/desby/app` | — |
| 3 | Smoke test | — |
| 4 | Prune old backups | Disk is the constraint (§10.2) |

> **Build before backup is intentional.** A script that backs up first and builds second can fill the disk with backups of a bundle you were about to replace, on a host that is already at 94% disk.

### 9.4 ⚠️ `deploy_desby.sh` hardcodes the legacy host

```bash
SSH="ssh -i /Users/mac/Downloads/<key>.pem -o ConnectTimeout=25 ubuntu@<LEGACY-HOST>"
```

This is correct **today** and is the first thing to change during migration (Section 18). It does not read from an environment variable, so it cannot be overridden without editing the file.

### 9.5 Rolling back

```bash
# List backups on the server
ssh -i ~/Downloads/<key>.pem ubuntu@<LEGACY-HOST> 'ls -lt /var/www/desby/backups | head'

# Restore the newest backup
ssh -i ~/Downloads/<key>.pem ubuntu@<LEGACY-HOST> '
  sudo tar -xzf /var/www/desby/backups/<file>.tar.gz -C /var/www/desby'
```

Then purge the client cache — Flutter's service worker will otherwise keep serving the broken bundle (§11.3).

---

## 10. The server

### 10.1 Connecting

```bash
ssh -i ~/Downloads/<key>.pem -o ConnectTimeout=25 ubuntu@<LEGACY-HOST>
```

### 10.2 ⚠️ The disk is nearly full

The instance sits at roughly **94% disk**. Consequences:

- The first thing to fail on a full disk is logging, so you lose visibility exactly when you need it.
- `deploy_desby.sh` keeps a bounded number of backups for this reason.
- Never run an unconstrained cleanup (`rm -rf /var/lib/docker/*`). Docker holds the layers of containers belonging to **other products**.

Check it before you start, not after:

```bash
df -h /
```

### 10.3 ⚠️ Services on this host — and which are yours

```bash
systemctl list-units --type=service --state=running | grep -E 'desby|nginx|docker'
```

| Service | Yours? | What it does | Restart is safe? |
|---------|--------|--------------|------------------|
| `nginx.service` | **Shared** | All vhosts | Reload only (§11.4) |
| `docker.service` | **Shared** | Runs `BACKEND_API_CONTAINER` | **No** |
| `desby-landing.service` | **Yes** | `/opt/desby-landing/server/index.mjs` | Yes |
| `desby-proxy.service` | **Yes** | `/opt/desby-proxy/server.js` (Flutterwave) | Yes |
| `SIDE_SERVICE_C` | **No** | Unrelated | **Never** |
| `SIDE_SERVICE_A` | **No** | Unrelated | **Never** |
| `SIDE_SERVICE_B` | **No** | Unrelated | **Never** |

> **The rule:** if you cannot name the service as Desby's, you do not restart it.

> **Where are the real names?** This document is public, so shared components are named by
> placeholder (`BACKEND_API_CONTAINER`, `SIDE_SERVICE_A`…). The placeholder-to-literal map lives
> in `docs/PRIVATE-SHARED-INFRA.md`, which is **gitignored and must never be committed or shared**.
> An operator who only has this document cannot safely run a command on the server — they need
> that local file too. Copy it onto the machine you operate from.

### 10.4 Safe restart procedure

```bash
# 1. Confirm it is Desby's
systemctl cat desby-landing.service | grep ExecStart
#    → must reference /opt/desby-landing or /opt/desby-proxy

# 2. Restart
sudo systemctl restart desby-landing.service

# 3. Confirm
systemctl is-active desby-landing.service
sudo journalctl -u desby-landing.service -n 50 --no-pager
```

### 10.5 Logs

```bash
sudo journalctl -u desby-landing.service -f          # follow
sudo journalctl -u desby-landing.service --since '1 hour ago' --no-pager
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 10.6 Disk hygiene

Safe (yours only):

```bash
du -sh /var/www/desby
ls /var/www/desby/backups | wc -l
# delete OLD backups only, never the newest
```

**Unsafe** (shared): anything under `/var/lib/docker/`, `/home/ubuntu/<side-service>`, `/home/ubuntu/<side-service>`, or any directory you did not create.

---

## 11. nginx and TLS

### 11.1 Location of the config

```
/etc/nginx/sites-available/desby.app     # the real file
/etc/nginx/sites-enabled/desby.app       # symlink → sites-available
```

`sites-enabled` contains exactly two entries: `desby.app` and `<OTHER_VHOST>`. **The `<OTHER_VHOST>` vhost is a regular file, not a symlink, and serves an unrelated product.**

Stale backups also exist in `/etc/nginx/sites-available/` and `/etc/nginx/backups/` (several `.bak-*` files from October). They are inert because nothing symlinks to them. Do not delete them during a migration without confirming.

### 11.2 Routing summary

| Path | Goes to | Cache |
|------|---------|-------|
| `/` | `/var/www/desby/landing/index.html` | no-cache |
| `/app/` | `/var/www/desby/app` (Flutter SPA) | see §11.3 |
| `/api/` | `127.0.0.1:8080` → `BACKEND_API_CONTAINER` | no cache |
| `/api/v2/health` | same, `access_log off` | — |

Rate limiting on `/api/`:

```
limit_req_zone $binary_remote_addr zone=desby_api:10m rate=30r/s;
limit_req zone=desby_api burst=20 ndelay;
limit_req_status 429;
```

> **429 is not a bug.** Load testing from one IP will produce 429s by design. A shared NAT office can hit this in normal use.

### 11.3 ⚠️ Flutter caching is deliberately contradictory

| Asset | Cache | Why |
|-------|-------|-----|
| `index.html`, `main.dart.js`, `flutter_bootstrap.js`, `flutter.js`, `manifest.json`, `version.json` | `no-cache, must-revalidate` | Must always be revalidated or a deploy is invisible |
| `flutter_service_worker.js` | `no-cache, no-store` | The SW pins old builds |
| `/app/assets/`, `/app/icons/` | `30d` | Content-hashed, safe |
| `/app/canvaskit/` | `7d` | Large, changes rarely |
| Everything else `/app/` | `no-cache` | SPA fallback to `index.html` |

**Do not "simplify" this to one cache policy.** The split exists because a uniform `30d` on `main.dart.js` means users keep running the old bundle indefinitely — the single most common "the deploy didn't work" report for Flutter web.

> **Stale bundle symptom:** user reports the old UI after a successful deploy. The deploy worked. The service worker is serving the previous build. Hard-reload, or test in a private window, before investigating further.

### 11.4 Reloading nginx safely

```bash
sudo nginx -t          # ALWAYS run this first
sudo systemctl reload nginx     # reload, never restart
```

- `reload` = graceful, existing connections finish.
- `restart` = drops connections and, if the config is broken, takes down **every vhost on the host** including unrelated products.
- `nginx -t` returning non-zero means **do not reload**.

### 11.5 Certificates

```bash
sudo certbot certificates                    # list + expiry
sudo certbot renew --dry-run                 # safe test
sudo systemctl status certbot.timer           # is renewal scheduled?
```

Renewal covers **all** certificates in `/etc/letsencrypt/live/`, including ones for other products. A `certbot` failure can therefore take down something you do not own. Monitor it.

**Both A and AAAA records point at the server.** If you migrate, update both. A stale AAAA sends IPv6 clients to a host that no longer serves you.

---

## 12. The API dependency

### 12.1 What it is

| Item | Value |
|------|-------|
| Container | `BACKEND_API_CONTAINER` |
| Image | `BACKEND_API_IMAGE` |
| Port binding | `127.0.0.1:8080 → 8080` |
| Owned by | A different product team |
| Source | A **separate repository** |

### 12.2 Inspect without changing anything

```bash
docker ps --format '{{.Names}}  {{.Image}}  {{.Ports}}'
docker logs --tail 100 BACKEND_API_CONTAINER
curl -s http://127.0.0.1:8080/api/v2/health
```

### 12.3 ⚠️ Rules

1. **Do not `docker restart`, `stop`, `rm`, or rebuild** this container. It is not yours, and Desby is not its only consumer.
2. **Do not edit its nginx upstream** (`upstream BACKEND_API_UPSTREAM`).
3. If it is down, **Desby cannot be fixed from this repository.** Escalate to the owning team.
4. The `:latest` tag is mutable. The image can change under you without a deploy on your side.

### 12.4 Health check from outside

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://desby.app/api/v2/health
```

`200` = the whole path (DNS → TLS → nginx → rate limit → container) is intact. Anything else localises the failure to §16.

---

## 13. Store builds (iOS / Android)

### 13.1 Status

| Target | State | Blocking issue |
|--------|-------|----------------|
| Web | **Live** | — |
| iOS | Configured, **not submitted** | Apple Developer membership + signing |
| Android | Configured, **not submitted** | **Debug keystore only** — see §13.3 |

### 13.2 Android — the debug-keystore problem

The Android project is signed with the **debug** keystore. Google Play rejects debug-signed uploads.

You cannot fix this by editing a file. You must:

1. Create an upload keystore.
2. Store it **outside the repository**.
3. Add signing config to `android/app/build.gradle`.
4. Record the keystore password in a secret store.
5. Build with `flutter build appbundle`.
6. Upload to Play Console.

> **Losing the upload keystore means losing the ability to update the app.** Play will not reissue it. This is the single highest-consequence item in this section.

### 13.3 iOS

Requires a real Apple Developer account, a bundle ID, and provisioning profiles. Until then, iOS builds cannot be distributed. Simulator builds work locally and prove nothing about distribution.

### 13.4 Store metadata

App icons, screenshots, privacy declarations, and data-safety forms are **not** in this repository. They live in the store dashboards.

---

## 14. Incident playbooks

### 14.1 Site is down (white page / 502)

```
1. ssh to the server
2. systemctl is-active nginx          → restart only if inactive
3. df -h /                            → full disk is the usual cause (§10.2)
4. ls /var/www/desby/app | head       → bundle present?
5. sudo nginx -t                      → config valid?
6. curl -I https://desby.app/app/     → still failing?
```

Do **not** restart docker as a diagnostic. See §12.3.

### 14.2 App loads but every API call fails

This is `BACKEND_API`, not Desby.

```
1. curl -s http://127.0.0.1:8080/api/v2/health
2. docker ps | grep BACKEND_API_CONTAINER
3. docker logs --tail 100 BACKEND_API_CONTAINER
```

If the container is down → **escalate to the owning team.** You cannot fix it here.

### 14.3 429 Too Many Requests

Rate limiting (30 r/s, burst 20). Expected under load testing or shared NAT. Not a bug. If it affects real users, ask the owning team to raise the zone rate — do not edit nginx casually; the zone is shared.

### 14.4 Deploy succeeded, users see the old app

Almost always the service worker (§11.3). Confirm with a private window. Only investigate further if a fresh browser also shows the old build — then check that `main.dart.js` really has `no-cache` on the server.

### 14.5 TLS errors

```bash
sudo certbot certificates
date
```

An expired certificate will not renew itself if the `certbot.timer` is disabled. Check the timer before assuming disk space.

### 14.6 Supabase sign-in fails

Distinguish carefully:

| Test | Result | Meaning |
|------|--------|---------|
| App can read public data | Works | App + network fine |
| App cannot sign in | Fails | Supabase problem **or** wrong anon key |

The anon key is a dart-define. Rebuilding with a different key fixes it (§6.4).

### 14.7 Payments fail

```
1. systemctl is-active desby-proxy.service
2. sudo journalctl -u desby-proxy.service -n 100 --no-pager
3. curl -s -o /dev/null -w '%{http_code}' https://api.flutterwave.com/v3/payments
```

Do not put the Flutterwave secret into the Flutter app to "fix" this (§4.4).

### 14.8 Everything is slow

Check in this order:

1. `df -h /` — full disk degrades everything (§10.2).
2. `uptime` / `top` — **the instance is shared**; another product may be consuming the CPU.
3. `free -h` — a t3.micro is small; expect pressure.

Do not kill a process you do not own to free memory.

### 14.9 Purging a secret from git history

**Rotate first.** History rewriting is cleanup, not remediation.

```bash
# 1. Rotate in the provider dashboard (§6.5)
# 2. Rewrite history with git-filter-repo / BFG
# 3. Force-push all branches and tags
# 4. Tell every clone owner to re-clone
# 5. Confirm the secret is gone from the provider's side (revoked)
```

Anyone who cloned before step 2 still has it. Rotation is what actually protects you.

### 14.10 Rolling back the web app

See §9.5.

---

## 15. Dependency graph

**Read this before making any change.** Desby is not a single stack; it is a directed graph, and the edges below are the ones that bite.

```
                    ┌──────────────────────────────┐
                    │   GitHub (public, source)    │
                    └───────────────┬──────────────┘
                                    │  git push
                                    ▼
                    ┌──────────────────────────────┐
                    │   macOS build host           │
                    │   Flutter → web bundle       │
                    └───────────────┬──────────────┘
                                    │  rsync  (deploy_desby.sh)
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  AWS EC2  (shared, ~94% disk)                                            │
│                                                                           │
│   ┌──────────────────┐     ┌──────────────────────┐                      │
│   │  nginx           │◄────┤  /var/www/desby/app  │  Flutter SPA        │
│   │  TLS + routing   │     │  /var/www/desby/land. │  Landing            │
│   └────────┬─────────┘     └──────────────────────┘                      │
│            │ /api/                                                        │
│            ▼                                                              │
│   ┌──────────────────┐                                                   │
│   │  Docker          │                                                   │
│   │  BACKEND_API_CONTAINER   │  ← NOT Desby's. Separate repo. Do not restart.    │
│   │  127.0.0.1:8080  │                                                   │
│   └────────┬─────────┘                                                   │
│            │                                                              │
│   ┌────────┴─────────┐   ┌──────────────┐   ┌────────────────────────┐    │
│   │  desby-landing   │   │ desby-proxy  │   │ SIDE_SERVICE_A │    │
│   │  (node :4600)    │   │ (node)       │   │ SIDE_SERVICE_C         │    │
│   └──────────────────┘   │ Flutterwave  │   │ ← NOT Desby's          │    │
│                          └──────────────┘   └────────────────────────┘    │
│                                                                           │
│   certbot ──► /etc/letsencrypt  (shared with other products)              │
└───────────┬───────────────────────┬───────────────────┬───────────────────┘
            │                       │                   │
            ▼                       ▼                   ▼
   ┌─────────────────┐    ┌────────────────┐   ┌──────────────┐
   │  Supabase       │    │  Flutterwave   │   │  Fez         │
   │  Auth + Store   │    │  Payments      │   │  Shipping    │
   │  + Realtime     │    └────────────────┘   └──────────────┘
   └─────────────────┘
            │
            ▼
   ┌─────────────────┐
   │  Brevo          │
   │  Email          │
   └─────────────────┘
```

### 15.1 Failure propagation — what breaks what

| If this fails | User sees | You should |
|---------------|-----------|-----------|
| **Fez** | No shipping options | Degrade gracefully (§4.5) |
| **Brevo** | No verification email | Acceptable short-term |
| **Supabase** | Cannot sign in | **Total outage** |
| **BACKEND_API** | App loads, no data | Escalate (§12.3) |
| **Disk full** | Slow, then logs stop | Free space (§10.2) |
| **nginx reload (bad config)** | **Every product on the host is down** | Always `nginx -t` first (§11.4) |
| **certbot** | Site expires in days | Renew manually (§11.5) |

### 15.2 The three shared-resource traps

1. **nginx.** One config, many products. A syntax error is a multi-product outage.
2. **Docker.** One daemon. `docker system prune` can delete another product's rollback path.
3. **TLS.** One certbot, many certs. Your failure mode may be someone else's renewal.

---

## 16. Troubleshooting index

| Symptom | Go to |
|---------|-------|
| White page on `/app/` | §14.1, then §9.2 |
| All API calls fail | §14.2 |
| 429s | §14.3 |
| Old UI after deploy | §14.4, §11.3 |
| TLS/certificate error | §14.5 |
| Cannot sign in | §14.6 |
| Payment button dead | §14.7 |
| Everything slow | §14.8 |
| Secret exposed in git | §14.9, §6.3 |
| Need to undo a deploy | §9.5 |
| Want to change a service on the server | §10.3 **before** you run anything |
| Building for Play | §13.2 |
| nginx change | §11.4 |
| Planning the migration | §18 |

---

## 17. If you only remember five things

1. **You do not own most of the running system.** `BACKEND_API`, nginx, Docker, and the certbot are shared with other products. Never restart or clean something you cannot name as Desby's.

2. **Config is compiled in, not read at runtime.** `--dart-define` means changing config requires a rebuild, and anything you pass is public. Server secrets never go in `lib/`.

3. **The disk is at ~94%.** It is shared, Docker holds other people's layers, and a full disk kills logging first. Check `df -h /` before debugging anything.

4. **`--base-href /app/` is mandatory.** Without it every asset 404s and you get a blank page — and the failure looks like a broken build, not a flag.

5. **Rotate before you rewrite.** For an exposed credential, revoking it in the provider dashboard is the only thing that actually removes risk. Git history cleanup is cosmetic by comparison.

---

## 18. Planned changes

### 18.1 Move to a dedicated EC2 instance

Desby currently shares an instance with unrelated products. The migration is **not done**.

| # | Step | Notes |
|---|------|-------|
| 1 | Provision a dedicated instance | Do not reuse the current host |
| 2 | Install nginx, Docker, certbot | Match versions |
| 3 | Copy `/var/www/desby` | `rsync`, do not hand-copy |
| 4 | Install `desby-landing`, `desby-proxy` | Restore their configs and secrets |
| 5 | Request a TLS certificate | New cert for the same domain |
| 6 | **Point `BACKEND_API` DNS at the new host** | ⚠️ Ordering — see below |
| 7 | Update `deploy_desby.sh` | It hardcodes the old host (§9.4) |
| 8 | Update A **and AAAA** | Stale AAAA breaks IPv6 (§11.5) |
| 9 | Verify the §8.2 matrix end to end | Do not skip |
| 10 | Keep the old host warm for 48h | Rollback |
| 11 | Decommission old host | Only after sign-off |

**Critical ordering.** Step 6 is the cutover. Before it, both hosts answer DNS and traffic may split; after it, nothing serves the old host. Do not decommission the old instance before step 10 completes — it is your only rollback.

> **`deploy_desby.sh` will silently deploy to the OLD host after migration** until you edit it. A green deploy is not proof the new host received anything. Always verify with `curl -I https://desby.app/app/` and check the served build.

### 18.2 Outstanding security work

| Item | Section | Priority |
|------|---------|----------|
| Rotate the exposed Fez key | §6.3 | **Critical** |
| Replace Flutterwave debug/legacy paths | §4.4 | Medium |
| Android upload keystore | §13.2 | High |
| Secret scanning in CI | §6.3 | Medium |
| Purge git history | §14.9 | After rotation |

### 18.3 Documentation gaps

- [ ] Record the `BACKEND_API` owning team and escalation contact
- [ ] Document the database schema (it lives outside this repo)
- [ ] Add a runbook for Fez and Brevo outages
- [ ] Document the DNS/registrar access path
- [ ] Add a CI pipeline — there is currently **none**

---

*End of handover. If you find a step that is wrong, fix it here and commit — this document is only useful if it stays true.*