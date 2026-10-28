#!/usr/bin/env bash
# Build with unit tests and run them in the simulator.
# Usage: scripts/test.sh [Module.testFunction]
set -euo pipefail
source "$(dirname "$0")/_common.sh"
source "$GarminScripts/_env.sh"

TestPrg="bin/${Project}-test.prg"
"$Sdk/bin/monkeyc" -d "$Device" -f "$Jungle" -o "$TestPrg" -y "$Key" -l 2 -w --unit-test

if ! pgrep -x simulator >/dev/null; then
  "$Sdk/bin/connectiq" >/dev/null 2>&1 &
  for _ in $(seq 1 30); do pgrep -x simulator >/dev/null && break; sleep 1; done
  sleep 2
fi

# macOS/Linux monkeydo takes -t (the docs show the Windows form /t)
"$Sdk/bin/monkeydo" "$TestPrg" "$Device" -t ${1:-}
