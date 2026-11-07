extends Node2D
class_name MegaCorpPrototype

@export_group("Run")
@export var total_rounds: int = 20
@export var start_res := {"cash": 10, "people": 2, "ip": 0, "infra": 0, "brand": 2}
@export var shop_size: int = 3
@export var base_dice: int = 3
@export var max_health: int = 5
@export var goal_base: float = 3.0
@export var goal_growth: float = 0.6
@export var goal_preview: int = 3
@export var early_goal_rounds: int = 4

@export_group("Feel")
@export var roll_seconds: float = 0.9
@export var flip_seconds: float = 0.7
@export var resolve_seconds: float = 1.4

enum Phase { BUILD, EVENT, ROLL, PLACE, RESOLVE, REPORT, GAMEOVER }

const GRID_COLS := 5
const GRID_ROWS := 3
const GRID_N := GRID_COLS * GRID_ROWS
const RES := ["cash", "people", "ip", "infra", "brand"]
const RES_NAMES := {"cash": "Cash", "people": "People", "ip": "IP", "infra": "Infra", "brand": "Brand"}
const RES_ONE := {"cash": "Cash", "people": "Person", "ip": "IP", "infra": "Infra", "brand": "Brand"}
const RES_TIPS := {
	"cash": "Cash is your money. If it runs out, your company closes!",
	"people": "People are the workers on your team.",
	"ip": "IP means ideas and inventions that belong to you.",
	"infra": "Infra means buildings, computers and machines.",
	"brand": "Brand is how much people know and like your company.",
}
const PAT_LABELS := {"any": "Any", "odd": "Odd", "even": "Even", "low": "1-3", "high": "4-6", "12": "1-2", "56": "5-6"}
const MAX_DICE := 5
const GOAL_WEIGHT := {"cash": 1.0, "people": 1.5, "brand": 2.0, "ip": 4.0, "infra": 4.0}

class Slot:
	var id := ""
	var card: Dictionary
	var flash := 0.0
	var fly_t := 1.0
	var fly_from := Vector2.ZERO

class Die:
	var face := 1
	var shown_face := 1
	var pos := Vector2.ZERO
	var home := Vector2.ZERO
	var start := Vector2.ZERO
	var slot := -1
	var roll_t := 0.0
	var roll_dur := 1.0
	var ang := 0.0
	var spin := 0.0
	var rest_ang := 0.0
	var flicker := 0.0

class FloatText:
	var pos: Vector2
	var vel: Vector2
	var life := 0.0
	var max_life := 1.0
	var text := ""
	var kind := ""
	var color := Color.WHITE

class UiButton:
	var rect: Rect2
	var cb: Callable

var c_board := Color("f6f0e4")
var c_board_dark := Color("ece3d1")
var c_board_line := Color("dccfb5")
var c_board_ink := Color("9a8b72")
var c_card := Color("fffdf8")
var c_ink := Color("24202d")
var c_muted := Color("857b8a")
var c_shadow := Color("4a3420")
var c_green := Color("1f9d55")
var c_orange := Color("f07f22")
var c_purple := Color("7c4fd8")
var c_blue := Color("2f6fe0")
var c_red := Color("e2453a")
var c_navy := Color("1f2b5c")
var kind_colors := {}

var phase := Phase.BUILD
var round_n := 1
var res := {}
var res_start := {}
var cash_start := 0
var grid: Array[Slot] = []
var shop: Array[String] = []
var deck: Array[String] = []
var event_deck: Array[int] = []
var event: Dictionary = {}
var event_t := 1.0
var event_applied := false
var event_blocked := false
var event_note := ""
var mods: Dictionary = {}
var shield := 0
var extra_dice := 0
var pending: Array[Dictionary] = []
var dice: Array[Die] = []
var drag_die: Die
var ledger: Array[Dictionary] = []
var round_notes: Array[String] = []
var report: Dictionary = {}
var resolve_t := 0.0
var lost := false
var health := 0
var heart_flash := 0.0
var goals: Array[Dictionary] = []
var goals_met := 0
var peak_cash := 0
var best_round := 0
var best_round_n := 0
var cards_bought := 0
var dice_used := 0
var chip_flash := {}
var floaters: Array[FloatText] = []

var buttons: Array[UiButton] = []
var ui_live := true
var tips_live := true
var hover_tip := ""
var mouse := Vector2.ZERO

var ui_size := Vector2(2560, 1440)
var window_size := Vector2.ZERO
var screen_rect := Rect2()
var ui_scale := 1.0
var clock := 0.0
var r_top := Rect2()
var r_shop := Rect2()
var r_grid := Rect2()
var r_news := Rect2()
var r_tray := Rect2()
var r_action := Rect2()

var font: Font
var font_bold: Font
var font_heavy: Font
var font_title: Font
var style := StyleBoxFlat.new()

var tone_buy: AudioStreamWAV
var tone_coin: AudioStreamWAV
var tone_bad: AudioStreamWAV
var tone_good: AudioStreamWAV
var tone_paper: AudioStreamWAV
var tone_rattle: AudioStreamWAV
var tone_clack: AudioStreamWAV
var tone_fanfare: AudioStreamWAV
var players: Array[AudioStreamPlayer] = []
var player_idx := 0

const CARD_W := 272.0
const CARD_H := 316.0
const CARD_GAP := 24.0
const SHOP_FOOT := 52.0
const SHOP_GAP := 14.0
const DIE_SIZE := 92.0
const SOCKET := 96.0
const BAND_H := 58.0

const T_XS := 14
const T_SM := 18
const T_MD := 22
const T_LG := 28
const T_XL := 40
const T_HERO := 60

const MARGIN := 40.0
const GAP := 28.0
const PAD := 28.0
const ZONE_HEAD := 66.0
const TOP_H := 140.0

func _ready() -> void:
	randomize()
	kind_colors = {"cash": c_green, "people": c_orange, "ip": c_purple, "infra": c_blue, "brand": c_red}
	_load_fonts()
	_build_audio()
	_recompute_layout()
	get_viewport().size_changed.connect(_recompute_layout)
	_new_run()

func _load_fonts() -> void:
	var path := "res://assets/fonts/Nunito-VariableFont_wght.ttf"
	if ResourceLoader.exists(path):
		var base: Font = load(path)
		var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
		var reg := FontVariation.new()
		reg.base_font = base
		reg.variation_opentype = {wght: 600}
		var bold := FontVariation.new()
		bold.base_font = base
		bold.variation_opentype = {wght: 850}
		var heavy := FontVariation.new()
		heavy.base_font = base
		heavy.variation_opentype = {wght: 1000}
		font = reg
		font_bold = bold
		font_heavy = heavy
	else:
		font = ThemeDB.fallback_font
		font_bold = ThemeDB.fallback_font
		font_heavy = ThemeDB.fallback_font
	var title_path := "res://assets/fonts/CherryBombOne-Regular.ttf"
	font_title = load(title_path) if ResourceLoader.exists(title_path) else font_heavy

func _recompute_layout() -> void:
	window_size = get_viewport_rect().size
	ui_scale = minf(window_size.x / ui_size.x, window_size.y / ui_size.y)
	screen_rect = Rect2((window_size - ui_size * ui_scale) * 0.5, ui_size * ui_scale)
	r_top = Rect2(MARGIN, 28.0, ui_size.x - MARGIN * 2.0, TOP_H)
	var top := r_top.end.y + GAP
	var bottom := ui_size.y - 28.0
	r_shop = Rect2(MARGIN, top, PAD * 2.0 + CARD_W, bottom - top)
	var grid_w := PAD * 2.0 + GRID_COLS * CARD_W + (GRID_COLS - 1) * CARD_GAP
	r_grid = Rect2(r_shop.end.x + GAP, top, grid_w, bottom - top)
	var rx := r_grid.end.x + GAP
	var rw := ui_size.x - MARGIN - rx
	r_news = Rect2(rx, top, rw, 490.0)
	r_tray = Rect2(rx, r_news.end.y + GAP, rw, 270.0)
	r_action = Rect2(rx, r_tray.end.y + GAP, rw, bottom - r_tray.end.y - GAP)

func _card(id: String) -> Dictionary:
	return MegaCorpCards.ABILITIES[id]

func _kcol(kind: String) -> Color:
	return kind_colors.get(kind, c_ink)

func _r(k: String) -> int:
	return int(res.get(k, 0))

func _has(need: Dictionary) -> bool:
	for k: String in need:
		if _r(k) < int(need[k]):
			return false
	return true

func _pat_ok(pat: String, face: int) -> bool:
	match pat:
		"any":
			return true
		"odd":
			return face % 2 == 1
		"even":
			return face % 2 == 0
		"low":
			return face <= 3
		"high":
			return face >= 4
		"12":
			return face <= 2
		"56":
			return face >= 5
	return str(face) == pat

func _pat_text(pat: String) -> String:
	return PAT_LABELS.get(pat, pat)

func _make_goals() -> void:
	goals.clear()
	var prev: Array = []
	for r in range(1, total_rounds + 1):
		var budget := goal_base + (r - 1) * goal_growth
		var pool: Array = ["cash", "people", "brand"] if r <= early_goal_rounds else RES.duplicate()
		pool.shuffle()
		for k in prev:
			if pool.has(k):
				pool.erase(k)
				pool.append(k)
		var kinds := 1 if r <= 5 else (2 if r <= 13 else 3)
		var g := {}
		for i in kinds:
			var k: String = pool[i]
			g[k] = maxi(1, roundi(budget / kinds / float(GOAL_WEIGHT[k])))
		goals.append(g)
		prev = g.keys()

func _goal_for(r: int) -> Dictionary:
	if r < 1 or r > goals.size():
		return {}
	var g: Dictionary = goals[r - 1].duplicate()
	var extra := int(mods.get("goal_cash", 0))
	if r == round_n and extra > 0:
		g["cash"] = int(g.get("cash", 0)) + extra
	return g

func _projected() -> Dictionary:
	var out := res.duplicate()
	if phase == Phase.PLACE:
		var prev := _preview()
		for k: String in prev:
			out[k] = int(out.get(k, 0)) + int(prev[k])
	return out

func _goal_ready() -> bool:
	var proj := _projected()
	var g := _goal_for(round_n)
	for k: String in g:
		if int(proj.get(k, 0)) < int(g[k]):
			return false
	return true

func _locked(c: Dictionary) -> bool:
	return (mods.get("lock", []) as Array).has(c["kind"])

func _count_cards(kind: String) -> int:
	var n := 0
	for s in grid:
		if s != null and (kind == "all" or s.card["kind"] == kind):
			n += 1
	return n

