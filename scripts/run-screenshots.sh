#!/usr/bin/env bash
# Build the README screenshot variant (screenshots.jungle: fixed demo events, reset on
# every start) and run it in the simulator. Long-lived: streams the app log until exit.
set -euo pipefail
source "$(dirname "$0")/_common.sh"
source "$GarminScripts/_env.sh"

ShotsPrg="bin/${Project}-screenshots.prg"
mkdir -p bin
"$Sdk/bin/monkeyc" -d "$Device" -f screenshots.jungle -o "$ShotsPrg" -y "$Key" -l 2 -w

if ! pgrep -x simulator >/dev/null; then
  "$Sdk/bin/connectiq" >/dev/null 2>&1 &
  for _ in $(seq 1 30); do pgrep -x simulator >/dev/null && break; sleep 1; done
  sleep 2
fi

exec "$Sdk/bin/monkeydo" "$ShotsPrg" "$Device"
