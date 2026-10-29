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

Runs Proxmox VE. Bought in September 2026 for about $1,560 CAD.

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

### 2026-10-29
- Set up SSH key authentication from the laptop to Proxmox: a dedicated Ed25519 key (`admin-laptop`) for the `admin` user, plus a `proxmox` host alias in the laptop's SSH config.
- Hardened the Proxmox SSH server: root login disabled (`PermitRootLogin no`) and password logins disabled (`PasswordAuthentication no`), so only keys work. The Proxmox web console stays available as a fallback.

### 2026-10-11
- Installed Proxmox and Tailscale.
