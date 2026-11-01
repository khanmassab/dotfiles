#!/usr/bin/env python3
"""Jump to an app's window if it is open (switching workspace), else launch it here.

  focus-or-launch.py <class-regex> <command...>
  e.g. focus-or-launch.py '^(rice-btop|btop)$' kitty --class btop -e btop

The class regex is matched against both the window's class and initial class.
New windows open on the current workspace.
"""
import json
import re
import subprocess
import sys


def clients():
    out = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True).stdout
    return json.loads(out or "[]")


def focus(window):
    """Focus a window without moving the cursor (Hyprland warps it to the window's center)."""
    pos = subprocess.run(["hyprctl", "cursorpos"], capture_output=True, text=True).stdout.strip()
    subprocess.run(["hyprctl", "dispatch",
                    f'hl.dsp.focus({{window="address:{window["address"]}"}})'],
                   capture_output=True)
    try:
        x, y = (int(v) for v in pos.split(","))
    except ValueError:
        return
    subprocess.run(["hyprctl", "dispatch", f"hl.dsp.cursor.move({{x={x},y={y}}})"],
                   capture_output=True)


def focus_matching(pattern):
    """Focus the most recently used window whose class matches; True if one was found."""
    rx = re.compile(pattern, re.I)
    wins = [c for c in clients() if rx.search(c["class"]) or rx.search(c["initialClass"])]
    if not wins:
        return False
    focus(min(wins, key=lambda c: c["focusHistoryID"]))
    return True


def launch(cmd):
    subprocess.Popen(cmd, start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    if not focus_matching(sys.argv[1]):
        launch(sys.argv[2:])
