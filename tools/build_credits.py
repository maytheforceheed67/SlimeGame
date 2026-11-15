#!/usr/bin/env python3
"""Writes CREDITS.md from data/asset_manifest.json.

Run from the project root:   python3 tools/build_credits.py

Every asset the game can show is a manifest entry with a source, a licence
and, where the licence asks for it, an attribution line. This file is the
only place CREDITS.md is written from, so the two can never disagree.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "data" / "asset_manifest.json"
OUT = ROOT / "CREDITS.md"

CATEGORY_TITLES = {
    "characters": "Characters",
    "creatures": "Creatures",
    "props": "Props and pickups",
    "env": "Environment",
    "textures": "Textures",
    "fonts": "Fonts",
    "audio": "Audio",
}


def main() -> None:
    assets = json.loads(MANIFEST.read_text(encoding="utf-8"))["assets"]
    lines = [
        "# Credits",
        "",
        "Generated from `data/asset_manifest.json` by `tools/build_credits.py`. Do not edit by hand.",
        "",
        "This is a personal, non-commercial fan project. Its designs are original;",
        "nothing is taken from any commercial game, show or book. Third-party",
        "assets are used within their licences and listed here.",
        "",
    ]
    third_party = [asset for asset in assets if asset.get("file")]
    lines.append(f"Third-party asset files in use: **{len(third_party)}**.")
    lines.append("")

    by_category: dict[str, list[dict]] = {}
    for asset in assets:
        by_category.setdefault(str(asset.get("category", "other")), []).append(asset)
    for category in sorted(by_category, key=lambda name: list(CATEGORY_TITLES).index(name) if name in CATEGORY_TITLES else 99):
        lines.append(f"## {CATEGORY_TITLES.get(category, category.title())}")
        lines.append("")
        lines.append("| Asset | Source | Licence | Attribution |")
        lines.append("|---|---|---|---|")
        for asset in sorted(by_category[category], key=lambda entry: entry["id"]):
            source = str(asset.get("source") or "")
            if asset.get("url"):
                source = f"[{source}]({asset['url']})"
            lines.append(f"| `{asset['id']}` | {source} | {asset.get('license') or ''} | {asset.get('attribution') or '-'} |")
        lines.append("")

    lines += [
        "## Engine",
        "",
        "Built with [Godot Engine](https://godotengine.org), MIT licence.",
        "",
    ]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(assets)} assets, {len(third_party)} third-party files")


if __name__ == "__main__":
    main()
