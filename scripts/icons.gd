class_name Icons
extends RefCounted
## Иконки, нарисованные кодом (без внешних ассетов). c — центр, s — размер.

const OUTLINE := Color("#8a4f86")


static func ellipse_pts(c: Vector2, rx: float, ry: float, rot: float = 0.0, n: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func star_pts(c: Vector2, r_out: float, r_in: float, n: int = 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := -PI / 2 + PI * i / n
		var r := r_out if i % 2 == 0 else r_in
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func blob(ci: CanvasItem, pts: PackedVector2Array, fill: Color, outline: Color = OUTLINE, w: float = 2.5) -> void:
	ci.draw_colored_polygon(pts, fill)
	if w > 0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, outline, w, true)


static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> void:
	match kind:
		"heart": heart(ci, c, s, Color("#ff5d8f"))
		"heart_empty": heart(ci, c, s, Color(1, 1, 1, 0.55), Color("#d9a7c7"))
		"pepper": pepper(ci, c, s)
		"cupcake": cupcake(ci, c, s)
		"crystal": crystal(ci, c, s)
		"apple": apple(ci, c, s)
		"dust": dust(ci, c, s)
		"ribbon": ribbon(ci, c, s)
		"shake": shake(ci, c, s)
		"star": blob(ci, star_pts(c, s * 0.48, s * 0.22), Color("#ffd84d"), Color("#e09a2b"))
		"candy": candy(ci, c, s)


static func heart(ci: CanvasItem, c: Vector2, s: float, col: Color, outline: Color = OUTLINE) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var t := TAU * i / 48.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y + 1.5) * s / 36.0)
	blob(ci, pts, col, outline, maxf(1.5, s / 18.0))
	ci.draw_circle(c + Vector2(-s * 0.2, -s * 0.12), s * 0.07, Color(1, 1, 1, 0.7))


static func pepper(ci: CanvasItem, c: Vector2, s: float) -> void:
	var body := PackedVector2Array()
	for i in 24:
		var t := float(i) / 23.0
		var y := lerpf(-0.3, 0.45, t)
		var w := 0.2 * (1.0 - t * t * 0.85)
		body.append(c + Vector2(w + sin(t * 2.4) * 0.08, y) * s)
	for i in 24:
		var t := 1.0 - float(i) / 23.0
		var y := lerpf(-0.3, 0.45, t)
		var w := 0.2 * (1.0 - t * t * 0.85)
		body.append(c + Vector2(-w + sin(t * 2.4) * 0.08, y) * s)
	blob(ci, body, Color("#ff4d4d"), Color("#a3263d"))
	ci.draw_line(c + Vector2(-0.07, -0.18) * s, c + Vector2(-0.05, 0.2) * s, Color(1, 1, 1, 0.55), maxf(1.0, s * 0.04), true)
	blob(ci, ellipse_pts(c + Vector2(0, -0.32) * s, s * 0.2, s * 0.07), Color("#5ccf7a"), Color("#2f8a4a"))
	ci.draw_line(c + Vector2(0, -0.36) * s, c + Vector2(0.1, -0.5) * s, Color("#2f8a4a"), maxf(2.0, s * 0.06), true)


static func cupcake(ci: CanvasItem, c: Vector2, s: float) -> void:
	var cup := PackedVector2Array([
		c + Vector2(-0.3, 0.02) * s, c + Vector2(0.3, 0.02) * s,
		c + Vector2(0.22, 0.45) * s, c + Vector2(-0.22, 0.45) * s])
	blob(ci, cup, Color("#c9b6ff"))
	for k in 3:
		var x := -0.12 + 0.12 * k
		ci.draw_line(c + Vector2(x * 1.2, 0.06) * s, c + Vector2(x, 0.42) * s, Color(1, 1, 1, 0.6), maxf(1.0, s * 0.03))
	var fr := Color("#ff9ccb")
	for p in [Vector2(-0.2, -0.04), Vector2(0.2, -0.04), Vector2(0, -0.2)]:
		ci.draw_circle(c + p * s, s * (0.2 if p.y < -0.1 else 0.17), Icons.OUTLINE)
	for p in [Vector2(-0.2, -0.04), Vector2(0.2, -0.04), Vector2(0, -0.2)]:
		ci.draw_circle(c + p * s, s * (0.2 if p.y < -0.1 else 0.17) - 1.5, fr)
	for p in [Vector2(-0.12, -0.1), Vector2(0.08, -0.22), Vector2(0.18, 0.0), Vector2(-0.02, 0.0)]:
		ci.draw_circle(c + p * s, maxf(1.0, s * 0.025), Color("#fff6a8"))
	ci.draw_circle(c + Vector2(0, -0.42) * s, s * 0.08, Color("#e0405a"))


