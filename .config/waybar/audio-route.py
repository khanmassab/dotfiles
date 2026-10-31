#!/usr/bin/env python3
"""Waybar right-click audio menu: route each playing app to an output, or change the default.

Step 1 (wofi): pick "Default output" or a playing app.
Step 2 (wofi): pick the output device; the app's stream is moved there.
"""
import html
import json
import subprocess
from pathlib import Path

WOFI = ["wofi", "--dmenu", "--insensitive", "--cache-file", "/dev/null",
        "--style", str(Path.home() / ".config/wofi/style.css")]
DEFAULT_ROW = "󰓃  Default output"
MIXER_ROW = "󰝚  Open mixer (pavucontrol)"


def pactl_json(kind):
    out = subprocess.run(["pactl", "-f", "json", "list", kind],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def pick(prompt, rows):
    """Show rows in wofi; return the chosen row's key, or None if cancelled."""
    labels = {label: key for key, label in rows}
    res = subprocess.run(WOFI + ["--prompt", prompt, "--lines", str(min(len(rows), 10))],
                         input="\n".join(labels), capture_output=True, text=True)
    return labels.get(res.stdout.strip())


def sink_icon(sink):
    name = sink["name"]
    if name.startswith("bluez_"):
        return ""
    if "hdmi" in name or "TU116" in sink["description"]:  # NVIDIA card = monitor speakers
        return "󰍹"
    if "usb" in name:
        return "󰋋"
    return "󰓃"


def main():
    sinks = pactl_json("sinks")
    by_index = {s["index"]: s for s in sinks}
    default = subprocess.run(["pactl", "get-default-sink"],
                             capture_output=True, text=True).stdout.strip()
    default_desc = next((s["description"] for s in sinks if s["name"] == default), default)

    rows = [("default", f"{DEFAULT_ROW}  →  {html.escape(default_desc)}")]
    for st in pactl_json("sink-inputs"):
        p = st["properties"]
        app = p.get("application.name") or p.get("application.process.binary") or "Unknown"
        media = p.get("media.name", "")
        if len(media) > 40:
            media = media[:39] + "…"
        dest = by_index.get(st["sink"], {}).get("description", "?")
        rows.append((st["index"], html.escape(f"  {app} — {media}  →  {dest}")))
    rows.append(("mixer", MIXER_ROW))

    choice = pick("Route audio", rows)
    if choice is None:
        return
    if choice == "mixer":
        subprocess.Popen(["pavucontrol"])
        return

    if choice == "default":
        current = default
    else:
        st = next(s for s in pactl_json("sink-inputs") if s["index"] == choice)
        current = by_index.get(st["sink"], {}).get("name")

    out_rows = [(s["name"], html.escape(
        f"{'●' if s['name'] == current else '  '} {sink_icon(s)}  {s['description']}")) for s in sinks]
    target = pick("Output", out_rows)
    if target is None:
        return

    if choice == "default":
        subprocess.run(["pactl", "set-default-sink", target])
    else:
        subprocess.run(["pactl", "move-sink-input", str(choice), target])


if __name__ == "__main__":
    main()
