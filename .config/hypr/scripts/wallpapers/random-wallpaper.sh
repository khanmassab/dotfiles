#!/bin/bash
# * 🌌 L€yzS Ricing - Dynamic Wallpaper & Theme Engine 🌌
# 🛠️  Engineered by L€yzS
# 🚀  Random Wallpaper Selection & Global Color Sync.
#
# [TR] Bu script, her basışta sistemi yeniden doğurur. Renkler, bildirimler ve duvar kağıdı senkronize olur.
# [EN] This script breathes new life into the system with every press. Colors, notifications, and wallpaper are synced.

set -eu

# [TR] Wallpaper arşivi / [EN] Wallpaper archive
WALL_DIR="$HOME/.config/wallpapers"

# 🎲 [TR] Şansını Dene: Klasörden rastgele bir şaheser seçiyoruz.
# 🎲 [EN] Roll the Dice: Picking a random masterpiece from the folder.
SELECTED_FILE=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | shuf -n 1)

# [TR] Eğer canlı duvar kağıdı (mpvpaper) aktifse, temiz bir geçiş için onu durdur.
# [EN] If live wallpaper (mpvpaper) is active, kill it for a clean transition.
pkill mpvpaper || true

# [TR] Seçim yapılamadıysa güvenli çıkış / [EN] Safety exit if no file selected
[ -z "$SELECTED_FILE" ] && exit 1
WALL="$SELECTED_FILE"

# 🖼️ 1️⃣ [TR] AWWW ANIMATION: 270Hz tazeleme hızıyla yağ gibi akan geçiş efekti.
# 🖼️ 1️⃣ [EN] AWWW ANIMATION: Silky smooth transition with 270Hz refresh rate.
awww img "$WALL" --transition-type fade --transition-step 255 --transition-fps 270 --transition-duration 0.70

# 🛠️ 2️⃣ [TR] Arka Planda Renk & Bildirim Senkronizasyonu (Gecikmeli İşlem)
# 🛠️ 2️⃣ [EN] Background Color & Notification Sync (Delayed Process)
(
    # [TR] SwayNC: Bildirim merkezine yeni renkleri tanıtır / [EN] Reloading SwayNC colors
    if command -v swaync-client >/dev/null 2>&1; then
        swaync-client -R && swaync-client -rs
    fi

    # [TR] PYWAL: Duvar kağıdındaki renk paletini terminale ve sisteme enjekte eder.
    # [EN] PYWAL: Injects the color palette from the wallpaper into the terminal and system.
    if command -v wal >/dev/null 2>&1; then
        wal -i "$WALL" -n -q -t -e
        # [TR] Cache güncelleme (Kullanıcı adı bağımsız) / [EN] Update cache (User independent)
        cp "$WALL" "$HOME/.cache/current_wallpaper.png"
        $HOME/.config/hypr/scripts/wal-cava.sh
        python3 -I $HOME/.config/hypr/scripts/wal-icons.py >/dev/null
    fi

    # [TR] Son Dokunuş: SwayNC'yi tam senkronize et / [EN] Final Touch: Fully sync SwayNC
    if command -v swaync-client >/dev/null 2>&1; then
        swaync-client -R && swaync-client -rs
    fi
) &
