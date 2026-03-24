#!/bin/sh
set -eu

CONFIG=/data/homeserver.yaml

if [ ! -f "$CONFIG" ]; then
  echo "Generating static config with migrate_config..."
  /start.py migrate_config
fi

python3 - <<'PY'
from pathlib import Path
import yaml

p = Path("/data/homeserver.yaml")
cfg = yaml.safe_load(p.read_text())

# Synapse behind Zeabur reverse proxy: disable direct TLS
cfg["tls_certificate_path"] = None
cfg["tls_private_key_path"] = None

# Replace listeners with a simple HTTP listener behind proxy
cfg["listeners"] = [{
    "port": 8008,
    "type": "http",
    "tls": False,
    "x_forwarded": True,
    "resources": [
        {"names": ["client", "federation"], "compress": False}
    ],
}]

# allow public register. You can change it if you don't want anyone have acess regist on homeserver
cfg["enable_registration"] = True

# require email verify
cfg["email"] = {
    "enable_notifs": True,
    "smtp_host": "smtp.protonmail.ch",
    "smtp_port": 587,
    "smtp_user": "${SMTP_USER}",
    "smtp_pass": "${SMTP_PASSWORD}",
    "require_transport_security": True,
    "notif_from": "%(app)s <${NOTIF_FROM}>",
    "notif_for_new_users": False,
    "client_base_url": "${CLIENT_BASE_URL}",
}
cfg["registrations_require_3pid"] = ["email"]
# email rate limit
cfg["rc_login"] = {
    "per_second": 0.17,
    "burst_count": 3,
}
cfg["serve_server_wellknown"] = True

p.write_text(yaml.safe_dump(cfg, sort_keys=False))
print("patched homeserver.yaml for reverse-proxy / no direct TLS")
PY

exec /start.py
