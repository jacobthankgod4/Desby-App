"""
Desby API Proxy — Thin relay to Korra AI
==========================================
Forwards all /api/v2/* requests to korra.work.
Converts JSON requests to form data (Korra expects form data).
"""

import os
import json
from datetime import datetime

import requests as http_requests
from flask import Flask, request, jsonify, Response
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app)

KORRA_BASE_URL = os.environ.get("KORRA_API_URL", "https://korra.work")
KORRA_API_KEY = os.environ.get("KORRA_API_KEY", "")


@app.route("/", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "service": "desby-api-proxy",
        "korra_upstream": KORRA_BASE_URL,
        "timestamp": datetime.utcnow().isoformat(),
    })


def _forward(method, target_url, timeout=60):
    """Forward the incoming request to the target URL, converting JSON to form data."""
    headers = {}
    for key in request.headers:
        if key.lower() not in ("host", "content-length", "transfer-encoding", "content-type"):
            headers[key] = request.headers[key]
    if KORRA_API_KEY:
        headers["X-API-Key"] = KORRA_API_KEY

    if request.content_type and "multipart" in request.content_type:
        files = {}
        for key in request.files:
            f = request.files[key]
            files[key] = (f.filename, f.stream, f.content_type)
        return http_requests.request(
            method=method, url=target_url,
            files=files, data=request.form,
            headers=headers, timeout=120,
        )

    if request.content_type and "json" in request.content_type:
        payload = request.get_json(force=True, silent=True) or {}
        return http_requests.request(
            method=method, url=target_url,
            data=payload,
            headers=headers, timeout=timeout,
        )

    if request.data:
        return http_requests.request(
            method=method, url=target_url,
            data=request.data,
            headers=headers, timeout=timeout,
        )

    return http_requests.request(
        method=method, url=target_url,
        params=request.args,
        headers=headers, timeout=timeout,
    )


@app.route("/api/v2/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def proxy_v2(path):
    """Generic proxy: forward any /api/v2/* request to Korra AI."""
    target_url = f"{KORRA_BASE_URL}/api/v2/{path}"
    try:
        resp = _forward(request.method, target_url)
        excluded = {"content-encoding", "content-length", "transfer-encoding", "connection"}
        resp_headers = {k: v for k, v in resp.headers.items() if k.lower() not in excluded}
        return Response(resp.content, status=resp.status_code, headers=resp_headers)
    except http_requests.Timeout:
        return jsonify({"error": "Korra API timeout"}), 504
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def proxy_legacy(path):
    """Legacy proxy: forward /api/* (no v2) to Korra /api/v2/*."""
    if path.startswith("api/"):
        korra_path = path.replace("api/", "api/v2/", 1)
    else:
        korra_path = f"api/v2/{path}"
    target_url = f"{KORRA_BASE_URL}/{korra_path}"
    try:
        resp = _forward(request.method, target_url)
        excluded = {"content-encoding", "content-length", "transfer-encoding", "connection"}
        resp_headers = {k: v for k, v in resp.headers.items() if k.lower() not in excluded}
        return Response(resp.content, status=resp.status_code, headers=resp_headers)
    except http_requests.Timeout:
        return jsonify({"error": "Korra API timeout"}), 504
    except Exception as e:
        return jsonify({"error": str(e)}), 500
