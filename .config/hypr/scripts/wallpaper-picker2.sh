#!/bin/bash
# * 🌌 L€yzS Ricing - Live Wallpaper & Color Extraction Engine 🌌
# 🛠️  Architected by L€yzS
# 🎥  Dynamic MPV Video Wallpapers with Real-time Palette Sync.
#
# [TR] Bu script, canlı videoları masaüstüne serer ve renkleri videodan çeker.
# [EN] This script sets live videos as wallpaper and extracts colors from the video.

set -eu

# [TR] Video arşivi ve geçici kare yolu / [EN] Video directory and temp frame path
WALL_DIR="/home/massab/.config/Live Wallpapers"
TEMP_THUMB="/tmp/wall_thumb.png"

# [TR] WOFI: Video seçici menüsü / [EN] WOFI: Video selection menu
choice=$(ls "$WALL_DIR" | grep ".mp4" | wofi --dmenu --style "$HOME/.config/wofi/style.css" --prompt "Select Live Wallpaper")

# [TR] Seçim yoksa güvenli çıkış / [EN] Safety exit if no selection
[ -z "$choice" ] && exit 1
VIDEO_PATH="$WALL_DIR/$choice"

# 🛑 1️⃣ [TR] ESKİSİNİ DURDUR: Çakışmayı önlemek için mevcut mpvpaper'ı öldür.
# 🛑 1️⃣ [EN] KILL OLD: Termination of current mpvpaper to prevent conflicts.
pkill mpvpaper || true

# ⚡ 2️⃣ [TR] RENK ÇIKARMA: Videonun ilk karesini yakalayıp palete dönüştür. (Kritik!)
# ⚡ 2️⃣ [EN] COLOR EXTRACTION: Capture the first frame to generate the palette. (Critical!)
ffmpeg -y -i "$VIDEO_PATH" -vframes 1 -f image2 -preset ultrafast -update 1 "$TEMP_THUMB" > /dev/null 2>&1

# 📽️ 3️⃣ [TR] VİDEOYU BAŞLAT: Çift monitör (DP-1 & HDMI-A-1) için optimize edildi.
# 📽️ 3️⃣ [EN] START VIDEO: Optimized for dual-monitor setup (DP-1 & HDMI-A-1).
mpvpaper -o "--loop --hwdec=auto-safe --no-audio" "*" "$VIDEO_PATH" &

# 🌈 4️⃣ [TR] L€yzS SİSTEM SENKRONİZASYONU (Tıp Tıp Sırası)
# 🌈 4️⃣ [EN] L€yzS SYSTEM SYNC (The Famous Sequence)
(
    # [TR] Bildirim merkezini yeni renk şemasına hazırla.
    # [EN] Prepare the notification center for the new color scheme.
    if command -v swaync-client >/dev/null 2>&1; then
        swaync-client -R && swaync-client -rs
    fi

    # [TR] PYWAL: Videodan alınan kareyi sisteme ve terminale enjekte et.
    # [EN] PYWAL: Inject the extracted frame into the system and terminal.
    if command -v wal >/dev/null 2>&1; then
        sleep 0.80
        wal -i "$TEMP_THUMB" -n -q -t -e
        cp "$TEMP_THUMB" "$HOME/.cache/current_wallpaper.png"
        $HOME/.config/hypr/scripts/wal-cava.sh
    fi

    # [TR] Son Dokunuş: Her şeyi senkronize et / [EN] Final Touch: Sync everything.
    if command -v swaync-client >/dev/null 2>&1; then
        swaync-client -R && swaync-client -rs
    fi
) &
