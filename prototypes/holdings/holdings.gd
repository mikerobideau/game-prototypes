extends Node2D
class_name HoldingsPrototype

const D := preload("res://prototypes/holdings/holdings_data.gd")
const ART_DIRS := ["res://prototypes/holdings/art/", "res://prototypes/holdings/art_silhouette/"]
const ART_SCALE := 2.5

enum Phase { ACTION, REPORT, GAMEOVER, MENU }
enum MissRule { STRIKES, DEBT }

@export_group("Run")
@export var run_seed: int = 0
@export var rounds_per_run: int = 28
@export var strikes_to_lose: int = 2
@export var miss_rule: MissRule = MissRule.STRIKES

@export_group("Dice")
@export var base_dice: int = 4
@export var min_dice: int = 3
@export var max_dice: int = 5
@export var trade_die_cash: int = 1
@export var reroll_cost: int = 2

@export_group("Board and market")
@export var board_slots: int = 9
@export var market_size: int = 4

@export_group("Economy")
@export var exchange_rate: int = 3
@export var storage_cap: int = 8

@export_group("Cards")
@export_enum("Classic frame", "Modern gradient", "Foil rarity") var card_style: int = 0
@export_enum("Halo", "Sunburst", "Skyline", "Art window", "Icon pattern") var card_bg: int = 1
@export_enum("Illustrated", "Silhouette") var art_set: int = 1

@export_group("Forecast")
@export var forecast_length: int = 3
@export var forecast_visible: int = 2

class CardInst:
	var uid := 0
	var id := ""
	var dormant := false
	var activated := false
	var pending: Array[int] = []
	var used_values: Array[int] = []
	var ops := 0
	var bonus := 0
	var age := 0
	var flash := 0.0
	var shake := 0.0
	var edition := ""
	var place_t := 1.0
	var place_from := Vector2.ZERO

class Die:
	var value := 1
	var shown := 1
	var used := false
	var card_uid := -1
	var roll_t := 0.0
	var flicker := 0.0

class FloatText:
	var pos := Vector2.ZERO
	var anchor := Vector2.ZERO
	var life := 1.4
	var age := 0.0
	var delay := 0.0
	var text := ""
	var icon := ""
	var color := Color.WHITE

class UiButton:
	var rect: Rect2
	var cb: Callable

const UI_W := 2560.0
const UI_H := 1440.0
const GRID_COLS := 3
const CARD_H := 356.0
const CARD_GAP := 20.0
const SLEEVE_GLOSS := 0.1
const PLACE_TIME := 0.6
const MARGIN := 40.0
const COL_GAP := 28.0
const PANEL_PAD := 28.0
const PANEL_HEAD := 64.0
const SPINE := 60.0
const BIND_STRIP := 26.0
const HEADER_Y := 28.0
const HEADER_H := 140.0
const BODY_TOP := 196.0
const DIE_SIZE := 68.0
const DIE_STEP := 80.0

const T_XS := 16
const T_SM := 20
const T_MD := 24
const T_LG := 30
const T_XL := 40
const T_HERO := 64

const SAVE_PATH := "user://holdings.cfg"

var c_bg := Color("eef0f2")
var c_panel := Color("e3e7eb")
var c_line := Color("d4dae0")
var c_card := Color("ffffff")
var c_ink := Color("1e2633")
var c_body := Color("4f5866")
var c_muted := Color("7a8290")
var c_shadow := Color("1e2633")
var c_good := Color("3e7b4f")
var c_bad := Color("c4553f")
var c_warn := Color("c8862f")
var c_gold := Color("e9b949")
var c_accent := Color("3e7b4f")
var c_ice := Color("bfe0f2")
var c_desk := Color("dbe2ea")
var c_page := Color("141a24")
var c_region := Color("1f2735")
var c_region_alt := Color("232d3d")
var c_light := Color("eef2f7")
var c_light_muted := Color("98a4b6")
var c_hole := Color(1, 1, 1, 0.06)

var rng := RandomNumberGenerator.new()
var seed_used := 0
var phase := Phase.ACTION
var round_n := 1
var strikes := 0
var slot_locks: Array[Dictionary] = []
var goals_met := 0
var slot_rules: Array[Dictionary] = []
var slot_mods: Array[String] = []
var market_eds := {}
const DEAL_EDITION_CHANCE := 0.1
const DEAL_EDITION_WEIGHTS := {"bluechip": 3, "franchise": 3, "holo": 2, "gold": 2}
var meeting: Array[String] = []
var meeting_info := {}
var pending_meeting := {}
var board_pick := -1
var debt := 0
var best_quarters := 0
var sheet_best := {}
var sheet_id := ""
var game_result := ""
var res := {}
var board: Array[CardInst] = []
var market: Array[String] = []
var deck: Array[String] = []
var discard: Array[String] = []
var forecast: Array[Dictionary] = []
var queued_penalties: Array = []
var mods := {}
var dice: Array[Die] = []
var selected_die := -1
var act_vp := 0
var year_vp := 0
var years: Array[Dictionary] = []
var spent := {}
var activations := 0
var types_activated := {}
var extra_dice_next := 0
var dice_notes: Array[String] = []
var round_notes: Array[String] = []
var choice := {}
var choice_queue: Array[Dictionary] = []
var report := {}
var history: Array[Dictionary] = []
var toast := ""
var toast_t := -10.0
var next_uid := 1
var show_help := false
var event_intro := false
var debug_on := false
var hover_forecast := -1
var float_next := 0.0
const FLOAT_STEP := 0.24

var floaters: Array[FloatText] = []
var buttons: Array[UiButton] = []
var ui_live := true
var hover_tip := ""
var hover_card := {}
var mouse := Vector2.ZERO
var sfx: Dictionary = {}
var music: AudioStreamPlayer
var dice_sfx_left := 0.0
var hover_rect := Rect2()
var tut_on := false
var tut_step := 0
var tut_rects: Dictionary = {}
var tut_panel := Rect2()
var clock := 0.0
var window_size := Vector2.ZERO
var ui_scale := 1.0
var screen_origin := Vector2.ZERO

var card_w := 254.0
var market_pick := -1
var r_portfolio := Rect2()
var r_market := Rect2()
var r_supply := Rect2()
var p_portfolio := Rect2()
var p_market := Rect2()
var p_supply := Rect2()
var h_left := Rect2()
var h_center := Rect2()
var s_mat := Rect2()
var s_end := Rect2()

var font: Font
var font_bold: Font
var font_italic: Font
var font_heavy: Font
var font_title: Font
var font_serif: Font
var font_serif_italic: Font
var font_marker: Font
var style := StyleBoxFlat.new()
var base_xform := Transform2D.IDENTITY
var art_cache := {}
var card_xform := Transform2D.IDENTITY

func _init() -> void:
	D.load_tables()

func _ready() -> void:
	_load_fonts()
	_load_best()
	_recompute_layout()
	get_viewport().size_changed.connect(_recompute_layout)
	_validate_data()
	_load_sounds()
	phase = Phase.MENU

func _load_sounds() -> void:
	for n: String in ["click", "mouseover", "dice", "page_turn"]:
		var path := "res://prototypes/holdings/sound/%s.%s" % [n, "mp3" if n in ["dice", "page_turn"] else "wav"]
		if not ResourceLoader.exists(path):
			continue
		var pl := AudioStreamPlayer.new()
		pl.stream = load(path)
		pl.volume_db = -10.0 if n == "mouseover" else -4.0
		add_child(pl)
		sfx[n] = pl
	var mpath := "res://prototypes/holdings/sound/background_music.mp3"
	if ResourceLoader.exists(mpath):
		var stream: AudioStreamMP3 = load(mpath)
		stream.loop = true
		music = AudioStreamPlayer.new()
		music.stream = stream
		music.volume_db = -14.0
		add_child(music)
		music.play()

func _sfx(n: String) -> void:
	if not sfx.has(n):
		return
	var pl: AudioStreamPlayer = sfx[n]
	pl.play(0.5 if n == "page_turn" else 0.0)
	if n == "dice":
		dice_sfx_left = 1.0

func _load_fonts() -> void:
	var ts := TextServerManager.get_primary_interface()
	var wght := ts.name_to_tag("wght")
	var sans_path := "res://assets/fonts/DMSans-VariableFont.ttf"
	var serif_path := "res://assets/fonts/Fraunces-VariableFont.ttf"
	font = ThemeDB.fallback_font
	font_bold = ThemeDB.fallback_font
	font_italic = ThemeDB.fallback_font
	font_heavy = ThemeDB.fallback_font
	if ResourceLoader.exists(sans_path):
		var sans: Font = load(sans_path)
		font = _variation(sans, {wght: 450})
		font_bold = _variation(sans, {wght: 700})
		var it := _variation(sans, {wght: 450})
		it.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.22, 1.0), Vector2.ZERO)
		font_italic = it
	if ResourceLoader.exists(serif_path):
		var serif: Font = load(serif_path)
		font_heavy = _variation(serif, {wght: 700, ts.name_to_tag("opsz"): 72, ts.name_to_tag("SOFT"): 50})
	font_title = font_heavy
	font_marker = font_heavy
	if ResourceLoader.exists("res://assets/fonts/PermanentMarker-Regular.ttf"):
		font_marker = load("res://assets/fonts/PermanentMarker-Regular.ttf")
	font_serif = font_heavy
	font_serif_italic = font_italic
	if ResourceLoader.exists(serif_path):
		var serif2: Font = load(serif_path)
		font_serif = _variation(serif2, {wght: 420, ts.name_to_tag("opsz"): 14})
		var si := _variation(serif2, {wght: 420, ts.name_to_tag("opsz"): 14})
		si.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.2, 1.0), Vector2.ZERO)
		font_serif_italic = si

func _variation(base: Font, axes: Dictionary) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = axes
	return v

func _recompute_layout() -> void:
	window_size = get_viewport_rect().size
	ui_scale = minf(window_size.x / UI_W, window_size.y / UI_H)
	screen_origin = (window_size - Vector2(UI_W, UI_H) * ui_scale) * 0.5
	var rows := ceili(board_slots / float(GRID_COLS))
	card_w = floorf(CARD_H * 5.0 / 7.0)
	var gw := GRID_COLS * card_w + (GRID_COLS - 1) * CARD_GAP
	var gh := rows * CARD_H + (rows - 1) * CARD_GAP
	var ph := PANEL_HEAD + gh + PANEL_PAD
	var market_w := card_w * 2.0 + CARD_GAP + PANEL_PAD * 2.0
	var portfolio_w := gw + PANEL_PAD * 2.0 + SPINE
	var supply_w := 560.0
	var x0 := (UI_W - market_w - portfolio_w - supply_w - COL_GAP * 2.0) * 0.5
	p_market = Rect2(x0, BODY_TOP, market_w, ph)
	p_portfolio = Rect2(p_market.end.x + COL_GAP, BODY_TOP, portfolio_w, ph)
	p_supply = Rect2(p_portfolio.end.x + COL_GAP, BODY_TOP, supply_w, ph)
	r_portfolio = Rect2(p_portfolio.position.x + PANEL_PAD + SPINE, BODY_TOP + PANEL_HEAD, gw, gh)
	r_market = Rect2(p_market.position.x + PANEL_PAD, r_portfolio.position.y, card_w * 2.0 + CARD_GAP, gh)
	r_supply = Rect2(p_supply.position.x + PANEL_PAD, r_portfolio.position.y, supply_w - PANEL_PAD * 2.0, gh)
	h_left = Rect2(p_market.position.x, HEADER_Y, market_w, HEADER_H)
	h_center = Rect2(p_portfolio.position.x, HEADER_Y, p_supply.end.x - p_portfolio.position.x, HEADER_H)
	s_mat = Rect2(r_supply.position, Vector2(r_supply.size.x, 470.0))
	s_end = Rect2(r_supply.position.x, r_supply.end.y - 104.0, r_supply.size.x, 104.0)

func _validate_data() -> void:
	for id: String in D.CARDS:
		var c: Dictionary = D.CARDS[id]
		var p: Dictionary = c.get("pattern", {})
		if not p.is_empty() and not D.PATTERNS.has(p["kind"]):
			push_warning("Card %s has unknown pattern %s" % [id, p["kind"]])
		if int(c["value"]) < 1 or int(c["value"]) > 7:
			push_warning("Card %s value out of range" % id)
	for msg in _tutorial_problems():
		push_warning("Tutorial: " + msg)

func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_quarters = int(cfg.get_value("run", "best_quarters", 0))
		if cfg.has_section("sheets"):
			for k in cfg.get_section_keys("sheets"):
				sheet_best[k] = int(cfg.get_value("sheets", k, 0))

func _save_best() -> void:
	var reached := history.size()
	var changed := false
	if reached > best_quarters:
		best_quarters = reached
		changed = true
	if sheet_id != "" and reached > int(sheet_best.get(sheet_id, 0)):
		sheet_best[sheet_id] = reached
		changed = true
	if not changed:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("run", "best_quarters", best_quarters)
	for k in sheet_best:
		cfg.set_value("sheets", k, int(sheet_best[k]))
	cfg.save(SAVE_PATH)

func _new_run(s: int) -> void:
	seed_used = s
	rng.seed = s
	phase = Phase.ACTION
	round_n = 1
	strikes = 0
	debt = 0
	year_vp = 0
	years.clear()
	game_result = ""
	res = D.STARTING_RESOURCES.duplicate()
	next_uid = 1
	goals_met = 0
	slot_rules = _make_slot_rules()
	slot_locks = _make_slot_locks()
	slot_mods.clear()
	slot_mods.resize(board_slots)
	slot_mods.fill("")
	var sheet: Dictionary = D.SHEETS.get(sheet_id, {})
	if not sheet.is_empty():
		if not bool(sheet["random"]) and (sheet["rules"] as Array).size() >= board_slots:
			for i in board_slots:
				slot_rules[i] = (sheet["rules"][i] as Dictionary).duplicate(true)
				slot_locks[i] = (sheet["locks"][i] as Dictionary).duplicate(true)
				slot_mods[i] = String(sheet["pockets"][i])
		var bonus: Dictionary = sheet["bonus"]
		for r: String in bonus:
			res[r] = _r(r) + int(bonus[r])
	meeting.clear()
	meeting_info = {}
	market_eds = {}
	pending_meeting = {}
	board.clear()
	board.resize(board_slots)
	for i in D.STARTING_BOARD.size():
		if i < board_slots:
			board[i] = _make_inst(D.STARTING_BOARD[i])
	deck = _build_deck()
	discard.clear()
	market.clear()
	market.resize(market_size)
	for i in market_size:
		market[i] = _deal_card()
	forecast.clear()
	for i in forecast_length:
		forecast.append(_new_event(i + 1))
	queued_penalties.clear()
	extra_dice_next = 0
	history.clear()
	report = {}
	toast = ""
	_start_round()

func _make_inst(id: String) -> CardInst:
	var inst := CardInst.new()
	inst.uid = next_uid
	next_uid += 1
	inst.id = id
	return inst

func _build_deck() -> Array[String]:
	var out: Array[String] = []
	for id: String in D.CARDS:
		if D.STARTING_BOARD.has(id):
			continue
		var c: Dictionary = D.CARDS[id]
		var copies := int(c.get("copies", D.RARITY_COPIES.get(String(c.get("rarity", "common")), 1)))
		for n in copies:
			out.append(id)
	_shuffle(out)
	return out

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = t

func _deal_card() -> String:
	if deck.is_empty() and not discard.is_empty():
		deck = discard.duplicate()
		discard.clear()
		_shuffle(deck)
		_say("Deal deck reshuffled")
	if deck.is_empty():
		return ""
	return deck.pop_back()

func _tiers_for(r: int) -> Array:
	for t: Dictionary in D.EVENT_TIERS:
		if r <= int(t["until"]):
			return t["tiers"]
	return ["severe"]

func _new_event(for_round: int) -> Dictionary:
	var tiers := _tiers_for(for_round)
	var pool: Array[String] = []
	for id: String in D.EVENTS:
		if tiers.has(D.EVENTS[id]["tier"]):
			pool.append(id)
	if not forecast.is_empty() and pool.size() > 1:
		pool.erase(String(forecast.back()["id"]))
	if pool.is_empty():
		return {"id": "steady_market", "weak": false, "revealed": false}
	return {"id": pool[rng.randi_range(0, pool.size() - 1)], "weak": false, "revealed": false}

func _start_round() -> void:
	mods = {"cost_plus": {}, "refresh_plus": 0, "dice_delta": 0}
	act_vp = 0
	spent = {}
	activations = 0
	types_activated = {}
	selected_die = -1
	choice = {}
	market_pick = -1
	board_pick = -1
	choice_queue.clear()
	round_notes.clear()
	dice_notes.clear()
	for inst in board:
		if inst != null:
			inst.activated = false
			inst.ops = 0
			inst.pending.clear()
			inst.used_values.clear()
	var ev: Dictionary = forecast[0]
	var ev_name := _event_name(ev)
	for m: Dictionary in _event_mods(ev):
		_apply_mod(m, ev_name)
	for m: Dictionary in queued_penalties:
		_apply_mod(m, "Penalty")
	queued_penalties.clear()
	var tier := String(D.EVENTS[ev["id"]]["tier"])
	if tier == "moderate" or tier == "severe":
		_fire_all("bad_event")
	var extra := extra_dice_next
	extra_dice_next = 0
	if extra > 0:
		dice_notes.push_front("+%d from abilities" % extra)
	var n := clampi(base_dice + extra + int(mods["dice_delta"]), min_dice, max_dice)
	_roll(n)
	phase = Phase.ACTION
	event_intro = true

func _event_name(ev: Dictionary) -> String:
	return String(D.EVENTS[ev["id"]]["name"])

func _event_mods(ev: Dictionary) -> Array:
	var e: Dictionary = D.EVENTS[ev["id"]]
	if bool(ev.get("weak", false)):
		return e.get("weak", [])
	return e.get("mods", [])

func _event_condition(ev: Dictionary) -> Dictionary:
	if bool(ev.get("weak", false)):
		return {}
	return D.EVENTS[ev["id"]].get("condition", {})

func _event_text(ev: Dictionary) -> String:
	var e: Dictionary = D.EVENTS[ev["id"]]
	if bool(ev.get("weak", false)):
		return "Weakened: " + String(e.get("weak_text", "no effect"))
	return String(e["text"])

func _event_target_uid(ev: Dictionary) -> int:
	var lists: Array = [_event_mods(ev)]
	if not _event_condition(ev).is_empty():
		lists.append(D.EVENTS[ev["id"]].get("penalty", []))
	for list: Array in lists:
		for m: Dictionary in list:
			if m.has("target"):
				return _target_uid(String(m["target"]))
	return -1

func _apply_mod(m: Dictionary, source: String) -> void:
	var kind := String(m["kind"])
	match kind:
		"dice_minus":
			var amt := int(m["amount"])
			mods["dice_delta"] = int(mods["dice_delta"]) - amt
			dice_notes.append("-%d %s" % [amt, source])
		"dice_minus_per_cards":
			var amt := floori(_board_count() / float(m["per"]))
			if amt > 0:
				mods["dice_delta"] = int(mods["dice_delta"]) - amt
				dice_notes.append("-%d %s" % [amt, source])
			round_notes.append("%s: -%d dice (%d businesses)" % [source, amt, _board_count()])
		"odd_minus":
			mods["odd_minus"] = true
			round_notes.append("%s: odd dice rolled -1" % source)
		"cap_highest":
			mods["cap_highest"] = int(m["cap"])
		"cost_plus":
			var cp: Dictionary = mods["cost_plus"]
			cp[m["res"]] = int(cp.get(m["res"], 0)) + int(m["amount"])
		"refresh_plus":
			mods["refresh_plus"] = int(mods["refresh_plus"]) + int(m["amount"])
		"market_frozen":
			mods["market_frozen"] = true
		"refresh_frozen":
			mods["refresh_frozen"] = true
		"lose_half":
			var r := String(m["res"])
			var lost := floori(_r(r) * 0.5)
			res[r] = _r(r) - lost
			round_notes.append("%s: lost %d %s" % [source, lost, D.RES_NAMES[r]])
		"halve_output":
			var u := _target_uid(String(m["target"]))
			if u >= 0:
				mods["halve_output_uid"] = u
				round_notes.append("%s: %s gives half output" % [source, _inst_name(u)])
		"halve_value":
			var u := _target_uid(String(m["target"]))
			if u >= 0:
				mods["halve_value_uid"] = u
				round_notes.append("%s: %s adds half its Brand" % [source, _inst_name(u)])
		"dormant":
			var u := _target_uid(String(m["target"]))
			if u >= 0:
				_distress(_inst_by_uid(u), source)
		"intel_locked":
			mods["intel_locked"] = true
			round_notes.append("%s: Intelligence can't be spent" % source)
		"exchange_rate":
			mods["exchange_rate"] = int(m["rate"])
		_:
			push_warning("Unknown modifier %s" % kind)

func _target_uid(target: String) -> int:
	var best: CardInst = null
	for inst in board:
		if inst == null or inst.dormant or inst.edition == "bluechip":
			continue
		var v := _base_value(inst)
		match target:
			"highest_value":
				if best == null or v > _base_value(best):
					best = inst
			"highest_value_ability":
				if not _base_pattern(inst.id).is_empty() and (best == null or v > _base_value(best)):
					best = inst
			"lowest_value":
				if best == null or v < _base_value(best):
					best = inst
	return best.uid if best != null else -1

func _inst_by_uid(uid: int) -> CardInst:
	for inst in board:
		if inst != null and inst.uid == uid:
			return inst
	return null

func _inst_name(uid: int) -> String:
	var inst := _inst_by_uid(uid)
	return _card_name(inst.id) if inst != null else "?"

func _slot_of(inst: CardInst) -> int:
	return board.find(inst)

func _card_name(id: String) -> String:
	return String(D.CARDS[id]["name"])

func _card_type(id: String) -> String:
	return String(D.CARDS[id]["type"])

func _base_value(inst: CardInst) -> int:
	return int(D.CARDS[inst.id]["value"]) + inst.bonus

func _effective_value(inst: CardInst) -> int:
	var v := _base_value(inst)
	var t := _card_type(inst.id)
	for n in _neighbors(inst):
		var aura: Dictionary = D.CARDS[n.id].get("passive", {}).get("adjacent_value", {})
		if not n.dormant and not aura.is_empty() and String(aura["type"]) == t:
			v += int(aura["amount"])
	if int(mods.get("halve_value_uid", -1)) == inst.uid:
		v = floori(v * 0.5)
	return v

func _base_pattern(id: String) -> Dictionary:
	return D.CARDS[id].get("pattern", {})

func _effective_pattern(inst: CardInst) -> Dictionary:
	var overrides: Dictionary = mods.get("pattern_override", {})
	var p: Dictionary = overrides.get(inst.uid, _base_pattern(inst.id))
	if not p.is_empty():
		if _slot_mod(_slot_of(inst)) == "express":
			return {"kind": "any"}
		for n in _neighbors(inst):
			if not n.dormant and _has_passive(n, "adjacent_any_die"):
				return {"kind": "any"}
	return p

func _dice_needed(p: Dictionary) -> int:
	if p.is_empty():
		return 0
	return int(D.PATTERNS[p["kind"]]["dice"])

func _pattern_label(p: Dictionary) -> String:
	if p.is_empty():
		return "None"
	var label := String(D.PATTERNS[p["kind"]]["label"])
	return label % int(p.get("param", 0)) if label.contains("%d") else label

func _pattern_short(p: Dictionary) -> String:
	if p.is_empty():
		return "Passive"
	var label := String(D.PATTERNS[p["kind"]].get("short", D.PATTERNS[p["kind"]]["label"]))
	return label % int(p.get("param", 0)) if label.contains("%d") else label

func _pattern_rule(p: Dictionary) -> String:
	if p.is_empty():
		return "cannot be activated"
	var rule := String(D.PATTERNS[p["kind"]]["rule"])
	return rule % int(p.get("param", 0)) if rule.contains("%d") else rule

func _fits1(p: Dictionary, v: int) -> bool:
	var n := int(p.get("param", 0))
	match String(p["kind"]):
		"odd":
			return v % 2 == 1
		"even":
			return v % 2 == 0
		"low":
			return v <= 3
		"high":
			return v >= 4
		"exact":
			return v == n
		"at_least":
			return v >= n
		"at_most":
			return v <= n
		"any":
			return true
	return false

func _fits2(p: Dictionary, a: int, b: int) -> bool:
	var n := int(p.get("param", 0))
	match String(p["kind"]):
		"pair":
			return a == b
		"sum_at_least":
			return a + b >= n
		"sum_exactly":
			return a + b == n
		"run":
			return absi(a - b) == 1
	return false

func _r(k: String) -> int:
	return int(res.get(k, 0))

func _board_count() -> int:
	var n := 0
	for inst in board:
		if inst != null:
			n += 1
	return n

