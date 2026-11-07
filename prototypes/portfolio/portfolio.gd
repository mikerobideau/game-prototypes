extends Node2D
class_name PortfolioPrototype

@export_group("Run")
@export var total_turns: int = 20
@export var starting_cash: float = 40.0
@export var offer_size: int = 3
@export var dice_count: int = 3
@export var restricted_cells: int = 6

@export_group("Margin call")
@export var margin_base: float = 30.0
@export var margin_growth: float = 1.06

@export_group("Trouble")
@export var trouble_base: float = 0.10
@export var trouble_per_turn: float = 0.0075
@export var trouble_spread: float = 0.05

@export_group("Businesses")
@export var cap_values := {"penny": 6.0, "small": 12.0, "mid": 20.0, "blue": 32.0}

@export_group("Feel")
@export var roll_seconds: float = 0.9

enum Phase { BUILD, TROUBLE, ROLL, PLACE, RESULT, GAMEOVER }

const COLS := 4
const ROWS := 3
const CELLS := COLS * ROWS
const COLOR_NAMES := ["red", "orange", "yellow", "green", "blue", "purple"]
const ROW_NAMES := ["North Street", "Market Street", "South Street"]
const COL_NAMES := ["1st Avenue", "2nd Avenue", "3rd Avenue", "4th Avenue"]

var sector_defs := {
	"Retail": {"color": 1, "trouble": "Retail slump"},
	"Industry": {"color": 0, "trouble": "Strike wave"},
	"Finance": {"color": 3, "trouble": "Rate hike"},
	"Tech": {"color": 4, "trouble": "Tech selloff"},
	"Services": {"color": 5, "trouble": "New regulations"},
}
var cap_defs := {
	"penny": {"label": "Penny", "plural": "Penny stocks", "trouble": "Penny purge", "chip": Color("b8692f")},
	"small": {"label": "Small Cap", "plural": "Small caps", "trouble": "Small cap squeeze", "chip": Color("6b7486")},
	"mid": {"label": "Mid Cap", "plural": "Mid caps", "trouble": "Mid cap wobble", "chip": Color("3f5f7a")},
	"blue": {"label": "Blue Chip", "plural": "Blue chips", "trouble": "Blue chip stumble", "chip": Color("1d3c8c")},
}

class Biz:
	var card := -1
	var name := ""
	var sector := ""
	var cap := ""
	var rules: Array = []
	var value := 0.0
	var cell := -1
	var flash := 0.0
	var last_delta := 0.0
	var has_last := false

class Die:
	var face := 1
	var colors: Array[int] = []
	var shown_face := 1
	var pos := Vector2.ZERO
	var home := Vector2.ZERO
	var start := Vector2.ZERO
	var target: Biz
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
	var color := Color.WHITE
	var size := T_XL

class UiButton:
	var rect: Rect2
	var cb: Callable

var c_board := Color("f6f0e4")
var c_board_dark := Color("e9dfcb")
var c_board_line := Color("d8c9ac")
var c_board_ink := Color("8a7c66")
var c_board_text := Color("2a2633")
var c_well := Color("1d4f6e")
var c_stock := Color("fffdf9")
var c_ivory := Color("fffdf7")
var c_ink := Color("24202d")
var c_muted := Color("857b8a")
var c_shadow := Color("4a3420")
var c_up := Color("1f9d55")
var c_up_light := Color("5fd08f")
var c_up_soft := Color("dff3e6")
var c_down := Color("e2453a")
var c_down_light := Color("ff8a78")
var c_down_soft := Color("fce3df")
var c_green := c_up
var c_red := c_down
var c_blue := Color("2f6fe0")
var c_gold := Color("f4b23e")
var c_gold_dark := Color("b9791a")
var c_down_chip := Color("d8473b")
var c_violet := Color("7c4fd8")
var c_violet_dark := Color("4d2fa0")
var c_violet_light := Color("b49cff")
var tile_colors: Array[Color] = [Color("e2453a"), Color("f07f22"), Color("f4b23e"), Color("1f9d55"), Color("2f6fe0"), Color("7c4fd8")]

var phase := Phase.BUILD
var turn := 1
var cash := 0.0
var board: Array = []
var cell_rules: Array = []
var offer: Array[Biz] = []
var deck: Array[int] = []
var dice: Array[Die] = []
var die_colors: Array = []
var drag_die: Die
var buying: Biz
var trouble := {}
var results := {}
var won := false
var lost := false
var peak_worth := 0.0
var bankruptcies := 0
var floaters: Array[FloatText] = []

var buttons: Array[UiButton] = []
var ui_live := true
var tips_live := true
var hover_tip := ""
var mouse := Vector2.ZERO
var view_size := Vector2.ZERO
var ui_size := Vector2(2560, 1440)
var window_size := Vector2.ZERO
var screen_rect := Rect2()
var ui_scale := 1.0
var clock := 0.0
var cur_offset := Vector2.ZERO
var cur_scale := 1.0
var r_track := Rect2()
var r_offer := Rect2()
var r_trouble := Rect2()
var r_stats := Rect2()
var r_board := Rect2()
var r_tray := Rect2()
var r_log := Rect2()
var log_rows: Array = []

var font: Font
var font_bold: Font
var font_heavy: Font
var style := StyleBoxFlat.new()

var tone_buy: AudioStreamWAV
var tone_sell: AudioStreamWAV
var tone_bell: AudioStreamWAV
var tone_learn: AudioStreamWAV
var tone_paper: AudioStreamWAV
var tone_rattle: AudioStreamWAV
var tone_clack: AudioStreamWAV
var tone_power: AudioStreamWAV
var players: Array[AudioStreamPlayer] = []
var player_idx := 0

const DIE_SIZE := 96.0
const MINI_DIE := 46.0
const CARD_W := 240.0
const CARD_H := 280.0
const CARD_GAP := 16.0
const CELL_GAP := 24.0
const RULE_H := 34.0

const T_XS := 12
const T_SM := 16
const T_MD := 20
const T_LG := 26
const T_XL := 38
const T_HERO := 56

const SP := 8.0
const MARGIN := SP * 5
const GAP := SP * 3
const PAD := SP * 3
const ZONE_HEAD := SP * 7.5
const TRACK_W := 150.0
const LABEL_W := 104.0
const LABEL_H := 30.0
const HEAD_H := 52.0

func _ready() -> void:
	randomize()
	_load_fonts()
	_build_audio()
	_recompute_layout()
	get_viewport().size_changed.connect(_recompute_layout)
	_new_run()

func _recompute_layout() -> void:
	window_size = get_viewport_rect().size
	view_size = ui_size
	ui_scale = minf(window_size.x / ui_size.x, window_size.y / ui_size.y)
	screen_rect = Rect2((window_size - ui_size * ui_scale) * 0.5, ui_size * ui_scale)
	var top := SP * 3
	var bottom := ui_size.y - SP * 3
	r_track = Rect2(MARGIN, top, TRACK_W, bottom - top)
	var x0 := r_track.end.x + GAP
	var right := ui_size.x - MARGIN
	var row_h := ZONE_HEAD + CARD_H + PAD
	var bw := LABEL_W + PAD * 2 + COLS * CARD_W + (COLS - 1) * CELL_GAP
	r_offer = Rect2(x0, top, PAD * 2 + offer_size * CARD_W + (offer_size - 1) * CARD_GAP, row_h)
	r_trouble = Rect2(r_offer.end.x + GAP, top, x0 + bw - r_offer.end.x - GAP, row_h)
	r_board = Rect2(x0, r_offer.end.y + GAP, bw, bottom - r_offer.end.y - GAP)
	var rx := r_board.end.x + GAP
	r_stats = Rect2(rx, top, right - rx, row_h)
	r_tray = Rect2(rx, r_board.position.y, right - rx, 430.0)
	r_log = Rect2(rx, r_tray.end.y + GAP, right - rx, bottom - r_tray.end.y - GAP)

