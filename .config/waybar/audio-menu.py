#!/usr/bin/env python3
"""Right-click audio context menu for the waybar volume module.

Opens a native GTK menu at the pointer:
  Default output   -> radio list of output devices
  <each playing app> -> submenu with a radio list of output devices
  Open mixer…

A transparent full-screen layer-shell surface hosts the popup so it can appear above
everything, the same way tray menus do; it closes when the menu does.
"""
import json
import subprocess

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell  # noqa: E402


def run(*args):
    return subprocess.run(args, capture_output=True, text=True).stdout


def pactl_json(kind):
    return json.loads(run("pactl", "-f", "json", "list", kind) or "[]")


def radio_sink_items(menu, sinks, current, on_pick):
    """Append one radio item per output device; on_pick(sink_name) runs when one is chosen."""
    group = None
    for s in sinks:
        item = Gtk.RadioMenuItem.new_with_label_from_widget(group, s["description"])
        group = item
        item.set_active(s["name"] == current)
        item.connect("activate", lambda it, name=s["name"]: it.get_active() and on_pick(name))
        menu.append(item)


def header(menu, text):
    item = Gtk.MenuItem(label=text)
    item.set_sensitive(False)
    item.get_style_context().add_class("audio-menu-header")
    menu.append(item)


def build_menu():
    sinks = pactl_json("sinks")
    by_index = {s["index"]: s for s in sinks}
    default = run("pactl", "get-default-sink").strip()
    menu = Gtk.Menu()
    menu.get_style_context().add_class("audio-menu")

    header(menu, "Default output")
    radio_sink_items(menu, sinks, default,
                     lambda name: subprocess.run(["pactl", "set-default-sink", name]))

    menu.append(Gtk.SeparatorMenuItem())
    header(menu, "Apps")
    streams = pactl_json("sink-inputs")
    if not streams:
        empty = Gtk.MenuItem(label="Nothing playing")
        empty.set_sensitive(False)
        menu.append(empty)
    for st in streams:
        p = st["properties"]
        app = p.get("application.name") or p.get("application.process.binary") or "Unknown"
        media = p.get("media.name", "")
        if len(media) > 36:
            media = media[:35] + "…"
        dest = by_index.get(st["sink"], {})
        label = f"{app} — {media}" if media else app
        item = Gtk.MenuItem(label=f"{label}   →  {dest.get('description', '?')}")
        sub = Gtk.Menu()
        sub.get_style_context().add_class("audio-menu")
        radio_sink_items(sub, sinks, dest.get("name"),
                         lambda name, idx=st["index"]: subprocess.run(
                             ["pactl", "move-sink-input", str(idx), name]))
        item.set_submenu(sub)
        menu.append(item)

    menu.append(Gtk.SeparatorMenuItem())
    mixer = Gtk.MenuItem(label="Open mixer…")
    mixer.connect("activate", lambda *_: subprocess.Popen(["pavucontrol"]))
    menu.append(mixer)
    menu.show_all()
    return menu


def pointer_position():
    """Cursor position relative to the monitor it is on."""
    x, y = (int(v) for v in run("hyprctl", "cursorpos").split(","))
    for m in json.loads(run("hyprctl", "monitors", "-j")):
        if m["x"] <= x < m["x"] + m["width"] and m["y"] <= y < m["y"] + m["height"]:
            return x - m["x"], y - m["y"]
    return x, y


def main():
    # read the pointer first: that's where the click happened, before GTK startup delay
    x, y = pointer_position()
    win = Gtk.Window()
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_namespace(win, "audio-menu")
    # hold keyboard focus while open, otherwise focus-follows-mouse closes the menu
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.EXCLUSIVE)
    GtkLayerShell.set_exclusive_zone(win, -1)
    for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                 GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
        GtkLayerShell.set_anchor(win, edge, True)

    # fully transparent host surface
    win.set_app_paintable(True)
    visual = win.get_screen().get_rgba_visual()
    if visual:
        win.set_visual(visual)
    win.connect("draw", lambda w, cr: (cr.set_source_rgba(0, 0, 0, 0), cr.set_operator(1), cr.paint()))
    win.connect("button-press-event", lambda *_: Gtk.main_quit())
    win.connect("key-press-event", lambda w, e: e.keyval == Gdk.KEY_Escape and Gtk.main_quit())

    menu = build_menu()
    menu.attach_to_widget(win, None)
    menu.connect("deactivate", lambda *_: GLib.idle_add(Gtk.main_quit))

    def popup(*_):
        rect = Gdk.Rectangle()
        rect.x, rect.y, rect.width, rect.height = x, y, 1, 1
        menu.popup_at_rect(win.get_window(), rect,
                           Gdk.Gravity.NORTH_WEST, Gdk.Gravity.NORTH_WEST, None)
        return False

    win.connect("map-event", lambda *_: GLib.timeout_add(30, popup))
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