func _make_slot_rules() -> Array[Dictionary]:
	var caps: Array = [{"kind": "cap", "min": 1, "max": 2}, {"kind": "cap", "min": 3, "max": 4}, {"kind": "cap", "min": 5, "max": 99}]
	var sectors: Array = D.TYPES.duplicate()
	var picked: Array = []
	for i in 3:
		picked.append({"kind": "sector", "type": String(sectors.pop_at(rng.randi_range(0, sectors.size() - 1)))})
	var top: Array = [{"kind": "any"}, picked.pop_back(), caps.pop_at(rng.randi_range(0, caps.size() - 1))]
	var rest: Array = [{"kind": "any"}] + picked + caps
	for i in range(top.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = top[i]
		top[i] = top[j]
		top[j] = t
	for i in range(rest.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = rest[i]
		rest[i] = rest[j]
		rest[j] = t
	var out: Array[Dictionary] = []
	out.resize(board_slots)
	for i in board_slots:
		if i < GRID_COLS:
			out[i] = top[i]
		elif i == board_slots / 2:
			out[i] = {"kind": "any"}
		else:
			out[i] = rest.pop_back() if not rest.is_empty() else {"kind": "any"}
	return out

func _slot_rule(slot: int) -> Dictionary:
	if slot < 0 or slot >= slot_rules.size():
		return {"kind": "any"}
	return slot_rules[slot]

func _slot_accepts(slot: int, id: String) -> bool:
	var rule := _slot_rule(slot)
	match String(rule["kind"]):
		"sector":
			return _card_type(id) == String(rule["type"])
		"cap":
			var v := int(D.CARDS[id]["value"])
			return v >= int(rule["min"]) and v <= int(rule["max"])
	return true

func _rule_text(rule: Dictionary) -> String:
	match String(rule["kind"]):
		"sector":
			return "%s only" % D.TYPE_NAMES[rule["type"]]
		"cap":
			if int(rule["max"]) >= 99:
				return "Value %d+" % int(rule["min"])
			return "Value %d–%d" % [int(rule["min"]), int(rule["max"])]
	return "Any business"

func _free_slot_for(id: String) -> int:
	for i in board_slots:
		if _slot_open(i) and board[i] == null and _slot_accepts(i, id):
			return i
	return -1

func _replace_slot_for(id: String) -> int:
	for i in board_slots:
		if _slot_open(i) and board[i] != null and _slot_accepts(i, id):
			return i
	return -1

func _free_slot() -> int:
	for i in board_slots:
		if _slot_open(i) and board[i] == null:
			return i
	return -1

func _make_slot_locks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.resize(board_slots)
	for i in board_slots:
		out[i] = {}
	var spots: Array = []
	for i in range(GRID_COLS, board_slots):
		if i != board_slots / 2:
			spots.append(i)
	var types: Array = D.TYPES.duplicate()
	var kinds: Array = [
		{"kind": "pay", "res": String(types[rng.randi_range(0, types.size() - 1)]), "amount": D.LOCK_PAY},
		{"kind": "adjacent", "type": String(types[rng.randi_range(0, types.size() - 1)])},
		[{"kind": "count", "n": 5}, {"kind": "value", "min": 5}][rng.randi_range(0, 1)],
	]
	for k in mini(D.LOCKED_LOTS, kinds.size()):
		var slot: int = spots.pop_at(rng.randi_range(0, spots.size() - 1))
		out[slot] = kinds[k]
	return out

func _unlock_all() -> void:
	for i in slot_locks.size():
		slot_locks[i] = {}

func _slot_open(slot: int) -> bool:
	return slot >= 0 and slot < slot_locks.size() and slot_locks[slot].is_empty()

func _lock_text(lock: Dictionary) -> String:
	match String(lock["kind"]):
		"pay":
			return "Pay %d %s" % [int(lock["amount"]), D.RES_NAMES[lock["res"]]]
		"adjacent":
			return "Next to a %s business" % D.TYPE_NAMES[lock["type"]]
		"count":
			return "Own %d businesses" % int(lock["n"])
		"value":
			return "Own a business worth %d+" % int(lock["min"])
	return ""

func _lock_block(slot: int) -> String:
	if phase != Phase.ACTION or not choice.is_empty():
		return "Not now"
	var lock: Dictionary = slot_locks[slot]
	match String(lock["kind"]):
		"pay":
			if _r(String(lock["res"])) < int(lock["amount"]):
				return "Need %d %s" % [int(lock["amount"]), D.RES_NAMES[lock["res"]]]
		"adjacent":
			for s2 in _adjacent_slots(slot):
				if board[s2] != null and _card_type(board[s2].id) == String(lock["type"]):
					return ""
			return "Needs an adjacent %s business" % D.TYPE_NAMES[lock["type"]]
		"count":
			if _board_count() < int(lock["n"]):
				return "Own %d businesses (you own %d)" % [int(lock["n"]), _board_count()]
		"value":
			for b2 in board:
				if b2 != null and _effective_value(b2) >= int(lock["min"]):
					return ""
			return "Needs a business worth %d+" % int(lock["min"])
	return ""

func _unlock_slot(slot: int) -> void:
	var why := _lock_block(slot)
	if why != "":
		_say(why)
		return
	var lock: Dictionary = slot_locks[slot]
	if String(lock["kind"]) == "pay":
		res[lock["res"]] = _r(String(lock["res"])) - int(lock["amount"])
	slot_locks[slot] = {}
	_say("Lot opened")

func _dormant_count() -> int:
	var n := 0
	for inst in board:
		if inst != null and inst.dormant:
			n += 1
	return n

func _market_count() -> int:
	var n := 0
	for id in market:
		if id != "":
			n += 1
	return n

func _round_vp() -> int:
	return year_vp + act_vp

func _year_of(r: int) -> int:
	return (r - 1) / D.QUARTERS_PER_YEAR + 1

func _quarter_in_year(r: int) -> int:
	return (r - 1) % D.QUARTERS_PER_YEAR + 1

func _is_year_end(r: int) -> bool:
	return _quarter_in_year(r) == D.QUARTERS_PER_YEAR

func _total_years() -> int:
	return ceili(rounds_per_run / float(D.QUARTERS_PER_YEAR))

func _target_for(r: int) -> int:
	var y := _year_of(r)
	var t: int = D.YEAR_TARGETS[clampi(y - 1, 0, D.YEAR_TARGETS.size() - 1)]
	if y == _year_of(round_n):
		t += debt
	return t

func _intel_locked() -> bool:
	return bool(mods.get("intel_locked", false))

func _rule_cost(id: String) -> Dictionary:
	var c: Dictionary = D.CARDS[id]
	var t := String(c["type"])
	var v := clampi(int(c["value"]), 1, 7)
	var total := v + D.COST_EXTRA
	var main := ceili(total / 2.0)
	var out := {t: main}
	var rest := total - main
	if v >= D.GATE_VALUE and t != D.GATE_RES:
		out[D.GATE_RES] = 1
		rest -= 1
	var filler := String(D.COST_FILLER.get(t, D.DEFAULT_FILLER))
	if rest > 0:
		out[filler] = int(out.get(filler, 0)) + rest
	return out

func _market_edition(i: int) -> String:
	var id := market[i]
	if id == "":
		return ""
	var rec: Dictionary = market_eds.get(i, {})
	if String(rec.get("id", "")) != id:
		var ed := ""
		if rng.randf() < DEAL_EDITION_CHANCE:
			var total := 0
			for e: String in DEAL_EDITION_WEIGHTS:
				total += int(DEAL_EDITION_WEIGHTS[e])
			var pick := rng.randi_range(1, total)
			for e: String in DEAL_EDITION_WEIGHTS:
				pick -= int(DEAL_EDITION_WEIGHTS[e])
				if pick <= 0:
					ed = e
					break
		rec = {"id": id, "ed": ed}
		market_eds[i] = rec
	return String(rec["ed"])

func _market_cost(i: int) -> Dictionary:
	var cost := _cost(market[i]).duplicate()
	if _market_edition(i) != "":
		cost["cash"] = int(cost.get("cash", 0)) + 1
	return cost

func _cost(id: String) -> Dictionary:
	var c: Dictionary = D.CARDS[id]
	var out: Dictionary = (c["cost"] as Dictionary).duplicate() if c.has("cost") else _rule_cost(id)
	var cp: Dictionary = mods.get("cost_plus", {})
	for r: String in cp:
		out[r] = int(out.get(r, 0)) + int(cp[r])
	return out

func _say(msg: String) -> void:
	toast = msg
	toast_t = clock

func _float(at: Vector2, text: String, col: Color) -> void:
	var f := FloatText.new()
	f.anchor = at
	f.delay = maxf(0.0, float_next - clock)
	float_next = clock + f.delay + FLOAT_STEP
	var lane := 0
	for o in floaters:
		if o.anchor.distance_to(at) < 30.0 and o.life > 0.5:
			lane += 1
	f.pos = at + Vector2(0.0, 40.0 - (lane % 5) * 48.0)
	f.color = col
	f.text = text
	var parts := text.split(" ", false, 1)
	if parts.size() == 2 and (parts[0].begins_with("+") or parts[0].begins_with("-")) and parts[0].substr(1).is_valid_int():
		if parts[1] == "Brand":
			f.icon = "vp"
			f.text = parts[0]
		else:
			for r: String in D.TYPES:
				if D.RES_NAMES[r] == parts[1]:
					f.icon = r
					f.text = parts[0]
	floaters.append(f)

func _roll(n: int) -> void:
	dice.clear()
	for i in n:
		var d := Die.new()
		d.value = rng.randi_range(1, 6)
		d.shown = d.value
		d.roll_t = 0.35 + i * 0.08
		dice.append(d)
	_sfx("dice")
	if bool(mods.get("odd_minus", false)):
		for d in dice:
			if d.value % 2 == 1 and d.value > 1:
				d.value -= 1
	if mods.has("cap_highest"):
		var hi := 0
		for i in dice.size():
			if dice[i].value > dice[hi].value:
				hi = i
		var cap := int(mods["cap_highest"])
		if dice[hi].value > cap:
			round_notes.append("%s: a %d was capped to %d" % [_event_name(forecast[0]), dice[hi].value, cap])
			dice[hi].value = cap

func _die_free(i: int) -> bool:
	return i >= 0 and i < dice.size() and not dice[i].used and dice[i].card_uid == -1

func _block_reason(inst: CardInst, di: int) -> String:
	if phase != Phase.ACTION or not choice.is_empty():
		return "Finish the current choice first"
	if not _die_free(di):
		return "That die is already placed"
	var v := _die_for(inst, dice[di].value)
	if inst.dormant:
		return ""
	if inst.activated and not _can_repeat(inst, v):
		return "Already operated this quarter"
	var p := _effective_pattern(inst)
	var need := _dice_needed(p)
	if need == 0:
		return "This business can't be operated"
	var short := _convert_short(inst)
	if short != "":
		return short
	if need == 1:
		return "" if _fits1(p, v) else "Needs %s (%s)" % [_pattern_label(p), _pattern_rule(p)]
	if inst.pending.is_empty():
		for other in range(1, 7):
			if _fits2(p, v, other):
				return ""
		return "No second die could complete %s with a %d" % [_pattern_label(p), v]
	var first := _die_for(inst, dice[inst.pending[0]].value)
	return "" if _fits2(p, first, v) else "%d and %d don't make %s" % [first, v, _pattern_label(p)]

func _can_repeat(inst: CardInst, v: int) -> bool:
	if not _has_passive(inst, "repeat_same_die") or inst.ops != 1 or inst.used_values.is_empty():
		return false
	return _dice_needed(_effective_pattern(inst)) == 1 and _die_for(inst, inst.used_values[0]) == v

func _die_for(inst: CardInst, v: int) -> int:
	var t := _card_type(inst.id)
	for n in _neighbors(inst):
		if n.dormant:
			continue
		var p: Dictionary = D.CARDS[n.id].get("passive", {}).get("adjacent_die_plus", {})
		if not p.is_empty() and String(p["type"]) == t:
			v += int(p["amount"])
	return mini(v, 6)

func _has_passive(inst: CardInst, key: String) -> bool:
	return D.CARDS[inst.id].get("passive", {}).has(key)

func _adjacent_slots(slot: int) -> Array[int]:
	var out: Array[int] = []
	if slot < 0:
		return out
	var col := slot % GRID_COLS
	if col > 0:
		out.append(slot - 1)
	if col < GRID_COLS - 1 and slot + 1 < board_slots:
		out.append(slot + 1)
	if slot - GRID_COLS >= 0:
		out.append(slot - GRID_COLS)
	if slot + GRID_COLS < board_slots:
		out.append(slot + GRID_COLS)
	return out

func _neighbors(inst: CardInst) -> Array[CardInst]:
	var out: Array[CardInst] = []
	for s in _adjacent_slots(_slot_of(inst)):
		if board[s] != null:
			out.append(board[s])
	return out

func _left_of(inst: CardInst) -> CardInst:
	var slot := _slot_of(inst)
	if slot < 0 or slot % GRID_COLS == 0:
		return null
	return board[slot - 1]

func _effects_of(inst: CardInst) -> Array:
	var c: Dictionary = D.CARDS[inst.id]
	if bool(c.get("copy_left", false)):
		var left := _left_of(inst)
		if left == null or bool(D.CARDS[left.id].get("copy_left", false)):
			return []
		return D.CARDS[left.id]["effects"]
	return c["effects"]

func _convert_short(inst: CardInst) -> String:
	for e: Dictionary in _effects_of(inst):
		var kind := String(e["kind"])
		if kind == "convert" or kind == "pay":
			var pay: Dictionary = e["pay"] if kind == "convert" else e["res"]
			for r: String in pay:
				if _r(r) < int(pay[r]):
					return "Needs %d %s" % [int(pay[r]), D.RES_NAMES[r]]
	return ""

func _assign(di: int, inst: CardInst) -> void:
	var d := dice[di]
	var at := _board_rect(_slot_of(inst)).get_center()
	if inst.dormant:
		d.used = true
		inst.dormant = false
		inst.activated = true
		inst.used_values.append(d.value)
		activations += 1
		inst.flash = 1.0
		_float(at, "Turned around", c_good)
		_say("%s turned around" % _card_name(inst.id))
	elif _dice_needed(_effective_pattern(inst)) == 2 and inst.pending.is_empty():
		inst.pending.append(di)
		d.card_uid = inst.uid
	else:
		var vals: Array[int] = []
		for pi in inst.pending:
			dice[pi].used = true
			dice[pi].card_uid = -1
			inst.used_values.append(dice[pi].value)
			vals.append(_die_for(inst, dice[pi].value))
		inst.pending.clear()
		d.used = true
		inst.used_values.append(d.value)
		vals.append(_die_for(inst, d.value))
		_activate(inst, vals)
	selected_die = -1
	_next_choice()

func _return_pending(inst: CardInst) -> void:
	for pi in inst.pending:
		dice[pi].card_uid = -1
	inst.pending.clear()

func _activate(inst: CardInst, vals: Array[int]) -> void:
	inst.activated = true
	inst.ops += 1
	inst.flash = 1.0
	_operate(inst, {"dice": vals}, 0, true)
	_tut_event("operated")

func _operate(inst: CardInst, ctx: Dictionary, depth: int, chain: bool) -> void:
	activations += 1
	types_activated[_card_type(inst.id)] = true
	var half := int(mods.get("halve_output_uid", -1)) == inst.uid
	var worth := _effective_value(inst)
	if _slot_mod(_slot_of(inst)) == "gold":
		worth *= 2
	if inst.edition == "gold":
		worth *= 2
	if worth > 0:
		_add_vp(worth, _board_rect(_slot_of(inst)).get_center())
	for e: Dictionary in _effects_of(inst):
		_run_effect(e, inst, half, ctx, depth)
	if inst.edition == "holo" and _convert_short(inst) == "":
		for e: Dictionary in _effects_of(inst):
			_run_effect(e, inst, half, ctx, depth)
	if not chain or depth > 6:
		return
	for n in _neighbors(inst):
		if n.dormant:
			continue
		_fire(n, "neighbor_operate", {"source": inst.uid, "source_type": _card_type(inst.id)})
		if bool(D.CARDS[n.id].get("chain_left", false)) and _left_of(n) == inst:
			n.flash = 1.0
			_operate(n, {"dice": []}, depth + 1, true)

func _fire(inst: CardInst, hook: String, ctx: Dictionary = {}) -> void:
	var list: Array = D.CARDS[inst.id].get("triggers", {}).get(hook, [])
	if list.is_empty() or inst.dormant:
		return
	var half := int(mods.get("halve_output_uid", -1)) == inst.uid
	for e: Dictionary in list:
		if e.has("if_source_type") and String(e["if_source_type"]) != String(ctx.get("source_type", "")):
			continue
		_run_effect(e, inst, half, ctx, 0)

func _fire_all(hook: String, ctx: Dictionary = {}) -> void:
	for inst in board.duplicate():
		if inst != null and _slot_of(inst) >= 0:
			_fire(inst, hook, ctx)

func _distress(inst: CardInst, source: String) -> void:
	if inst == null or inst.dormant:
		return
	if inst.edition == "bluechip":
		round_notes.append("%s: %s is Blue Chip and shrugged it off" % [source, _card_name(inst.id)])
		return
	if not bool(mods.get("insured", false)):
		for guard in board:
			if guard != null and not guard.dormant and _has_passive(guard, "prevent_distress"):
				mods["insured"] = true
				var reward := int(D.CARDS[guard.id]["passive"]["prevent_distress"].get("vp", 0))
				if reward > 0:
					_add_vp(reward, _board_rect(_slot_of(guard)).get_center())
				round_notes.append("%s: %s protected %s" % [source, _card_name(guard.id), _card_name(inst.id)])
				_say("%s protected %s" % [_card_name(guard.id), _card_name(inst.id)])
				return
	inst.dormant = true
	round_notes.append("%s: %s is distressed" % [source, _card_name(inst.id)])

func _mature(inst: CardInst, min_value: int) -> void:
	var pool: Array[String] = []
	for id: String in D.CARDS:
		if int(D.CARDS[id]["value"]) >= min_value:
			pool.append(id)
	if pool.is_empty():
		return
	var old := _card_name(inst.id)
	inst.id = pool[rng.randi_range(0, pool.size() - 1)]
	inst.age = 0
	inst.bonus = 0
	inst.flash = 1.0
	round_notes.append("%s grew into %s" % [old, _card_name(inst.id)])

func _check(cond: Dictionary, inst: CardInst = null) -> bool:
	match String(cond["kind"]):
		"type_count_at_most":
			return _count_per({"per": "board_type", "type": cond["type"]}, null, {}) <= int(cond["amount"])
		"adjacent_type_at_most":
			return _count_per({"per": "adjacent_type", "type": cond["type"]}, inst, {}) <= int(cond["amount"])
		"ops_at_least":
			return inst != null and inst.ops >= int(cond["amount"])
	return true

func _halve(amt: int, half: bool) -> int:
	return floori(amt * 0.5) if half else amt

func _run_effect(e: Dictionary, inst: CardInst, half: bool, ctx: Dictionary = {}, depth: int = 0) -> void:
	var at := _board_rect(_slot_of(inst)).get_center()
	var kind := String(e["kind"])
	match kind:
		"gain":
			var g: Dictionary = e["res"]
			for r: String in g:
				var amt := _halve(int(g[r]), half)
				if amt > 0:
					res[r] = _r(r) + amt
					_float(at, "+%d %s" % [amt, D.RES_NAMES[r]], _tcol(r))
		"gain_per":
			var r := String(e["res"])
			var amt := _halve(_count_per(e, inst, ctx) * int(e.get("amount", 1)), half)
			if amt > 0:
				res[r] = _r(r) + amt
				_float(at, "+%d %s" % [amt, D.RES_NAMES[r]], _tcol(r))
		"gain_ctx":
			var r := String(e["res"])
			var amt := _halve(int(ctx.get(e["key"], 0)), half)
			if amt > 0:
				res[r] = _r(r) + amt
				_float(at, "+%d %s" % [amt, D.RES_NAMES[r]], _tcol(r))
		"vp":
			_add_vp(_halve(int(e["amount"]), half), at)
		"vp_per":
			_add_vp(_halve(_count_per(e, inst, ctx) * int(e["amount"]), half), at)
		"vp_if":
			_add_vp(_halve(int(e["amount"]) if _check(e["cond"], inst) else int(e.get("else", 0)), half), at)
		"pay":
			var pay: Dictionary = e["res"]
			for r: String in pay:
				res[r] = _r(r) - int(pay[r])
				spent[r] = int(spent.get(r, 0)) + int(pay[r])
				_float(at, "-%d %s" % [int(pay[r]), D.RES_NAMES[r]], _tcol(r))
		"grow":
			if not bool(e.get("if_operated", false)) or inst.activated:
				inst.bonus += int(e["amount"])
				inst.flash = 1.0
				round_notes.append("%s grew to value %d" % [_card_name(inst.id), _base_value(inst)])
		"distress_self":
			var dv: Array = ctx.get("dice", [])
			if dv.has(int(e["on_die"])):
				_distress(inst, _card_name(inst.id))
				_float(at, "Distressed", c_bad)
		"retrigger_adjacent":
			if depth < 6:
				for n in _neighbors(inst):
					if e.has("type") and _card_type(n.id) != String(e["type"]):
						continue
					if n.activated and not n.dormant:
						n.flash = 1.0
						var vals: Array[int] = []
						for v in n.used_values:
							vals.append(_die_for(n, v))
						_operate(n, {"dice": vals}, depth + 1, false)
		"mature":
			inst.age += 1
			if e.has("speed_per"):
				inst.age += _count_per({"per": e["speed_per"], "type": e.get("type", "")}, inst, ctx)
			if inst.age >= int(e["quarters"]):
				_mature(inst, int(e["min_value"]))
		"absorb":
			choice_queue.append({"kind": "absorb", "uid": inst.uid})
		"upgrade_adjacent":
			choice_queue.append({"kind": "upgrade", "uid": inst.uid, "amount": int(e.get("amount", 1))})
		"grow_adjacent":
			for n in _neighbors(inst):
				if e.has("tag") and not _has_tag(n.id, String(e["tag"])):
					continue
				if e.has("type") and _card_type(n.id) != String(e["type"]):
					continue
				n.bonus += int(e.get("amount", 1))
				n.flash = 1.0
				_float(_board_rect(_slot_of(n)).get_center(), "+%d value" % int(e.get("amount", 1)), c_good)
		"extra_die":
			extra_dice_next += int(e["amount"])
			_float(at, "+%d die next quarter" % int(e["amount"]), c_accent)
		"forecast_weaken":
			var s := int(e["slot"])
			if s < forecast.size():
				forecast[s]["weak"] = true
				_say("%s weakened" % _event_name(forecast[s]))
		"forecast_delay":
			var s := int(e["slot"])
			if s + 1 < forecast.size():
				var t: Dictionary = forecast[s]
				forecast[s] = forecast[s + 1]
				forecast[s + 1] = t
				_say("%s delayed a quarter" % _event_name(t))
		"forecast_cancel":
			var s := int(e["slot"])
			if s < forecast.size():
				_say("%s cancelled" % _event_name(forecast[s]))
				forecast[s] = {"id": "steady_market", "weak": false, "revealed": true}
		"forecast_reveal":
			for ev in forecast:
				ev["revealed"] = true
		"refresh_market":
			_refresh_market()
		"gain_random_card":
			var id := _deal_card() if not e.has("type") else _deal_of_type(String(e["type"]))
			if id == "":
				_say("No deals left in the deck")
			else:
				var slot := _free_slot_for(id)
				if slot >= 0:
					board[slot] = _make_inst(id)
					board[slot].flash = 1.0
					board[slot].place_t = 0.0
					board[slot].place_from = _pile_rect(0).position
					_placement_brand(board[slot])
					_say("Acquired %s" % _card_name(id))
				else:
					discard.append(id)
					_say("Acquired %s, but no empty lot fits it (lost)" % _card_name(id))
		"convert":
			var pay: Dictionary = e["pay"]
			for r: String in pay:
				res[r] = _r(r) - int(pay[r])
				spent[r] = int(spent.get(r, 0)) + int(pay[r])
				_float(at, "-%d %s" % [int(pay[r]), D.RES_NAMES[r]], _tcol(r))
			_add_vp(_halve(int(e["vp"]), half), at)
		"replace_market", "peek_swap", "refresh_type", "restore_dormant":
			choice_queue.append(e.duplicate())
		_:
			push_warning("Unknown effect %s" % kind)

func _has_tag(id: String, tag: String) -> bool:
	return (D.CARDS[id].get("tags", []) as Array).has(tag)

func _deal_of_type(t: String) -> String:
	for i in range(deck.size() - 1, -1, -1):
		if _card_type(deck[i]) == t:
			var id := deck[i]
			deck.remove_at(i)
			return id
	for i in range(discard.size() - 1, -1, -1):
		if _card_type(discard[i]) == t:
			var id := discard[i]
			discard.remove_at(i)
			return id
	return ""

func _placement_brand(inst: CardInst) -> void:
	var worth := _effective_value(inst)
	if worth > 0:
		_add_vp(worth, _board_rect(_slot_of(inst)).get_center())

func _add_vp(amt: int, at: Vector2) -> void:
	act_vp += amt
	_float(at, "+%d Brand" % amt, c_gold.darkened(0.25))

func _count_per(e: Dictionary, inst: CardInst, ctx: Dictionary) -> int:
	var n := 0
	match String(e["per"]):
		"board_type":
			for b in board:
				if b != null and _card_type(b.id) == String(e["type"]):
					n += 2 if b.edition == "franchise" else 1
		"activations":
			n = activations
		"distinct_types":
			n = types_activated.size()
		"market_cards":
			n = _market_count()
		"empty_slots":
			for i in board_slots:
				if _slot_open(i) and board[i] == null:
					n += 1
		"adjacent":
			n = _neighbors(inst).size()
		"adjacent_other_type":
			for b in _neighbors(inst):
				if _card_type(b.id) != _card_type(inst.id):
					n += 1
		"adjacent_type_operated":
			for b in _neighbors(inst):
				if b.activated and _card_type(b.id) == String(e["type"]):
					n += 1
		"operated":
			for b in board:
				if b != null and b.activated:
					n += 1
		"type_operated":
			for b in board:
				if b != null and b.activated and _card_type(b.id) == String(e["type"]):
					n += 1
		"spent":
			n = int(spent.get(String(e["res"]), 0))
		"adjacent_type":
			for b in _neighbors(inst):
				if _card_type(b.id) == String(e["type"]):
					n += 1
		"row_type":
			var slot := _slot_of(inst)
			var row := slot - slot % GRID_COLS
			for i in GRID_COLS:
				var b: CardInst = board[row + i] if row + i < board.size() else null
				if b != null and b != inst and _card_type(b.id) == String(e["type"]):
					n += 1
		"adjacent_empty":
			for s in _adjacent_slots(_slot_of(inst)):
				if _slot_open(s) and board[s] == null:
					n += 1
		"adjacent_operated":
			for b in _neighbors(inst):
				if b.activated:
					n += 1
		"die_value":
			for v in ctx.get("dice", []):
				n += int(v)
		"copies":
			for b in board:
				if b != null and b != inst and b.id == inst.id:
					n += 1
		"resource":
			n = floori(_r(String(e["res"])) / float(e.get("div", 1)))
		"goals_met":
			n = goals_met
		"distinct_dice":
			var seen := {}
			for b in board:
				if b != null:
					for v in b.used_values:
						seen[v] = true
			n = seen.size()
		"unused_dice":
			for i in dice.size():
				if _die_free(i):
					n += 1
	return mini(n, int(e.get("max", 99)))

func _next_choice() -> void:
	while choice.is_empty() and not choice_queue.is_empty():
		var e: Dictionary = choice_queue.pop_front()
		var kind := String(e["kind"])
		if kind == "restore_dormant":
			if _dormant_count() == 0:
				_say("No distressed business to turn around")
			else:
				choice = {"kind": kind, "prompt": "Choose a distressed business to turn around"}
		elif kind == "replace_market":
			if _market_count() > 0:
				choice = {"kind": kind, "prompt": "Choose a deal to replace"}
		elif kind == "peek_swap":
			var cards: Array[String] = []
			for i in int(e.get("count", 3)):
				var id := _deal_card()
				if id != "":
					cards.append(id)
			if cards.is_empty():
				_say("No deals left in the deck")
			else:
				choice = {"kind": kind, "cards": cards, "picked": -1, "prompt": "Pick a deal to swap into the Market"}
		elif kind == "refresh_type":
			choice = {"kind": kind, "prompt": "Choose a sector to rescout"}
		elif kind == "upgrade":
			var up_inst := _inst_by_uid(int(e["uid"]))
			if up_inst == null or _neighbors(up_inst).is_empty():
				_say("Nothing adjacent to upgrade")
			else:
				choice = {"kind": kind, "uid": up_inst.uid, "amount": int(e["amount"]), "prompt": "Choose an adjacent business to upgrade"}
		elif kind == "absorb":
			var src_inst := _inst_by_uid(int(e["uid"]))
			if src_inst == null or _neighbors(src_inst).is_empty():
				_say("Nothing adjacent to absorb")
			else:
				choice = {"kind": kind, "uid": src_inst.uid, "prompt": "Choose an adjacent business to absorb"}

func _finish_choice() -> void:
	choice = {}
	_next_choice()

func _skip_choice() -> void:
	if choice.is_empty():
		return
	if String(choice["kind"]) == "peek_swap":
		_return_peek(-1)
	_finish_choice()

func _pick_peek(j: int) -> void:
	choice["picked"] = j
	choice["prompt"] = "Now click a deal slot to swap it into"

func _return_peek(keep: int) -> void:
	var cards: Array[String] = choice["cards"]
	for i in range(cards.size() - 1, -1, -1):
		if i != keep:
			deck.append(cards[i])

func _buy_block(i: int) -> String:
	if phase != Phase.ACTION:
		return "Not now"
	if bool(mods.get("market_frozen", false)):
		return "Deals are frozen this quarter"
	var id := market[i]
	if id == "":
		return "Empty slot"
	var cost := _market_cost(i)
	if cost.has("intel") and _intel_locked():
		return "Intelligence can't be spent this quarter"
	var short: Array[String] = []
	for r: String in cost:
		if _r(r) < int(cost[r]):
			short.append("%d %s" % [int(cost[r]) - _r(r), D.RES_NAMES[r]])
	if not short.is_empty():
		return "Need " + ", ".join(short) + " more"
	if _free_slot_for(id) < 0 and _replace_slot_for(id) < 0:
		return "No open lot accepts it"
	return ""

func _on_market(i: int) -> void:
	var kind := String(choice.get("kind", ""))
	if kind == "replace_market":
		if market[i] == "":
			return
		var old := market[i]
		discard.append(old)
		market[i] = _deal_card()
		_say("Replaced %s" % _card_name(old))
		_finish_choice()
		return
	if kind == "peek_swap":
		var picked := int(choice["picked"])
		if picked < 0:
			_say("Pick one of the revealed deals first")
			return
		var cards: Array[String] = choice["cards"]
		if market[i] != "":
			discard.append(market[i])
		market[i] = cards[picked]
		_say("Swapped %s into the Market" % _card_name(cards[picked]))
		_return_peek(picked)
		_finish_choice()
		return
	if not choice.is_empty() or market[i] == "":
		return
	market_pick = -1 if market_pick == i else i
	board_pick = -1
	if market_pick == i:
		_tut_event("market_pick")

func _buy_pick() -> void:
	var i := market_pick
	market_pick = -1
	if i < 0 or not choice.is_empty():
		return
	var why := _buy_block(i)
	if why != "":
		_say(why)
		return
	if _free_slot_for(market[i]) < 0:
		choice = {"kind": "discard_for", "market": i, "prompt": "No empty lot fits %s: choose a business to sell and replace" % _card_name(market[i])}
		_tut_event("buy")
		return
	choice = {"kind": "place", "market": i, "prompt": "Choose an open lot for %s" % _card_name(market[i])}
	_tut_event("buy")

func _complete_buy(i: int, slot: int) -> void:
	var id := market[i]
	var cost := _market_cost(i)
	for r: String in cost:
		res[r] = _r(r) - int(cost[r])
	var inst := _make_inst(id)
	inst.edition = _market_edition(i)
	inst.flash = 1.0
	inst.place_t = 0.0
	inst.place_from = _market_rect(i).position
	board[slot] = inst
	_placement_brand(inst)
	market[i] = _deal_card()
	_say("Acquired %s" % _card_name(id))
	_fire(inst, "buy")
	_tut_event("placed")
	_next_choice()

func _remove_from_board(slot: int) -> void:
	var inst := board[slot]
	if inst == null:
		return
	_return_pending(inst)
	if not D.STARTING_BOARD.has(inst.id):
		discard.append(inst.id)
	board[slot] = null
	_say("Sold off %s" % _card_name(inst.id))
	_fire_all("sell", {"value": _base_value(inst)})

func _sell_price(inst: CardInst) -> int:
	return ceili((_base_value(inst) + D.COST_EXTRA) * 0.5)

func _sell(slot: int) -> void:
	var inst := board[slot]
	if inst == null:
		return
	var price := _sell_price(inst)
	res["cash"] = _r("cash") + price
	_float(_board_rect(slot).get_center(), "+%d Cash" % price, _tcol("cash"))
	_remove_from_board(slot)

func _sell_pick() -> void:
	var slot := board_pick
	board_pick = -1
	if slot < 0 or board[slot] == null or not choice.is_empty() or phase != Phase.ACTION:
		return
	_sell(slot)

func _on_board(slot: int) -> void:
	market_pick = -1
	var picked := board_pick
	board_pick = -1
	var inst := board[slot]
	var kind := String(choice.get("kind", ""))
	if kind == "discard_for":
		if inst == null or not _slot_accepts(slot, market[int(choice["market"])]):
			return
		var mi := int(choice["market"])
		choice = {}
		_sell(slot)
		_complete_buy(mi, slot)
		_next_choice()
		return
	if kind == "place":
		if inst == null and _slot_open(slot) and _slot_accepts(slot, market[int(choice["market"])]):
			var pi := int(choice["market"])
			choice = {}
			if _buy_block(pi) == "":
				_complete_buy(pi, slot)
			_next_choice()
		return
	if kind == "restore_dormant":
		if inst != null and inst.dormant:
			inst.dormant = false
			inst.flash = 1.0
			_say("%s turned around" % _card_name(inst.id))
			_finish_choice()
		return
	if kind == "absorb":
		var src_inst := _inst_by_uid(int(choice["uid"]))
		if inst != null and src_inst != null and _neighbors(src_inst).has(inst):
			src_inst.bonus += _base_value(inst)
			src_inst.flash = 1.0
			_return_pending(inst)
			discard.append(inst.id)
			board[slot] = null
			_say("%s absorbed %s" % [_card_name(src_inst.id), _card_name(inst.id)])
			_fire_all("sell", {"value": _base_value(inst)})
			_finish_choice()
		return
	if kind == "free_unlock":
		if not _slot_open(slot):
			slot_locks[slot] = {}
			_say("Lot opened")
			_finish_choice()
		return
	if kind == "edition":
		if inst != null and inst.edition == "":
			inst.edition = String(choice["edition"])
			inst.flash = 1.0
			_say("%s is now %s" % [_card_name(inst.id), D.EDITIONS[inst.edition]["name"]])
			_finish_choice()
		return
	if kind == "meeting_upgrade":
		if inst != null:
			inst.bonus += int(choice["amount"])
			inst.flash = 1.0
			_say("%s grew to value %d" % [_card_name(inst.id), _base_value(inst)])
			_finish_choice()
		return
	if kind == "pocket":
		var mod := String(choice["mod"])
		if _pocket_target_ok(slot, mod):
			if mod == "open":
				slot_rules[slot] = {"kind": "any"}
				_say("Lot %d now accepts any business" % (slot + 1))
			else:
				slot_mods[slot] = mod
				_say("%s pocket installed" % D.POCKET_MODS[mod]["name"])
			_finish_choice()
		return
	if kind == "upgrade":
		var up_inst := _inst_by_uid(int(choice["uid"]))
		if inst != null and up_inst != null and _neighbors(up_inst).has(inst):
			inst.bonus += int(choice["amount"])
			inst.flash = 1.0
			_say("%s upgraded to value %d" % [_card_name(inst.id), _base_value(inst)])
			_finish_choice()
		return
	if not choice.is_empty() or inst == null or phase != Phase.ACTION:
		return
	if selected_die >= 0:
		var why := _block_reason(inst, selected_die)
		if why == "":
			_assign(selected_die, inst)
		else:
			_say(why)
			inst.shake = 1.0
	elif not inst.pending.is_empty():
		_return_pending(inst)
	elif picked != slot:
		board_pick = slot

func _on_die(i: int) -> void:
	market_pick = -1
	board_pick = -1
	if phase != Phase.ACTION or not _die_free(i):
		return
	selected_die = -1 if selected_die == i else i

const SCOUT_FACE := 6

func _refresh_price() -> int:
	return int(mods.get("refresh_plus", 0))

func _face_die(face: int) -> int:
	if _die_free(selected_die) and dice[selected_die].value == face:
		return selected_die
	for i in dice.size():
		if _die_free(i) and dice[i].value == face:
			return i
	return -1

func _refresh_block() -> String:
	if phase != Phase.ACTION:
		return "Not now"
	if bool(mods.get("market_frozen", false)) or bool(mods.get("refresh_frozen", false)):
		return "Deals can't be scouted this quarter"
	if _face_die(SCOUT_FACE) < 0:
		return "Needs a die showing %d" % SCOUT_FACE
	if _r("cash") < _refresh_price():
		return "Also needs %d Cash this quarter" % _refresh_price()
	return ""

func _cash_refresh() -> void:
	var why := _refresh_block()
	if why != "" or not choice.is_empty():
		_say(why)
		return
	var di := _face_die(SCOUT_FACE)
	dice[di].used = true
	selected_die = -1
	res["cash"] = _r("cash") - _refresh_price()
	_refresh_market()
	_say("New deals scouted")
	_tut_event("scout")

func _res_face(r: String) -> int:
	return D.TYPES.find(r) + 1

func _res_die_block(r: String) -> String:
	if phase != Phase.ACTION or not choice.is_empty():
		return "Not now"
	if _face_die(_res_face(r)) < 0:
		return "Needs a die showing %d" % _res_face(r)
	return ""

func _res_die(r: String) -> void:
	var why := _res_die_block(r)
	if why != "":
		_say(why)
		return
	var di := _face_die(_res_face(r))
	dice[di].used = true
	selected_die = -1
	res[r] = _r(r) + 1
	_float(_die_home(di), "+1 %s" % D.RES_NAMES[r], _tcol(r))
	_tut_event("resource")

func _refresh_market() -> void:
	for i in market.size():
		if market[i] != "":
			discard.append(market[i])
			market[i] = ""
	for i in market.size():
		market[i] = _deal_card()

func _refresh_type(t: String) -> void:
	var n := 0
	for i in market.size():
		if market[i] != "" and _card_type(market[i]) == t:
			discard.append(market[i])
			market[i] = _deal_card()
			n += 1
	_say("Rescouted %d %s deal%s" % [n, D.TYPE_NAMES[t], "" if n == 1 else "s"])
	_finish_choice()

func _rate() -> int:
	return int(mods.get("exchange_rate", exchange_rate))

func _start_exchange() -> void:
	if not choice.is_empty() or phase != Phase.ACTION:
		return
	choice = {"kind": "exchange", "give": "", "prompt": "Exchange: choose a resource to give (%d)" % _rate()}

func _on_chip(r: String) -> void:
	if String(choice.get("kind", "")) != "exchange":
		return
	var give := String(choice["give"])
	if give == "":
		if r == "intel" and _intel_locked():
			_say("Intelligence can't be spent this quarter")
		elif _r(r) < _rate():
			_say("Need %d %s to exchange" % [_rate(), D.RES_NAMES[r]])
		else:
			choice["give"] = r
			choice["prompt"] = "Give %d %s for 1 of: (choose)" % [_rate(), D.RES_NAMES[r]]
	elif r != give:
		res[give] = _r(give) - _rate()
		res[r] = _r(r) + 1
		_say("Exchanged %d %s for 1 %s" % [_rate(), D.RES_NAMES[give], D.RES_NAMES[r]])
		_finish_choice()

func _intel_block(price: int) -> String:
	if phase != Phase.ACTION or not choice.is_empty():
		return "Not now"
	if _intel_locked():
		return "Intelligence can't be spent this quarter"
	if _r("intel") < price:
		return "Need %d Intelligence" % price
	return ""

func _reroll_block() -> String:
	var any := false
	for i in dice.size():
		if _die_free(i):
			any = true
	if not any:
		return "No unused dice"
	return _intel_block(reroll_cost)

func _reroll_all() -> void:
	var why := _reroll_block()
	if why != "":
		_say(why)
		return
	res["intel"] = _r("intel") - reroll_cost
	for i in dice.size():
		if _die_free(i):
			dice[i].value = rng.randi_range(1, 6)
			dice[i].roll_t = 0.35 + i * 0.05
	_sfx("dice")
	selected_die = -1

func _condition_met(cond: Dictionary) -> bool:
	match String(cond["kind"]):
		"type_activated":
			return types_activated.has(cond["type"])
		"activations_at_least":
			return activations >= int(cond["amount"])
	return true

func _condition_text(cond: Dictionary) -> String:
	match String(cond["kind"]):
		"type_activated":
			return "Operate a %s business" % D.TYPE_NAMES[cond["type"]]
		"activations_at_least":
			return "Operate %d businesses (%d so far)" % [int(cond["amount"]), activations]
	return ""

func _end_round() -> void:
	if phase != Phase.ACTION or not choice.is_empty():
		return
	board_pick = -1
	for inst in board:
		if inst != null:
			_return_pending(inst)
	var sold := 0
	for i in dice.size():
		if _die_free(i):
			dice[i].used = true
			sold += 1
	if sold > 0:
		res["cash"] = _r("cash") + sold * trade_die_cash
		round_notes.append("Sold %d unused %s for %d Cash" % [sold, "die" if sold == 1 else "dice", sold * trade_die_cash])
	_fire_all("quarter_end")
	year_vp += act_vp
	var quarter_vp := act_vp
	act_vp = 0
	var target := _target_for(round_n)
	var year_end := _is_year_end(round_n)
	var hit := year_vp >= target
	var rep := {"round": round_n, "vp": quarter_vp, "year_vp": year_vp, "target": target, "year": _year_of(round_n),
		"year_end": year_end, "hit": hit, "activations": activations, "event": _event_name(forecast[0])}
	if year_end:
		if hit:
			rep["surplus"] = year_vp - target
			debt = 0
		elif miss_rule == MissRule.STRIKES:
			strikes += 1
			rep["strike"] = strikes
		else:
			debt = target - year_vp
			rep["debt"] = debt
		years.append({"year": _year_of(round_n), "vp": year_vp, "target": target, "hit": hit})
		year_vp = 0
	var cond := _event_condition(forecast[0])
	if not cond.is_empty():
		var ok := _condition_met(cond)
		rep["cond"] = {"name": _event_name(forecast[0]), "ok": ok, "text": _event_text(forecast[0])}
		if not ok:
			queued_penalties.append_array(D.EVENTS[forecast[0]["id"]].get("penalty", []))
		else:
			goals_met += 1
	var lost := {}
	for r: String in D.TYPES:
		if storage_cap > 0 and _r(r) > storage_cap:
			lost[r] = _r(r) - storage_cap
			res[r] = storage_cap
	rep["lost"] = lost
	_fire_all("after_quarter")
	rep["notes"] = round_notes.duplicate()
	forecast.pop_front()
	forecast.append(_new_event(round_n + forecast_length))
	history.append(rep)
	var out := (miss_rule == MissRule.STRIKES and strikes >= strikes_to_lose) or (miss_rule == MissRule.DEBT and year_end and not hit and round_n >= rounds_per_run)
	if out:
		game_result = "lost"
	elif round_n >= rounds_per_run:
		game_result = "won"
	if game_result == "":
		var n := 3
		if year_end:
			n = 2
			if hit:
				n = 4 if year_vp_at_check(rep) >= int(round(target * 1.25)) else 3
		pending_meeting = {"year": _year_of(round_n), "quarter": _quarter_in_year(round_n), "year_end": year_end, "count": n, "hit": hit, "surplus": int(rep.get("surplus", 0))}
		rep["meeting"] = n
	report = rep
	selected_die = -1
	phase = Phase.REPORT
	_tut_event("end_quarter")

func year_vp_at_check(rep: Dictionary) -> int:
	return int(rep["year_vp"])

func _slot_mod(slot: int) -> String:
	if slot < 0 or slot >= slot_mods.size():
		return ""
	return slot_mods[slot]

func _has_rare_in_deck() -> bool:
	for id in deck:
		if String(D.CARDS[id].get("rarity", "")) == "rare":
			return true
	return false

func _make_offers(n: int) -> Array[String]:
	var pool: Array[String] = ["capital"]
	var plain := false
	for b in board:
		if b != null and b.edition == "":
			plain = true
	if plain:
		var eds: Array = D.EDITION_OFFERS.keys()
		pool.append(String(eds[rng.randi_range(0, eds.size() - 1)]))
	for mod in ["gold", "express"]:
		for i in board_slots:
			if _pocket_target_ok(i, mod):
				pool.append(mod)
				break
	for i in board_slots:
		if not _slot_open(i):
			pool.append("free_lot")
			break
	if _board_count() > 0:
		pool.append("upgrade")
	if strikes > 0:
		pool.append("clear_strike")
	if base_dice < 6 and _year_of(round_n) >= 3:
		pool.append("extra_die")
	if _has_rare_in_deck():
		pool.append("rare_deal")
	for r in slot_rules:
		if String(r["kind"]) != "any":
			pool.append("open")
			break
	var out: Array[String] = []
	while out.size() < n and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return out

func _take_offer(id: String) -> void:
	meeting.clear()
	_tut_event("meeting")
	var o: Dictionary = _offer_data(id)
	match id:
		"ed_gold", "ed_holo", "ed_bluechip", "ed_franchise":
			choice = {"kind": "edition", "edition": String(o["edition"]), "prompt": "%s: choose a business" % o["name"]}
		"free_lot":
			choice = {"kind": "free_unlock", "prompt": "Expansion Capital: choose a locked lot to open"}
		"upgrade":
			choice = {"kind": "meeting_upgrade", "amount": 2, "prompt": "Growth Investment: choose a business to gain +2 value"}
		"clear_strike":
			strikes = maxi(0, strikes - 1)
		"capital":
			for r: String in D.TYPES:
				res[r] = _r(r) + 2
		"extra_die":
			base_dice += 1
			max_dice = maxi(max_dice, base_dice + 1)
		"rare_deal":
			for i in range(deck.size() - 1, -1, -1):
				if String(D.CARDS[deck[i]].get("rarity", "")) == "rare":
					if market[0] != "":
						discard.append(market[0])
					market[0] = deck[i]
					deck.remove_at(i)
					break
		"gold", "express":
			choice = {"kind": "pocket", "mod": id, "prompt": "%s: choose a lot to upgrade" % o["name"]}
		"open":
			choice = {"kind": "pocket", "mod": "open", "prompt": "Open Charter: choose a restricted lot"}
	_say("Investor meeting: %s" % o["name"])

func _offer_data(id: String) -> Dictionary:
	if D.EDITION_OFFERS.has(id):
		return D.EDITION_OFFERS[id]
	return D.MEETING_OFFERS[id]

func _pocket_target_ok(slot: int, mod: String) -> bool:
	if mod == "open":
		return String(_slot_rule(slot)["kind"]) != "any"
	return _slot_mod(slot) != mod

func _draw_meeting() -> void:
	var n := meeting.size()
	var cw := 300.0
	var gap := 28.0
	var r := _modal(maxf(980.0, n * cw + (n - 1) * gap + 128.0), 690.0)
	_panel_corners(Rect2(r.position, Vector2(r.size.x, 18.0)), c_gold, 28, 28, 0, 0)
	var x := r.position.x + 64.0
	var ye := bool(meeting_info.get("year_end", false))
	var when := "END OF YEAR %d" % int(meeting_info.get("year", 1)) if ye else "YEAR %d  ·  END OF Q%d" % [int(meeting_info.get("year", 1)), int(meeting_info.get("quarter", 1))]
	_text(Vector2(x, r.position.y + 84.0), when, T_SM, c_muted, true)
	_heavy(Vector2(x, r.position.y + 150.0), "Investor Meeting", T_HERO, c_ink)
	var sub := "Choose 1 of %d." % n
	if ye and not bool(meeting_info.get("hit", false)):
		sub = "Year target missed: the investors offer only 2 options."
	elif ye:
		sub = "Year target met with %d surplus: choose 1 of %d." % [int(meeting_info.get("surplus", 0)), n]
	_text(Vector2(x, r.position.y + 196.0), sub, T_MD, c_muted, true)
	var x0 := r.get_center().x - (n * cw + (n - 1) * gap) * 0.5
	for i in n:
		var id := meeting[i]
		var o: Dictionary = _offer_data(id)
		var cr := Rect2(x0 + i * (cw + gap), r.position.y + 240.0, cw, 380.0)
		var hov := cr.has_point(mouse)
		_shadow(cr, 20, 6.0)
		_panel(cr, Color("fbf6e9") if hov else Color("f6f1e3"), 20, c_gold if hov else Color(c_gold, 0.5), 3)
		var ic := Vector2(cr.get_center().x, cr.position.y + 72.0)
		draw_circle(ic, 40.0, Color.WHITE)
		draw_arc(ic, 40.0, 0.0, TAU, 32, Color(c_gold, 0.6), 2.0, true)
		_icon(String(o["icon"]), ic, 22.0)
		_text_center(Rect2(cr.position.x, cr.position.y + 130.0, cw, 40.0), String(o["name"]), T_LG, c_ink, true)
		_wrap(Vector2(cr.position.x + 24.0, cr.position.y + 176.0), String(o["text"]), cw - 48.0, T_SM, c_body, true, 4)
		_button(Rect2(cr.position.x + 40.0, cr.end.y - 76.0, cw - 80.0, 56.0), "Choose", _take_offer.bind(id), true, c_accent, T_MD)

func _sheet_name() -> String:
	return String(D.SHEETS.get(sheet_id, {}).get("name", "Random Sheet"))

func _start_sheet(id: String) -> void:
	tut_on = false
	sheet_id = id
	_new_run(randi_range(1, 999999))

func _close_intro() -> void:
	event_intro = false
	_tut_event("intro_closed")

func _start_tutorial() -> void:
	sheet_id = D.TUTORIAL_SHEET
	_new_run(D.TUTORIAL_SEED)
	var lot := D.TUTORIAL_LOT
	slot_rules[lot] = {"kind": "any"}
	slot_locks[lot] = {}
	slot_mods[lot] = ""
	for i in mini(market.size(), D.TUTORIAL_MARKET.size()):
		market[i] = D.TUTORIAL_MARKET[i]
		market_eds[i] = {"id": market[i], "ed": ""}
	forecast[0] = {"id": D.TUTORIAL_EVENT, "weak": false, "revealed": true}
	_start_round()
	for i in mini(dice.size(), D.TUTORIAL_DICE.size()):
		dice[i].value = D.TUTORIAL_DICE[i]
	tut_on = true
	tut_step = 0

func _tut() -> Dictionary:
	if not tut_on or tut_step >= D.TUTORIAL.size():
		return {}
	return D.TUTORIAL[tut_step]

func _tut_event(ev: String) -> void:
	var st := _tut()
	if not st.is_empty() and String(st["wait"]) == ev:
		_tut_advance()

func _tut_advance() -> void:
	tut_step += 1
	if tut_step >= D.TUTORIAL.size():
		tut_on = false

func _tut_end() -> void:
	tut_on = false

func _tut_free() -> bool:
	var t: Array = _tut().get("targets", [])
	return t.has("*") or t.has("modal")

func _tut_allows(p: Vector2, left: bool) -> bool:
	if tut_panel.has_point(p):
		return left
	if _tut_free():
		return true
	if not left:
		return false
	for t: String in _tut().get("targets", []):
		if _tut_rect(t).has_point(p):
			return true
	return false

func _tut_key_ok(key: Key) -> bool:
	if key == KEY_F1 or key == KEY_M:
		return true
	if key == KEY_ESCAPE:
		_tut_end()
		return false
	return _tut_free()

func _tut_rect(t: String) -> Rect2:
	var parts := t.split(":")
	var arg := parts[1] if parts.size() > 1 else ""
	match parts[0]:
		"market":
			return _market_rect(int(arg)) if int(arg) < market.size() else Rect2()
		"board":
			return _board_rect(int(arg)) if int(arg) < board_slots else Rect2()
		"die":
			if int(arg) >= dice.size() or not _die_free(int(arg)):
				return Rect2()
			return Rect2(_die_home(int(arg)) - Vector2(DIE_SIZE, DIE_SIZE) * 0.5, Vector2(DIE_SIZE, DIE_SIZE)).grow(6.0)
		"res":
			var i := D.TYPES.find(arg)
			if i < 0:
				return Rect2()
			var col := _res_col_rect(i)
			return Rect2(Vector2(col.get_center().x, col.position.y + 40.0) - Vector2(32, 32), Vector2(64, 64))
		"scout":
			return _pile_rect(1)
		"deck":
			return _pile_rect(0)
		"end":
			return s_end
		"assets":
			return s_mat
		"market_panel":
			return p_market
		"portfolio":
			return p_portfolio
		"calendar":
			return Rect2(h_left.position.x, HEADER_Y + 4.0, 176.0, HEADER_H - 8.0)
		"help":
			return Rect2(h_center.end.x - 104.0, HEADER_Y + 14.0, 100.0, 100.0)
	return tut_rects.get(t, Rect2())

func _tut_text(s: String) -> String:
	var vals := {
		"years": str(_total_years()), "quarters": str(rounds_per_run), "target": str(_target_for(round_n)),
		"strikes": str(strikes_to_lose), "dice": str(base_dice), "cap": str(storage_cap),
		"rate": str(_rate()), "reroll": str(reroll_cost), "scout": str(SCOUT_FACE),
	}
	for k: String in vals:
		s = s.replace("{%s}" % k, vals[k])
	var rx := RegEx.create_from_string("\\{(card|cost|value):([a-z0-9_]+)\\}")
	for m in rx.search_all(s):
		var id := m.get_string(2)
		var rep := id
		if D.CARDS.has(id):
			match m.get_string(1):
				"card":
					rep = _card_name(id)
				"value":
					rep = str(int(D.CARDS[id]["value"]))
				"cost":
					var parts: Array[String] = []
					var cost := _cost(id)
					for r: String in D.TYPES:
						if cost.has(r):
							parts.append("%d %s" % [int(cost[r]), D.RES_NAMES[r]])
					rep = " and ".join(parts)
		s = s.replace(m.get_string(), rep)
	return s

func _tutorial_problems() -> Array[String]:
	var out: Array[String] = []
	var known := ["market", "board", "die", "res", "scout", "deck", "end", "assets", "market_panel", "portfolio", "calendar", "help", "clipping", "scorepad", "exchange", "reroll", "buy", "modal", "*"]
	if not D.SHEETS.has(D.TUTORIAL_SHEET):
		out.append("unknown sheet %s" % D.TUTORIAL_SHEET)
	if not D.EVENTS.has(D.TUTORIAL_EVENT):
		out.append("unknown event %s" % D.TUTORIAL_EVENT)
	for id in D.TUTORIAL_MARKET:
		if not D.CARDS.has(id):
			out.append("unknown market card %s" % id)
	var rx := RegEx.create_from_string("\\{(card|cost|value):([a-z0-9_]+)\\}")
	for i in D.TUTORIAL.size():
		var st: Dictionary = D.TUTORIAL[i]
		for t: String in st["targets"]:
			var head := t.split(":")[0]
			if not known.has(head):
				out.append("step %d has unknown target %s" % [i + 1, t])
			elif head == "res" and not D.TYPES.has(t.split(":")[1] if t.contains(":") else ""):
				out.append("step %d has unknown resource %s" % [i + 1, t])
		for m in rx.search_all(String(st["title"]) + " " + String(st["body"])):
			if not D.CARDS.has(m.get_string(2)):
				out.append("step %d mentions unknown card %s" % [i + 1, m.get_string(2)])
	return out

func _dim_except(holes: Array[Rect2], col: Color) -> void:
	var ys: Array[float] = [0.0, UI_H]
	for h in holes:
		ys.append(clampf(h.position.y, 0.0, UI_H))
		ys.append(clampf(h.end.y, 0.0, UI_H))
	ys.sort()
	for i in ys.size() - 1:
		var y0 := ys[i]
		var y1 := ys[i + 1]
		if y1 - y0 < 0.5:
			continue
		var spans: Array = []
		for h in holes:
			if h.position.y <= y0 and h.end.y >= y1:
				spans.append([h.position.x, h.end.x])
		spans.sort_custom(func(a, b): return a[0] < b[0])
		var x := 0.0
		for sp in spans:
			if sp[0] > x:
				draw_rect(Rect2(x, y0, sp[0] - x, y1 - y0), col)
			x = maxf(x, sp[1])
		if x < UI_W:
			draw_rect(Rect2(x, y0, UI_W - x, y1 - y0), col)

func _draw_tutorial() -> void:
	var st := _tut()
	tut_panel = Rect2()
	if st.is_empty():
		return
	var targets: Array = st["targets"]
	var free := targets.has("*") or targets.has("modal")
	var holes: Array[Rect2] = []
	for t: String in targets:
		var tr := _tut_rect(t)
		if tr.has_area():
			holes.append(tr.grow(10.0))
	if not free:
		_dim_except(holes, Color(0.03, 0.04, 0.06, 0.62))
		var pulse := 0.6 + 0.4 * sin(clock * 5.0)
		for h in holes:
			_panel(h, Color(0, 0, 0, 0), 18, Color(c_gold, pulse), 4)
		if not holes.is_empty():
			var h := holes[0]
			var bob := sin(clock * 6.0) * 8.0
			var up := h.position.y < 260.0
			var tip := Vector2(h.get_center().x, (h.end.y + 14.0 - bob) if up else (h.position.y - 14.0 + bob))
			var d := -1.0 if up else 1.0
			var tri := PackedVector2Array([tip, tip + Vector2(-22.0, -30.0 * d), tip + Vector2(22.0, -30.0 * d)])
			var sh := PackedVector2Array()
			for p in tri:
				sh.append(p + Vector2(3, 4))
			draw_colored_polygon(sh, Color(0, 0, 0, 0.4))
			draw_colored_polygon(tri, c_gold)
			draw_rect(Rect2(tip.x - 8.0, tip.y - 58.0 * d if not up else tip.y + 28.0, 16.0, 30.0), c_gold)
	var pw := 640.0
	var pad := 34.0
	var title := _tut_text(String(st["title"]))
	var paras := _tut_text(String(st["body"])).split("\n", false)
	var body_h := 0.0
	for para in paras:
		body_h += _rich_wrap(Vector2.ZERO, para, pw - pad * 2.0, T_SM, -1, false) + 10.0
	var waits := String(st["wait"]) != "next"
	var ph := 96.0 + body_h + 92.0
	var cands: Array[Rect2] = [
		Rect2(p_portfolio.get_center().x - pw * 0.5, UI_H - ph - 40.0, pw, ph),
		Rect2(p_market.position.x + 10.0, UI_H - ph - 40.0, pw, ph),
		Rect2(p_supply.end.x - pw - 10.0, UI_H - ph - 40.0, pw, ph),
		Rect2(p_market.position.x + 10.0, BODY_TOP + 20.0, pw, ph),
		Rect2(p_supply.end.x - pw - 10.0, BODY_TOP + 20.0, pw, ph),
		Rect2(UI_W * 0.5 - pw * 0.5, BODY_TOP + 20.0, pw, ph),
	]
	if targets.is_empty():
		cands.push_front(Rect2(Vector2(UI_W - pw, UI_H - ph) * 0.5, Vector2(pw, ph)))
	var avoid: Array[Rect2] = holes.duplicate()
	if targets.has("modal") and tut_rects.has("modal"):
		avoid.append(tut_rects["modal"])
	var pr := cands[0]
	for c in cands:
		var ok := true
		for a in avoid:
			if c.grow(12.0).intersects(a):
				ok = false
				break
		if ok:
			pr = c
			break
	tut_panel = pr
	_panel(Rect2(pr.position + Vector2(8, 14), pr.size), Color(0, 0, 0, 0.45), 10)
	_grad_panel(pr, 10.0, Color("fbf7ec"), Color("f1e9d4"))
	_panel(pr, Color(0, 0, 0, 0), 10, Color("cbb98c"), 2)
	_panel_corners(Rect2(pr.position, Vector2(pr.size.x, 10.0)), c_accent, 10, 10, 0, 0)
	var x := pr.position.x + pad
	var step_txt := "LESSON %d OF %d" % [tut_step + 1, D.TUTORIAL.size()]
	_text(Vector2(x, pr.position.y + 46.0), step_txt, T_XS, c_muted, true)
	_heavy(Vector2(x, pr.position.y + 84.0), title, _fit(title, pw - pad * 2.0, T_LG), c_ink)
	var y := pr.position.y + 104.0
	for para in paras:
		y += _rich_wrap(Vector2(x, y), para, pw - pad * 2.0, T_SM) + 10.0
	var by := pr.end.y - 72.0
	_ghost(Rect2(x - 8.0, by, 190.0, 50.0), "Skip tutorial", _tut_end, true, c_muted)
	if waits:
		_text_right(pr.end.x - pad, by + 34.0, "Do it to continue", T_SM, c_accent, true)
	else:
		var last := tut_step == D.TUTORIAL.size() - 1
		_button(Rect2(pr.end.x - pad - 200.0, by, 200.0, 56.0), "Let's play" if last else "Next", _tut_advance, true, c_accent, T_MD)

func _quarters_text(q: int) -> String:
	if q <= 0:
		return "-"
	if q >= rounds_per_run:
		return "Won"
	return "Y%d Q%d" % [_year_of(q), _quarter_in_year(q)]

func _draw_menu() -> void:
	_heavy(Vector2(UI_W * 0.5 - _heavy_w("HOLDINGS", T_HERO + 24) * 0.5, 150.0), "HOLDINGS", T_HERO + 24, c_light)
	var sub := "Choose a portfolio sheet. Survive %d years of yearly Brand targets." % _total_years()
	_text(Vector2(UI_W * 0.5 - _text_w(sub, T_MD, true) * 0.5, 202.0), sub, T_MD, c_light_muted, true)
	var ids: Array = D.SHEETS.keys()
	var cols := 4
	var tw := 548.0
	var th := 320.0
	var gap := 28.0
	var x0 := (UI_W - cols * tw - (cols - 1) * gap) * 0.5
	var y0 := 250.0
	for i in ids.size():
		var id := String(ids[i])
		var sh: Dictionary = D.SHEETS[id]
		var r := Rect2(x0 + (i % cols) * (tw + gap), y0 + floori(i / float(cols)) * (th + gap), tw, th)
		var hov := r.has_point(mouse)
		if hov:
			_panel(r.grow(6.0), Color(c_accent, 0.8), 26)
		_shadow(r, 20, 6.0)
		_panel(r, c_card, 20)
		_draw_sheet_thumb(Rect2(r.position + Vector2(24.0, 46.0), Vector2(228.0, 228.0)), sh)
		var tx := r.position.x + 276.0
		var w := r.end.x - 22.0 - tx
		var nm := String(sh["name"])
		_heavy(Vector2(tx, r.position.y + 62.0), nm, _fit(nm, w, T_LG), c_ink)
		var d := int(sh["difficulty"])
		var dl: String = ["", "EASY", "MEDIUM", "HARD"][clampi(d, 1, 3)]
		var dcol: Color = [c_good, c_good, c_warn, c_bad][clampi(d, 1, 3)]
		for j in 3:
			draw_circle(Vector2(tx + 7.0 + j * 18.0, r.position.y + 92.0), 6.0, dcol if j < d else c_line)
		_text(Vector2(tx + 62.0, r.position.y + 98.0), dl, T_XS, dcol.darkened(0.15), true)
		_wrap(Vector2(tx, r.position.y + 114.0), String(sh["description"]), w, T_SM, c_body, false, 6)
		var best := _quarters_text(int(sheet_best.get(id, 0)))
		_text(Vector2(tx, r.end.y - 24.0), "Best: %s" % best, T_SM, c_muted, true)
		_text_right(r.end.x - 22.0, r.end.y - 24.0, "Play →", T_SM, c_accent if hov else c_muted, true)
		_register(r, _start_sheet.bind(id))
	if not D.TUTORIAL.is_empty():
		var tb := Rect2(UI_W * 0.5 - 230.0, y0 + 3.0 * (th + gap) + 4.0, 460.0, 76.0)
		_button(tb, "Learn to play", _start_tutorial, true, c_accent, T_LG, "Guided first quarter")

func _draw_sheet_thumb(r: Rect2, sh: Dictionary) -> void:
	_panel(r.grow(8.0), Color("dfe7f1"), 12)
	var cell := (r.size.x - 2.0 * 8.0) / 3.0
	var random := bool(sh["random"])
	for i in 9:
		var c := Rect2(r.position + Vector2((i % 3) * (cell + 8.0), floori(i / 3.0) * (cell + 8.0)), Vector2(cell, cell))
		if random:
			_panel(c, Color(c_ink, 0.08), 8)
			_heavy_center(c, "?", T_XL, Color(c_ink, 0.3))
			continue
		var rule: Dictionary = sh["rules"][i]
		var lock: Dictionary = sh["locks"][i]
		var pocket := String(sh["pockets"][i])
		match String(rule["kind"]):
			"sector":
				var tc := _tcol(String(rule["type"]))
				_panel(c, tc.lerp(Color.WHITE, 0.35), 8)
				draw_circle(c.get_center(), cell * 0.24, Color.WHITE)
				_res_icon(String(rule["type"]), c.get_center(), cell * 0.16)
			"cap":
				_panel(c, Color("5b6577").lerp(Color.WHITE, 0.45), 8)
				var label := "%d+" % int(rule["min"]) if int(rule["max"]) >= 99 else "%d-%d" % [int(rule["min"]), int(rule["max"])]
				_heavy_center(c, label, T_SM, Color.WHITE)
			_:
				_panel(c, Color.WHITE, 8, Color(c_ink, 0.12), 2)
		if pocket != "":
			_panel(c, Color(0, 0, 0, 0), 8, Color(D.POCKET_MODS[pocket]["color"]), 4)
		if not lock.is_empty():
			_panel(c, Color(c_ink, 0.45), 8)
			draw_circle(c.get_center(), cell * 0.22, Color.WHITE)
			_icon("lock", c.get_center(), cell * 0.14)

func _best_text() -> String:
	if best_quarters <= 0:
		return "-"
	if best_quarters >= rounds_per_run:
		return "won"
	return "Y%d Q%d" % [_year_of(best_quarters), _quarter_in_year(best_quarters)]

func _continue() -> void:
	if game_result != "":
		phase = Phase.GAMEOVER
		_save_best()
		return
	round_n += 1
	_refresh_market()
	_start_round()
	if not pending_meeting.is_empty():
		meeting_info = pending_meeting
		pending_meeting = {}
		meeting = _make_offers(int(meeting_info["count"]))
	_tut_event("next_quarter")

func _primary_action() -> void:
	if show_help:
		show_help = false
		return
	if not meeting.is_empty() and phase == Phase.ACTION:
		return
	if event_intro and phase == Phase.ACTION:
		_close_intro()
		return
	match phase:
		Phase.ACTION:
			_end_round()
		Phase.REPORT:
			_continue()
		Phase.GAMEOVER:
			phase = Phase.MENU

func _debug_skip_round() -> void:
	if round_n >= rounds_per_run:
		return
	forecast.pop_front()
	forecast.append(_new_event(round_n + forecast_length))
	round_n += 1
	_say("Debug: skipped to quarter %d" % round_n)
	_refresh_market()
	_start_round()

func _debug_cycle_event(slot: int) -> void:
	var ids: Array = D.EVENTS.keys()
	var at := ids.find(forecast[slot]["id"])
	forecast[slot] = {"id": ids[(at + 1) % ids.size()], "weak": false, "revealed": true}

func _ui_mouse() -> Vector2:
	return (get_local_mouse_position() - screen_origin) / maxf(ui_scale, 0.0001)

func _process(delta: float) -> void:
	clock += delta
	if dice_sfx_left > 0.0:
		dice_sfx_left -= delta
		if dice_sfx_left <= 0.0 and sfx.has("dice"):
			sfx["dice"].stop()
	var over := Rect2()
	var mp := _ui_mouse()
	for i in range(buttons.size() - 1, -1, -1):
		if buttons[i].rect.has_point(mp):
			over = buttons[i].rect
			break
	if over != hover_rect:
		hover_rect = over
		if over.has_area():
			_sfx("mouseover")
	for d in dice:
		if d.roll_t > 0.0:
			d.roll_t = maxf(0.0, d.roll_t - delta)
			d.flicker -= delta
			if d.flicker <= 0.0:
				d.flicker = 0.06
				d.shown = randi_range(1, 6)
			if d.roll_t <= 0.0:
				d.shown = d.value
		else:
			d.shown = d.value
	for inst in board:
		if inst != null:
			inst.flash = maxf(0.0, inst.flash - delta * 1.4)
			inst.shake = maxf(0.0, inst.shake - delta * 3.0)
			var was := inst.place_t
			inst.place_t = minf(1.0, inst.place_t + delta / PLACE_TIME)
			if was < 0.6 and inst.place_t >= 0.6:
				_sfx("page_turn")
	for i in range(floaters.size() - 1, -1, -1):
		var f := floaters[i]
		if f.delay > 0.0:
			f.delay -= delta
			if f.delay <= 0.0:
				_flash_at(f.anchor)
			continue
		if f.age == 0.0:
			_flash_at(f.anchor)
		f.age += delta
		f.life -= delta
		f.pos.y -= 34.0 * delta
		if f.life <= 0.0:
			floaters.remove_at(i)
	queue_redraw()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		var p := _ui_mouse()
		if tut_on and not _tut_allows(p, mb.button_index == MOUSE_BUTTON_LEFT):
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			for i in range(buttons.size() - 1, -1, -1):
				if buttons[i].rect.has_point(p):
					_sfx("click")
					buttons[i].cb.call()
					return
			if phase == Phase.ACTION and choice.is_empty():
				selected_die = -1
				market_pick = -1
				board_pick = -1
		elif mb.button_index == MOUSE_BUTTON_RIGHT and phase == Phase.ACTION:
			for i in board.size():
				if board[i] != null and _board_rect(i).has_point(p) and not board[i].pending.is_empty():
					_return_pending(board[i])
					return
			selected_die = -1
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var key := (ev as InputEventKey).keycode
		if tut_on and not _tut_key_ok(key):
			return
		match key:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_primary_action()
			KEY_ESCAPE:
				if show_help:
					show_help = false
				elif not choice.is_empty():
					_skip_choice()
				else:
					selected_die = -1
					market_pick = -1
					board_pick = -1
			KEY_H:
				show_help = not show_help
			KEY_M:
				if music != null:
					music.stream_paused = not music.stream_paused
			KEY_F1:
				debug_on = not debug_on
			_:
				if debug_on and phase == Phase.ACTION:
					_debug_key(key)

func _debug_key(key: Key) -> void:
	if key >= KEY_1 and key <= KEY_6 and _die_free(selected_die):
		dice[selected_die].value = key - KEY_0
	elif key == KEY_R:
		for r: String in D.TYPES:
			res[r] = _r(r) + 1
	elif key == KEY_D:
		var d := Die.new()
		d.value = rng.randi_range(1, 6)
		d.roll_t = 0.3
		dice.append(d)
	elif key == KEY_N:
		_debug_skip_round()


func _market_slot(slot: int) -> Rect2:
	var col := slot % 2
	var row := floori(slot / 2.0)
	return Rect2(r_market.position.x + col * (card_w + CARD_GAP), r_market.position.y + row * (CARD_H + CARD_GAP), card_w, CARD_H)

func _market_rect(i: int) -> Rect2:
	return _market_slot(i + 2)

func _board_rect(i: int) -> Rect2:
	if i < 0:
		return Rect2(r_portfolio.get_center(), Vector2.ZERO)
	var col := i % GRID_COLS
	var row := floori(i / float(GRID_COLS))
	return Rect2(r_portfolio.position.x + col * (card_w + CARD_GAP), r_portfolio.position.y + row * (CARD_H + CARD_GAP), card_w, CARD_H)

func _mat_tray() -> Rect2:
	return Rect2(s_mat.position.x + 14.0, s_mat.position.y + 54.0, s_mat.size.x - 28.0, s_mat.size.y - 54.0 - 16.0 - 60.0 - 14.0)

func _mat_felt() -> Rect2:
	return _mat_tray().grow(-11.0)

func _res_col_rect(i: int) -> Rect2:
	var f := _mat_felt()
	var cw := (f.size.x - 16.0) / D.TYPES.size()
	return Rect2(f.position.x + 8.0 + i * cw, f.position.y + 132.0, cw, f.size.y - 140.0)

func _die_home(i: int) -> Vector2:
	var f := _mat_felt()
	var n := maxi(1, dice.size())
	var span := DIE_SIZE + (n - 1) * DIE_STEP
	var x0 := f.position.x + (f.size.x - span) * 0.5 + DIE_SIZE * 0.5
	return Vector2(x0 + i * DIE_STEP, f.position.y + 64.0)

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
	style.anti_aliasing = true
	draw_style_box(style, r)

func _shadow(r: Rect2, radius: int, depth: float = 6.0) -> void:
	_panel(Rect2(r.position + Vector2(0.0, depth), r.size), Color(c_shadow, 0.06), radius)
	_panel(Rect2(r.position + Vector2(0.0, depth * 0.4), r.size), Color(c_shadow, 0.05), radius)

func _f(bold: bool) -> Font:
	return font_bold if bold else font

func _vc(f: Font, size: int) -> float:
	return (f.get_ascent(size) - f.get_descent(size)) * 0.5

func _text(pos: Vector2, s: String, size: int, col: Color, bold: bool = false) -> void:
	draw_string(_f(bold), pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _text_w(s: String, size: int, bold: bool = false) -> float:
	return _f(bold).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _text_right(right_x: float, y: float, s: String, size: int, col: Color, bold: bool = false) -> void:
	_text(Vector2(right_x - _text_w(s, size, bold), y), s, size, col, bold)

func _heavy(pos: Vector2, s: String, size: int, col: Color) -> void:
	draw_string(font_heavy, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _heavy_w(s: String, size: int) -> float:
	return font_heavy.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _heavy_center(r: Rect2, s: String, size: int, col: Color) -> void:
	_heavy(Vector2(r.position.x + (r.size.x - _heavy_w(s, size)) * 0.5, r.get_center().y + _vc(font_heavy, size)), s, size, col)

func _heavy_right(right_x: float, y: float, s: String, size: int, col: Color) -> void:
	_heavy(Vector2(right_x - _heavy_w(s, size), y), s, size, col)

func _text_center(r: Rect2, s: String, size: int, col: Color, bold: bool = false) -> void:
	var f := _f(bold)
	draw_string(f, Vector2(r.position.x + (r.size.x - _text_w(s, size, bold)) * 0.5, r.get_center().y + _vc(f, size)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _fit(s: String, max_w: float, size: int) -> int:
	var sz := size
	while sz > 12 and _heavy_w(s, sz) > max_w:
		sz -= 1
	return sz

func _wrap(pos: Vector2, s: String, width: float, size: int, col: Color, bold: bool = false, max_lines: int = -1) -> void:
	draw_multiline_string(_f(bold), pos + Vector2(0.0, _f(bold).get_ascent(size)), s, HORIZONTAL_ALIGNMENT_LEFT, width, size, max_lines, col)

func _rich_wrap(pos: Vector2, s: String, width: float, size: int, max_lines: int = -1, do_draw: bool = true) -> float:
	var icons := {"Brand": "vp"}
	for r: String in D.TYPES:
		icons[D.RES_NAMES[r]] = r
	var f := _f(true)
	var space := f.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var rad := size * 0.62
	var lh := size * 1.45
	var x := 0.0
	var line := 0
	var cy := pos.y + lh * 0.5
	for word: String in s.split(" ", false):
		var core := word.rstrip(".,:;")
		var tail := word.substr(core.length())
		var is_icon := icons.has(core)
		var tail_w := f.get_string_size(tail, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x if tail != "" else 0.0
		var w := rad * 2.0 + tail_w if is_icon else f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		if x > 0.0 and x + w > width:
			line += 1
			if max_lines > 0 and line >= max_lines:
				return line * lh
			x = 0.0
			cy += lh
		if not do_draw:
			x += w + space
			continue
		if is_icon:
			_icon(String(icons[core]), Vector2(pos.x + x + rad, cy), rad)
			if tail != "":
				draw_string(f, Vector2(pos.x + x + rad * 2.0, cy + _vc(f, size)), tail, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c_body)
		else:
			var strong := word.begins_with("+") or word.begins_with("-") or word.is_valid_int()
			draw_string(f, Vector2(pos.x + x, cy + _vc(f, size)), word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c_ink if strong else c_body)
		x += w + space
	return (line + 1) * lh

func _register(r: Rect2, cb: Callable) -> void:
	if not ui_live:
		return
	var b := UiButton.new()
	b.rect = r
	b.cb = cb
	buttons.append(b)

func _tip_card(r: Rect2, id: String, inst: CardInst, market_i: int) -> void:
	if ui_live and r.has_point(mouse):
		hover_card = {"id": id, "inst": inst, "market": market_i}
		hover_tip = ""

func _chip(x: float, y: float, label: String, col: Color, icon: String, do_draw: bool) -> float:
	var w := _text_w(label, T_XS, true) + (40.0 if icon != "" else 22.0)
	if do_draw:
		var r := Rect2(x, y, w, 28.0)
		_panel(r, col, 14)
		var tx := x + 11.0
		if icon != "":
			draw_circle(Vector2(tx + 8.0, r.get_center().y), 10.0, Color.WHITE)
			_icon(icon, Vector2(tx + 8.0, r.get_center().y), 7.0)
			tx += 22.0
		_text(Vector2(tx, r.get_center().y + _vc(font_bold, T_XS)), label, T_XS, Color.WHITE, true)
	return w

func _tip_section(x: float, y: float, label: String, do_draw: bool) -> float:
	if do_draw:
		_text(Vector2(x, y + 14.0), label, T_XS, c_muted, true)
	return 24.0

func _card_tooltip_body(pos: Vector2, w: float, do_draw: bool) -> float:
	var id := String(hover_card["id"])
	var inst: CardInst = hover_card["inst"]
	var mi := int(hover_card["market"])
	var c: Dictionary = D.CARDS[id]
	var t := String(c["type"])
	var x := pos.x
	var y := pos.y
	var value := _effective_value(inst) if inst != null else int(c["value"])
	if do_draw:
		_heavy(Vector2(x, y + 28.0), String(c["name"]), T_LG, c_ink)
		var vs := str(value)
		_heavy_right(x + w, y + 28.0, vs, T_LG, c_ink)
		_icon("vp", Vector2(x + w - _heavy_w(vs, T_LG) - 18.0, y + 18.0), 12.0)
	y += 44.0
	var cx := x
	cx += _chip(cx, y, D.TYPE_NAMES[t], _tcol(t), t, do_draw) + 8.0
	var rarity := String(c.get("rarity", "common"))
	cx += _chip(cx, y, rarity.capitalize(), Color(D.RARITY_COLORS.get(rarity, "8b8f87")), "", do_draw) + 8.0
	var ed := ""
	if inst != null:
		ed = inst.edition
	elif mi >= 0:
		ed = _market_edition(mi)
	if ed != "":
		_chip(cx, y, D.EDITIONS[ed]["name"], Color(D.EDITIONS[ed]["color"]).darkened(0.1), "", do_draw)
	y += 42.0
	if do_draw:
		draw_line(Vector2(x, y), Vector2(x + w, y), c_line, 2.0)
	y += 12.0
	y += _tip_section(x, y, "ABILITY", do_draw)
	y += _rich_wrap(Vector2(x, y), String(c["text"]), w, T_SM, -1, do_draw) + 10.0
	y += _tip_section(x, y, "OPERATE", do_draw)
	var p := _effective_pattern(inst) if inst != null else _base_pattern(id)
	if do_draw:
		if p.is_empty():
			draw_string(font_italic, Vector2(x, y + 16.0), "Needs no die: works on its own", HORIZONTAL_ALIGNMENT_LEFT, -1, T_SM, c_body)
		else:
			_icon("die", Vector2(x + 10.0, y + 10.0), 10.0)
			var lbl := _pattern_label(p)
			_text(Vector2(x + 28.0, y + 16.0), lbl, T_SM, c_ink, true)
			draw_string(font_italic, Vector2(x + 36.0 + _text_w(lbl, T_SM, true), y + 16.0), "(%s)" % _pattern_rule(p), HORIZONTAL_ALIGNMENT_LEFT, -1, T_SM, c_muted)
	y += 30.0
	if not p.is_empty():
		if do_draw:
			_icon("vp", Vector2(x + 10.0, y + 10.0), 10.0)
			_text(Vector2(x + 28.0, y + 16.0), "+%d Brand" % (value * (2 if ed == "gold" else 1)), T_SM, c_ink, true)
			draw_string(font_italic, Vector2(x + 36.0 + _text_w("+%d Brand" % (value * (2 if ed == "gold" else 1)), T_SM, true), y + 16.0), "each time it operates", HORIZONTAL_ALIGNMENT_LEFT, -1, T_SM, c_muted)
		y += 30.0
	if mi >= 0:
		y += 6.0
		y += _tip_section(x, y, "COST", do_draw)
		if do_draw:
			_tokens(x, y + 12.0, _market_cost(mi), 10.0, T_MD, true)
		y += 30.0
		if do_draw:
			var cv := int(c["value"])
			var filler := String(D.COST_FILLER.get(t, D.DEFAULT_FILLER))
			var note := "Mostly %s, the rest %s" % [D.RES_NAMES[t], D.RES_NAMES[filler]]
			if cv >= D.GATE_VALUE and t != D.GATE_RES:
				note += ", plus 1 %s" % D.RES_NAMES[D.GATE_RES]
			if c.has("cost"):
				note = "Set price"
			if ed != "":
				note += ". Enhanced: +1 Cash"
			draw_string(font_italic, Vector2(x, y + 14.0), note, HORIZONTAL_ALIGNMENT_LEFT, w, T_XS, c_muted)
		y += 24.0
	if ed != "":
		y += 6.0
		y += _tip_section(x, y, "EDITION", do_draw)
		y += _rich_wrap(Vector2(x, y), "%s: %s." % [D.EDITIONS[ed]["name"], D.EDITIONS[ed]["text"]], w, T_SM, -1, do_draw)
	return y - pos.y

func _draw_card_tooltip() -> void:
	var w := 440.0
	var h := _card_tooltip_body(Vector2.ZERO, w, false) + 40.0
	var box := Rect2(mouse + Vector2(24.0, 24.0), Vector2(w + 44.0, h))
	if box.end.x > UI_W - 12.0:
		box.position.x = mouse.x - box.size.x - 16.0
	if box.end.y > UI_H - 12.0:
		box.position.y = maxf(12.0, UI_H - 12.0 - box.size.y)
	_shadow(box, 16, 8.0)
	_panel(box, Color("fbf9f2"), 16, Color(c_ink, 0.15), 2)
	var t := String(D.CARDS[String(hover_card["id"])]["type"])
	_panel_corners(Rect2(box.position, Vector2(box.size.x, 8.0)), _tcol(t), 16, 16, 0, 0)
	_card_tooltip_body(box.position + Vector2(22.0, 22.0), w, true)

func _tip(r: Rect2, text: String) -> void:
	if ui_live and text != "" and r.has_point(mouse):
		hover_tip = text

func _tcol(kind: String) -> Color:
	return Color(D.TYPE_COLORS.get(kind, "8b8f87"))

func _button(r: Rect2, label: String, cb: Callable, enabled: bool, face: Color, size: int = T_LG, sub: String = "") -> void:
	var hovered := enabled and ui_live and r.has_point(mouse)
	var col := face if enabled else c_line
	var ink := Color.WHITE if enabled else c_muted
	var radius := int(minf(r.size.y * 0.5, 20.0))
	_panel(r, col.lightened(0.08) if hovered else col, radius)
	if sub == "":
		_text_center(r, label, size, ink, true)
	else:
		_text_center(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.62)), label, size, ink, true)
		_text_center(Rect2(r.position + Vector2(0, r.size.y * 0.52), Vector2(r.size.x, r.size.y * 0.4)), sub, T_XS, Color(ink, 0.8), true)
	if enabled:
		_register(r, cb)

func _ghost(r: Rect2, label: String, cb: Callable, enabled: bool, ink: Color = c_ink) -> void:
	var hovered := enabled and ui_live and r.has_point(mouse)
	var radius := int(minf(r.size.y * 0.5, 20.0))
	if hovered:
		_panel(r, Color(ink, 0.07), radius)
	_panel(r, Color(0, 0, 0, 0), radius, Color(ink if enabled else c_line, 0.35 if enabled else 1.0), 2)
	_text_center(r, label, T_MD, ink if enabled else c_muted, true)
	if enabled:
		_register(r, cb)

func _star(c: Vector2, outer: float, inner: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (outer if i % 2 == 0 else inner))
	draw_colored_polygon(pts, col)

func _res_icon(kind: String, c: Vector2, rad: float) -> void:
	var col := _tcol(kind)
	match kind:
		"cash":
			draw_rect(Rect2(c - Vector2(rad, rad * 0.62), Vector2(rad * 2.0, rad * 1.24)), col)
			draw_circle(c, rad * 0.36, col.lightened(0.45))
			draw_circle(c, rad * 0.18, col)
		"labor":
			draw_circle(c + Vector2(0, -rad * 0.45), rad * 0.42, col)
			_dome(c + Vector2(0, rad * 0.95), rad * 0.85, rad * 0.95, col)
		"equipment":
			var pts := PackedVector2Array()
			for i in 32:
				var a := i * TAU / 32.0
				var out := rad if (i / 2) % 2 == 0 else rad * 0.72
				pts.append(c + Vector2.from_angle(a + TAU / 64.0) * out)
			draw_colored_polygon(pts, col)
			draw_circle(c, rad * 0.32, col.lightened(0.6))
		"intel":
			var lens := c + Vector2(-rad * 0.22, -rad * 0.22)
			var w := maxf(2.0, rad * 0.26)
			draw_line(lens + Vector2(rad * 0.45, rad * 0.45), c + Vector2(rad * 0.95, rad * 0.95), col, w * 1.3, true)
			draw_circle(lens, rad * 0.68, col)
			draw_circle(lens, rad * 0.68 - w, col.lightened(0.7))
		"advertising":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-rad * 0.95, -rad * 0.3), c + Vector2(rad * 0.75, -rad * 0.95), c + Vector2(rad * 0.75, rad * 0.95), c + Vector2(-rad * 0.95, rad * 0.3)]), col)
			draw_rect(Rect2(c + Vector2(-rad * 0.95, -rad * 0.32), Vector2(rad * 0.4, rad * 0.64)), col.darkened(0.25))
			draw_rect(Rect2(c + Vector2(rad * 0.7, -rad * 0.95), Vector2(rad * 0.25, rad * 1.9)), col.darkened(0.2))

func _tokens(x: float, cy: float, cost: Dictionary, rad: float, size: int, check: bool) -> float:
	for r: String in D.TYPES:
		if not cost.has(r):
			continue
		var amt := int(cost[r])
		var short := check and _r(r) < amt
		var s := str(amt)
		_heavy(Vector2(x, cy + _vc(font_heavy, size)), s, size, c_bad if short else c_ink)
		x += _heavy_w(s, size) + 3.0
		_res_icon(r, Vector2(x + rad, cy), rad)
		x += rad * 2.0 + 14.0
	return x

func _pip_offsets(face: int) -> Array:
	match face:
		1:
			return [Vector2.ZERO]
		2:
			return [Vector2(-1, -1), Vector2(1, 1)]
		3:
			return [Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)]
		4:
			return [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
		5:
			return [Vector2(-1, -1), Vector2(1, -1), Vector2.ZERO, Vector2(-1, 1), Vector2(1, 1)]
	return [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]

func _draw_dice_tray(r: Rect2) -> void:
	var wood := Color("6b4a32")
	_panel(Rect2(r.position + Vector2(0, 4), r.size), Color(c_shadow, 0.18), 18)
	_panel(r, wood, 18)
	_panel(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5)), Color(1, 1, 1, 0.07), 18)
	var grain := Color(wood.darkened(0.25), 0.5)
	for i in 3:
		var gy := r.position.y + 4.0 + i * 3.0
		draw_line(Vector2(r.position.x + 20.0, gy), Vector2(r.end.x - 20.0, gy), grain, 1.0)
		var by := r.end.y - 4.0 - i * 3.0
		draw_line(Vector2(r.position.x + 20.0, by), Vector2(r.end.x - 20.0, by), grain, 1.0)
	var felt := r.grow(-11.0)
	_grad_panel(felt, 11.0, Color("2f7a4c"), Color("1f5a37"))
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 7
	for i in 260:
		var pt := Vector2(rng2.randf_range(felt.position.x + 4.0, felt.end.x - 4.0), rng2.randf_range(felt.position.y + 4.0, felt.end.y - 4.0))
		draw_rect(Rect2(pt, Vector2(1.5, 1.5)), Color(1, 1, 1, 0.05) if i % 2 == 0 else Color(0, 0, 0, 0.08))
	draw_rect(Rect2(felt.position + Vector2(8.0, 0.0), Vector2(felt.size.x - 16.0, 5.0)), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(felt.position + Vector2(8.0, 5.0), Vector2(felt.size.x - 16.0, 4.0)), Color(0, 0, 0, 0.1))
	_panel(felt, Color(0, 0, 0, 0), 11, Color(0, 0, 0, 0.35), 2)