static func crystal(ci: CanvasItem, c: Vector2, s: float) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -0.45) * s, c + Vector2(0.3, -0.12) * s,
		c + Vector2(0, 0.45) * s, c + Vector2(-0.3, -0.12) * s])
	blob(ci, pts, Color("#b8a3ff"), Color("#6a4fc2"))
	ci.draw_line(c + Vector2(-0.3, -0.12) * s, c + Vector2(0.3, -0.12) * s, Color(1, 1, 1, 0.7), maxf(1.0, s * 0.03))
	ci.draw_line(c + Vector2(0, -0.45) * s, c + Vector2(0, 0.45) * s, Color(1, 1, 1, 0.4), maxf(1.0, s * 0.03))
	ci.draw_colored_polygon(star_pts(c + Vector2(0.25, -0.35) * s, s * 0.12, s * 0.04, 4), Color.WHITE)


static func apple(ci: CanvasItem, c: Vector2, s: float) -> void:
	blob(ci, ellipse_pts(c + Vector2(0, 0.06) * s, s * 0.36, s * 0.33), Color("#ff6b6b"), Color("#a3263d"))
	ci.draw_circle(c + Vector2(-0.14, -0.04) * s, s * 0.07, Color(1, 1, 1, 0.6))
	ci.draw_line(c + Vector2(0, -0.22) * s, c + Vector2(0.03, -0.4) * s, Color("#8a5a3c"), maxf(2.0, s * 0.06), true)
	blob(ci, ellipse_pts(c + Vector2(0.15, -0.36) * s, s * 0.13, s * 0.06, -0.5), Color("#5ccf7a"), Color("#2f8a4a"), 1.5)


static func dust(ci: CanvasItem, c: Vector2, s: float) -> void:
	var cols := [Color("#ff8fa3"), Color("#ffc46b"), Color("#fff07a"), Color("#8ee6a6"), Color("#8ccfff"), Color("#c3a3ff")]
	for i in cols.size():
		ci.draw_arc(c + Vector2(0, 0.3) * s, s * (0.42 - i * 0.05), PI, TAU, 24, cols[i], maxf(1.5, s * 0.05), true)
	blob(ci, star_pts(c + Vector2(0, -0.08) * s, s * 0.26, s * 0.11), Color("#fff07a"), Color("#e09a2b"), 2.0)
	ci.draw_colored_polygon(star_pts(c + Vector2(-0.3, -0.3) * s, s * 0.08, s * 0.03, 4), Color.WHITE)
	ci.draw_colored_polygon(star_pts(c + Vector2(0.32, -0.32) * s, s * 0.06, s * 0.02, 4), Color.WHITE)


static func ribbon(ci: CanvasItem, c: Vector2, s: float) -> void:
	var col := Color("#ff6fae")
	blob(ci, PackedVector2Array([c, c + Vector2(-0.42, -0.25) * s, c + Vector2(-0.42, 0.22) * s]), col)
	blob(ci, PackedVector2Array([c, c + Vector2(0.42, -0.25) * s, c + Vector2(0.42, 0.22) * s]), col)
	blob(ci, PackedVector2Array([c + Vector2(-0.05, 0.05) * s, c + Vector2(-0.2, 0.45) * s, c + Vector2(-0.08, 0.4) * s]), col)
	blob(ci, PackedVector2Array([c + Vector2(0.05, 0.05) * s, c + Vector2(0.08, 0.4) * s, c + Vector2(0.2, 0.45) * s]), col)
	ci.draw_circle(c, s * 0.1, Icons.OUTLINE)
	ci.draw_circle(c, s * 0.1 - 1.5, Color("#ff9ccb"))


static func shake(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_line(c + Vector2(0.05, -0.1) * s, c + Vector2(0.2, -0.5) * s, Color("#ff5d8f"), maxf(2.0, s * 0.07), true)
	var cup := PackedVector2Array([
		c + Vector2(-0.25, -0.1) * s, c + Vector2(0.25, -0.1) * s,
		c + Vector2(0.17, 0.45) * s, c + Vector2(-0.17, 0.45) * s])
	blob(ci, cup, Color("#a8f0d4"), Color("#3f9a7c"))
	ci.draw_line(c + Vector2(-0.22, 0.08) * s, c + Vector2(0.22, 0.08) * s, Color(1, 1, 1, 0.7), maxf(1.0, s * 0.04))
	for p in [Vector2(-0.14, -0.14), Vector2(0.12, -0.14), Vector2(0, -0.24)]:
		ci.draw_circle(c + p * s, s * 0.13, Color("#fffaf0"))
	ci.draw_circle(c + Vector2(0, -0.37) * s, s * 0.07, Color("#e0405a"))


static func candy(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_line(c + Vector2(0, 0.05) * s, c + Vector2(0, 0.5) * s, Color("#fffaf0"), maxf(2.0, s * 0.08), true)
	blob(ci, ellipse_pts(c + Vector2(0, -0.12) * s, s * 0.3, s * 0.3), Color("#ffd36e"), Color("#e09a2b"), 2.0)
	ci.draw_arc(c + Vector2(0, -0.12) * s, s * 0.18, 0, PI * 1.5, 16, Color("#ff6fae"), maxf(2.0, s * 0.07), true)
	ci.draw_arc(c + Vector2(0, -0.12) * s, s * 0.07, PI, TAU * 1.2, 12, Color("#ff6fae"), maxf(1.5, s * 0.05), true)
