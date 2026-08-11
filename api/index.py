"""
Desby API Proxy — echo test
"""

import os
import sys
from datetime import datetime

from flask import Flask, request, jsonify, Response

app = Flask(__name__)


@app.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
@app.route("/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
def catch_all(path):
    return jsonify({
        "method": request.method,
        "path": path,
        "url": request.url,
        "full_path": request.full_path,
        "remote_addr": request.remote_addr,
        "timestamp": datetime.utcnow().isoformat(),
    })
