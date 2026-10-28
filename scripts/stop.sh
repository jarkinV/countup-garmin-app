#!/usr/bin/env bash
# Wrapper for the garmin-dev skill's stop.sh (see scripts/_common.sh)
set -euo pipefail
source "$(dirname "$0")/_common.sh"
exec bash "$GarminScripts/stop.sh" "$@"
