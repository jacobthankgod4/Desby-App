# Infrastructure Handover

Written 14 October 2026 against `korra.work` (`13.60.215.88`, Ubuntu 26.04,
48 GB disk at 76%).

Purpose: move **Desby** off the shared box onto a dedicated EC2 account, so that
possession of the SSH key cannot put Korra or Scout at risk.

---

## 1. Why this is urgent

`korra.work` is not a Desby server. It runs three other things that matter more
than Desby does:

| Service | What it is |
|---|---|
| `korra-ai-prod` (Docker) | **Korra** — AI body-measurement platform with real customer scans and garment data |
| `scout.service` | Scout autonomous trading agent |
| `scout-signer.service` | **Scout's Solana signer sidecar** — the process that can move funds. Bound to `127.0.0.1:4601`, reachable only from the agent |
| `garment-proxy.service` | Korra's Kaggle garment proxy |
| `dotf-monitor.service` | Monitoring |

Anyone holding the SSH key gets root on all of that. The signer in particular
is the reason this is not theoretical: a mistake on a box that holds a Solana
signer is not a bad deploy, it is a lost wallet.

### The coupling that makes this urgent — and the hard part

**`desby.app/api/*` does not reach a Desby backend. It proxies to Korra's.**

```nginx
# /etc/nginx/sites-enabled/desby.app
upstream korra_backend { server 127.0.0.1:8080; keepalive 32; }
location /api/          { proxy_pass http://korra_backend; }
location = /api/v2/health { proxy_pass http://korra_backend; }
```

`127.0.0.1:8080` is `docker-proxy` for `korra-ai-prod`. So Desby's API surface is
**currently served by the Korra container**. You cannot move Desby to its own
host without deciding what replaces this. See §6.

Also orphaned: **`desby-proxy.service`** (node, `127.0.0.1:3002`, the Flutterwave
proxy) is running but **nothing in nginx references port 3002**. Either it is
dead, or the vhost was changed without updating it. Resolve this before copying
anything.

---

## 2. What moves, what stays

### Moves to the new Desby host

| Item | Location on the old box | Size |
|---|---|---|
| Flutter web app | `/var/www/desby/app` | 66 MB |
| Static landing | `/var/www/desby/landing` | 3.2 MB |
| Root redirect | `/var/www/desby/index.html` | 20 KB |
| Landing service | `/opt/desby-landing` → `desby-landing.service` | — |
| Nginx vhost | `/etc/nginx/sites-enabled/desby.app` | — |
| TLS certs | certbot: `desby.app`, `desby.app-0001` | — |
| **The box's DNS** | Route 53 / registrar record for `desby.app` | — |

### Stays on `korra.work`

`korra-ai-prod` container, `scout.service`, `scout-signer.service`,
`garment-proxy.service`, `dotf-monitor.service`, the `korra` nginx vhost, and
the `korra.work` certificate.

### Build from source — do not copy `/var/www/desby/web`

There is a **second Flutter build** at `/var/www/desby/web` (66 MB) and backups in
`/var/www/desby/backups` (**847 MB**). The live one is `/var/www/desby/app`.
`deploy_desby.sh` targets `app`.

Note that the in-repo `deploy/nginx/desby.app.conf` points at
`/var/www/desby/web` — **that config is stale** and is not what is live. It is
also the exact mismatch implicated in a past production outage. Do not use it as
the migration source; use the live `sites-enabled/desby.app`.

---

## 3. Current state on the old box (verify before you start)

```
Hostname        ip-172-31-40-249
Public IP       13.60.215.88
OS              Ubuntu 26.04 LTS
Disk            48G total, 36G used, 12G free (76%)
nginx sites     desby.app, korra
```

Certificates — **both expire in ~35 days. Renewal will break on cutover if
DNS still points at the old host.**

| Cert | Domains | Expiry |
|---|---|---|
| `desby.app` | `desby.app`, `www.desby.app` | 2026-11-18 |
| `desby.app-0001` | `desby.app` | 2026-11-19 |
| `korra.work` | `korra.work`, `www.korra.work` | 2026-11-17 |

