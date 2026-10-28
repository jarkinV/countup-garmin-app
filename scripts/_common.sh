# Shared setup for project scripts. Source it, do not run it.
# - cd to the project root (scripts must run where manifest.xml lives)
# - force JDK 17: jenv exports JAVA_HOME=21 here, and the garmin-dev skill's
#   _env.sh rejects it and does not search ~/Library/Java (where Corretto 17 is)
# - locate the newest installed garmin-dev plugin scripts
ProjectRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ProjectRoot"

if [ -x /usr/libexec/java_home ] && jdk17="$(/usr/libexec/java_home -v 17 2>/dev/null)"; then
  export JAVA_HOME="$jdk17"
fi

GarminScripts="${GARMIN_DEV_SCRIPTS:-$(ls -d "$HOME"/.claude/plugins/cache/garmin-dev-skills/garmin-dev/*/skills/garmin-dev/scripts/posix 2>/dev/null | sort -V | tail -1)}"
if [ -z "$GarminScripts" ] || [ ! -f "$GarminScripts/_env.sh" ]; then
  echo "garmin-dev plugin not found. Install: /plugin marketplace add athitupakan/garmin-dev-skills && /plugin install garmin-dev@garmin-dev-skills" >&2
  exit 1
fi
