# dotfiles

My Arch + Hyprland rice, based on [LeyzS's dotfiles](https://github.com/L3yzs/By-LeyzS-Arch-Hyprland-Dotfiles), with pywal colors that follow the wallpaper.

## What's in here

| Path | What |
|---|---|
| `.config/hypr/hyprland.lua` | Hyprland config (Lua, Hyprland 0.57+) |
| `.config/hypr/hyprlock.conf`, `hypridle.conf`, `lock.sh` | Lock screen and idle lock |
| `.config/hypr/scripts/` | Wallpaper pickers, pywal → cava colors, startup dashboard |
| `.config/waybar`, `wofi`, `swaync`, `wlogout`, `kitty`, `cava`, `btop`, `fastfetch` | The rest of the rice |
| `.config/wallpapers`, `.config/Live Wallpapers` | Static and video wallpapers |
| `sddm/hyprlock-clone` | SDDM login theme that matches the hyprlock screen |

## Keys added on top of the defaults

| Key | Action |
|---|---|
| SUPER+W | Pick a wallpaper (recolors everything) |
| SUPER+SHIFT+W | Random wallpaper |
| SUPER+K / SUPER+ALT+K | Live video wallpaper |
| SUPER+L | Lock |
| SUPER+SHIFT+P | Power menu |
| SHIFT+Print | Area screenshot to `~/Pictures/Screenshots` |

## Restore on a new machine

```bash
git clone git@github.com:khanmassab/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

## Update the backup

```bash
~/dotfiles/sync.sh
cd ~/dotfiles && git add -A && git commit -m "Update rice" && git push
```

## Other scripts

- `sddm-hyprlock-theme.sh [wallpaper]`: re-render and install the SDDM theme (re-run after changing the wallpaper or profile picture).
- `fix-boot.sh`: makes systemd-boot default to linux-zen and builds the NVIDIA driver for the stock kernel too.