Backups on the old box: 847 MB in `/var/www/desby/backups` and **51 tarballs** in
`/home/ubuntu`. They are why the disk sits at 76%. Archive what you need and
prune before decommissioning; do not copy them to the new host.

---

## 4. What you need before touching DNS

### Credentials

Do not request these from a person; go to the provider dashboards.

| System | Where | Needed for |
|---|---|---|
| **Supabase** | supabase.com — project `sakmdeacligrqayfxyb` | DB, auth, storage, 3 edge functions |
| **Flutterwave** | dashboard.flutterwave.com | Public key (client), **secret key → edge-function secret**, encryption key |
| **Terminal Shipping** | terminal.africa | `TERMINAL_API_SECRET_KEY` — **books real paid shipments** |
| **Fez Logistics** | fezdelivery.co | **key is leaked in `FEZ_DELIVERY_API.md`; rotate** |
| **Brevo** | brevo.com | SMTP key — **already rotated once this session** |
| **Vercel** | vercel.com `jacobthankgod4-5488` | Scout only; irrelevant to Desby |
| **AWS** | AWS console | The new EC2 instance itself |

### Edge functions to redeploy

Not in the repo's deploy path; set secrets, then:

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

Work through the phases in order. **Do not touch DNS until Phase 5** — the whole
point is to be able to roll back by putting the record back.

### Phase 0 — Provision and harden the new host

- New EC2 in its own AWS account. **A separate account is the entire point**: an
  IAM compromise or a leaked key in the Desby account cannot reach Korra.
- Ubuntu 22.04 or 26.04, matching. Ubuntu 26.04 is current on the old box.
- Security groups: **22 from your IP only**, 80/443 from `0.0.0.0/0`, and no
  inbound access to 3002, 8080, 4601.
- Key-based SSH only. `PasswordAuthentication no`, `PermitRootLogin no`.
  Use one key per person. **Never reuse the `korra-ai-key.pem` you are holding
  right now** — it is, by definition, a key that has been shared.
- `fail2ban`, unattended-upgrades, and a non-default SSH port.

### Phase 1 — Baseline the app

```bash
sudo apt install -y nginx certbot python3-certbot-nginx postgresql-client rsync
```

Copy the **live** vhost from the old box and correct its roots to the new layout:

```bash
scp -i $KEY ubuntu@korra.work:/etc/nginx/sites-enabled/desby.app .
```

Known edits required:

- The vhost proxies `/api/` to `korra_backend` on `127.0.0.1:8080`. **That is
  Korra's container.** Decide per §6 before the new host serves any traffic.
- Confirm every `root` points under `/var/www/desby`, not `/var/www/desby/web`.

### Phase 2 — Copy the static content

```bash
# Direct server-to-server copy; the new host needs a key the old one trusts.
rsync -az --delete -e "ssh -i $KEY" \
  ubuntu@korra.work:/var/www/desby/app      /var/www/desby/app
rsync -az --delete -e "ssh -i $KEY" \
  ubuntu@korra.work:/var/www/desby/landing  /var/www/desby/landing
rsync -az        -e "ssh -i $KEY" \
  ubuntu@korra.work:/var/www/desby/index.html /var/www/desby/index.html
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
rsync -az -e "ssh -i $KEY" ubuntu@korra.work:/opt/desby-landing /opt/desby-landing
sudo systemctl daemon-reload && sudo systemctl enable --now desby-landing
```

**Proxy** — do **not** copy this until you know whether it is used. It listens
on `127.0.0.1:3002` and nginx does not reference it. Confirm on the old host
whether anything calls it; if not, leave it behind and delete it on decommission.

### Phase 4 — TLS and verification

```bash
sudo nginx -t
sudo systemctl reload nginx

# Point the domain at the new host FIRST, or certbot's HTTP challenge fails.
sudo certbot --nginx -d desby.app -d www.desby.app
```

Verify before cutover, using `curl --resolve` so you test the new host without
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

**Rollback:** repoint DNS to `13.60.215.88`. Nothing is destroyed by the cutover
as long as you have not decommissioned the old box.