func _make_biz(i: int) -> Biz:
	var c: Dictionary = PortfolioCards.CARDS[i]
	var b := Biz.new()
	b.card = i
	b.name = c["name"]
	b.sector = c["sector"]
	b.cap = c["cap"]
	b.rules = c["rules"]
	b.value = float(cap_values.get(b.cap, 10.0))
	return b

func _draw_offer() -> void:
	for b in offer:
		if b.card >= 0 and not deck.has(b.card):
			deck.insert(randi_range(0, deck.size()), b.card)
	offer.clear()
	for i in offer_size:
		if deck.is_empty():
			break
		offer.append(_make_biz(deck.pop_front()))

func _owned() -> Array[Biz]:
	var out: Array[Biz] = []
	for b in board:
		if b != null:
			out.append(b)
	return out

func _net_worth() -> float:
	var total := cash
	for b in _owned():
		total += b.value
	return total

func _margin_for(t: int) -> float:
	return roundf(margin_base * pow(margin_growth, t - 1))

func _sector_color_index(sec: String) -> int:
	return int(sector_defs[sec]["color"])

func _sector_color(sec: String) -> Color:
	return tile_colors[_sector_color_index(sec)]

func _cell_allows(cell: int, b: Biz) -> bool:
	var rule: Dictionary = cell_rules[cell]
	match rule.get("kind", ""):
		"sector":
			return b.sector == rule["value"]
		"cap":
			return b.cap == rule["value"]
	return true

func _cell_label(cell: int) -> String:
	var rule: Dictionary = cell_rules[cell]
	match rule.get("kind", ""):
		"sector":
			return "%s only" % rule["value"]
		"cap":
			return "%s only" % cap_defs[rule["value"]]["label"]
	return ""

func _can_buy(b: Biz) -> bool:
	if phase != Phase.BUILD or not offer.has(b) or b.value > cash + 0.0001:
		return false
	for i in CELLS:
		if board[i] == null and _cell_allows(i, b):
			return true
	return false

func _start_buy(b: Biz) -> void:
	if not _can_buy(b):
		return
	buying = b
	_play(tone_power, 1.4, -12.0)

func _place_buy(cell: int) -> void:
	if buying == null or board[cell] != null or not _cell_allows(cell, buying):
		return
	cash = maxf(0.0, cash - buying.value)
	buying.cell = cell
	buying.flash = 1.0
	board[cell] = buying
	offer.erase(buying)
	buying = null
	_play(tone_buy, randf_range(0.97, 1.05), -8.0)

func _sell(b: Biz) -> void:
	if phase != Phase.BUILD or b.cell < 0:
		return
	cash += b.value
	board[b.cell] = null
	b.cell = -1
	deck.insert(randi_range(0, deck.size()), b.card)
	_play(tone_sell, randf_range(0.97, 1.05), -8.0)

func _new_run() -> void:
	turn = 1
	cash = starting_cash
	board.clear()
	board.resize(CELLS)
	cell_rules.clear()
	for i in CELLS:
		cell_rules.append({})
	var spots: Array = range(CELLS)
	spots.shuffle()
	for k in mini(restricted_cells, CELLS):
		if randf() < 0.5:
			cell_rules[spots[k]] = {"kind": "sector", "value": PortfolioCards.SECTORS[randi() % PortfolioCards.SECTORS.size()]}
		else:
			cell_rules[spots[k]] = {"kind": "cap", "value": PortfolioCards.CAPS[randi() % PortfolioCards.CAPS.size()]}
	deck.clear()
	for i in PortfolioCards.CARDS.size():
		deck.append(i)
	deck.shuffle()
	offer.clear()
	die_colors.clear()
	dice.clear()
	floaters.clear()
	won = false
	lost = false
	log_rows = []
	peak_worth = starting_cash
	bankruptcies = 0
	_start_turn()

func _start_turn() -> void:
	dice.clear()
	drag_die = null
	buying = null
	trouble = {}
	results = {}
	for b in _owned():
		b.has_last = false
	_draw_offer()
	phase = Phase.BUILD

func _group_members(kind: String, value) -> Array[Biz]:
	var out: Array[Biz] = []
	for i in CELLS:
		var b: Biz = board[i]
		if b == null:
			continue
		match kind:
			"sector":
				if b.sector == value:
					out.append(b)
			"cap":
				if b.cap == value:
					out.append(b)
			"row":
				if floori(float(i) / COLS) == int(value):
					out.append(b)
			"col":
				if i % COLS == int(value):
					out.append(b)
	return out

func _all_groups() -> Array:
	var out: Array = []
	for sec in PortfolioCards.SECTORS:
		out.append({"kind": "sector", "value": sec})
	for cap in PortfolioCards.CAPS:
		out.append({"kind": "cap", "value": cap})
	for r in ROWS:
		out.append({"kind": "row", "value": r})
	for c in COLS:
		out.append({"kind": "col", "value": c})
	return out

func _draw_trouble() -> void:
	if phase != Phase.BUILD:
		return
	buying = null
	var groups := _all_groups()
	var hitting: Array = groups.filter(func(g): return not _group_members(g["kind"], g["value"]).is_empty())
	var pool: Array = hitting if not hitting.is_empty() and randf() < 0.9 else groups
	var g: Dictionary = pool[randi() % pool.size()]
	var pct := trouble_base + trouble_per_turn * (turn - 1) + randf_range(-trouble_spread, trouble_spread)
	pct = snappedf(clampf(pct, 0.05, 0.5), 0.05)
	trouble = {"kind": g["kind"], "value": g["value"], "pct": pct, "title": _trouble_title(g), "group": _group_name(g)}
	_play(tone_paper, randf_range(0.95, 1.05), -6.0)
	phase = Phase.TROUBLE
	if _owned().is_empty():
		_resolve()

func _trouble_title(g: Dictionary) -> String:
	match g["kind"]:
		"sector":
			return sector_defs[g["value"]]["trouble"]
		"cap":
			return cap_defs[g["value"]]["trouble"]
		"row":
			return "Blackout on %s" % ROW_NAMES[int(g["value"])]
		"col":
			return "Flooding on %s" % COL_NAMES[int(g["value"])]
	return "Trouble"

func _group_name(g: Dictionary) -> String:
	match g["kind"]:
		"sector":
			return "%s businesses" % g["value"]
		"cap":
			return cap_defs[g["value"]]["plural"]
		"row":
			return "Businesses on %s" % ROW_NAMES[int(g["value"])]
		"col":
			return "Businesses on %s" % COL_NAMES[int(g["value"])]
	return ""

func _in_trouble(b: Biz) -> bool:
	if trouble.is_empty() or b == null:
		return false
	return _group_members(trouble["kind"], trouble["value"]).has(b)

func _in_trouble_cell(cell: int) -> bool:
	if trouble.is_empty():
		return false
	match trouble["kind"]:
		"row":
			return floori(float(cell) / COLS) == int(trouble["value"])
		"col":
			return cell % COLS == int(trouble["value"])
	return _in_trouble(board[cell])

func _throw_face() -> int:
	return randi_range(1, 6)

func _die_color(d: Die, face: int) -> int:
	return d.colors[clampi(face, 1, 6) - 1] if d.colors.size() == 6 else 0