func _gain_of(c: Dictionary) -> Dictionary:
	var out: Dictionary = (c.get("gain", {}) as Dictionary).duplicate()
	if c.has("per"):
		var per: Dictionary = c["per"]
		var g: String = per["gain"]
		var amt := int(per["each"]) * _count_cards(per["cards"])
		out[g] = int(out.get(g, 0)) + amt
	var cm := int(mods.get("cash_mod", 0))
	if cm != 0 and int(out.get("cash", 0)) > 0:
		out["cash"] = maxi(0, int(out["cash"]) + cm)
	if str(mods.get("double", "")) == c["kind"]:
		for k: String in out:
			out[k] = int(out[k]) * 2
	return out

func _can_buy(c: Dictionary) -> bool:
	return _has(c.get("buy", {})) and _free_slot() >= 0

func _free_slot() -> int:
	for i in GRID_N:
		if grid[i] == null:
			return i
	return -1

# ---------------------------------------------------------------- run flow
func _new_run() -> void:
	round_n = 1
	res = start_res.duplicate()
	grid.clear()
	grid.resize(GRID_N)
	deck.clear()
	for id: String in MegaCorpCards.ABILITIES:
		var copies := int(_card(id).get("copies", 1))
		if MegaCorpCards.FIRST_SHOP.has(id):
			copies -= 1
		for n in copies:
			deck.append(id)
	deck.shuffle()
	for i in range(MegaCorpCards.FIRST_SHOP.size() - 1, -1, -1):
		deck.append(MegaCorpCards.FIRST_SHOP[i])
	shop.clear()
	event_deck.clear()
	pending.clear()
	shield = 0
	extra_dice = 0
	lost = false
	health = max_health
	heart_flash = 0.0
	goals_met = 0
	_make_goals()
	peak_cash = _r("cash")
	best_round = 0
	best_round_n = 0
	cards_bought = 0
	dice_used = 0
	floaters.clear()
	report = {}
	_start_round()

func _start_round() -> void:
	phase = Phase.BUILD
	mods = {}
	event = {}
	event_note = ""
	event_blocked = false
	event_t = 1.0
	dice.clear()
	drag_die = null
	ledger.clear()
	round_notes.clear()
	cash_start = _r("cash")
	res_start = res.duplicate()
	for id in shop:
		if id != "":
			deck.insert(0, id)
	shop.clear()
	for i in shop_size:
		if deck.is_empty():
			break
		shop.append(deck.pop_back())

func _change(k: String, amt: int, label: String, at: Vector2) -> void:
	if amt == 0:
		return
	var before := _r(k)
	res[k] = maxi(0, before + amt)
	amt = _r(k) - before
	if amt == 0:
		return
	if k == "cash":
		ledger.append({"label": label, "amt": amt})
	chip_flash[k] = 1.0
	_spawn_floater(at, _delta_text(k, amt), k, c_green if amt > 0 else c_red)

func _delta_text(k: String, amt: int) -> String:
	if k == "cash":
		return ("+$%d" if amt > 0 else "-$%d") % absi(amt)
	return "%+d" % amt

func _buy(i: int) -> void:
	if phase != Phase.BUILD or i >= shop.size() or shop[i] == "":
		return
	var id := shop[i]
	var c := _card(id)
	if not _can_buy(c):
		_play(tone_clack, 0.7, -10.0)
		return
	var slot := _free_slot()
	var from := _shop_rect(i)
	var buy: Dictionary = c.get("buy", {})
	for k: String in buy:
		_change(k, -int(buy[k]), "Bought %s" % c["name"], from.get_center())
	var s := Slot.new()
	s.id = id
	s.card = c
	s.fly_from = from.position
	s.fly_t = 0.0
	grid[slot] = s
	shop[i] = ""
	cards_bought += 1
	_play(tone_buy, 1.0, -8.0)

func _reveal_event() -> void:
	if phase != Phase.BUILD:
		return
	if event_deck.is_empty():
		for i in MegaCorpCards.EVENTS.size():
			event_deck.append(i)
		event_deck.shuffle()
	event = MegaCorpCards.EVENTS[event_deck.pop_back()]
	event_t = 0.0
	event_applied = false
	event_blocked = false
	event_note = ""
	mods = {}
	phase = Phase.EVENT
	_play(tone_paper, 1.0, -6.0)

func _apply_event() -> void:
	event_applied = true
	var at := _event_rect().get_center()
	if event.get("bad", false) and shield > 0:
		shield -= 1
		event_blocked = true
		event_note = "Your Lobbyist stopped it!"
		round_notes.append("%s was blocked by your Lobbyist" % event["name"])
		_play(tone_good, 1.0, -6.0)
		return
	mods = (event.get("mod", {}) as Dictionary).duplicate(true)
	var fx: Dictionary = event.get("fx", {})
	if event.has("if") and not _has(event["if"]):
		event_note = "You need %s first." % _need_words(event["if"])
		_play(tone_clack, 0.8, -8.0)
		return
	if event.has("unless") and _has(event["unless"]):
		event_note = "You were ready! Nothing lost."
		round_notes.append("You were ready for %s" % event["name"])
		_play(tone_good, 1.0, -6.0)
		return
	var bump := _event_bump() if event.get("scale", false) else 0
	for k: String in fx:
		var amt := int(fx[k])
		if k == "cash" and bump > 0:
			amt += bump * signi(amt)
		_change(k, amt, event["name"], at)
	if event.has("tax"):
		var t := floori(maxi(0, _r("cash")) * float(event["tax"]))
		if t > 0:
			_change("cash", -t, event["name"], at)
		else:
			event_note = "You had nothing to tax."
	_play(tone_bad if event.get("bad", false) else tone_good, 1.0, -6.0)

func _event_bump() -> int:
	return floori((round_n - 1) / 5.0)

func _need_words(need: Dictionary) -> String:
	var parts: Array[String] = []
	for k: String in need:
		parts.append("%d %s" % [int(need[k]), RES_NAMES[k]])
	return " and ".join(parts)

func _dice_count() -> int:
	return clampi(base_dice + extra_dice + int(mods.get("dice", 0)), 1, MAX_DICE)

func _start_roll() -> void:
	if phase != Phase.EVENT or event_t < 1.0:
		return
	var n := _dice_count()
	extra_dice = 0
	dice.clear()
	for i in n:
		var d := Die.new()
		d.face = randi_range(1, 6)
		d.shown_face = randi_range(1, 6)
		d.home = _tray_home(i, n)
		d.start = r_action.get_center() + Vector2(randf_range(-80.0, 80.0), 0.0)
		d.pos = d.start
		d.roll_dur = roll_seconds + i * 0.12
		d.roll_t = d.roll_dur
		d.spin = randf_range(-14.0, 14.0)
		d.rest_ang = randf_range(-0.22, 0.22)
		dice.append(d)
	phase = Phase.ROLL
	_play(tone_rattle, 1.0, -4.0)

func _tray_home(i: int, n: int) -> Vector2:
	var step := DIE_SIZE + 18.0
	var cx := r_tray.get_center().x - (n - 1) * step * 0.5 + i * step
	return Vector2(cx, r_tray.position.y + ZONE_HEAD + (r_tray.size.y - ZONE_HEAD) * 0.5 - 6.0)

func _die_on(i: int) -> Die:
	for d in dice:
		if d.slot == i:
			return d
	return null

func _place_block(d: Die, i: int) -> String:
	if i < 0 or i >= GRID_N or grid[i] == null:
		return "Empty space"
	var c := grid[i].card
	var other := _die_on(i)
	if other != null and other != d:
		return "This card already has a die"
	if _locked(c):
		return "Closed this round by %s" % event.get("name", "the news")
	var only := str(mods.get("only", ""))
	if only != "" and not _pat_ok(only, d.face):
		return "Only %s dice work this round" % only
	if not _pat_ok(c["pat"], d.face):
		return "This card needs a %s" % _pat_text(c["pat"])
	return ""

func _assign(d: Die, i: int) -> void:
	if i >= 0 and _place_block(d, i) != "":
		return
	d.slot = i
	_play(tone_clack, 1.0 if i >= 0 else 0.8, -10.0)

func _preview() -> Dictionary:
	var out := {}
	for d in dice:
		if d.slot < 0:
			continue
		var c := grid[d.slot].card
		if c.has("chance") or c.has("delay"):
			continue
		var g := _gain_of(c)
		for k: String in g:
			out[k] = int(out.get(k, 0)) + int(g[k])
	return out

func _confirm() -> void:
	if phase != Phase.PLACE:
		return
	var used: Array[int] = []
	for d in dice:
		if d.slot >= 0:
			used.append(d.slot)
	used.sort()
	dice_used += used.size()
	var gains := {}
	for i in used:
		gains[i] = _gain_of(grid[i].card)
	for i in used:
		var s := grid[i]
		var c := s.card
		var g: Dictionary = gains[i]
		var at := _slot_rect(i).get_center()
		s.flash = 1.0
		if c.has("chance"):
			if randf() >= float(c["chance"]):
				round_notes.append("%s missed. Better luck next time!" % c["name"])
				_spawn_floater(at, "Missed!", "", c_muted)
				continue
			round_notes.append("%s worked!" % c["name"])
		if c.has("delay"):
			pending.append({"rounds": int(c["delay"]) + 1, "fx": g, "label": c["name"], "slot": i})
			_spawn_floater(at, "On the way!", "", _kcol(c["kind"]))
		else:
			for k: String in g:
				_change(k, int(g[k]), c["name"], at)
		if c.has("later"):
			var later: Dictionary = c["later"]
			pending.append({"rounds": int(later["rounds"]) + 1, "fx": later["fx"], "label": "%s payback" % c["name"], "slot": i})
		if c.has("shield"):
			shield += int(c["shield"])
			_spawn_floater(at, "Shield up!", "", _kcol(c["kind"]))
		if c.has("extra_die"):
			extra_dice += int(c["extra_die"])
			_spawn_floater(at, "+1 die next round", "", _kcol(c["kind"]))
	if used.is_empty():
		_play(tone_clack, 0.8, -8.0)
	else:
		_play(tone_coin, 1.0, -6.0)
	phase = Phase.RESOLVE
	resolve_t = 0.0

