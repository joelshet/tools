#!/bin/sh
# bluf-report — open Zed at ~/hq with README.md focused; its top line names
# the next step (ctrl-shift-space runs the claude BLUF task in Zed's terminal).
set -eu

"/Applications/Zed.app/Contents/MacOS/cli" "$HOME/hq" "$HOME/hq/README.md"
