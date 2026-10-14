import pathlib

SHELL = pathlib.Path('_shell.html').read_text()

T = {
 'confirmation.html': dict(
   preview='Confirm your email to finish setting up your Desby OS account.',
   eyebrow='WELCOME',
   headline='Confirm your email',
   body='Confirm your email address and your Desby OS account is ready to use. It takes about ten seconds.',
   cta='Confirm email address',
   note='Didn\'t sign up? You can safely ignore this email &mdash; no account is created until you confirm.',
   meta='This link expires in 24 hours.',
 ),
 'magic_link.html': dict(
   preview='Sign in to Desby OS without typing your password.',
   eyebrow='SIGN IN',
   headline='Your sign-in link',
   body='Use the button below to sign in. No password needed.',
   cta='Sign in to Desby OS',
   note='Didn\'t request this? You can safely ignore this email. Your account stays exactly as it is.',
   meta='This link expires in 1 hour and can only be used once.',
 ),
 'recovery.html': dict(
   preview='Reset your Desby OS password.',
   eyebrow='ACCOUNT RECOVERY',
   headline='Reset your password',
   body='Click below to choose a new password. If you didn\'t ask for this, ignore this email and nothing changes.',
   cta='Choose a new password',
   note='For your security, this link works once and then stops working.',
   meta='This link expires in 1 hour.',
 ),
 'email_change.html': dict(
   preview='Confirm your new Desby OS email address.',
   eyebrow='SECURITY',
   headline='Confirm your new email',
   body='Confirm this change to move your Desby OS account to the address below.',
   cta='Confirm new email',
   note='If you didn\'t request this, your old email is still active &mdash; ignore this message and nothing changes.',
   meta='If not confirmed, this request expires in 24 hours.',
 ),
}

for fn, d in T.items():
    body = SHELL.replace('{{ .PreviewText }}', d['preview']) \
                .replace('{{ .Eyebrow }}', d['eyebrow']) \
                .replace('{{ .Headline }}', d['headline']) \
                .replace('{{ .Body }}', d['body']) \
                .replace('{{ .CtaLabel }}', d['cta']) \
                .replace('{{ .Note }}', d['note']) \
                .replace('{{ .Meta }}', d['meta'])
    pathlib.Path(fn).write_text(body)
    print(f"  {fn}: {len(body)} bytes")

# ── Appended: the two auth flows that were still unset ────────────────────────
# invite  -> admin.inviteUserByEmail() — Supabase sends this when an admin
#            invites someone to create an account.
# reauthentication -> auth.reauthenticate() / reauthSession(), used to confirm
#            identity before a sensitive operation (email change, account
#            deletion, payout changes).
MORE = {
 'invite.html': dict(
   preview='You have been invited to join Desby OS.',
   eyebrow='YOU&rsquo;RE INVITED',
   headline='Join Desby OS',
   body='You have been invited to create a Desby OS account. Accept the invitation to set your password and get started.',
   cta='Accept invitation',
   note='If you weren&rsquo;t expecting this invitation, you can ignore it. No account is created until you accept.',
   meta='This invitation link expires in 24 hours.',
 ),
 'reauthentication.html': dict(
   preview='Confirm it&rsquo;s you before continuing.',
   eyebrow='SECURITY CHECK',
   headline='Confirm it&rsquo;s you',
   body='For your security, confirm your identity to continue with this change to your account.',
   cta='Confirm it&rsquo;s me',
   note='If you didn&rsquo;t start this, close this email. Nothing on your account will change without confirmation.',
   meta='This link expires in 1 hour.',
 ),
}
for fn, d in MORE.items():
    body = SHELL.replace('{{ .PreviewText }}', d['preview']) \
                .replace('{{ .Eyebrow }}', d['eyebrow']) \
                .replace('{{ .Headline }}', d['headline']) \
                .replace('{{ .Body }}', d['body']) \
                .replace('{{ .CtaLabel }}', d['cta']) \
                .replace('{{ .Note }}', d['note']) \
                .replace('{{ .Meta }}', d['meta'])
    pathlib.Path(fn).write_text(body)
    print(f"  {fn}: {len(body)} bytes")
