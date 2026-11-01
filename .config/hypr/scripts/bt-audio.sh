#!/usr/bin/env bash
# Keep Bluetooth headphones usable as a sound output.
# AirPods sometimes reset the audio (A2DP) channel while connecting; the device then shows
# as connected but has no output, or its card is left on profile "off". On every Bluetooth
# connect this checks each connected audio device and repairs it:
#   card exists but profile off -> switch to the best A2DP profile
#   no card at all             -> ask the device for the A2DP channel again (a few tries)
A2DP="0000110d-0000-1000-8000-00805f9b34fb"
SINK_UUID="0000110b-0000-1000-8000-00805f9b34fb"

fix_device() {
    local mac=$1 card=bluez_card.${1//:/_} try profile
    for try in 1 2 3 4; do
        sleep 3
        bluetoothctl info "$mac" | grep -q 'Connected: yes' || return
        profile=$(pactl -f json list cards 2>/dev/null | python3 -I -c "
import json, sys
for c in json.load(sys.stdin):
    if c['name'] == '$card':
        best = max((p for n, p in c['profiles'].items() if n.startswith('a2dp') and p['available']),
                   key=lambda p: p['priority'], default=None)
        names = [n for n, p in c['profiles'].items() if p is best]
        print(c['active_profile'], names[0] if names else '')")
        if [ -z "$profile" ]; then                      # no audio card: retry the channel
            bluetoothctl connect "$mac" "$A2DP" >/dev/null 2>&1
        elif [ "${profile%% *}" = "off" ] && [ -n "${profile#* }" ]; then
            pactl set-card-profile "$card" "${profile#* }"
        else
            return                                      # has a working profile
        fi
    done
}

check_all() {
    local mac
    for mac in $(bluetoothctl devices Connected | awk '{print $2}'); do
        bluetoothctl info "$mac" | grep -q "$SINK_UUID" && fix_device "$mac" &
    done
    wait
}

check_all
# re-check whenever any Bluetooth device's Connected property changes
gdbus monitor --system --dest org.bluez | grep --line-buffered "'Connected'" |
while read -r _; do
    check_all
done
