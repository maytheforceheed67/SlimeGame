#!/usr/bin/env bash
# Lists what has been downloaded into assets_raw/ and, if GODOT is set,
# prints the nodes and animation clips of every model file in it.
# Run it after following ASSETS_TODO.md and paste the output back, so the
# asset manifest can be filled in with real file and clip names.
#
#   GODOT=/path/to/godot tools/inspect_assets.sh > assets_report.txt
set -u
cd "$(dirname "$0")/.."

echo "# Files in assets_raw/"
find assets_raw -type f ! -name '.gdignore' | sort | sed 's/^/  /'

if [ -z "${GODOT:-}" ]; then
	echo
	echo "(Set GODOT to the engine binary to also list each model's nodes and animation clips.)"
	exit 0
fi
models=$(find assets_raw -type f \( -iname '*.glb' -o -iname '*.gltf' -o -iname '*.fbx' \) | sort)
if [ -n "$models" ]; then
	echo
	echo "# Models"
	# shellcheck disable=SC2086
	"$GODOT" --headless --path . --script tools/inspect_model.gd -- $models 2>&1 | grep -v '^Godot Engine'
fi
