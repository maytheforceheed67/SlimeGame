#!/usr/bin/env python3
"""Checks the content tables in data/ without opening Godot.

Run from the project root:   python3 tools/validate_data.py

It verifies that every file parses, ids are unique snake_case, labels are one
of CANON / DESIGN / UNCONFIRMED, cross-references resolve, rank bands are
contiguous, and every Voice of the World line used by the scripts exists.
Exit code 0 means clean; 1 means at least one problem was printed.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
SCRIPTS = ROOT / "scripts"

LABELS = {"CANON", "DESIGN", "UNCONFIRMED"}
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
VOICE_CALL = re.compile(r"Voice\.(?:say|broadcast|advise|confirm|text)\(\s*\"([a-z0-9_]+)\"")

problems: list[str] = []


def problem(message: str) -> None:
    problems.append(message)


def read(file_name: str) -> dict:
    path = DATA / file_name
    if not path.exists():
        problem(f"{file_name}: file not found")
        return {}
    try:
        root = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        problem(f"{file_name}: line {error.lineno}: {error.msg}")
        return {}
    if not isinstance(root, dict):
        problem(f"{file_name}: top level must be an object")
        return {}
    return root


def check_label(where: str, value: object) -> None:
    if value not in LABELS:
        problem(f"{where}: label must be one of {sorted(LABELS)}, found {value!r}")


def by_id(root: dict, key: str, file_name: str) -> dict[str, dict]:
    table: dict[str, dict] = {}
    entries = root.get(key)
    if not isinstance(entries, list):
        problem(f"{file_name}: '{key}' must be a list")
        return table
    for index, entry in enumerate(entries):
        where = f"{file_name}: {key}[{index}]"
        if not isinstance(entry, dict) or not isinstance(entry.get("id"), str):
            problem(f"{where}: needs a string id")
            continue
        entry_id = entry["id"]
        if not ID_PATTERN.match(entry_id):
            problem(f"{where}: id '{entry_id}' must be snake_case")
        if entry_id in table:
            problem(f"{where}: duplicate id '{entry_id}'")
        table[entry_id] = entry
        check_label(f"{file_name}: {key} '{entry_id}'", entry.get("label"))
    return table


def need(table: dict, ref: object, where: str) -> None:
    if ref in (None, ""):
        return
    if ref not in table:
        problem(f"{where}: unknown id {ref!r}")


def need_all(table: dict, refs: object, where: str) -> None:
    if refs is None:
        return
    if not isinstance(refs, list):
        problem(f"{where}: must be a list")
        return
    for ref in refs:
        need(table, ref, where)


def check_ranks() -> tuple[dict, dict]:
    file_name = "ranks.json"
    root = read(file_name)
    ranks = by_id(root, "ranks", file_name)
    danger = by_id(root, "danger_classes", file_name)
    by_id(root, "informal_labels", file_name)
    by_id(root, "thresholds", file_name)

    bands = [rank for rank in ranks.values() if rank.get("ep_min") is not None]
    bands.sort(key=lambda rank: rank["ep_min"])
    if not bands or bands[0]["ep_min"] != 0:
        problem(f"{file_name}: the lowest EP band must start at 0")
    for lower, upper in zip(bands, bands[1:]):
        if lower.get("ep_max") != upper["ep_min"]:
            problem(
                f"{file_name}: band '{lower['id']}' ends at {lower.get('ep_max')} "
                f"but '{upper['id']}' starts at {upper['ep_min']}"
            )
    if bands and bands[-1].get("ep_max") is not None:
        problem(f"{file_name}: the highest EP band must have ep_max null")
    for rank_id, rank in ranks.items():
        need(danger, rank.get("danger_class"), f"{file_name}: rank '{rank_id}' danger_class")
    return ranks, danger


def check_resistances() -> dict:
    damage_file, resist_file = "damage_types.json", "resistances.json"
    damage = by_id(read(damage_file), "damage_types", damage_file)
    resist_root = read(resist_file)
    resistances = by_id(resist_root, "resistances", resist_file)

    for damage_id, entry in damage.items():
        need(resistances, entry.get("imprint_resistance"), f"{damage_file}: '{damage_id}' imprint_resistance")
        imprint = resistances.get(entry.get("imprint_resistance"), {})
        if imprint and imprint.get("grade") != "resistance":
            problem(f"{damage_file}: '{damage_id}' imprint must be Resistance grade, not Nullification")
    for resist_id, entry in resistances.items():
        if entry.get("grade") not in ("resistance", "nullification"):
            problem(f"{resist_file}: '{resist_id}' grade must be resistance or nullification")
        need_all(damage, entry.get("mitigates"), f"{resist_file}: '{resist_id}' mitigates")

    merges = resist_root.get("merges")
    if not isinstance(merges, list):
        problem(f"{resist_file}: 'merges' must be a list")
        merges = []
    for index, merge in enumerate(merges):
        where = f"{resist_file}: merges[{index}]"
        if not isinstance(merge, dict):
            problem(f"{where}: must be an object")
            continue
        check_label(where, merge.get("label"))
        if not merge.get("inputs"):
            problem(f"{where}: needs at least one input")
        need_all(resistances, merge.get("inputs"), f"{where} inputs")
        if merge.get("result") in (None, ""):
            problem(f"{where}: needs a result")
        need(resistances, merge.get("result"), f"{where} result")
    return resistances


def check_skills() -> dict:
    skill_file, fusion_file = "skills.json", "fusions.json"
    skill_root = read(skill_file)
    categories = by_id(skill_root, "categories", skill_file)
    skills = by_id(skill_root, "skills", skill_file)
    for skill_id, skill in skills.items():
        where = f"{skill_file}: skill '{skill_id}'"
        if skill.get("category") not in categories:
            problem(f"{where}: unknown category {skill.get('category')!r}")
        if "category_label" in skill:
            check_label(f"{where} category_label", skill["category_label"])
        if not isinstance(skill.get("sub_functions", []), list):
            problem(f"{where}: sub_functions must be a list")

    fusions = by_id(read(fusion_file), "fusions", fusion_file)
    for fusion_id, fusion in fusions.items():
        where = f"{fusion_file}: '{fusion_id}'"
        kind = fusion.get("kind")
        inputs = fusion.get("inputs") or []
        if kind not in ("fusion", "evolution"):
            problem(f"{where}: kind must be fusion or evolution")
        if not inputs:
            problem(f"{where}: needs at least one input")
        if kind == "evolution" and len(inputs) != 1:
            problem(f"{where}: an evolution has exactly one input")
        if fusion.get("result") in (None, ""):
            problem(f"{where}: needs a result")
        need_all(skills, fusion.get("inputs"), f"{where} inputs")
        need(skills, fusion.get("result"), f"{where} result")
        need_all(skills, fusion.get("sacrifices"), f"{where} sacrifices")
        need_all(skills, fusion.get("absorbs"), f"{where} absorbs")
    return skills


def check_world(ranks: dict, skills: dict) -> None:
    race_file, region_file, spin_file = "races.json", "regions.json", "spin.json"
    region_root = read(region_file)
    regions = by_id(region_root, "regions", region_file)

    levels = set()
    for index, level in enumerate(region_root.get("density_levels") or []):
        where = f"{region_file}: density_levels[{index}]"
        if not isinstance(level, dict) or not isinstance(level.get("level"), int):
            problem(f"{where}: needs an integer level")
            continue
        if level["level"] in levels:
            problem(f"{where}: duplicate level {level['level']}")
        levels.add(level["level"])
        check_label(where, level.get("label"))
    for region_id, region in regions.items():
        where = f"{region_file}: region '{region_id}'"
        if region.get("magicule_density") not in levels:
            problem(f"{where}: magicule_density {region.get('magicule_density')!r} is not a density level")
        need(regions, region.get("parent"), f"{where} parent")

    race_root = read(race_file)
    races = by_id(race_root, "races", race_file)
    meta = race_root.get("_meta", {})
    for label in (meta.get("default_field_labels") or {}).values():
        check_label(f"{race_file}: _meta.default_field_labels", label)
    stage_ids: set[str] = set()
    for race_id, race in races.items():
        where = f"{race_file}: race '{race_id}'"
        line = race.get("evolution_line") or []
        if not line:
            problem(f"{where}: evolution_line must not be empty")
        elif line[0].get("id") != race_id:
            problem(f"{where}: the first evolution stage must have the race's own id")
        for stage in line:
            stage_id = stage.get("id")
            if not isinstance(stage_id, str) or not isinstance(stage.get("name"), str):
                problem(f"{where}: every evolution stage needs an id and a name")
                continue
            if stage_id in stage_ids:
                problem(f"{where}: stage id '{stage_id}' is used twice across races")
            stage_ids.add(stage_id)
            if "trigger_label" in stage:
                check_label(f"{where} stage '{stage_id}' trigger_label", stage["trigger_label"])
        for label in (race.get("field_labels") or {}).values():
            check_label(f"{where} field_labels", label)
        need(ranks, race.get("base_rank"), f"{where} base_rank")
        need_all(skills, race.get("intrinsic_skills"), f"{where} intrinsic_skills")
        need_all(regions, race.get("spawn_regions"), f"{where} spawn_regions")
        if not race.get("spawn_regions") and not race.get("spawn_rule"):
            problem(f"{where}: needs spawn_regions or a spawn_rule")
        if race.get("magicule_tolerance") not in levels:
            problem(f"{where}: magicule_tolerance must be a density level")
        base_rank = ranks.get(race.get("base_rank"), {})
        base_ep = race.get("base_ep")
        if not isinstance(base_ep, int) or base_ep < 0:
            problem(f"{where}: base_ep must be a non-negative integer")
        elif base_rank.get("ep_min") is not None:
            upper = base_rank.get("ep_max")
            if base_ep < base_rank["ep_min"] or (upper is not None and base_ep >= upper):
                problem(f"{where}: base_ep {base_ep} is outside the band of base_rank '{race.get('base_rank')}'")

    spin_root = read(spin_file)
    origins = by_id(spin_root, "origins", spin_file)
    by_id(spin_root, "affinities", spin_file)
    for origin_id, origin in origins.items():
        need_all(races, origin.get("races"), f"{spin_file}: origin '{origin_id}' races")
    first = spin_root.get("first_life") or {}
    need(races, first.get("race") or "<missing>", f"{spin_file}: first_life race")
    need(regions, first.get("region") or "<missing>", f"{spin_file}: first_life region")
    need(origins, first.get("origin") or "<missing>", f"{spin_file}: first_life origin")
    check_label(f"{spin_file}: first_life", first.get("label"))


def check_voice() -> None:
    file_name = "voice_lines.json"
    lines = read(file_name).get("lines")
    if not isinstance(lines, dict):
        problem(f"{file_name}: 'lines' must be an object")
        return
    for key, text in lines.items():
        if not ID_PATTERN.match(key):
            problem(f"{file_name}: key '{key}' must be snake_case")
        if not isinstance(text, str) or not text.strip():
            problem(f"{file_name}: line '{key}' must be non-empty text")
    used: dict[str, str] = {}
    for script in sorted(SCRIPTS.rglob("*.gd")):
        for key in VOICE_CALL.findall(script.read_text(encoding="utf-8")):
            used.setdefault(key, str(script.relative_to(ROOT)))
    for key, script in used.items():
        if key not in lines:
            problem(f"{script}: uses voice line '{key}' which is missing from {file_name}")
    for key in lines:
        if key not in used:
            print(f"note: voice line '{key}' is not used by any script")


def main() -> int:
    ranks, _danger = check_ranks()
    check_resistances()
    skills = check_skills()
    check_world(ranks, skills)
    check_voice()
    if problems:
        for message in problems:
            print(f"PROBLEM  {message}")
        print(f"\n{len(problems)} problem(s) found.")
        return 1
    print("Data tables are consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
