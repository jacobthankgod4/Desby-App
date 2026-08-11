"""
Desby API Proxy — Thin relay to Korra AI
==========================================
Forwards measurement requests to korra.work API.
No local ML processing — all heavy lifting happens on Korra's servers.
"""

import os
import io
import base64
import json
from datetime import datetime

import requests
from flask import Flask, request, jsonify
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app)

KORRA_BASE_URL = os.environ.get("KORRA_API_URL", "https://korra.work")
KORRA_API_KEY = os.environ.get("KORRA_API_KEY", "")

def korra_headers():
    return {
        "X-API-Key": KORRA_API_KEY,
        "Content-Type": "application/json",
    }

@app.route("/", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "service": "desby-api-proxy",
        "korra_upstream": KORRA_BASE_URL,
        "timestamp": datetime.utcnow().isoformat(),
    })

@app.route("/api/measurements/extract", methods=["POST"])
def extract_measurements():
    """Proxy measurement extraction to Korra AI."""
    try:
        files = {}
        data = {}

        if "front" in request.files:
            front = request.files["front"]
            files["front"] = (front.filename, front.stream, front.content_type)

        if "side" in request.files:
            side = request.files["side"]
            files["side"] = (side.filename, side.stream, side.content_type)

        data["height"] = request.form.get("height", "")
        data["gender"] = request.form.get("gender", "male")

        resp = requests.post(
            f"{KORRA_BASE_URL}/api/v2/measurements/extract",
            files=files,
            data=data,
            headers={"X-API-Key": KORRA_API_KEY},
            timeout=120,
        )

        return jsonify(resp.json()), resp.status_code

    except requests.Timeout:
        return jsonify({"error": "Korra API timeout"}), 504
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/measurements/estimate", methods=["POST"])
def estimate_measurements():
    """Proxy height-based estimation to Korra AI."""
    try:
        payload = request.get_json(force=True)
        resp = requests.post(
            f"{KORRA_BASE_URL}/api/v2/measurements/estimate",
            json=payload,
            headers=korra_headers(),
            timeout=30,
        )
        return jsonify(resp.json()), resp.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/measurements", methods=["GET"])
def list_measurements():
    """Proxy list measurements from Korra AI."""
    try:
        resp = requests.get(
            f"{KORRA_BASE_URL}/api/v2/measurements",
            headers=korra_headers(),
            timeout=15,
        )
        return jsonify(resp.json()), resp.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/measurements/<measurement_id>", methods=["GET"])
def get_measurement(measurement_id):
    """Proxy get measurement from Korra AI."""
    try:
        resp = requests.get(
            f"{KORRA_BASE_URL}/api/v2/measurements/{measurement_id}",
            headers=korra_headers(),
            timeout=15,
        )
        return jsonify(resp.json()), resp.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/measurements/<measurement_id>/pdf", methods=["GET"])
def download_pdf(measurement_id):
    """Proxy PDF download from Korra AI."""
    try:
        resp = requests.get(
            f"{KORRA_BASE_URL}/api/v2/measurements/{measurement_id}/pdf",
            headers=korra_headers(),
            timeout=30,
        )
        return resp.content, resp.status_code, {
            "Content-Type": "application/pdf",
            "Content-Disposition": f'attachment; filename="measurement_{measurement_id}.pdf"',
        }
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/keys/partner-provision", methods=["POST"])
def provision_key():
    """Proxy partner key provisioning to Korra AI."""
    try:
        payload = request.get_json(force=True)
        resp = requests.post(
            f"{KORRA_BASE_URL}/api/v2/keys/partner-provision",
            json=payload,
            headers=korra_headers(),
            timeout=15,
        )
        return jsonify(resp.json()), resp.status_code
    except Exception as e:
        return jsonify({"error": str(e)}), 500
