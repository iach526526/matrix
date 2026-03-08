#!/bin/sh
set -eu

DATA_DIR=/data
CONFIG_FILE="$DATA_DIR/homeserver.yaml"

: "${SYNAPSE_SERVER_NAME:?missing SYNAPSE_SERVER_NAME}"
: "${SYNAPSE_REPORT_STATS:=no}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "homeserver.yaml not found, generating it with migrate_config..."

  /start.py migrate_config

  echo "generated $CONFIG_FILE"
fi

echo "starting synapse with $CONFIG_FILE"
exec /start.py