func _die_palette(i: int) -> Array[int]:
	while die_colors.size() <= i:
		var order: Array[int] = [0, 1, 2, 3, 4, 5]
		for tries in 20:
			order.shuffle()
			if not die_colors.has(order):
				break
		die_colors.append(order.duplicate())
	var out: Array[int] = []
	out.assign(die_colors[i])
	return out

func _tray_home(i: int, n: int) -> Vector2:
	var cx := r_tray.position.x + (r_tray.size.x - 260.0) * 0.5 + (i - (n - 1) * 0.5) * 132.0
	return Vector2(cx, r_tray.position.y + ZONE_HEAD + 110.0)

func _roll() -> void:
	if phase != Phase.TROUBLE:
		return
	dice.clear()
	for i in dice_count:
		var d := Die.new()
		d.face = _throw_face()
		d.colors = _die_palette(i)
		d.shown_face = randi_range(1, 6)
		d.home = _tray_home(i, dice_count)
		d.start = Vector2(r_tray.end.x + 80.0, d.home.y + randf_range(-40.0, 40.0))
		d.pos = d.start
		d.roll_dur = roll_seconds + i * 0.08 + randf_range(0.0, 0.15)
		d.roll_t = d.roll_dur
		d.spin = randf_range(9.0, 15.0) * (1.0 if randf() < 0.5 else -1.0)
		d.rest_ang = randf_range(-0.18, 0.18)
		dice.append(d)
	phase = Phase.ROLL
	_play(tone_rattle, 1.0, -3.0)

func _dice_on(b: Biz) -> Array[Die]:
	var out: Array[Die] = []
	for d in dice:
		if d.target == b:
			out.append(d)
	return out

func _all_placed() -> bool:
	for d in dice:
		if d.target == null:
			return false
	return true

func _die_at(p: Vector2) -> Die:
	for i in range(dice.size() - 1, -1, -1):
		var d := dice[i]
		var size := DIE_SIZE if d.target == null or d == drag_die else MINI_DIE
		if d.roll_t <= 0.0 and absf(p.x - d.pos.x) < size * 0.55 and absf(p.y - d.pos.y) < size * 0.55:
			return d
	return null

func _cell_rect(i: int) -> Rect2:
	var col := i % COLS
	var row := floori(float(i) / COLS)
	var x0 := r_board.position.x + LABEL_W + PAD
	var y0 := r_board.position.y + ZONE_HEAD + LABEL_H
	var gap_y := (r_board.size.y - ZONE_HEAD - LABEL_H - PAD - ROWS * CARD_H) / (ROWS - 1)
	return Rect2(x0 + col * (CARD_W + CELL_GAP), y0 + row * (CARD_H + gap_y), CARD_W, CARD_H)

func _cell_at(p: Vector2) -> int:
	for i in CELLS:
		if _cell_rect(i).has_point(p):
			return i
	return -1

func _mini_slot(b: Biz, k: int) -> Vector2:
	var r := _cell_rect(b.cell)
	return Vector2(r.end.x - 30.0 - k * (MINI_DIE + 6.0), r.position.y + 72.0)

func _rule_matches(rule: Dictionary, d: Die) -> bool:
	if rule.has("nums") and not (rule["nums"] as Array).has(d.face):
		return false
	if rule.has("color") and COLOR_NAMES.find(rule["color"]) != _die_color(d, d.face):
		return false
	return rule.has("nums") or rule.has("color")

func _rule_is_bad(rule: Dictionary) -> bool:
	var fx: Dictionary = rule["fx"]
	return fx.has("bankrupt") or float(fx.get("value", 0.0)) < 0.0 or float(fx.get("cash", 0.0)) < 0.0

func _preview(b: Biz) -> Dictionary:
	var out := {"value": b.value, "cash": 0.0, "bankrupt": false, "fired": [], "protected": false, "hit": false}
	var ds := _dice_on(b)
	var v := b.value
	for d in ds:
		for k in b.rules.size():
			var rule: Dictionary = b.rules[k]
			if not _rule_matches(rule, d):
				continue
			(out["fired"] as Array).append(k)
			var fx: Dictionary = rule["fx"]
			if fx.has("bankrupt"):
				out["bankrupt"] = true
			v *= 1.0 + float(fx.get("value", 0.0))
			out["cash"] += float(fx.get("cash", 0.0))
	if _in_trouble(b):
		if ds.is_empty():
			v *= 1.0 - float(trouble["pct"])
			out["hit"] = true
		else:
			out["protected"] = true
	out["value"] = 0.0 if out["bankrupt"] else v
	return out

func _resolve() -> void:
	if phase == Phase.PLACE and not _all_placed():
		return
	if phase != Phase.PLACE and phase != Phase.TROUBLE:
		return
	drag_die = null
	_play(tone_bell, 1.0, -4.0)
	results = {}
	log_rows = []
	for b in _owned():
		var p := _preview(b)
		var names: Array[String] = []
		for k in p["fired"]:
			names.append(b.rules[int(k)]["name"])
		if bool(p["hit"]):
			names.append("%s -%d%%" % [trouble["title"], int(round(float(trouble["pct"]) * 100.0))])
		elif bool(p["protected"]):
			names.append("protected")
		results[b] = p
		var before := b.value
		cash += float(p["cash"])
		b.value = float(p["value"])
		b.last_delta = b.value - before + float(p["cash"])
		b.has_last = true
		b.flash = 1.0
		log_rows.append({"name": b.name, "note": ", ".join(names), "delta": b.last_delta, "bankrupt": bool(p["bankrupt"]), "color": _sector_color(b.sector)})
		var r := _cell_rect(b.cell)
		if p["bankrupt"]:
			_spawn_floater(r.get_center(), "Bankrupt", c_red, 34)
		elif absf(b.last_delta) > 0.004:
			_spawn_floater(r.get_center(), _signed_money(b.last_delta), c_green if b.last_delta >= 0.0 else c_red, 34)
	for b in _owned():
		if bool(results[b]["bankrupt"]):
			board[b.cell] = null
			b.cell = -1
			bankruptcies += 1
	for d in dice:
		if d.target != null and d.target.cell < 0:
			d.target = null
	peak_worth = maxf(peak_worth, _net_worth())
	if _net_worth() < _margin_for(turn):
		lost = true
	elif turn >= total_turns:
		won = true
	phase = Phase.RESULT

func _next_turn() -> void:
	if phase != Phase.RESULT:
		return
	if lost or won:
		phase = Phase.GAMEOVER
		return
	turn += 1
	_start_turn()

func _primary_action() -> void:
	match phase:
		Phase.BUILD:
			_draw_trouble()
		Phase.TROUBLE:
			_roll()
		Phase.PLACE:
			_resolve()
		Phase.RESULT:
			_next_turn()
		Phase.GAMEOVER:
			_new_run()

func _build_audio() -> void:
	tone_buy = _make_tone(PackedFloat32Array([660.0, 990.0]), 0.16, 0.05)
	tone_sell = _make_tone(PackedFloat32Array([523.0, 784.0]), 0.18, 0.06)
	tone_bell = _make_tone(PackedFloat32Array([784.0, 1176.0, 1568.0, 392.0]), 1.4, 0.35)
	tone_learn = _make_tone(PackedFloat32Array([880.0, 1320.0, 1760.0]), 0.5, 0.14)
	tone_power = _make_tone(PackedFloat32Array([523.0, 659.0, 784.0, 1046.0]), 0.7, 0.25)
	tone_paper = _make_rustle(0.55)
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
		var slap := exp(-maxf(0.0, t - 0.82) * 60.0) * (1.0 if t > 0.82 else 0.0) * 1.3
		var crackle := (raw - lp) * 0.25 * swell
		var v := int(clampf(lp * (swell + slap) + crackle, -1.0, 1.0) * 26000.0)
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
	if players.is_empty():
		return
	var p := players[player_idx]
	player_idx = (player_idx + 1) % players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()

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
	for b in _owned():
		b.flash = maxf(0.0, b.flash - delta * 0.6)
	for i in range(floaters.size() - 1, -1, -1):
		var f := floaters[i]
		f.life -= delta
		f.pos += f.vel * delta
		f.vel.y += 120.0 * delta
		if f.life <= 0.0:
			floaters.remove_at(i)
	queue_redraw()

