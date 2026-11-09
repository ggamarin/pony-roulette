extends Control
## Главная сцена: строит UI, ведёт ход игры, анимации и ходы ИИ.

const PLAYER := GameLogic.PLAYER
const AI := GameLogic.AI
const NAMES := ["Звёздочка", "Карамелька"]
const NAMES_ACC := ["Звёздочку", "Карамельку"]
const NAMES_DAT := ["Звёздочке", "Карамельке"]
const PONY_POS := [Vector2(250, 560), Vector2(1030, 560)]

const RULES := """[center][b]Две пони, одна Кексовая пушка.[/b][/center]
В пушку заряжают [color=#e0405a][b]острые перчики[/b][/color] (минус сердечко) и безобидные [color=#c04a86][b]кексы-конфетти[/b][/color]. Сколько каких — покажут, а вот порядок — секрет!

• Пальнула в себя кексом — ходишь ещё раз.
• Пальнула в соперницу кексом — ход переходит.
• Перчик всегда снимает сердечко у того, в кого попал.

[b]Предметы:[/b] Кристалл — подсмотреть заряд; Яблочко — +1 сердечко; Радужная пыль — перчик жжёт вдвое; Ленточка — соперница пропускает ход; Коктейль — выбросить текущий заряд.

[center]Выиграй [b]2 раунда из 3[/b]![/center]"""

var g: GameLogic
var busy := true
var demo := false   # --demo: ИИ играет за обе стороны (для проверки)

var world: Node2D
var ponies: Array[Pony] = []
var cannon: Cannon
var sfx: Sfx

var name_labels: Array[Label] = []
var status_labels: Array[Label] = []
var hearts_boxes: Array[HBoxContainer] = []
var item_grids: Array[GridContainer] = []
var round_label: Label
var info_label: Label
var log_label: RichTextLabel
var shells_label: Label
var btn_self: Button
var btn_opp: Button
var btn_mute: Button
var peek_icon: IconView
var reload_panel: PanelContainer
var reload_icons: HBoxContainer
var reload_text: Label
var banner: Label
var start_overlay: Control
var end_overlay: Control
var end_title: Label
var end_text: RichTextLabel


func _ready() -> void:
	theme = PonyTheme.make()
	sfx = Sfx.new()
	add_child(sfx)
	_build_world()
	_build_ui()
	_show_start()
	var args := OS.get_cmdline_user_args()
	demo = "--demo" in args
	if demo or "--autostart" in args:
		_on_play()


# ---------------------------------------------------------------- построение

func _build_world() -> void:
	world = Node2D.new()
	add_child(world)
	world.add_child(Background.new())
	for who in 2:
		var p := Pony.new()
		p.configure("player" if who == PLAYER else "ai", PONY_POS[who], 1 if who == PLAYER else -1)
		world.add_child(p)
		ponies.append(p)
	cannon = Cannon.new()
	cannon.position = Vector2(640, 498)
	world.add_child(cannon)


