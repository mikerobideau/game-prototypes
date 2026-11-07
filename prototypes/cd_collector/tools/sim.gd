extends SceneTree

const GAMES := 300

func _initialize() -> void:
	var g = load("res://prototypes/cd_collector/cd_collector.gd").new()
	root.add_child(g)
	var totals: Array[int] = []
	var objs := {}
	var plays_used := 0
	for n in GAMES:
		g.rng.seed = n + 1
		g._new_game()
		g._choose(0)
		for t in g.D.TURNS:
			_turn(g)
			g._end_turn()
		totals.append(g._total())
		var key: String = g.objective["id"]
		if not objs.has(key):
			objs[key] = []
		objs[key].append(g.final_objective)
	totals.sort()
	var sum := 0
	for v in totals:
		sum += v
	print("games %d  mean %.1f  min %d  p25 %d  median %d  p75 %d  max %d" % [GAMES, float(sum) / GAMES, totals[0], totals[GAMES / 4], totals[GAMES / 2], totals[GAMES * 3 / 4], totals[GAMES - 1]])
	for k in objs:
		var s := 0
		for v in objs[k]:
			s += v
		print("  %s: %d games, mean objective %.1f" % [k, objs[k].size(), float(s) / objs[k].size()])
	quit()

func _turn(g) -> void:
	var guard := 0
	while guard < 80:
		guard += 1
		if not _act(g):
			break

func _act(g) -> bool:
	for i in g.hand.size():
		var best := -1
		var best_n := -1
		for s in 9:
			if g.binder[s] == null and g._legal(s, g.hand[i]):
				var n := 0
				for k in g._neighbors(s):
					var o = g.binder[k]
					if o != null and (o.genre == g.hand[i].genre or o.era == g.hand[i].era):
						n += 1
				if n > best_n:
					best_n = n
					best = s
		if best >= 0:
			g.held = i
			g._place(best)
			return true
	for s in 9:
		var cd = g.binder[s]
		if cd != null and not cd.used and g.plays > 0:
			g._play(s)
			return true
	var empty := 0
	for s in 9:
		if g.binder[s] == null:
			empty += 1
	if g.hand.size() < empty:
		var pick := -1
		for i in g.row.size():
			var cd = g.row[i]
			if cd != null and g.cash >= cd.cost and (pick < 0 or cd.cost > g.row[pick].cost):
				pick = i
		if pick >= 0:
			g._buy(pick)
			return true
	return false
