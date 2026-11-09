class_name PonyAI
extends RefCounted
## ИИ «Мисс Карамелька». Возвращает {"type": "item", "index": i} или {"type": "shoot", "target": who}.

const I := GameLogic.Item


static func decide(g: GameLogic, me: int) -> Dictionary:
	var opp := GameLogic.other(me)
	var total := g.shells.size()
	var live := g.live_count()
	var known: int = g.known_by[me]
	if known == -1:
		if live == 0:
			known = 0
		elif live == total:
			known = 1
	var p: float = float(known) if known != -1 else float(live) / total
	var inv: Array = g.items[me]

	var idx := inv.find(I.APPLE)
	if idx != -1 and g.can_use_item(me, idx):
		return _item(idx)

	if known == -1:
		idx = inv.find(I.CRYSTAL)
		if idx != -1 and g.can_use_item(me, idx):
			return _item(idx)
		idx = inv.find(I.SHAKE)
		if idx != -1 and p > 0.35 and p < 0.65:
			return _item(idx)

	if p >= 0.5:
		idx = inv.find(I.RIBBON)
		if idx != -1 and g.can_use_item(me, idx):
			return _item(idx)
		idx = inv.find(I.DUST)
		if idx != -1 and g.can_use_item(me, idx) and (known == 1 or p >= 0.66) and g.hp[opp] >= 2:
			return _item(idx)
		return {"type": "shoot", "target": opp}

	return {"type": "shoot", "target": me}


static func _item(idx: int) -> Dictionary:
	return {"type": "item", "index": idx}