func _label(text: String, font_size: int, pos: Vector2, width: float, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, 0)
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _build_ui() -> void:
	# панели сторон
	for who in 2:
		var panel := PanelContainer.new()
		panel.position = Vector2(20, 14) if who == PLAYER else Vector2(950, 14)
		panel.custom_minimum_size = Vector2(310, 0)
		add_child(panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		panel.add_child(vb)
		var nl := Label.new()
		nl.text = NAMES[who] + (" (ты)" if who == PLAYER else "")
		nl.add_theme_color_override("font_color", PonyTheme.HOT_PINK if who == PLAYER else Color("#d0763a"))
		nl.add_theme_font_size_override("font_size", 24)
		vb.add_child(nl)
		name_labels.append(nl)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 2)
		hb.custom_minimum_size = Vector2(0, 32)
		vb.add_child(hb)
		hearts_boxes.append(hb)
		var sl := Label.new()
		sl.add_theme_font_size_override("font_size", 16)
		sl.add_theme_color_override("font_color", Color("#9a5fa0"))
		vb.add_child(sl)
		status_labels.append(sl)

	round_label = _label("", 24, Vector2(340, 14), 600)
	info_label = _label("", 28, Vector2(290, 48), 700)
	info_label.add_theme_color_override("font_color", PonyTheme.HOT_PINK)

	var log_panel := PanelContainer.new()
	log_panel.position = Vector2(400, 96)
	log_panel.custom_minimum_size = Vector2(480, 128)
	log_panel.size = Vector2(480, 128)
	log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(log_panel)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.custom_minimum_size = Vector2(450, 100)
	log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(log_label)

	shells_label = _label("", 18, Vector2(390, 578), 500)

	peek_icon = IconView.new("pepper", 64)
	peek_icon.position = Vector2(700, 330)
	peek_icon.size = Vector2(64, 64)
	peek_icon.visible = false
	add_child(peek_icon)

	# предметы
	_label("Твои предметы", 17, Vector2(22, 566), 270, HORIZONTAL_ALIGNMENT_LEFT)
	_label("Предметы Карамельки", 17, Vector2(1020, 566), 240, HORIZONTAL_ALIGNMENT_RIGHT)
	for who in 2:
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		grid.position = Vector2(20, 592) if who == PLAYER else Vector2(1064, 596)
		add_child(grid)
		item_grids.append(grid)

	btn_self = Button.new()
	btn_self.text = "Пальнуть в себя"
	btn_self.position = Vector2(372, 616)
	btn_self.custom_minimum_size = Vector2(225, 66)
	btn_self.pressed.connect(_on_shoot.bind(PLAYER))
	add_child(btn_self)
	btn_opp = Button.new()
	btn_opp.text = "Пальнуть в Карамельку"
	btn_opp.position = Vector2(607, 616)
	btn_opp.custom_minimum_size = Vector2(290, 66)
	btn_opp.pressed.connect(_on_shoot.bind(AI))
	add_child(btn_opp)
	btn_mute = Button.new()
	btn_mute.text = "Звук: вкл"
	btn_mute.position = Vector2(910, 626)
	btn_mute.custom_minimum_size = Vector2(125, 48)
	btn_mute.add_theme_font_size_override("font_size", 16)
	btn_mute.pressed.connect(_on_mute)
	add_child(btn_mute)

	# окно перезарядки
	var rc := CenterContainer.new()
	rc.position = Vector2(0, 236)
	rc.size = Vector2(1280, 150)
	rc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rc)
	reload_panel = PanelContainer.new()
	reload_panel.visible = false
	rc.add_child(reload_panel)
	var rv := VBoxContainer.new()
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	reload_panel.add_child(rv)
	reload_text = Label.new()
	reload_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(reload_text)
	reload_icons = HBoxContainer.new()
	reload_icons.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_child(reload_icons)

	banner = _label("", 64, Vector2(0, 250), 1280)
	banner.add_theme_color_override("font_color", PonyTheme.HOT_PINK)
	banner.add_theme_constant_override("outline_size", 16)
	banner.visible = false

	start_overlay = _overlay("Пони-рулетка", RULES, "Играть!", _on_play)
	var end_parts := _overlay_parts("", "", "Ещё раз!", _on_play)
	end_overlay = end_parts[0]
	end_title = end_parts[1]
	end_text = end_parts[2]


func _overlay(title: String, text: String, btn_text: String, cb: Callable) -> Control:
	return _overlay_parts(title, text, btn_text, cb)[0]