func _close_round() -> void:
	for i in range(pending.size() - 1, -1, -1):
		var p := pending[i]
		p["rounds"] = int(p["rounds"]) - 1
		if int(p["rounds"]) <= 0:
			var fx: Dictionary = p["fx"]
			var at := _slot_rect(int(p["slot"])).get_center()
			for k: String in fx:
				_change(k, int(fx[k]), p["label"], at)
			round_notes.append("%s arrived" % p["label"])
			pending.remove_at(i)
	var goal := _goal_for(round_n)
	var met := _has(goal)
	if met:
		for k: String in goal:
			_change(k, -int(goal[k]), "Round goal", _goal_rect().get_center())
		goals_met += 1
	else:
		health -= 1
		heart_flash = 1.0
	var income := {}
	var order: Array[String] = []
	for e in ledger:
		var key: String = e["label"]
		if not income.has(key):
			income[key] = 0
			order.append(key)
		income[key] = int(income[key]) + int(e["amt"])
	var ins: Array = []
	var outs: Array = []
	for key in order:
		var v := int(income[key])
		if v > 0:
			ins.append([key, v])
		elif v < 0:
			outs.append([key, v])
	var deltas := {}
	for k: String in RES:
		if k != "cash":
			deltas[k] = _r(k) - int(res_start.get(k, 0))
	var net := _r("cash") - cash_start
	report = {"start": cash_start, "end": _r("cash"), "ins": ins, "outs": outs, "deltas": deltas, "notes": round_notes.duplicate(), "net": net, "goal": goal, "met": met}
	peak_cash = maxi(peak_cash, _r("cash"))
	if net > best_round or best_round_n == 0:
		best_round = net
		best_round_n = round_n
	lost = health <= 0
	dice.clear()
	phase = Phase.REPORT
	_play(tone_good if met else tone_bad, 1.0, -6.0)

func _continue_from_report() -> void:
	if phase != Phase.REPORT:
		return
	if lost or round_n >= total_rounds:
		phase = Phase.GAMEOVER
		if not lost:
			_play(tone_fanfare, 1.0, -4.0)
		return
	round_n += 1
	_start_round()

func _primary_action() -> void:
	match phase:
		Phase.BUILD:
			_reveal_event()
		Phase.EVENT:
			_start_roll()
		Phase.PLACE:
			_confirm()
		Phase.REPORT:
			_continue_from_report()
		Phase.GAMEOVER:
			_new_run()

# ---------------------------------------------------------------- audio
func _build_audio() -> void:
	tone_buy = _make_tone(PackedFloat32Array([660.0, 990.0]), 0.16, 0.05)
	tone_coin = _make_tone(PackedFloat32Array([988.0, 1319.0, 1976.0]), 0.45, 0.12)
	tone_good = _make_tone(PackedFloat32Array([523.0, 659.0, 784.0]), 0.5, 0.16)
	tone_bad = _make_tone(PackedFloat32Array([196.0, 233.0, 147.0]), 0.6, 0.2)
	tone_fanfare = _make_tone(PackedFloat32Array([523.0, 659.0, 784.0, 1046.0]), 1.2, 0.35)
	tone_paper = _make_rustle(0.45)
	tone_rattle = _make_rattle(0.9, 14)
	tone_clack = _make_rattle(0.12, 1)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

