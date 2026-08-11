"""
Desby API Proxy — Korra AI relay
"""

import os
import sys
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
    try:
        print(f"[PROXY] {request.method} {dest}", file=sys.stderr)

        fwd = {}
        if KORRA_API_KEY:
            fwd["X-API-Key"] = KORRA_API_KEY

        body = request.get_data()
        print(f"[PROXY] body_len={len(body)}", file=sys.stderr)

        r = Request(dest, data=body if body else None, headers=fwd, method=request.method)
        with urlopen(r, timeout=120) as resp:
            data = resp.read()
            print(f"[PROXY] upstream {resp.status}, {len(data)} bytes", file=sys.stderr)
            return Response(data, resp.status, {
                "Content-Type": resp.headers.get("Content-Type", "application/json"),
            })
    except HTTPError as e:
        data = e.read()
        print(f"[PROXY] HTTPError {e.code}: {data[:200]}", file=sys.stderr)
        return Response(data, e.code, {"Content-Type": "application/json"})
    except Exception as e:
        tb = traceback.format_exc()
        print(f"[PROXY] Error: {e}\n{tb}", file=sys.stderr)
        return jsonify({"error": str(e)}), 500
