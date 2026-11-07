extends "res://prototypes/nine_pocket/nine_pocket_ui.gd"

const D := preload("res://prototypes/cd_collector/cd_collector_data.gd")

const BIN := 9
const LINES := [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8]]
const CORNERS := [0, 2, 6, 8]
const EDGES := [1, 3, 5, 7]
const ROW_X := 220.0
const ROW_Y := 238.0
const ROW_W := 246.0
const ROW_GAP := 18.0
const HAND_X := 48.0
const HAND_Y := 1076.0
const HAND_W := 205.0
const HAND_STEP := 216.0
const C_FELT := Color("22352e")
const C_PAPER := Color("f3eedf")
const C_PLACED := Color("5b6b82")
const C_PLAYED := Color("b4532a")

class Cd:
	var uid := 0
	var band := ""
	var album := ""
	var cover := ""
	var genre := 0
	var era := 0
	var cost := 0
	var placed := {}
	var played := {}
	var used := false

var rng := RandomNumberGenerator.new()
var albums: Array = []
var covers := {}
var next_uid := 1
var deck: Array[Cd] = []
var discard: Array[Cd] = []
var row: Array = []
var hand: Array[Cd] = []
var binder: Array = []
var phase := "objective"
var turn := 1
var plays := 0
var plays_max := 0
var cash := 0
var vp_placed := 0
var vp_played := 0
var objective := {}
var offers: Array = []
var held := -1
var log_lines: Array[String] = []
var floats: Array = []
var message := ""
var message_t := 0.0
var final_objective := 0

func _ready() -> void:
	_ui_ready()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rng.randomize()
	_load_albums()
	_new_game()

func _process(delta: float) -> void:
	message_t = maxf(0.0, message_t - delta)
	for i in range(floats.size() - 1, -1, -1):
		var f: Dictionary = floats[i]
		f["life"] = float(f["life"]) - delta
		f["pos"] = Vector2(f["pos"]) + Vector2(0.0, -46.0 * delta)
		if float(f["life"]) <= 0.0:
			floats.remove_at(i)
	_ui_process(delta)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_ui_click(_ui_mouse())
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			held = -1
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var key := (ev as InputEventKey).keycode
		if key == KEY_ESCAPE:
			held = -1
		elif key == KEY_SPACE and phase == "turn":
			_end_turn()

func _say(msg: String) -> void:
	message = msg
	message_t = 2.6

func _log(s: String) -> void:
	log_lines.append(s)
	if log_lines.size() > 60:
		log_lines.pop_front()

func _float_at(at: Vector2, s: String, col: Color) -> void:
	floats.append({"pos": at, "text": s, "col": col, "life": 1.6})

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

