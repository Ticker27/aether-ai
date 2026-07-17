#!/bin/sh
# OTA-in-air: ship a new DNA handbook to a running Aether engine.
# No APK rebuild, no restart — the engine reloads target.json on next round.
#
# Usage: scripts/ota_push.sh <path-to-new-target.json> [device-serial]
#
# The shipped file is validated as JSON here; on-device the engine verifies
# the CIPHER slot (cip_pub) before applying. Auth comes from the adb/device
# session — never echo secrets.
set -e

NEW="${1:?usage: ota_push.sh <new-target.json> [serial]}"
SERIAL="${2:-}"

echo "== validate JSON =="
python3 - "$NEW" <<'PY'
import json, sys
p = sys.argv[1]
try:
    d = json.load(open(p))
    assert "game" in d and "chains" in d, "missing game/chains"
    print("OK: %s chains, game=%s" % (len(d["chains"]), d["game"]))
except Exception as e:
    print("INVALID:", e); sys.exit(1)
PY

DEST=/data/data/com.aether/dna/target.json
if [ -n "$SERIAL" ]; then
  adb -s "$SERIAL" push "$NEW" "$DEST"
else
  adb push "$NEW" "$DEST"
fi
echo "Shipped -> $DEST (engine reloads on next round; no restart)"