func _update_dice(delta: float) -> void:
	var um := _ui_mouse()
	var slots := {}
	for d in dice:
		var goal := d.home
		if d == drag_die:
			goal = um
		elif d.target != null and d.target.cell >= 0:
			var k: int = slots.get(d.target, 0)
			slots[d.target] = k + 1
			goal = _mini_slot(d.target, k)
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
		var kk := 1.0 if d == drag_die else 1.0 - exp(-delta * 16.0)
		d.pos = d.pos.lerp(goal, kk)
		d.ang = lerpf(d.ang, 0.0 if d.target != null or d == drag_die else d.rest_ang, 1.0 - exp(-delta * 10.0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
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
					queue_redraw()
					return
			if buying != null:
				var cell := _cell_at(ui_p)
				if cell >= 0:
					_place_buy(cell)
				else:
					buying = null
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and drag_die != null:
			var cell := _cell_at(ui_p)
			if cell >= 0 and board[cell] != null:
				drag_die.target = board[cell]
				_play(tone_clack, randf_range(0.9, 1.1), -6.0)
			elif r_tray.has_point(ui_p):
				drag_die.target = null
			drag_die = null
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if buying != null:
				buying = null
			elif phase == Phase.PLACE:
				var d := _die_at(ui_p)
				if d != null:
					d.target = null
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE:
			buying = null
		elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE:
			if phase != Phase.PLACE or _all_placed():
				_primary_action()

func _spawn_floater(pos: Vector2, t: String, col: Color, size: int) -> void:
	var f := FloatText.new()
	f.pos = pos
	f.vel = Vector2(randf_range(-12.0, 12.0), -70.0)
	f.max_life = 1.4
	f.life = f.max_life
	f.text = t
	f.color = col
	f.size = size
	floaters.append(f)

func _money(v: float) -> String:
	var neg := v < -0.004
	v = absf(v)
	var whole := int(floor(v))
	var cents := int(round((v - whole) * 100.0))
	if cents >= 100:
		whole += 1
		cents = 0
	var digits := str(whole)
	var out := ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	out = digits + out
	var sign_s := "-" if neg else ""
	if whole >= 10000:
		return "%s$%s" % [sign_s, out]
	return "%s$%s.%02d" % [sign_s, out, cents]

func _signed_money(v: float) -> String:
	return ("+" if v >= 0.0 else "") + _money(v)

func _whole_money(v: float) -> String:
	var t := _money(roundf(v))
	return t.trim_suffix(".00")

func _row_x(area: Rect2, n: int, w: float, gap: float) -> float:
	return area.get_center().x - (n * w + (n - 1) * gap) * 0.5

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
	_panel(Rect2(r.position + Vector2(0.0, depth), r.size), Color(c_shadow, 0.5 * (alpha)), radius)
	_panel(Rect2(r.position + Vector2(-2.0, depth * 0.5), r.size + Vector2(4.0, 2.0)), Color(c_shadow, 0.5 * (alpha * 0.35)), radius + 2)

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
	b.rect = Rect2(cur_offset + r.position * cur_scale, r.size * cur_scale)
	b.cb = cb
	buttons.append(b)

func _tip(r: Rect2, text: String) -> void:
	if tips_live and r.has_point(mouse):
		hover_tip = text

func _screen_xform() -> Transform2D:
	return Transform2D(0.0, Vector2(cur_scale, cur_scale), 0.0, cur_offset)

func _dashed_rect(r: Rect2, col: Color, width: float = 2.0, dash: float = 14.0, gap: float = 10.0) -> void:
	var inset := 10.0
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
		draw_arc(c[0], inset, c[1], c[2], 6, col, width, true)

func _pill(r: Rect2, label: String, cb: Callable, enabled: bool = true, kind: String = "gold", size: int = 24) -> void:
	var live := enabled and ui_live
	var hovered := live and r.has_point(mouse)
	var face := c_gold
	var edge := c_gold_dark
	var ink := c_ink
	match kind:
		"light":
			face = c_stock
			edge = Color("b9c0cf")
		"violet":
			face = c_violet
			edge = c_violet_dark
			ink = Color.WHITE
	if not enabled:
		face = c_board_line
		edge = c_board_dark
		ink = c_board_ink
	var press := 2.0 if hovered else 0.0
	var radius := int(r.size.y * 0.5)
	_panel(Rect2(r.position + Vector2(0, 6), r.size), Color(c_shadow, 0.5 * (0.35)), radius)
	_panel(Rect2(r.position + Vector2(0, 5), r.size), edge, radius)
	var top := Rect2(r.position + Vector2(0, press), r.size)
	_panel(top, face.lightened(0.06) if hovered else face, radius)
	_heavy_center(top, label, size, ink)
	if live:
		_register(r, cb)

func _coin(c: Vector2, rad: float, label: String, cb: Callable, enabled: bool) -> void:
	var live := enabled and ui_live
	var box := Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0)
	var hovered := live and box.has_point(mouse)
	var face := c_gold if enabled else c_board_line
	var pulse := 0.0
	if enabled:
		pulse = 0.5 + 0.5 * sin(clock * 3.0)
		draw_circle(c, rad + 10.0 + pulse * 6.0, Color(c_gold, 0.10))
	draw_circle(c + Vector2(0, 9), rad, Color(c_shadow, 0.5 * (0.45)))
	draw_circle(c + Vector2(0, 6), rad, face.darkened(0.35))
	var cc := c + Vector2(0, 2.0 if hovered else 0.0)
	draw_circle(cc, rad, face)
	draw_arc(cc, rad - 12.0, 0.0, TAU, 48, face.darkened(0.18), 3.0, true)
	draw_arc(cc, rad - 3.0, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.35), 4.0, true)
	var lines := label.split("\n")
	var size := T_XL if lines.size() == 1 else T_LG
	var ink := c_ink if enabled else c_board_ink
	var total_h := lines.size() * size * 1.05
	for i in lines.size():
		var y := cc.y - total_h * 0.5 + (i + 0.82) * size * 1.05
		_heavy(Vector2(cc.x - _heavy_w(lines[i], size) * 0.5, y), lines[i], size, ink)
	if live:
		_register(box, cb)

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
	_panel(Rect2(r.position + Vector2(0, size * 0.07), r.size), Color(body.darkened(0.3), body.a), radius)
	_panel(r, body, radius, outline, 3 if outline.a > 0.0 else 0)
	var spread := size * 0.26
	var pip_r := size * 0.085
	for o in _pip_offsets(face):
		draw_circle(center + o * spread, pip_r, pip)

func _draw_floaters() -> void:
	for f in floaters:
		var a := clampf(f.life / f.max_life * 1.6, 0.0, 1.0)
		var c := f.color
		c.a = a
		var tw := _heavy_w(f.text, f.size)
		var pill := Rect2(f.pos.x - tw * 0.5 - 18.0, f.pos.y - f.size * 0.9, tw + 36.0, f.size * 1.2)
		_panel(pill, Color(c_stock, 0.95 * a), int(pill.size.y * 0.5), Color(f.color, 0.5 * a), 3)
		_heavy(Vector2(f.pos.x - tw * 0.5, f.pos.y), f.text, f.size, c)