func _load_albums() -> void:
	var f := FileAccess.open(D.CATALOG, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		albums = parsed

func _hook(t: Dictionary, cd: Cd) -> Dictionary:
	var h := t.duplicate()
	h["genre"] = cd.genre
	h["era"] = cd.era
	h["text"] = D.describe(h)
	return h

func _make_cd(genre: int, era: int, album: Dictionary) -> Cd:
	var cd := Cd.new()
	cd.uid = next_uid
	next_uid += 1
	cd.genre = genre
	cd.era = era
	cd.band = String(album.get("band", "Unknown Band"))
	cd.album = String(album.get("album", "Untitled"))
	cd.cover = String(album.get("cover", ""))
	var lt: Dictionary = D.PLAYED[rng.randi() % D.PLAYED.size()]
	cd.played = _hook(lt, cd)
	var cost: int = lt["cost"]
	if rng.randf() < D.PLACED_CHANCE:
		var pt: Dictionary = D.PLACED[rng.randi() % D.PLACED.size()]
		cd.placed = _hook(pt, cd)
		cost += int(pt["cost"])
	cd.cost = clampi(cost, 0, D.COST_MAX)
	return cd

func _new_game() -> void:
	next_uid = 1
	deck.clear()
	discard.clear()
	hand.clear()
	log_lines.clear()
	floats.clear()
	var pool := albums.duplicate()
	_shuffle(pool)
	var n := 0
	for g in D.GENRES.size():
		for e in D.ERAS.size():
			for c in D.COPIES:
				var album: Dictionary = pool[n % pool.size()] if not pool.is_empty() else {}
				deck.append(_make_cd(g, e, album))
				n += 1
	_shuffle(deck)
	binder.clear()
	for i in BIN:
		binder.append(null)
	row.clear()
	for i in D.ROW_SIZE:
		row.append(_pop_deck())
	turn = 1
	plays = 0
	plays_max = 0
	cash = D.START_CASH
	vp_placed = 0
	vp_played = 0
	held = -1
	final_objective = 0
	var objs := D.OBJECTIVES.duplicate()
	_shuffle(objs)
	offers = objs.slice(0, D.OBJECTIVE_CHOICES)
	objective = {}
	phase = "objective"

func _pop_deck() -> Cd:
	if deck.is_empty() and not discard.is_empty():
		deck.assign(discard)
		discard.clear()
		_shuffle(deck)
	if deck.is_empty():
		return null
	return deck.pop_back()

func _choose(i: int) -> void:
	objective = offers[i]
	phase = "turn"
	_start_turn()

func _start_turn() -> void:
	plays_max = D.PLAYS_PER_TURN
	plays = plays_max
	cash += D.INCOME
	held = -1
	for o in binder:
		if o != null:
			o.used = false
	_log("Turn %d begins: %d Plays, +%d Cash." % [turn, plays, D.INCOME])

func _end_turn() -> void:
	held = -1
	if turn >= D.TURNS:
		_finish()
		return
	var gone: Cd = row[0]
	if gone != null:
		discard.append(gone)
	row[0] = row[1]
	row[1] = row[2]
	row[2] = _pop_deck()
	turn += 1
	_start_turn()

func _finish() -> void:
	final_objective = _objective_score(String(objective["id"]))
	phase = "over"
	_log("Final count: %d VP." % _total())

func _total() -> int:
	return vp_placed + vp_played + final_objective

func _neighbors(i: int) -> Array[int]:
	var out: Array[int] = []
	var r := i / 3
	var c := i % 3
	if r > 0:
		out.append(i - 3)
	if r < 2:
		out.append(i + 3)
	if c > 0:
		out.append(i - 1)
	if c < 2:
		out.append(i + 1)
	return out

func _count(h: Dictionary, i: int) -> int:
	var cond: String = h["cond"]
	match cond:
		"always":
			return 1
		"corner":
			return 1 if i in CORNERS else 0
		"center":
			return 1 if i == 4 else 0
		"edge":
			return 1 if i in EDGES else 0
		"hand":
			return hand.size()
	var bits := cond.split("_")
	var scope: String = bits[0]
	var tag: String = bits[1] if bits.size() > 1 else ""
	var pool: Array[int] = []
	match scope:
		"adj":
			pool = _neighbors(i)
		"row":
			for k in 3:
				if i / 3 * 3 + k != i:
					pool.append(i / 3 * 3 + k)
		"col":
			for k in 3:
				if i % 3 + k * 3 != i:
					pool.append(i % 3 + k * 3)
		"bind":
			for k in BIN:
				if k != i:
					pool.append(k)
	var n := 0
	for k in pool:
		var o: Cd = binder[k]
		if o == null:
			continue
		if tag == "genre" and o.genre != int(h["genre"]):
			continue
		if tag == "era" and o.era != int(h["era"]):
			continue
		n += 1
	return n

func _amount(h: Dictionary, i: int) -> int:
	var n := _count(h, i)
	if bool(h["per"]):
		return n
	return 1 if n >= int(h["min"]) else 0

func _fire(cd: Cd, idx: int, h: Dictionary, bucket: String) -> void:
	if h.is_empty():
		return
	var n := _amount(h, idx)
	var at := _cell(idx).get_center()
	if n <= 0:
		_float_at(at, "no effect", c_muted)
		_log("%s %s: no effect." % [bucket.capitalize(), cd.band])
		return
	var g: Dictionary = h["gives"]
	var out: Array[String] = []
	if g.has("vp"):
		var v: int = int(g["vp"]) * n
		if bucket == "placed":
			vp_placed += v
		else:
			vp_played += v
		out.append("+%d VP" % v)
	if g.has("cash"):
		var c: int = int(g["cash"]) * n
		cash += c
		out.append("+%d Cash" % c)
	if g.has("play"):
		var p: int = int(g["play"]) * n
		plays += p
		plays_max += p
		out.append("+%d Play" % p)
	if g.has("draw"):
		var d: int = int(g["draw"]) * n
		var got := _draw_cds(d)
		out.append("Draw %d" % got)
	var s := ", ".join(out)
	_float_at(at, s, c_gold)
	_log("%s %s: %s." % [bucket.capitalize(), cd.band, s])

func _draw_cds(n: int) -> int:
	var got := 0
	for i in n:
		var cd := _pop_deck()
		if cd == null:
			break
		if hand.size() >= D.HAND_MAX:
			discard.append(cd)
			_say("Hand is full: the drawn CD was discarded")
			continue
		hand.append(cd)
		got += 1
	return got

func _buy(slot: int) -> void:
	var cd: Cd = row[slot]
	if cd == null:
		return
	if cash < cd.cost:
		_say("Not enough Cash")
		return
	if hand.size() >= D.HAND_MAX:
		_say("Your hand is full")
		return
	cash -= cd.cost
	hand.append(cd)
	row[slot] = _pop_deck()
	_log("Bought %s for $%d." % [cd.band, cd.cost])

func _refresh_row() -> void:
	if cash < D.REFRESH_COST:
		_say("Not enough Cash")
		return
	cash -= D.REFRESH_COST
	for i in row.size():
		if row[i] != null:
			discard.append(row[i])
	for i in row.size():
		row[i] = _pop_deck()
	_log("Paid $%d to refresh the row." % D.REFRESH_COST)

func _select(i: int) -> void:
	held = -1 if held == i else i

func _legal(i: int, cd: Cd) -> bool:
	var others := 0
	for k in BIN:
		if k != i and binder[k] != null:
			others += 1
	if others == 0:
		return true
	for k in _neighbors(i):
		var o: Cd = binder[k]
		if o != null and (o.genre == cd.genre or o.era == cd.era):
			return true
	return false

func _place(i: int) -> void:
	if held < 0 or held >= hand.size():
		return
	var cd: Cd = hand[held]
	if not _legal(i, cd):
		_say("Must share a genre or decade with a neighbour")
		return
	var old: Cd = binder[i]
	if old != null:
		discard.append(old)
		_log("%s replaced %s." % [cd.band, old.band])
	else:
		_log("Placed %s." % cd.band)
	binder[i] = cd
	cd.used = false
	hand.remove_at(held)
	held = -1
	_fire(cd, i, cd.placed, "placed")

func _play(i: int) -> void:
	var cd: Cd = binder[i]
	if cd == null:
		return
	if cd.used:
		_say("Already played this turn")
		return
	if plays <= 0:
		_say("No Plays left")
		return
	plays -= 1
	cd.used = true
	_fire(cd, i, cd.played, "played")

func _same(idx: Array, key: String) -> bool:
	var first: Cd = binder[idx[0]]
	if first == null:
		return false
	for k in idx:
		var o: Cd = binder[k]
		if o == null or o.get(key) != first.get(key):
			return false
	return true

func _tally(key: String, size: int) -> Array[int]:
	var out: Array[int] = []
	out.resize(size)
	out.fill(0)
	for o in binder:
		if o != null:
			out[o.get(key)] += 1
	return out

func _objective_score(id: String) -> int:
	var filled := 0
	for o in binder:
		if o != null:
			filled += 1
	match id:
		"genre_lines":
			var n := 0
			for line in LINES:
				if _same(line, "genre"):
					n += 1
			return n * 4
		"era_lines":
			var n := 0
			for line in LINES:
				if _same(line, "era"):
					n += 1
			return n * 4
		"corners":
			var seen := {}
			for k in CORNERS:
				var o: Cd = binder[k]
				if o == null:
					return 0
				seen[o.era] = true
			return 10 if seen.size() == CORNERS.size() else 0
		"full_page":
			return filled + (6 if filled == BIN else 0)
		"spread":
			var n := 0
			for c in _tally("genre", D.GENRES.size()):
				if c >= 2:
					n += 1
			return n * 3
		"specialist":
			return _tally("genre", D.GENRES.size()).max() * 2
		"hub":
			var mid: Cd = binder[4]
			if mid == null:
				return 0
			var n := 0
			for k in _neighbors(4):
				var o: Cd = binder[k]
				if o != null and o.genre == mid.genre:
					n += 1
			return n * 3
		"stash":
			return hand.size() + cash / 2
		"diagonal":
			var n := 0
			for line in [[0, 4, 8], [2, 4, 6]]:
				if _same(line, "genre"):
					n += 1
			return n * 10
		"decade_sweep":
			var n := 0
			for c in _tally("era", D.ERAS.size()):
				if c >= 2:
					n += 1
			return n * 4
	return 0

func _rank() -> String:
	var name := ""
	for r in D.RANKS:
		if _total() >= int(r["vp"]):
			name = String(r["name"])
	return name

func _cell(i: int) -> Rect2:
	return Rect2(r_grid.position + Vector2(i % 3 * (CARD_W + GAP), i / 3 * (CARD_H + GAP)), Vector2(CARD_W, CARD_H))

func _card_size(w: float) -> Vector2:
	return Vector2(w, w * CARD_H / CARD_W)

func _row_rect(i: int) -> Rect2:
	return Rect2(Vector2(ROW_X + i * (ROW_W + ROW_GAP), ROW_Y), _card_size(ROW_W))

func _hand_rect(i: int) -> Rect2:
	var r := Rect2(Vector2(HAND_X + i * HAND_STEP, HAND_Y), _card_size(HAND_W))
	if i == held:
		r.position.y -= 28.0
	return r

func _cover(path: String) -> Texture2D:
	if path == "":
		return null
	if not covers.has(path):
		covers[path] = load(path) if ResourceLoader.exists(path) else null
	return covers[path]

func _clip(s: String, width: float, size: int, bold: bool) -> String:
	if _text_w(s, size, bold) <= width:
		return s
	while s.length() > 1 and _text_w(s + "...", size, bold) > width:
		s = s.left(s.length() - 1)
	return s + "..."

func _cd_tip(cd: Cd) -> String:
	var lines: Array[String] = ["%s - %s" % [cd.band, cd.album], "%s, %s" % [D.GENRES[cd.genre], D.ERAS[cd.era]]]
	lines.append("PLACED: %s" % (String(cd.placed["text"]) if not cd.placed.is_empty() else "nothing"))
	lines.append("PLAYED: %s" % String(cd.played["text"]))
	return "\n".join(lines)

func _draw() -> void:
	_begin_draw()
	ui_live = phase == "turn"
	_draw_desk()
	_draw_header()
	_draw_row()
	if phase != "objective":
		_draw_objective_card(Rect2(1030.0, 206.0, 370.0, 434.0), objective, true)
	_draw_controls()
	_draw_log()
	_draw_note()
	_draw_hand()
	_draw_binder()
	_draw_floats()
	_draw_toast()
	ui_live = true
	if phase == "objective":
		_draw_pick()
	elif phase == "over":
		_draw_over()
	_end_draw()

func _draw_desk() -> void:
	_panel(Rect2(0.0, 0.0, UI_W, UI_H), C_FELT, 0)
	_grain(Rect2(0.0, 0.0, UI_W, UI_H), 11, 1100.0)
	if held >= 0:
		_register(Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0), func() -> void: held = -1)

