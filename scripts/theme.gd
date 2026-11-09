class_name PonyTheme
extends RefCounted
## Пастельная палитра и общий Theme.

const PINK := Color("#ffb7d5")
const HOT_PINK := Color("#ff6fae")
const LAVENDER := Color("#c9b6ff")
const MINT := Color("#a8f0d4")
const CREAM := Color("#fff6fb")
const TEXT := Color("#6b3d6e")
const SKY_TOP := Color("#bfe6ff")
const SKY_BOTTOM := Color("#ffe1f0")


static func box(bg: Color, border: Color, radius: int = 18, bw: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	sb.shadow_color = Color(0.45, 0.15, 0.45, 0.22)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true
	return sb


static func make() -> Theme:
	var t := Theme.new()
	var f := FontVariation.new()
	f.base_font = ThemeDB.fallback_font
	f.variation_embolden = 0.45
	t.default_font = f
	t.default_font_size = 22

	t.set_stylebox("normal", "Button", box(HOT_PINK, Color.WHITE))
	t.set_stylebox("hover", "Button", box(Color("#ff8cc0"), Color.WHITE))
	t.set_stylebox("pressed", "Button", box(Color("#e9559a"), Color.WHITE))
	t.set_stylebox("disabled", "Button", box(Color("#e6c6d8"), Color("#f5e6ef")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.75))
	t.set_color("font_outline_color", "Button", Color("#c04a86"))
	t.set_constant("outline_size", "Button", 4)
	t.set_font_size("font_size", "Button", 20)

	t.set_type_variation("ItemButton", "Button")
	t.set_stylebox("normal", "ItemButton", box(CREAM, PINK, 14, 4))
	t.set_stylebox("hover", "ItemButton", box(Color("#ffe9f4"), HOT_PINK, 14, 4))
	t.set_stylebox("pressed", "ItemButton", box(Color("#ffd6ea"), HOT_PINK, 14, 4))
	t.set_stylebox("disabled", "ItemButton", box(Color(1, 0.97, 0.99, 0.6), Color("#ecd3e2"), 14, 4))

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color.WHITE)
	t.set_constant("outline_size", "Label", 8)

	t.set_stylebox("panel", "PanelContainer", box(Color(1, 0.97, 0.99, 0.92), PINK, 22, 4))
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 17)
	t.set_font_size("bold_font_size", "RichTextLabel", 17)

	var tip := box(CREAM, HOT_PINK, 10, 3)
	tip.set_content_margin_all(8)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 17)
	return t
