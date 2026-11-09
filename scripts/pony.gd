class_name Pony
extends Node2D
## Пони, нарисованная кодом. Начало координат — между копытами, смотрит вправо.

var body_color := Color("#f3e8ff")
var mane_color := Color("#7ccfff")
var mane_color2 := Color("#ff9ccb")
var eye_color := Color("#3f7fd9")
var has_wings := false
var has_horn := false
var mark := "star"
var expression := "normal"   # normal | happy | hurt | scared
var base_pos := Vector2.ZERO
var t := 0.0
var _expr_id := 0


func configure(preset: String, pos: Vector2, facing: int) -> void:
	if preset == "player":
		body_color = Color("#f3e8ff")
		mane_color = Color("#7ccfff")
		mane_color2 = Color("#ff9ccb")
		eye_color = Color("#3f7fd9")
		has_wings = true
		mark = "star"
	else:
		body_color = Color("#ffe3c7")
		mane_color = Color("#ff6fae")
		mane_color2 = Color("#ffd36e")
		eye_color = Color("#b0457c")
		has_horn = true
		mark = "candy"
		t = 1.3
	base_pos = pos
	position = pos
	scale = Vector2(1.1 * facing, 1.1)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _outline() -> Color:
	return body_color.darkened(0.35)


func _part(pts: PackedVector2Array, fill: Color) -> void:
	Icons.blob(self, pts, fill, _outline(), 3.0)


func _ell(c: Vector2, rx: float, ry: float, fill: Color, rot: float = 0.0) -> void:
	_part(Icons.ellipse_pts(c, rx, ry, rot), fill)


func _leg(x: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(x - 9, -75), Vector2(x + 9, -75), Vector2(x + 9, -8), Vector2(x - 9, -8)])
	_part(pts, col)
	_ell(Vector2(x, -6), 11, 7, mane_color.darkened(0.15))


func _draw() -> void:
	var shade := body_color.darkened(0.08)
	var bob := sin(t * 2.2) * 2.5
	draw_colored_polygon(Icons.ellipse_pts(Vector2(0, 2), 95, 13), Color(0.4, 0.1, 0.4, 0.13))

	# дальние ноги
	_leg(-38, shade)
	_leg(30, shade)

	draw_set_transform(Vector2(0, bob))
	# хвост
	var tail := [[Vector2(-78, -112), 20, mane_color], [Vector2(-95, -92), 22, mane_color2],
		[Vector2(-100, -66), 19, mane_color], [Vector2(-94, -44), 15, mane_color2]]
	for p in tail:
		_ell(p[0], p[1], p[1] * 0.9, p[2])
	draw_set_transform(Vector2.ZERO)

	# ближние ноги
	_leg(-55, body_color)
	_leg(48, body_color)

	draw_set_transform(Vector2(0, bob))
	_ell(Vector2(0, -98), 74, 42, body_color)
	# кьютимарка
	Icons.draw_icon(self, mark, Vector2(-38, -95), 30)
	if has_wings:
		var wc := body_color.lightened(0.4)
		_ell(Vector2(5, -112), 44, 20, wc, -0.35)
		for k in 3:
			_ell(Vector2(-22 + k * 14, -100 + k * 4), 12, 9, wc, -0.35)

	# шея и голова
	_part(PackedVector2Array([Vector2(28, -118), Vector2(52, -178), Vector2(98, -170), Vector2(72, -100)]), body_color)
	var head_bob := Vector2(0, sin(t * 2.2 + 0.6) * 1.5)
	var h := Vector2(80, -190) + head_bob
	_ell(h, 46, 42, body_color)
	_ell(h + Vector2(34, 18), 30, 24, body_color.lightened(0.25))
	draw_circle(h + Vector2(50, 14), 2.8, _outline())
	draw_colored_polygon(Icons.ellipse_pts(h + Vector2(28, 8), 10, 6), Color(1, 0.45, 0.6, 0.45))

	# ухо
	_part(PackedVector2Array([h + Vector2(-26, -26), h + Vector2(-18, -66), h + Vector2(0, -34)]), body_color)
	draw_colored_polygon(PackedVector2Array([h + Vector2(-19, -30), h + Vector2(-16, -54), h + Vector2(-6, -33)]), Color("#ffc3dc"))

	_draw_face(h)

	# грива
	var mane := [[Vector2(-20, -40), 22, mane_color], [Vector2(-34, -16), 23, mane_color2],
		[Vector2(-42, 12), 21, mane_color], [Vector2(-42, 40), 18, mane_color2],
		[Vector2(-32, 64), 14, mane_color], [Vector2(2, -42), 16, mane_color2]]
	for p in mane:
		_ell(h + p[0], p[1], p[1] * 0.9, p[2])

	if has_horn:
		_part(PackedVector2Array([h + Vector2(-2, -36), h + Vector2(14, -92), h + Vector2(20, -34)]), Color("#ffd76e"))
		for k in 3:
			var y := -44.0 - k * 14.0
			draw_line(h + Vector2(1 + k * 3, y), h + Vector2(15 + k * 1, y - 6), Color("#e09a2b"), 2.0, true)
	draw_set_transform(Vector2.ZERO)


