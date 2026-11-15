#!/usr/bin/env bash
# Runs the data validator and every headless test scene.
#   tools/run_tests.sh            all tests
#   tools/run_tests.sh foundation one test (tests/test_foundation.tscn)
# Set GODOT to the engine binary if it is not on PATH as "godot".
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
failed=0

python3 tools/validate_data.py | grep -v '^note:' || failed=1
"$GODOT" --headless --path . --import >/dev/null 2>&1

if [ $# -gt 0 ]; then
	scenes=("tests/test_$1.tscn")
else
	scenes=(tests/test_*.tscn)
fi
for scene in "${scenes[@]}"; do
	echo "== $scene"
	if ! "$GODOT" --headless --fixed-fps 60 --path . "res://$scene" 2>&1 | grep -v '^Godot Engine\|^$\|^\[Database\]'; then
		:
	fi
	[ "${PIPESTATUS[0]}" -eq 0 ] || failed=1
done
exit $failed
