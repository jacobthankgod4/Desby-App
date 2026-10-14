# Desby OS transactional email templates

Four auth emails, all generated from one shared shell so they stay visually
identical:

| File | Purpose | Eyebrow |
|---|---|---|
| `confirmation.html` | Confirm email on signup | WELCOME |
| `magic_link.html` | Passwordless sign-in | SIGN IN |
| `recovery.html` | Password reset | ACCOUNT RECOVERY |
| `email_change.html` | Change account email | SECURITY |
| `invite.html` | `admin.inviteUserByEmail()` — invited to create an account | YOU'RE INVITED |
| `reauthentication.html` | `reauthenticate()` before a sensitive operation | SECURITY CHECK |
| `_shell.html` | Source of truth — **do not deploy** | — |

`_shell.html` is a build input, not a template. Supabase reads only the four
files listed in `supabase/config.toml`.

## Design

Light, bold, minimal. Palette is taken from `lib/theme/colors.dart`:

| Token | Hex | Use |
|---|---|---|
| Background | `#F2F4F7` | Page |
| Card | `#FFFFFF` | Email body |
| Ink | `#0F172A` | Headings, and all text on amber |
| Body text | `#475569` | Paragraphs |
| Muted | `#64748B` | Secondary, fallback link |
| Brand amber | `#FFC107` | Header rule, CTA fill, note border |
| Readable amber | `#8A5A00` | Amber as *text* on white |

**Amber is never text on white and never carries white text.** `#FFC107` on
white is ~1.9:1 and unreadable; white on `#FFC107` fails too. That is why
`#8A5A00` exists for the `Desby.` wordmark and the fallback link, and why the
CTA pairs amber with `#0F172A`.

Structure per email: brand rule → wordmark + eyebrow → 32px headline → greeting
→ body → amber CTA → fallback link → amber-ruled note → expiry meta → footer.

## Variables used

Supabase injects these; do not rename them.

- `{{ .ConfirmationURL }}` — the action link (CTA + fallback)
- `{{ .SiteURL }}` — footer link
- `{{ .Data.name }}` — greeting, optional (`there` when absent)

All styling is inline. Email clients strip `<style>` blocks and external CSS, so
the tables and inline styles are deliberate.

## Editing

Change `_shell.html`, then regenerate all four:

```bash
cd supabase/templates && python3 /tmp/gen.py
```

Or edit a single file directly — just keep the structure aligned so the four
stay consistent.

## Copy changes (per template)

| File | Headline | CTA | Note |
|---|---|---|---|
| `confirmation.html` | Confirm your email | Confirm email address | Didn't sign up? … no account is created until you confirm. |
| `magic_link.html` | Your sign-in link | Sign in to Desby OS | Didn't request this? … Your account stays exactly as it is. |
| `recovery.html` | Reset your password | Choose a new password | For your security, this link works once and then stops working. |
| `email_change.html` | Confirm your new email | Confirm new email | If you didn't request this, your old email is still active. |

Security-focused emails (recovery, email change) say explicitly that ignoring
them changes nothing. That is deliberate.

## Applying to the new project

The dashboard templates are pasted per-template; `supabase/config.toml` only
applies them to a linked project via `supabase db push`. For the new Supabase
account, paste each file's **full contents** into Authentication → Email
Templates. Subjects are set in `config.toml`:

- `Confirm your Desby OS account`
- `Reset your Desby OS password`
- `Sign in to Desby OS`
- `Confirm your new email for Desby OS`

## Not yet customised

**Security notifications** (password changed, email changed, phone changed,
MFA added/removed, sign-in method linked/removed) are enabled on the project but
still use Supabase's stock styling. They are one-way — a user cannot action
them — so they need no CTA. They are left alone deliberately rather than half
branded.

**`email_otp`** is only sent when a flow requests a one-time *code* instead of a
link. The app signs in with `signInWithPassword`, never `signInWithOtp`, so this
template is unused today. Set it if OTP sign-in is ever enabled.

## Which code path triggers each template

| Template | Triggered by | In the app today |
|---|---|---|
| `confirmation.html` | `auth.signUp()` | Yes |
| `recovery.html` | `auth.resetPasswordForEmail()` | Yes (forgot password, settings) |
| `email_change.html` | `auth.updateUser()` with a new email | Yes (settings) |
| `magic_link.html` | `auth.signInWithOtp()` | No — password sign-in only |
| `invite.html` | `auth.admin.inviteUserByEmail()` | No |
| `reauthentication.html` | `auth.reauthenticate()` | No |

### Reauthentication — wired as a service, deliberately not on the delete path

`ReauthService` (`lib/core/services/reauth_service.dart`) is live and used by
account deletion in `settings_page.dart`. That fixed a real bug: the old code
called `signInWithPassword` and **ignored its result**, so with MFA enabled — where
that call returns no user and throws nothing — the account was deleted without
the identity ever being confirmed.

Deletion still confirms through `confirmWithPassword` rather than an emailed
challenge. Switching it to `requestChallenge()` would make the template send,
but `auth.reauthenticate()` returns `void`: it requests an OTP and hands back
nothing to complete it with, and `OtpType` has no `reauthentication` member. Doing
that properly means adding a callback route and a verify step that cannot be
end-to-end tested in this environment. Putting an untestable OTP flow in front of
**account deletion** risks locking users out of their own account, so the proven
password path stays, now with the MFA hole closed.

### Invite — wired and live

`admin.inviteUserByEmail()` is reached through the admin console:

- `AdminService.inviteUser()` — `lib/features/admin/data/admin_service.dart`
- `supabase/functions/admin-invite-user/index.ts` — takes the caller's JWT,
  re-checks the role against the SECURITY DEFINER `is_admin()` RPC, then
  invites. The browser never holds a `service_role` key.
- Admin console app bar → "Invite a user"

This is the only path that sends the **Invite user** template. Desby's
client-facing "invite" feature (`invite_provider.dart`) is unrelated — it shares
a token so a *client* can submit measurements and never creates an auth account.

## Pushing to a remote project

```bash
supabase config push --yes
```

`supabase config diff` first, to see exactly what will change. The CLI uploads
each template's **body** from `content_path` as well as the subject, so this is
the supported route — pasting into the dashboard by hand is the fallback.

**Blocked on Free plan with the default email provider.** Pushing currently
fails with:

```
Email template modification is not available for free tier projects using the
default email provider. Please upgrade your plan or configure a custom SMTP
provider.
```

Supabase only accepts custom template content once a custom SMTP provider is
configured on the project. Configure Brevo in Authentication → SMTP first, then
run the push. Nothing partially applies — the auth push fails as a unit, so no
subject or template lands half-applied.

Two values in `config.toml` are declared locally and would otherwise be pushed
too. They are pinned to match the live project on purpose:

- `db.major_version = 17` — lowering it would try to change the live database
- `api.schemas` / `api.extra_search_path` — match remote

`auth.site_url` is deliberately `https://desby.app`; the remote still has
`http://localhost:3000`, and pushing corrects it.

## Not verified

These were reviewed as markup — tags balanced, no unfilled placeholders,
Supabase variables preserved, contrast checked by hand. They have **not** been
rendered in Outlook, Gmail or Brevo's editor. Test one send per template after
the SMTP migration.