func _play_token(c: Vector2, rad: float, filled: bool) -> void:
	if not filled:
		draw_arc(c, rad, 0.0, TAU, 28, Color(1, 1, 1, 0.3), 2.0, true)
		return
	draw_circle(c + Vector2(0.0, rad * 0.12), rad, Color(0, 0, 0, 0.3))
	draw_circle(c, rad, Color("e9b949"))
	draw_arc(c, rad * 0.78, 0.0, TAU, 28, Color("b98a1f"), maxf(1.5, rad * 0.1), true)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-0.28, -0.4) * rad, c + Vector2(0.46, 0.0) * rad, c + Vector2(-0.28, 0.4) * rad]), Color("7a5710"))

func _coin(c: Vector2, rad: float) -> void:
	draw_circle(c + Vector2(0.0, rad * 0.12), rad, Color(0, 0, 0, 0.3))
	draw_circle(c, rad, Color("c0c6cc"))
	draw_arc(c, rad * 0.78, 0.0, TAU, 24, Color("8d949c"), maxf(1.5, rad * 0.1), true)
	_text_center(Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0), "$", int(rad * 1.1), Color("565d66"), true)

func _draw_header() -> void:
	_heavy(Vector2(48.0, 84.0), "CD Collector", T_HERO - 8, C_PAPER)
	for t in D.TURNS:
		var c := Vector2(72.0 + t * 50.0, 138.0)
		var n := t + 1
		if n < turn or phase == "over":
			draw_circle(c, 20.0, Color(0, 0, 0, 0.35))
			_text_center(Rect2(c - Vector2(20, 20), Vector2(40, 40)), str(n), T_SM, Color(1, 1, 1, 0.4), true)
		elif n == turn:
			draw_circle(c, 23.0, c_gold)
			_text_center(Rect2(c - Vector2(23, 23), Vector2(46, 46)), str(n), T_MD, c_ink, true)
		else:
			draw_arc(c, 20.0, 0.0, TAU, 28, Color(1, 1, 1, 0.5), 2.0, true)
			_text_center(Rect2(c - Vector2(20, 20), Vector2(40, 40)), str(n), T_SM, Color(1, 1, 1, 0.7), true)
	_text(Vector2(860.0, 62.0), "PLAYS", T_SM, Color("c9d3c6"), true)
	for i in maxi(plays_max, D.PLAYS_PER_TURN):
		_play_token(Vector2(878.0 + i * 46.0, 96.0), 18.0, i < plays)
	_text(Vector2(860.0, 150.0), "CASH", T_SM, Color("c9d3c6"), true)
	for i in mini(cash, 14):
		_coin(Vector2(878.0 + i * 20.0, 180.0), 14.0)
	_text(Vector2(878.0 + mini(cash, 14) * 20.0 + 24.0, 190.0), str(cash), T_XL, C_PAPER, true)
	var pad := Rect2(1452.0, 24.0, 1052.0, 164.0)
	_shadow(pad, 14)
	_panel(pad, C_PAPER, 14)
	_text(Vector2(pad.position.x + 36.0, pad.position.y + 50.0), "VICTORY POINTS", T_MD, c_muted, true)
	_heavy(Vector2(pad.position.x + 36.0, pad.position.y + 136.0), str(_total()), T_HERO + 40, c_ink)
	var obj_now := _objective_score(String(objective["id"])) if not objective.is_empty() else 0
	var shown := final_objective if phase == "over" else obj_now
	_text_right(pad.end.x - 36.0, pad.position.y + 56.0, "from CDs you played   %d" % vp_played, T_MD, c_body)
	_text_right(pad.end.x - 36.0, pad.position.y + 100.0, "from CDs you placed   %d" % vp_placed, T_MD, c_body)
	_text_right(pad.end.x - 36.0, pad.position.y + 144.0, "objective (%s)   %d" % ["final" if phase == "over" else "if scored now", shown], T_MD, c_body)

