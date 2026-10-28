#!/usr/bin/env bash
# Push the release build (bin/<project>-release.prg) to the simulator.
# Long-lived: streams the app log until the app exits.
set -euo pipefail
source "$(dirname "$0")/_common.sh"
source "$GarminScripts/_env.sh"

ReleasePrg="bin/${Project}-release.prg"
[ -f "$ReleasePrg" ] || { echo "$ReleasePrg not found, run scripts/release.sh first" >&2; exit 1; }

if ! pgrep -x simulator >/dev/null; then
  "$Sdk/bin/connectiq" >/dev/null 2>&1 &
  for _ in $(seq 1 30); do pgrep -x simulator >/dev/null && break; sleep 1; done
  sleep 2
fi

exec "$Sdk/bin/monkeydo" "$ReleasePrg" "$Device"
