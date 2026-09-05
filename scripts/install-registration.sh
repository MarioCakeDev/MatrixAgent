#!/usr/bin/env bash
# Install AS registration into the Matrix service (Coolify-managed Synapse)
# Run this AFTER generate-as-registration.sh
#
# Since Synapse runs inside a Coolify-managed service, we can't directly
# modify homeserver.yaml. Instead, we mount the registration file into the
# Synapse container via Coolify's storage configuration.
#
# Steps:
# 1. The registration file is at /opt/matrix/zooid/registration.yaml
# 2. Mount it into the Synapse container at /data/zooid-registration.yaml
# 3. Add the path to app_service_config_files in homeserver.yaml
# 4. Restart the Matrix service via Coolify
set -euo pipefail

WORKSTATION="agent"
REG_FILE="/opt/matrix/zooid/registration.yaml"

echo "=== AS Registration Installation (Coolify) ==="
echo ""
echo "The registration file is at: ${REG_FILE}"
echo ""
echo "Since Synapse runs inside a Coolify-managed Matrix service,"
echo "manual docker commands won't work. Instead:"
echo ""
echo "1. In Coolify UI, go to the Matrix service → Storage"
echo "2. Add a bind mount:"
echo "   Source: ${REG_FILE}"
echo "   Target: /data/zooid-registration.yaml"
echo ""
echo "3. In the Matrix service → Config → homeserver.yaml (or Synapse config),"
echo "   ensure app_service_config_files includes:"
echo "   - /data/zooid-registration.yaml"
echo ""
echo "4. Restart the Matrix service via Coolify"
echo ""
echo "5. Verify with:"
echo "   docker logs <synapse-container> --tail 20 | grep zooid"
echo ""
echo "Alternatively, if you have SSH access to the worker:"
echo "  docker cp ${REG_FILE} <synapse-container>:/data/zooid-registration.yaml"
echo "  docker restart <synapse-container>"
