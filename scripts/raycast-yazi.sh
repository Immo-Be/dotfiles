#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Yazi
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🗂️
# @raycast.packageName Terminal
# @raycast.description Open Yazi in a new Ghostty window

set -euo pipefail

osascript <<'APPLESCRIPT'
tell application "/Applications/Ghostty.app"
  activate

  set cfg to new surface configuration
  set initial input of cfg to "yazi\n"
  set win to new window with configuration cfg

  activate window win
end tell
APPLESCRIPT