func _die_body(center: Vector2, size: float, face: int, body: Color, pip: Color, outline: Color = Color(0, 0, 0, 0)) -> void:
	var r := Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size))
	var radius := int(size * 0.22)
	_panel(Rect2(r.position + Vector2(0, size * 0.05), r.size), Color(c_shadow, 0.12), radius)
	_panel(r, body, radius, outline if outline.a > 0.0 else Color(c_line, 1.0), 4 if outline.a > 0.0 else 2)
	for o: Vector2 in _pip_offsets(face):
		draw_circle(center + o * size * 0.25, size * 0.085, pip)

func _picker_active() -> bool:
	var kind := String(choice.get("kind", ""))
	return kind == "refresh_type" or (kind == "peek_swap" and int(choice["picked"]) < 0)

func _draw() -> void:
	buttons.clear()
	tut_rects.clear()
	hover_tip = ""
	hover_card = {}
	hover_forecast = -1
	draw_rect(Rect2(Vector2.ZERO, window_size), c_page)
	mouse = _ui_mouse()
	base_xform = Transform2D(0.0, Vector2(ui_scale, ui_scale), 0.0, screen_origin)
	draw_set_transform_matrix(base_xform)
	card_xform = base_xform
	if phase == Phase.MENU:
		ui_live = true
		_draw_menu()
		if hover_tip != "":
			_draw_tooltip(hover_tip)
		draw_set_transform(Vector2.ZERO)
		return
	var picker := _picker_active() and phase == Phase.ACTION
	var in_meeting := not meeting.is_empty() and phase == Phase.ACTION
	var intro := event_intro and phase == Phase.ACTION
	ui_live = phase == Phase.ACTION and not show_help and not picker and not intro and not in_meeting
	_draw_header()
	_draw_padfolio()
	_draw_market()
	_draw_portfolio()
	_draw_supply()
	_draw_floaters()
	ui_live = phase == Phase.ACTION and not show_help and not intro and not in_meeting
	if picker:
		_draw_picker()
	else:
		_draw_banner()
	ui_live = true
	if in_meeting and not show_help:
		_draw_meeting()
	elif intro and not show_help:
		_draw_event_intro()
	if phase == Phase.REPORT:
		_draw_report()
	elif phase == Phase.GAMEOVER:
		_draw_gameover()
	if tut_on and not show_help:
		_draw_tutorial()
	if show_help:
		_draw_help()
	if debug_on:
		_draw_debug()
	if not hover_card.is_empty():
		_draw_card_tooltip()
	elif hover_tip != "":
		_draw_tooltip(hover_tip)
	draw_set_transform(Vector2.ZERO)

