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

open -na Ghostty.app --args -e /bin/zsh -lic yazi