func _draw_tooltip(text: String, bounds: Vector2) -> void:
	var w := 480.0
	var size := T_MD
	var ts := font_bold.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, size)
	var box := Rect2(mouse + Vector2(24.0, 24.0), Vector2(ts.x + 36.0, ts.y + 26.0))
	if box.end.x > bounds.x - 12.0:
		box.position.x = mouse.x - box.size.x - 16.0
	if box.end.y > bounds.y - 12.0:
		box.position.y = mouse.y - box.size.y - 16.0
	_panel(Rect2(box.position + Vector2(0, 6), box.size), Color(0, 0, 0, 0.3), 14)
	_panel(box, c_ink, 14)
	_wrap(box.position + Vector2(18.0, 13.0 + font_bold.get_ascent(size)), text, w, size, c_stock, true)

func _dim(amount: float = 1.0) -> void:
	draw_rect(Rect2(Vector2(-400, -400), view_size + Vector2(800, 800)), Color(0.13, 0.10, 0.08, minf(0.9, 0.72 * amount)))

func _draw() -> void:
	buttons.clear()
	hover_tip = ""
	draw_rect(Rect2(Vector2.ZERO, window_size), c_board)
	cur_offset = screen_rect.position
	cur_scale = ui_scale
	mouse = _ui_mouse()
	draw_set_transform_matrix(_screen_xform())
	var modal := phase == Phase.GAMEOVER
	ui_live = not modal
	tips_live = not modal and drag_die == null
	_draw_board()
	_draw_track()
	_draw_offer_zone()
	_draw_trouble_zone()
	_draw_stats()
	_draw_portfolio()
	_draw_tray()
	_draw_log()
	for d in dice:
		if d != drag_die:
			_draw_die(d)
	if drag_die != null:
		_draw_die(drag_die)
	_draw_floaters()
	if buying != null:
		var hint := "Place %s: click a glowing lot" % buying.name
		var hw := _heavy_w(hint, T_MD) + 40.0
		var hr := Rect2(mouse + Vector2(26.0, 18.0), Vector2(hw, 46.0))
		_panel(hr, c_violet, 23)
		_heavy_center(hr, hint, T_MD, Color.WHITE)
	ui_live = true
	tips_live = true
	if phase == Phase.GAMEOVER:
		_draw_gameover()
	if hover_tip != "":
		_draw_tooltip(hover_tip, view_size)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_board() -> void:
	var b := Rect2(Vector2(-400, -400), view_size + Vector2(800, 800))
	draw_rect(b, c_board)
	var step := 72.0
	var row := 0
	var y := -step
	while y < view_size.y + step:
		var x := -step + (step * 0.5 if row % 2 == 1 else 0.0)
		while x < view_size.x + step:
			_diamond(Vector2(x, y), 5.0, Color(c_board_line, 0.45))
			x += step
		y += step
		row += 1
	var frame := Rect2(Vector2(10.0, 10.0), view_size - Vector2(20.0, 20.0))
	_panel(frame, Color(0, 0, 0, 0), 30, Color(c_board_line, 0.9), 2)
	var corners := [frame.position, Vector2(frame.end.x, frame.position.y), frame.end, Vector2(frame.position.x, frame.end.y)]
	for k in corners.size():
		_diamond(corners[k], 9.0, tile_colors[(k * 2) % tile_colors.size()])

func _zone(r: Rect2, title: String, note: String, accent: Color = c_gold) -> void:
	_shadow(r, 26, 4.0, 0.12)
	_panel(r, c_stock, 26, Color(c_board_line, 0.9), 2)
	_panel_corners(Rect2(r.position + Vector2(2.0, 2.0), Vector2(r.size.x - 4.0, HEAD_H - 2.0)), accent.lerp(c_stock, 0.84), 24, 24, 0, 0)
	draw_line(Vector2(r.position.x + 2.0, r.position.y + HEAD_H), Vector2(r.end.x - 2.0, r.position.y + HEAD_H), Color(accent, 0.35), 2.0)
	_diamond(r.position + Vector2(PAD + 9.0, HEAD_H * 0.5 + 1.0), 9.0, accent)
	_heavy(Vector2(r.position.x + PAD + 28.0, r.position.y + 36.0), title, T_LG, c_board_text)
	if note != "":
		var room := r.size.x - PAD * 2.0 - 40.0 - _heavy_w(title, T_LG)
		var ns := T_SM
		while ns > 12 and _text_w(note, ns, true) > room:
			ns -= 1
		_text(Vector2(r.end.x - PAD - _text_w(note, ns, true), r.position.y + 34.0), note, ns, c_board_ink, true)

func _diamond(c: Vector2, rad: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad), c + Vector2(rad, 0), c + Vector2(0, rad), c + Vector2(-rad, 0)]), col)

func _draw_pawn(c: Vector2) -> void:
	var col := c_violet
	draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 18), c + Vector2(11, 18), c + Vector2(5, 2), c + Vector2(-5, 2)]), col.darkened(0.1))
	draw_circle(c + Vector2(0, -4), 9.0, col)
	draw_circle(c + Vector2(-3, -7), 3.0, Color(1, 1, 1, 0.35))

func _draw_track() -> void:
	var r := r_track
	_heavy_center(Rect2(r.position.x, r.position.y, r.size.x, 36.0), "Port", T_LG, c_board_text)
	_heavy_center(Rect2(r.position.x, r.position.y + 30.0, r.size.x, 36.0), "folio", T_LG, c_board_text)
	var tw := (r.size.x - 40.0) / tile_colors.size()
	for k in tile_colors.size():
		_panel(Rect2(r.position.x + 20.0 + k * tw + 2.0, r.position.y + 70.0, tw - 4.0, 8.0), tile_colors[k], 3)
	var y0 := r.position.y + 92.0
	var gap := 6.0
	var sh := (r.end.y - y0 - gap * (total_turns - 1)) / total_turns
	for t in total_turns:
		var tn := t + 1
		var sr := Rect2(r.position.x, y0 + t * (sh + gap), r.size.x, sh)
		var past := tn < turn or (tn == turn and phase == Phase.RESULT)
		var now := tn == turn
		_panel(sr, Color(c_board_dark, 0.8) if past else Color(c_stock, 0.85), 12, c_gold if now else Color(c_board_line, 0.9), 3 if now else 2)
		var cy := sr.get_center().y
		_text(Vector2(sr.position.x + 12.0, cy + 6.0), str(tn), T_SM, c_board_ink, true)
		var m := "$%d" % int(_margin_for(tn))
		_heavy_right(sr.end.x - 12.0, cy + 8.0, m, T_MD, c_down if now else (Color(c_board_ink, 0.6) if past else c_board_text))
		if now:
			_draw_pawn(Vector2(sr.position.x + 50.0, cy - 4.0))
		_tip(sr, "Turn %d. Margin call: your net worth must be at least %s when the turn ends." % [tn, _money(_margin_for(tn))])

