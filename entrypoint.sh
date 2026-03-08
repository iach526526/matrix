#!/bin/sh
set -eu

DATA_DIR=/data

: "${SYNAPSE_SERVER_NAME:?missing SYNAPSE_SERVER_NAME}"
: "${SYNAPSE_REPORT_STATS:=no}"

if [ ! -f "$DATA_DIR/homeserver.yaml" ]; then
  echo "homeserver.yaml not found, generating initial config..."
  python -m synapse.app.homeserver \
    --server-name "$SYNAPSE_SERVER_NAME" \
    --config-path "$DATA_DIR/homeserver.yaml" \
    --generate-config \
    --report-stats "$SYNAPSE_REPORT_STATS"
fi

exec python -m synapse.app.homeserver \
  --config-path "$DATA_DIR/homeserver.yaml"