func _draw_row() -> void:
	_text(Vector2(ROW_X, 222.0), "COMMUNITY ROW", T_SM, Color("c9d3c6"), true)
	_text(Vector2(ROW_X + 190.0, 222.0), "the left CD leaves when your turn ends", T_SM, Color("e4a08f"))
	var pile := Rect2(48.0, ROW_Y, 140.0, _card_size(ROW_W).y)
	for j in 4:
		_panel(Rect2(pile.position + Vector2(j * 3.0, -j * 3.0), pile.size), Color("2a3a55"), 12, Color("1b2638"), 3)
	_text_center(pile, "DECK", T_MD, Color(1, 1, 1, 0.7), true)
	_text_center(Rect2(pile.position + Vector2(0.0, 40.0), pile.size), str(deck.size()), T_XL, Color.WHITE, true)
	_text(Vector2(48.0, pile.end.y + 34.0), "Discard  %d" % discard.size(), T_SM, Color("c9d3c6"), true)
	for i in D.ROW_SIZE:
		var r := _row_rect(i)
		var cd: Cd = row[i]
		if cd == null:
			_panel(r, Color(0, 0, 0, 0.2), 14, Color(1, 1, 1, 0.2), 2)
			continue
		var ok := cash >= cd.cost and hand.size() < D.HAND_MAX
		_draw_cd(r, cd, true, not ok)
		_tip(r, _cd_tip(cd))
		if ui_live:
			_register(r, _buy.bind(i))

