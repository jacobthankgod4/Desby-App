"""
Desby API Proxy — Korra AI relay
Single catch-all handler.
"""

import os
import sys
import traceback
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import HTTPError

from flask import Flask, request, jsonify, Response

app = Flask(__name__)

KORRA_BASE_URL = os.environ.get("KORRA_API_URL", "https://korra.work")
KORRA_API_KEY = os.environ.get("KORRA_API_KEY", "")


@app.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
@app.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def catch_all(path):
    print(f"[PROXY] {request.method} /{path} -> {KORRA_BASE_URL}/api/v2/{path}", file=sys.stderr)

    if not path:
        return jsonify({
            "status": "ok",
            "service": "desby-api-proxy",
            "timestamp": datetime.utcnow().isoformat(),
        })

    dest = f"{KORRA_BASE_URL}/api/v2/{path}"

    fwd = {}
    if KORRA_API_KEY:
        fwd["X-API-Key"] = KORRA_API_KEY

    try:
        body = request.get_data()
        print(f"[PROXY] body={len(body)}b", file=sys.stderr)
        r = Request(dest, data=body if body else None, headers=fwd, method=request.method)
        with urlopen(r, timeout=120) as resp:
            data = resp.read()
            ct = resp.headers.get("Content-Type", "application/json")
            print(f"[PROXY] ok {resp.status}", file=sys.stderr)
            return Response(data, resp.status, {"Content-Type": ct})
    except HTTPError as e:
        data = e.read()
        print(f"[PROXY] http {e.code}", file=sys.stderr)
        return Response(data, e.code, {"Content-Type": "application/json"})
    except Exception as e:
        print(f"[PROXY] err {e}", file=sys.stderr)
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500