func _overlay_parts(title: String, text: String, btn_text: String, cb: Callable) -> Array:
	var root := ColorRect.new()
	root.color = Color(0.35, 0.12, 0.4, 0.45)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var panel := PanelContainer.new()
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var tl := Label.new()
	tl.text = title
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_size_override("font_size", 56)
	tl.add_theme_color_override("font_color", PonyTheme.HOT_PINK)
	tl.add_theme_constant_override("outline_size", 12)
	vb.add_child(tl)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(680, 0)
	rt.add_theme_font_size_override("normal_font_size", 19)
	rt.add_theme_font_size_override("bold_font_size", 19)
	rt.text = text
	vb.add_child(rt)
	var b := Button.new()
	b.text = btn_text
	b.custom_minimum_size = Vector2(260, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	vb.add_child(b)
	root.visible = false
	return [root, tl, rt]


# ---------------------------------------------------------------- обновление UI

static func plural(n: int, one: String, few: String, many: String) -> String:
	var n10 := n % 10
	var n100 := n % 100
	if n10 == 1 and n100 != 11:
		return one
	if n10 >= 2 and n10 <= 4 and (n100 < 10 or n100 >= 20):
		return few
	return many


func _log(msg: String) -> void:
	log_label.append_text(msg + "\n")


func _refresh() -> void:
	if g == null:
		return
	for who in 2:
		var hb := hearts_boxes[who]
		for c in hb.get_children():
			hb.remove_child(c)
			c.queue_free()
		for i in g.max_hp:
			hb.add_child(IconView.new("heart" if i < g.hp[who] else "heart_empty", 30))
		status_labels[who].text = "Связана ленточкой — пропустит ход" if g.tied[who] else " "
		_rebuild_items(who)
	round_label.text = "Раунд %d из 3   ·   Счёт %d : %d" % [g.round_idx + 1, g.wins[PLAYER], g.wins[AI]]
	var n := g.shells.size()
	shells_label.text = "В пушке: %d %s" % [n, plural(n, "заряд", "заряда", "зарядов")]
	if g.dust_active:
		shells_label.text += "   ·   радужная пыль: x2!"
	_refresh_controls()


func _rebuild_items(who: int) -> void:
	var grid := item_grids[who]
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	var can := _player_can_act()
	for i in g.items[who].size():
		var it = g.items[who][i]
		var icon := IconView.new(GameLogic.ITEM_ICONS[it])
		if who == PLAYER:
			var b := Button.new()
			b.theme_type_variation = "ItemButton"
			b.custom_minimum_size = Vector2(54, 54)
			b.tooltip_text = "%s\n%s" % [GameLogic.ITEM_NAMES[it], GameLogic.ITEM_DESC[it]]
			b.disabled = not (can and g.can_use_item(PLAYER, i))
			b.pressed.connect(_on_item.bind(i))
			grid.add_child(b)
			b.add_child(icon)
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			if b.disabled:
				icon.modulate = Color(1, 1, 1, 0.5)
		else:
			var pc := PanelContainer.new()
			pc.custom_minimum_size = Vector2(46, 46)
			pc.add_theme_stylebox_override("panel", PonyTheme.box(PonyTheme.CREAM, PonyTheme.PINK, 10, 3))
			pc.tooltip_text = GameLogic.ITEM_NAMES[it]
			grid.add_child(pc)
			pc.add_child(icon)


func _player_can_act() -> bool:
	return g != null and not busy and g.phase == GameLogic.Phase.PLAYING and g.turn == PLAYER


func _refresh_controls() -> void:
	var can := _player_can_act()
	btn_self.disabled = not can
	btn_opp.disabled = not can
	if g != null:
		var grid := item_grids[PLAYER]
		for i in grid.get_child_count():
			var b := grid.get_child(i) as Button
			b.disabled = not (can and g.can_use_item(PLAYER, i))
			b.get_child(0).modulate = Color(1, 1, 1, 0.5 if b.disabled else 1.0)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _banner(text: String, dur: float) -> void:
	banner.text = text
	banner.visible = true
	banner.pivot_offset = Vector2(640, 40)
	banner.scale = Vector2(0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(dur)
	banner.visible = false


func _shake(amount: float) -> void:
	var tw := create_tween()
	for i in 8:
		tw.tween_property(world, "position", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.04)
		amount *= 0.8
	tw.tween_property(world, "position", Vector2.ZERO, 0.05)


func _float_icon(kind: String, who: int) -> void:
	var ic := IconView.new(kind, 70)
	ic.size = Vector2(70, 70)
	ic.position = PONY_POS[who] + Vector2(-35, -330)
	add_child(ic)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ic, "position:y", ic.position.y - 50, 1.1)
	tw.tween_property(ic, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tw.chain().tween_callback(ic.queue_free)


# ---------------------------------------------------------------- ход игры

func _show_start() -> void:
	start_overlay.visible = true
	end_overlay.visible = false
	_refresh_controls()


func _on_play() -> void:
	start_overlay.visible = false
	end_overlay.visible = false
	sfx.play("chime")
	g = GameLogic.new()
	g.start_match()
	log_label.clear()
	await _begin_round()


func _on_mute() -> void:
	sfx.muted = not sfx.muted
	btn_mute.text = "Звук: выкл" if sfx.muted else "Звук: вкл"


func _begin_round() -> void:
	busy = true
	_refresh()
	_log("[b]Раунд %d![/b] У каждой по %d %s." % [g.round_idx + 1, g.max_hp, plural(g.max_hp, "сердечку", "сердечка", "сердечек")])
	info_label.text = ""
	await _banner("Раунд %d" % (g.round_idx + 1), 1.2)
	await _show_reload()
	_next_turn()


func _show_reload() -> void:
	busy = true
	peek_icon.visible = false
	var ld := g.last_load
	var live: int = ld["live"]
	var blank: int = ld["blank"]
	for c in reload_icons.get_children():
		reload_icons.remove_child(c)
		c.queue_free()
	for i in live:
		reload_icons.add_child(IconView.new("pepper", 52))
	for i in blank:
		reload_icons.add_child(IconView.new("cupcake", 52))
	reload_text.text = "Заряжаем: %d %s и %d %s" % [live, plural(live, "перчик", "перчика", "перчиков"), blank, plural(blank, "кекс", "кекса", "кексов")]
	reload_panel.visible = true
	info_label.text = "Перезарядка!"
	sfx.play("load")
	_log("Заряжено: %d %s, %d %s. Порядок — секрет!" % [live, plural(live, "перчик", "перчика", "перчиков"), blank, plural(blank, "кекс", "кекса", "кексов")])
	for who in 2:
		var dealt: Array = ld["dealt"][who]
		if dealt.is_empty():
			continue
		var names := PackedStringArray()
		for it in dealt:
			names.append(GameLogic.ITEM_NAMES[it])
		_log("%s получает: %s." % [NAMES[who], ", ".join(names)])
	_refresh()
	await _wait(2.4)
	reload_panel.visible = false


func _next_turn() -> void:
	if g.phase != GameLogic.Phase.PLAYING:
		return
	if g.turn == AI or demo:
		busy = true
		_refresh()
		info_label.text = "Ход %s…" % ("Карамельки" if g.turn == AI else "Звёздочки")
		await _ai_turn(g.turn)
	else:
		busy = false
		_refresh()
		info_label.text = "Твой ход, Звёздочка!"


func _ai_turn(who: int) -> void:
	await _wait(0.9)
	var guard := 0
	while g.phase == GameLogic.Phase.PLAYING and g.turn == who and guard < 20:
		guard += 1
		var d := PonyAI.decide(g, who)
		if d["type"] == "item":
			var ok: bool = await _do_item(who, d["index"])
			if ok:
				await _wait(0.8)
				continue
			d = {"type": "shoot", "target": GameLogic.other(who)}
		await _do_shoot(who, d["target"])
		return


func _on_item(idx: int) -> void:
	if not _player_can_act():
		return
	busy = true
	_refresh_controls()
	await get_tree().process_frame   # не удаляем кнопку внутри её же сигнала
	await _do_item(PLAYER, idx)
	busy = false
	_refresh()


func _on_shoot(target: int) -> void:
	if not _player_can_act():
		return
	busy = true
	_refresh_controls()
	await _do_shoot(PLAYER, target)


func _shell_name(s: int) -> String:
	return "[color=#e0405a][b]острый перчик[/b][/color]" if s == 1 else "[color=#c04a86][b]кекс[/b][/color]"


func _do_item(who: int, idx: int) -> bool:
	var r := g.use_item(who, idx)
	if not r["ok"]:
		return false
	var it = r["item"]
	var nm: String = NAMES[who]
	sfx.play("chime")
	_float_icon(GameLogic.ITEM_ICONS[it], who)
	ponies[who].hop()
	match it:
		GameLogic.Item.CRYSTAL:
			if who == PLAYER:
				_log("Кристалл мерцает… сейчас в пушке %s!" % _shell_name(r["shell"]))
				peek_icon.set_kind("pepper" if r["shell"] == 1 else "cupcake")
				peek_icon.visible = true
			else:
				_log("Карамелька смотрит в кристалл и загадочно улыбается…")
		GameLogic.Item.APPLE:
			_log("%s хрумкает яблочко: +1 сердечко." % nm)
		GameLogic.Item.DUST:
			_log("%s посыпает пушку радужной пылью — следующий перчик жжёт вдвое!" % nm)
		GameLogic.Item.RIBBON:
			_log("%s повязывает ленточку %s — та пропустит ход." % [nm, NAMES_DAT[GameLogic.other(who)]])
		GameLogic.Item.SHAKE:
			cannon.puff(r["shell"] == 1)
			_log("%s пьёт коктейль и вытряхивает заряд: это был %s." % [nm, _shell_name(r["shell"])])
	_refresh()
	if r["reloaded"]:
		await _wait(0.8)
		_log("Пушка пуста — перезаряжаем!")
		await _show_reload()
		_refresh()
	return true


func _do_shoot(shooter: int, target: int) -> void:
	peek_icon.visible = false
	if shooter == target:
		info_label.text = "%s направляет пушку на себя…" % NAMES[shooter]
	else:
		info_label.text = "%s целится в %s…" % [NAMES[shooter], NAMES_ACC[target]]
	ponies[target].scared()
	await cannon.aim_at(ponies[target].global_position + Vector2(0, -190)).finished
	sfx.play("click")
	await _wait(0.7)
	var r := g.shoot(target)
	cannon.fire(r["live"])
	if r["live"]:
		sfx.play("boom")
		_shake(16.0)
		ponies[target].hurt()
		var dmg: int = r["dmg"]
		_log("[color=#e0405a][b]БАХ! Острый перчик![/b][/color] %s теряет %d %s." % [NAMES[target], dmg, plural(dmg, "сердечко", "сердечка", "сердечек")])
	else:
		sfx.play("puff")
		ponies[target].happy()
		_log("Пуф! Всего лишь кекс-конфетти.")
		if shooter == target and not r["round_over"]:
			_log("%s ходит ещё раз!" % NAMES[shooter])
	_refresh()
	await _wait(1.3)
	cannon.rest()
	if r["skipped"] != -1:
		_log("%s связана ленточкой и пропускает ход!" % NAMES[r["skipped"]])
		await _wait(0.6)
	if r["round_over"]:
		await _round_end(r["winner"])
		return
	if r["reloaded"]:
		_log("Пушка пуста — перезаряжаем!")
		await _show_reload()
	_next_turn()


func _round_end(winner: int) -> void:
	busy = true
	info_label.text = ""
	ponies[winner].happy()
	sfx.play("win")
	_refresh()
	_log("[b]%s выигрывает раунд![/b]" % NAMES[winner])
	await _banner("%s выигрывает раунд!" % NAMES[winner], 2.0)
	if g.phase == GameLogic.Phase.MATCH_OVER:
		_show_end()
	else:
		g.next_round()
		await _begin_round()


func _show_end() -> void:
	var won := g.match_winner == PLAYER
	end_title.text = "Победа!" if won else "Поражение…"
	if won:
		end_text.text = "[center]Звёздочка перехитрила Карамельку!\nСчёт [b]%d : %d[/b]. Кексы и слава — твои![/center]" % [g.wins[PLAYER], g.wins[AI]]
	else:
		end_text.text = "[center]Карамелька оказалась хитрее.\nСчёт [b]%d : %d[/b]. Попробуешь ещё разок?[/center]" % [g.wins[PLAYER], g.wins[AI]]
	end_overlay.visible = true
	_refresh_controls()
	if demo:
		print("DEMO MATCH OVER: winner=%d score=%d:%d" % [g.match_winner, g.wins[PLAYER], g.wins[AI]])
