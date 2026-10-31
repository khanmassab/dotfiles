#!/usr/bin/env bash
# LANGTU keyboard status for waybar.
#   Bluetooth: real battery %          󰌌 83%
#   Cable:     charging (+% if BT too) 󰌌 󱐋  /  󰌌 󱐋 83%
#   2.4G:      mode only (the receiver doesn't report battery)  󰌌 2.4G
#   Off:       dimmed icon
# With "watch", stays running and reprints on USB plug/unplug and Bluetooth changes.
mac="33:9B:B4:36:17:16"
dongle="1a2c:7fff"   # LANGTU 2.4G receiver (vendor:product)
cable="1a2c:7f07"    # LANGTU over USB cable ("SEMICO USB Gaming Keyboard")
kb=$'\U000f030c'     # 󰌌
bolt=$'\U000f140b'   # 󱐋

usb_dir() {
    local d
    for d in /sys/bus/usb/devices/*; do
        [ "$(cat "$d/idVendor" 2>/dev/null):$(cat "$d/idProduct" 2>/dev/null)" = "$1" ] && echo "$d" && return 0
    done
    return 1
}
usb_present() { usb_dir "$1" >/dev/null; }

# The receiver stays plugged in even when the keyboard is off or on Bluetooth, so "2.4G"
# means: the receiver carried traffic (its USB transfer counter moved) in the last 5 minutes.
last_urb="" last_traffic=0
dongle_active() {
    local d urb now
    d=$(usb_dir "$dongle") || return 1
    urb=$(cat "$d/urbnum" 2>/dev/null)
    now=$(date +%s)
    [ -n "$last_urb" ] && [ "$urb" != "$last_urb" ] && last_traffic=$now
    last_urb=$urb
    (( now - last_traffic < 300 ))
}

emit() {
    local info bt_pct="" name class text
    info=$(bluetoothctl info "$mac" 2>/dev/null)
    # tooltip is always the keyboard's name; it stays paired in every mode
    name=$(grep -oP 'Alias: \K.*' <<<"$info"); name=${name:-LANGTU}
    grep -q 'Connected: yes' <<<"$info" && bt_pct=$(grep -oP 'Battery Percentage:.*\(\K[0-9]+' <<<"$info")

    class="kbd"
    if usb_present "$cable"; then
        text="$kb $bolt${bt_pct:+ $bt_pct%}"
        class="charging"
    elif [ -n "$bt_pct" ]; then
        text="$kb $bt_pct%"
        [ "$bt_pct" -le 20 ] && class="low"
    elif dongle_active; then
        text="$kb 2.4G"
    else
        text="$kb"
        class="disconnected"
    fi

    # result goes in OUT (not stdout) so callers keep dongle_active's state
    printf -v OUT '{"text":"%s","tooltip":"%s","class":"%s"}' "$text" "$name" "$class"
}

if [ "$1" != "watch" ]; then
    emit
    echo "$OUT"
    exit
fi

trap 'kill 0' EXIT
dev_path="dev_${mac//:/_}"
last=""
show() { emit; [ "$OUT" != "$last" ] && echo "$OUT"; last=$OUT; }
show
{
    udevadm monitor --udev --subsystem-match=hid --subsystem-match=usb &
    gdbus monitor --system --dest org.bluez | grep --line-buffered "$dev_path" &
    wait
} | while true; do
    # wake on USB/Bluetooth events, or every 5s to check 2.4G traffic
    if read -r -t 5 _; then
        sleep 0.7                          # let a burst of events settle (and battery arrive)
        while read -r -t 0.2 _; do :; done
    fi
    show
done
