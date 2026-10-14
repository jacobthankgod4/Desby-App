#!/usr/bin/env bash
# ============================================================================
# DEPRECATED — DO NOT RUN
# ============================================================================
# This script is superseded by scripts/deploy_desby.sh.
#
# It was retired because it broke production in two ways:
#
#   1. It synced build/web to /var/www/desby/web, but nginx serves the Flutter
#      app from /var/www/desby/app (under /app/). The bundle landed where
#      nothing served it.
#
#   2. It uploaded deploy/nginx/desby.app.conf over the live config. That repo
#      conf predates the /app/ locations and points root at /var/www/desby/web,
#      so overwriting the live config removed every /app/ location block and
#      took the app down entirely.
#
# It also built without --base-href /app/, which produced <base href="/"> and
# sent main.dart.js / flutter_bootstrap.js / manifest.json / logo.png requests
# to the domain root (the landing dir, no Flutter assets) — all 404.
#
# The retained script builds with the correct base href, deploys to the
# correct directory, and backs up the live bundle first.
# ============================================================================

echo "DEPRECATED: this script overwrites the live nginx config and deploys to" >&2
echo "           the wrong directory (/var/www/desby/web). It is kept only as" >&2
echo "           a record of why it was retired." >&2
echo "" >&2
echo "Use instead:" >&2
echo "    ./scripts/deploy_desby.sh" >&2
exit 1
