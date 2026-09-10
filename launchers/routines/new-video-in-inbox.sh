#!/bin/sh
# open Zed at ~/hq_video with README.md focused; its top line names
# the next step (ctrl-shift-space runs the claude task in Zed's terminal).
set -eu

INBOX="$HOME/hq_video/_inbox"

"/Applications/Zed.app/Contents/MacOS/cli" "$HOME/hq_video" "$HOME/hq_video/README.md"
