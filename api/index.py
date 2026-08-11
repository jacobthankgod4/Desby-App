"""
Desby API Proxy — Thin relay to Korra AI
==========================================
"""

import os
import traceback
from datetime import datetime

import requests as http_requests
from flask import Flask, request, jsonify, Response
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app)

KORRA_BASE_URL = os.environ.get("KORRA_API_URL", "https://korra.work")
KORRA_API_KEY = os.environ.get("KORRA_API_KEY", "")

SKIP_HEADERS = {"host", "content-length", "transfer-encoding"}


@app.route("/", methods=["GET"])
def health():
    return jsonify({
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
    fwd_headers = {}
    for k in request.headers:
        if k.lower() not in SKIP_HEADERS:
            fwd_headers[k] = request.headers[k]
    if KORRA_API_KEY:
        fwd_headers["X-API-Key"] = KORRA_API_KEY

    try:
        body = request.get_data()
        resp = http_requests.request(
            method=request.method,
            url=target_url,
            data=body,
            headers=fwd_headers,
            timeout=120,
        )
        out_headers = {k: v for k, v in resp.headers.items()
                       if k.lower() not in SKIP_HEADERS}
        return Response(resp.content, resp.status_code, out_headers)
    except http_requests.Timeout:
        return jsonify({"error": "Korra API timeout"}), 504
    except Exception as e:
        tb = traceback.format_exc()
        return jsonify({"error": str(e), "trace": tb}), 500
