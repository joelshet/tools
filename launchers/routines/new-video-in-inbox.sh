#!/bin/sh
# open Zed at ~/repos/hq_video with README.md focused; its top line names
# the next step (ctrl-shift-space runs the claude task in Zed's terminal).
set -eu

INBOX="$HOME/repos/hq_video/_inbox"

"/Applications/Zed.app/Contents/MacOS/cli" "$HOME/repos/hq_video" "$HOME/repos/hq_video/README.md"
