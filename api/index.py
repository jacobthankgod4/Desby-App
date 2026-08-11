"""
Desby API Proxy — Korra AI relay
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
        r = Request(dest, data=body if body else None, headers=fwd, method=request.method)
        with urlopen(r, timeout=120) as resp:
            data = resp.read()
            ct = resp.headers.get("Content-Type", "application/json")
            return Response(data, resp.status, {"Content-Type": ct})
    except HTTPError as e:
        data = e.read()
        return Response(data, e.code, {"Content-Type": "application/json"})
    except Exception as e:
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500