func _region(p: Rect2, title: String, fill: Color) -> void:
	_panel(p, fill, 28)
	_heavy(Vector2(p.position.x + PANEL_PAD, p.position.y + 44.0), title, T_LG, c_light)

func _tile(r: Rect2, border: Color = Color(0, 0, 0, 0)) -> void:
	_shadow(r, 20, 4.0)
	_panel(r, c_card, 20, border, 3 if border.a > 0.0 else 0)

func _draw_header() -> void:
	var cal := Rect2(h_left.position.x, HEADER_Y + 4.0, 176.0, HEADER_H - 8.0)
	_draw_calendar(cal)
	var note := Rect2(h_center.end.x - 104.0, HEADER_Y + 14.0, 100.0, 100.0)
	if not forecast.is_empty():
		_draw_clipping(cal.end.x + 44.0, note.position.x - 40.0 - cal.end.x - 44.0)
	_draw_help_note(note)

func _rot_xform(c: Vector2, angle: float) -> Transform2D:
	return base_xform * Transform2D(angle, Vector2.ONE, 0.0, c) * Transform2D(0.0, -c)

func _draw_calendar(r: Rect2) -> void:
	var red := Color("c4553f")
	_panel(Rect2(r.position + Vector2(4, 7), r.size), Color(0, 0, 0, 0.35), 8)
	_panel(Rect2(r.position + Vector2(3, 3), r.size), Color("e8e2d4"), 8)
	_panel(r, Color("fbf8f0"), 8)
	var band := Rect2(r.position, Vector2(r.size.x, 40.0))
	_panel_corners(band, red, 8, 8, 0, 0)
	var year_end := _is_year_end(round_n)
	var ht := "YEAR END" if year_end else "YEAR %d OF %d" % [_year_of(round_n), _total_years()]
	_text_center(Rect2(band.position + Vector2(0, 8), band.size - Vector2(0, 8)), ht, T_SM, Color.WHITE, true)
	for i in 4:
		var rx := r.position.x + 30.0 + i * (r.size.x - 60.0) / 3.0
		draw_circle(Vector2(rx, r.position.y + 8.0), 4.0, Color(0, 0, 0, 0.45))
		draw_arc(Vector2(rx, r.position.y + 2.0), 6.0, PI * 1.05, PI * 1.95, 10, Color("8a8f98"), 3.0, true)
		draw_line(Vector2(rx, r.position.y - 4.0), Vector2(rx, r.position.y + 8.0), Color("8a8f98"), 3.0, true)
	var q := _quarter_in_year(round_n)
	_heavy_center(Rect2(r.position.x, r.position.y + 42.0, r.size.x, 56.0), "Q%d" % q, T_HERO - 6, c_ink)
	for i in D.QUARTERS_PER_YEAR:
		var pc := Vector2(r.get_center().x - 33.0 + i * 22.0, r.end.y - 16.0)
		if i < q - 1:
			draw_circle(pc, 6.0, c_ink)
		elif i == q - 1:
			draw_circle(pc, 7.0, red)
		else:
			draw_arc(pc, 5.5, 0.0, TAU, 16, c_line, 2.0, true)
	var lines: Array[String] = ["Year %d of %d, quarter %d of %d." % [_year_of(round_n), _total_years(), q, D.QUARTERS_PER_YEAR]]
	for y in years:
		lines.append("Year %d: %s (%d / %d Brand)" % [int(y["year"]), "target met" if bool(y["hit"]) else "missed", int(y["vp"]), int(y["target"])])
	lines.append("Sheet: %s  ·  Best: %s" % [_sheet_name(), _quarters_text(int(sheet_best.get(sheet_id, 0)))])
	_tip(r, "\n".join(lines))

