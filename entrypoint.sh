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

p.write_text(yaml.safe_dump(cfg, sort_keys=False))
print("patched homeserver.yaml for reverse-proxy / no direct TLS")
PY

exec /start.py