func _draw_controls() -> void:
	var refresh := Rect2(ROW_X, 566.0, 320.0, 64.0)
	_ghost(refresh, "Refresh row  $%d" % D.REFRESH_COST, _refresh_row, ui_live and cash >= D.REFRESH_COST, C_PAPER)
	var end := Rect2(refresh.end.x + 20.0, 566.0, 340.0, 64.0)
	var hover := ui_live and end.has_point(mouse)
	_shadow(end, 16, 5.0)
	_panel(end, c_gold.lightened(0.15) if hover else c_gold, 16)
	_text_center(end, "End turn  (%d Play%s left)" % [plays, "" if plays == 1 else "s"], T_MD, c_ink, true)
	if ui_live:
		_register(end, _end_turn)

func _draw_objective_card(r: Rect2, o: Dictionary, live: bool) -> void:
	if o.is_empty():
		return
	_shadow(r, 18)
	_panel(r, Color("f6efdc"), 18, Color("c9a227"), 6)
	var tag := Rect2(r.position + Vector2(24.0, 24.0), Vector2(r.size.x - 48.0, 40.0))
	_panel(tag, Color("c9a227"), 10)
	_text_center(tag, "OBJECTIVE", T_MD, Color.WHITE, true)
	_heavy_center(Rect2(r.position + Vector2(0.0, 84.0), Vector2(r.size.x, 60.0)), String(o["name"]), T_XL, c_ink)
	_wrap(r.position + Vector2(30.0, 170.0), String(o["text"]), r.size.x - 60.0, T_LG - 4, c_body, true)
	if live:
		var now := _objective_score(String(o["id"]))
		_text_i(r.position + Vector2(30.0, r.size.y - 36.0), "worth %d VP right now" % now, T_MD, c_muted)

