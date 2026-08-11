"""
Desby API Proxy — Korra AI relay
"""

import os
import traceback
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

from flask import Flask, request, jsonify, Response

app = Flask(__name__)

KORRA_BASE_URL = os.environ.get("KORRA_API_URL", "https://korra.work")
KORRA_API_KEY = os.environ.get("KORRA_API_KEY", "")


@app.route("/", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "service": "desby-api-proxy",
        "timestamp": datetime.utcnow().isoformat(),
    })


@app.route("/api/v2/<path:subpath>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def proxy_v2(subpath):
    return _relay(f"{KORRA_BASE_URL}/api/v2/{subpath}")


@app.route("/<path:subpath>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def proxy_any(subpath):
    return _relay(f"{KORRA_BASE_URL}/{subpath}")


def _relay(dest):
    fwd = {"X-API-Key": KORRA_API_KEY} if KORRA_API_KEY else {}
    for k in request.headers:
        kl = k.lower()
        if kl not in ("host", "content-length", "transfer-encoding", "x-api-key"):
            fwd[k] = request.headers[k]
    try:
        body = request.get_data()
        r = Request(dest, data=body or None, headers=fwd, method=request.method)
        with urlopen(r, timeout=120) as resp:
            data = resp.read()
            return Response(data, resp.status, {
                k: v for k, v in resp.getheaders()
                if k.lower() not in ("content-length", "transfer-encoding")
            })
    except HTTPError as e:
        return Response(e.read(), e.code, {"Content-Type": "application/json"})
    except Exception as e:
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500
