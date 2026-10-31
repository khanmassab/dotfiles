#!/usr/bin/env bash
# LANGTU keyboard status for waybar.
#   Bluetooth: real battery %          󰌌 83%
#   Cable:     charging (+% if BT too) 󰌌 󱐋 wired  /  󰌌 󱐋 83%
#   2.4G:      mode only (the receiver doesn't report battery)  󰌌 2.4G
# With "watch", stays running and reprints on USB plug/unplug and Bluetooth changes.
mac="33:9B:B4:36:17:16"
dongle="1a2c:7fff"   # LANGTU 2.4G receiver (vendor:product)
cable="1a2c:7f07"    # LANGTU over USB cable ("SEMICO USB Gaming Keyboard")
kb=$'\U000f030c'     # 󰌌
bolt=$'\U000f140b'   # 󱐋

usb_present() {
    local d
    for d in /sys/bus/usb/devices/*; do
        [ "$(cat "$d/idVendor" 2>/dev/null):$(cat "$d/idProduct" 2>/dev/null)" = "$1" ] && return 0
    done
    return 1
}

emit() {
    local bt_pct="" wired="" dongle_present="" class text tip
    if bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes'; then
        bt_pct=$(bluetoothctl info "$mac" | grep -oP 'Battery Percentage:.*\(\K[0-9]+')
    fi

    usb_present "$cable" && wired=1
    usb_present "$dongle" && dongle_present=1

    class="kbd"
    if [ -n "$wired" ]; then
        text="$kb $bolt ${bt_pct:+$bt_pct%}"; [ -z "$bt_pct" ] && text="$kb $bolt wired"
        tip="Keyboard: wired, charging${bt_pct:+ (battery $bt_pct% via Bluetooth)}"
        class="charging"
    elif [ -n "$bt_pct" ]; then
        text="$kb $bt_pct%"
        tip="Keyboard: Bluetooth, battery $bt_pct%"
        [ "$bt_pct" -le 20 ] && class="low"
    elif [ -n "$dongle_present" ]; then
        text="$kb 2.4G"
        tip="Keyboard: 2.4G receiver (battery not reported in this mode)"
    else
        text=$'\U000f030c'
        tip="Keyboard: not connected"
        class="disconnected"
    fi

    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tip" "$class"
}

if [ "$1" != "watch" ]; then
    emit
    exit
fi

trap 'kill 0' EXIT
dev_path="dev_${mac//:/_}"
emit
{
    udevadm monitor --udev --subsystem-match=hid --subsystem-match=usb &
    gdbus monitor --system --dest org.bluez | grep --line-buffered "$dev_path" &
    wait
} | while true; do
    if read -r -t 60 _; then
        sleep 0.7                          # let a burst of events settle (and battery arrive)
        while read -r -t 0.2 _; do :; done
    fi
    emit
done
