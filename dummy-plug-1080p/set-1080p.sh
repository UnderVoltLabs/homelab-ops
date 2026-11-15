#!/bin/sh
# set-1080p.sh : force la sortie du dummy plug HDMI en 1920x1080 @ 60 Hz.
#
# Pourquoi : sans ce réglage, le dummy plug annonce 4096x2160 @ 29,97 Hz.
# Sunshine streame alors du 4K à 30 Hz et l'interface (Steam Big Picture)
# paraît minuscule dans Moonlight.
#
# Appelé par set-1080p.service juste avant le démarrage de Sunshine.
# Il se lance aussi à la main pour tester : sh ~/.local/bin/set-1080p.sh

# X11 : la session Cinnamon tourne sur l'écran :0 (valeur par défaut
# si le script est lancé depuis SSH sans DISPLAY).
export DISPLAY="${DISPLAY:-:0}"

# Première sortie « connected » de xrandr (DP-7 aujourd'hui). On ne code pas
# le nom en dur : il marche même si le dummy plug change de port.
OUT=$(xrandr | awk '/ connected/{print $1; exit}')

# Si aucune sortie n'est prête (X pas encore démarré), on quitte avec une
# erreur : le service réessaie (Restart=on-failure).
[ -n "$OUT" ] || exit 1

# Applique 1080p60 et marque la sortie comme écran principal.
# Pour 120 FPS dans Moonlight, remplacer 60 par 119.88 (le dummy plug
# accepte aussi 75 Hz) ; 60 Hz reste plus sûr pour la Quadro P4000.
xrandr --output "$OUT" --mode 1920x1080 --rate 60 --primary