func _jit(i: int, amp: float) -> float:
	return sin(i * 12.9898 + 78.233) * amp

func _marker_rect(r: Rect2, col: Color, w: float, seed: int) -> void:
	var pts := PackedVector2Array([
		r.position + Vector2(_jit(seed, 2.0), _jit(seed + 1, 2.0)),
		Vector2(r.end.x + _jit(seed + 2, 2.0), r.position.y + _jit(seed + 3, 2.0)),
		r.end + Vector2(_jit(seed + 4, 2.0), _jit(seed + 5, 2.0)),
		Vector2(r.position.x + _jit(seed + 6, 2.0), r.end.y + _jit(seed + 7, 2.0)),
		r.position + Vector2(3.0 + _jit(seed + 8, 1.5), _jit(seed + 9, 2.0)),
	])
	draw_polyline(pts, col, w, true)

func _marker_star(c: Vector2, rad: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 11:
		var a := -PI * 0.5 + i * TAU * 2.0 / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * rad + Vector2(_jit(i, 1.5), _jit(i + 7, 1.5)))
	draw_polyline(pts, col, w, true)

func _draw_scorepad(r: Rect2) -> void:
	var c := r.get_center()
	draw_set_transform_matrix(_rot_xform(c, -0.025))
	_panel(Rect2(r.position + Vector2(8, 12), r.size), Color(0, 0, 0, 0.4), 6)
	_panel(Rect2(r.position + Vector2(4, 5), r.size), Color("e9d98a"), 6)
	_grad_panel(r, 6.0, Color("fdf3ae"), Color("f3e290"))
	var strip := Rect2(r.position, Vector2(r.size.x, 28.0))
	_panel_corners(strip, Color("7a2a22"), 6, 6, 0, 0)
	draw_line(strip.position + Vector2(6, 4), Vector2(strip.end.x - 6, strip.position.y + 4), Color(1, 1, 1, 0.18), 2.0)
	draw_line(Vector2(strip.position.x, strip.end.y), Vector2(strip.end.x, strip.end.y), Color(0, 0, 0, 0.3), 2.0)
	var y := strip.end.y + 44.0
	while y < r.end.y - 6.0:
		draw_line(Vector2(r.position.x + 4.0, y), Vector2(r.end.x - 4.0, y), Color("6aa0d8", 0.45), 1.5)
		y += 40.0
	var mx := r.position.x + 56.0
	draw_line(Vector2(mx, strip.end.y), Vector2(mx, r.end.y), Color("d9534f", 0.55), 2.0)
	var ink := Color("1f2430")
	var vp := _round_vp()
	var target := _target_for(round_n)
	var met := vp >= target
	var year_end := _is_year_end(round_n)
	var tx := mx + 18.0
	var lw := strip.end.y + 44.0
	draw_string(font_marker, Vector2(tx, lw - 8.0), "Brand  ·  Year %d" % _year_of(round_n), HORIZONTAL_ALIGNMENT_LEFT, -1, T_MD, Color(ink, 0.8))
	_marker_star(Vector2(tx + 26.0, lw + 58.0), 26.0, Color("e0a32a"), 5.0)
	var big := "%d / %d" % [vp, target]
	draw_string(font_marker, Vector2(tx + 66.0, lw + 82.0), big, HORIZONTAL_ALIGNMENT_LEFT, -1, T_HERO + 6, Color("2e7d32") if met else ink)
	var head := "Target met!" if met else ("Short by %d!" % (target - vp) if year_end else "%d to go" % (target - vp))
	draw_string(font_marker, Vector2(tx, lw + 148.0), head, HORIZONTAL_ALIGNMENT_LEFT, -1, T_LG, Color("2e7d32") if met else (Color("c62828") if year_end else Color(ink, 0.85)))
	var bar := Rect2(tx, lw + 172.0, r.end.x - 28.0 - tx, 26.0)
	var fill := clampf(float(vp) / maxf(1.0, target), 0.0, 1.0)
	if fill > 0.0:
		var fc := Color("2e7d32", 0.8) if met else Color("e2762f", 0.85)
		var hx := bar.position.x + 3.0
		var i := 0
		while hx < bar.position.x + bar.size.x * fill - 2.0:
			draw_line(Vector2(hx, bar.end.y - 3.0), Vector2(hx + 9.0, bar.position.y + 3.0), fc, 4.0, true)
			hx += 7.0
			i += 1
	_marker_rect(bar, ink, 3.0, 3)
	if miss_rule == MissRule.STRIKES:
		var sy := bar.end.y + 56.0
		draw_string(font_marker, Vector2(tx, sy), "Strikes", HORIZONTAL_ALIGNMENT_LEFT, -1, T_MD, Color(ink, 0.85))
		var bx := tx + 120.0
		for k in strikes_to_lose:
			var box := Rect2(bx + k * 46.0, sy - 30.0, 32.0, 32.0)
			_marker_rect(box, ink, 3.0, 20 + k * 10)
			if k < strikes:
				draw_line(box.position + Vector2(-2, -2), box.end + Vector2(3, 2), Color("c62828"), 5.0, true)
				draw_line(Vector2(box.end.x + 2, box.position.y - 3), Vector2(box.position.x - 2, box.end.y + 2), Color("c62828"), 5.0, true)
	else:
		draw_string(font_marker, Vector2(tx, bar.end.y + 56.0), "Debt: %d" % debt, HORIZONTAL_ALIGNMENT_LEFT, -1, T_MD, Color("c62828") if debt > 0 else ink)
	draw_set_transform_matrix(base_xform)
	var left := D.QUARTERS_PER_YEAR - _quarter_in_year(round_n)
	_tip(r, "Brand this year: %d of %d (%d this quarter), earned by placing and operating businesses.\nThe yearly target is checked after quarter %d. %s\nMiss a yearly target and take a strike (%d and you're out). Unused dice become Cash at quarter end." % [vp, target, act_vp, D.QUARTERS_PER_YEAR, "This is the last quarter of the year." if left == 0 else "%d more quarter%s after this one." % [left, "" if left == 1 else "s"], strikes_to_lose])

func _draw_clipping(x: float, max_w: float) -> void:
	var ev: Dictionary = forecast[0]
	var e: Dictionary = D.EVENTS[ev["id"]]
	var tier := String(e["tier"])
	var tcol: Color = {"mild": c_good, "moderate": c_warn, "severe": c_bad}.get(tier, c_muted)
	var title := (String(e["name"]) + (" (weakened)" if bool(ev.get("weak", false)) else "")).to_upper()
	var deck := _event_text(ev)
	var cond := _event_condition(ev)
	var kick := _tier_kicker(tier)
	var dateline := "%s  ·  Y%d Q%d" % [NEWSPAPER, _year_of(round_n), _quarter_in_year(round_n)]
	var tsz := T_XL
	var dsz := T_SM
	var inner := maxf(_heavy_w(title, tsz), font_serif_italic.get_string_size(deck, HORIZONTAL_ALIGNMENT_LEFT, -1, dsz).x)
	var stamp_w := (_text_w("GOAL OPEN", T_XS, true) + 24.0) if not cond.is_empty() else 0.0
	inner = maxf(inner, _text_w(dateline, T_XS, true) + _text_w(kick, T_XS, true) + 40.0 + stamp_w)
	var w := minf(inner + 56.0, max_w)
	while tsz > T_MD and _heavy_w(title, tsz) > w - 56.0:
		tsz -= 1
	while dsz > 13 and font_serif_italic.get_string_size(deck, HORIZONTAL_ALIGNMENT_LEFT, -1, dsz).x > w - 56.0:
		dsz -= 1
	var r := Rect2(x, HEADER_Y + 8.0, w, HEADER_H - 14.0)
	tut_rects["clipping"] = r
	var c := r.get_center()
	draw_set_transform_matrix(_rot_xform(c, -0.012))
	var pts := PackedVector2Array()
	var step := 14.0
	var n := int(r.size.x / step)
	for i in n + 1:
		pts.append(Vector2(r.position.x + i * r.size.x / n, r.position.y + (3.0 if i % 2 == 0 else 0.0)))
	for i in range(n, -1, -1):
		pts.append(Vector2(r.position.x + i * r.size.x / n, r.end.y - (3.0 if i % 2 == 1 else 0.0)))
	var sh := PackedVector2Array()
	for pt in pts:
		sh.append(pt + Vector2(5, 7))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
	draw_colored_polygon(pts, C_PAPER)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 5
	for i in int(r.size.x * r.size.y / 700.0):
		draw_rect(Rect2(Vector2(rng2.randf_range(r.position.x + 4.0, r.end.x - 4.0), rng2.randf_range(r.position.y + 6.0, r.end.y - 6.0)), Vector2(1.5, 1.5)), Color(0.35, 0.28, 0.15, 0.07))
	var tx := r.position.x + 28.0
	var tw := r.size.x - 56.0
	draw_string(font_bold, Vector2(tx, r.position.y + 30.0), dateline, HORIZONTAL_ALIGNMENT_LEFT, -1, T_XS, Color(C_NEWSINK, 0.75))
	var kw := _text_w(kick, T_XS, true) + 16.0
	var kr := Rect2(tx + tw - kw, r.position.y + 13.0, kw, 22.0)
	_panel(kr, tcol.darkened(0.15) if tier != "mild" else C_NEWSINK, 3)
	_text_center(kr, kick, T_XS, C_PAPER, true)
	if not cond.is_empty():
		var ok := _condition_met(cond)
		var tag := "GOAL MET" if ok else "GOAL OPEN"
		var gw := _text_w(tag, T_XS, true) + 16.0
		var gr := Rect2(kr.position.x - gw - 8.0, kr.position.y, gw, 22.0)
		_panel(gr, Color(0, 0, 0, 0), 3, c_good if ok else c_warn.darkened(0.2), 2)
		_text_center(gr, tag, T_XS, c_good if ok else c_warn.darkened(0.25), true)
	_double_rule(tx, tx + tw, r.position.y + 42.0)
	_heavy(Vector2(tx, r.position.y + 84.0), title, tsz, C_NEWSINK)
	draw_string(font_serif_italic, Vector2(tx, r.position.y + 110.0), deck, HORIZONTAL_ALIGNMENT_LEFT, -1, dsz, Color(C_NEWSINK, 0.85))
	for tp: Vector2 in [Vector2(r.position.x + 2.0, r.position.y + 2.0), Vector2(r.end.x - 2.0, r.position.y + 2.0)]:
		draw_set_transform_matrix(_rot_xform(c, -0.012) * Transform2D(-0.78 if tp.x < c.x else 0.78, Vector2.ONE, 0.0, tp) * Transform2D(0.0, -tp))
		draw_rect(Rect2(tp - Vector2(24, 8), Vector2(48, 16)), Color(0.96, 0.93, 0.8, 0.8))
	draw_set_transform_matrix(base_xform)
	if r.has_point(mouse) and ui_live:
		hover_forecast = 0
	var lines: Array[String] = [String(e["name"]) + ": " + deck]
	if not cond.is_empty():
		lines.append("Goal: " + _condition_text(cond))
	lines.append_array(round_notes)
	for j in range(1, forecast.size()):
		if round_n + j > rounds_per_run:
			break
		var fe: Dictionary = forecast[j]
		var when := "Next quarter" if j == 1 else "In %d quarters" % j
		if j < forecast_visible or bool(fe.get("revealed", false)):
			lines.append("%s: %s (%s)" % [when, _event_name(fe), _event_text(fe)])
		else:
			lines.append("%s: %s event, details revealed later" % [when, String(D.EVENTS[fe["id"]]["category"]).capitalize()])
	_tip(r, "\n".join(lines))

func _draw_help_note(r: Rect2) -> void:
	var c := r.get_center()
	var hov := ui_live and r.has_point(mouse)
	draw_set_transform_matrix(_rot_xform(c, 0.05 if not hov else 0.0))
	_panel(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.35), 3)
	_grad_panel(r, 3.0, Color("fff3a0"), Color("f5d54a"))
	draw_colored_polygon(PackedVector2Array([Vector2(r.end.x - 22.0, r.end.y), r.end, Vector2(r.end.x, r.end.y - 22.0)]), Color("d9b52c"))
	_heavy_center(Rect2(r.position.x, r.position.y + 6.0, r.size.x, 60.0), "?", T_HERO - 12, Color("5a4a10"))
	_text_center(Rect2(r.position.x, r.end.y - 34.0, r.size.x, 24.0), "HELP", T_XS, Color("5a4a10"), true)
	draw_set_transform_matrix(base_xform)
	_register(r, func() -> void: show_help = true)
	_tip(r, "How to play (H)")

func _tier_name(tier: String) -> String:
	return {"mild": "MILD", "moderate": "MODERATE", "severe": "SEVERE"}.get(tier, tier.to_upper())

const NEWSPAPER := "THE HOLDINGS HERALD"
const C_PAPER := Color("f3eedf")
const C_NEWSINK := Color("1d1b18")

func _news_lines(f: Font, text: String, width: float, size: int) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for word in text.split(" ", false):
		var t := word if cur == "" else cur + " " + word
		if cur != "" and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			out.append(cur)
			cur = word
		else:
			cur = t
	if cur != "":
		out.append(cur)
	return out

func _paper(r: Rect2, radius: int) -> void:
	_panel(r, C_PAPER, radius)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 11
	for i in int(r.size.x * r.size.y / 900.0):
		var p := Vector2(rng2.randf_range(r.position.x + 6.0, r.end.x - 6.0), rng2.randf_range(r.position.y + 6.0, r.end.y - 6.0))
		draw_rect(Rect2(p, Vector2(1.5, 1.5)), Color(0.35, 0.28, 0.15, 0.07))

func _double_rule(x0: float, x1: float, y: float) -> void:
	draw_line(Vector2(x0, y), Vector2(x1, y), C_NEWSINK, 2.5)
	draw_line(Vector2(x0, y + 5.0), Vector2(x1, y + 5.0), C_NEWSINK, 1.0)

func _tier_kicker(tier: String) -> String:
	return {"mild": "MARKET NEWS", "moderate": "MARKETS SHAKEN", "severe": "BREAKING"}.get(tier, "MARKET NEWS")

func _draw_event_intro() -> void:
	var ev: Dictionary = forecast[0]
	var e: Dictionary = D.EVENTS[ev["id"]]
	var tier := String(e["tier"])
	var tcol: Color = {"mild": c_good, "moderate": c_warn, "severe": c_bad}.get(tier, c_muted)
	var cond := _event_condition(ev)
	_dim()
	var r := Rect2(Vector2(UI_W - 1040.0, UI_H - 700.0) * 0.5, Vector2(1040.0, 700.0))
	tut_rects["modal"] = r
	_panel(Rect2(r.position + Vector2(10, 14), r.size), Color(0, 0, 0, 0.35), 6)
	_paper(r, 6)
	var x := r.position.x + 56.0
	var w := r.size.x - 112.0
	var mast := NEWSPAPER
	var msz := _fit(mast, w, T_HERO)
	_heavy(Vector2(r.get_center().x - _heavy_w(mast, msz) * 0.5, r.position.y + 92.0), mast, msz, C_NEWSINK)
	_double_rule(x, x + w, r.position.y + 112.0)
	var dl := "YEAR %d OF %d  ·  QUARTER %d" % [_year_of(round_n), _total_years(), _quarter_in_year(round_n)]
	draw_string(font_bold, Vector2(x, r.position.y + 140.0), dl, HORIZONTAL_ALIGNMENT_LEFT, -1, T_XS, C_NEWSINK)
	var price := "PRICE: 1 CASH"
	draw_string(font_bold, Vector2(x + w - _text_w(price, T_XS, true), r.position.y + 140.0), price, HORIZONTAL_ALIGNMENT_LEFT, -1, T_XS, C_NEWSINK)
	draw_line(Vector2(x, r.position.y + 154.0), Vector2(x + w, r.position.y + 154.0), C_NEWSINK, 1.0)
	var kick := _tier_kicker(tier)
	var kw := _text_w(kick, T_SM, true) + 24.0
	var kr := Rect2(x, r.position.y + 176.0, kw, 32.0)
	_panel(kr, tcol.darkened(0.15) if tier != "mild" else C_NEWSINK, 3)
	_text_center(kr, kick, T_SM, C_PAPER, true)
	var title := (String(e["name"]) + (" (weakened)" if bool(ev.get("weak", false)) else "")).to_upper()
	var tsz := _fit(title, w, T_HERO + 14)
	_heavy(Vector2(x, r.position.y + 282.0), title, tsz, C_NEWSINK)
	var deck := _event_text(ev)
	var dy := r.position.y + 330.0
	for line in _news_lines(font_serif_italic, deck, w, T_LG):
		draw_string(font_serif_italic, Vector2(x, dy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, T_LG, C_NEWSINK)
		dy += 38.0
	draw_line(Vector2(x, dy - 10.0), Vector2(x + w, dy - 10.0), Color(C_NEWSINK, 0.5), 1.0)
	var col_w := (w - 40.0) * 0.5
	var cy := dy + 26.0
	var body := "Analysts say %s will shape trading this quarter. Firms are urged to plan around the change: %s Portfolio managers who adapt quickly are expected to come out ahead." % [String(e["name"]), deck.rstrip(".") + "."]
	var ly := cy
	for line in _news_lines(font_serif, body, col_w, T_SM):
		draw_string(font_serif, Vector2(x, ly), line, HORIZONTAL_ALIGNMENT_LEFT, -1, T_SM, Color(C_NEWSINK, 0.85))
		ly += 28.0
	draw_line(Vector2(x + col_w + 20.0, cy - 18.0), Vector2(x + col_w + 20.0, cy + 150.0), Color(C_NEWSINK, 0.4), 1.0)
	var bx := x + col_w + 40.0
	draw_string(font_bold, Vector2(bx, cy), "MARKET WATCH", HORIZONTAL_ALIGNMENT_LEFT, -1, T_XS, C_NEWSINK)
	draw_line(Vector2(bx, cy + 8.0), Vector2(bx + col_w, cy + 8.0), C_NEWSINK, 1.5)
	var by := cy + 40.0
	var tl := "Year %d target" % _year_of(round_n)
	draw_string(font_serif, Vector2(bx, by), tl, HORIZONTAL_ALIGNMENT_LEFT, -1, T_SM, C_NEWSINK)
	var tv := "%d" % _target_for(round_n)
	_heavy_right(bx + col_w - 26.0, by + 2.0, tv, T_LG, C_NEWSINK)
	_icon("vp", Vector2(bx + col_w - 10.0, by - 8.0), 10.0)
	by += 32.0
	var q := _quarter_in_year(round_n)
	var sub := "Checked at the end of this quarter" if q == D.QUARTERS_PER_YEAR else "Checked after quarter %d" % D.QUARTERS_PER_YEAR
	draw_string(font_serif_italic, Vector2(bx, by), sub, HORIZONTAL_ALIGNMENT_LEFT, col_w, T_XS, Color(C_NEWSINK, 0.7))
	by += 26.0
	draw_string(font_serif_italic, Vector2(bx, by), "%d Brand earned so far" % year_vp, HORIZONTAL_ALIGNMENT_LEFT, col_w, T_XS, Color(C_NEWSINK, 0.7))
	if not cond.is_empty():
		by += 36.0
		var gl := "Goal: " + _condition_text(cond)
		for line in _news_lines(font_bold, gl, col_w, T_XS):
			draw_string(font_bold, Vector2(bx, by), line, HORIZONTAL_ALIGNMENT_LEFT, -1, T_XS, c_warn.darkened(0.35))
			by += 22.0
	_button(Rect2(r.get_center().x - 170.0, r.end.y - 98.0, 340.0, 70.0), "Start quarter", _close_intro, true, C_NEWSINK, T_LG)

func _pile_rect(i: int) -> Rect2:
	return _market_slot(i)

func _card_back(r: Rect2) -> void:
	var k := r.size.y / 340.0
	_panel(r, Color.WHITE, int(16.0 * k))
	var inner := r.grow(-9.0 * k)
	_panel(inner, c_accent, int(11.0 * k))
	var light := c_accent.lightened(0.12)
	var step := 34.0 * k
	var y := inner.position.y + step * 0.5
	var row := 0
	while y < inner.end.y - step * 0.3:
		var x := inner.position.x + step * (0.5 if row % 2 == 0 else 1.0)
		while x < inner.end.x - step * 0.3:
			draw_colored_polygon(PackedVector2Array([Vector2(x, y - 7.0 * k), Vector2(x + 7.0 * k, y), Vector2(x, y + 7.0 * k), Vector2(x - 7.0 * k, y)]), light)
			x += step
		y += step
		row += 1
	var c := inner.get_center()
	draw_circle(c, 38.0 * k, Color.WHITE)
	_icon("briefcase", c, 22.0 * k)

func _pile_label(r: Rect2, text: String) -> void:
	var w := _text_w(text, T_SM, true) + 28.0
	var pr := Rect2(r.get_center().x - w * 0.5, r.end.y - 54.0, w, 36.0)
	_material(pr, Color.WHITE, 18)
	_text_center(pr, text, T_SM, c_ink, true)

func _draw_market() -> void:
	var kind := String(choice.get("kind", ""))
	var picking := kind == "replace_market" or (kind == "peek_swap" and int(choice["picked"]) >= 0)
	var frozen := bool(mods.get("market_frozen", false))
	for i in market.size():
		var r := _market_rect(i)
		var id := market[i]
		if id == "":
			_panel(r, c_hole, 16)
			if picking:
				_register(r, _on_market.bind(i))
			continue
		var glow := Color(0, 0, 0, 0)
		if picking:
			glow = Color(c_gold, 0.5 + 0.3 * sin(clock * 5.0))
		elif market_pick == i:
			glow = Color(c_accent, 0.8)
		elif choice.is_empty() and r.has_point(mouse) and ui_live:
			glow = Color(c_accent, 0.35)
		var med := _market_edition(i)
		_draw_card(r, id, null, "market", glow, _market_cost(i))
		_draw_edition(r, med)
		_corner_pockets(r)
		_price_tag(r, _market_cost(i), r.size.y / 340.0, true)
		var k := r.size.y / 340.0
		if frozen:
			_panel(r, Color(c_ice, 0.7), int(16.0 * k))
			_heavy_center(r, "Frozen", T_XL, Color("2b4d7a"))
		_register(r, _on_market.bind(i))
		if market_pick == i and choice.is_empty() and not frozen:
			_panel(r, Color(c_ink, 0.42), int(16.0 * k))
			var why := _buy_block(i)
			if why == "":
				var br := Rect2(r.get_center() - Vector2(84.0, 30.0) * k, Vector2(168.0, 60.0) * k)
				tut_rects["buy"] = br
				_button(br, "Buy", _buy_pick, true, c_accent, T_LG)
			else:
				var msg := why.replace(" this quarter", "")
				var mw := minf(_text_w(msg, T_SM, true) + 36.0, r.size.x - 24.0 * k)
				var size := T_SM
				while size > 13 and _text_w(msg, size, true) + 36.0 > mw:
					size -= 1
				var mr := Rect2(r.get_center() - Vector2(mw, 52.0 * k) * 0.5, Vector2(mw, 52.0 * k))
				_material(mr, Color.WHITE, int(26.0 * k))
				_text_center(mr, msg, size, c_bad, true)
		elif choice.is_empty():
			_tip_card(r, id, null, i)
	var d0 := _pile_rect(0)
	if deck.is_empty():
		_panel(d0, c_hole, 16)
	else:
		for n in mini(3, deck.size() - 1):
			var off := Vector2(4.0, 4.0) * (mini(3, deck.size() - 1) - n)
			_panel(Rect2(d0.position + off, d0.size), Color.WHITE.darkened(0.06 + n * 0.02), 16)
		_shadow(d0, 16)
		_card_back(d0)
	_pile_label(d0, "Deals %d" % deck.size())
	_tip(d0, "Businesses still to come up for sale.
%d passed-on deals, shuffled back in when the deck runs out." % discard.size())
	var d2 := _pile_rect(1)
	var why_refresh := _refresh_block()
	var can_refresh := why_refresh == "" and choice.is_empty() and phase == Phase.ACTION
	var hov := can_refresh and ui_live and d2.has_point(mouse)
	_panel(d2, Color(c_accent, 0.32 if hov else 0.2) if can_refresh else c_hole, 16, Color(c_accent.lightened(0.3), 0.8) if can_refresh else Color(1, 1, 1, 0.12), 2)
	var cc := d2.get_center() + Vector2(0, -30)
	draw_circle(cc, 34.0, Color.WHITE)
	_icon("swap", cc, 18.0)
	_text_center(Rect2(d2.position.x, cc.y + 44.0, d2.size.x, 34.0), "Scout deals", T_MD, c_light if can_refresh else c_light_muted, true)
	var sc := Vector2(d2.get_center().x, cc.y + 104.0)
	if can_refresh and _die_free(selected_die) and dice[selected_die].value == SCOUT_FACE:
		_panel(Rect2(sc - Vector2(27, 27), Vector2(54, 54)), Color(c_gold, 0.35 + 0.2 * sin(clock * 6.0)), 12)
	_die_body(sc, 42.0, SCOUT_FACE, Color.WHITE if can_refresh else Color(1, 1, 1, 0.45), c_ink if can_refresh else Color(c_ink, 0.4), Color(c_accent, 0.9) if can_refresh else Color(0, 0, 0, 0))
	if _refresh_price() > 0:
		_text_center(Rect2(d2.position.x, sc.y + 26.0, d2.size.x, 30.0), "+ %d Cash" % _refresh_price(), T_SM, c_accent.lightened(0.45) if can_refresh else c_light_muted, true)
	if can_refresh:
		_register(d2, _cash_refresh)
	_tip(d2, (why_refresh + "\n" if why_refresh != "" else "") + "Place a %d here to pass on every listed deal and see new ones." % SCOUT_FACE)

func _cost_explain(id: String) -> String:
	var c: Dictionary = D.CARDS[id]
	var t := String(c["type"])
	var v := int(c["value"])
	var filler := String(D.COST_FILLER.get(t, D.DEFAULT_FILLER))
	var s := "Costs %d: mostly %s, the rest %s" % [v + D.COST_EXTRA, D.RES_NAMES[t], D.RES_NAMES[filler]]
	if v >= D.GATE_VALUE and t != D.GATE_RES:
		s += ", plus 1 %s" % D.RES_NAMES[D.GATE_RES]
	return s + "."

func _sheet_rect() -> Rect2:
	var sheet := r_portfolio.grow(12.0)
	sheet.position.x -= BIND_STRIP
	sheet.size.x += BIND_STRIP
	return sheet

func _ring_ys() -> Array[float]:
	var sheet := _sheet_rect()
	var out: Array[float] = []
	for k in 3:
		out.append(sheet.position.y + sheet.size.y * (0.16 + k * 0.34))
	return out

const C_LEATHER := Color("5a3826")
const C_FOIL := Color("e6c36a")

func _foil(pos: Vector2, text: String, size: int) -> void:
	_heavy(pos + Vector2(1, 2), text, size, Color(0, 0, 0, 0.45))
	_heavy(pos, text, size, C_FOIL)

func _stitch_rect(st: Rect2, col: Color) -> void:
	var x := st.position.x + 18.0
	while x < st.end.x - 18.0:
		draw_line(Vector2(x, st.position.y), Vector2(x + 8.0, st.position.y), col, 2.0)
		draw_line(Vector2(x, st.end.y), Vector2(x + 8.0, st.end.y), col, 2.0)
		x += 14.0
	var y := st.position.y + 18.0
	while y < st.end.y - 18.0:
		draw_line(Vector2(st.position.x, y), Vector2(st.position.x, y + 8.0), col, 2.0)
		draw_line(Vector2(st.end.x, y), Vector2(st.end.x, y + 8.0), col, 2.0)
		y += 14.0

func _grain(r: Rect2, seed: int, density: float) -> void:
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = seed
	for i in int(r.size.x * r.size.y / density):
		var pt := Vector2(rng2.randf_range(r.position.x + 6.0, r.end.x - 6.0), rng2.randf_range(r.position.y + 6.0, r.end.y - 6.0))
		draw_rect(Rect2(pt, Vector2(1.6, 1.6)), Color(0, 0, 0, 0.12) if i % 3 else Color(1, 1, 1, 0.05))

func _draw_padfolio() -> void:
	var body := Rect2(p_market.position.x - 14.0, BODY_TOP - 8.0, p_supply.end.x - p_market.position.x + 28.0, p_market.size.y + 18.0)
	_panel(Rect2(body.position + Vector2(0, 12), body.size), Color(0, 0, 0, 0.5), 24)
	_panel(Rect2(body.position + Vector2(0, 5), body.size), C_LEATHER.darkened(0.5), 24)
	_grad_panel(body, 24.0, C_LEATHER.lightened(0.08), C_LEATHER.darkened(0.12))
	_grain(body, 19, 260.0)
	_panel(Rect2(body.position + Vector2(6, 3), Vector2(body.size.x - 12.0, 3.0)), Color(1, 1, 1, 0.12), 2)
	for flap: Rect2 in [p_market, p_supply]:
		var inner := flap.grow(-4.0)
		_panel(inner, C_LEATHER.darkened(0.22), 16)
		_grain(inner, 23, 180.0)
		_panel(inner, Color(0, 0, 0, 0), 16, Color(0, 0, 0, 0.3), 2)
		_stitch_rect(inner.grow(-8.0), Color("d9b77e", 0.4))
	for cx: float in [(p_market.end.x + p_portfolio.position.x) * 0.5, (p_portfolio.end.x + p_supply.position.x) * 0.5]:
		for k in 6:
			var w := 4.0 + k * 5.0
			draw_rect(Rect2(cx - w * 0.5, body.position.y + 4.0, w, body.size.y - 8.0), Color(0, 0, 0, 0.05))
		draw_line(Vector2(cx, body.position.y + 6.0), Vector2(cx, body.end.y - 6.0), Color(0, 0, 0, 0.55), 3.0)
		draw_line(Vector2(cx + 3.0, body.position.y + 6.0), Vector2(cx + 3.0, body.end.y - 6.0), Color(1, 1, 1, 0.08), 2.0)
	_stitch_rect(body.grow(-10.0), Color("d9b77e", 0.55))
	_foil(Vector2(p_market.position.x + PANEL_PAD, p_market.position.y + 44.0), "MARKET", T_MD)
	_foil(Vector2(p_portfolio.position.x + PANEL_PAD + SPINE - 8.0, p_portfolio.position.y + 44.0), "PORTFOLIO", T_MD)
	_foil(Vector2(p_supply.position.x + PANEL_PAD, p_supply.position.y + 44.0), "ASSETS", T_MD)

func _brass_button(r: Rect2, label: String, cb: Callable, enabled: bool, sub: String = "") -> void:
	var hovered := enabled and ui_live and r.has_point(mouse)
	var radius := int(minf(r.size.y * 0.5, 14.0))
	_panel(Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.4), radius)
	if enabled:
		_grad_panel(r, radius, Color("f2d483") if hovered else Color("e8c66a"), Color("b28a3a"))
	else:
		_grad_panel(r, radius, Color("8f877a"), Color("6d675d"))
	_panel(r, Color(0, 0, 0, 0), radius, Color("7a5a20") if enabled else Color("4f4a42"), 2)
	draw_line(r.position + Vector2(radius, 3), Vector2(r.end.x - radius, r.position.y + 3), Color(1, 1, 1, 0.45 if enabled else 0.15), 2.0)
	var ink := Color("3e2b10") if enabled else Color("3a362f")
	if sub == "":
		_text_center(r, label, T_MD, ink, true)
	else:
		_text_center(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.62)), label, T_MD, ink, true)
		_text_center(Rect2(r.position + Vector2(0, r.size.y * 0.52), Vector2(r.size.x, r.size.y * 0.4)), sub, T_XS, Color(ink, 0.8), true)
	if enabled:
		_register(r, cb)

