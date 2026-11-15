#!/bin/sh
# set-1080p.sh: force the HDMI dummy plug output to 1920x1080 @ 60 Hz.
#
# Why: without this, the dummy plug advertises 4096x2160 @ 29.97 Hz.
# Sunshine then streams 4K at 30 Hz and the UI (Steam Big Picture)
# looks tiny in Moonlight.
#
# Run by set-1080p.service right before Sunshine starts.
# It can also be run by hand to test: sh ~/.local/bin/set-1080p.sh

# X11: the Cinnamon session runs on display :0 (default value when the
# script is run over SSH without DISPLAY set).
export DISPLAY="${DISPLAY:-:0}"

# First "connected" output reported by xrandr (DP-7 today). The name is not
# hardcoded, so this still works if the dummy plug moves to another port.
OUT=$(xrandr | awk '/ connected/{print $1; exit}')

# If no output is ready yet (X not started), exit with an error so the
# service retries (Restart=on-failure).
[ -n "$OUT" ] || exit 1

# Apply 1080p60 and make the output the primary display.
# For 120 FPS in Moonlight, replace 60 with 119.88 (the dummy plug also
# accepts 75 Hz); 60 Hz is the safer choice for the Quadro P4000.
xrandr --output "$OUT" --mode 1920x1080 --rate 60 --primary
