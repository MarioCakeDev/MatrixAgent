#!/usr/bin/env bash
# Verify Zooid ↔ Synapse integration
# Run after install-registration.sh and starting the Zooid daemon
set -euo pipefail

WORKSTATION="home"
SERVER="mariocake.de"

echo "=== Verifying Zooid ↔ Synapse integration ==="
echo ""

# 1. Check Synapse is running
SYNAPSE_CONTAINER=$(docker ps --filter "name=synapse" --format "{{.ID}}" | head -1)
if [ -z "${SYNAPSE_CONTAINER}" ]; then
    echo "FAIL: Synapse container not running"
    exit 1
fi
echo "OK: Synapse container running (${SYNAPSE_CONTAINER:0:12})"

# 2. Check registration is in homeserver.yaml
HAS_REG=$(docker exec "${SYNAPSE_CONTAINER}" grep -c "zoooid-registration.yaml" /data/homeserver.yaml || true)
if [ "${HAS_REG}" -eq 0 ]; then
    echo "FAIL: Registration not found in homeserver.yaml"
    exit 1
fi
echo "OK: Registration present in homeserver.yaml"

# 3. Check registration file exists in container
HAS_FILE=$(docker exec "${SYNAPSE_CONTAINER}" test -f /data/zoooid-registration.yaml && echo "yes" || echo "no")
if [ "${HAS_FILE}" != "yes" ]; then
    echo "FAIL: Registration file not in container"
    exit 1
fi
echo "OK: Registration file in container"

# 4. Check Synapse responds
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://matrix.${SERVER}:8008/_matrix/client/versions" || true)
if [ "${HTTP_CODE}" = "200" ]; then
    echo "OK: Synapse responding (HTTP ${HTTP_CODE})"
else
    echo "WARN: Synapse returned HTTP ${HTTP_CODE} — may still be restarting"
fi

# 5. Check agent namespace is reserved (via Synapse admin API if available)
echo ""
echo "=== Manual checks ==="
echo "1. In Ketesa, create agent accounts:"
echo "   - @${WORKSTATION}.architect:${SERVER}"
echo "   - @${WORKSTATION}.coding:${SERVER}"
echo "   - @${WORKSTATION}.devops:${SERVER}"
echo ""
echo "2. Start the Zooid daemon"
echo ""
echo "3. Verify agents appear in Matrix client (Element)"
echo ""
echo "4. Test by @-mentioning an agent in a room"