func _make_tone(freqs: PackedFloat32Array, dur: float, decay: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var s := 0.0
		for k in freqs.size():
			s += sin(TAU * freqs[k] * t) * exp(-t / (decay * (1.0 - k * 0.15))) / (1.0 + k * 0.8)
		var attack := minf(1.0, t / 0.004)
		var tail := minf(1.0, (dur - t) / 0.03)
		var v := int(clampf(s * 0.45 * attack * tail, -1.0, 1.0) * 30000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return _wav(bytes, rate)

func _make_rustle(dur: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var raw := randf() * 2.0 - 1.0
		lp = lp * 0.82 + raw * 0.18
		var swell := sin(t * PI) * 0.55
		var v := int(clampf(lp * swell + (raw - lp) * 0.2 * swell, -1.0, 1.0) * 26000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return _wav(bytes, rate)

func _make_rattle(dur: float, clicks: int) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for c in clicks:
		var at := int(n * (0.0 if clicks == 1 else pow(randf(), 0.7) * 0.85))
		var amp := 0.9 if clicks == 1 else lerpf(0.9, 0.25, float(at) / n)
		var f := randf_range(1100.0, 2200.0)
		var click_len := int(rate * 0.035)
		for k in click_len:
			if at + k >= n:
				break
			var t := float(k) / rate
			buf[at + k] += (sin(TAU * f * t) * 0.6 + (randf() * 2.0 - 1.0) * 0.4) * exp(-t / 0.006) * amp
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var v := int(clampf(buf[i] * 0.6, -1.0, 1.0) * 28000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return _wav(bytes, rate)

func _wav(bytes: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w

func _play(stream: AudioStreamWAV, pitch: float, vol_db: float) -> void:
	if players.is_empty() or stream == null:
		return
	var p := players[player_idx]
	player_idx = (player_idx + 1) % players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()

# ---------------------------------------------------------------- loop + input
func _ui_mouse() -> Vector2:
	return (get_local_mouse_position() - screen_rect.position) / maxf(ui_scale, 0.0001)

func _process(delta: float) -> void:
	clock += delta
	_update_dice(delta)
	if phase == Phase.ROLL:
		var settled := true
		for d in dice:
			if d.roll_t > 0.0:
				settled = false
		if settled:
			phase = Phase.PLACE
	if phase == Phase.EVENT and event_t < 1.0:
		event_t = minf(1.0, event_t + delta / maxf(flip_seconds, 0.05))
		if event_t >= 0.6 and not event_applied:
			_apply_event()
	if phase == Phase.RESOLVE:
		resolve_t += delta
		if resolve_t >= resolve_seconds:
			_close_round()
	for s in grid:
		if s != null:
			s.flash = maxf(0.0, s.flash - delta * 0.8)
			s.fly_t = minf(1.0, s.fly_t + delta * 2.2)
	heart_flash = maxf(0.0, heart_flash - delta * 0.8)
	for k: String in chip_flash.keys():
		chip_flash[k] = maxf(0.0, float(chip_flash[k]) - delta * 1.5)
	for i in range(floaters.size() - 1, -1, -1):
		var f := floaters[i]
		f.life -= delta
		f.pos += f.vel * delta
		f.vel.y += 40.0 * delta
		if f.life <= 0.0:
			floaters.remove_at(i)
	queue_redraw()

func _update_dice(delta: float) -> void:
	var um := _ui_mouse()
	for d in dice:
		if d.roll_t > 0.0:
			d.roll_t = maxf(0.0, d.roll_t - delta)
			var t := 1.0 - d.roll_t / d.roll_dur
			var e := 1.0 - pow(1.0 - t, 3.0)
			d.pos = d.start.lerp(d.home, e) + Vector2(0.0, -absf(sin(t * PI * 3.0)) * 60.0 * (1.0 - t))
			d.ang = d.rest_ang + d.spin * pow(1.0 - t, 2.0)
			d.flicker -= delta
			if d.flicker <= 0.0:
				d.flicker = 0.07
				d.shown_face = randi_range(1, 6)
			if d.roll_t <= 0.0:
				d.shown_face = d.face
				_play(tone_clack, randf_range(0.85, 1.15), -12.0)
			continue
		d.shown_face = d.face
		var goal := d.home
		if d == drag_die:
			goal = um
		elif d.slot >= 0:
			goal = _socket_rect(_slot_rect(d.slot)).get_center()
		var k := 1.0 if d == drag_die else 1.0 - exp(-delta * 16.0)
		d.pos = d.pos.lerp(goal, k)
		d.ang = lerpf(d.ang, 0.0 if d.slot >= 0 or d == drag_die else d.rest_ang, 1.0 - exp(-delta * 10.0))

func _die_at(p: Vector2) -> Die:
	for i in range(dice.size() - 1, -1, -1):
		var d := dice[i]
		if d.roll_t <= 0.0 and absf(p.x - d.pos.x) < DIE_SIZE * 0.55 and absf(p.y - d.pos.y) < DIE_SIZE * 0.55:
			return d
	return null

func _slot_at(p: Vector2) -> int:
	for i in GRID_N:
		if _slot_rect(i).has_point(p):
			return i
	return -1

func _unhandled_input(event_in: InputEvent) -> void:
	if event_in is InputEventMouseButton:
		var mb := event_in as InputEventMouseButton
		var ui_p := _ui_mouse()
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if phase == Phase.PLACE:
				var d := _die_at(ui_p)
				if d != null:
					drag_die = d
					_play(tone_clack, 1.25, -14.0)
					return
			var p := get_local_mouse_position()
			for i in range(buttons.size() - 1, -1, -1):
				if buttons[i].rect.has_point(p):
					buttons[i].cb.call()
					return
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and drag_die != null:
			var target := _slot_at(ui_p)
			if target >= 0:
				if _place_block(drag_die, target) == "":
					_assign(drag_die, target)
				else:
					_play(tone_clack, 0.6, -10.0)
			elif r_tray.grow(30.0).has_point(ui_p):
				_assign(drag_die, -1)
			drag_die = null
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and phase == Phase.PLACE:
			var d := _die_at(ui_p)
			if d != null and d.slot >= 0:
				_assign(d, -1)
	elif event_in is InputEventKey and event_in.pressed and not event_in.echo:
		var key := event_in as InputEventKey
		if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE:
			_primary_action()

func _spawn_floater(pos: Vector2, t: String, kind: String, col: Color) -> void:
	var f := FloatText.new()
	f.pos = pos + Vector2(randf_range(-14.0, 14.0), 0.0)
	f.vel = Vector2(0.0, -60.0)
	f.max_life = 1.6
	f.life = f.max_life
	f.text = t
	f.kind = kind
	f.color = col
	floaters.append(f)

# ---------------------------------------------------------------- layout
func _slot_rect(i: int) -> Rect2:
	var col := i % GRID_COLS
	var row := floori(float(i) / GRID_COLS)
	var gh := GRID_ROWS * CARD_H + (GRID_ROWS - 1) * CARD_GAP
	var y0 := r_grid.position.y + ZONE_HEAD + (r_grid.size.y - ZONE_HEAD - PAD - gh) * 0.5
	return Rect2(r_grid.position.x + PAD + col * (CARD_W + CARD_GAP), y0 + row * (CARD_H + CARD_GAP), CARD_W, CARD_H)

func _shop_rect(i: int) -> Rect2:
	return Rect2(r_shop.position.x + PAD, r_shop.position.y + ZONE_HEAD + i * (CARD_H + SHOP_FOOT + SHOP_GAP), CARD_W, CARD_H)

func _socket_rect(card: Rect2) -> Rect2:
	return Rect2(card.position.x + (card.size.x - SOCKET) * 0.5, card.position.y + BAND_H + 14.0, SOCKET, SOCKET)

func _event_rect() -> Rect2:
	var w := 440.0
	var h := 350.0
	return Rect2(r_news.get_center().x - w * 0.5, r_news.position.y + ZONE_HEAD + 18.0, w, h)

func _chip_rect(k: String) -> Rect2:
	var i := RES.find(k)
	var w := 196.0
	var h := 100.0
	var x0 := r_top.position.x + 470.0
	return Rect2(x0 + i * (w + 14.0), r_top.get_center().y - h * 0.5, w, h)

# ---------------------------------------------------------------- draw helpers
func _panel(r: Rect2, col: Color, radius: int = 18, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> void:
	_panel_corners(r, col, radius, radius, radius, radius, border, border_w)

func _panel_corners(r: Rect2, col: Color, tl: int, tr: int, br: int, bl: int, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> void:
	style.bg_color = col
	style.corner_radius_top_left = tl
	style.corner_radius_top_right = tr
	style.corner_radius_bottom_right = br
	style.corner_radius_bottom_left = bl
	style.border_color = border
	style.set_border_width_all(border_w)
	style.shadow_size = 0
	style.anti_aliasing = true
	draw_style_box(style, r)

func _shadow(r: Rect2, radius: int, depth: float = 8.0, alpha: float = 0.45) -> void:
	_panel(Rect2(r.position + Vector2(0.0, depth), r.size), Color(c_shadow, 0.5 * alpha), radius)
	_panel(Rect2(r.position + Vector2(-2.0, depth * 0.5), r.size + Vector2(4.0, 2.0)), Color(c_shadow, 0.18 * alpha), radius + 2)

func _f(bold: bool) -> Font:
	return font_bold if bold else font

func _text(pos: Vector2, s: String, size: int, col: Color, bold: bool = false) -> void:
	draw_string(_f(bold), pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _heavy(pos: Vector2, s: String, size: int, col: Color) -> void:
	draw_string(font_heavy, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _heavy_w(s: String, size: int) -> float:
	return font_heavy.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _heavy_right(right_x: float, y: float, s: String, size: int, col: Color) -> void:
	_heavy(Vector2(right_x - _heavy_w(s, size), y), s, size, col)

func _heavy_center(r: Rect2, s: String, size: int, col: Color) -> void:
	var y := r.position.y + (r.size.y + font_heavy.get_ascent(size) - font_heavy.get_descent(size)) * 0.5
	_heavy(Vector2(r.position.x + (r.size.x - _heavy_w(s, size)) * 0.5, y), s, size, col)

func _fit(s: String, max_w: float, size: int) -> int:
	var sz := size
	while sz > 12 and _heavy_w(s, sz) > max_w:
		sz -= 1
	return sz

func _text_w(s: String, size: int, bold: bool = false) -> float:
	return _f(bold).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _text_center(r: Rect2, s: String, size: int, col: Color, bold: bool = false) -> void:
	var f := _f(bold)
	var y := r.position.y + (r.size.y + f.get_ascent(size) - f.get_descent(size)) * 0.5
	draw_string(f, Vector2(r.position.x + (r.size.x - _text_w(s, size, bold)) * 0.5, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _wrap(pos: Vector2, s: String, width: float, size: int, col: Color, bold: bool = false, max_lines: int = -1, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_multiline_string(_f(bold), pos, s, align, width, size, max_lines, col)

func _register(r: Rect2, cb: Callable) -> void:
	if not ui_live:
		return
	var b := UiButton.new()
	b.rect = Rect2(screen_rect.position + r.position * ui_scale, r.size * ui_scale)
	b.cb = cb
	buttons.append(b)

func _tip(r: Rect2, text: String) -> void:
	if tips_live and r.has_point(mouse):
		hover_tip = text

func _screen_xform() -> Transform2D:
	return Transform2D(0.0, Vector2(ui_scale, ui_scale), 0.0, screen_rect.position)

func _dashed_rect(r: Rect2, col: Color, width: float = 3.0, dash: float = 16.0, gap: float = 12.0) -> void:
	var inset := 16.0
	var edges := [
		[r.position + Vector2(inset, 0), Vector2(r.end.x - inset, r.position.y)],
		[Vector2(r.end.x, r.position.y + inset), Vector2(r.end.x, r.end.y - inset)],
		[Vector2(r.end.x - inset, r.end.y), Vector2(r.position.x + inset, r.end.y)],
		[Vector2(r.position.x, r.end.y - inset), r.position + Vector2(0, inset)],
	]
	for e in edges:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var length := a.distance_to(b)
		var dir := (b - a) / maxf(length, 0.001)
		var t := 0.0
		while t < length:
			draw_line(a + dir * t, a + dir * minf(t + dash, length), col, width, true)
			t += dash + gap
	var corners := [
		[r.position + Vector2(inset, inset), PI, PI * 1.5],
		[Vector2(r.end.x - inset, r.position.y + inset), PI * 1.5, TAU],
		[r.end - Vector2(inset, inset), 0.0, PI * 0.5],
		[Vector2(r.position.x + inset, r.end.y - inset), PI * 0.5, PI],
	]
	for c in corners:
		draw_arc(c[0], inset, c[1], c[2], 8, col, width, true)

func _button(r: Rect2, label: String, cb: Callable, enabled: bool, face: Color, size: int = T_XL) -> void:
	var live := enabled and ui_live
	var hovered := live and r.has_point(mouse)
	var col := face if enabled else c_board_line
	var ink := Color.WHITE if enabled else c_board_ink
	var radius := int(minf(r.size.y * 0.5, 40.0))
	var pulse := 0.5 + 0.5 * sin(clock * 3.0) if enabled else 0.0
	if enabled:
		_panel(r.grow(6.0 + pulse * 5.0), Color(col, 0.12), radius + 8)
	_panel(Rect2(r.position + Vector2(0, 10), r.size), Color(c_shadow, 0.2), radius)
	_panel(Rect2(r.position + Vector2(0, 7), r.size), col.darkened(0.3), radius)
	var top := Rect2(r.position + Vector2(0, 3.0 if hovered else 0.0), r.size)
	_panel(top, col.lightened(0.08) if hovered else col, radius)
	_heavy_center(top, label, size, ink)
	if live:
		_register(r, cb)

func _star(c: Vector2, outer: float, inner: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + i * PI / 5.0
		var rad := outer if i % 2 == 0 else inner
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(pts, col)

func _icon(kind: String, c: Vector2, rad: float, ring: bool = false) -> void:
	var col := _kcol(kind)
	if ring:
		draw_circle(c, rad + 3.0, Color.WHITE)
	draw_circle(c + Vector2(0, rad * 0.1), rad, col.darkened(0.25))
	draw_circle(c, rad, col)
	var w := Color.WHITE
	match kind:
		"cash":
			var sz := int(rad * 1.35)
			var r := Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0)
			_heavy_center(r, "$", sz, w)
		"people":
			draw_circle(c + Vector2(0, -rad * 0.26), rad * 0.26, w)
			var pts := PackedVector2Array()
			var bc := c + Vector2(0, rad * 0.58)
			for i in 13:
				var a := PI + i * PI / 12.0
				pts.append(bc + Vector2(cos(a) * rad * 0.5, sin(a) * rad * 0.5))
			draw_colored_polygon(pts, w)
		"ip":
			draw_circle(c + Vector2(0, -rad * 0.14), rad * 0.38, w)
			draw_rect(Rect2(c + Vector2(-rad * 0.2, rad * 0.12), Vector2(rad * 0.4, rad * 0.3)), w)
			draw_rect(Rect2(c + Vector2(-rad * 0.14, rad * 0.46), Vector2(rad * 0.28, rad * 0.1)), w)
		"infra":
			var b := Rect2(c + Vector2(-rad * 0.38, -rad * 0.5), Vector2(rad * 0.76, rad * 0.98))
			draw_rect(b, w)
			for row in 3:
				for colm in 2:
					var wr := Rect2(b.position + Vector2(rad * 0.12 + colm * rad * 0.3, rad * 0.12 + row * rad * 0.28), Vector2(rad * 0.2, rad * 0.16))
					draw_rect(wr, col)
		"brand":
			_star(c, rad * 0.6, rad * 0.26, w)

func _shield_icon(c: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(-rad * 0.8, -rad * 0.75), c + Vector2(rad * 0.8, -rad * 0.75),
		c + Vector2(rad * 0.75, rad * 0.1), c + Vector2(0, rad), c + Vector2(-rad * 0.75, rad * 0.1)])
	draw_colored_polygon(pts, col)
	_star(c + Vector2(0, -rad * 0.05), rad * 0.4, rad * 0.18, Color.WHITE)

func _pip_offsets(face: int) -> Array:
	var a := 1.0
	match face:
		1:
			return [Vector2.ZERO]
		2:
			return [Vector2(-a, -a), Vector2(a, a)]
		3:
			return [Vector2(-a, -a), Vector2.ZERO, Vector2(a, a)]
		4:
			return [Vector2(-a, -a), Vector2(a, -a), Vector2(-a, a), Vector2(a, a)]
		5:
			return [Vector2(-a, -a), Vector2(a, -a), Vector2.ZERO, Vector2(-a, a), Vector2(a, a)]
	return [Vector2(-a, -a), Vector2(a, -a), Vector2(-a, 0), Vector2(a, 0), Vector2(-a, a), Vector2(a, a)]

func _draw_die_body(center: Vector2, size: float, face: int, body: Color, pip: Color, outline: Color = Color(0, 0, 0, 0)) -> void:
	var r := Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size))
	var radius := int(size * 0.2)
	_panel(Rect2(r.position + Vector2(0, size * 0.07), r.size), Color(body.darkened(0.25), body.a), radius)
	_panel(r, body, radius, outline, 4 if outline.a > 0.0 else 0)
	var spread := size * 0.26
	var pip_r := size * 0.085
	for o in _pip_offsets(face):
		draw_circle(center + o * spread, pip_r, pip)

func _cash_tag(pos: Vector2, amt: int, h: float, col: Color) -> float:
	var s := "$%d" % amt
	var sz := int(h * 0.72)
	var w := _heavy_w(s, sz) + h * 0.6
	var r := Rect2(pos.x, pos.y - h * 0.5, w, h)
	_panel(r, col, int(h * 0.5))
	_heavy_center(r, s, sz, Color.WHITE)
	return w

func _tokens(x: float, cy: float, d: Dictionary, rad: float, paint: bool = true) -> float:
	var start := x
	var first := true
	for k: String in RES:
		if not d.has(k) or int(d[k]) == 0:
			continue
		if not first:
			x += rad * 0.5
		first = false
		var n := absi(int(d[k]))
		if k == "cash":
			if paint:
				x += _cash_tag(Vector2(x, cy), n, rad * 2.0, c_green)
			else:
				x += _heavy_w("$%d" % n, int(rad * 2.0 * 0.72)) + rad * 1.2
			continue
		if n > 1:
			var s := "%dx" % n
			var sz := int(rad * 1.3)
			if paint:
				_heavy(Vector2(x, cy + rad * 0.45), s, sz, c_ink)
			x += _heavy_w(s, sz) + 2.0
		if paint:
			_icon(k, Vector2(x + rad, cy), rad, true)
		x += rad * 2.0
	return x - start

func _tokens_w(d: Dictionary, rad: float) -> float:
	return _tokens(0.0, 0.0, d, rad, false)

func _card_icon(kind: String, c: Vector2, rad: float) -> void:
	var w := rad * 1.5
	var h := rad * 2.0
	var r := Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))
	_panel(Rect2(r.position + Vector2(0, 2), r.size), Color(c_shadow, 0.25), int(rad * 0.3))
	if kind == "all":
		var cols: Array[Color] = [c_green, c_orange, c_purple, c_blue, c_red]
		_panel(r, Color.WHITE, int(rad * 0.3), c_ink, 2)
		for i in cols.size():
			draw_rect(Rect2(r.position.x + 3.0 + i * (w - 6.0) / cols.size(), r.position.y + 4.0, (w - 6.0) / cols.size(), h * 0.3), cols[i])
		return
	var col := _kcol(kind)
	_panel(r, Color.WHITE, int(rad * 0.3), col, 2)
	_panel_corners(Rect2(r.position, Vector2(w, h * 0.32)), col, int(rad * 0.3), int(rad * 0.3), 0, 0)
	_icon(kind, Vector2(c.x, c.y + h * 0.14), rad * 0.5)

func _ability_row(x: float, cy: float, c: Dictionary, rad: float, paint: bool) -> float:
	var start := x
	var gap := rad * 0.5
	var parts := 0
	var gain: Dictionary = c.get("gain", {})
	if not gain.is_empty():
		x += _tokens(x, cy, gain, rad, paint)
		parts += 1
	if c.has("per"):
		var per: Dictionary = c["per"]
		if parts > 0:
			x += gap
		x += _tokens(x, cy, {per["gain"]: per["each"]}, rad, paint)
		var word := "each"
		var sz := int(rad * 1.1)
		if paint:
			_text(Vector2(x + 5.0, cy + rad * 0.4), word, sz, c_ink, true)
		x += _text_w(word, sz, true) + 10.0
		if paint:
			_card_icon(per["cards"], Vector2(x + rad * 0.8, cy), rad)
		x += rad * 1.6
		parts += 1
	if c.has("shield"):
		if parts > 0:
			x += gap
		if paint:
			_shield_icon(Vector2(x + rad, cy), rad * 1.05, _kcol(c["kind"]))
		x += rad * 2.0
		parts += 1
	if c.has("extra_die"):
		if parts > 0:
			x += gap
		var s := "+%d" % int(c["extra_die"])
		var sz := int(rad * 1.3)
		if paint:
			_heavy(Vector2(x, cy + rad * 0.45), s, sz, c_ink)
		x += _heavy_w(s, sz) + 4.0
		if paint:
			_draw_die_body(Vector2(x + rad, cy), rad * 1.8, 3, Color.WHITE, c_ink, c_ink)
		x += rad * 2.0
	return x - start

# ---------------------------------------------------------------- draw
func _draw() -> void:
	buttons.clear()
	hover_tip = ""
	draw_rect(Rect2(Vector2.ZERO, window_size), c_board)
	mouse = _ui_mouse()
	draw_set_transform_matrix(_screen_xform())
	var modal := phase == Phase.REPORT or phase == Phase.GAMEOVER
	ui_live = not modal
	tips_live = not modal and drag_die == null
	_draw_board()
	_draw_top()
	_draw_shop()
	_draw_grid()
	_draw_news()
	_draw_tray()
	_draw_action()
	for d in dice:
		if d != drag_die:
			_draw_die(d)
	if drag_die != null:
		_draw_die(drag_die)
		var target := _slot_at(mouse)
		if target >= 0:
			var why := _place_block(drag_die, target)
			if why != "":
				_drag_hint(why, c_red)
	_draw_floaters()
	ui_live = true
	tips_live = true
	match phase:
		Phase.REPORT:
			_draw_report()
		Phase.GAMEOVER:
			_draw_gameover()
	if hover_tip != "":
		_draw_tooltip(hover_tip)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _drag_hint(text: String, col: Color) -> void:
	var hw := _heavy_w(text, T_MD) + 40.0
	var hr := Rect2(mouse + Vector2(40.0, 30.0), Vector2(hw, 50.0))
	if hr.end.x > ui_size.x - 12.0:
		hr.position.x = mouse.x - hw - 40.0
	_panel(hr, col, 25)
	_heavy_center(hr, text, T_MD, Color.WHITE)

func _draw_board() -> void:
	var b := Rect2(Vector2(-600, -600), ui_size + Vector2(1200, 1200))
	draw_rect(b, c_board)
	var step := 56.0
	var y := 0.0
	while y < ui_size.y:
		var x := 0.0
		while x < ui_size.x:
			draw_circle(Vector2(x, y), 2.2, Color(c_board_line, 0.55))
			x += step
		y += step
	var frame := Rect2(Vector2(12.0, 12.0), ui_size - Vector2(24.0, 24.0))
	_panel(frame, Color(0, 0, 0, 0), 32, Color(c_board_line, 0.9), 2)
	var cols: Array[Color] = [c_blue, c_green, c_red, c_purple, c_orange]
	var seg := (frame.size.x - 120.0) / cols.size()
	for i in cols.size():
		draw_line(Vector2(frame.position.x + 60.0 + i * seg, frame.end.y), Vector2(frame.position.x + 60.0 + (i + 1) * seg - 8.0, frame.end.y), cols[i], 6.0, true)
		draw_line(Vector2(frame.position.x + 60.0 + i * seg, frame.position.y), Vector2(frame.position.x + 60.0 + (i + 1) * seg - 8.0, frame.position.y), cols[i], 6.0, true)

func _zone(r: Rect2, num: int, title: String, accent: Color, active: bool) -> void:
	_panel(r, Color(c_board_dark, 0.75), 26, Color(accent, 0.9) if active else c_board_line, 4 if active else 2)
	var badge := Vector2(r.position.x + PAD + 20.0, r.position.y + 36.0)
	if num > 0:
		draw_circle(badge, 20.0, accent if active else c_board_ink)
		_heavy_center(Rect2(badge - Vector2(20, 20), Vector2(40, 40)), str(num), T_MD, Color.WHITE)
		_heavy(Vector2(badge.x + 32.0, r.position.y + 47.0), title, T_LG, c_ink if active else c_board_ink)
	else:
		_heavy(Vector2(r.position.x + PAD, r.position.y + 47.0), title, T_LG, c_ink if active else c_board_ink)

func _step_index() -> int:
	match phase:
		Phase.BUILD:
			return 0
		Phase.EVENT:
			return 1
		Phase.ROLL, Phase.PLACE, Phase.RESOLVE:
			return 2
	return 3

func _draw_top() -> void:
	_shadow(r_top, 28, 6.0, 0.3)
	_panel(r_top, c_card, 28)
	var title := "MEGA CORP"
	var cols: Array[Color] = [c_blue, c_green, c_red, c_purple, c_orange]
	var x := r_top.position.x + 36.0
	var ty := r_top.get_center().y + 14.0
	var ci := 0
	for ch in title:
		if ch == " ":
			x += 18.0
			continue
		var w := font_title.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 62).x
		draw_string(font_title, Vector2(x, ty + 4.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 62, Color(c_shadow, 0.25))
		draw_string(font_title, Vector2(x, ty), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 62, cols[ci % cols.size()])
		x += w
		ci += 1
	for i in max_health:
		var hc := _heart_pos(i)
		var full := i < health
		var shake := Vector2(sin(clock * 40.0) * 4.0 * heart_flash, 0.0) if i == health else Vector2.ZERO
		_heart(hc + Vector2(0, 3) + shake, 15.0, Color(c_shadow, 0.2))
		_heart(hc + shake, 15.0, c_red if full else c_board_line)
	_text(Vector2(_heart_pos(max_health - 1).x + 26.0, _heart_pos(0).y + 7.0), "Health", T_SM, c_muted, true)
	_tip(Rect2(r_top.position.x + 30.0, ty + 14.0, 240.0, 40.0), "Your company's health. You lose a heart when you miss a goal. Lose them all and the game is over!")
	var prev := _preview() if phase == Phase.PLACE else {}
	for k: String in RES:
		var r := _chip_rect(k)
		var col := _kcol(k)
		var fl := float(chip_flash.get(k, 0.0))
		_panel(r, col.lerp(Color.WHITE, 0.86 - fl * 0.3), 24, Color(col, 0.5 + fl * 0.5), 3)
		_icon(k, Vector2(r.position.x + 46.0, r.get_center().y), 30.0)
		var v := _r(k)
		var vs := ("$%d" % v) if k == "cash" else str(v)
		var vcol := c_red if k == "cash" and v <= 3 else c_ink
		_heavy(Vector2(r.position.x + 88.0, r.position.y + 56.0), vs, T_XL, vcol)
		_text(Vector2(r.position.x + 90.0, r.position.y + 84.0), RES_NAMES[k], T_SM, Color(col.darkened(0.25)), true)
		if prev.has(k) and int(prev[k]) != 0:
			var dv := int(prev[k])
			var ds := _delta_text(k, dv)
			var dw := _heavy_w(ds, T_SM) + 20.0
			var dr := Rect2(r.end.x - dw - 6.0, r.position.y - 14.0, dw, 32.0)
			_panel(dr, c_green if dv > 0 else c_red, 16)
			_heavy_center(dr, ds, T_SM, Color.WHITE)
		_tip(r, RES_TIPS[k])
	var steps := ["Buy", "News", "Roll", "Profit"]
	var step_cols: Array[Color] = [c_orange, c_purple, c_blue, c_green]
	var si := _step_index()
	var sx := _chip_rect("brand").end.x + 60.0
	var sy := r_top.get_center().y - 10.0
	for i in steps.size():
		var c := Vector2(sx + i * 130.0 + 30.0, sy)
		if i < steps.size() - 1:
			draw_line(c + Vector2(30, 0), c + Vector2(100, 0), c_board_line, 4.0, true)
		var on := i == si
		var done := i < si
		var rad := 30.0 if on else 24.0
		if on:
			draw_circle(c, rad + 7.0 + 3.0 * sin(clock * 4.0), Color(step_cols[i], 0.2))
		draw_circle(c, rad, step_cols[i] if on or done else c_board_dark)
		_heavy_center(Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0), str(i + 1), T_LG if on else T_MD, Color.WHITE if on or done else c_board_ink)
		var lw := _heavy_w(steps[i], T_SM)
		_heavy(Vector2(c.x - lw * 0.5, sy + 56.0), steps[i], T_SM, c_ink if on else c_board_ink)
	var rx := r_top.end.x - 380.0
	_heavy(Vector2(rx, r_top.position.y + 60.0), "Round %d" % round_n, T_XL, c_ink)
	_text(Vector2(rx + _heavy_w("Round %d" % round_n, T_XL) + 12.0, r_top.position.y + 60.0), "of %d" % total_rounds, T_MD, c_muted, true)
	for i in total_rounds:
		var col := i % 10
		var row := floori(i / 10.0)
		var dc := Vector2(rx + 14.0 + col * 34.0, r_top.position.y + 88.0 + row * 28.0)
		var filled := i < round_n - 1
		var now := i == round_n - 1
		var dcol: Color = cols[floori(i / 4.0) % cols.size()]
		if now:
			draw_circle(dc, 12.0, dcol)
			draw_circle(dc, 5.0, Color.WHITE)
		elif filled:
			draw_circle(dc, 9.0, dcol)
		else:
			draw_arc(dc, 8.0, 0.0, TAU, 20, c_board_line, 3.0, true)

func _draw_shop() -> void:
	var active := phase == Phase.BUILD
	_zone(r_shop, 1, "Shop", c_orange, active)
	for i in shop_size:
		var r := _shop_rect(i)
		if i >= shop.size() or shop[i] == "":
			_dashed_rect(r, c_board_line)
			_text_center(r, "Sold!" if i < shop.size() else "", T_LG, c_board_ink, true)
			continue
		var c := _card(shop[i])
		var ok := active and _can_buy(c)
		var hovered := ok and Rect2(r.position, r.size + Vector2(0, SHOP_FOOT)).has_point(mouse)
		var rr := Rect2(r.position + Vector2(0, -6.0 if hovered else 0.0), r.size)
		_draw_ability(rr, c, -1, not active or ok)
		var pr := Rect2(r.position.x, r.end.y + 8.0, r.size.x, SHOP_FOOT - 8.0)
		var buy: Dictionary = c.get("buy", {})
		var pcol := c_orange if ok else c_board_line
		_panel(Rect2(pr.position + Vector2(0, 4), pr.size), pcol.darkened(0.3) if ok else c_board_dark, 22)
		_panel(pr, pcol.lightened(0.1) if hovered else pcol, 22)
		var label := "Buy" if not buy.is_empty() else "Free!"
		var ink := Color.WHITE if ok else c_board_ink
		var tw := _tokens_w(buy, 14.0)
		var lw := _heavy_w(label, T_MD)
		var total := lw + (16.0 + tw if not buy.is_empty() else 0.0)
		var lx := pr.get_center().x - total * 0.5
		_heavy(Vector2(lx, pr.get_center().y + 8.0), label, T_MD, ink)
		if not buy.is_empty():
			_tokens(lx + lw + 16.0, pr.get_center().y, buy, 14.0)
		if active:
			var full := _free_slot() < 0
			var why := "Your board is full!" if full else ("Tap to buy!" if ok else "You need %s." % _need_words(buy))
			_tip(Rect2(r.position, r.size + Vector2(0, SHOP_FOOT)), "%s\n\n%s" % [_card_text(c), why])
			if ok:
				_register(Rect2(r.position, r.size + Vector2(0, SHOP_FOOT)), _buy.bind(i))
		else:
			_tip(r, _card_text(c))

func _hl_die() -> Die:
	if phase != Phase.PLACE:
		return null
	if drag_die != null:
		return drag_die
	var d := _die_at(mouse)
	return d

func _draw_grid() -> void:
	var active := phase == Phase.PLACE or phase == Phase.ROLL or phase == Phase.RESOLVE
	_zone(r_grid, 3, "Your Company", c_blue, active)
	var hint := ""
	match phase:
		Phase.BUILD:
			hint = "Cards you buy go here."
		Phase.PLACE:
			hint = "Drag a die onto a card with the same number."
	if hint != "":
		_text(Vector2(r_grid.end.x - PAD - _text_w(hint, T_MD, true), r_grid.position.y + 46.0), hint, T_MD, c_muted, true)
	var hd := _hl_die()
	for i in GRID_N:
		var r := _slot_rect(i)
		var s := grid[i]
		if s == null:
			_dashed_rect(r, c_board_line)
			_text_center(r, "Empty", T_MD, c_board_line, true)
			continue
		if s.fly_t < 1.0:
			var e := 1.0 - pow(1.0 - s.fly_t, 3.0)
			r.position = s.fly_from.lerp(r.position, e) + Vector2(0, -sin(e * PI) * 60.0)
		var bright := true
		var glow := false
		if hd != null:
			var why := _place_block(hd, i)
			if why == "" and _die_on(i) == null:
				glow = true
			elif why != "" and _die_on(i) != hd:
				bright = false
		if glow:
			var p := 0.5 + 0.5 * sin(clock * 6.0)
			_panel(r.grow(10.0 + p * 4.0), Color(c_green, 0.25 + p * 0.15), 28)
		_draw_ability(r, s.card, i, bright)
		if s.flash > 0.0:
			_panel(r.grow(6.0), Color(0, 0, 0, 0), 26, Color(Color.WHITE, s.flash), 6)
		var why_tip := ""
		if phase == Phase.PLACE and _locked(s.card):
			why_tip = "\n\nClosed this round by %s." % event.get("name", "")
		_tip(r, _card_text(s.card) + why_tip)

func _draw_ability(r: Rect2, c: Dictionary, slot: int, bright: bool) -> void:
	var kind: String = c["kind"]
	var kc := _kcol(kind)
	_shadow(r, 20, 7.0, 0.35)
	_panel(r, c_card, 20, Color(kc, 0.35), 2)
	_panel_corners(Rect2(r.position, Vector2(r.size.x, BAND_H)), kc, 20, 20, 0, 0)
	_icon(kind, r.position + Vector2(34.0, BAND_H * 0.5), 19.0, true)
	var nm: String = c["name"]
	var nsz := _fit(nm, r.size.x - 80.0, T_LG)
	_heavy(Vector2(r.position.x + 64.0, r.position.y + BAND_H * 0.5 + nsz * 0.36), nm, nsz, Color.WHITE)
	var sr := _socket_rect(r)
	var pat: String = c["pat"]
	_panel(sr, c_board, 20, Color(kc, 0.55), 4)
	if pat.is_valid_int():
		var face := int(pat)
		for o in _pip_offsets(face):
			draw_circle(sr.get_center() + o * SOCKET * 0.22, SOCKET * 0.075, Color(kc, 0.7))
	else:
		var label := _pat_text(pat)
		_heavy_center(sr, label, _fit(label, SOCKET - 14.0, T_XL), Color(kc, 0.8))
	var rad := 22.0
	while rad > 11.0 and _ability_row(0.0, 0.0, c, rad, false) > r.size.x - 28.0:
		rad -= 1.0
	var row_w := _ability_row(0.0, 0.0, c, rad, false)
	var y := sr.end.y + 44.0
	var row := Rect2(r.position.x + 10.0, y - 30.0, r.size.x - 20.0, 60.0)
	_panel(row, c_board, 30)
	_ability_row(r.get_center().x - row_w * 0.5, y, c, rad, true)
	if slot >= 0 and c.has("per"):
		var per: Dictionary = c["per"]
		var now := "= %s now" % _res_words({per["gain"]: int(per["each"]) * _count_cards(per["cards"])})
		_text(Vector2(r.get_center().x - _text_w(now, T_SM, true) * 0.5, y + 50.0), now, T_SM, c_muted, true)
	y += 66.0
	var note := _card_note(c)
	if note != "":
		var nr := Rect2(r.position.x + 12.0, y - 18.0, r.size.x - 24.0, 36.0)
		_panel(nr, kc.lerp(Color.WHITE, 0.85), 16)
		_text_center(nr, note, T_SM if _text_w(note, T_SM, true) < nr.size.x - 16.0 else T_XS, kc.darkened(0.35), true)
	if slot >= 0:
		var waits: Array[int] = []
		for p in pending:
			if int(p["slot"]) == slot:
				waits.append(int(p["rounds"]))
		if not waits.is_empty():
			var bc := Vector2(r.end.x - 10.0, r.position.y + 6.0)
			draw_circle(bc, 22.0, c_ink)
			draw_arc(bc, 16.0, 0.0, TAU, 24, Color.WHITE, 2.0, true)
			_heavy_center(Rect2(bc - Vector2(22, 22), Vector2(44, 44)), str(waits.min()), T_MD, Color.WHITE)
		if phase in [Phase.EVENT, Phase.ROLL, Phase.PLACE] and _locked(c):
			_panel(r, Color(c_board, 0.7), 20)
			var lr := Rect2(r.position.x + 30.0, r.get_center().y - 30.0, r.size.x - 60.0, 60.0)
			_panel(lr, c_red, 30)
			_heavy_center(lr, "CLOSED", T_LG, Color.WHITE)
			return
	if not bright:
		_panel(r, Color(c_board, 0.62), 20)

func _card_note(c: Dictionary) -> String:
	if c.has("delay"):
		return "Arrives in %d rounds" % int(c["delay"])
	if c.has("chance"):
		return "%d%% chance" % int(float(c["chance"]) * 100.0)
	if c.has("shield"):
		return "Blocks the next bad news"
	if c.has("extra_die"):
		return "+1 die next round"
	if c.has("later"):
		var later: Dictionary = c["later"]
		var fx: Dictionary = later["fx"]
		return "Pay back $%d in %d rounds" % [absi(int(fx.get("cash", 0))), int(later["rounds"])]
	return ""

func _res_words(d: Dictionary) -> String:
	var parts: Array[String] = []
	for k: String in RES:
		if not d.has(k):
			continue
		var n := absi(int(d[k]))
		if k == "cash":
			parts.append("$%d" % n)
		else:
			parts.append("%d %s" % [n, RES_ONE[k] if n == 1 else RES_NAMES[k]])
	return ", ".join(parts)

func _card_text(c: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("%s: roll %s to use it." % [c["name"], _pat_text(c["pat"]) if c["pat"] != "any" else "any number"])
	var gets: Array[String] = []
	if c.has("gain"):
		gets.append(_res_words(c["gain"]))
	if c.has("per"):
		var per: Dictionary = c["per"]
		var what := "card you own" if per["cards"] == "all" else "%s card you own" % RES_ONE[per["cards"]]
		gets.append("%s for each %s" % [_res_words({per["gain"]: per["each"]}), what])
	if not gets.is_empty():
		lines.append("Gives %s." % " and ".join(gets))
	var note := _card_note(c)
	if note != "":
		lines.append(note + ".")
	if c.has("buy"):
		lines.append("Shop price: %s." % _res_words(c["buy"]))
	return "\n".join(lines)

func _draw_news() -> void:
	var active := phase == Phase.EVENT
	_zone(r_news, 2, "Market News", c_purple, active)
	var r := _event_rect()
	var showing_front := not event.is_empty() and event_t >= 0.5
	var sx := 1.0
	if not event.is_empty() and event_t < 1.0:
		sx = absf(cos(event_t * PI))
	var center := r.get_center()
	var lift := sin(event_t * PI) * 30.0 if not event.is_empty() and event_t < 1.0 else 0.0
	draw_set_transform_matrix(_screen_xform() * Transform2D(0.0, Vector2(maxf(sx, 0.02), 1.0), 0.0, center + Vector2(0, -lift)))
	var lr := Rect2(-r.size * 0.5, r.size)
	_shadow(lr, 26, 10.0 + lift * 0.3, 0.4)
	if not showing_front:
		_panel(lr, c_navy, 26)
		_panel(lr.grow(-16.0), Color(0, 0, 0, 0), 18, Color(1, 1, 1, 0.25), 3)
		var cols: Array[Color] = [c_blue, c_green, c_red, c_purple, c_orange]
		for i in cols.size():
			draw_circle(Vector2(-80.0 + i * 40.0, 90.0), 12.0, cols[i])
		_heavy_center(Rect2(lr.position.x, -120.0, lr.size.x, 160.0), "?", 140, Color.WHITE)
		_heavy_center(Rect2(lr.position.x, 30.0, lr.size.x, 50.0), "NEWS", T_XL, Color(1, 1, 1, 0.85))
	else:
		var bad: bool = event.get("bad", false)
		var bc := c_red if bad else c_green
		_panel(lr, c_card, 26, Color(bc, 0.5), 3)
		_panel_corners(Rect2(lr.position, Vector2(lr.size.x, 70.0)), bc, 26, 26, 0, 0)
		_heavy_center(Rect2(lr.position, Vector2(lr.size.x, 70.0)), "Bad news!" if bad else "Good news!", T_LG, Color.WHITE)
		var nm: String = event["name"]
		_heavy_center(Rect2(lr.position.x, lr.position.y + 72.0, lr.size.x, 70.0), nm, _fit(nm, lr.size.x - 40.0, T_HERO - 8), c_ink)
		var desc := _event_desc()
		_wrap(Vector2(lr.position.x + 30.0, lr.position.y + 176.0), desc, lr.size.x - 60.0, T_LG, c_ink, true, 3, HORIZONTAL_ALIGNMENT_CENTER)
		if event_note != "":
			var nr := Rect2(lr.position.x + 24.0, lr.end.y - 72.0, lr.size.x - 48.0, 54.0)
			_panel(nr, (c_green if event_blocked or event_note.begins_with("You were") else c_board_dark), 30)
			_heavy_center(nr, event_note, _fit(event_note, nr.size.x - 30.0, T_MD), Color.WHITE if event_blocked or event_note.begins_with("You were") else c_ink)
	draw_set_transform_matrix(_screen_xform())
	if showing_front and event_blocked:
		draw_set_transform_matrix(_screen_xform() * Transform2D(-0.2, center + Vector2(0, 20)))
		var st := Rect2(-170, -44, 340, 88)
		_panel(st, Color(0, 0, 0, 0), 16, c_green, 8)
		_heavy_center(st, "BLOCKED", T_HERO, c_green)
		draw_set_transform_matrix(_screen_xform())
	if showing_front:
		_tip(r, _event_desc())
	var by := r.end.y + 46.0
	var bx := r_news.position.x + PAD
	if shield > 0:
		_shield_icon(Vector2(bx + 20.0, by - 8.0), 20.0, c_red)
		_text(Vector2(bx + 50.0, by), "Shield ready x%d" % shield, T_MD, c_ink, true)
		_tip(Rect2(bx, by - 30.0, 260.0, 40.0), "Your Lobbyist will block the next bad news.")

func _event_desc() -> String:
	var t: String = event.get("text", "")
	if event.get("scale", false):
		var fx: Dictionary = event.get("fx", {})
		if fx.has("cash"):
			var amt := int(fx["cash"])
			amt += _event_bump() * signi(amt)
			t += " (%s)" % (("$%d" % absi(amt)) if amt > 0 else ("-$%d" % absi(amt)))
	return t

func _draw_tray() -> void:
	var active := phase == Phase.ROLL or phase == Phase.PLACE
	_zone(r_tray, 0, "Dice", c_blue, active)
	var inner := Rect2(r_tray.position.x + PAD, r_tray.position.y + ZONE_HEAD, r_tray.size.x - PAD * 2.0, r_tray.size.y - ZONE_HEAD - PAD)
	_panel(inner, Color(c_navy, 0.9), 22)
	_panel(inner.grow(-8.0), Color(0, 0, 0, 0), 16, Color(1, 1, 1, 0.12), 2)
	if dice.is_empty():
		var n := _dice_count() if phase == Phase.EVENT else base_dice + extra_dice
		n = clampi(n, 1, MAX_DICE)
		for i in n:
			var h := _tray_home(i, n)
			_panel(Rect2(h - Vector2(DIE_SIZE, DIE_SIZE) * 0.5, Vector2(DIE_SIZE, DIE_SIZE)), Color(1, 1, 1, 0.08), 18, Color(1, 1, 1, 0.25), 2)
			_heavy_center(Rect2(h - Vector2(DIE_SIZE, DIE_SIZE) * 0.5, Vector2(DIE_SIZE, DIE_SIZE)), "?", T_XL, Color(1, 1, 1, 0.3))
	if extra_dice > 0 and dice.is_empty():
		_text(Vector2(r_tray.end.x - PAD - _text_w("+%d from Overtime" % extra_dice, T_SM, true), r_tray.position.y + 46.0), "+%d from Overtime" % extra_dice, T_SM, c_orange, true)

func _draw_die(d: Die) -> void:
	var size := DIE_SIZE
	if d.slot >= 0 and d != drag_die and d.roll_t <= 0.0:
		size = SOCKET - 12.0
	var hovered := phase == Phase.PLACE and drag_die == null and _die_at(mouse) == d
	var lift := 1.1 if d == drag_die else (1.05 if hovered else 1.0)
	draw_set_transform_matrix(_screen_xform() * Transform2D(d.ang, Vector2(lift, lift), 0.0, d.pos))
	if d.slot < 0 or d == drag_die:
		var depth := 24.0 if d == drag_die else 10.0
		_panel(Rect2(Vector2(-size, -size) * 0.5 + Vector2(4, depth), Vector2(size, size)), Color(0, 0, 0, 0.3), int(size * 0.2))
	var outline := Color(0, 0, 0, 0)
	if hovered:
		outline = c_orange
	elif d.slot >= 0 and grid[d.slot] != null:
		outline = _kcol(grid[d.slot].card["kind"])
	_draw_die_body(Vector2.ZERO, size, d.shown_face, Color.WHITE, c_ink, outline)
	draw_set_transform_matrix(_screen_xform())

func _heart_pos(i: int) -> Vector2:
	return Vector2(r_top.position.x + 58.0 + i * 40.0, r_top.get_center().y + 42.0)

func _heart(c: Vector2, rad: float, col: Color) -> void:
	draw_circle(c + Vector2(-rad * 0.5, -rad * 0.15), rad * 0.55, col)
	draw_circle(c + Vector2(rad * 0.5, -rad * 0.15), rad * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-rad * 1.01, rad * 0.05), c + Vector2(rad * 1.01, rad * 0.05), c + Vector2(0, rad * 1.1)]), col)

func _goal_rect() -> Rect2:
	return Rect2(r_action.position.x + PAD, r_action.position.y + ZONE_HEAD, r_action.size.x - PAD * 2.0, 84.0)

func _fit_tokens(d: Dictionary, max_w: float, rad: float) -> float:
	while rad > 9.0 and _tokens_w(d, rad) > max_w:
		rad -= 1.0
	return rad

func _draw_action() -> void:
	_zone(r_action, 4, "Round Goal", c_green, phase == Phase.PLACE or phase == Phase.RESOLVE)
	var x := r_action.position.x + PAD
	var sub := "Pay it at the end!"
	_text(Vector2(r_action.end.x - PAD - _text_w(sub, T_SM, true), r_action.position.y + 46.0), sub, T_SM, c_muted, true)
	var gr := _goal_rect()
	var goal := _goal_for(round_n)
	var ready := _goal_ready()
	_panel(gr, c_green.lerp(Color.WHITE, 0.82) if ready else c_card, 22, c_green if ready else c_board_line, 3)
	var grad := _fit_tokens(goal, gr.size.x - 200.0, 24.0)
	_tokens(gr.position.x + 22.0, gr.get_center().y, goal, grad)
	var status := "Ready!" if ready else "Not yet"
	var sr := Rect2(gr.end.x - 150.0, gr.get_center().y - 24.0, 134.0, 48.0)
	_panel(sr, c_green if ready else c_board_dark, 24)
	_heavy_center(sr, status, T_MD, Color.WHITE if ready else c_board_ink)
	_tip(gr, "This round's goal: %s.\nAt the end of the round you pay it. If you can't, your company loses a heart!" % _res_words(goal))
	var cy := gr.end.y + 16.0
	var n := mini(goal_preview, total_rounds - round_n)
	var cw := (gr.size.x - 12.0 * (goal_preview - 1)) / goal_preview
	for i in goal_preview:
		var cr := Rect2(gr.position.x + i * (cw + 12.0), cy, cw, 54.0)
		if i >= n:
			_dashed_rect(cr, c_board_line, 2.0, 10.0, 8.0)
			continue
		var rn := round_n + i + 1
		var g := _goal_for(rn)
		_panel(cr, Color(c_card, 0.7), 18, c_board_line, 2)
		var rl := "R%d" % rn
		_heavy(Vector2(cr.position.x + 12.0, cr.get_center().y + 7.0), rl, T_SM, c_board_ink)
		var lw := _heavy_w(rl, T_SM) + 20.0
		var rad := _fit_tokens(g, cr.size.x - lw - 12.0, 15.0)
		_tokens(cr.position.x + lw, cr.get_center().y, g, rad)
		_tip(cr, "Round %d goal: %s." % [rn, _res_words(g)])
	var hint := ""
	var label := ""
	var col := c_blue
	var enabled := true
	match phase:
		Phase.BUILD:
			hint = "Buy cards from the shop. Then see the news!"
			label = "See the News"
			col = c_purple
		Phase.EVENT:
			hint = "Uh oh, what happened? Now roll the dice!" if event.get("bad", false) else "Yay! Now roll the dice!"
			label = "Roll Dice"
			col = c_blue
			enabled = event_t >= 1.0
		Phase.ROLL:
			hint = "Rolling..."
			label = "Rolling..."
			enabled = false
		Phase.PLACE:
			var placed := 0
			for d in dice:
				if d.slot >= 0:
					placed += 1
			hint = "Drag dice onto cards. Then tap Done!" if placed == 0 else "%d of %d dice placed. Tap Done when ready!" % [placed, dice.size()]
			label = "Done!"
			col = c_green
		Phase.RESOLVE:
			hint = "Your company is working hard..."
			label = "Working..."
			enabled = false
		_:
			hint = ""
			label = "..."
			enabled = false
	_text(Vector2(x, cy + 54.0 + 36.0), hint, T_SM if _text_w(hint, T_MD, true) > gr.size.x else T_MD, c_muted, true)
	var br := Rect2(x, r_action.end.y - PAD - 92.0, r_action.size.x - PAD * 2.0, 92.0)
	_button(br, label, _primary_action, enabled, col, T_XL)

func _draw_floaters() -> void:
	for f in floaters:
		var a := clampf(f.life / f.max_life * 1.8, 0.0, 1.0)
		var tw := _heavy_w(f.text, T_LG)
		var iw := 44.0 if f.kind != "" and f.kind != "cash" else 0.0
		var w := tw + iw + 36.0
		var pill := Rect2(f.pos.x - w * 0.5, f.pos.y - 26.0, w, 52.0)
		_panel(pill, Color(c_card, 0.97 * a), 26, Color(f.color, 0.8 * a), 4)
		var tx := pill.position.x + 18.0
		if iw > 0.0:
			_icon(f.kind, Vector2(tx + 18.0, pill.get_center().y), 18.0)
			tx += iw
		_heavy(Vector2(tx, pill.get_center().y + 10.0), f.text, T_LG, Color(f.color, a))

func _draw_tooltip(text: String) -> void:
	var w := 460.0
	var size := T_MD
	var ts := font_bold.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, size)
	var box := Rect2(mouse + Vector2(24.0, 24.0), Vector2(ts.x + 36.0, ts.y + 26.0))
	if box.end.x > ui_size.x - 12.0:
		box.position.x = mouse.x - box.size.x - 16.0
	if box.end.y > ui_size.y - 12.0:
		box.position.y = mouse.y - box.size.y - 16.0
	_panel(Rect2(box.position + Vector2(0, 6), box.size), Color(0, 0, 0, 0.3), 14)
	_panel(box, c_ink, 14)
	_wrap(box.position + Vector2(18.0, 13.0 + font_bold.get_ascent(size)), text, w, size, c_card, true)

func _dim() -> void:
	draw_rect(Rect2(Vector2(-600, -600), ui_size + Vector2(1200, 1200)), Color(0.13, 0.10, 0.08, 0.66))

func _draw_report() -> void:
	_dim()
	var ins: Array = report.get("ins", [])
	var outs: Array = report.get("outs", [])
	var notes: Array = report.get("notes", [])
	var deltas: Dictionary = report.get("deltas", {})
	var row_h := 46.0
	var w := 1000.0
	var h := 230.0 + 60.0 + maxi(1, ins.size()) * row_h + 60.0 + maxi(1, outs.size()) * row_h + 150.0 + 110.0 + 90.0 + notes.size() * 34.0 + 140.0
	var r := Rect2((ui_size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_shadow(r, 30, 14.0)
	_panel(r, c_card, 30)
	_panel_corners(Rect2(r.position, Vector2(w, 16.0)), c_green, 30, 30, 0, 0)
	var x := r.position.x + 60.0
	var right := r.end.x - 60.0
	var y := r.position.y + 96.0
	_heavy(Vector2(x, y), "Round %d: Profit & Loss" % round_n, T_HERO - 6, c_ink)
	y += 60.0
	_text(Vector2(x, y), "Cash at the start", T_LG, c_muted, true)
	_heavy_right(right, y, "$%d" % int(report.get("start", 0)), T_LG, c_ink)
	y += 56.0
	_heavy(Vector2(x, y), "Money in", T_LG, c_green)
	y += 8.0
	if ins.is_empty():
		y += row_h
		_text(Vector2(x + 30.0, y - 12.0), "Nothing this round", T_MD, c_muted, true)
	for ln in ins:
		y += row_h
		_text(Vector2(x + 30.0, y - 12.0), str(ln[0]), T_MD, c_ink, true)
		_heavy_right(right, y - 12.0, "+$%d" % int(ln[1]), T_LG, c_green)
	y += 56.0
	_heavy(Vector2(x, y), "Money out", T_LG, c_red)
	y += 8.0
	if outs.is_empty():
		y += row_h
		_text(Vector2(x + 30.0, y - 12.0), "Nothing this round", T_MD, c_muted, true)
	for ln in outs:
		y += row_h
		_text(Vector2(x + 30.0, y - 12.0), str(ln[0]), T_MD, c_ink, true)
		_heavy_right(right, y - 12.0, "-$%d" % absi(int(ln[1])), T_LG, c_red)
	y += 30.0
	draw_line(Vector2(x, y), Vector2(right, y), c_board_line, 3.0)
	var net := int(report.get("net", 0))
	y += 60.0
	_heavy(Vector2(x, y), "Profit!" if net > 0 else ("Loss" if net < 0 else "Broke even"), T_XL, c_green if net > 0 else (c_red if net < 0 else c_muted))
	_heavy_right(right, y, ("+$%d" if net >= 0 else "-$%d") % absi(net), T_XL, c_green if net > 0 else (c_red if net < 0 else c_muted))
	y += 70.0
	var end_cash := int(report.get("end", 0))
	_heavy(Vector2(x, y), "Cash now", T_XL, c_ink)
	var ecol := c_red if end_cash <= 0 else c_ink
	_heavy_right(right, y + 6.0, "$%d" % end_cash, T_HERO, ecol)
	y += 40.0
	var dx := x
	var any_delta := false
	for k: String in RES:
		if k == "cash":
			continue
		var dv := int(deltas.get(k, 0))
		if dv == 0:
			continue
		any_delta = true
		_icon(k, Vector2(dx + 22.0, y + 30.0), 22.0)
		var ds := "%+d %s" % [dv, RES_NAMES[k]]
		_heavy(Vector2(dx + 52.0, y + 40.0), ds, T_MD, c_green if dv > 0 else c_red)
		dx += 52.0 + _heavy_w(ds, T_MD) + 30.0
	if not any_delta:
		_text(Vector2(x, y + 40.0), "Your other stuff stayed the same.", T_MD, c_muted, true)
	y += 70.0
	var goal: Dictionary = report.get("goal", {})
	var met: bool = report.get("met", false)
	var gb := Rect2(x, y, right - x, 72.0)
	_panel(gb, c_green.lerp(Color.WHITE, 0.82) if met else c_red.lerp(Color.WHITE, 0.85), 22, c_green if met else c_red, 3)
	_heavy(Vector2(gb.position.x + 22.0, gb.get_center().y + 10.0), "Goal", T_LG, c_ink)
	_tokens(gb.position.x + 110.0, gb.get_center().y, goal, _fit_tokens(goal, 360.0, 20.0))
	var verdict := "Paid! Goal met" if met else "Missed! Lost a heart"
	_heavy_right(gb.end.x - 22.0, gb.get_center().y + 10.0, verdict, T_LG, c_green if met else c_red)
	y += 90.0
	for n in notes:
		y += 34.0
		_text(Vector2(x, y), "• " + str(n), T_MD, c_purple, true)
	var label := "Next Round"
	var col := c_blue
	if lost:
		label = "Uh oh..."
		col = c_red
		_heavy(Vector2(x, r.end.y - 62.0), "No hearts left!", T_LG, c_red)
	elif round_n >= total_rounds:
		label = "You made it!"
		col = c_green
	_button(Rect2(right - 340.0, r.end.y - 52.0 - 80.0, 340.0, 80.0), label, _continue_from_report, true, col, T_LG)

func _draw_gameover() -> void:
	_dim()
	var w := 1000.0
	var h := 720.0
	var r := Rect2((ui_size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_shadow(r, 30, 14.0)
	_panel(r, c_card, 30)
	var won := not lost
	_panel_corners(Rect2(r.position, Vector2(w, 16.0)), c_green if won else c_red, 30, 30, 0, 0)
	var x := r.position.x + 64.0
	var right := r.end.x - 64.0
	var title := "Mega Corp made it!" if won else "Out of hearts!"
	_heavy(Vector2(x, r.position.y + 110.0), title, T_HERO + 8, c_green if won else c_red)
	var sub := "Your company survived all %d rounds." % total_rounds if won else "Your company missed too many goals by round %d." % round_n
	_text(Vector2(x, r.position.y + 162.0), sub, T_LG, c_muted, true)
	var stats := [
		["Goals met", "%d of %d" % [goals_met, round_n]],
		["Cash at the end", "$%d" % _r("cash")],
		["Most cash", "$%d" % peak_cash],
		["Best round", ("Round %d (+$%d)" % [best_round_n, best_round]) if best_round > 0 else "None"],
		["Cards bought", str(cards_bought)],
		["Dice used", str(dice_used)],
	]
	var y := r.position.y + 250.0
	for st in stats:
		_text(Vector2(x, y), st[0], T_LG, c_muted, true)
		_heavy_right(right, y, st[1], T_XL, c_ink)
		y += 64.0
	_button(Rect2(right - 340.0, r.end.y - 56.0 - 84.0, 340.0, 84.0), "Play Again", _new_run, true, c_blue, T_XL)
