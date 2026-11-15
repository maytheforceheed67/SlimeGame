class_name UiStyle
extends RefCounted
## Shared look of the interface: flat, thin-bordered, quiet. One place to
## change colours and label styling for every HUD panel.

const WORLD_COLOR := Color(0.9, 0.93, 0.96)
const BROADCAST_COLOR := Color(1.0, 0.86, 0.55)
const ADVISOR_COLOR := Color(0.55, 0.92, 0.85)
const MUTED_COLOR := Color(0.62, 0.68, 0.76)
const WARNING_COLOR := Color(1.0, 0.5, 0.45)
const PANEL_BACKGROUND := Color(0.03, 0.05, 0.08, 0.72)
const PANEL_BORDER := Color(0.6, 0.7, 0.8, 0.35)


static func panel_box(border: Color = PANEL_BORDER) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BACKGROUND
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(12.0)
	return box


static func label(font_size: int, color: Color = WORLD_COLOR) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	node.add_theme_constant_override("outline_size", 4)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## 1234567 -> "1,234,567"
static func format_int(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	out = digits + out
	return "-" + out if value < 0 else out
