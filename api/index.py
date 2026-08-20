"""
Desby API Proxy — Production-grade Korra AI relay

Handles:
- CORS for Flutter Web
- Multipart form forwarding (photos)
- Graceful timeout with upstream deadline
- Request/response logging
- Health check endpoint
"""

import os
import time
import traceback
from datetime import datetime, timezone
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin

from flask import Flask, request, jsonify, Response

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

KORRA_BASE_URL = os.environ.get("KORRA_API_URL", "https://korra.work")
KORRA_API_KEY = os.environ.get("KORRA_API_KEY", "")

# Upstream timeout in seconds. Vercel Hobby hard-caps at 10s, Pro at 60s.
# We set this to match the plan limit so urllib doesn't hang indefinitely.
UPSTREAM_TIMEOUT = int(os.environ.get("UPSTREAM_TIMEOUT", "55"))

# Endpoints that are known to be slow (need longer timeout)
SLOW_ENDPOINTS = {
    "api/v2/measurements/estimate",
    "api/v2/measurements/extract",
    "api/v2/body-shape/compute",
    "api/v2/refinement/impute",
    "api/v2/tryon",
    "api/v2/tryon/capture",
    "api/v2/ai/assist",
}

# CORS config
ALLOWED_ORIGINS = os.environ.get(
    "ALLOWED_ORIGINS",
    "https://desbyapp.vercel.app,http://localhost:8080,http://localhost:3000",
).split(",")

# ---------------------------------------------------------------------------
# CORS helpers
# ---------------------------------------------------------------------------

CORS_HEADERS = {
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Accept, X-API-Key, x-partner-key, Authorization",
    "Access-Control-Max-Age": "86400",
    "Access-Control-Expose-Headers": "Content-Type, Content-Length, Content-Disposition",
}


def _cors_headers(origin: str | None = None) -> dict:
    """Return CORS headers, allowing the requesting origin if in allowlist."""
    headers = dict(CORS_HEADERS)
    if origin and origin in ALLOWED_ORIGINS:
        headers["Access-Control-Allow-Origin"] = origin
        headers["Vary"] = "Origin"
    elif "*" in ALLOWED_ORIGINS:
        headers["Access-Control-Allow-Origin"] = "*"
    return headers


# ---------------------------------------------------------------------------
# Health check (always fast, never proxied)
# ---------------------------------------------------------------------------


@app.route("/", defaults={"path": ""})
@app.route("/<path:path>", methods=["OPTIONS"])
def options_handler(path):
    """Handle CORS preflight for all routes."""
    origin = request.headers.get("Origin")
    return Response("", status=204, headers=_cors_headers(origin))


@app.route("/health")
def health():
    origin = request.headers.get("Origin")
    return jsonify({
        "status": "ok",
        "service": "desby-api-proxy",
        "upstream": KORRA_BASE_URL,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }), 200, _cors_headers(origin)


# ---------------------------------------------------------------------------
# Main proxy handler
# ---------------------------------------------------------------------------


@app.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
@app.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def catch_all(path):
    origin = request.headers.get("Origin")
    cors = _cors_headers(origin)

    # Root without path → info
    if not path:
        return jsonify({
            "status": "ok",
            "service": "desby-api-proxy",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }), 200, cors

    # ------------------------------------------------------------------
    # Build upstream request
    # ------------------------------------------------------------------

    dest = f"{KORRA_BASE_URL}/{path}"
    fwd_headers = {}

    # API key forwarding
    if KORRA_API_KEY:
        fwd_headers["X-API-Key"] = KORRA_API_KEY

    # Forward relevant headers
    for hdr in ("Content-Type", "Accept", "X-API-Key", "x-partner-key"):
        val = request.headers.get(hdr)
        if val:
            fwd_headers[hdr] = val

    body = request.get_data()

    # Determine timeout — longer for known-slow endpoints
    timeout = UPSTREAM_TIMEOUT
    if path in SLOW_ENDPOINTS:
        timeout = min(UPSTREAM_TIMEOUT + 10, 58)  # stay under Vercel limits

    # ------------------------------------------------------------------
    # Forward to Korra
    # ------------------------------------------------------------------

    start = time.monotonic()
    try:
        req = Request(dest, data=body if body else None, headers=fwd_headers, method=request.method)
        with urlopen(req, timeout=timeout) as resp:
            data = resp.read()
            elapsed = (time.monotonic() - start) * 1000
            resp_ct = resp.headers.get("Content-Type", "application/json")

            # Log slow requests
            if elapsed > 3000:
                print(f"[PROXY] SLOW {request.method} {path} → {elapsed:.0f}ms ({resp.status})")

            return Response(data, resp.status, {
                "Content-Type": resp_ct,
                "X-Upstream-Ms": str(int(elapsed)),
                **cors,
            })

    except HTTPError as e:
        data = e.read()
        elapsed = (time.monotonic() - start) * 1000
        print(f"[PROXY] ERROR {request.method} {path} → {e.code} ({elapsed:.0f}ms)")
        return Response(data, e.code, {
            "Content-Type": "application/json",
            "X-Upstream-Ms": str(int(elapsed)),
            **cors,
        })

    except (URLError, TimeoutError) as e:
        elapsed = (time.monotonic() - start) * 1000
        print(f"[PROXY] TIMEOUT {request.method} {path} → {elapsed:.0f}ms ({e})")
        return jsonify({
            "error": "upstream_timeout",
            "message": f"Korra API did not respond within {timeout}s",
            "endpoint": path,
            "retryable": True,
        }), 504, cors

    except Exception as e:
        elapsed = (time.monotonic() - start) * 1000
        print(f"[PROXY] FATAL {request.method} {path} → {e} ({elapsed:.0f}ms)")
        traceback.print_exc()
        return jsonify({
            "error": "proxy_error",
            "message": str(e),
            "retryable": False,
        }), 500, cors
