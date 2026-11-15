#!/usr/bin/env bash
# Renders a capture stage to a PNG on a virtual display.
#   tools/capture.sh <stage> <output-directory>
# Needs xvfb-run. Set GODOT to the engine binary if it is not on PATH.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3 --fixed-fps 60 --path . \
	res://tests/capture.tscn -- --stage="$1" --out="$2" 2>&1 | grep -E "saved|ERROR|SCRIPT|at:|unknown stage"
