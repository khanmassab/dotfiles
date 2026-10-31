#!/bin/bash
# Writes pywal colors into cava's [color] section and tells running cava to reload colors.
CONF="$HOME/.config/cava/config"
mapfile -t C < "$HOME/.cache/wal/colors"
python3 -I - "$CONF" "${C[3]}" "${C[4]}" "${C[7]}" <<'EOF'
import re, sys
conf, c1, c2, c3 = sys.argv[1:]
s = open(conf).read()
block = ("[color]\nbackground = default\nforeground = '%s'\ngradient = 1\ngradient_count = 3\n"
         "gradient_color_1 = '%s'\ngradient_color_2 = '%s'\ngradient_color_3 = '%s'\n\n") % (c2, c1, c2, c3)
s = re.sub(r'^\[color\].*?(?=^\[)', block, s, flags=re.S | re.M)
open(conf, 'w').write(s)
EOF
pkill -USR2 -x cava || true
