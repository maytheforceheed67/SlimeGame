#!/usr/bin/env python3
"""Generates scenes/world/sealed_cave.tscn, the greybox Sealed Cave.

Run from the project root:   python3 tools/build_sealed_cave.py

The cave is described below as a grid of 2 m cells: rooms are carved out of
solid rock, then spawn points, harvest spots and lights are placed on them.
Edit CARVE and MARKS and run the script again to reshape the cave. The scene
it writes is an ordinary Godot scene and can also be edited in the editor,
but running this script again overwrites those edits.

Cell kinds
  #  solid rock            .  floor at y = 0
  l  low ledge  (y = 1.5)  L  high ledge (y = 5, reached by clinging)
  w  deep water (bed -3)   u  shallow water (bed -1.2)
  g  squeeze gap: floor at 0 under a 0.6 m ceiling
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "scenes" / "world" / "sealed_cave.tscn"

CELL = 2.0
ROWS, COLS = 44, 56
BOTTOM = -5.0
CEILING = 9.0
WATER_SURFACE = -0.6
FLOOR_Y = {".": 0.0, "l": 1.5, "L": 5.0, "w": -3.0, "u": -1.2, "g": 0.0}
GAP_HEIGHT = 0.6

# (first row, last row, first column, last column, kind); later entries win.
CARVE = [
    (1, 9, 20, 35, "."),     # serpent lair
    (10, 13, 26, 29, "."),   # tunnel: lair to hall
    (14, 26, 18, 37, "."),   # crystal hall (hub)
    (14, 15, 30, 37, "l"),   # low ledge in the hall
    (3, 11, 5, 16, "."),     # spider nook
    (10, 11, 17, 19, "."),   # nook corridor
    (12, 13, 18, 19, "."),
    (16, 30, 1, 14, "."),    # Veldora's chamber
    (20, 23, 15, 17, "."),   # passage: hall to Veldora
    (14, 30, 40, 54, "."),   # lake cavern
    (12, 13, 40, 54, "L"),   # bat roost above the lake
    (19, 21, 38, 39, "."),   # passage: hall to lake
    (15, 28, 44, 53, "w"),   # the lake
    (15, 28, 44, 44, "u"),   # shallow western edge
    (20, 22, 48, 50, "."),   # island
    (27, 30, 26, 29, "."),   # corridor: birth chamber to hall
    (31, 41, 22, 33, "."),   # birth chamber
    (36, 36, 34, 37, "g"),   # squeeze gap to the grotto
    (32, 41, 38, 48, "."),   # herb grotto
]

# (row, column, kind, id). Kinds: spawn (creature id), harvest (item id),
# mote, light (colour name), and the named points "player" and "veldora".
MARKS = [
    (37, 27, "point", "SpawnPoint"),
    (23, 4, "point", "VeldoraSpot"),
    (23, 9, "point", "VeldoraAudience"),
    # where Veldora's voice seems to come from, leading a sightless slime to him
    (32, 27, "point", "VoicePath1"), (25, 27, "point", "VoicePath2"),
    (22, 19, "point", "VoicePath3"), (22, 12, "point", "VoicePath4"),
    (21, 43, "point", "LakeSound"),
    # hipokute herbs
    (33, 24, "harvest", "hipokute_herb"), (40, 31, "harvest", "hipokute_herb"),
    (16, 20, "harvest", "hipokute_herb"), (24, 35, "harvest", "hipokute_herb"),
    (25, 21, "harvest", "hipokute_herb"), (33, 40, "harvest", "hipokute_herb"),
    (34, 45, "harvest", "hipokute_herb"), (38, 42, "harvest", "hipokute_herb"),
    (40, 47, "harvest", "hipokute_herb"), (39, 39, "harvest", "hipokute_herb"),
    (35, 47, "harvest", "hipokute_herb"), (17, 12, "harvest", "hipokute_herb"),
    (29, 12, "harvest", "hipokute_herb"), (28, 3, "harvest", "hipokute_herb"),
    (29, 41, "harvest", "hipokute_herb"), (16, 41, "harvest", "hipokute_herb"),
    # magic ore
    (18, 36, "harvest", "magic_ore"), (26, 19, "harvest", "magic_ore"),
    (14, 33, "harvest", "magic_ore"), (15, 36, "harvest", "magic_ore"),
    (12, 52, "harvest", "magic_ore"), (13, 47, "harvest", "magic_ore"),
    (21, 49, "harvest", "magic_ore"), (2, 21, "harvest", "magic_ore"),
    (8, 34, "harvest", "magic_ore"), (4, 6, "harvest", "magic_ore"),
    (9, 15, "harvest", "magic_ore"),
    # magicule motes
    (34, 30, "mote", ""), (20, 28, "mote", ""), (22, 10, "mote", ""),
    (24, 41, "mote", ""), (11, 27, "mote", ""), (36, 44, "mote", ""),
    (17, 23, "mote", ""), (28, 27, "mote", ""),
    # creatures
    (12, 50, "spawn", "giant_bat"), (13, 53, "spawn", "giant_bat"),
    (16, 54, "spawn", "giant_bat"), (16, 31, "spawn", "giant_bat"),
    (37, 45, "spawn", "evil_centipede"), (40, 41, "spawn", "evil_centipede"),
    (12, 18, "spawn", "evil_centipede"),
    (11, 27, "spawn", "armorsaurus"), (29, 47, "spawn", "armorsaurus"),
    (5, 8, "spawn", "black_spider"), (8, 13, "spawn", "black_spider"),
    (4, 27, "spawn", "tempest_serpent"),
    # crystal lights
    (32, 23, "light", "cyan"), (41, 32, "light", "cyan"),
    (15, 19, "light", "cyan"), (26, 36, "light", "cyan"), (20, 28, "light", "white"),
    (17, 2, "light", "violet"), (29, 2, "light", "violet"), (17, 13, "light", "violet"),
    (14, 41, "light", "cyan"), (30, 53, "light", "cyan"), (21, 49, "light", "white"),
    (2, 34, "light", "green"), (9, 21, "light", "green"),
    (4, 15, "light", "red"), (10, 6, "light", "red"),
    (33, 47, "light", "green"), (41, 39, "light", "green"),
]

LIGHT_COLORS = {
    "cyan": (0.4, 0.85, 1.0),
    "white": (0.75, 0.82, 1.0),
    "violet": (0.7, 0.5, 1.0),
    "green": (0.45, 1.0, 0.6),
    "red": (1.0, 0.45, 0.4),
}


def build_grid() -> list[list[str]]:
    grid = [["#"] * COLS for _ in range(ROWS)]
    for r0, r1, c0, c1, kind in CARVE:
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                grid[r][c] = kind
    for r in range(ROWS):
        for c in range(COLS):
            if (r in (0, ROWS - 1) or c in (0, COLS - 1)) and grid[r][c] != "#":
                raise SystemExit(f"cell ({r}, {c}) opens the edge of the map")
    return grid


def rectangles(grid: list[list[str]], wanted: set[str]) -> list[tuple[int, int, int, int, str]]:
    """Greedy merge of equal cells into rectangles: (row, col, rows, cols, kind)."""
    seen = [[False] * COLS for _ in range(ROWS)]
    found = []
    for r in range(ROWS):
        for c in range(COLS):
            kind = grid[r][c]
            if seen[r][c] or kind not in wanted:
                continue
            width = 1
            while c + width < COLS and grid[r][c + width] == kind and not seen[r][c + width]:
                width += 1
            height = 1
            while r + height < ROWS and all(
                grid[r + height][c + i] == kind and not seen[r + height][c + i] for i in range(width)
            ):
                height += 1
            for rr in range(r, r + height):
                for cc in range(c, c + width):
                    seen[rr][cc] = True
            found.append((r, c, height, width, kind))
    return found


def cell_x(col: float) -> float:
    return (col - COLS / 2) * CELL


def cell_z(row: float) -> float:
    return (row - ROWS / 2) * CELL


def number(value: float) -> str:
    text = f"{value:.4f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


class Scene:
    def __init__(self) -> None:
        self.resources: list[str] = []
        self.nodes: list[str] = []
        self.shapes: dict[tuple, str] = {}
        self.meshes: dict[tuple, str] = {}

    def box(self, name: str, center: tuple[float, float, float], size: tuple[float, float, float], material: str) -> None:
        key = tuple(round(v, 4) for v in size)
        if key not in self.shapes:
            shape_id = f"Shape_{len(self.shapes)}"
            self.shapes[key] = shape_id
            self.resources.append(
                f'[sub_resource type="BoxShape3D" id="{shape_id}"]\nsize = Vector3({", ".join(number(v) for v in size)})\n'
            )
        mesh_key = key + (material,)
        if mesh_key not in self.meshes:
            mesh_id = f"Mesh_{len(self.meshes)}"
            self.meshes[mesh_key] = mesh_id
            self.resources.append(
                f'[sub_resource type="BoxMesh" id="{mesh_id}"]\nmaterial = SubResource("{material}")\n'
                f'size = Vector3({", ".join(number(v) for v in size)})\n'
            )
        origin = ", ".join(number(v) for v in center)
        transform = f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {origin})"
        self.nodes.append(
            f'[node name="{name}" type="MeshInstance3D" parent="Rock"]\ntransform = {transform}\n'
            f'mesh = SubResource("{self.meshes[mesh_key]}")\n'
        )
        self.nodes.append(
            f'[node name="{name}Shape" type="CollisionShape3D" parent="Rock"]\ntransform = {transform}\n'
            f'shape = SubResource("{self.shapes[key]}")\n'
        )


def main() -> None:
    grid = build_grid()
    scene = Scene()
    header = [
        '[gd_scene format=3]\n',
        '[ext_resource type="Script" path="res://scripts/world/level.gd" id="1_level"]',
        '[ext_resource type="Script" path="res://scripts/world/water_volume.gd" id="2_water"]\n',
        '[sub_resource type="Environment" id="Environment_cave"]\nbackground_mode = 1\n'
        'background_color = Color(0.01, 0.014, 0.025, 1)\nambient_light_source = 2\n'
        'ambient_light_color = Color(0.36, 0.44, 0.6, 1)\nambient_light_energy = 0.55\nglow_enabled = true\n'
        'fog_enabled = true\nfog_light_color = Color(0.04, 0.07, 0.12, 1)\nfog_density = 0.008\n',
        '[sub_resource type="StandardMaterial3D" id="Mat_floor"]\nalbedo_color = Color(0.3, 0.33, 0.4, 1)\nroughness = 0.95\n',
        '[sub_resource type="StandardMaterial3D" id="Mat_wall"]\nalbedo_color = Color(0.22, 0.24, 0.31, 1)\nroughness = 1.0\n',
        '[sub_resource type="StandardMaterial3D" id="Mat_ledge"]\nalbedo_color = Color(0.36, 0.38, 0.47, 1)\nroughness = 0.9\n',
        '[sub_resource type="StandardMaterial3D" id="Mat_bed"]\nalbedo_color = Color(0.16, 0.22, 0.3, 1)\nroughness = 1.0\n',
        '[sub_resource type="StandardMaterial3D" id="Mat_water"]\ntransparency = 1\ncull_mode = 2\n'
        'albedo_color = Color(0.2, 0.5, 0.75, 0.5)\nroughness = 0.08\nemission_enabled = true\n'
        'emission = Color(0.05, 0.2, 0.35, 1)\nemission_energy_multiplier = 0.5\n',
    ]
    for name, (red, green, blue) in LIGHT_COLORS.items():
        header.append(
            f'[sub_resource type="StandardMaterial3D" id="Mat_crystal_{name}"]\n'
            f'albedo_color = Color({red}, {green}, {blue}, 1)\nemission_enabled = true\n'
            f'emission = Color({red}, {green}, {blue}, 1)\nemission_energy_multiplier = 2.5\n'
        )
        header.append(
            f'[sub_resource type="BoxMesh" id="Mesh_crystal_{name}"]\nmaterial = SubResource("Mat_crystal_{name}")\n'
            'size = Vector3(0.5, 1.8, 0.5)\n'
        )

    scene.nodes.append('[node name="SealedCave" type="Node3D"]\nscript = ExtResource("1_level")\nregion_id = "sealed_cave"\n')
    scene.nodes.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]\nenvironment = SubResource("Environment_cave")\n')
    scene.nodes.append('[node name="Rock" type="StaticBody3D" parent="."]\n')

    count = 0
    for r, c, rows, cols, kind in rectangles(grid, {"#"}):
        size = (cols * CELL, CEILING - BOTTOM, rows * CELL)
        center = (cell_x(c) + size[0] / 2, (CEILING + BOTTOM) / 2, cell_z(r) + size[2] / 2)
        scene.box(f"Wall{count:03d}", center, size, "Mat_wall")
        count += 1
    count = 0
    materials = {".": "Mat_floor", "g": "Mat_floor", "l": "Mat_ledge", "L": "Mat_ledge", "w": "Mat_bed", "u": "Mat_bed"}
    for r, c, rows, cols, kind in rectangles(grid, set(FLOOR_Y)):
        top = FLOOR_Y[kind]
        size = (cols * CELL, top - BOTTOM, rows * CELL)
        center = (cell_x(c) + size[0] / 2, (top + BOTTOM) / 2, cell_z(r) + size[2] / 2)
        scene.box(f"Floor{count:03d}", center, size, materials[kind])
        if kind == "g":
            lintel = (size[0], CEILING - GAP_HEIGHT, size[2])
            scene.box(f"Lintel{count:03d}", (center[0], (CEILING + GAP_HEIGHT) / 2, center[2]), lintel, "Mat_wall")
        count += 1
    scene.box("Ceiling", (0.0, CEILING + 0.5, 0.0), (COLS * CELL, 1.0, ROWS * CELL), "Mat_wall")

    # Water: one volume per merged rectangle of water cells.
    water_grid = [["w" if cell in "wu" else "#" for cell in row] for row in grid]
    scene.nodes.append('[node name="Water" type="Node3D" parent="."]\n')
    for index, (r, c, rows, cols, _kind) in enumerate(rectangles(water_grid, {"w"})):
        width, depth = cols * CELL, rows * CELL
        height = WATER_SURFACE - FLOOR_Y["w"]
        x, z = cell_x(c) + width / 2, cell_z(r) + depth / 2
        shape_id, mesh_id = f"WaterShape_{index}", f"WaterMesh_{index}"
        header.append(f'[sub_resource type="BoxShape3D" id="{shape_id}"]\nsize = Vector3({number(width)}, {number(height)}, {number(depth)})\n')
        header.append(f'[sub_resource type="PlaneMesh" id="{mesh_id}"]\nmaterial = SubResource("Mat_water")\nsize = Vector2({number(width)}, {number(depth)})\n')
        scene.nodes.append(
            f'[node name="Lake{index}" type="Area3D" parent="Water"]\n'
            f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {number(x)}, {number(WATER_SURFACE - height / 2)}, {number(z)})\n'
            f'collision_layer = 0\ncollision_mask = 2\nscript = ExtResource("2_water")\nsurface_y = {number(WATER_SURFACE)}\n'
        )
        scene.nodes.append(f'[node name="Shape" type="CollisionShape3D" parent="Water/Lake{index}"]\nshape = SubResource("{shape_id}")\n')
        scene.nodes.append(
            f'[node name="Surface" type="MeshInstance3D" parent="Water/Lake{index}"]\n'
            f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {number(height / 2)}, 0)\nmesh = SubResource("{mesh_id}")\n'
        )

    for group in ("Points", "Spawns", "Harvest", "Motes", "Lights"):
        scene.nodes.append(f'[node name="{group}" type="Node3D" parent="."]\n')
    counters: dict[str, int] = {}
    for row, col, kind, ident in MARKS:
        cell = grid[row][col]
        if cell not in FLOOR_Y:
            raise SystemExit(f"mark {kind} {ident} at ({row}, {col}) is inside rock")
        x, y, z = cell_x(col) + CELL / 2, FLOOR_Y[cell], cell_z(row) + CELL / 2
        if kind == "point":
            scene.nodes.append(f'[node name="{ident}" type="Marker3D" parent="Points"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {number(x)}, {number(y + 0.6)}, {number(z)})\n')
            continue
        parent = {"spawn": "Spawns", "harvest": "Harvest", "mote": "Motes", "light": "Lights"}[kind]
        key = f"{parent}:{ident}"
        counters[key] = counters.get(key, 0) + 1
        label = ident if ident else "mote"
        name = f"{label}__{counters[key]:02d}"
        if kind == "light":
            red, green, blue = LIGHT_COLORS[ident]
            scene.nodes.append(
                f'[node name="{name}" type="OmniLight3D" parent="Lights"]\n'
                f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {number(x)}, {number(y + 3.2)}, {number(z)})\n'
                f'light_color = Color({red}, {green}, {blue}, 1)\nlight_energy = 2.2\nomni_range = 17.0\n'
            )
            scene.nodes.append(
                f'[node name="Crystal" type="MeshInstance3D" parent="Lights/{name}"]\n'
                f'transform = Transform3D(0.94, -0.34, 0, 0.34, 0.94, 0, 0, 0, 1, 0, -2.4, 0)\nmesh = SubResource("Mesh_crystal_{ident}")\n'
            )
            continue
        lift = {"spawn": 0.3, "harvest": 0.0, "mote": 0.7}[kind]
        scene.nodes.append(f'[node name="{name}" type="Marker3D" parent="{parent}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {number(x)}, {number(y + lift)}, {number(z)})\n')
    scene.nodes.append('[node name="Spawned" type="Node3D" parent="."]\n')

    OUT.write_text("\n".join(header + scene.resources) + "\n" + "\n".join(scene.nodes), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(scene.nodes)} nodes, {len(scene.shapes)} shapes")
    print("\n".join("".join(row) for row in grid))


if __name__ == "__main__":
    main()
