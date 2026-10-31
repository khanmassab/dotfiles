#!/usr/bin/env bash
mac="33:9B:B4:36:17:16"
pct=$(bluetoothctl info "$mac" | grep -oP 'Battery Percentage:.*\(\K[0-9]+')

[ -z "$pct" ] && { echo '{"text":"󰥇","tooltip":"keyboard disconnected"}'; exit; }

if   [ "$pct" -ge 90 ]; then ico=""
elif [ "$pct" -ge 60 ]; then ico=""
elif [ "$pct" -ge 40 ]; then ico=""
elif [ "$pct" -ge 15 ]; then ico=""
else ico=""; fi

echo "{\"text\":\" $ico ${pct}%\",\"tooltip\":\"Keyboard: ${pct}%\",\"class\":\"kbd\"}"

