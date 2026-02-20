#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# bootstrap.sh — UserData script for Amazon Linux 2 (WORKING baseline)
#
# This script runs automatically on first boot when EC2 launches.
# It installs Python3, pip, Flask, and starts a simple Flask health-check app.
#
# IMPORTANT: This script is written for Amazon Linux 2.
# When we later swap to Amazon Linux 2023, specific commands here will break
# (yum vs dnf, package naming differences) — that is the intentional scenario
# we will use to test the Bedrock healing pipeline in Phase 2+.
# ─────────────────────────────────────────────────────────────────────────────

set -e  # Stop immediately if any command fails — makes errors visible in logs

echo "=== Bootstrap started at $(date) ==="
echo "=== Running on AMI: $(curl -s http://169.254.169.254/latest/meta-data/ami-id) ==="

# ─── Step 1: Update system packages ──────────────────────────────────────────
echo "--- Updating system packages ---"
yum update -y

# ─── Step 2: Install Python3 and pip ─────────────────────────────────────────
# On Amazon Linux 2, python3-pip is available via yum in the base repo
# NOTE: This line WILL BREAK on Amazon Linux 2023 (that's the scenario)
echo "--- Installing Python3 and pip ---"
yum install -y python3 python3-pip

python3 --version
pip3 --version

# ─── Step 3: Install Flask ────────────────────────────────────────────────────
echo "--- Installing Flask ---"
pip3 install flask

# ─── Step 4: Write the Flask application ─────────────────────────────────────
echo "--- Writing application files ---"
mkdir -p /opt/app

cat > /opt/app/app.py << 'EOF'
from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.route('/health')
def health():
    """ALB health check endpoint — must return HTTP 200"""
    return jsonify({
        "status": "healthy",
        "hostname": socket.gethostname(),
        "instance_id": os.popen("curl -s http://169.254.169.254/latest/meta-data/instance-id").read()
    }), 200

@app.route('/')
def home():
    return jsonify({
        "message": "App is running",
        "host": socket.gethostname()
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# ─── Step 5: Create systemd service ──────────────────────────────────────────
echo "--- Creating systemd service ---"

cat > /etc/systemd/system/flaskapp.service << 'EOF'
[Unit]
Description=Flask Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

chown -R ec2-user:ec2-user /opt/app

# ─── Step 6: Enable and start the app ────────────────────────────────────────
echo "--- Starting Flask application ---"
systemctl daemon-reload
systemctl enable flaskapp
systemctl start flaskapp

# ─── Step 7: Verify the app is responding ────────────────────────────────────
echo "--- Verifying app health endpoint ---"
sleep 3
curl -f http://localhost:8080/health && echo "=== App is healthy ===" || echo "=== WARNING: App health check failed ==="

echo "=== Bootstrap completed at $(date) ==="
