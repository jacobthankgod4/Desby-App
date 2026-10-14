# Infrastructure Handover

Written 14 October 2026. Audited against the current production host:
Ubuntu 26.04, 48 GB disk at 76%.

Purpose: move **Desby** onto a dedicated EC2 account in a **separate AWS
account**, so that possession of the SSH key cannot put unrelated production
workloads at risk.

Throughout this document the current host is written as `LEGACY-HOST`. Substitute
the real hostname from your own infrastructure records — it is deliberately not
reproduced here, because this repository is public.

---

## 1. Why this is urgent

The current host is not a Desby server. It also runs **other production
workloads that are more sensitive than Desby is** — services handling customer
data and, critically, a process that is authorised to move funds on-chain.

Concretely, on that host today:

- A production Docker container serving another platform's API and customer data
- An autonomous agent service
- **A signing sidecar** — the only process on the box able to move funds. Bound to
  localhost and reachable only by the agent, but a shell on this host is a shell
  next to it
- A proxy service and a monitoring agent

Anyone holding the SSH key gets root on all of it. The signing sidecar is why
this is not theoretical: a mistake here is not a bad deploy, it is a lost wallet.

### The coupling that makes this urgent — and the hard part

**`desby.app/api/*` does not reach a Desby backend.** In the live nginx vhost:

```nginx
upstream <name> { server 127.0.0.1:8080; keepalive 32; }
location /api/            { proxy_pass http://<name>; }
location = /api/v2/health { proxy_pass http://<name>; }
```

Port 8080 is bound by `docker-proxy` for another platform's container — **not a
Desby service.** Desby's API surface is currently served by something outside this
project.

You cannot move Desby to its own host without deciding what replaces this. See
§6, and read the live vhost (`/etc/nginx/sites-enabled/desby.app`) to get the real
upstream name.

Moving the SSH key off the box removes the *access* risk but **not** this
availability coupling. Desby would still depend on another platform's container
being up.

Also check: a **second proxy service** (`desby-proxy.service`, node,
`127.0.0.1:3002`) is running, but **nothing in nginx references port 3002**. Either
it is dead, or the vhost was changed without updating it — which would mean
payment traffic has been routing somewhere unexpected. Resolve before copying.

---

## 2. What moves, what stays

### Moves to the new Desby host

| Item | Location on the old host | Size |
|---|---|---|
| Flutter web app | `/var/www/desby/app` | 66 MB |
| Static landing | `/var/www/desby/landing` | 3.2 MB |
| Root redirect | `/var/www/desby/index.html` | 20 KB |
| Landing service | `/opt/desby-landing` → `desby-landing.service` | — |
| Nginx vhost | `/etc/nginx/sites-enabled/desby.app` | — |
| TLS certificate | certbot, covering `desby.app` + `www` | — |
| **DNS records** | `desby.app`, `www.desby.app` | — |

### Stays on `LEGACY-HOST`

Every other service on the box, its nginx vhost, and its certificate. Do not
touch them. See the service list in §3 — confirm what is and is not Desby before
you copy anything.

### Build from source — do not copy `/var/www/desby/web`

There is a **second Flutter build** at `/var/www/desby/web` (66 MB) plus backups
in `/var/www/desby/backups` (**847 MB**). The live one is `/var/www/desby/app`.
`deploy_desby.sh` targets `app`.

The in-repo `deploy/nginx/desby.app.conf` points at `/var/www/desby/web` — **that
config is stale** and is not what is live. It is also the exact mismatch
implicated in a past production outage. Do not use it as the migration source;
use the live `sites-enabled/desby.app`.

---

## 3. Current state on the old host (verify before you start)

```
OS              Ubuntu 26.04 LTS
Disk            48G total, 36G used, 12G free (76%)
nginx sites     desby.app, plus others unrelated to Desby
```

Services running on the host — **only the first three are Desby:**

| Service | Desby? |
|---|---|
| `desby-landing.service` | ✅ yes |
| `desby-proxy.service` | ✅ yes (but unreferenced — see §1) |
| `nginx.service` | ✅ shared |
| everything else on the box | ❌ **no — leave alone** |

Certificates:

| Cert | Domains | Expiry |
|---|---|---|
| `desby.app` | `desby.app`, `www.desby.app` | 2026-11-18 |
| `desby.app-0001` | `desby.app` | 2026-11-19 |
| *(other certs on the host)* | — | *not Desby's — do not renew or revoke here* |

> **Both Desby certs expire in ~35 days.** Renewal will fail on cutover if DNS
> still points at the old host.

Backups on the old host: 847 MB in `/var/www/desby/backups` and **51 tarballs** in
`/home/ubuntu`. They are why the disk sits at 76%. Archive what you need, then
prune before decommissioning — do not copy them to the new host.

---

## 4. What you need before touching DNS

Do not request these from a person; go to the provider dashboards.

