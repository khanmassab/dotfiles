#!/usr/bin/env python3
"""Build ~/.local/share/icons/Papirus-Wal: Papirus-Dark with folder icons tinted to the pywal accent.

Papirus's generic folder icons (folder.svg, folder-documents.svg, user-home.svg, ...) are
symlinks to folder-blue-* variants. We copy those variants under the generic names, swapping
the three blues for shades of the wallpaper accent. Everything else is inherited.
"""
import os
import re
import sys
from pathlib import Path

SRC = Path("/usr/share/icons/Papirus")
DST = Path.home() / ".local/share/icons/Papirus-Wal"
WAL = Path.home() / ".cache/wal/colors"

BLUE_LINK = re.compile(r"^(folder|user)-blue(-|\.)")


def shade(hex_color, f):
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (1, 3, 5))
    return "#%02x%02x%02x" % tuple(min(255, int(c * f)) for c in (r, g, b))


def main():
    colors = WAL.read_text().split()
    accent = sys.argv[1] if len(sys.argv) > 1 else colors[4]
    swap = {
        "#5294e2": accent,             # folder front
        "#4877b1": shade(accent, 0.8),  # folder back
        "#1d344f": shade(accent, 0.3),  # symbol on the folder
    }
    pattern = re.compile("|".join(swap), re.I)

    sections = re.split(r"\n(?=\[)", (SRC / "index.theme").read_text())
    dir_sections = {}
    for sec in sections:
        m = re.match(r"\[([^\]]+)\]", sec)
        if m and m.group(1).endswith("/places"):
            dir_sections[m.group(1)] = sec.strip()

    written_dirs = []
    for rel in sorted(dir_sections):
        places = SRC / rel
        if not places.is_dir():
            continue
        out = DST / rel
        count = 0
        for entry in os.scandir(places):
            if not entry.is_symlink():
                continue
            # follow link chains (folder-public -> folder-publicshare -> folder-blue-image-people)
            target = Path(entry.path).resolve()
            if not BLUE_LINK.match(target.name):
                continue
            svg = target.read_text()
            svg = pattern.sub(lambda m: swap[m.group(0).lower()], svg)
            out.mkdir(parents=True, exist_ok=True)
            tmp = out / (entry.name + ".tmp")
            tmp.write_text(svg)
            os.replace(tmp, out / entry.name)
            count += 1
        if count:
            written_dirs.append(rel)

    index = ["[Icon Theme]", "Name=Papirus-Wal",
             "Comment=Papirus-Dark with folders tinted from the wallpaper",
             "Inherits=Papirus-Dark,Papirus,hicolor",
             "Directories=" + ",".join(written_dirs), ""]
    index += [dir_sections[d] + "\n" for d in written_dirs]
    (DST / "index.theme").write_text("\n".join(index))
    # touching the theme dir tells running GTK apps to rescan
    os.utime(DST)
    print(f"Papirus-Wal: {len(written_dirs)} dirs, accent {accent}")


if __name__ == "__main__":
    main()
