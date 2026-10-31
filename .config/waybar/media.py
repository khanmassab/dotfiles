#!/usr/bin/env python3
"""Waybar now-playing helper. Follows the player that is actually playing.

  media.py text            JSON for the custom/media module ("artist - title")
  media.py icon            path of that player's app icon, for the image#media module
  media.py playicon        play/pause glyph for the hover controls
  media.py end             right cap of the pill (blank while playing, empty to hide)
  media.py play-pause|next|previous   control that same player
"""
import html
import json
import subprocess
import sys


def run(*args):
    return subprocess.run(args, capture_output=True, text=True).stdout.strip()


def active_player():
    """Playing player first, else a paused one; None when nothing is loaded."""
    paused = None
    for p in run("playerctl", "-l").splitlines():
        status = run("playerctl", "-p", p, "status")
        if status == "Playing":
            return p
        if status == "Paused" and paused is None:
            paused = p
    return paused


def desktop_entry(player):
    """The player's .desktop name (Zen reports itself as 'firefox' but its entry is 'zen')."""
    out = run("gdbus", "call", "--session", "--dest", f"org.mpris.MediaPlayer2.{player}",
              "--object-path", "/org/mpris/MediaPlayer2", "--method",
              "org.freedesktop.DBus.Properties.Get", "org.mpris.MediaPlayer2", "DesktopEntry")
    # output looks like: (<'zen'>,)
    return out.split("'")[1] if "'" in out else player.split(".")[0]


def icon_path(player):
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gio, Gtk

    try:
        gi.require_version("GioUnix", "2.0")
        from gi.repository import GioUnix
        DesktopAppInfo = GioUnix.DesktopAppInfo
    except (ValueError, ImportError):
        DesktopAppInfo = Gio.DesktopAppInfo

    entry = desktop_entry(player)
    app = DesktopAppInfo.new(f"{entry}.desktop")
    icon = app.get_icon() if app else Gio.ThemedIcon.new(entry)
    info = Gtk.IconTheme.get_default().lookup_by_gicon(icon, 64, 0) if icon else None
    if info is None:
        info = Gtk.IconTheme.get_default().lookup_icon("audio-x-generic", 64, 0)
    return info.get_filename() if info else ""


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "text"
    player = active_player()

    if mode in ("play-pause", "next", "previous"):
        if player:
            subprocess.run(["playerctl", "-p", player, mode])
        return

    if mode == "icon":
        # never print nothing: waybar keeps the previous icon on empty output.
        # A path that doesn't exist makes it clear the image and add the "empty" class.
        print((icon_path(player) if player else "") or "none")
        return

    if mode == "playicon":
        playing = player and run("playerctl", "-p", player, "status") == "Playing"
        print("󰏤" if playing else ("󰐊" if player else ""))
        return

    if mode == "end":
        # right cap of the pill: present (a space) only while something is loaded
        print(" " if player else "")
        return

    if not player:
        print(json.dumps({"text": "", "class": "stopped"}))
        return
    artist = run("playerctl", "-p", player, "metadata", "artist")
    title = run("playerctl", "-p", player, "metadata", "title")
    text = f"{artist} - {title}" if artist else title
    status = run("playerctl", "-p", player, "status").lower()
    print(json.dumps({
        "text": html.escape(text),
        "tooltip": html.escape(f"{desktop_entry(player)}: {text}"),
        "class": status,
    }))


if __name__ == "__main__":
    main()
