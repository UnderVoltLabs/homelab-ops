#!/bin/bash
#
# gpu-fan-curve.sh - custom fan curve for the Quadro P4000
#
# What it does:
#   Every 2 seconds, read the GPU temperature and set the fan speed
#   according to the curve below.
#
# Safety:
#   If anything goes wrong (can't read the temperature, can't talk to X),
#   the fan is handed back to the NVIDIA driver (its default "auto" curve).
#
# Requires: Coolbits=4 in the Xorg config (enables manual fan control).

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

# Fan curve: "temperature:fan_speed" pairs (°C : %).
# Between two points, the speed follows a straight line.
# Below the first point: first speed. Above the last point: last speed.
CURVE="40:40 50:50 60:65 70:85 75:100"

CHECK_EVERY=2   # seconds between checks
MAX_DROP=2      # fan speeds up right away, but slows down by at most 2 % per check

# nvidia-settings needs access to the desktop (X server) to change the fan.
export DISPLAY=:0
export XAUTHORITY=/var/run/lightdm/root/:0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Give fan control back to the NVIDIA driver (default auto curve).
fan_auto() {
  nvidia-settings -a "[gpu:0]/GPUFanControlState=0" >/dev/null 2>&1
}

# Take manual control and set the fan to $1 percent. Fails if X refuses.
fan_set() {
  nvidia-settings -a "[gpu:0]/GPUFanControlState=1" \
                  -a "[fan:0]/GPUTargetFanSpeed=$1" >/dev/null 2>&1
}

# Print the GPU temperature in °C (empty if it can't be read).
gpu_temp() {
  nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null \
    | head -n1 | tr -d '[:space:]'
}

# Print the fan speed (%) for temperature $1, using CURVE.
speed_for_temp() {
  local temp=$1
  local prev_temp=0 prev_speed=0
  local point point_temp point_speed

  for point in $CURVE; do
    point_temp=${point%:*}    # part before ":"
    point_speed=${point#*:}   # part after ":"

    if [ "$temp" -le "$point_temp" ]; then
      if [ "$prev_temp" -eq 0 ]; then
        echo "$point_speed"   # below the first point
      else
        # straight line between the previous point and this one
        echo $(( prev_speed + (point_speed - prev_speed) * (temp - prev_temp) / (point_temp - prev_temp) ))
      fi
      return
    fi

    prev_temp=$point_temp
    prev_speed=$point_speed
  done

  echo "$prev_speed"          # above the last point
}

# On exit (systemctl stop, reboot, Ctrl+C), always give the fan back to the driver.
# kill -9 can't be caught: the systemd unit's ExecStopPost covers that case.
on_exit() {
  trap - EXIT INT TERM
  fan_auto
  echo "Stopped: fan handed back to the driver (auto)"
  exit 0
}
trap on_exit EXIT INT TERM

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

current_speed=0   # last speed we set (0 = none, driver in control)
status=""         # last status logged, so the journal only shows changes

while sleep "$CHECK_EVERY"; do
  temp=$(gpu_temp)

  # 1. Can't read the temperature? Don't guess: hand the fan back to the driver.
  if ! [[ $temp =~ ^[0-9]+$ ]]; then
    fan_auto
    current_speed=0
    [ "$status" != no_temp ] && echo "Cannot read GPU temperature: fan set to auto" >&2
    status=no_temp
    continue
  fi

  # 2. Target speed from the curve.
  target=$(speed_for_temp "$temp")

  # 3. Going down? Drop by MAX_DROP at most (avoids the fan pulsing up and down).
  if [ "$target" -lt $(( current_speed - MAX_DROP )) ]; then
    target=$(( current_speed - MAX_DROP ))
  fi

  # 4. Apply it. Manual mode is re-applied every time, in case X restarted
  #    (an X restart puts the driver back in auto).
  if fan_set "$target"; then
    [ "$status" != ok ] && echo "Fan curve active: ${temp} °C, fan ${target} %"
    status=ok
    current_speed=$target
  else
    fan_auto
    current_speed=0
    [ "$status" != no_x ] && echo "nvidia-settings failed (X not ready or Coolbits missing): fan set to auto" >&2
    status=no_x
  fi
done
