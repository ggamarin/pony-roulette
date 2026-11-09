extends SceneTree
## Headless-тесты логики:
##   godot --headless --path . -s tests/test_logic.gd

const MATCHES := 500
const MAX_STEPS := 20000

var failures := 0


func _init() -> void:
	_test_self_blank_keeps_turn()
	_test_live_passes_turn()
	_test_dust_double_damage()
	_test_ribbon_skips_turn()
	_test_apple_capped()
	_test_simulation()
	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		printerr("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: " + msg)


func _fresh(shells: Array, hp: int = 4) -> GameLogic:
	var g := GameLogic.new()
	g.start_match(1)
	g.shells = shells.duplicate()
	g.hp = [hp, hp]
	g.max_hp = hp
	g.items = [[], []]
	g.turn = GameLogic.PLAYER
	return g


func _test_self_blank_keeps_turn() -> void:
	var g := _fresh([false, true])
	var r := g.shoot(GameLogic.PLAYER)
	check(not r["live"] and g.turn == GameLogic.PLAYER, "кекс в себя должен сохранять ход")
	check(g.hp[GameLogic.PLAYER] == 4, "кекс не наносит урон")


func _test_live_passes_turn() -> void:
	var g := _fresh([true, false])
	g.shoot(GameLogic.PLAYER)
	check(g.hp[GameLogic.PLAYER] == 3, "перчик в себя: -1")
	check(g.turn == GameLogic.AI, "перчик в себя передаёт ход")
	g.shoot(GameLogic.AI)
	check(g.turn == GameLogic.AI, "кекс в себя у ИИ сохраняет ход ИИ")
	check(g.shells.size() >= 2, "пустая пушка перезаряжается")


func _test_dust_double_damage() -> void:
	var g := _fresh([true, true, false])
	g.items[GameLogic.PLAYER] = [GameLogic.Item.DUST]
	check(g.use_item(GameLogic.PLAYER, 0)["ok"], "пыль применяется")
	check(not g.can_use_item(GameLogic.PLAYER, 0), "пустой слот недоступен")
	g.shoot(GameLogic.AI)
	check(g.hp[GameLogic.AI] == 2, "пыль: перчик снимает 2")
	check(not g.dust_active, "пыль сгорает после выстрела")


func _test_ribbon_skips_turn() -> void:
	var g := _fresh([false, false, true])
	g.items[GameLogic.PLAYER] = [GameLogic.Item.RIBBON, GameLogic.Item.RIBBON]
	check(g.use_item(GameLogic.PLAYER, 0)["ok"], "ленточка применяется")
	check(not g.use_item(GameLogic.PLAYER, 0)["ok"], "нельзя связать уже связанную")
	var r := g.shoot(GameLogic.AI)
	check(r["skipped"] == GameLogic.AI and g.turn == GameLogic.PLAYER, "связанная пропускает ход")
	g.shoot(GameLogic.AI)
	check(g.turn == GameLogic.AI, "после пропуска ход переходит нормально")


func _test_apple_capped() -> void:
	var g := _fresh([true, false])
	g.items[GameLogic.PLAYER] = [GameLogic.Item.APPLE]
	check(not g.can_use_item(GameLogic.PLAYER, 0), "яблоко при полном здоровье недоступно")
	g.hp[GameLogic.PLAYER] = 2
	g.use_item(GameLogic.PLAYER, 0)
	check(g.hp[GameLogic.PLAYER] == 3, "яблоко: +1")


func _test_simulation() -> void:
	var wins := [0, 0]
	var total_steps := 0
	for m in MATCHES:
		var g := GameLogic.new()
		g.start_match(m)
		var steps := 0
		while g.phase != GameLogic.Phase.MATCH_OVER:
			steps += 1
			if steps > MAX_STEPS:
				check(false, "матч %d не завершился" % m)
				break
			if g.phase == GameLogic.Phase.ROUND_OVER:
				g.next_round()
				continue
			for who in 2:
				check(g.hp[who] >= 0 and g.hp[who] <= g.max_hp, "hp вне диапазона (матч %d)" % m)
				check(g.items[who].size() <= GameLogic.MAX_ITEMS, "больше 8 предметов (матч %d)" % m)
			check(not g.shells.is_empty(), "пустая пушка во время хода (матч %d)" % m)
			var who: int = g.turn
			var d := PonyAI.decide(g, who)
			if d["type"] == "item":
				var r := g.use_item(who, d["index"])
				check(r["ok"], "ИИ выбрал недоступный предмет (матч %d)" % m)
				if not r["ok"]:
					break
			else:
				var live_before := g.live_count()
				var r := g.shoot(d["target"])
				if not r["reloaded"] and not r["round_over"]:
					check(g.live_count() == live_before - (1 if r["live"] else 0), "счёт перчиков сломан (матч %d)" % m)
				if r["reloaded"]:
					check(g.live_count() >= 1 and g.blank_count() >= 1, "после перезарядки нет обоих типов")
					check(g.live_count() + g.blank_count() == g.last_load["live"] + g.last_load["blank"], "сумма зарядов не совпадает")
		total_steps += steps
		if g.phase == GameLogic.Phase.MATCH_OVER:
			check(g.wins[g.match_winner] >= GameLogic.WINS_NEEDED, "победитель без 2 побед (матч %d)" % m)
			wins[g.match_winner] += 1
	print("Симуляция: %d матчей, побед P0/P1 = %d/%d, ср. шагов %.1f" % [MATCHES, wins[0], wins[1], float(total_steps) / MATCHES])