| System | Where | Needed for |
|---|---|---|
| **Supabase** | supabase.com — project ref in your records | DB, auth, storage, 3 edge functions |
| **Flutterwave** | dashboard.flutterwave.com | Public key (client), **secret key → edge-function secret**, encryption key |
| **Terminal Shipping** | terminal.africa | `TERMINAL_API_SECRET_KEY` — **books real paid shipments** |
| **Fez Logistics** | fezdelivery.co | **key is leaked in `FEZ_DELIVERY_API.md`; rotate** |
| **Brevo** | brevo.com | SMTP key — **already rotated once** |
| **AWS** | AWS console | The new EC2 instance itself |

### Edge functions to redeploy

Not in the repo's deploy path. Set secrets first, then:

```bash
supabase functions deploy flutterwave-pay
supabase functions deploy flutterwave-verify
supabase functions deploy admin-invite-user
```

`flutterwave-verify` requires `FLUTTERWAVE_SECRET_KEY`, `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY`.

> **Do not "simplify" the Flutterwave settlement path.** The inline JS SDK
> reports success from the browser, so the client **never** writes
> `orders.status`. `flutterwave-verify` re-checks with the secret key and settles
> via `service_role`. Reintroducing a client-side settle is a payment-forgery
> hole. See `supabase/functions/DEPLOY.md`.

---

## 5. Migration runbook

Work the phases in order. **Do not touch DNS until Phase 5** — the point is to be
able to roll back by putting the record back.

### Phase 0 — Provision and harden the new host

- New EC2 in its own AWS account. **A separate account is the entire point**: an
  IAM compromise or leaked credential in the Desby account cannot reach anything
  else.
- Ubuntu 22.04 or 26.04, matching the current host.
- Security groups: **22 from your IP only**, 80/443 from `0.0.0.0/0`, no inbound
  access to 3002, 8080, or any loopback-bound port.
- Key-based SSH only. `PasswordAuthentication no`, `PermitRootLogin no`. One key
  per person. **Never reuse the key currently in use** — it has been shared by
  definition, which is the premise of this migration.
- `fail2ban`, unattended-upgrades, non-default SSH port.

### Phase 1 — Baseline the app

```bash
sudo apt install -y nginx certbot python3-certbot-nginx postgresql-client rsync
```

Copy the **live** vhost and correct its roots to the new layout:

```bash
scp -i $KEY ubuntu@LEGACY-HOST:/etc/nginx/sites-enabled/desby.app .
```

Known edits required:

- The vhost proxies `/api/` to an upstream on `127.0.0.1:8080` that is **not a
  Desby service.** Decide per §6 before the new host serves any traffic.
- Confirm every `root` points under `/var/www/desby`, not `/var/www/desby/web`.

### Phase 2 — Copy the static content

```bash
rsync -az --delete -e "ssh -i $KEY" \
  ubuntu@LEGACY-HOST:/var/www/desby/app       /var/www/desby/app
rsync -az --delete -e "ssh -i $KEY" \
  ubuntu@LEGACY-HOST:/var/www/desby/landing   /var/www/desby/landing
rsync -az        -e "ssh -i $KEY" \
  ubuntu@LEGACY-HOST:/var/www/desby/index.html /var/www/desby/index.html
```

`--delete` matters: Flutter writes `version.json` and stale chunks must not
survive a deploy.

Then ownership:

```bash
sudo chown -R www-data:www-data /var/www/desby
sudo find /var/www/desby -type d -exec chmod 755 {} +
sudo find /var/www/desby -type f -exec chmod 644 {} +
```

### Phase 3 — Services

**Landing** (`desby-landing.service`):

```ini
[Unit]
Description=Desby Landing Page (TanStack Start)
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/desby-landing
ExecStart=/usr/bin/node /opt/desby-landing/server/index.mjs
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
rsync -az -e "ssh -i $KEY" ubuntu@LEGACY-HOST:/opt/desby-landing /opt/desby-landing
sudo systemctl daemon-reload && sudo systemctl enable --now desby-landing
```

**Proxy** — do **not** copy this until you know whether it is used. It listens on
`127.0.0.1:3002` and nginx does not reference it. Confirm on the old host whether
anything calls it; if not, leave it behind and delete it on decommission.

### Phase 4 — TLS and verification

```bash
sudo nginx -t
sudo systemctl reload nginx

# Point DNS at the new host FIRST, or certbot's HTTP challenge fails.
sudo certbot --nginx -d desby.app -d www.desby.app
```

Verify **before** cutover, using `curl --resolve` so you test the new host without
touching DNS:

```bash
curl -sI --resolve desby.app:443:NEW_IP https://desby.app/app/ | head -1
curl -s  --resolve desby.app:443:NEW_IP https://desby.app/app/index.html | grep -o '<base[^>]*>'
curl -s  --resolve desby.app:443:NEW_IP https://desby.app/app/main.dart.js -o /dev/null -w '%{http_code} %{size_download}\n'
```

