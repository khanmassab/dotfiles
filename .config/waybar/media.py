#!/usr/bin/env python3
"""Waybar now-playing helper. Follows the player that is actually playing.

  media.py text            JSON for the custom/media module ("artist - title")
  media.py icon            path of that player's app icon, for the image#media module
  media.py playicon        play/pause glyph for the hover controls
  media.py end             right cap of the pill (blank while playing, empty to hide)
  media.py play-pause|next|previous   control that same player
  media.py focus           jump to that player's window (launch the app if it has none)
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


def _gi():
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gio, Gtk
    try:
        gi.require_version("GioUnix", "2.0")
        from gi.repository import GioUnix
        return Gio, Gtk, GioUnix.DesktopAppInfo
    except (ValueError, ImportError):
        return Gio, Gtk, Gio.DesktopAppInfo


def player_names(player):
    """Names the player goes by: "spotify" for org.mpris.MediaPlayer2.spotify,
    "chromium" for chromium.instance1234, Zen's DesktopEntry "zen"."""
    return list(dict.fromkeys(n.lower() for n in (desktop_entry(player), player.split(".")[0]) if n))


def find_apps(player):
    """Installed apps that belong to this player, best match first."""
    Gio, _, DesktopAppInfo = _gi()
    names = player_names(player)
    # 1. exact .desktop file (Zen: zen.desktop). new() raises instead of returning None.
    for n in names:
        try:
            app = DesktopAppInfo.new(f"{n}.desktop")
        except TypeError:
            app = None
        if app:
            yield app

    # 2. any installed app whose id, executable, window class or name matches
    #    (Spotify reports "spotify" but installs spotify-launcher.desktop)
    def fields(app):
        exe = (app.get_executable() or "").rsplit("/", 1)[-1]
        wm = app.get_string("StartupWMClass") if hasattr(app, "get_string") else None
        return [(app.get_id() or "").removesuffix(".desktop"), exe, wm or "", app.get_name() or ""]

    apps = Gio.AppInfo.get_all()
    for exact in (True, False):          # exact field match first, then prefix match
        for app in apps:
            vals = [v.lower() for v in fields(app) if v]
            if any((v == n) if exact else v.startswith(n) for n in names for v in vals):
                yield app


def icon_path(player):
    Gio, Gtk, _ = _gi()
    theme = Gtk.IconTheme.get_default()

    def lookup(gicon):
        info = theme.lookup_by_gicon(gicon, 64, 0) if gicon else None
        return info.get_filename() if info else None

    for app in find_apps(player):
        if path := lookup(app.get_icon()):
            return path
    # an icon theme entry with the player's name, then a generic music icon
    for n in player_names(player) + ["audio-x-generic"]:
        if theme.has_icon(n) and (path := lookup(Gio.ThemedIcon.new(n))):
            return path
    return ""


def player_pid(player):
    out = run("gdbus", "call", "--session", "--dest", "org.freedesktop.DBus",
              "--object-path", "/org/freedesktop/DBus", "--method",
              "org.freedesktop.DBus.GetConnectionUnixProcessID", f"org.mpris.MediaPlayer2.{player}")
    # output looks like: (uint32 2409,)
    digits = "".join(ch for ch in out.split()[-1] if ch.isdigit()) if out else ""
    return int(digits) if digits else None


def ancestors(pid):
    """pid and its parents (a browser's MPRIS may live in a child process)."""
    while pid and pid > 1:
        yield pid
        try:
            with open(f"/proc/{pid}/stat") as f:
                pid = int(f.read().rsplit(")", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            return


def focus_player(player):
    """Jump to the player's window (switching workspace); launch the app if it has none."""
    import re
    import os
    sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
    from importlib import import_module
    fol = import_module("focus-or-launch")

    wins = fol.clients()
    pids = set(ancestors(player_pid(player)))
    match = [c for c in wins if c["pid"] in pids]
    if not match:
        names = player_names(player)
        for app in find_apps(player):
            wm = app.get_string("StartupWMClass") if hasattr(app, "get_string") else None
            names += [n.lower() for n in (wm, (app.get_id() or "").removesuffix(".desktop")) if n]
            break
        rx = re.compile("|".join(f"^{re.escape(n)}$" for n in names), re.I)
        match = [c for c in wins if rx.search(c["class"]) or rx.search(c["initialClass"])]
    if match:
        fol.focus(min(match, key=lambda c: c["focusHistoryID"]))
        return
    # playing but windowless (e.g. Spotify closed to tray): open the app on this workspace
    for app in find_apps(player):
        app.launch([], None)
        return


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "text"
    player = active_player()

    if mode == "focus":
        if player:
            focus_player(player)
        return

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
