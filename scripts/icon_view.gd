class_name IconView
extends Control
## Control, рисующий иконку из Icons по имени.

var kind := "heart"
var icon_scale := 0.8


func _init(k: String = "heart", sz: float = 0.0) -> void:
	kind = k
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if sz > 0:
		custom_minimum_size = Vector2(sz, sz)


func set_kind(k: String) -> void:
	kind = k
	queue_redraw()


func _draw() -> void:
	Icons.draw_icon(self, kind, size / 2.0, minf(size.x, size.y) * icon_scale)