func _draw_log() -> void:
	var r := Rect2(48.0, 660.0, 952.0, 350.0)
	_shadow(r, 10)
	_panel(r, C_PAPER, 10)
	_text(r.position + Vector2(28.0, 46.0), "TABLE LOG", T_MD, c_muted, true)
	var y := r.position.y + 86.0
	for i in range(log_lines.size() - 1, maxi(-1, log_lines.size() - 9), -1):
		draw_line(Vector2(r.position.x + 20.0, y + 8.0), Vector2(r.end.x - 20.0, y + 8.0), Color(0.3, 0.4, 0.6, 0.18), 2.0)
		_text(Vector2(r.position.x + 28.0, y), _clip(log_lines[i], r.size.x - 56.0, T_MD, false), T_MD, c_ink if i == log_lines.size() - 1 else c_body)
		y += 34.0

func _draw_note() -> void:
	var r := Rect2(1030.0, 660.0, 370.0, 350.0)
	_shadow(r, 6)
	_panel(r, Color("f2d96b"), 6)
	_text(r.position + Vector2(24.0, 44.0), "ON YOUR TURN", T_MD, Color("6b5a1d"), true)
	var lines := [
		"BUY a CD from the row.",
		"PLACE it in the binder next to a CD with the same genre or decade.",
		"PLAY a CD in the binder for 1 Play. Once per CD per turn.",
		"15 turns, most VP wins.",
	]
	_wrap(r.position + Vector2(24.0, 70.0), "\n\n".join(lines), r.size.x - 48.0, T_SM, Color("4a3f12"), true)

func _draw_hand() -> void:
	_text(Vector2(HAND_X, 1050.0), "YOUR HAND  %d/%d" % [hand.size(), D.HAND_MAX], T_SM, Color("c9d3c6"), true)
	for i in hand.size():
		var r := _hand_rect(i)
		var cd := hand[i]
		var legal := false
		for k in BIN:
			if _legal(k, cd):
				legal = true
				break
		_draw_cd(r, cd, false, false)
		if i == held:
			_panel(r.grow(5.0), Color(0, 0, 0, 0), 18, c_gold, 5)
		_tip(r, _cd_tip(cd))
		if ui_live:
			_register(r, _select.bind(i))

