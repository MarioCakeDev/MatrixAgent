#!/usr/bin/env bash
# Generate Application Service registration for Zooid workstation "agent"
# Run this ONCE on the Coolify worker (Home Worker 01)
set -euo pipefail

WORKSTATION="agent"
BASE_DIR="/opt/matrix/zooid"
REG_FILE="${BASE_DIR}/registration.yaml"
ENV_FILE="${BASE_DIR}/.env"

mkdir -p "${BASE_DIR}"

echo "Generating AS registration for workstation: ${WORKSTATION}"

# Generate cryptographically random tokens (never echoed)
AS_TOKEN=$(openssl rand -hex 32)
HS_TOKEN=$(openssl rand -hex 32)

# Write registration file (contains secrets — chmod 600)
# url: where Synapse pushes events to the daemon (through Traefik)
# exclusive: false — allows human registrations on the same homeserver
cat > "${REG_FILE}" <<EOF
id: ${WORKSTATION}
url: "http://zooid.coolify.lan"
as_token: "${AS_TOKEN}"
hs_token: "${HS_TOKEN}"
sender_localpart: "zooid"
namespaces:
  users:
    - exclusive: false
      regex: "@${WORKSTATION}\\..*:mariocake\\.de"
  aliases: []
  rooms: []
EOF
chmod 600 "${REG_FILE}"

# Write env file for Zooid daemon (contains secrets — chmod 600)
cat > "${ENV_FILE}" <<EOF
MATRIX_AS_TOKEN=${AS_TOKEN}
MATRIX_HS_TOKEN=${HS_TOKEN}
EOF
chmod 600 "${ENV_FILE}"

echo "=== Registration generated ==="
echo "Files created:"
echo "  ${REG_FILE}  (for Synapse)"
echo "  ${ENV_FILE}  (for Zooid daemon)"
echo ""
echo "Both files are chmod 600. Keep them secure."
echo ""
echo "Next step: install the registration into the Matrix service."
echo "Since Synapse runs inside a Coolify service, mount the registration"
echo "file via Coolify's storage config or copy it into the service volume."
