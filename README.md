# 🏠 homelab-ops

A personal homelab built to practice **DevOps** and **FinOps** end to end:
self-hosting local LLMs, developing my own tools, automating the
infrastructure with **Infrastructure as Code (IaC)**, monitoring
everything, and measuring what it all really costs.

## Hardware

| Component | Model |
|-----------|-------|
| CPU | Intel Core i7-12700KF (12 cores / 20 threads) |
| GPU | NVIDIA RTX 3060 (12 GB VRAM) |
| RAM | 32 GB DDR5 |
| Storage | 1 TB SSD + 256 GB SSD |
| PSU | 1000W 80+ Gold |
| Network switch | UGREEN 8-port 2.5G Ethernet switch (unmanaged, plug & play) |

Runs Proxmox VE. Bought in September 2026 for about $1,560 CAD.

### Network wiring

```
Router ── UGREEN switch ──── Proxmox server
                                   ┆
                                   ┆  Tailscale (SSH), virtual link
                                   ┆
                              Laptop (anywhere)
```

## Stack

**Server**
- Proxmox VE 9.2.2
- Tailscale 1.104.1 for remote access
- Planned: Ubuntu Server VM built with IaC (OpenTofu + Ansible)

**Workstation**
- ThinkPad T16 Gen 2 (AMD) laptop: Ryzen 7 7840U, 32 GB DDR5, 1 TB SSD
- VS Code, with AI coding tools (Claude Pro, GitHub Copilot)
- Manages the server over Tailscale: SSH, and the Proxmox web UI on port 8006
- Runs the IaC tools (OpenTofu, Ansible) from here and applies them to the server over SSH

## Progress

| Step | Status |
|------|--------|
| Install Proxmox | ✅ Done |
| Install Tailscale | ✅ Done |
| Secure SSH (key-only, no root login) | ✅ Done |
| Ubuntu Server VM (IaC) | ⬜ Planned |
| GPU passthrough | ⬜ Planned |
| Docker | ⬜ Planned |
| PostgreSQL | ⬜ Planned |
| Ollama | ⬜ Planned |
| IT cost analyser | ⬜ Planned |

## Log

### 2026-11-08
- Installed a custom GPU fan curve on the retrogaming PC (Quadro P4000, Linux Mint) at about 21:46 (America/Toronto). Coolbits=4 is enabled through `/etc/X11/xorg.conf.d/20-nvidia-coolbits.conf`. The curve is 40 °C: 40 %, 50 °C: 50 %, 60 °C: 65 %, 70 °C: 85 %, 75 °C: 100 %, and it fails safe to the driver's automatic control.
- The `gpu-fan-curve` systemd service starts and reaches X with Coolbits (the `ExecStopPost` reset worked). Still to confirm: the "Fan curve active" journal line and a `gpu_burn` run under load.
- Procedure and scripts: [gpu-fan/fan-curve.md](gpu-fan/fan-curve.md).

### 2026-10-29
- Set up SSH key authentication from the laptop to Proxmox: a dedicated Ed25519 key (`admin-laptop`) for the `admin` user, plus a `proxmox` host alias in the laptop's SSH config.
- Hardened the Proxmox SSH server: root login disabled (`PermitRootLogin no`) and password logins disabled (`PasswordAuthentication no`), so only keys work. The Proxmox web console stays available as a fallback.

### 2026-10-11
- Installed Proxmox and Tailscale.
