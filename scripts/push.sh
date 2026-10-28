#!/usr/bin/env bash
# Wrapper for the garmin-dev skill's push.sh (see scripts/_common.sh)
set -euo pipefail
source "$(dirname "$0")/_common.sh"
exec bash "$GarminScripts/push.sh" "$@"
