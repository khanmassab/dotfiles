#!/bin/bash
# Copy the live rice configs into this repo. Run, then: git add -A && git commit && git push
set -e
cd "$(dirname "$0")"
C="$HOME/.config"
mkdir -p .config/hypr sddm
for d in waybar wofi kitty swaync wlogout fastfetch cava btop wallpapers "Live Wallpapers" Kitty-Efeckt Hyprlock-Pfp; do
    rsync -a --delete --exclude '*.bak' --exclude '*.save' "$C/$d/" ".config/$d/"
done
for f in hyprland.lua hyprlock.conf hypridle.conf lock.sh wallpaper-picker.sh; do cp "$C/hypr/$f" .config/hypr/; done
rsync -a --delete "$C/hypr/scripts/" .config/hypr/scripts/
rsync -a --delete "$HOME/.local/share/sddm-themes/hyprlock-clone/" sddm/hyprlock-clone/
echo "Synced."
