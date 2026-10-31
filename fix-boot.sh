#!/bin/bash
# Boot zen by default and build the NVIDIA driver for the stock kernel too.
set -e
# Remove the stray "default arch.conf" line so only "default arch-zen.conf" remains
sudo sed -i '/^default arch\.conf$/d' /boot/loader/loader.conf
grep '^default' /boot/loader/loader.conf
# Headers for the stock kernel: DKMS then builds nvidia-open for it as a fallback
sudo pacman -S --needed linux-headers
dkms status | grep nvidia
echo "Done. Reboot."