func _corner_pockets(r: Rect2) -> void:
	var sz := 54.0
	for side in [0, 1]:
		var c := Vector2(r.position.x - 3.0 if side == 0 else r.end.x + 3.0, r.end.y + 3.0)
		var dx := sz if side == 0 else -sz
		var tri := PackedVector2Array([c, c + Vector2(dx, 0), c + Vector2(0, -sz)])
		var sh := PackedVector2Array()
		for p in tri:
			sh.append(p + Vector2(0, -3))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
		draw_colored_polygon(tri, C_LEATHER.darkened(0.08))
		draw_line(c + Vector2(dx, 0), c + Vector2(0, -sz), Color(1, 1, 1, 0.18), 2.0, true)
		var a := c + Vector2(dx * 0.82, -3.0)
		var b := c + Vector2(dx * 0.1, -sz * 0.75)
		var t := 0.0
		while t < 1.0:
			draw_line(a.lerp(b, t), a.lerp(b, minf(1.0, t + 0.08)), Color("d9b77e", 0.6), 1.5)
			t += 0.16

func _draw_binder_cover() -> void:
	var p := p_portfolio
	var sheet := _sheet_rect()
	_panel(sheet.grow(6.0), Color("2b221d"), 14)
	_panel(Rect2(sheet.position.x - 6.0, sheet.position.y - 6.0, 10.0, sheet.size.y + 12.0), Color(0, 0, 0, 0.25), 4)
	var bar := Rect2(p.position.x + 16.0, sheet.position.y + 20.0, 18.0, sheet.size.y - 40.0)
	_panel(Rect2(bar.position + Vector2(2, 3), bar.size), Color(0, 0, 0, 0.4), 6)
	_grad_panel(bar, 6.0, Color("d7dde3"), Color("8a939c"))
	draw_line(bar.position + Vector2(4, 8), Vector2(bar.position.x + 4.0, bar.end.y - 8.0), Color(1, 1, 1, 0.55), 2.0)
	for ry in [bar.position.y + 10.0, bar.end.y - 10.0]:
		draw_circle(Vector2(bar.get_center().x, ry), 3.5, Color("6e767e"))

func _draw_rings() -> void:
	var sheet := _sheet_rect()
	var bx := p_portfolio.position.x + 25.0
	for hy in _ring_ys():
		var hc := Vector2(sheet.position.x + 14.0, hy)
		draw_circle(hc, 8.0, Color(0, 0, 0, 0.6))
		var cx := (bx + hc.x + 12.0) * 0.5
		var rx := (hc.x + 12.0 - bx) * 0.5
		var pts := PackedVector2Array()
		for i in 41:
			var t := i / 40.0 * TAU
			pts.append(Vector2(cx + cos(t) * rx, hy + sin(t) * 13.0))
		var shadow := PackedVector2Array()
		for pt in pts:
			shadow.append(pt + Vector2(2, 4))
		draw_polyline(shadow, Color(0, 0, 0, 0.45), 8.0, true)
		draw_polyline(pts, Color("5f676f"), 8.0, true)
		draw_polyline(pts, Color("c3cad1"), 5.0, true)
		var hi := PackedVector2Array()
		for i in range(22, 37):
			var t := i / 40.0 * TAU
			hi.append(Vector2(cx + cos(t) * rx, hy + sin(t) * 13.0 - 1.0))
		draw_polyline(hi, Color(1, 1, 1, 0.75), 2.0, true)

func _draw_sleeve_page() -> void:
	var sheet := _sheet_rect()
	_panel(Rect2(sheet.position + Vector2(0, 5), sheet.size), Color(0, 0, 0, 0.25), 16)
	_panel(sheet, Color(Color("dfe7f1"), 0.09), 16, Color(1, 1, 1, 0.16), 2)
	draw_line(Vector2(sheet.position.x + BIND_STRIP + 2.0, sheet.position.y + 8.0), Vector2(sheet.position.x + BIND_STRIP + 2.0, sheet.end.y - 8.0), Color(1, 1, 1, 0.12), 2.0)
	_draw_rings()
	for i in board_slots:
		var r := _board_rect(i)
		var pocket := r.grow(CARD_GAP * 0.5 - 1.0)
		var pm := _slot_mod(i)
		if pm != "":
			var mc := Color(D.POCKET_MODS[pm]["color"])
			_panel(pocket, Color(mc, 0.22), 8, mc, 4)
		else:
			_panel(pocket, Color(1, 1, 1, 0.025), 8, Color(1, 1, 1, 0.13), 2)
		_pocket_lip(pocket)

func _pocket_lip(pocket: Rect2) -> void:
	var lip := Rect2(pocket.position + Vector2(4.0, 3.0), Vector2(pocket.size.x - 8.0, 7.0))
	_panel(lip, Color(0, 0, 0, 0.22), 3)
	var notch := Vector2(pocket.get_center().x, pocket.position.y + 4.0)
	var pts := PackedVector2Array()
	for a in 13:
		var t := a / 12.0 * PI
		pts.append(notch + Vector2(cos(t) * 26.0, sin(t) * 13.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.22))
	draw_polyline(pts, Color(1, 1, 1, 0.16), 1.5, true)

func _draw_flying() -> void:
	for slot in board_slots:
		var inst := board[slot]
		if inst == null or inst.place_t >= 1.0:
			continue
		var r := _board_rect(slot)
		var t := inst.place_t
		var pocket_top := r.grow(CARD_GAP * 0.5 - 1.0).position.y + 4.0
		var above := Vector2(r.position.x, pocket_top - r.size.y)
		var pos: Vector2
		var angle: float
		var sc := 1.0
		var inside := t >= 0.6
		if not inside:
			var u := t / 0.6
			u = u * u * (3.0 - 2.0 * u)
			pos = inst.place_from.lerp(above, u) + Vector2(0.0, -sin(u * PI) * 90.0)
			angle = lerpf(-0.2, 0.0, u)
			sc = 1.0 + sin(u * PI) * 0.06
		else:
			var u := (t - 0.6) / 0.4
			u = 1.0 - pow(1.0 - u, 3.0)
			pos = above.lerp(r.position, u)
			angle = 0.0
		var fr := Rect2(pos, r.size)
		var c := fr.get_center()
		_panel(Rect2(fr.position + Vector2(10, 18), fr.size), Color(0, 0, 0, 0.22 if not inside else 0.12), 16)
		card_xform = base_xform * Transform2D(angle, Vector2(sc, sc), 0.0, c) * Transform2D(0.0, -c)
		draw_set_transform_matrix(card_xform)
		_draw_card(fr, inst.id, inst, "board", Color(0, 0, 0, 0))
		_draw_edition(fr, inst.edition)
		card_xform = base_xform
		draw_set_transform_matrix(base_xform)
		if inside:
			var pocket := r.grow(CARD_GAP * 0.5 - 1.0)
			_pocket_lip(pocket)
			_sleeve_gloss(r)
			var sheen := clampf((t - 0.85) / 0.15, 0.0, 1.0)
			if sheen > 0.0 and sheen < 1.0:
				var x := r.position.x + r.size.x * (sheen * 1.4 - 0.2)
				draw_colored_polygon(PackedVector2Array([Vector2(x, r.position.y), Vector2(x + 26.0, r.position.y), Vector2(x - 40.0, r.end.y), Vector2(x - 66.0, r.end.y)]), Color(1, 1, 1, 0.18))

func _draw_edition(r: Rect2, ed: String) -> void:
	if ed == "":
		return
	var k := r.size.y / 340.0
	var radius := int(16.0 * k)
	var col := Color(D.EDITIONS[ed]["color"])
	var label := String(D.EDITIONS[ed]["name"]).to_upper()
	var lw := _text_w(label, T_XS, true) + 22.0
	var lr := Rect2(r.position.x + 12.0 * k, r.position.y + 88.0 * k, lw, 24.0)
	_panel(lr, col.darkened(0.15), 12, Color(1, 1, 1, 0.85), 2)
	_text_center(lr, label, T_XS, Color.WHITE, true)
	_tip(lr, "%s: %s." % [D.EDITIONS[ed]["name"], D.EDITIONS[ed]["text"]])
	match ed:
		"gold":
			_panel(r, Color(0, 0, 0, 0), radius, Color("e9c46a"), maxi(3, int(5.0 * k)))
			_panel(r.grow(-5.0 * k), Color(0, 0, 0, 0), radius - 4, Color(1, 0.95, 0.7, 0.8), 2)
			var t := fmod(clock * 0.35, 1.6) - 0.3
			var x := r.position.x + r.size.x * t
			var band := PackedVector2Array([Vector2(x, r.position.y), Vector2(x + 30.0 * k, r.position.y), Vector2(x - 60.0 * k, r.end.y), Vector2(x - 90.0 * k, r.end.y)])
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(band, _round_points(r, radius)):
				draw_colored_polygon(piece, Color(1, 0.92, 0.6, 0.22))
		"holo":
			var hues := [Color("ff7eb6"), Color("ffd77a"), Color("a6ff8f"), Color("7ff0e6"), Color("b8a3ff")]
			var clip := _round_points(r, radius)
			var off := fmod(clock * 40.0, 60.0 * k)
			var i := 0
			var x := r.position.x - r.size.y * 0.5 - 60.0 * k + off
			while x < r.end.x + 30.0 * k:
				var w := 30.0 * k
				var band := PackedVector2Array([Vector2(x, r.position.y), Vector2(x + w, r.position.y), Vector2(x + w + r.size.y * 0.5, r.end.y), Vector2(x + r.size.y * 0.5, r.end.y)])
				for piece: PackedVector2Array in Geometry2D.intersect_polygons(band, clip):
					draw_colored_polygon(piece, Color(hues[i % hues.size()], 0.14))
				x += w
				i += 1
			_panel(r, Color(0, 0, 0, 0), radius, Color(col.lightened(0.3), 0.9), maxi(3, int(4.0 * k)))
		"bluechip":
			_panel(r, Color(0, 0, 0, 0), radius, Color("d8e0ea"), maxi(3, int(5.0 * k)))
			var sc := Vector2(r.end.x - 22.0 * k, r.position.y + 96.0 * k)
			var sh := PackedVector2Array([sc + Vector2(-13, -14) * k, sc + Vector2(13, -14) * k, sc + Vector2(13, 2) * k, sc + Vector2(0, 16) * k, sc + Vector2(-13, 2) * k])
			draw_colored_polygon(sh, col.darkened(0.2))
			draw_polyline(sh + PackedVector2Array([sh[0]]), Color.WHITE, 2.0, true)
		"franchise":
			_panel(r, Color(0, 0, 0, 0), radius, col, maxi(3, int(4.0 * k)))

func _sleeve_gloss(r: Rect2) -> void:
	if SLEEVE_GLOSS <= 0.0:
		return
	var a := r.grow(-6.0)
	draw_colored_polygon(PackedVector2Array([a.position, a.position + Vector2(a.size.x * 0.62, 0), a.position + Vector2(0, a.size.y * 0.42)]), Color(1, 1, 1, SLEEVE_GLOSS))
	draw_colored_polygon(PackedVector2Array([a.position + Vector2(a.size.x * 0.8, 0), a.position + Vector2(a.size.x * 0.9, 0), a.position + Vector2(0, a.size.y * 0.66), a.position + Vector2(0, a.size.y * 0.58)]), Color(1, 1, 1, SLEEVE_GLOSS * 0.6))
	draw_line(a.position + Vector2(2, 0), a.position + Vector2(a.size.x - 2, 0), Color(1, 1, 1, SLEEVE_GLOSS * 2.0), 2.0)

func _draw_locked_slot(r: Rect2, slot: int) -> void:
	var cc := r.get_center()
	_panel(r, Color(Color("c9d3e0"), 0.1), 14)
	for k in 3:
		var fy := r.position.y + 40.0 + k * 110.0
		draw_line(Vector2(r.position.x + 14.0, fy + 60.0), Vector2(r.end.x - 14.0, fy), Color(1, 1, 1, 0.03), 26.0)
	var lock: Dictionary = slot_locks[slot]
	var freeing := String(choice.get("kind", "")) == "free_unlock"
	var why := _lock_block(slot)
	var can := why == "" or freeing
	var hov := can and r.has_point(mouse) and (ui_live or freeing)
	var col := c_accent
	if freeing:
		_panel(r, Color(c_gold, 0.25 + 0.12 * sin(clock * 5.0)), 14, c_gold, 3)
	elif can:
		_panel(r, Color(col, 0.3 if hov else 0.18), 14, Color(col.lightened(0.3), 0.8), 2)
	draw_circle(cc + Vector2(0, -50), 34.0, Color.WHITE)
	_icon("lock", cc + Vector2(0, -50), 18.0)
	var ic := ""
	match String(lock["kind"]):
		"pay":
			ic = String(lock["res"])
		"adjacent":
			ic = String(lock["type"])
	var text := _lock_text(lock)
	var ty := cc.y + 6.0
	if ic != "":
		draw_circle(Vector2(cc.x, ty + 4.0), 16.0, Color.WHITE)
		_res_icon(ic, Vector2(cc.x, ty + 4.0), 11.0)
		ty += 30.0
	_wrap(Vector2(r.position.x + 18.0, ty), text, r.size.x - 36.0, T_SM, c_light if can else c_light_muted, true, 2)
	_text_center(Rect2(r.position.x, r.end.y - 60.0, r.size.x, 30.0), ("Click to open" if can else "Locked"), T_SM, col.lightened(0.45) if can else c_light_muted, true)
	if freeing:
		_register(r, _on_board.bind(slot))
		_tip(r, "Open this lot for free")
	elif can:
		_register(r, _unlock_slot.bind(slot))
		_tip(r, "Open this lot (%s)." % text)
	else:
		_tip(r, "Locked lot. To open it: %s.\n%s" % [text.to_lower(), why])

func _draw_portfolio() -> void:
	_draw_binder_cover()
	var kind := String(choice.get("kind", ""))
	var warned := {}
	for j in range(1, forecast.size()):
		if j < forecast_visible or bool(forecast[j].get("revealed", false)):
			var u := _event_target_uid(forecast[j])
			if u >= 0 and not warned.has(u):
				warned[u] = "%s %s" % [_event_name(forecast[j]), "next quarter" if j == 1 else "in %d quarters" % j]
	var hover_uid := _event_target_uid(forecast[hover_forecast]) if hover_forecast > 0 else -1
	_draw_sleeve_page()
	for i in board_slots:
		var r := _board_rect(i)
		var inst := board[i]
		if not _slot_open(i):
			_draw_locked_slot(r, i)
			continue
		if inst == null:
			var placing := kind == "place" and _slot_accepts(i, market[int(choice["market"])])
			if placing:
				_panel(r, Color(c_accent, 0.3 + 0.12 * sin(clock * 5.0)), 14, Color(c_accent.lightened(0.35), 0.9), 3)
				var cc := r.get_center()
				var pc := Color(c_accent.lightened(0.5), 0.95)
				draw_line(cc - Vector2(14, 0), cc + Vector2(14, 0), pc, 3.0, true)
				draw_line(cc - Vector2(0, 14), cc + Vector2(0, 14), pc, 3.0, true)
			_sleeve_gloss(r)
			if placing:
				_register(r, _on_board.bind(i))
				_tip(r, "Place %s here" % _card_name(market[int(choice["market"])]))
			continue
		if inst.place_t < 1.0:
			continue
		var glow := Color(0, 0, 0, 0)
		var tip := ""
		if kind == "discard_for" and _slot_accepts(i, market[int(choice["market"])]):
			glow = Color(c_bad, 0.45 + 0.25 * sin(clock * 5.0))
			tip = "Sell off %s" % _card_name(inst.id)
		elif kind == "absorb" and _inst_by_uid(int(choice["uid"])) != null and _neighbors(_inst_by_uid(int(choice["uid"]))).has(inst):
			glow = Color(c_gold, 0.55 + 0.3 * sin(clock * 5.0))
			tip = "Absorb %s" % _card_name(inst.id)
		elif kind == "edition" and inst.edition == "":
			glow = Color(D.EDITIONS[String(choice["edition"])]["color"], 0.6 + 0.3 * sin(clock * 5.0))
			tip = "Make %s %s" % [_card_name(inst.id), D.EDITIONS[String(choice["edition"])]["name"]]
		elif kind == "meeting_upgrade":
			glow = Color(c_good, 0.55 + 0.3 * sin(clock * 5.0))
			tip = "Give %s +2 value" % _card_name(inst.id)
		elif kind == "upgrade" and _inst_by_uid(int(choice["uid"])) != null and _neighbors(_inst_by_uid(int(choice["uid"]))).has(inst):
			glow = Color(c_good, 0.55 + 0.3 * sin(clock * 5.0))
			tip = "Upgrade %s" % _card_name(inst.id)
		elif kind == "restore_dormant" and inst.dormant:
			glow = Color(c_gold, 0.55 + 0.3 * sin(clock * 5.0))
		elif hover_uid == inst.uid:
			glow = Color(c_bad, 0.6)
		elif selected_die >= 0 and choice.is_empty():
			var why := _block_reason(inst, selected_die)
			if why == "":
				glow = Color(c_good, 0.45 + 0.3 * sin(clock * 6.0))
			tip = why
		if inst.edition == "franchise":
			var back := Rect2(r.position + Vector2(10, -8), r.size)
			_panel(back, _tcol(_card_type(inst.id)).darkened(0.45), int(16.0 * r.size.y / 340.0), Color(D.EDITIONS["franchise"]["color"]), 3)
		_draw_card(r, inst.id, inst, "board", glow)
		_draw_edition(r, inst.edition)
		_sleeve_gloss(r)
		var tags: Array = []
		if int(mods.get("halve_output_uid", -1)) == inst.uid:
			tags.append(["Half output", c_bad])
		if int(mods.get("halve_value_uid", -1)) == inst.uid:
			tags.append(["Half Brand", c_bad])
		if warned.has(inst.uid):
			tags.append([warned[inst.uid], c_bad])
		for e: Dictionary in D.CARDS[inst.id].get("triggers", {}).get("after_quarter", []):
			if String(e["kind"]) == "mature":
				tags.append(["Matures in %d" % (int(e["quarters"]) - inst.age), c_accent])
		if _has_passive(inst, "repeat_same_die") and inst.ops == 1 and not inst.used_values.is_empty():
			tags.append(["Again on a %d" % _die_for(inst, inst.used_values[0]), c_accent])
		for t in tags.size():
			var label := String(tags[t][0])
			var w := _text_w(label, T_XS, true) + 24.0
			var tr := Rect2(r.get_center().x - w * 0.5, r.end.y - 14.0 - t * 34.0, w, 30.0)
			_panel(tr, tags[t][1], 15)
			_text_center(tr, label, T_XS, Color.WHITE, true)
		_register(r, _on_board.bind(i))
		if board_pick == i and choice.is_empty():
			var k := r.size.y / 340.0
			_panel(r, Color(c_ink, 0.42), int(16.0 * k))
			var br := Rect2(r.get_center() - Vector2(84.0, 36.0) * k, Vector2(168.0, 72.0) * k)
			_button(br, "Sell", _sell_pick, true, c_bad, T_LG, "+%d Cash" % _sell_price(inst))
		if tip == "" and not inst.pending.is_empty():
			tip = "Click or right-click to take the die back"
		if tip == "":
			_tip_card(r, inst.id, inst, -1)
		else:
			_tip(r, tip)
	_draw_slot_rules()
	_draw_flying()

func _draw_slot_rules() -> void:
	var kind := String(choice.get("kind", ""))
	for i in board_slots:
		var pm := _slot_mod(i)
		if pm == "":
			continue
		var r := _board_rect(i)
		var label: String = String(D.POCKET_MODS[pm]["name"]) + (" ×2 value" if pm == "gold" else " · any die")
		var w := _text_w(label, T_XS, true) + 24.0
		var chip := Rect2(r.get_center().x - w * 0.5, r.end.y - 34.0, w, 26.0)
		_panel(chip, Color(D.POCKET_MODS[pm]["color"]), 13, Color(1, 1, 1, 0.9), 2)
		_text_center(chip, label, T_XS, Color.WHITE, true)
		_tip(chip, "Gold pocket: a business here earns double its value when it operates." if pm == "gold" else "Express lane: a business here can operate with any single die.")
	if kind == "pocket":
		var mod := String(choice["mod"])
		for i in board_slots:
			var r := _board_rect(i)
			if _pocket_target_ok(i, mod):
				_panel(r.grow(4.0), Color(0, 0, 0, 0), 16, Color(c_gold, 0.6 + 0.3 * sin(clock * 5.0)), 4)
				_register(r, _on_board.bind(i))
				_tip(r, "Upgrade this lot")
	var pending := ""
	if kind == "place" or kind == "discard_for":
		pending = market[int(choice["market"])]
	for i in board_slots:
		var rule := _slot_rule(i)
		if String(rule["kind"]) == "any":
			continue
		var r := _board_rect(i)
		var label := _rule_text(rule)
		var w := _text_w(label, T_XS, true) + (40.0 if String(rule["kind"]) == "sector" else 22.0)
		var chip := Rect2(r.get_center().x - w * 0.5, r.position.y - 13.0, w, 26.0)
		var fits := pending == "" or _slot_accepts(i, pending)
		var col := _tcol(String(rule["type"])) if String(rule["kind"]) == "sector" else Color("5b6577")
		_panel(chip, col if fits else Color(col, 0.35), 13, Color(1, 1, 1, 0.85 if fits else 0.3), 2)
		var tx := chip.position.x + 11.0
		if String(rule["kind"]) == "sector":
			draw_circle(Vector2(tx + 8.0, chip.get_center().y), 10.0, Color.WHITE)
			_res_icon(String(rule["type"]), Vector2(tx + 8.0, chip.get_center().y), 7.0)
			tx += 22.0
		_text(Vector2(tx, chip.get_center().y + _vc(font_bold, T_XS)), label, T_XS, Color(1, 1, 1, 1.0 if fits else 0.55), true)
		_tip(chip, "This lot only accepts %s." % ("%s businesses" % D.TYPE_NAMES[rule["type"]] if String(rule["kind"]) == "sector" else "businesses with %s" % label.to_lower()))

func _draw_supply() -> void:
	var exchanging := String(choice.get("kind", "")) == "exchange"
	var give := String(choice.get("give", ""))
	var roles := {
		"cash": "Pays the rest of most business costs. Scouts deals and expands your portfolio. Unused dice become Cash at quarter end. Finance businesses cost mostly Cash.",
		"labor": "Services businesses cost mostly Labor. Finance businesses pay the rest in Labor. Some businesses turn Labor into Brand.",
		"equipment": "Industry businesses cost mostly Equipment. Every business worth 5+ also needs 1.",
		"intel": "Tech businesses cost mostly Intelligence. Also adds a die or rerolls.",
		"advertising": "Consumer businesses cost mostly Advertising. Some businesses turn it into big Brand.",
	}
	var mx := s_mat.position.x + 24.0
	_text(Vector2(mx, s_mat.position.y + 40.0), "YOURS TO SPEND", T_XS, Color("d8c091"), true)
	var count := "%d DICE" % dice.size()
	if extra_dice_next > 0:
		count += "  ·  +%d NEXT" % extra_dice_next
	if storage_cap > 0:
		count += "  ·  CAP %d EACH" % storage_cap
	_text_right(s_mat.end.x - 24.0, s_mat.position.y + 40.0, count, T_XS, Color("9fe0b0") if extra_dice_next > 0 else Color("d8c091"), true)
	var why_note := "%d base" % base_dice
	if not dice_notes.is_empty():
		why_note += ", " + ", ".join(dice_notes)
	_tip(Rect2(s_mat.position, Vector2(s_mat.size.x, 52.0)), "Dice and resources are both spent from here.\nDice this quarter: %s (always %d-%d)." % [why_note, min_dice, max_dice])
	_draw_dice_tray(_mat_tray())
	var felt := _mat_felt()
	var sy := felt.position.y + 120.0
	var sx := felt.position.x + 18.0
	while sx < felt.end.x - 18.0:
		draw_line(Vector2(sx, sy), Vector2(sx + 9.0, sy), Color(1, 1, 1, 0.22), 2.0)
		sx += 16.0
	for i in dice.size():
		var d := dice[i]
		var home := _die_home(i)
		var box := Rect2(home - Vector2(DIE_SIZE, DIE_SIZE) * 0.5, Vector2(DIE_SIZE, DIE_SIZE))
		if d.used or d.card_uid != -1:
			_panel(box, Color(0, 0, 0, 0.16), 16, Color(1, 1, 1, 0.08), 2)
			continue
		_ell(home + Vector2(3.0, DIE_SIZE * 0.42), DIE_SIZE * 0.5, DIE_SIZE * 0.13, 0.0, Color(0, 0, 0, 0.28))
		var sel := i == selected_die
		var lift := -10.0 if sel else (-4.0 if box.has_point(mouse) and ui_live else 0.0)
		if d.roll_t > 0.0:
			lift = -absf(sin(d.roll_t * 22.0)) * 16.0
		_die_body(home + Vector2(0, lift), DIE_SIZE, d.shown, Color.WHITE, c_ink, c_good if sel else Color(0, 0, 0, 0))
		_register(box.grow(6.0), _on_die.bind(i))
	for i in D.TYPES.size():
		var k: String = D.TYPES[i]
		var col := _res_col_rect(i)
		var cx := col.get_center().x
		var tc := _tcol(k)
		var pick := exchanging and k != give
		var over := storage_cap > 0 and _r(k) > storage_cap
		if exchanging and k == give:
			_panel(col.grow(-3.0), Color(tc, 0.28), 14)
		elif pick:
			_panel(col.grow(-3.0), Color(c_gold, 0.32 if col.has_point(mouse) and ui_live else 0.14), 14, Color(c_gold, 0.6), 2)
		var face := _res_face(k)
		var sock := Vector2(cx, col.position.y + 40.0)
		var usable := not exchanging and _res_die_block(k) == ""
		var lit := usable and _die_free(selected_die) and dice[selected_die].value == face
		if lit:
			_panel(Rect2(sock - Vector2(32, 32), Vector2(64, 64)), Color(c_gold, 0.4 + 0.2 * sin(clock * 6.0)), 14)
		_panel(Rect2(sock - Vector2(27, 27), Vector2(54, 54)), Color(0, 0, 0, 0.22), 12, Color(1, 1, 1, 0.12), 2)
		_die_body(sock, 44.0, face, Color.WHITE if usable else Color(1, 1, 1, 0.35), tc if usable else Color(c_ink, 0.3), Color(tc, 0.9) if usable else Color(0, 0, 0, 0))
		if usable:
			_register(Rect2(sock - Vector2(32, 32), Vector2(64, 64)), _res_die.bind(k))
			_tip(Rect2(sock - Vector2(31, 31), Vector2(62, 62)), "Place a %d here: gain 1 %s." % [face, D.RES_NAMES[k]])
		elif not exchanging:
			_tip(Rect2(sock - Vector2(31, 31), Vector2(62, 62)), "Dice slot: place a die showing %d to gain 1 %s." % [face, D.RES_NAMES[k]])
		var have := _r(k)
		var row_y := col.position.y + 104.0
		var cnt := str(have)
		var gw := 32.0 + 6.0 + _heavy_w(cnt, T_XL)
		var ic := Vector2(cx - gw * 0.5 + 16.0, row_y)
		draw_circle(ic, 16.0, Color.WHITE)
		_res_icon(k, ic, 11.0)
		_heavy(Vector2(ic.x + 22.0, row_y + _vc(font_heavy, T_XL)), cnt, T_XL, c_bad if over else c_light)
		if k == "intel" and _intel_locked():
			_text_center(Rect2(col.position.x, row_y + 24.0, col.size.x, 22.0), "LOCKED", T_XS, c_bad, true)
		var tip: String = "%s: %d. %s" % [D.RES_NAMES[k], have, roles[k]]
		if over:
			tip += "\nAbove the cap: %d will be lost at quarter end." % (have - storage_cap)
		var stack_r := Rect2(col.position.x, col.position.y + 74.0, col.size.x, 64.0)
		_tip(stack_r, tip)
		if pick:
			_register(stack_r, _on_chip.bind(k))
	var by := s_mat.end.y - 16.0 - 60.0
	var half := (s_mat.size.x - 48.0 - 12.0) * 0.5
	_brass_button(Rect2(mx, by, half, 60.0), "Exchange %d:1" % _rate(), _start_exchange, choice.is_empty() and phase == Phase.ACTION)
	var b3 := Rect2(mx + half + 12.0, by, half, 60.0)
	tut_rects["exchange"] = Rect2(mx, by, half, 60.0)
	tut_rects["reroll"] = b3
	_brass_button(b3, "Reroll all", _reroll_all, _reroll_block() == "", "%d Intelligence" % reroll_cost)
	_tip(b3, _reroll_block() if _reroll_block() != "" else "Reroll every unused die.")
	var top := s_mat.end.y + 28.0
	var bottom := s_end.position.y - 30.0
	var ph := minf(380.0, bottom - top)
	var pw := minf(420.0, s_mat.size.x - 40.0)
	tut_rects["scorepad"] = Rect2(s_mat.get_center().x - pw * 0.5, top + (bottom - top - ph) * 0.5, pw, ph)
	_draw_scorepad(tut_rects["scorepad"])
	var cp: Dictionary = mods.get("cost_plus", {})
	var notes: Array[String] = []
	for k: String in cp:
		notes.append("Businesses +%d %s" % [int(cp[k]), D.RES_NAMES[k]])
	if not notes.is_empty():
		_text_center(Rect2(felt.position.x, felt.end.y - 30.0, felt.size.x, 24.0), ", ".join(notes), T_SM, Color("ff9a8a"), true)
	var year_end := _is_year_end(round_n)
	var met := _round_vp() >= _target_for(round_n)
	_button(s_end, "End Year" if year_end else "End Quarter", _end_round, phase == Phase.ACTION and choice.is_empty(), c_accent if met or not year_end else c_ink, T_XL)

