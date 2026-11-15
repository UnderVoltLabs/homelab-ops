# Dummy plug 1080p

Forces the HDMI dummy plug of the gaming box to 1920x1080 @ 60 Hz before Sunshine starts.

Without it, the dummy plug advertises 4096x2160 @ 29.97 Hz (output `DP-7` today). Sunshine then streams 4K at 30 Hz and Steam Big Picture looks tiny in Moonlight.

## How it works

| File | Installed to | Purpose |
|---|---|---|
| [`set-1080p.sh`](set-1080p.sh) | `~/.local/bin/` | Picks the first connected output with `xrandr` and sets `1920x1080 --rate 60 --primary` |
| [`set-1080p.service`](set-1080p.service) | `~/.config/systemd/user/` | User service (`Type=oneshot`) run before `sunshine.service`, retried up to 5 times if X is not ready |

Unlike [`gpu-fan-curve`](../gpu-fan/fan-curve.md), this is a **user** service: no sudo, but it needs the auto-login session to be running. It is hooked to `sunshine.service` (`WantedBy=sunshine.service`), so the resolution is applied every time Sunshine starts.

Not used: an Xorg `MetaModes` option (more robust, but a wrong value can give a black screen). `Coolbits=4` is unrelated: it only unlocks fan control.

## Install

Copy the two files to the box (for example `scp set-1080p.* retrogaming:/tmp/`), then on the box:

```bash
mkdir -p ~/.local/bin ~/.config/systemd/user
install -m 755 /tmp/set-1080p.sh ~/.local/bin/
install -m 644 /tmp/set-1080p.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable set-1080p
systemctl --user restart sunshine
```

## Verify

```bash
DISPLAY=:0 xrandr | grep -A1 ' connected'   # expect 1920x1080 with 60.00*
systemctl --user status set-1080p
```

In Moonlight, refresh the app list and relaunch Steam Big Picture.

## Change the resolution or refresh rate

Edit the last line of `~/.local/bin/set-1080p.sh`, then `systemctl --user start set-1080p`. For 120 FPS streaming, use `--rate 119.88` (available modes: `xrandr`).

## Lessons learned

- The first attempt used `WantedBy=xdg-desktop-autostart.target`. Cinnamon never triggers it, so after a reboot the output was back to 4096x2160. Hooking to `sunshine.service` fixed it.
- Tested with a Sunshine restart (forced 1920x1200, then back to 1080p60). **A real reboot test is still pending.**

## Sunshine apps

`Low Res Desktop` was removed (it targeted a non-existent `HDMI-1`). Remaining: Desktop, Steam Big Picture, RetroDECK.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Still 4096x2160 after reboot | Service not enabled or auto-login off | `systemctl --user is-enabled set-1080p`, then `systemctl --user start set-1080p` |
| `Cannot open display` in the journal | X not ready | The service retries; check `journalctl --user -u set-1080p` |
| Steam still tiny | Steam kept the old size | Relaunch Steam Big Picture from Moonlight |

## Uninstall

```bash
systemctl --user disable --now set-1080p
rm ~/.config/systemd/user/set-1080p.service ~/.local/bin/set-1080p.sh
systemctl --user daemon-reload
```