func _draw_offer_zone() -> void:
	_zone(r_offer, "For sale", "Buy a business, then place it on a lot" if phase == Phase.BUILD else "Back next turn", c_blue)
	var x0 := _row_x(r_offer, offer_size, CARD_W, CARD_GAP)
	for i in offer_size:
		var r := Rect2(x0 + i * (CARD_W + CARD_GAP), r_offer.position.y + ZONE_HEAD, CARD_W, CARD_H)
		if i >= offer.size():
			_dashed_rect(r, Color(c_board_line, 0.9))
			_text_center(r, "Sold", T_MD, c_board_ink, true)
			continue
		var b := offer[i]
		var hovered := r.has_point(mouse) and phase == Phase.BUILD and buying == null
		var cr := Rect2(r.position + Vector2(0, -8.0 if hovered or buying == b else 0.0), r.size)
		_draw_biz(cr, b, false)
		if buying == b:
			_panel(cr.grow(6.0), Color(0, 0, 0, 0), 26, c_violet, 5)
		if phase == Phase.BUILD:
			var can := _can_buy(b)
			if hovered:
				var hint := "Buy %s" % _whole_money(b.value)
				if not can:
					hint = "Too pricey" if b.value > cash else "No legal lot"
				var hw := maxf(_heavy_w(hint, T_MD) + 40.0, 110.0)
				var hr := Rect2(Vector2(cr.end.x - 14.0 - hw, cr.end.y - 50.0), Vector2(hw, 42.0))
				_panel(hr, c_gold if can else c_board_line, 21)
				_heavy_center(hr, hint, T_MD, c_ink if can else c_board_text)
			if can:
				_register(r, _start_buy.bind(b))
	if phase != Phase.BUILD:
		_panel(r_offer, Color(c_board, 0.5), 26)

