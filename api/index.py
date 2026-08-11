"""
Desby API Proxy — Thin relay to Korra AI
==========================================
Uses only Python stdlib (no pip dependencies needed).
"""

import os
import json
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from urllib.parse import urlencode

app = __import__("flask").Flask(__name__)

KORRA_BASE_URL = os.environ.get("KORRA_API_URL", "https://korra.work")
KORRA_API_KEY = os.environ.get("KORRA_API_KEY", "")


@app.route("/", methods=["GET"])
def health():
    return __import__("flask").jsonify({
        "status": "ok",
        "service": "desby-api-proxy",
        "korra_upstream": KORRA_BASE_URL,
        "timestamp": datetime.utcnow().isoformat(),
    })


@app.route("/api/v2/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def proxy_v2(path):
    return _forward(f"{KORRA_BASE_URL}/api/v2/{path}")


@app.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def proxy_legacy(path):
    korra_path = path if path.startswith("api/") else f"api/v2/{path}"
    return _forward(f"{KORRA_BASE_URL}/{korra_path}")


def _forward(target_url):
    from flask import request, Response, jsonify

    headers = {}
    for k in request.headers:
        if k.lower() not in ("host", "content-length", "transfer-encoding"):
            headers[k] = request.headers[k]
    if KORRA_API_KEY:
        headers["X-API-Key"] = KORRA_API_KEY

    try:
        body = request.get_data()
        req = Request(target_url, data=body, headers=headers, method=request.method)
        with urlopen(req, timeout=120) as resp:
            resp_body = resp.read()
            resp_headers = {k: v for k, v in resp.headers.items()
                            if k.lower() not in ("content-length", "transfer-encoding", "connection")}
            return Response(resp_body, resp.status, resp_headers)
    except HTTPError as e:
        resp_body = e.read()
        return Response(resp_body, e.code, {"Content-Type": "application/json"})
    except URLError as e:
        return jsonify({"error": str(e.reason)}), 502
    except Exception as e:
        return jsonify({"error": str(e)}), 500