func _card_tip(id: String) -> String:
	var c: Dictionary = D.CARDS[id]
	var p := _base_pattern(id)
	var s := "%s (%s, %s, value %d: earns that much Brand each time it operates)\n%s" % [c["name"], D.TYPE_NAMES[c["type"]], String(c.get("rarity", "common")), int(c["value"]), c["text"]]
	if not p.is_empty():
		s += "\nOperate with: %s (%s)" % [_pattern_label(p), _pattern_rule(p)]
	return s

func _ability_lines(id: String) -> Array:
	var lines: Array = []
	var quick: Array = []
	for e: Dictionary in D.CARDS[id]["effects"]:
		var kind := String(e["kind"])
		if kind == "gain":
			var g: Dictionary = e["res"]
			for r: String in D.TYPES:
				if g.has(r):
					quick.append_array(["+%d" % int(g[r]), {"icon": r}])
			continue
		if kind == "vp":
			quick.append_array(["+%d" % int(e["amount"]), {"icon": "vp"}])
			continue
		var line: Array = []
		match kind:
			"convert":
				var pay: Dictionary = e["pay"]
				line = ["Pay"]
				for r: String in pay:
					line.append_array([str(int(pay[r])), {"icon": r}])
				line.append_array(["→", "+%d" % int(e["vp"]), {"icon": "vp"}])
			"vp_per":
				line = ["+%d" % int(e["amount"]), {"icon": "vp"}, "per"]
				match String(e["per"]):
					"board_type":
						line.append_array([{"icon": String(e["type"])}, "business"])
					"activations":
						line.append("business run")
					"distinct_types":
						line.append("sector run")
					"market_cards":
						line.append("deal")
					"empty_slots":
						line.append("empty slot")
			"extra_die":
				line = ["+%d" % int(e["amount"]), {"icon": "die"}, "next quarter"]
			"forecast_weaken":
				line = [{"icon": "outlook"}, "Weaken next event"]
			"forecast_delay":
				line = [{"icon": "outlook"}, "Delay next event"]
			"forecast_cancel":
				line = [{"icon": "outlook"}, "Cancel next event"]
			"forecast_reveal":
				line = [{"icon": "outlook"}, "Reveal the outlook"]
			"restore_dormant":
				line = [{"icon": "wrench"}, "Turn around a business"]
			"replace_market":
				line = [{"icon": "swap"}, "Replace a deal"]
			"peek_swap":
				line = [{"icon": "eye"}, "Peek %d, swap 1 in" % int(e.get("count", 3))]
			"gain_random_card":
				line = [{"icon": "card"}, "Acquire a random business"]
			"refresh_type":
				line = [{"icon": "swap"}, "Rescout one sector"]
			"refresh_market":
				line = [{"icon": "swap"}, "Scout new deals"]
		if not line.is_empty():
			lines.append(line)
	if not quick.is_empty():
		lines.push_front(quick)
	if lines.is_empty():
		lines.append(["No ability"])
	return lines

func _draw_token_line(pos: Vector2, tokens: Array, size: int, k: float) -> void:
	var x := pos.x
	var cy := pos.y
	for tok: Variant in tokens:
		if tok is Dictionary:
			_icon(String(tok["icon"]), Vector2(x + 11.0 * k, cy), 11.0 * k)
			x += 28.0 * k
		else:
			var txt := String(tok)
			var strong := txt.begins_with("+")
			var f := font_bold if strong else font
			draw_string(f, Vector2(x, cy + _vc(f, size)), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c_ink if strong else c_body)
			x += f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + (3.0 if strong else 7.0) * k

func _icon(kind: String, c: Vector2, rad: float) -> void:
	if D.TYPES.has(kind):
		_res_icon(kind, c, rad)
		return
	match kind:
		"vp":
			_star(c, rad, rad * 0.5, c_gold.darkened(0.08))
		"die":
			var dr := Rect2(c - Vector2(rad, rad) * 0.85, Vector2(rad, rad) * 1.7)
			_panel(dr, Color(0, 0, 0, 0), int(rad * 0.4), c_ink, 2)
			draw_circle(c, rad * 0.2, c_ink)
		"outlook":
			var col := Color("6f8aa6")
			draw_polyline(PackedVector2Array([c + Vector2(-rad, rad * 0.6), c + Vector2(-rad * 0.35, -rad * 0.05), c + Vector2(rad * 0.1, rad * 0.3), c + Vector2(rad * 0.7, -rad * 0.45)]), col, maxf(2.0, rad * 0.2), true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(rad, -rad * 0.75), c + Vector2(rad * 0.35, -rad * 0.68), c + Vector2(rad * 0.88, -rad * 0.12)]), col)
		"lock":
			var col := Color(c_ink, 0.45)
			draw_arc(c + Vector2(0, -rad * 0.15), rad * 0.45, PI, TAU, 12, col, maxf(2.0, rad * 0.18), true)
			draw_rect(Rect2(c + Vector2(-rad * 0.7, -rad * 0.15), Vector2(rad * 1.4, rad * 1.05)), col)
		"briefcase":
			var col := Color("6b4a32")
			var body := Rect2(c + Vector2(-rad, -rad * 0.45), Vector2(rad * 2.0, rad * 1.35))
			draw_rect(Rect2(c + Vector2(-rad * 0.38, -rad * 0.8), Vector2(rad * 0.76, rad * 0.4)), col, false, maxf(2.0, rad * 0.16))
			draw_rect(body, col)
			draw_line(Vector2(body.position.x, c.y), Vector2(body.end.x, c.y), col.darkened(0.3), maxf(1.5, rad * 0.1), true)
			draw_rect(Rect2(c + Vector2(-rad * 0.14, -rad * 0.1), Vector2(rad * 0.28, rad * 0.22)), c_gold)
		"wrench":
			var a := c + Vector2(-rad * 0.65, rad * 0.65)
			var b := c + Vector2(rad * 0.35, -rad * 0.35)
			var w := maxf(2.5, rad * 0.32)
			draw_line(a, b, c_good, w, true)
			draw_circle(a, w * 0.5, c_good)
			draw_circle(b, rad * 0.45, c_good)
			draw_circle(b + Vector2(rad * 0.22, -rad * 0.22), rad * 0.24, Color("fbf9f2"))
		"swap":
			var w := maxf(2.0, rad * 0.2)
			draw_line(c + Vector2(-rad, -rad * 0.35), c + Vector2(rad * 0.8, -rad * 0.35), c_accent, w, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(rad, -rad * 0.35), c + Vector2(rad * 0.4, -rad * 0.75), c + Vector2(rad * 0.4, rad * 0.05)]), c_accent)
			draw_line(c + Vector2(rad, rad * 0.4), c + Vector2(-rad * 0.8, rad * 0.4), c_accent, w, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-rad, rad * 0.4), c + Vector2(-rad * 0.4, 0.0), c + Vector2(-rad * 0.4, rad * 0.8)]), c_accent)
		"eye":
			_ell(c, rad, rad * 0.6, 0.0, c_ink)
			_ell(c, rad * 0.8, rad * 0.42, 0.0, Color.WHITE)
			draw_circle(c, rad * 0.32, c_ink)
		"card":
			var cr := Rect2(c - Vector2(rad * 0.7, rad), Vector2(rad * 1.4, rad * 2.0))
			_panel(cr, Color.WHITE, int(rad * 0.25), c_ink, 2)
			draw_rect(Rect2(cr.position + Vector2(2, 2), Vector2(cr.size.x - 4, rad * 0.6)), Color(c_good, 0.6))
		"check":
			draw_circle(c, rad, c_good)
			draw_polyline(PackedVector2Array([c + Vector2(-0.5, 0) * rad, c + Vector2(-0.15, 0.42) * rad, c + Vector2(0.55, -0.42) * rad]), Color.WHITE, maxf(2.0, rad * 0.22), true)

func _material(r: Rect2, col: Color, radius: int) -> void:
	_panel(Rect2(r.position + Vector2(0, 7), r.size), Color(c_shadow, 0.07), radius)
	_panel(Rect2(r.position + Vector2(0, 3), r.size), Color(c_shadow, 0.1), radius)
	_panel(r, col, radius)

func _award_icons(id: String) -> Array[String]:
	var c: Dictionary = D.CARDS[id]
	var found := {}
	var lists: Array = [c.get("effects", [])]
	var trig: Dictionary = c.get("triggers", {})
	for h in trig:
		lists.append(trig[h])
	for list: Array in lists:
		for e: Dictionary in list:
			match String(e["kind"]):
				"gain":
					for r in (e["res"] as Dictionary):
						found[r] = true
				"gain_per", "gain_ctx":
					found[String(e["res"])] = true
				"vp", "vp_per", "vp_if", "convert":
					found["vp"] = true
	if c.get("passive", {}).has("prevent_distress"):
		found["vp"] = true
	var out: Array[String] = []
	for r: String in D.TYPES:
		if found.has(r):
			out.append(r)
	if found.has("vp"):
		out.append("vp")
	return out

func _price_tag(card: Rect2, cost: Dictionary, k: float, check: bool) -> void:
	var size := int(21.0 * k)
	var rad := 10.0 * k
	var th := 38.0 * k
	var pt := 18.0 * k
	var tw := _tokens_w(cost, rad, size) + pt + 30.0 * k
	var tag := Rect2(card.get_center().x - tw * 0.5 + pt * 0.3, card.end.y - 25.0 * k, tw, th)
	var c := tag.get_center()
	draw_set_transform_matrix(card_xform * Transform2D(-0.035, Vector2.ONE, 0.0, c) * Transform2D(0.0, -c))
	var shape := PackedVector2Array([tag.position + Vector2(pt, 0), Vector2(tag.end.x - 3.0 * k, tag.position.y), Vector2(tag.end.x, tag.position.y + 3.0 * k), Vector2(tag.end.x, tag.end.y - 3.0 * k), Vector2(tag.end.x - 3.0 * k, tag.end.y), Vector2(tag.position.x + pt, tag.end.y), tag.position + Vector2(0, th * 0.5)])
	var sh := PackedVector2Array()
	for p in shape:
		sh.append(p + Vector2(2.0, 5.0) * k)
	draw_colored_polygon(sh, Color(0, 0, 0, 0.3))
	draw_colored_polygon(shape, Color("fbf6e4"))
	var outline := shape.duplicate()
	outline.append(shape[0])
	draw_polyline(outline, Color("c9b98e"), maxf(1.0, 1.5 * k), true)
	draw_line(Vector2(tag.position.x + pt + 4.0 * k, tag.position.y + 3.0 * k), Vector2(tag.end.x - 5.0 * k, tag.position.y + 3.0 * k), Color(1, 1, 1, 0.8), maxf(1.0, 1.5 * k))
	var hole := tag.position + Vector2(pt * 0.8, th * 0.5)
	draw_circle(hole, 5.0 * k, Color("b08a3a"))
	draw_circle(hole, 3.6 * k, Color("e3c77a"))
	draw_circle(hole, 2.2 * k, Color("6b5420"))
	_tokens(tag.position.x + pt + 12.0 * k, c.y, cost, rad, size, check)
	draw_set_transform_matrix(card_xform)

func _tokens_w(cost: Dictionary, rad: float, size: int) -> float:
	var w := 0.0
	for r: String in D.TYPES:
		if cost.has(r):
			w += _heavy_w(str(int(cost[r])), size) + 3.0 + rad * 2.0 + 14.0
	return maxf(0.0, w - 14.0)

func _draw_card(r: Rect2, id: String, inst: CardInst, where: String, glow: Color, cost_override: Dictionary = {}) -> void:
	var c: Dictionary = D.CARDS[id]
	var t := String(c["type"])
	var tcol := _tcol(t)
	var k := r.size.y / 340.0
	if inst != null and inst.shake > 0.0:
		r.position.x += sin(clock * 70.0) * 9.0 * inst.shake
	var radius := int(16.0 * k)
	if glow.a > 0.0:
		_panel(r.grow(7.0), glow, radius + 6)
	_shadow(r, radius, 6.0 * k)
	var dark := tcol.darkened(0.35)
	var rarity := String(c.get("rarity", "common"))
	var inner := r.grow(-9.0 * k)
	var ir := int(10.0 * k)
	match card_style:
		0:
			_grad_panel(r, radius, tcol.darkened(0.2), tcol.darkened(0.5))
			_grad_panel(inner, ir, tcol.lerp(Color.WHITE, 0.5), tcol.lerp(Color.WHITE, 0.8))
			_panel(inner, Color(0, 0, 0, 0), ir, Color(1, 1, 1, 0.6), maxi(1, int(2.0 * k)))
		1:
			_panel(r, dark, radius)
			inner = r.grow(-7.0 * k)
			_grad_panel(inner, ir, tcol.lerp(Color.WHITE, 0.45), tcol.darkened(0.08))
			var sheen := PackedVector2Array([inner.position + Vector2(inner.size.x * 0.55, 0), inner.position + Vector2(inner.size.x * 0.85, 0), inner.position + Vector2(inner.size.x * 0.35, inner.size.y * 0.6), inner.position + Vector2(inner.size.x * 0.05, inner.size.y * 0.6)])
			draw_colored_polygon(sheen, Color(1, 1, 1, 0.12))
		_:
			_panel(r, dark, radius)
			if D.RARITY_COLORS.has(rarity):
				var foil := Color("e9c46a") if rarity == "rare" else Color("c9d1da")
				_panel(r.grow(-4.0 * k), Color(0, 0, 0, 0), radius - int(3.0 * k), foil, maxi(2, int(3.0 * k)))
			_panel(inner, tcol.lerp(Color.WHITE, 0.62), ir)
			var step := 13.0 * k
			var dot := Color(tcol.darkened(0.25), 0.13)
			var y := inner.position.y + ir
			var row := 0
			while y < inner.end.y - ir:
				var x := inner.position.x + ir + (step * 0.5 if row % 2 == 1 else 0.0)
				while x < inner.end.x - ir:
					draw_circle(Vector2(x, y), 1.7 * k, dot)
					x += step
				y += step
				row += 1
	var pad := 8.0 * k
	var bar := Rect2(inner.position + Vector2(pad, pad), Vector2(inner.size.x - pad * 2.0, 70.0 * k))
	var lines := _ability_lines(id)
	var value := _effective_value(inst) if inst != null else int(c["value"])
	var strip_h := 100.0 * k
	var strip := Rect2(inner.position.x, inner.end.y - 10.0 * k - strip_h, inner.size.x, strip_h)
	_draw_art(inner, id, tcol, bar.end.y - 24.0 * k, strip.position.y + 10.0 * k)
	match card_style:
		0:
			_material(bar, Color.WHITE, int(12.0 * k))
			_panel(bar, Color(0, 0, 0, 0), int(12.0 * k), Color(dark, 0.55), maxi(1, int(2.0 * k)))
		1:
			_material(bar, Color(1, 1, 1, 0.9), int(bar.size.y * 0.5))
		_:
			_material(bar, Color.WHITE, int(12.0 * k))
			_panel_corners(Rect2(bar.position.x, bar.end.y - 5.0 * k, bar.size.x, 5.0 * k), tcol, 0, 0, int(12.0 * k), int(12.0 * k))
	var badge := bar.position + Vector2(24.0 * k, bar.size.y * 0.5)
	_star(badge + Vector2(0, 2.0 * k), 25.0 * k, 15.0 * k, Color(0, 0, 0, 0.18))
	_star(badge, 25.0 * k, 15.0 * k, c_gold.darkened(0.3))
	_star(badge, 22.0 * k, 13.0 * k, c_gold)
	_heavy_center(Rect2(badge - Vector2(16, 15) * k, Vector2(32, 32) * k), str(value), int(18.0 * k), c_ink)
	var nx := bar.position.x + 54.0 * k
	var name := String(c["name"])
	var nsz := _fit(name, bar.end.x - 26.0 * k - nx, int(22.0 * k))
	if D.RARITY_COLORS.has(rarity):
		var gc := Vector2(bar.end.x - 14.0 * k, bar.position.y + 14.0 * k)
		var gs := 7.0 * k
		draw_colored_polygon(PackedVector2Array([gc + Vector2(0, -gs), gc + Vector2(gs, 0), gc + Vector2(0, gs), gc + Vector2(-gs, 0)]), Color(D.RARITY_COLORS[rarity]))
	_heavy(Vector2(nx, bar.position.y + 30.0 * k), name, nsz, c_ink)
	var ax := nx
	for icon in _award_icons(id):
		var ac := Vector2(ax + 12.0 * k, bar.position.y + 52.0 * k)
		draw_circle(ac, 13.0 * k, Color(_tcol(icon) if icon != "vp" else c_gold, 0.24))
		_icon(icon, ac, 10.5 * k)
		ax += 30.0 * k
	var desc := Rect2(inner.position.x + pad, strip.position.y, inner.size.x - pad * 2.0, inner.end.y - pad - strip.position.y)
	match card_style:
		0:
			_material(desc, Color("fbf9f2"), int(10.0 * k))
			_panel(desc, Color(0, 0, 0, 0), int(10.0 * k), Color(dark, 0.4), maxi(1, int(2.0 * k)))
		1:
			_material(desc, Color(1, 1, 1, 0.92), int(12.0 * k))
		_:
			desc = strip
			_material(strip, Color("fbf9f2"), 0)
			draw_line(strip.position, Vector2(strip.end.x, strip.position.y), tcol, 3.0 * k)
	var tx := desc.position.x + 10.0 * k
	var tw := desc.size.x - 20.0 * k
	var lh := 26.0 * k
	var top := strip.position.y + 26.0 * k
	var ly := top + (desc.end.y - 4.0 * k - top - lines.size() * lh) * 0.5 + lh * 0.5
	if c.has("short"):
		_rich_wrap(Vector2(tx, top - 4.0 * k), String(c["short"]), tw, int(15.0 * k), 3)
	else:
		for line: Array in lines:
			_draw_token_line(Vector2(tx, ly), line, int(17.0 * k), k * 0.9)
			ly += lh
	var p := _effective_pattern(inst) if inst != null else _base_pattern(id)
	var need := _dice_needed(p)
	if where != "board" and where != "market":
		_price_tag(r, _cost(id) if cost_override.is_empty() else cost_override, k, false)
	var chip_h := 36.0 * k
	var sock := 44.0 * k
	var label := _pattern_short(p)
	var lsz := int(19.0 * k)
	var chip := Rect2(inner.position.x + pad, strip.position.y - chip_h * 0.62, _heavy_w(label, lsz) + 46.0 * k, chip_h)
	_material(chip, Color.WHITE, int(chip_h * 0.5))
	if need > 0:
		_icon("die", chip.position + Vector2(19.0 * k, chip_h * 0.5), 9.0 * k)
		_heavy(Vector2(chip.position.x + 34.0 * k, chip.get_center().y + _vc(font_heavy, lsz)), label, lsz, c_ink)
	else:
		_heavy(Vector2(chip.position.x + 14.0 * k, chip.get_center().y + _vc(font_heavy, lsz)), label, lsz, c_muted)
	for j in need:
		var sr := Rect2(inner.end.x - pad - (need - j) * sock - (need - 1 - j) * 6.0 * k, strip.position.y - sock * 0.62, sock, sock)
		_material(sr, Color.WHITE, int(10.0 * k))
		_panel(sr, Color(0, 0, 0, 0), int(10.0 * k), Color(tcol, 0.5), 2)
		if inst == null:
			continue
		if j < inst.pending.size():
			_die_body(sr.get_center(), sr.size.x * 0.84, dice[inst.pending[j]].value, Color.WHITE, c_ink, tcol)
		elif inst.activated and j < inst.used_values.size():
			_die_body(sr.get_center(), sr.size.x * 0.84, inst.used_values[j], c_bg, Color(c_ink, 0.4))
	if inst != null and inst.flash > 0.0:
		_panel(r, Color(Color("fff4cf"), inst.flash * 0.45), radius)
	if inst != null and inst.activated and not inst.dormant:
		var cc := r.position + Vector2(r.size.x - 4.0 * k, 4.0 * k)
		draw_circle(cc + Vector2(0, 2), 18.0 * k, Color(c_shadow, 0.15))
		draw_circle(cc, 18.0 * k, Color.WHITE)
		_icon("check", cc, 14.0 * k)
	if inst != null and inst.dormant:
		_panel(r, Color(c_bg, 0.9), radius)
		var pw := inner.size.x - 24.0 * k
		var pill := Rect2(r.get_center() - Vector2(pw, 80.0 * k) * 0.5, Vector2(pw, 80.0 * k))
		_material(pill, Color.WHITE, int(18.0 * k))
		_heavy_center(Rect2(pill.position, Vector2(pw, 48.0 * k)), "Distressed", int(24.0 * k), c_ink)
		_text_center(Rect2(pill.position + Vector2(0, 42.0 * k), Vector2(pw, 28.0 * k)), "Any die turns it around", int(15.0 * k), c_muted, true)

func _round_points(r: Rect2, radius: float) -> PackedVector2Array:
	var rad := minf(radius, minf(r.size.x, r.size.y) * 0.5)
	var centers := [Vector2(r.end.x - rad, r.end.y - rad), Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad), Vector2(r.end.x - rad, r.position.y + rad)]
	var pts := PackedVector2Array()
	for q in 4:
		for i in 7:
			var a := (q + i / 6.0) * PI * 0.5
			pts.append(centers[q] + Vector2(cos(a), sin(a)) * rad)
	return pts

func _grad_panel(r: Rect2, radius: float, top: Color, bottom: Color) -> void:
	var pts := _round_points(r, radius)
	var cols := PackedColorArray()
	for pt in pts:
		cols.append(top.lerp(bottom, clampf((pt.y - r.position.y) / r.size.y, 0.0, 1.0)))
	draw_polygon(pts, cols)

func _draw_card_bg(r: Rect2, t: String, id: String, tcol: Color, top: float, ground: float, k: float, focus: Vector2) -> void:
	var cx := focus.x
	var cy := focus.y
	var br := minf(r.size.x * 0.4, (ground - top) * 0.5)
	match card_bg:
		1:
			var clip := _round_points(r, 10.0 * k)
			var reach := r.size.length()
			var n := 20
			for i in range(0, n, 2):
				var a0 := i * TAU / n
				var a1 := (i + 1) * TAU / n
				var ray := PackedVector2Array([Vector2(cx, cy), Vector2(cx, cy) + Vector2(cos(a0), sin(a0)) * reach, Vector2(cx, cy) + Vector2(cos(a1), sin(a1)) * reach])
				for piece: PackedVector2Array in Geometry2D.intersect_polygons(ray, clip):
					draw_colored_polygon(piece, Color(1, 1, 1, 0.3))
			draw_circle(Vector2(cx, cy), br * 0.85, Color(1, 1, 1, 0.45))
			_dome(Vector2(cx, r.end.y), r.size.x * 0.46, 22.0 * k, tcol.lerp(Color.WHITE, 0.42))
		2:
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = hash(id)
			draw_circle(Vector2(r.position.x + r.size.x * 0.24, top + 34.0 * k), 13.0 * k, Color(1, 1, 1, 0.75))
			_ell(Vector2(r.position.x + r.size.x * 0.72, top + 30.0 * k), 22.0 * k, 7.0 * k, 0.0, Color(1, 1, 1, 0.7))
			_ell(Vector2(r.position.x + r.size.x * 0.64, top + 36.0 * k), 14.0 * k, 5.0 * k, 0.0, Color(1, 1, 1, 0.7))
			var far := Color(tcol.lerp(Color.WHITE, 0.38), 0.75)
			var x := r.position.x + 6.0 * k
			while x < r.end.x - 10.0 * k:
				var w := rng2.randf_range(14.0, 26.0) * k
				var h := rng2.randf_range(36.0, 96.0) * k
				w = minf(w, r.end.x - 6.0 * k - x)
				draw_rect(Rect2(x, ground - h, w, h), far)
				var wy := ground - h + 6.0 * k
				while wy < ground - 10.0 * k:
					draw_rect(Rect2(x + 3.0 * k, wy, 3.0 * k, 3.0 * k), Color(1, 1, 1, 0.35))
					if w > 12.0 * k:
						draw_rect(Rect2(x + w - 6.0 * k, wy, 3.0 * k, 3.0 * k), Color(1, 1, 1, 0.35))
					wy += 9.0 * k
				x += w + rng2.randf_range(1.0, 4.0) * k
			draw_rect(Rect2(r.position.x, ground - 16.0 * k, r.size.x, 16.0 * k), tcol.lerp(Color.WHITE, 0.3))
		3:
			_panel(r, Color("f4eedf"), int(10.0 * k))
			var step := 9.0 * k
			var y := r.position.y + 10.0 * k
			while y < r.end.y - 10.0 * k:
				var x := r.position.x + 10.0 * k
				while x < r.end.x - 10.0 * k:
					draw_rect(Rect2(x, y, 1.2 * k, 1.2 * k), Color(tcol, 0.12))
					x += step
				y += step
			var win := Rect2(r.position.x + 8.0 * k, top + 8.0 * k, r.size.x - 16.0 * k, ground - top + 4.0 * k)
			_grad_panel(win, 9.0 * k, tcol.lerp(Color.WHITE, 0.78), tcol.lerp(Color.WHITE, 0.45))
			draw_rect(Rect2(win.position.x, ground - 14.0 * k, win.size.x, 18.0 * k), tcol.lerp(Color.WHITE, 0.25))
			_panel(win, Color(0, 0, 0, 0), int(9.0 * k), Color(tcol.darkened(0.35), 0.6), maxi(1, int(2.0 * k)))
		4:
			var step := 30.0 * k
			var y := r.position.y + 18.0 * k
			var row := 0
			while y < r.end.y - 12.0 * k:
				var x := r.position.x + 18.0 * k + (step * 0.5 if row % 2 == 1 else 0.0)
				while x < r.end.x - 12.0 * k:
					_res_icon(t, Vector2(x, y), 6.0 * k)
					x += step
				y += step
				row += 1
			_grad_panel(r, 10.0 * k, Color(tcol.lerp(Color.WHITE, 0.5), 0.8), Color(tcol.lerp(Color.WHITE, 0.8), 0.8))
			draw_circle(Vector2(cx, cy), br, tcol.lerp(Color.WHITE, 0.82))
			_dome(Vector2(cx, r.end.y), r.size.x * 0.46, 22.0 * k, tcol.lerp(Color.WHITE, 0.42))
		_:
			draw_circle(Vector2(cx, cy), br, tcol.lerp(Color.WHITE, 0.78))
			_dome(Vector2(cx, r.end.y), r.size.x * 0.46, 22.0 * k, tcol.lerp(Color.WHITE, 0.42))

func _ell(c: Vector2, rx: float, ry: float, rot: float, col: Color, n: int = 18) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := i * TAU / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	draw_colored_polygon(pts, col)

func _dome(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + i * PI / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)

func _draw_art(r: Rect2, id: String, tcol: Color, top: float, ground: float) -> void:
	var a: Dictionary = D.CARDS[id].get("art", {})
	var k := r.size.y / 340.0
	var s := minf((ground - top) / 160.0, r.size.x / 150.0)
	var origin := Vector2(r.get_center().x - 80.0 * s, ground - 160.0 * s)
	var art := _art_entry(id)
	var tex: Texture2D = art.get("tex")
	var offset := Vector2(0.0, -12.0)
	var focus := Vector2(r.get_center().x, top + (ground - top) * 0.5)
	var fit := 1.0
	if tex != null:
		var box: Rect2 = art["box"]
		var room := 140.0 - (top + 28.0 * k - origin.y) / s
		fit = minf(1.0, room / box.size.y)
		offset = Vector2(80.0 - box.get_center().x * fit, 140.0 - box.end.y * fit)
		focus = origin + Vector2(80.0, 140.0 - box.size.y * fit * 0.5) * s
	_draw_card_bg(r, String(D.CARDS[id]["type"]), id, tcol, top, ground, k, focus)
	draw_set_transform_matrix(card_xform * Transform2D(0.0, Vector2(s, s), 0.0, origin))
	if tex != null:
		draw_texture_rect(tex, Rect2(offset, Vector2(160.0, 160.0) * fit), false)
	else:
		_draw_business(a)
	draw_set_transform_matrix(card_xform)