func _draw_binder() -> void:
	_shadow(p_binder, 28, 10.0)
	_panel(p_binder, C_LEATHER, 28)
	_grain(p_binder, 5, 120.0)
	_stitch_rect(p_binder.grow(-14.0), Color(1, 1, 1, 0.18))
	var page := r_grid.grow(16.0)
	_panel(page, Color("dfe4e8"), 12)
	for j in 4:
		var c := Vector2(page.position.x - 26.0, page.position.y + (j + 0.5) * page.size.y / 4.0)
		draw_circle(c + Vector2(0.0, 3.0), 22.0, Color(0, 0, 0, 0.3))
		draw_circle(c, 22.0, Color("aeb4bb"))
		draw_circle(c, 11.0, Color("5b616a"))
	for i in BIN:
		var r := _cell(i)
		var cd: Cd = binder[i]
		var can_place := held >= 0 and held < hand.size() and _legal(i, hand[held])
		if cd == null:
			_panel(r, Color(0.45, 0.5, 0.58, 0.22), 12, Color(1, 1, 1, 0.5), 2)
			_pocket_lip(r)
		else:
			_draw_cd(r, cd, false, false)
			if cd.used:
				_panel(r, Color(0, 0, 0, 0.4), 14)
				_play_token(r.get_center(), 44.0, true)
			_sleeve_gloss(r)
			_tip(r, _cd_tip(cd))
		if held >= 0 and can_place:
			var pulse := 0.55 + 0.35 * sin(clock * 5.0)
			_panel(r.grow(4.0), Color(0.3, 0.9, 0.5, 0.12), 16, Color(0.3, 0.9, 0.5, pulse), 6)
		elif held < 0 and cd != null and not cd.used and plays > 0:
			_panel(r.grow(3.0), Color(0, 0, 0, 0), 16, Color(c_gold, 0.35 + 0.2 * sin(clock * 3.0)), 4)
		if ui_live and held >= 0:
			_register(r, _place.bind(i))
		elif ui_live and cd != null:
			_register(r, _play.bind(i))

func _draw_cd(r: Rect2, cd: Cd, badge: bool, dim: bool) -> void:
	var k := r.size.x / CARD_W
	var gcol := Color(D.GENRE_COLORS[cd.genre])
	_shadow(r, int(14.0 * k), 6.0 * k)
	_panel(r, c_card, int(14.0 * k))
	var art := Rect2(r.position + Vector2(14.0, 14.0) * k, Vector2(CARD_W - 28.0, 130.0) * k)
	var tex := _cover(cd.cover)
	if tex != null:
		var ts := tex.get_size()
		draw_texture_rect_region(tex, art, Rect2(0.0, ts.y * 0.25, ts.x, ts.y * 0.5))
	else:
		_draw_art(art, cd.uid, cd.album, gcol, c_gold)
	var chip_g := Rect2(r.position + Vector2(14.0, 152.0) * k, Vector2(132.0, 28.0) * k)
	_panel(chip_g, gcol, int(8.0 * k))
	_text_center(chip_g, D.GENRES[cd.genre], _fs(16.0, k), Color.WHITE, true)
	var chip_e := Rect2(r.position + Vector2(154.0, 152.0) * k, Vector2(90.0, 28.0) * k)
	_panel(chip_e, Color(D.ERA_COLORS[cd.era]), int(8.0 * k))
	_text_center(chip_e, D.ERAS[cd.era], _fs(16.0, k), Color.WHITE, true)
	var tw := (CARD_W - 28.0) * k
	_text(r.position + Vector2(14.0, 206.0) * k, _clip(cd.band, tw, _fs(20.0, k), true), _fs(20.0, k), c_ink, true)
	_text_i(r.position + Vector2(14.0, 230.0) * k, _clip(cd.album, tw, _fs(16.0, k), false), _fs(16.0, k), c_muted)
	_hook_block(r, k, 248.0, "PLACED", cd.placed, C_PLACED)
	_hook_block(r, k, 296.0, "PLAYED", cd.played, C_PLAYED)
	if badge:
		var c := Vector2(r.end.x - 34.0 * k, r.position.y + 34.0 * k)
		draw_circle(c + Vector2(0.0, 3.0 * k), 24.0 * k, Color(0, 0, 0, 0.35))
		draw_circle(c, 24.0 * k, c_gold)
		_text_center(Rect2(c - Vector2(24, 24) * k, Vector2(48, 48) * k), "$%d" % cd.cost, _fs(24.0, k), c_ink, true)
	if dim:
		_panel(r, Color(0, 0, 0, 0.45), int(14.0 * k))