`<base href="/app/">` is the critical one. Without it Flutter requests
`main.dart.js` from the domain root, hits `landing/`, and every asset 404s.

### Phase 5 — Cutover

1. Lower DNS TTL to 300 **at least 24h before** this step. If you skipped it,
   expect up to an hour of stale resolution during rollback.
2. Repoint `desby.app` and `www.desby.app` to the new IP.
3. Re-run the Phase 4 checks **without** `--resolve`.
4. Watch nginx access logs on both hosts for 30 minutes.

**Rollback:** repoint DNS to the old IP. Nothing is destroyed by the cutover as
long as you have not decommissioned.

### Phase 6 — Retire the old surface

Only after several clean days:

- Remove the `desby.app` nginx site from `LEGACY-HOST`.
- **Revoke Desby from that host's certbot renewal** — otherwise renewal attempts
  will fail and may alert. **Do not touch any non-Desby certificate.**
- Add a maintenance stub so the old host does not serve stale content to anyone
  who bookmarked it.
- Decommission only once nothing routes there.
- Archive `/var/www/desby/backups` (847 MB) if you want them; prune the rest.
- **Rotate the SSH key and destroy the old one.**

---

## 6. Decisions you must make before Phase 1

### A. What serves `/api/`?

Today it is a container belonging to another platform, on `127.0.0.1:8080`. Three
options:

1. **Run the same backend on the new host.** Cleanest isolation, but you must
   identify what that container actually is and how it is configured — it is not
   Desby code and does not live in this repository.
2. **Point Desby's `/api/` at that platform's public host over TLS.** Fastest, but
   it keeps a runtime cross-platform dependency — the availability coupling
   survives the migration even though the SSH key no longer bridges them.
3. **Give Desby its own Supabase-proxied API.** Most work.

This is the one question I cannot answer from the host. It needs whoever owns the
upstream service.

### B. Does `desby-proxy` (`:3002`) do anything?

Running, and nothing references it. Either dead, or nginx was edited without
updating it — which would mean payment routing has been somewhere unexpected.
**Check before you copy it.**

### C. Is `/var/www/desby/web` needed?

A second 66 MB Flutter build with no nginx reference. It looks like the artifact
of the root migration. Confirm, then delete.

---

## 7. Known gaps to fix during or after the migration

Ordered by how likely they are to bite.

1. **`deploy_desby.sh` hardcodes a personal key path and the current host.** It
   will silently deploy Desby back to `LEGACY-HOST` after the migration. Change
   it **first** and parameterise both.
2. **No CI.** `.github/` does not exist. A migration this size without a test
   gate is how a bad build reaches production. Add `flutter analyze` and
   `flutter test` on PR before the next cutover.
3. **`FEZ_DELIVERY_API.md` leaks a live shipping key**, and the repo is public.
   Rotate today.
4. **`docs/SECRETS.md` is wrong** — it says keys arrive via `--dart-define`. They
   come from the bundled `.env` asset. A developer following it ships a broken app.
5. **`.env.example` is missing 33 of the 63 keys the code reads**, including
   every Supabase, payment and AI-provider key.
6. **No seed script and 8 SQL files outside `migrations/`**, so a fresh Supabase
   project cannot reproduce the database. This will bite whoever builds staging.
7. **Two competing config systems** — `lib/config/environment.dart` and
   `lib/config/app_config.dart` (122 lines, referenced by almost nothing).
8. **`ENABLE_ANALYTICS` and `ENABLE_CRASH_REPORTING` are no-ops.** No analytics,
   crash reporting or push notifications are actually wired up.
9. **Vimeo uploads are broken** (`_accessToken = ''`), so the apprentice lesson
   video dead-ends. `AGENTS.md` records the intended fix: proxy through an edge
   function.
10. **Mobile is unshippable.** Android signs release with the debug key; iOS has
    no signing team. Not a migration blocker — do not claim otherwise.

---

## 8. Post-migration cleanup on the old host

Only once the new host has been stable for a week:

- Delete `desby-proxy.service` (or keep it if §6B says it is live).
- Delete `/var/www/desby/web` if confirmed unused.
- Prune `/var/www/desby/backups` and the 51 tarballs in `/home/ubuntu`. They are
  the bulk of the 76% disk usage.
- Add the new host's key to `~/.ssh/authorized_keys` **only** for the deploy path,
  ideally as a restricted command rather than a full shell key.
- Leave every non-Desby service untouched.

---

## 9. Contacts and ownership

Ownership is not recorded anywhere in the repo. Fill this in **before** handing
over:

| Area | Owner | Contact |
|---|---|---|
| AWS account / EC2 | _unassigned_ | |
| Domain registrar + DNS | _unassigned_ | |
| Supabase project | _unassigned_ | |
| Flutterwave account | _unassigned_ | |
| **The `/api/` upstream service (§6A)** | _unassigned_ | |
| Shipping accounts (Terminal, Fez) | _unassigned_ | |