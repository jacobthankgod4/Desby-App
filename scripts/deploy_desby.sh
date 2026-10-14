#!/bin/bash
# Build the Flutter web app and deploy it to /var/www/desby/app via rsync.
#
# Order matters:
#   Build first (so a failed build never consumes a backup slot),
#   then back up the live bundle BEFORE overwriting, because there is no
#   second copy and the box is at 94% disk so a failed deploy cannot simply be
#   rebuilt from scratch if the source tree is lost.
set -uo pipefail
STAMP=$(date +%Y%m%d-%H%M%S)
TARGET=/var/www/desby/app
BACKUP=/home/ubuntu/desby_app_backup_${STAMP}.tar.gz
# The Flutter app is served under /app/ by the live nginx config. Without this
# flag index.html gets <base href="/">, which sends main.dart.js/manifest.json/
# logo.png requests to the domain root (/var/www/desby/landing, which has no
# Flutter assets) and every one of them 404s.
BASE_HREF=/app/

SSH="ssh -i /Users/mac/Downloads/korra-ai-key.pem -o ConnectTimeout=25 ubuntu@korra.work"

echo "=== 0. build flutter web (base-href $BASE_HREF) ==="
cd /Users/mac/desby_app || exit 1
flutter build web --release --dart-define=ENV=production --base-href "$BASE_HREF"
BUILD_RC=$?
if [ $BUILD_RC -ne 0 ]; then
  echo "    build failed (exit $BUILD_RC) — live bundle untouched"
  exit $BUILD_RC
fi
grep -o '<base[^>]*>' build/web/index.html || {
  echo "    WARNING: no <base> tag in built index.html — check the build"
  exit 1
}
echo "    build ok"

echo
echo "=== 1. back up current deployment (on the server) ==="
# Must run over ssh: /var/www/desby only exists there. An earlier version of this
# script ran tar locally, silently produced nothing, and aborted — which is the
# only reason the guard caught it.
$SSH "sudo tar -czf $BACKUP -C /var/www/desby app && sudo chown ubuntu:ubuntu $BACKUP"
if $SSH "test -s $BACKUP"; then
  echo "    ok: $BACKUP ($($SSH "du -h $BACKUP" | cut -f1))"
else
  echo "    WARNING: backup failed — aborting so the live bundle is not lost"
  exit 1
fi

echo
echo "=== 2. rsync build/web -> $TARGET ==="
# -e must repeat the identity file: --rsync-path overrides the remote command,
# and without -e the key is never passed, so the transfer dies with
# "Permission denied (publickey)".
rsync -az --delete \
  --rsync-path="sudo rsync" \
  -e "ssh -i /Users/mac/Downloads/korra-ai-key.pem -o ConnectTimeout=25" \
  --exclude '.DS_Store' \
  --human-readable \
  --stats \
  /Users/mac/desby_app/build/web/ \
  ubuntu@korra.work:$TARGET
RC=$?
echo "    rsync exit: $RC"
[ $RC -ne 0 ] && { echo "    rsync failed — live bundle untouched or partially synced"; exit $RC; }

echo
echo "=== 3. fix ownership ==="
$SSH \
  "sudo chown -R www-data:www-data $TARGET && sudo find $TARGET -type d -exec chmod 755 {} + && sudo find $TARGET -type f -exec chmod 644 {} + && echo '    ownership set to www-data'"

echo
echo "=== 4. verify ==="
ssh -i /Users/mac/Downloads/korra-ai-key.pem -o ConnectTimeout=25 ubuntu@korra.work "
  echo -n '    app http      : '; curl -s -m 20 -o /dev/null -w '%{http_code}\n' https://desby.app/app/
  echo -n '    main.dart.js  : '; curl -s -m 30 -o /dev/null -w 'http=%{http_code} bytes=%{size_download}\n' https://desby.app/app/main.dart.js
  echo -n '    index.html    : '; curl -s -m 20 -o /dev/null -w 'http=%{http_code}\n' https://desby.app/app/index.html
  echo -n '    manifest      : '; curl -s -m 20 -o /dev/null -w '%{http_code}\n' https://desby.app/app/manifest.json
  echo -n '    base href     : '; sudo grep -o '<base[^>]*>' $TARGET/index.html || echo MISSING
  echo    '    deployed files:'; sudo ls $TARGET | head -12
  echo -n '    size          : '; sudo du -sh $TARGET | cut -f1
  echo -n '    disk          :'; df -h / | tail -1
"
echo
echo "backup kept at: $BACKUP"
