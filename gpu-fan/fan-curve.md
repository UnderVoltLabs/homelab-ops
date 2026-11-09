# Courbe de ventilateur GPU (Quadro P4000)

Courbe de ventilateur « gaming » pour la box `retrogaming` (HP Z240, Linux Mint 22.3 Cinnamon, driver NVIDIA 580, session X11 auto-login via LightDM).

**Pourquoi :** avec la courbe d'usine (silencieuse), `gpu_burn` montait à 77 °C. Cette courbe fait tourner le ventilateur plus fort, plus tôt.

## La courbe

| Température GPU | Ventilateur |
|---|---|
| 40 °C et moins | 40 % |
| 50 °C | 50 % |
| 60 °C | 65 % |
| 70 °C | 85 % |
| 75 °C et plus | 100 % |

Entre deux points, la vitesse suit une ligne droite. Le ventilateur accélère tout de suite, mais ralentit d'au plus 2 % toutes les 2 s (pas de yo-yo).

## Fichiers

| Fichier | Emplacement sur la box | Rôle |
|---|---|---|
| `gpu-fan-curve.sh` | `/usr/local/bin/` | Le script : lit la température toutes les 2 s et règle le ventilateur |
| `gpu-fan-curve.service` | `/etc/systemd/system/` | Le service systemd : lance le script au démarrage et le relance s'il plante |
| `20-nvidia-coolbits.conf` | `/etc/X11/xorg.conf.d/` | Active Coolbits=4 dans X (autorise le contrôle manuel du ventilateur) |

## Sécurités

- Coolbits=4 débloque uniquement le ventilateur (pas d'overclock, pas de tension).
- Si la température est illisible ou si `nvidia-settings` échoue, le script rend le ventilateur au pilote (mode auto, courbe d'usine).
- À l'arrêt du script (stop, reboot, Ctrl+C), le ventilateur repasse en auto. Si le script est tué (`kill -9`, plantage), le service le remet en auto (`ExecStopPost`) et relance le script après 5 s.
- Dans tous les cas, la carte se protège seule (bridage puis arrêt). Seuils : `nvidia-smi -q -d TEMPERATURE` (lignes « Slowdown » et « Shutdown »).

## Installation

> Les gros blocs collés dans le terminal Windows se mélangent. On copie donc les fichiers avec `scp` au lieu de les coller.

### 1. Activer Coolbits (une seule fois, sur la box)

```bash
sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/20-nvidia-coolbits.conf >/dev/null <<'EOF'
Section "Device"
    Identifier "NVIDIA GPU"
    Driver "nvidia"
    Option "Coolbits" "4"
EndSection
EOF
sudo reboot
```

Vérifier après le reboot : `grep -i coolbits /var/log/Xorg.0.log` doit afficher `"Coolbits" "4"`.

### 2. Envoyer les fichiers (PowerShell, sur le laptop)

```powershell
scp "$HOME\Downloads\gpu-fan-curve.sh" "$HOME\Downloads\gpu-fan-curve.service" retrogaming:/tmp/
```

### 3. Installer et démarrer (sur la box)

```bash
sudo systemctl stop gpu-fan-curve        # seulement si une ancienne version tourne
sudo install -m 755 /tmp/gpu-fan-curve.sh /usr/local/bin/gpu-fan-curve.sh
sudo install -m 644 /tmp/gpu-fan-curve.service /etc/systemd/system/gpu-fan-curve.service
bash -n /usr/local/bin/gpu-fan-curve.sh && echo SCRIPT OK
sudo systemctl daemon-reload
sudo systemctl reenable gpu-fan-curve
sudo systemctl restart gpu-fan-curve
```

## Vérifier

```bash
journalctl -u gpu-fan-curve -n 5 --no-pager      # doit afficher "Fan curve active: ..."
nvidia-smi --query-gpu=temperature.gpu,fan.speed --format=csv -l 2
```

Test de charge (dans une 2e fenêtre SSH) : `cd ~/gpu-burn && ./gpu_burn 120`.

## Modifier la courbe

Modifier la ligne `CURVE=` dans `/usr/local/bin/gpu-fan-curve.sh` (format `température:vitesse`), puis :

```bash
sudo systemctl restart gpu-fan-curve
```

Après une modification du fichier `.service`, faire d'abord `sudo systemctl daemon-reload`.

## Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| Journal : `nvidia-settings failed (X not ready or Coolbits missing)` | Coolbits pas pris par X, ou X pas démarré | Vérifier `grep -i coolbits /var/log/Xorg.0.log` et `pgrep -a Xorg`. Ventilateur en auto en attendant (sans danger) |
| Journal : `Cannot read GPU temperature` | `nvidia-smi` ne répond pas (driver) | Vérifier `nvidia-smi`. Ventilateur en auto en attendant |
| Écran noir après le reboot de l'étape 1 | Config X refusée | Par SSH : `sudo rm /etc/X11/xorg.conf.d/20-nvidia-coolbits.conf && sudo reboot` |
| Doute sur l'index du ventilateur | | `sudo DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -q fans` |

## Désinstaller

```bash
sudo systemctl disable --now gpu-fan-curve
sudo rm /etc/systemd/system/gpu-fan-curve.service /usr/local/bin/gpu-fan-curve.sh
sudo systemctl daemon-reload
# optionnel, puis reboot :
sudo rm /etc/X11/xorg.conf.d/20-nvidia-coolbits.conf
```
