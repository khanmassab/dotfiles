#!/bin/bash
# Install the hyprlock-style SDDM theme. Optional arg: wallpaper to use (default: central.png)
# Re-run after changing wallpaper or ~/.config/Hyprlock-Pfp/picture.jpg to refresh it.
set -e
SRC="$HOME/.local/share/sddm-themes/hyprlock-clone"
WALL="${1:-$HOME/.config/wallpapers/central.png}"
ffmpeg -loglevel error -y -i "$WALL" -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=18,eq=contrast=0.8,lutrgb=r=val*0.5:g=val*0.5:b=val*0.5,vignette=angle=PI/4" "$SRC/background.png"
ffmpeg -loglevel error -y -i "$HOME/.config/Hyprlock-Pfp/picture.jpg" -vf "scale=260:260,format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(lte(hypot(X-129.5,Y-129.5),130),255,0)'" "$SRC/avatar.png"
sudo rm -rf /usr/share/sddm/themes/hyprlock-clone
sudo cp -r "$SRC" /usr/share/sddm/themes/hyprlock-clone
sudo chmod -R a+rX /usr/share/sddm/themes/hyprlock-clone
printf '[Theme]\nCurrent=hyprlock-clone\n' | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
echo "Installed. Login screen now matches hyprlock."
