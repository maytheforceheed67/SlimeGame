extends Node
## The visual configuration (autoload "Visual"): every colour, width,
## threshold, tier switch and accessibility setting of the look, read from
## data/visual_config.json. Presentation code asks this for its numbers and
## listens to `changed` so edits made in the F4 panel show at once.
##
##   Visual.color("palette.cave.fog")
##   Visual.number("post.bloom_intensity")
##   Visual.flag("accessibility.reduce_flashes")
##
## Values changed at run time are kept as overrides and can be saved to
## user://visual_overrides.json, which is laid over the shipped file at
## start-up. Game logic never reads this autoload.

## A value changed. `path` is "" when everything was reloaded or reset.
signal changed(path: String)

const CONFIG_PATH := "res://data/visual_config.json"

## Where saved overrides live. Tests point this at a scratch file.
var overrides_path := "user://visual_overrides.json"

var _defaults: Dictionary = {}
var _overrides: Dictionary = {}


func _enter_tree() -> void:
	reload()


## Reads the shipped config and the saved overrides again.
func reload() -> void:
	_defaults = {}
	_flatten(_read(CONFIG_PATH), "", _defaults)
	_overrides = {}
	var saved := _read(overrides_path)
	for path: String in saved:
		if _defaults.has(path) and typeof(saved[path]) == typeof(_defaults[path]):
			_overrides[path] = saved[path]
	changed.emit("")


## The value at a dotted path, or `fallback` if the path is unknown.
func value(path: String, fallback: Variant = null) -> Variant:
	if _overrides.has(path):
		return _overrides[path]
	if _defaults.has(path):
		return _defaults[path]
	push_warning("[Visual] unknown setting '%s'" % path)
	return fallback


func number(path: String, fallback: float = 0.0) -> float:
	var found: Variant = value(path, fallback)
	return float(found) if found is float or found is int else fallback


func flag(path: String, fallback: bool = false) -> bool:
	var found: Variant = value(path, fallback)
	return found if found is bool else fallback


func text(path: String, fallback: String = "") -> String:
	var found: Variant = value(path, fallback)
	return found if found is String else fallback


func color(path: String, fallback: Color = Color.MAGENTA) -> Color:
	var found: Variant = value(path, null)
	if found is String and Color.html_is_valid(found):
		return Color.html(found)
	return fallback


## Changes a value for this session and tells listeners. The new value must
## be of the same kind as the default (number, flag or text).
func set_value(path: String, new_value: Variant) -> bool:
	if not _defaults.has(path):
		return false
	var kind := typeof(_defaults[path])
	if new_value is int and kind == TYPE_FLOAT:
		new_value = float(new_value)
	if typeof(new_value) != kind:
		return false
	if new_value == _defaults[path]:
		_overrides.erase(path)
	else:
		_overrides[path] = new_value
	changed.emit(path)
	return true


func is_overridden(path: String) -> bool:
	return _overrides.has(path)


## Drops one override, or all of them with "".
func reset(path: String = "") -> void:
	if path == "":
		_overrides.clear()
	else:
		_overrides.erase(path)
	changed.emit(path)


## Writes the current overrides to `overrides_path`.
func save_overrides() -> bool:
	var file := FileAccess.open(overrides_path, FileAccess.WRITE)
	if file == null:
		push_error("[Visual] cannot write %s" % overrides_path)
		return false
	file.store_string(JSON.stringify(_overrides, "\t"))
	file.close()
	return true


## Every setting as {"path", "value", "default", "kind"}, in file order.
## kind is "number", "flag", "color" or "text".
func entries() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for path: String in _defaults:
		var current: Variant = value(path)
		var kind := "text"
		if current is bool:
			kind = "flag"
		elif current is float:
			kind = "number"
		elif current is String and current.begins_with("#") and Color.html_is_valid(current):
			kind = "color"
		found.append({"path": path, "value": current, "default": _defaults[path], "kind": kind})
	return found


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not (json.data is Dictionary):
		push_error("[Visual] %s: line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	return json.data


## Turns nested sections into dotted paths: {"fog": {"density": 1}} becomes
## {"fog.density": 1}. Keys starting with "_" are notes, not settings.
func _flatten(section: Dictionary, prefix: String, into: Dictionary) -> void:
	for key: String in section:
		if key.begins_with("_"):
			continue
		var entry: Variant = section[key]
		if entry is Dictionary:
			_flatten(entry, prefix + key + ".", into)
		elif entry is int:
			into[prefix + key] = float(entry)
		else:
			into[prefix + key] = entry
