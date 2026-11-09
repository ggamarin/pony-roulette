class_name GameLogic
extends RefCounted
## Чистая логика «Пони-рулетки»: без UI, детерминирована при заданном seed.

enum Item { CRYSTAL, APPLE, DUST, RIBBON, SHAKE }
enum Phase { IDLE, PLAYING, ROUND_OVER, MATCH_OVER }

const PLAYER := 0
const AI := 1
const MAX_ITEMS := 8
const ROUND_HP := [2, 4, 6]
const WINS_NEEDED := 2

const ITEM_NAMES := {
	Item.CRYSTAL: "Волшебный кристалл",
	Item.APPLE: "Яблочко",
	Item.DUST: "Радужная пыль",
	Item.RIBBON: "Ленточка",
	Item.SHAKE: "Молочный коктейль",
}
const ITEM_DESC := {
	Item.CRYSTAL: "Подсмотреть текущий заряд пушки.",
	Item.APPLE: "+1 сердечко (не выше максимума).",
	Item.DUST: "Следующий перчик снимет 2 сердечка.",
	Item.RIBBON: "Соперница пропустит свой следующий ход.",
	Item.SHAKE: "Выбросить текущий заряд и узнать, какой он был.",
}
const ITEM_ICONS := {
	Item.CRYSTAL: "crystal",
	Item.APPLE: "apple",
	Item.DUST: "dust",
	Item.RIBBON: "ribbon",
	Item.SHAKE: "shake",
}

var rng := RandomNumberGenerator.new()
var phase: Phase = Phase.IDLE
var round_idx := 0
var wins := [0, 0]
var hp := [0, 0]
var max_hp := 0
var shells: Array = []          # true = острый перчик (боевой), false = кекс (холостой)
var items: Array = [[], []]
var turn := PLAYER
var tied := [false, false]      # связана ленточкой -> пропускает следующий ход
var dust_active := false
var known_by := [-1, -1]        # что каждая сторона знает о текущем заряде: -1 / 0 / 1
var last_load := {"live": 0, "blank": 0, "dealt": [[], []]}
var round_winner := -1
var match_winner := -1


static func other(who: int) -> int:
	return 1 - who


func start_match(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	wins = [0, 0]
	round_idx = 0
	match_winner = -1
	start_round()


func start_round() -> void:
	max_hp = ROUND_HP[mini(round_idx, ROUND_HP.size() - 1)]
	hp = [max_hp, max_hp]
	items = [[], []]
	tied = [false, false]
	dust_active = false
	turn = PLAYER
	round_winner = -1
	phase = Phase.PLAYING
	load_shells()


func next_round() -> void:
	assert(phase == Phase.ROUND_OVER)
	round_idx += 1
	start_round()


func load_shells() -> void:
	var total := rng.randi_range(2, 8)
	var live := clampi(roundi(total / 2.0) + rng.randi_range(-1, 1), 1, total - 1)
	shells.clear()
	for i in live:
		shells.append(true)
	for i in total - live:
		shells.append(false)
	for i in range(shells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = shells[i]
		shells[i] = shells[j]
		shells[j] = tmp
	known_by = [-1, -1]
	dust_active = false
	var dealt := [[], []]
	var n := rng.randi_range(2, 4)
	for who in 2:
		for k in n:
			if items[who].size() >= MAX_ITEMS:
				break
			var it := rng.randi_range(0, Item.size() - 1)
			items[who].append(it)
			dealt[who].append(it)
	last_load = {"live": live, "blank": total - live, "dealt": dealt}


func live_count() -> int:
	return shells.count(true)


func blank_count() -> int:
	return shells.count(false)


## Выстрел того, чей сейчас ход, в target.
func shoot(target: int) -> Dictionary:
	assert(phase == Phase.PLAYING and not shells.is_empty())
	var shooter := turn
	var live: bool = shells.pop_front()
	known_by = [-1, -1]
	var dmg := 0
	if live:
		dmg = 2 if dust_active else 1
		hp[target] = maxi(0, hp[target] - dmg)
	var res := {
		"shooter": shooter, "target": target, "live": live, "dmg": dmg,
		"dust": dust_active, "skipped": -1, "round_over": false,
		"winner": -1, "reloaded": false,
	}
	dust_active = false
	if hp[target] <= 0:
		_end_round(other(target))
		res["round_over"] = true
		res["winner"] = round_winner
		return res
	# Кекс в себя — ходишь ещё раз, иначе ход переходит.
	if live or target != shooter:
		res["skipped"] = _pass_turn()
	if shells.is_empty():
		load_shells()
		res["reloaded"] = true
	return res


func _pass_turn() -> int:
	var nxt := other(turn)
	if tied[nxt]:
		tied[nxt] = false
		return nxt   # связанная пропускает ход, ход остаётся у текущей
	turn = nxt
	return -1


func can_use_item(who: int, idx: int) -> bool:
	if phase != Phase.PLAYING or who != turn or shells.is_empty():
		return false
	if idx < 0 or idx >= items[who].size():
		return false
	match items[who][idx]:
		Item.APPLE:
			return hp[who] < max_hp
		Item.DUST:
			return not dust_active
		Item.RIBBON:
			return not tied[other(who)]
		Item.CRYSTAL:
			return known_by[who] == -1
	return true


func use_item(who: int, idx: int) -> Dictionary:
	if not can_use_item(who, idx):
		return {"ok": false}
	var it = items[who][idx]
	items[who].remove_at(idx)
	var res := {"ok": true, "who": who, "item": it, "shell": -1, "reloaded": false}
	match it:
		Item.CRYSTAL:
			known_by[who] = 1 if shells[0] else 0
			res["shell"] = known_by[who]
		Item.APPLE:
			hp[who] = mini(max_hp, hp[who] + 1)
		Item.DUST:
			dust_active = true
		Item.RIBBON:
			tied[other(who)] = true
		Item.SHAKE:
			var s: bool = shells.pop_front()
			res["shell"] = 1 if s else 0
			known_by = [-1, -1]
			if shells.is_empty():
				load_shells()
				res["reloaded"] = true
	return res


func _end_round(winner: int) -> void:
	round_winner = winner
	wins[winner] += 1
	if wins[winner] >= WINS_NEEDED or round_idx >= ROUND_HP.size() - 1:
		phase = Phase.MATCH_OVER
		match_winner = PLAYER if wins[PLAYER] > wins[AI] else AI
	else:
		phase = Phase.ROUND_OVER
