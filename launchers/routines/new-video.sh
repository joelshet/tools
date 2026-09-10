#!/bin/sh
# new-video — move the newest video in ~/Downloads to ~/hq_video/_inbox,
# then open Zed at ~/hq_video with README.md focused; its top line names
# the next step (ctrl-shift-space runs the claude task in Zed's terminal).
set -eu

INBOX="$HOME/hq_video/_inbox"

newest=$(find "$HOME/Downloads" -maxdepth 1 -type f \
    \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.mkv' -o -iname '*.webm' \) \
    -exec stat -f '%m %N' {} + | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$newest" ]; then
    echo "no video files in ~/Downloads" >&2
    exit 1
fi

mv "$newest" "$INBOX/"

"/Applications/Zed.app/Contents/MacOS/cli" "$HOME/hq_video" "$HOME/hq_video/README.md"