func _hook_block(r: Rect2, k: float, y: float, label: String, h: Dictionary, col: Color) -> void:
	var tag := Rect2(r.position + Vector2(14.0, y + 2.0) * k, Vector2(66.0, 20.0) * k)
	_panel(tag, col, int(5.0 * k))
	_text_center(tag, label, _fs(12.0, k), Color.WHITE, true)
	var txt := String(h["text"]) if not h.is_empty() else "-"
	_wrap(r.position + Vector2(88.0, y) * k, txt, (CARD_W - 104.0) * k, _fs(16.0, k), c_body if not h.is_empty() else c_muted, true, 3)

func _draw_floats() -> void:
	for f in floats:
		var p: Vector2 = f["pos"]
		var a := clampf(float(f["life"]) * 1.4, 0.0, 1.0)
		var s := String(f["text"])
		var w := _text_w(s, T_XL, true)
		_text(p + Vector2(-w * 0.5 + 2.0, 2.0), s, T_XL, Color(0, 0, 0, 0.6 * a), true)
		_text(p + Vector2(-w * 0.5, 0.0), s, T_XL, Color(f["col"], a), true)

func _draw_toast() -> void:
	if message_t <= 0.0:
		return
	var r := Rect2(48.0, 1346.0, 1352.0, 56.0)
	_panel(r, Color(c_ink, minf(1.0, message_t * 2.0) * 0.92), 14)
	_text_center(r, message, T_MD, Color(1, 1, 1, minf(1.0, message_t * 2.0)), true)

func _draw_pick() -> void:
	_panel(Rect2(0.0, 0.0, UI_W, UI_H), Color(0, 0, 0, 0.72), 0)
	_heavy_center(Rect2(0.0, 190.0, UI_W, 80.0), "Choose your objective", T_HERO, C_PAPER)
	_text_center(Rect2(0.0, 270.0, UI_W, 40.0), "It scores once, when the 15 turns are over.", T_LG, Color(1, 1, 1, 0.7))
	for i in offers.size():
		var r := Rect2(580.0 + i * 480.0, 380.0, 440.0, 560.0)
		var hover := r.has_point(mouse)
		_draw_objective_card(r.grow(10.0) if hover else r, offers[i], false)
		_register(r, _choose.bind(i))

func _draw_over() -> void:
	_panel(Rect2(0.0, 0.0, UI_W, UI_H), Color(0, 0, 0, 0.72), 0)
	var r := Rect2((UI_W - 900.0) * 0.5, 260.0, 900.0, 760.0)
	_shadow(r, 20)
	_panel(r, C_PAPER, 20)
	_heavy_center(Rect2(r.position.x, r.position.y + 40.0, r.size.x, 70.0), "The tour is over", T_XL + 8, c_ink)
	_heavy_center(Rect2(r.position.x, r.position.y + 130.0, r.size.x, 170.0), str(_total()), T_HERO + 90, c_ink)
	_text_center(Rect2(r.position.x, r.position.y + 270.0, r.size.x, 40.0), "victory points", T_LG, c_muted)
	_text_center(Rect2(r.position.x, r.position.y + 330.0, r.size.x, 50.0), _rank(), T_XL, C_PLAYED, true)
	var rows := [
		["CDs you played", vp_played],
		["CDs you placed", vp_placed],
		[String(objective["name"]), final_objective],
	]
	for i in rows.size():
		var y := r.position.y + 440.0 + i * 56.0
		_text(Vector2(r.position.x + 130.0, y), String(rows[i][0]), T_LG, c_body, true)
		_text_right(r.end.x - 130.0, y, "%d VP" % int(rows[i][1]), T_LG, c_ink, true)
	var btn := Rect2(r.position.x + (r.size.x - 360.0) * 0.5, r.end.y - 120.0, 360.0, 76.0)
	_shadow(btn, 16, 5.0)
	_panel(btn, c_gold.lightened(0.15) if btn.has_point(mouse) else c_gold, 16)
	_text_center(btn, "New game", T_LG, c_ink, true)
	_register(btn, _new_game)