### Phase 6 — Retire the old surface

Only after several clean days:

- Remove the `desby.app` nginx site from `korra.work`.
- **Revoke `desby.app` from the shared certbot renewal** — otherwise renewal
  attempts against the old host will fail and may alert.
- Add a maintenance stub so the old host does not serve stale content to anyone
  who bookmarked it.
- Decommission only after you are certain nothing still routes there.
- Archive `/var/www/desby/backups` (847 MB) if you want them; prune the rest.
- **Rotate and issue a new SSH key**, then destroy the old one. It has been
  shared by definition.

---

## 6. Decisions you must make before Phase 1

### A. What serves `/api/`?

Today it is the Korra Docker container on `127.0.0.1:8080`. Three options:

1. **Run the same backend on the new host.** Cleanest isolation, but you must know
   what that container actually is and how it is configured. It is not Desby code
   — it lives in the Korra repository.
2. **Point Desby's `/api/` at the public Korra host** (`korra.work/api/...`) over
   TLS. Fastest, but it keeps a runtime dependency on Korra — the availability
   coupling survives the migration even though the SSH key no longer bridges them.
3. **Give Desby its own Supabase-proxied API.** Most work.

This is the one question I cannot answer from the box. It needs whoever owns the
Korra backend.

### B. Does `desby-proxy` (`:3002`) do anything?

It is running and nothing references it. Either dead, or nginx was edited without
updating it — which would mean Flutterwave payments have been routing somewhere
unexpected. **Check before you copy it.**

### C. Is `/var/www/desby/web` needed?

A second 66 MB Flutter build with no nginx reference. It looks like the artifact
of the root migration. Confirm, then delete.

---

## 7. Known gaps to fix during or after the migration

Ordered by how likely they are to bite.

1. **`deploy_desby.sh` hardcodes a personal path and the shared host.** It will
   silently deploy Desby to `korra.work` after the migration. Change it **first**,
   and parameterise the key and host.
2. **No CI.** `.github/` does not exist. A migration this size without a test
   gate is how a bad build reaches production. Add `flutter analyze` and
   `flutter test` on PR before the next cutover.
3. **`FEZ_DELIVERY_API.md` leaks a live shipping key**, repo is public. Rotate
   today.
4. **`docs/SECRETS.md` is wrong** — it says keys arrive via `--dart-define`. They
   come from the bundled `.env` asset. A developer following it ships a broken app.
5. **`.env.example` is missing 33 of the 63 keys the code reads**, including
   every Supabase, Flutterwave and AI key.
6. **No seed script and 8 SQL files outside `migrations/`**, so a fresh Supabase
   project cannot reproduce the database. This will bite whoever builds a staging
   environment.
7. **Two competing config systems** — `lib/config/environment.dart` and
   `lib/config/app_config.dart` (122 lines, referenced by almost nothing).
8. **`ENABLE_ANALYTICS` and `ENABLE_CRASH_REPORTING` are no-ops.** No analytics,
   no crash reporting, no push notifications are actually wired up.
9. **Vimeo uploads are broken** (`_accessToken = ''`), so the apprentice lesson
   video dead-ends. `AGENTS.md` records the intended fix: proxy through an edge
   function.
10. **Mobile is unshippable.** Android signs release with the debug key; iOS has
    no signing team. Not a migration blocker, but do not claim otherwise.

---

## 8. Post-migration cleanup on the old host

Only once the new host has been stable for a week:

- Delete `desby-proxy.service` (or keep it if §6B says it is live).
- Delete `/var/www/desby/web` if confirmed unused.
- Prune `/var/www/desby/backups` and the 51 tarballs in `/home/ubuntu`. They are
  the bulk of the 76% disk usage.
- Add the new host's key to `~/.ssh/authorized_keys` **only** for the deploy path,
  ideally as a restricted command rather than a full shell key.

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
| Korra backend (the `/api/` dependency) | _unassigned_ | |
| Shipping accounts (Terminal, Fez) | _unassigned_ | |