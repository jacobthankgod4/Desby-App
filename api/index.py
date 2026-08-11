"""
Desby API Proxy — Thin relay to Korra AI
==========================================
Forwards all /api/v2/* requests to korra.work.
No local ML processing — all heavy lifting happens on Korra's servers.
"""

import os
import re
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


@app.route("/api/v2/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def proxy_v2(path):
    """Generic proxy: forward any /api/v2/* request to Korra AI."""
    target_url = f"{KORRA_BASE_URL}/api/v2/{path}"

    headers = {}
    for key in request.headers:
        if key.lower() not in ("host", "content-length", "transfer-encoding"):
            headers[key] = request.headers[key]
    if KORRA_API_KEY:
        headers["X-API-Key"] = KORRA_API_KEY

    try:
        if request.content_type and "multipart" in request.content_type:
            files = {}
            for key in request.files:
                f = request.files[key]
                files[key] = (f.filename, f.stream, f.content_type)
            resp = http_requests.request(
                method=request.method,
                url=target_url,
                files=files,
                data=request.form,
                headers=headers,
                timeout=120,
            )
        elif request.data:
            resp = http_requests.request(
                method=request.method,
                url=target_url,
                data=request.data,
                headers=headers,
                timeout=60,
            )
        else:
            resp = http_requests.request(
                method=request.method,
                url=target_url,
                params=request.args,
                headers=headers,
                timeout=60,
            )

        excluded_headers = {"content-encoding", "content-length", "transfer-encoding", "connection"}
        resp_headers = {k: v for k, v in resp.headers.items() if k.lower() not in excluded_headers}

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

    headers = {}
    for key in request.headers:
        if key.lower() not in ("host", "content-length", "transfer-encoding"):
            headers[key] = request.headers[key]
    if KORRA_API_KEY:
        headers["X-API-Key"] = KORRA_API_KEY

    try:
        if request.content_type and "multipart" in request.content_type:
            files = {}
            for key in request.files:
                f = request.files[key]
                files[key] = (f.filename, f.stream, f.content_type)
            resp = http_requests.request(
                method=request.method,
                url=target_url,
                files=files,
                data=request.form,
                headers=headers,
                timeout=120,
            )
        elif request.data:
            resp = http_requests.request(
                method=request.method,
                url=target_url,
                data=request.data,
                headers=headers,
                timeout=60,
            )
        else:
            resp = http_requests.request(
                method=request.method,
                url=target_url,
                params=request.args,
                headers=headers,
                timeout=60,
            )

        excluded_headers = {"content-encoding", "content-length", "transfer-encoding", "connection"}
        resp_headers = {k: v for k, v in resp.headers.items() if k.lower() not in excluded_headers}

        return Response(resp.content, status=resp.status_code, headers=resp_headers)

    except http_requests.Timeout:
        return jsonify({"error": "Korra API timeout"}), 504
    except Exception as e:
        return jsonify({"error": str(e)}), 500
