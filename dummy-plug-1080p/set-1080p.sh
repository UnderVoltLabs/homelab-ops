#!/bin/sh
# Force the dummy plug to 1920x1080 @ 60 Hz.
# Without it, the plug defaults to 4096x2160 @ 30 Hz and Steam looks tiny in Moonlight.
# Run by set-1080p.service before Sunshine starts.

export DISPLAY="${DISPLAY:-:0}"

# First connected output (DP-7 today), so a port change doesn't break it.
OUT=$(xrandr | awk '/ connected/{print $1; exit}')

# Display not ready yet: fail so the service retries.
[ -n "$OUT" ] || exit 1

# For 120 FPS, use --rate 119.88.
xrandr --output "$OUT" --mode 1920x1080 --rate 60 --primary
