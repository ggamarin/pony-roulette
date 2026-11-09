class_name Background
extends Node2D
## Небо, радуга, облака, холмы и стол.

const W := 1280.0
const H := 720.0
const CLOUDS := [[80.0, 90.0, 1.0, 9.0], [520.0, 60.0, 0.8, 6.0], [900.0, 120.0, 1.2, 11.0], [1250.0, 70.0, 0.9, 7.0]]
const SPARKLES := [Vector2(160, 240), Vector2(420, 180), Vector2(860, 210), Vector2(1110, 260), Vector2(640, 150), Vector2(300, 330), Vector2(980, 340)]

var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([PonyTheme.SKY_TOP, PonyTheme.SKY_TOP, PonyTheme.SKY_BOTTOM, PonyTheme.SKY_BOTTOM]))

	var rainbow := [Color("#ff8fa3"), Color("#ffc46b"), Color("#fff07a"), Color("#8ee6a6"), Color("#8ccfff"), Color("#c3a3ff")]
	for i in rainbow.size():
		draw_arc(Vector2(640, 640), 560.0 - i * 26.0, PI, TAU, 128, Color(rainbow[i], 0.4), 26.0, true)

	for c in CLOUDS:
		var x := fposmod(c[0] + t * c[3], W + 300.0) - 150.0
		_cloud(Vector2(x, c[1]), c[2])

	for i in SPARKLES.size():
		var a := 0.5 + 0.5 * sin(t * 2.0 + i * 1.7)
		draw_colored_polygon(Icons.star_pts(SPARKLES[i], 4.0 + 6.0 * a, 1.5 + 1.5 * a, 4), Color(1, 1, 1, 0.35 + 0.5 * a))

	draw_colored_polygon(Icons.ellipse_pts(Vector2(260, 800), 560, 250, 0.0, 64), Color("#b9f2d8"))
	draw_colored_polygon(Icons.ellipse_pts(Vector2(1040, 810), 580, 260, 0.0, 64), Color("#a3ebc9"))
	draw_colored_polygon(Icons.ellipse_pts(Vector2(640, 860), 760, 300, 0.0, 64), Color("#c4f5df"))
	for i in 14:
		var fx := 60.0 + i * 92.0
		var fy := 640.0 + (i % 3) * 22.0
		draw_circle(Vector2(fx, fy), 5, [Color("#ff9ccb"), Color("#fff07a"), Color("#c9b6ff")][i % 3])

	# стол со скатертью
	draw_colored_polygon(Icons.ellipse_pts(Vector2(640, 572), 290, 52, 0.0, 64), Color(0.4, 0.1, 0.4, 0.12))
	Icons.blob(self, Icons.ellipse_pts(Vector2(640, 552), 285, 50, 0.0, 64), Color("#fff6fb"), Color("#ff9ccb"), 4.0)
	for i in 15:
		var a := PI * (i + 0.5) / 15.0
		var p := Vector2(640, 552) + Vector2(cos(a) * 285, sin(a) * 50)
		draw_circle(p, 9, Color("#ffb7d5"))
	Icons.blob(self, Icons.ellipse_pts(Vector2(640, 548), 220, 34, 0.0, 64), Color("#ffe9f4"), Color("#ffd0e6"), 2.0)


func _cloud(p: Vector2, s: float) -> void:
	var col := Color(1, 1, 1, 0.9)
	for c in [[Vector2(0, 0), 34.0], [Vector2(36, -12), 42.0], [Vector2(78, 0), 32.0], [Vector2(40, 12), 34.0]]:
		draw_circle(p + c[0] * s, c[1] * s, col)
