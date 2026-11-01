#!/bin/bash
# Restore this rice on a fresh Arch + Hyprland install.
# Assumes yay and the chaotic-aur repo (for wlogout, mpvpaper, grimblast-git, tty-clock, and waybar-git, which speaks Hyprland's Lua IPC so workspace clicks work).
set -e
cd "$(dirname "$0")"

echo "==> Installing packages"
sudo pacman -S --needed hyprland kitty waybar-git wofi awww swaync hyprlock hypridle hyprpolkitagent \
    cava btop cmatrix fastfetch cliphist wl-clipboard grim slurp swappy ffmpeg mpv rsync \
    pavucontrol playerctl brightnessctl network-manager-applet thunar gnome-keyring qt6-wayland papirus-icon-theme \
    ttf-jetbrains-mono-nerd sddm wlogout mpvpaper grimblast-git tty-clock
yay -S --needed python-pywal16

echo "==> Copying configs (existing ones backed up to ~/.config-backup-<date>)"
B="$HOME/.config-backup-$(date +%F-%H%M)"
mkdir -p "$B"
for d in .config/*; do
    n=$(basename "$d")
    [ -e "$HOME/.config/$n" ] && cp -a "$HOME/.config/$n" "$B/"
done
cp -a .config/. "$HOME/.config/"
mkdir -p "$HOME/.local/share/sddm-themes" "$HOME/Pictures/Screenshots"
cp -a sddm/hyprlock-clone "$HOME/.local/share/sddm-themes/"

echo "==> Generating colors from the default wallpaper"
wal -i "$HOME/.config/wallpapers/central.png" -n -q -t -e
cp "$HOME/.config/wallpapers/central.png" "$HOME/.cache/current_wallpaper.png"
"$HOME/.config/hypr/scripts/wal-cava.sh"
python3 -I "$HOME/.config/hypr/scripts/wal-icons.py"
gsettings set org.gnome.desktop.interface icon-theme Papirus-Wal

echo "==> Installing the SDDM login theme"
./sddm-hyprlock-theme.sh
sudo systemctl enable sddm

echo "Done. Check the monitor name in ~/.config/hypr/hyprland.lua, then log in to Hyprland."