func _draw_face(h: Vector2) -> void:
	var e := h + Vector2(12, -6)
	var dark := Color("#3a2340")
	match expression:
		"happy":
			draw_arc(e + Vector2(0, 6), 12, PI * 1.15, PI * 1.85, 14, dark, 4.0, true)
			_mouth_open(h)
		"hurt":
			draw_line(e + Vector2(-9, -9), e + Vector2(9, 9), dark, 4.0, true)
			draw_line(e + Vector2(9, -9), e + Vector2(-9, 9), dark, 4.0, true)
			draw_circle(h + Vector2(38, 30), 6, dark)
			_drop(h + Vector2(-8, -22))
		_:
			var pupil := 6.0 if expression == "normal" else 3.5
			_ell(e, 15, 19, Color.WHITE)
			draw_colored_polygon(Icons.ellipse_pts(e + Vector2(4, 2), 11, 15), eye_color)
			draw_circle(e + Vector2(6, 4), pupil, dark)
			draw_circle(e + Vector2(1, -4), 4, Color.WHITE)
			draw_circle(e + Vector2(9, 9), 1.8, Color.WHITE)
			draw_line(e + Vector2(10, -17), e + Vector2(17, -24), dark, 2.5, true)
			draw_line(e + Vector2(14, -12), e + Vector2(22, -17), dark, 2.5, true)
			if expression == "scared":
				draw_arc(h + Vector2(40, 32), 6, PI + 0.4, TAU - 0.4, 10, dark, 3.0, true)
				_drop(h + Vector2(-8, -22))
			else:
				draw_arc(h + Vector2(36, 24), 10, 0.5, PI - 0.6, 12, dark, 3.0, true)


func _mouth_open(h: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(h + Vector2(38, 26) + Vector2(cos(a) * 11, sin(a) * 9))
	draw_colored_polygon(pts, Color("#c94f7c"))


func _drop(p: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -10), p + Vector2(6, 2), p + Vector2(-6, 2)]), Color("#8ccfff"))
	draw_circle(p + Vector2(0, 3), 6, Color("#8ccfff"))


func set_expression(e: String, hold: float = 0.0) -> void:
	expression = e
	_expr_id += 1
	if hold > 0:
		var my_id := _expr_id
		get_tree().create_timer(hold).timeout.connect(func():
			if _expr_id == my_id:
				expression = "normal")


func hop() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:y", base_pos.y - 34, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", base_pos.y, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func happy() -> void:
	set_expression("happy", 1.3)
	hop()


func scared() -> void:
	set_expression("scared", 3.0)


func hurt() -> void:
	set_expression("hurt", 1.6)
	modulate = Color(1, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.9)
	var sh := create_tween()
	for i in 6:
		sh.tween_property(self, "position:x", base_pos.x + (12 if i % 2 == 0 else -12), 0.05)
	sh.tween_property(self, "position:x", base_pos.x, 0.05)