func _draw_trouble_zone() -> void:
	_zone(r_trouble, "Trouble", "", c_down)
	var r := Rect2(r_trouble.position.x + PAD, r_trouble.position.y + ZONE_HEAD, r_trouble.size.x - PAD * 2.0, CARD_H)
	_shadow(r, 20, 8.0)
	if trouble.is_empty():
		_panel(r, Color("3a2230"), 20, c_down, 4)
		_panel(r.grow(-12.0), Color(0, 0, 0, 0), 14, Color(c_down_light, 0.4), 2)
		_heavy_center(Rect2(r.position.x, r.position.y + 70.0, r.size.x, 60.0), "Trouble deck", T_XL, Color(1, 1, 1, 0.9))
		_wrap(Vector2(r.position.x + 30.0, r.position.y + 170.0), "Draw a card when you've finished buying. It hits a group of your businesses.", r.size.x - 60.0, T_MD, Color(1, 1, 1, 0.7), true, 3, HORIZONTAL_ALIGNMENT_CENTER)
		return
	_panel(r, c_stock, 20, c_down, 5)
	_panel_corners(Rect2(r.position, Vector2(r.size.x, 48.0)), c_down, 20, 20, 0, 0)
	_heavy_center(Rect2(r.position.x, r.position.y, r.size.x, 48.0), trouble["title"], T_LG, Color.WHITE)
	_heavy_center(Rect2(r.position.x, r.position.y + 70.0, r.size.x, 80.0), "-%d%%" % int(round(float(trouble["pct"]) * 100.0)), T_HERO + 16, c_down)
	_text_center(Rect2(r.position.x, r.position.y + 150.0, r.size.x, 36.0), trouble["group"], T_MD, c_ink, true)
	var n := _group_members(trouble["kind"], trouble["value"]).size()
	var line := "No businesses hit" if n == 0 else "%d of your businesses hit" % n
	_text_center(Rect2(r.position.x, r.position.y + 190.0, r.size.x, 30.0), line, T_MD, c_muted, true)
	_wrap(Vector2(r.position.x + 24.0, r.position.y + 236.0), "A die on a business protects it.", r.size.x - 48.0, T_SM, c_muted, true, 2, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_stats() -> void:
	_zone(r_stats, "Ledger", "Turn %d of %d" % [turn, total_turns], c_gold)
	var r := Rect2(r_stats.position.x + PAD, r_stats.position.y + ZONE_HEAD + SP, r_stats.size.x - PAD * 2.0, r_stats.size.y - ZONE_HEAD - PAD - SP)
	var worth := _net_worth()
	var margin := _margin_for(turn)
	var cells := [
		["Cash", _money(cash), c_board_text, "Spend it on businesses. Some dice rules pay cash."],
		["Net worth", _money(worth), c_up if worth >= margin else c_down, "Cash plus the value of every business you own."],
		["Margin call", _money(margin), c_down, "If your net worth is below this when the turn ends, the run is over."],
		["Cushion", _signed_money(worth - margin), c_up if worth >= margin else c_down, "How far your net worth is above the margin call."],
	]
	var cw := (r.size.x - GAP) / 2.0
	var ch := (r.size.y - GAP) / 2.0
	for i in cells.size():
		var cell: Array = cells[i]
		var cr := Rect2(r.position.x + (i % 2) * (cw + GAP), r.position.y + floori(i / 2.0) * (ch + GAP), cw, ch)
		_panel(cr, c_board, 16, Color(c_board_line, 0.7), 1)
		_text(cr.position + Vector2(PAD, 32.0), cell[0].to_upper(), T_XS + 1, c_board_ink, true)
		var size := T_XL
		while size > T_MD and _heavy_w(cell[1], size) > cw - PAD * 2.0:
			size -= 1
		_heavy(Vector2(cr.position.x + PAD, cr.end.y - 22.0), cell[1], size, cell[2])
		_tip(cr, cell[3])

func _draw_portfolio() -> void:
	var note := ""
	match phase:
		Phase.BUILD:
			note = "Sell by hovering a business" if buying == null else "Place it on a glowing lot"
		Phase.PLACE:
			note = "Drag every die onto a business"
		Phase.RESULT:
			note = "The turn is over"
	_zone(r_board, "Your portfolio", note, c_up)
	_draw_street_labels()
	for i in CELLS:
		var r := _cell_rect(i)
		var b: Biz = board[i]
		var threatened := _in_trouble_cell(i)
		if b == null:
			var legal := buying != null and _cell_allows(i, buying)
			_panel(r, Color(c_board_dark, 0.45), 20, Color(c_down, 0.6) if threatened else Color(c_board_line, 0.9), 3 if threatened else 2)
			var label := _cell_label(i)
			var rule: Dictionary = cell_rules[i]
			if label != "":
				var col: Color = _sector_color(rule["value"]) if rule.get("kind", "") == "sector" else cap_defs[rule["value"]]["chip"]
				var lr := Rect2(r.position.x + 20.0, r.get_center().y - 22.0, r.size.x - 40.0, 44.0)
				_panel(lr, col, 22)
				_heavy_center(lr, label, T_MD, Color.WHITE)
			else:
				_text_center(Rect2(r.position.x, r.get_center().y - 20.0, r.size.x, 40.0), "Open lot", T_MD, c_board_ink, true)
			if legal:
				var a := 0.55 + 0.35 * sin(clock * 5.0)
				_panel(r.grow(4.0), Color(0, 0, 0, 0), 24, Color(c_gold, a), 5)
				_register(r, _place_buy.bind(i))
			elif buying != null:
				_panel(r, Color(c_board, 0.55), 20)
			continue
		_draw_biz(r, b, true)
		var hovered := r.has_point(mouse)
		if phase == Phase.BUILD and buying == null and hovered:
			var sr := Rect2(Vector2(r.position.x + 14.0, r.end.y - 50.0), Vector2(r.size.x - 28.0, 40.0))
			_panel(sr, c_down_chip, 20)
			_heavy_center(sr, "Sell %s" % _whole_money(b.value), T_MD, Color.WHITE)
			_tip(sr, "Sell %s for its current value." % b.name)
			_register(sr, _sell.bind(b))
		if drag_die != null and hovered:
			_panel(r.grow(6.0), Color(0, 0, 0, 0), 26, c_gold, 5)

func _draw_street_labels() -> void:
	var hit_kind: String = trouble.get("kind", "")
	for c in COLS:
		var cr := _cell_rect(c)
		var hot: bool = hit_kind == "col" and int(trouble["value"]) == c
		var lr := Rect2(cr.position.x, cr.position.y - LABEL_H - 2.0, cr.size.x, LABEL_H - 4.0)
		if hot:
			_panel(lr, c_down, 12)
		_heavy_center(lr, COL_NAMES[c].to_upper(), T_XS + 1, Color.WHITE if hot else c_board_ink)
	for rw in ROWS:
		var cr := _cell_rect(rw * COLS)
		var hot: bool = hit_kind == "row" and int(trouble["value"]) == rw
		var lr := Rect2(r_board.position.x + PAD, cr.position.y, LABEL_W - SP, cr.size.y)
		if hot:
			_panel(lr, c_down, 14)
		var words: PackedStringArray = ROW_NAMES[rw].to_upper().split(" ")
		for k in words.size():
			_heavy_center(Rect2(lr.position.x, lr.get_center().y - 22.0 + k * 24.0, lr.size.x, 24.0), words[k], T_XS + 1, Color.WHITE if hot else c_board_ink)

func _rule_chip_w(rule: Dictionary) -> float:
	var w := 10.0
	if rule.has("color"):
		w += 24.0
	if rule.has("nums"):
		w += _heavy_w(_nums_label(rule["nums"]), T_SM) + 6.0
	return w

func _nums_label(nums: Array) -> String:
	if nums.size() >= 2 and int(nums[nums.size() - 1]) - int(nums[0]) == nums.size() - 1:
		return "%d-%d" % [int(nums[0]), int(nums[nums.size() - 1])]
	var parts: Array[String] = []
	for n in nums:
		parts.append(str(int(n)))
	return ",".join(parts)

func _fx_label(fx: Dictionary) -> String:
	if fx.has("bankrupt"):
		return "Bankrupt"
	var parts: Array[String] = []
	if fx.has("value"):
		parts.append("%+d%%" % int(round(float(fx["value"]) * 100.0)))
	if fx.has("cash"):
		parts.append("%s$%d" % ["+" if float(fx["cash"]) >= 0.0 else "-", int(absf(float(fx["cash"])))])
	return " ".join(parts)

func _rule_text(rule: Dictionary) -> String:
	var when := ""
	if rule.has("color") and rule.has("nums"):
		when = "A %s die showing %s" % [rule["color"], _nums_label(rule["nums"])]
	elif rule.has("color"):
		when = "Any %s die" % rule["color"]
	else:
		when = "A die showing %s" % _nums_label(rule["nums"])
	var fx: Dictionary = rule["fx"]
	var what := ""
	if fx.has("bankrupt"):
		what = "the business goes bankrupt"
	else:
		var bits: Array[String] = []
		if fx.has("value"):
			bits.append("its value changes %+d%%" % int(round(float(fx["value"]) * 100.0)))
		if fx.has("cash"):
			bits.append("you collect $%d" % int(float(fx["cash"])))
		what = " and ".join(bits)
	return "%s: %s." % [when, what]

func _draw_biz(r: Rect2, b: Biz, owned: bool) -> void:
	_shadow(r, 20, 8.0)
	var sec_col := _sector_color(b.sector)
	var body := c_stock.lerp(sec_col, 0.08)
	if owned and b.flash > 0.0 and b.has_last:
		body = body.lerp(c_up_soft if b.last_delta >= 0.0 else c_down_soft, clampf(b.flash * 1.4, 0.0, 1.0))
	elif owned and b.flash > 0.0:
		body = body.lerp(Color("fcecc4"), clampf(b.flash * 1.4, 0.0, 1.0))
	var threatened := owned and _in_trouble(b)
	var pv := _preview(b) if owned and phase == Phase.PLACE else {}
	_panel(r, body, 20, c_down if threatened else sec_col, 6)
	var band := Rect2(r.position, Vector2(r.size.x, 36.0))
	_panel_corners(band, sec_col, 20, 20, 0, 0)
	_heavy(Vector2(r.position.x + 18.0, band.position.y + 26.0), b.sector.to_upper(), T_SM, Color.WHITE)
	var lbl: String = cap_defs[b.cap]["label"].to_upper()
	var chip := Rect2(r.end.x - 14.0 - _heavy_w(lbl, T_XS) - 16.0, band.position.y + 7.0, _heavy_w(lbl, T_XS) + 16.0, 22.0)
	_panel(chip, cap_defs[b.cap]["chip"], 11)
	_heavy_center(chip, lbl, T_XS, Color.WHITE)
	_tip(band, "%s, %s. A %s die is its sector colour." % [b.sector, cap_defs[b.cap]["label"], COLOR_NAMES[_sector_color_index(b.sector)]])
	var nsize := T_LG
	while nsize > 14 and _heavy_w(b.name, nsize) > r.size.x - 32.0:
		nsize -= 1
	_heavy(Vector2(r.position.x + 16.0, r.position.y + 70.0), b.name, nsize, c_ink)
	_text(Vector2(r.position.x + 16.0, r.position.y + 96.0), "Value", T_SM, c_muted, true)
	_heavy(Vector2(r.position.x + 16.0, r.position.y + 128.0), _money(b.value), T_XL - 6, c_ink)
	if not pv.is_empty() and (not _dice_on(b).is_empty() or bool(pv["hit"])):
		var dv: float = float(pv["value"]) - b.value + float(pv["cash"])
		var ps := "Bankrupt" if bool(pv["bankrupt"]) else _signed_money(dv)
		_heavy(Vector2(r.position.x + 22.0 + _heavy_w(_money(b.value), T_XL - 6), r.position.y + 126.0), ps, T_MD, c_down if bool(pv["bankrupt"]) or dv < 0.0 else c_up)
	var fired: Array = pv.get("fired", [])
	var top := r.position.y + 142.0
	for k in b.rules.size():
		var rule: Dictionary = b.rules[k]
		var rr := Rect2(r.position.x + 10.0, top + k * RULE_H, r.size.x - 20.0, RULE_H - 4.0)
		var bad := _rule_is_bad(rule)
		var on := fired.has(k)
		_panel(rr, c_down_soft if bad else c_up_soft, 8, c_gold if on else Color(0, 0, 0, 0), 3 if on else 0)
		var cw := _rule_chip_w(rule)
		var cr := Rect2(rr.position.x + 3.0, rr.position.y + 3.0, cw, rr.size.y - 6.0)
		_panel(cr, c_ink, 6)
		var cx := cr.position.x + 6.0
		if rule.has("color"):
			draw_circle(Vector2(cx + 10.0, cr.get_center().y), 9.0, tile_colors[COLOR_NAMES.find(rule["color"])])
			cx += 24.0
		if rule.has("nums"):
			_heavy(Vector2(cx, cr.get_center().y + 6.0), _nums_label(rule["nums"]), T_SM, Color.WHITE)
		var nm: String = rule["name"]
		var fl := _fx_label(rule["fx"])
		var ink := c_down if bad else c_up
		_heavy_right(rr.end.x - 8.0, rr.get_center().y + 7.0, fl, T_SM, ink)
		var room := rr.end.x - 14.0 - _heavy_w(fl, T_SM) - (cr.end.x + 8.0)
		var ns := T_SM
		while ns > 11 and _heavy_w(nm, ns) > room:
			ns -= 1
		_heavy(Vector2(cr.end.x + 8.0, rr.get_center().y + 6.0), nm, ns, c_ink)
		_tip(rr, "%s\n%s" % [nm, _rule_text(rule)])
	if threatened:
		var tr := Rect2(r.position.x + 10.0, r.end.y - 34.0, r.size.x - 20.0, 28.0)
		var safe := not _dice_on(b).is_empty()
		_panel(tr, c_up if safe else c_down, 14)
		var ts := "Protected" if safe else "%s  -%d%%" % [trouble["title"], int(round(float(trouble["pct"]) * 100.0))]
		_heavy_center(tr, ts, T_SM, Color.WHITE)
		_tip(tr, "A die on this business protects it from the trouble." if not safe else "A die is on it, so the trouble can't touch it.")

func _draw_tray() -> void:
	var r := r_tray
	_shadow(r, 26, 4.0, 0.15)
	_panel(r, c_well, 26)
	_panel_corners(Rect2(r.position, Vector2(r.size.x, HEAD_H)), c_well.darkened(0.25), 26, 26, 0, 0)
	_diamond(r.position + Vector2(PAD + 9.0, HEAD_H * 0.5 + 1.0), 9.0, c_gold)
	_heavy(Vector2(r.position.x + PAD + 28.0, r.position.y + 36.0), "Dice", T_LG, Color.WHITE)
	var msg := ""
	match phase:
		Phase.BUILD:
			msg = "Finish buying, then draw this turn's trouble"
		Phase.TROUBLE:
			msg = "Roll %d dice. Every die must go on a business." % dice_count
		Phase.PLACE:
			var left := 0
			for d in dice:
				if d.target == null:
					left += 1
			msg = "%d left to place" % left if left > 0 else "Every die is placed"
		Phase.RESULT:
			msg = "The turn is resolved"
	var area_w := r.size.x - 260.0
	if dice.is_empty():
		for i in dice_count:
			var hp := _tray_home(i, dice_count)
			_panel(Rect2(hp - Vector2(DIE_SIZE, DIE_SIZE) * 0.5, Vector2(DIE_SIZE, DIE_SIZE)), Color(1, 1, 1, 0.06), 20, Color(1, 1, 1, 0.18), 2)
	_text_center(Rect2(r.position.x, r.position.y + ZONE_HEAD + 180.0, area_w, 30.0), msg, T_MD, Color(1, 1, 1, 0.75), true)
	var ly := r.end.y - 48.0
	var step := area_w / 6.0
	for k in 6:
		var c := Vector2(r.position.x + step * (k + 0.5) - 26.0, ly)
		draw_circle(c, 11.0, tile_colors[k])
		_text(Vector2(c.x + 18.0, c.y + 6.0), COLOR_NAMES[k].capitalize(), T_XS + 1, Color(1, 1, 1, 0.7), true)
	draw_line(Vector2(r.end.x - 260.0, r.position.y + HEAD_H + PAD), Vector2(r.end.x - 260.0, r.end.y - PAD), Color(1, 1, 1, 0.12), 2.0)
	var cc := Vector2(r.end.x - 130.0, r.position.y + HEAD_H + (r.size.y - HEAD_H) * 0.5)
	match phase:
		Phase.BUILD:
			_coin(cc, 92.0, "Draw\ntrouble", _primary_action, true)
		Phase.TROUBLE:
			_coin(cc, 92.0, "Roll", _primary_action, true)
		Phase.PLACE:
			_coin(cc, 92.0, "Resolve", _primary_action, _all_placed())
		Phase.RESULT:
			_coin(cc, 92.0, "Next\nturn" if not (won or lost) else "See\nresult", _primary_action, true)
		_:
			_coin(cc, 92.0, "...", _primary_action, false)

func _draw_log() -> void:
	_zone(r_log, "Turn report", "Turn %d" % turn if not log_rows.is_empty() else "", c_violet)
	var x := r_log.position.x + PAD
	var right := r_log.end.x - PAD
	var y := r_log.position.y + ZONE_HEAD + SP
	if log_rows.is_empty():
		_wrap(Vector2(x, y + 30.0), "What happens to each business shows up here once the turn resolves.", right - x, T_MD, c_board_ink, true, 3)
		return
	for row in log_rows:
		if y + 52.0 > r_log.end.y - PAD:
			break
		var rr := Rect2(x, y, right - x, 46.0)
		_panel(rr, c_board, 12)
		_diamond(Vector2(rr.position.x + 18.0, rr.get_center().y), 7.0, row["color"])
		_heavy(Vector2(rr.position.x + 36.0, rr.get_center().y + 7.0), row["name"], T_MD, c_ink)
		var note: String = row["note"]
		if note != "":
			_text(Vector2(rr.position.x + 44.0 + _heavy_w(row["name"], T_MD), rr.get_center().y + 6.0), note, T_SM, c_muted, true)
		var dv: float = row["delta"]
		var ds := "Bankrupt" if bool(row["bankrupt"]) else _signed_money(dv)
		_heavy(Vector2(rr.end.x - 14.0 - _heavy_w(ds, T_MD), rr.get_center().y + 7.0), ds, T_MD, c_down if bool(row["bankrupt"]) or dv < -0.004 else (c_up if dv > 0.004 else c_muted))
		y += 52.0

func _draw_die(d: Die) -> void:
	var small := d.target != null and d != drag_die and d.roll_t <= 0.0
	var size := MINI_DIE if small else DIE_SIZE
	var hovered := phase == Phase.PLACE and drag_die == null and absf(mouse.x - d.pos.x) < size * 0.55 and absf(mouse.y - d.pos.y) < size * 0.55
	var lift := 1.08 if d == drag_die else (1.05 if hovered else 1.0)
	draw_set_transform_matrix(_screen_xform() * Transform2D(d.ang, Vector2(lift, lift), 0.0, d.pos))
	if not small:
		_panel(Rect2(Vector2(-size, -size) * 0.5 + Vector2(4, 10.0 if d != drag_die else 22.0), Vector2(size, size)), Color(c_shadow, 0.18), int(size * 0.2))
	var ci := _die_color(d, d.shown_face)
	var outline := c_gold if hovered else Color(1, 1, 1, 0.9) if small else Color(0, 0, 0, 0)
	_draw_die_body(Vector2.ZERO, size, d.shown_face, tile_colors[ci], c_ink if ci == 2 else Color.WHITE, outline)
	draw_set_transform_matrix(_screen_xform())
	if d.roll_t <= 0.0:
		_tip(Rect2(d.pos - Vector2(size, size) * 0.5, Vector2(size, size)), "A %s %d." % [COLOR_NAMES[ci], d.face])

func _draw_gameover() -> void:
	_dim()
	var w := 1040.0
	var h := 640.0
	var r := Rect2((view_size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_shadow(r, 28, 14.0)
	_panel(r, c_stock, 28)
	var x := r.position.x + 64.0
	var right := r.end.x - 64.0
	var title := "Your portfolio survived %d turns" % total_turns if won else "Margin call on turn %d" % turn
	_heavy(Vector2(x, r.position.y + 100.0), title, T_HERO, c_up if won else c_down)
	var sub := "The market couldn't shake you." if won else "Your net worth fell below %s." % _money(_margin_for(turn))
	_text(Vector2(x, r.position.y + 148.0), sub, T_LG, c_muted, true)
	var stats := [
		["Final net worth", _money(_net_worth())],
		["Peak net worth", _money(peak_worth)],
		["Businesses owned", str(_owned().size())],
		["Bankruptcies", str(bankruptcies)],
	]
	var y := r.position.y + 236.0
	for st in stats:
		_text(Vector2(x, y), st[0], T_LG, c_muted, true)
		_heavy_right(right, y, st[1], T_XL, c_ink)
		y += 62.0
	_pill(Rect2(right - 320.0, r.end.y - 52.0 - 76.0, 320.0, 76.0), "Play again", _new_run, true, "gold", T_XL)
