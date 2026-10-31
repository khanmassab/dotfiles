#!/bin/bash
# Recreates the screenshot layout: btop | cmatrix / tty-clock / cava (tiled by dwindle)
kitty --class rice-btop btop &
sleep 0.3; kitty --class rice-matrix cmatrix -b -u 6 &
sleep 0.3; kitty --class rice-clock tty-clock -c -C 7 &
sleep 0.3; kitty --class rice-cava cava &
