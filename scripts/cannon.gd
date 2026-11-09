class_name Cannon
extends Node2D
## Кексовая пушка: прицеливание, отдача, конфетти / «острый» взрыв.

const REST := -PI / 2
const LENGTH := 150.0

var angle := REST
var recoil := 0.0
var _aim_tween: Tween


func _draw() -> void:
	draw_colored_polygon(Icons.ellipse_pts(Vector2(0, 58), 92, 13), Color(0.4, 0.1, 0.4, 0.13))
	var ol := Color("#8a4f86")
	# ствол
	draw_set_transform(Vector2.ZERO, angle)
	var x0 := -30.0 - recoil
	Icons.blob(self, PackedVector2Array([Vector2(x0, -27), Vector2(x0 + LENGTH, -22), Vector2(x0 + LENGTH, 22), Vector2(x0, 27)]), Color("#ff9ccb"), ol, 3.0)
	for k in 3:
		draw_rect(Rect2(x0 + 28 + k * 32, -23 + k, 11, 46 - k * 2), Color(1, 1, 1, 0.75))
	Icons.blob(self, PackedVector2Array([Vector2(x0 + LENGTH - 6, -31), Vector2(x0 + LENGTH + 18, -31), Vector2(x0 + LENGTH + 18, 31), Vector2(x0 + LENGTH - 6, 31)]), Color("#ff6fae"), ol, 3.0)
	Icons.blob(self, Icons.ellipse_pts(Vector2(x0, 0), 22, 27), Color("#ff6fae"), ol, 3.0)
	draw_set_transform(Vector2.ZERO)
	# лафет
	Icons.blob(self, PackedVector2Array([Vector2(-62, 12), Vector2(62, 12), Vector2(48, 50), Vector2(-48, 50)]), Color("#c9b6ff"), ol, 3.0)
	for wx in [-46.0, 46.0]:
		Icons.blob(self, Icons.ellipse_pts(Vector2(wx, 46), 28, 28), Color("#a8f0d4"), Color("#3f9a7c"), 3.0)
		for k in 4:
			var a := PI / 4 * k
			draw_line(Vector2(wx, 46) + Vector2.from_angle(a) * 22, Vector2(wx, 46) - Vector2.from_angle(a) * 22, Color(1, 1, 1, 0.8), 3.0, true)
		draw_circle(Vector2(wx, 46), 7, Color("#ffd76e"))
	Icons.blob(self, Icons.ellipse_pts(Vector2.ZERO, 20, 20), Color("#ffd76e"), Color("#e09a2b"), 3.0)
	draw_colored_polygon(Icons.star_pts(Vector2.ZERO, 12, 5), Color.WHITE)


func _set_angle(a: float) -> void:
	angle = a
	queue_redraw()


func _set_recoil(r: float) -> void:
	recoil = r
	queue_redraw()


func aim_at(global_target: Vector2) -> Tween:
	var target := (global_target - global_position).angle()
	if _aim_tween:
		_aim_tween.kill()
	_aim_tween = create_tween()
	_aim_tween.tween_method(_set_angle, angle, target, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return _aim_tween


func rest() -> void:
	aim_at(global_position + Vector2.from_angle(REST) * 100)


func muzzle_local() -> Vector2:
	return Vector2.from_angle(angle) * (LENGTH - 15)


func fire(live: bool) -> void:
	var tw := create_tween()
	tw.tween_method(_set_recoil, 22.0, 0.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if live:
		_burst(110, [Color("#ff3b3b"), Color("#ff8a3d"), Color("#ffd84d"), Color("#ff5d8f")], 300, 650, 8, 15)
		_burst(40, [Color(1, 1, 1, 0.9), Color("#ffe0e0")], 80, 200, 14, 24, 0.0)
	else:
		_burst(70, [Color("#ff9ccb"), Color("#8ccfff"), Color("#fff07a"), Color("#a8f0d4"), Color("#c9b6ff")], 220, 460, 5, 10)


func puff(live: bool) -> void:
	var cols := [Color("#ff4d4d"), Color("#ffb347")] if live else [Color("#ff9ccb"), Color("#fff07a")]
	_burst(25, cols, 90, 200, 4, 8)


func _burst(amount: int, cols: Array, vmin: float, vmax: float, smin: float, smax: float, grav: float = 520.0) -> void:
	var p := CPUParticles2D.new()
	add_child(p)
	p.position = muzzle_local()
	p.amount = amount
	p.lifetime = 1.4
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector2.from_angle(angle)
	p.spread = 30.0
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector2(0, grav)
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	var g := Gradient.new()
	g.set_color(0, cols[0])
	g.set_color(1, cols[cols.size() - 1])
	for i in range(1, cols.size() - 1):
		g.add_point(float(i) / (cols.size() - 1), cols[i])
	p.color_initial_ramp = g
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.7, Color.WHITE)
	p.color_ramp = fade
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free)