func _art_entry(id: String) -> Dictionary:
	var key := "%d/%s" % [art_set, id]
	if art_cache.has(key):
		return art_cache[key]
	var entry := {}
	for dir: String in [ART_DIRS[art_set], ART_DIRS[0]]:
		var path := dir + id + ".svg"
		if FileAccess.file_exists(path):
			var img := Image.new()
			if img.load_svg_from_string(FileAccess.get_file_as_string(path), ART_SCALE) == OK:
				entry["box"] = _art_box(img)
				img.generate_mipmaps()
				entry["tex"] = ImageTexture.create_from_image(img)
				break
	art_cache[key] = entry
	return entry

func _art_box(img: Image) -> Rect2:
	var lo := Vector2i(img.get_width(), img.get_height())
	var hi := Vector2i(-1, -1)
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			if img.get_pixel(x, y).a > 0.3:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	if hi.x < 0:
		return Rect2(0.0, 0.0, 160.0, 160.0)
	return Rect2(Vector2(lo) / ART_SCALE, Vector2(hi - lo + Vector2i(2, 2)) / ART_SCALE)

func _windows(r: Rect2, cols: int, rows: int, col: Color) -> void:
	var cw := r.size.x / cols
	var rh := r.size.y / rows
	for i in cols:
		for j in rows:
			draw_rect(Rect2(r.position.x + i * cw + 2.5, r.position.y + j * rh + 2.5, cw - 5.0, rh - 5.0), col)

func _awning(r: Rect2, col: Color) -> void:
	var n := maxi(4, roundi(r.size.x / 14.0))
	var sw := r.size.x / n
	for i in n:
		var stripe := col if i % 2 == 0 else Color.WHITE
		draw_rect(Rect2(r.position.x + i * sw, r.position.y, sw, r.size.y), stripe)
		draw_circle(Vector2(r.position.x + (i + 0.5) * sw, r.end.y), sw * 0.5, stripe)

func _slats(r: Rect2, col: Color) -> void:
	draw_rect(r, col)
	var y := r.position.y + 6.0
	while y < r.end.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), col.darkened(0.18), 1.5)
		y += 7.0

func _draw_business(a: Dictionary) -> void:
	var body := Color(a.get("body", "d9d4c7"))
	var accent := Color(a.get("accent", "4f8a5b"))
	var glass := Color("bcd6e6")
	var dark := Color("3a4450")
	match String(a.get("form", "office")):
		"office":
			var w := float(a.get("width", 90))
			var h := float(a.get("height", 110))
			var x := 80.0 - w * 0.5
			var top := 158.0 - h
			var rows := maxi(1, floori((h - 44.0) / 20.0))
			draw_rect(Rect2(x, top, w, h), body)
			draw_rect(Rect2(x - 4, top - 6, w + 8, 8), body.darkened(0.25))
			_windows(Rect2(x + 8, top + 10, w - 16, rows * 20.0), int(a.get("cols", 3)), rows, glass)
			draw_rect(Rect2(x, 128, w, 4), body.darkened(0.15))
			draw_rect(Rect2(71, 134, 18, 24), dark)
		"shop":
			var w := float(a.get("width", 104))
			var h := float(a.get("height", 90))
			var x := 80.0 - w * 0.5
			var top := 158.0 - h
			var ay := top + 28.0
			var wy := ay + 24.0
			draw_rect(Rect2(x, top, w, h), body)
			draw_rect(Rect2(x - 3, top - 4, w + 6, 6), body.darkened(0.25))
			draw_rect(Rect2(x + 10, top + 7, w - 20, 16), Color.WHITE)
			draw_rect(Rect2(x + 16, top + 13, w - 32, 4), accent)
			_awning(Rect2(x - 4, ay, w + 8, 12), accent)
			draw_rect(Rect2(x + 8, wy, w * 0.52 - 8, 148 - wy), glass)
			draw_rect(Rect2(x + w * 0.62, wy, w * 0.28, 158 - wy), dark)
			draw_circle(Vector2(x + w * 0.62 + 5, wy + (158 - wy) * 0.55), 1.8, c_gold)
		"stand":
			var wood := Color("c9965f")
			draw_line(Vector2(42, 112), Vector2(42, 64), wood.darkened(0.3), 4.0, true)
			draw_line(Vector2(118, 112), Vector2(118, 64), wood.darkened(0.3), 4.0, true)
			_awning(Rect2(34, 52, 92, 14), accent)
			draw_rect(Rect2(36, 110, 88, 48), wood)
			draw_rect(Rect2(36, 110, 88, 6), wood.darkened(0.2))
			draw_rect(Rect2(50, 124, 60, 22), Color.WHITE)
			draw_rect(Rect2(56, 132, 48, 6), accent)
			_ell(Vector2(64, 98), 9, 12, 0.0, Color(accent, 0.85))
			draw_rect(Rect2(86, 96, 10, 14), glass)
			draw_rect(Rect2(100, 98, 9, 12), glass)
		"van":
			draw_colored_polygon(PackedVector2Array([Vector2(24, 146), Vector2(24, 96), Vector2(102, 96), Vector2(122, 116), Vector2(136, 120), Vector2(136, 146)]), Color("f4f4f2"))
			draw_colored_polygon(PackedVector2Array([Vector2(104, 102), Vector2(118, 117), Vector2(104, 117)]), glass)
			draw_rect(Rect2(24, 124, 112, 7), accent)
			draw_rect(Rect2(34, 104, 54, 14), Color(accent, 0.25))
			for wx: float in [50.0, 112.0]:
				draw_circle(Vector2(wx, 146), 12, dark)
				draw_circle(Vector2(wx, 146), 5, Color("b8bec6"))
		"warehouse":
			draw_rect(Rect2(22, 96, 116, 62), body)
			draw_colored_polygon(PackedVector2Array([Vector2(16, 98), Vector2(80, 70), Vector2(144, 98)]), body.darkened(0.2))
			_slats(Rect2(34, 112, 38, 46), body.darkened(0.1))
			_slats(Rect2(88, 112, 38, 46), body.darkened(0.1))
			if bool(a.get("truck", false)):
				draw_rect(Rect2(14, 120, 52, 28), Color("f4f4f2"))
				draw_rect(Rect2(14, 132, 52, 5), accent)
				draw_rect(Rect2(66, 128, 18, 20), accent.darkened(0.1))
				draw_rect(Rect2(72, 131, 9, 8), glass)
				for wx: float in [28.0, 74.0]:
					draw_circle(Vector2(wx, 150), 8, dark)
		"factory":
			var brick := Color("8a5a44")
			var smoke := Color(1, 1, 1, 0.8)
			if bool(a.get("small", false)):
				draw_rect(Rect2(100, 68, 11, 30), brick)
				draw_circle(Vector2(108, 56), 7, smoke)
				draw_rect(Rect2(36, 100, 88, 58), body)
				draw_colored_polygon(PackedVector2Array([Vector2(30, 102), Vector2(80, 76), Vector2(130, 102)]), body.darkened(0.2))
				_windows(Rect2(42, 110, 44, 20), 2, 1, glass)
				_slats(Rect2(92, 118, 26, 40), body.darkened(0.12))
			else:
				draw_rect(Rect2(116, 50, 12, 50), brick)
				draw_rect(Rect2(116, 56, 12, 4), Color.WHITE)
				draw_circle(Vector2(126, 40), 7, smoke)
				draw_circle(Vector2(136, 28), 9, Color(smoke, 0.6))
				draw_rect(Rect2(20, 100, 120, 58), body)
				for i in 3:
					var x0 := 20.0 + i * 40.0
					draw_colored_polygon(PackedVector2Array([Vector2(x0, 100), Vector2(x0 + 40, 100), Vector2(x0, 76)]), body.darkened(0.15))
					draw_rect(Rect2(x0 + 1, 82, 4, 18), glass)
				_windows(Rect2(28, 112, 80, 18), 4, 1, glass)
				draw_rect(Rect2(112, 124, 20, 34), dark)
		"garage":
			draw_rect(Rect2(26, 96, 108, 62), body)
			draw_rect(Rect2(22, 84, 116, 16), accent)
			draw_rect(Rect2(40, 89, 80, 6), Color.WHITE)
			_slats(Rect2(38, 108, 60, 50), body.darkened(0.12))
			draw_rect(Rect2(106, 120, 18, 38), dark)
		"bank":
			draw_rect(Rect2(30, 88, 100, 56), body.darkened(0.08))
			draw_colored_polygon(PackedVector2Array([Vector2(22, 84), Vector2(80, 54), Vector2(138, 84)]), body)
			draw_rect(Rect2(24, 82, 112, 9), body.darkened(0.15))
			draw_circle(Vector2(80, 72), 7, accent)
			for i in 4:
				draw_rect(Rect2(38 + i * 24, 92, 10, 50), body)
			draw_rect(Rect2(28, 142, 104, 7), body.darkened(0.15))
			draw_rect(Rect2(20, 149, 120, 9), body.darkened(0.25))
		"tower":
			draw_rect(Rect2(18, 78, 34, 80), body.lightened(0.2))
			_windows(Rect2(22, 84, 26, 66), 2, 5, Color.WHITE)
			draw_rect(Rect2(108, 98, 34, 60), body.darkened(0.1))
			_windows(Rect2(112, 104, 26, 48), 2, 4, glass.lightened(0.3))
			draw_line(Vector2(80, 22), Vector2(80, 6), dark, 2.0, true)
			draw_rect(Rect2(52, 22, 56, 136), body)
			_windows(Rect2(56, 28, 48, 112), 3, 9, glass.lightened(0.25))
			draw_rect(Rect2(72, 144, 16, 14), dark)
		"mall":
			draw_rect(Rect2(14, 76, 132, 82), body)
			draw_rect(Rect2(10, 70, 140, 8), body.darkened(0.25))
			draw_rect(Rect2(42, 56, 76, 18), accent)
			draw_rect(Rect2(52, 63, 56, 4), Color.WHITE)
			_windows(Rect2(20, 82, 120, 22), 6, 1, glass)
			_awning(Rect2(14, 108, 132, 10), accent)
			draw_rect(Rect2(22, 126, 26, 24), glass)
			draw_rect(Rect2(112, 126, 26, 24), glass)
			draw_rect(Rect2(56, 126, 48, 32), glass)
			draw_line(Vector2(80, 126), Vector2(80, 158), body.darkened(0.3), 2.0)
		"server":
			draw_rect(Rect2(30, 40, 100, 6), dark.darkened(0.2))
			for rx: float in [36.0, 84.0]:
				draw_rect(Rect2(rx, 46, 40, 112), dark)
				for j in 7:
					var sy := 54.0 + j * 14.0
					draw_rect(Rect2(rx + 5, sy, 30, 9), dark.lightened(0.18))
					draw_circle(Vector2(rx + 29, sy + 4.5), 2.0, accent.lightened(0.35) if (j + int(rx)) % 3 == 0 else Color("6fd08c"))
		"dish":
			draw_polyline(PackedVector2Array([Vector2(24, 98), Vector2(38, 82), Vector2(50, 90), Vector2(68, 62)]), accent, 3.0, true)
			draw_rect(Rect2(28, 114, 104, 44), body)
			draw_rect(Rect2(24, 108, 112, 8), body.darkened(0.2))
			_windows(Rect2(34, 122, 60, 20), 3, 1, glass)
			draw_rect(Rect2(104, 128, 18, 30), dark)
			draw_line(Vector2(88, 108), Vector2(96, 82), dark, 4.0, true)
			_ell(Vector2(98, 74), 32, 13, -0.55, Color("b8bec6"))
			_ell(Vector2(98, 72), 30, 11, -0.55, Color.WHITE)
			draw_line(Vector2(98, 72), Vector2(112, 50), dark, 2.0, true)
			draw_circle(Vector2(112, 50), 3.5, accent)
		"billboard":
			draw_line(Vector2(50, 100), Vector2(50, 158), dark, 4.0)
			draw_line(Vector2(110, 100), Vector2(110, 158), dark, 4.0)
			draw_rect(Rect2(18, 34, 124, 70), Color.WHITE)
			draw_rect(Rect2(18, 34, 124, 70), dark, false, 3.0)
			draw_rect(Rect2(24, 40, 112, 58), accent.lightened(0.55))
			_star(Vector2(52, 69), 18, 8, accent)
			draw_rect(Rect2(78, 56, 50, 8), accent)
			draw_rect(Rect2(78, 70, 40, 6), accent.lightened(0.25))
			draw_rect(Rect2(78, 82, 46, 6), accent.lightened(0.25))
			draw_rect(Rect2(40, 128, 80, 30), Color("d8d2c6"))
			_windows(Rect2(46, 132, 48, 14), 3, 1, glass)
			draw_rect(Rect2(100, 136, 14, 22), dark)
		"startup":
			var roof := Color("8a5a44")
			draw_rect(Rect2(36, 104, 88, 54), body)
			draw_colored_polygon(PackedVector2Array([Vector2(28, 106), Vector2(80, 72), Vector2(132, 106)]), roof)
			draw_rect(Rect2(46, 116, 50, 30), dark)
			draw_polyline(PackedVector2Array([Vector2(50, 140), Vector2(62, 130), Vector2(72, 135), Vector2(90, 120)]), Color("6fd08c"), 2.5, true)
			draw_rect(Rect2(104, 126, 14, 32), roof.darkened(0.2))
			draw_circle(Vector2(80, 64), 3.0, accent)
			draw_arc(Vector2(80, 66), 10, -PI * 0.8, -PI * 0.2, 8, accent, 2.5, true)
			draw_arc(Vector2(80, 66), 18, -PI * 0.78, -PI * 0.22, 10, accent, 2.5, true)

func _draw_banner() -> void:
	var kind := String(choice.get("kind", ""))
	var text := ""
	var action := ""
	var alpha := 1.0
	if kind != "":
		text = String(choice["prompt"])
		action = "Cancel" if ["discard_for", "exchange", "place"].has(kind) else "Skip"
	elif _die_free(selected_die) and phase == Phase.ACTION:
		var v := dice[selected_die].value
		text = "Place the %d on a glowing business" % v
		var fits := false
		for inst in board:
			if inst != null and _block_reason(inst, selected_die) == "":
				fits = true
		if not fits:
			text = "No business takes a %d. Trade it for Cash or pick another die" % v
	elif toast != "" and clock - toast_t < 3.0 and phase == Phase.ACTION:
		text = toast
		alpha = clampf((3.0 - (clock - toast_t)) / 0.5, 0.0, 1.0)
	if text == "":
		return
	var size := T_SM
	var aw := _text_w(action, size, true) + 36.0 if action != "" else 0.0
	var max_w := p_portfolio.size.x - 420.0
	while size > 14 and _text_w(text, size, true) + 48.0 + aw > max_w:
		size -= 1
	aw = _text_w(action, size, true) + 36.0 if action != "" else 0.0
	var w := _text_w(text, size, true) + 48.0 + aw
	var r := Rect2(p_portfolio.get_center().x - w * 0.5, p_portfolio.position.y + 12.0, w, 44.0)
	_panel(r, Color(c_ink, 0.92 * alpha), 22)
	_text(Vector2(r.position.x + 24.0, r.get_center().y + _vc(font_bold, size)), text, size, Color(1, 1, 1, alpha), true)
	if action != "":
		var ar := Rect2(r.end.x - aw - 6.0, r.position.y + 5.0, aw, 34.0)
		if ar.has_point(mouse) and ui_live:
			_panel(ar, Color(1, 1, 1, 0.12), 17)
		_text_center(ar, action, size, c_gold, true)
		_register(ar, _skip_choice)

func _draw_picker() -> void:
	_dim()
	var kind := String(choice["kind"])
	var cy := UI_H * 0.5
	var title := String(choice["prompt"])
	_heavy(Vector2((UI_W - _heavy_w(title, T_XL)) * 0.5, cy - 260.0), title, T_XL, Color.WHITE)
	if kind == "peek_swap":
		var cards: Array[String] = choice["cards"]
		var total := cards.size() * card_w + (cards.size() - 1) * 32.0
		for j in cards.size():
			var r := Rect2((UI_W - total) * 0.5 + j * (card_w + 32.0), cy - 200.0, card_w, CARD_H)
			_draw_card(r, cards[j], null, "peek", Color(c_gold, 0.8) if r.has_point(mouse) else Color(0, 0, 0, 0))
			_register(r, _pick_peek.bind(j))
	else:
		var bw := 250.0
		var total := D.TYPES.size() * bw + (D.TYPES.size() - 1) * 16.0
		for j in D.TYPES.size():
			var t: String = D.TYPES[j]
			var n := 0
			for id in market:
				if id != "" and _card_type(id) == t:
					n += 1
			_button(Rect2((UI_W - total) * 0.5 + j * (bw + 16.0), cy - 60.0, bw, 90.0), D.TYPE_NAMES[t], _refresh_type.bind(t), true, _tcol(t), T_LG, "%d listed" % n)
	_ghost(Rect2(UI_W * 0.5 - 110.0, cy + 190.0, 220.0, 56.0), "Skip", _skip_choice, true, Color.WHITE)

func _flash_at(at: Vector2) -> void:
	for i in board_slots:
		if board[i] != null and _board_rect(i).has_point(at):
			board[i].flash = maxf(board[i].flash, 0.7)
			return

func _draw_floaters() -> void:
	for f in floaters:
		if f.delay > 0.0:
			continue
		var a := clampf(f.life / 0.45, 0.0, 1.0)
		var pop := minf(1.0, f.age / 0.14)
		var sc := 0.6 + 0.4 * pop + 0.12 * sin(pop * PI)
		var size := int(T_MD * sc)
		var tw := _heavy_w(f.text, size)
		var ir := 12.0 * sc
		var w := tw + 28.0 * sc + (ir * 2.0 + 6.0 * sc if f.icon != "" else 0.0)
		var h := 40.0 * sc
		var box := Rect2(f.pos - Vector2(w, h) * 0.5, Vector2(w, h))
		var col := Color(f.color)
		_panel(Rect2(box.position + Vector2(0, 4), box.size), Color(0, 0, 0, 0.3 * a), int(h * 0.5))
		_panel(box, Color(col.darkened(0.1), a), int(h * 0.5), Color(1, 1, 1, 0.85 * a), 2)
		var x := box.position.x + 14.0 * sc
		_heavy(Vector2(x, box.get_center().y + _vc(font_heavy, size)), f.text, size, Color(1, 1, 1, a))
		if f.icon != "":
			var ic := Vector2(x + tw + 6.0 * sc + ir, box.get_center().y)
			draw_circle(ic, ir, Color(1, 1, 1, a))
			_icon(f.icon, ic, ir * 0.72)

func _draw_tooltip(text: String) -> void:
	var w := 520.0
	var ts := font_bold.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, T_SM)
	var box := Rect2(mouse + Vector2(24.0, 24.0), Vector2(minf(ts.x, w) + 36.0, ts.y + 26.0))
	if box.end.x > UI_W - 12.0:
		box.position.x = mouse.x - box.size.x - 16.0
	if box.end.y > UI_H - 12.0:
		box.position.y = mouse.y - box.size.y - 16.0
	_panel(box, c_ink, 14)
	_wrap(box.position + Vector2(18.0, 13.0), text, w, T_SM, Color.WHITE, true)

func _dim() -> void:
	draw_rect(Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600)), Color(0.1, 0.12, 0.1, 0.6))

func _modal(w: float, h: float) -> Rect2:
	_dim()
	var r := Rect2(Vector2(UI_W - w, UI_H - h) * 0.5, Vector2(w, h))
	tut_rects["modal"] = r
	_panel(r, c_card, 28)
	return r

func _row(x: float, w: float, y: float, label: String, value: String, col: Color = c_ink) -> void:
	_text(Vector2(x, y), label, T_MD, c_muted, true)
	_heavy_right(x + w, y, value, T_LG, col)

func _draw_report() -> void:
	var extra := int(report.has("cond")) + (report["lost"] as Dictionary).size() + (report["notes"] as Array).size()
	var r := _modal(900.0, 572.0 + extra * 40.0)
	var hit := bool(report["hit"])
	var year_end := bool(report["year_end"])
	var x := r.position.x + 64.0
	var w := r.size.x - 128.0
	var rq := int(report["round"])
	_text(Vector2(x, r.position.y + 76.0), "YEAR %d  ·  Q%d  ·  %s" % [_year_of(rq), _quarter_in_year(rq), String(report["event"]).to_upper()], T_SM, c_muted, true)
	var title := ("Year target met" if hit else "Year target missed") if year_end else "Quarter complete"
	_heavy(Vector2(x, r.position.y + 146.0), title, T_HERO, (c_good if hit else c_bad) if year_end else c_ink)
	var y := r.position.y + 228.0
	var n := int(report["activations"])
	_row(x, w, y, "Earned this quarter (%d operation%s)" % [n, "" if n == 1 else "s"], str(int(report["vp"])))
	y += 22.0
	draw_line(Vector2(x, y), Vector2(x + w, y), c_line, 2.0)
	y += 44.0
	_row(x, w, y, "Year %d total" % int(report["year"]), "%d / %d" % [int(report["year_vp"]), int(report["target"])], c_good if hit else (c_bad if year_end else c_ink))
	y += 72.0
	var lines: Array = []
	if not year_end:
		var left := D.QUARTERS_PER_YEAR - _quarter_in_year(rq)
		if hit:
			lines.append(["Year target already met; beat it by 25% for a better Investor Meeting", c_good])
		else:
			lines.append(["%d Brand to go in %d quarter%s" % [int(report["target"]) - int(report["year_vp"]), left, "" if left == 1 else "s"], c_muted])
	elif hit:
		var surplus := int(report["surplus"])
		if surplus > 0:
			lines.append(["Beat the target by %d" % surplus, c_good])
		else:
			lines.append(["Exactly on target", c_good])
	elif report.has("strike"):
		lines.append(["Strike %d of %d" % [int(report["strike"]), strikes_to_lose], c_bad])
	elif report.has("debt"):
		lines.append(["Shortfall of %d added to the next target" % int(report["debt"]), c_bad])
	if report.has("cond"):
		var cd: Dictionary = report["cond"]
		if bool(cd["ok"]):
			lines.append(["%s: goal met" % cd["name"], c_good])
		else:
			lines.append(["%s: goal missed, penalty next quarter" % cd["name"], c_bad])
	var lost: Dictionary = report["lost"]
	for k: String in lost:
		lines.append(["Storage cap: lost %d %s" % [int(lost[k]), D.RES_NAMES[k]], c_warn])
	for note: String in report["notes"]:
		lines.append([note, c_muted])
	for l: Array in lines:
		_text(Vector2(x, y), String(l[0]), T_MD, l[1], true)
		y += 40.0
	var label := "Next quarter"
	if game_result == "won":
		label = "See results"
	elif game_result == "lost":
		label = "See results"
	_button(Rect2(r.get_center().x - 180.0, r.end.y - 116.0, 360.0, 80.0), label, _continue, true, c_accent, T_LG)

func _draw_gameover() -> void:
	var r := _modal(1400.0, 940.0)
	var won := game_result == "won"
	var x := r.position.x + 70.0
	_heavy(Vector2(x, r.position.y + 120.0), "Your portfolio thrived" if won else "The board voted you out", T_HERO, c_good if won else c_bad)
	_text(Vector2(x, r.position.y + 172.0), "%s after %d years, %d quarters  ·  %s  ·  seed %d" % ["Survived" if won else "Eliminated", years.size(), history.size(), _sheet_name(), seed_used], T_MD, c_muted, true)
	var sc := "Won" if won else "Reached year %d, Q%d" % [_year_of(history.size()), _quarter_in_year(history.size())]
	_heavy(Vector2(x, r.position.y + 260.0), sc, T_HERO - 8, c_ink)
	var best_txt := "New best" if history.size() >= best_quarters and history.size() > 0 else "Best: %s" % _best_text()
	_text(Vector2(x + _heavy_w(sc, T_HERO - 8) + 28.0, r.position.y + 256.0), best_txt, T_LG, c_accent, true)
	var chart := Rect2(x, r.position.y + 360.0, r.size.x - 140.0, 360.0)
	var top := 1
	for h in years:
		top = maxi(top, maxi(int(h["vp"]), int(h["target"])))
	var bw := chart.size.x / maxf(1.0, _total_years())
	for i in years.size():
		var h: Dictionary = years[i]
		var bx := chart.position.x + i * bw + bw * 0.2
		var bww := bw * 0.6
		var ah := chart.size.y * int(h["vp"]) / top
		var base_y := chart.end.y
		if ah > 0.0:
			_panel(Rect2(bx, base_y - ah, bww, ah), c_gold, 4)
		var ty := base_y - chart.size.y * int(h["target"]) / top
		draw_line(Vector2(bx - 8.0, ty), Vector2(bx + bww + 8.0, ty), c_bad if not bool(h["hit"]) else c_ink, 3.0)
		_text_center(Rect2(bx, base_y + 6.0, bww, 32.0), "Year %d" % (i + 1), T_SM, c_muted, true)
	_text(Vector2(chart.position.x, chart.end.y + 70.0), "Gold: Brand earned each year   Line: yearly target", T_SM, c_muted, true)
	_button(Rect2(r.end.x - 430.0, r.end.y - 116.0, 360.0, 80.0), "Choose sheet", func() -> void: phase = Phase.MENU, true, c_accent, T_LG)
	_ghost(Rect2(r.end.x - 810.0, r.end.y - 116.0, 360.0, 80.0), "Replay seed", func() -> void: _new_run(seed_used), true)

func _draw_help() -> void:
	var r := _modal(1800.0, 1100.0)
	var x := r.position.x + 70.0
	var col_w := (r.size.x - 200.0) / 2.0
	_heavy(Vector2(x, r.position.y + 96.0), "How to play", T_HERO - 12, c_ink)
	var left := "\n".join([
		"Each quarter:",
		"1. This quarter's outlook event takes effect.",
		"2. Roll %d dice (always %d-%d after modifiers)." % [base_dice, min_dice, max_dice],
		"3. Click a die, then a business whose pattern it matches to operate it. Each business operates once per quarter. Two-die patterns operate once both dice are placed.",
		"4. Dice have other uses: place a 1-5 on a resource's dice slot to gain 1 of it (1 Cash, 2 Labor, 3 Equipment, 4 Intelligence, 5 Advertising), or a 6 on Scout to see new deals. Buy businesses from the Market, exchange %d:1, or reroll all dice for %d Intelligence." % [exchange_rate, reroll_cost],
		"5. End the quarter. Brand is earned by placing and operating businesses, and adds up over a year of %d quarters. After the last quarter of each year, meet the yearly target or take a strike (%d strikes and the board votes you out); Brand then resets. Survive %d years to win. After every quarter, the Investor Meeting offers rewards; pick 1." % [D.QUARTERS_PER_YEAR, strikes_to_lose, _total_years()],
		"6. The outlook moves forward." if storage_cap <= 0 else "6. Resources above %d are lost. The outlook moves forward." % storage_cap,
		"",
		"Distressed businesses add no Brand and can't operate. Any die turns one around, without triggering its ability.",
		"Buying a business lets you choose its lot; it can't be moved afterwards. A newly placed business earns its value in Brand right away. Click a business (with no die selected) to sell it for about half its cost in Cash. Adjacent means directly left, right, above or below.",
		"Unused dice are sold for %d Cash each when the quarter ends." % trade_die_cash,
		"Some lots only accept one sector or a range of business values; the tag at the top of the lot shows its rule.",
		"Editions: Gold earns double value, Holographic triggers its ability twice, Blue Chip can't be distressed or targeted, Franchise counts as 2 of its sector. Earned at Investor Meetings.",
		"Investor Meeting: 3 offers after most quarters. At year end: 4 if you beat the target by 25%, 3 if you met it, 2 if you missed.",
		"Rarity: no gem = common, blue = uncommon, gold = rare.",
	])
	_wrap(Vector2(x, r.position.y + 140.0), left, col_w, T_MD, c_ink)
	var rx := x + col_w + 60.0
	var right := "\n".join([
		"Costs: value + 1 in total.",
		"- Half (rounded up) in the business's sector resource.",
		"- Value 5+: 1 Equipment (unless it's Industry).",
		"- The rest in Cash (Finance businesses: Labor).",
		"%d lots start locked. Each shows what opens it: paying a resource, an adjacent business of a sector, or a portfolio goal." % D.LOCKED_LOTS,
		"Some businesses spend Labor or Advertising for Brand.",
		"",
		"Patterns: Odd, Even, Low (1-3), High (4-6), Exactly N, N+, N or less, Any, Pair, Sum N+, Sum = N, Run (two consecutive values).",
		"",
		"Hover anything for details.",
		"Keys: Enter = end quarter / continue, Esc = cancel, H = help, M = music on/off, F1 = debug.",
	])
	_wrap(Vector2(rx, r.position.y + 140.0), right, col_w, T_MD, c_ink)
	ui_live = true
	_button(Rect2(r.get_center().x - 160.0, r.end.y - 110.0, 320.0, 72.0), "Got it", func() -> void: show_help = false, true, c_accent, T_LG)

func _draw_debug() -> void:
	var r := Rect2(40.0, UI_H - 140.0, 620.0, 100.0)
	_panel(r, Color(0, 0, 0, 0.8), 14)
	var lines := "DEBUG  ·  1-6 set selected die  ·  R +1 all resources\nD add a die  ·  N skip quarter  ·  click outlook slot 2/3 to cycle"
	_wrap(r.position + Vector2(18.0, 14.0), lines, r.size.x - 36.0, T_SM, Color("9ef0a8"), true)
