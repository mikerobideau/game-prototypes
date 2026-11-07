extends Node2D
class_name BotanicalGardenPrototype

const D := preload("res://prototypes/botanical_garden/botanical_garden_data.gd")

enum Phase { ACTION, REPORT, GAMEOVER }
enum MissRule { STRIKES, DEBT }

@export_group("Run")
@export var run_seed: int = 0
@export var rounds_per_run: int = 12
@export var strikes_to_lose: int = 3
@export var miss_rule: MissRule = MissRule.STRIKES

@export_group("Dice")
@export var base_dice: int = 4
@export var min_dice: int = 3
@export var max_dice: int = 5
@export var trade_die_seeds: int = 1
@export var add_die_cost: int = 1
@export var reroll_cost: int = 2

@export_group("Board and market")
@export var board_slots: int = 9
@export var market_size: int = 4
@export var refresh_cost: int = 2
@export var low_value_max: int = 3
@export var low_value_copies: int = 2
@export var high_value_copies: int = 1

@export_group("Economy")
@export var exchange_rate: int = 3
@export var storage_cap: int = 0

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
	var flash := 0.0
	var shake := 0.0

class Die:
	var value := 1
	var shown := 1
	var used := false
	var card_uid := -1
	var roll_t := 0.0
	var flicker := 0.0

class FloatText:
	var pos := Vector2.ZERO
	var life := 1.5
	var text := ""
	var color := Color.WHITE

class UiButton:
	var rect: Rect2
	var cb: Callable

const UI_W := 2560.0
const UI_H := 1440.0
const GRID_COLS := 3
const CARD_H := 356.0
const CARD_GAP := 20.0
const MARGIN := 40.0
const COL_GAP := 28.0
const PANEL_PAD := 28.0
const PANEL_HEAD := 64.0
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

const SAVE_PATH := "user://botanical_garden.cfg"

var c_bg := Color("eef0e6")
var c_panel := Color("e6e9de")
var c_line := Color("d9ded0")
var c_card := Color("ffffff")
var c_ink := Color("1e2b22")
var c_body := Color("4f5b53")
var c_muted := Color("7a857c")
var c_shadow := Color("1e2b22")
var c_good := Color("3e7b4f")
var c_bad := Color("c4553f")
var c_warn := Color("c8862f")
var c_gold := Color("e9b949")
var c_accent := Color("3e7b4f")
var c_ice := Color("bfe0f2")
var c_soil := Color("dce4d2")
var c_leaf := Color("5e8a3a")

var rng := RandomNumberGenerator.new()
var seed_used := 0
var phase := Phase.ACTION
var round_n := 1
var strikes := 0
var debt := 0
var score := 0
var best_score := -1
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
var debug_on := false
var hover_forecast := -1
var float_burst := 0

var floaters: Array[FloatText] = []
var buttons: Array[UiButton] = []
var ui_live := true
var hover_tip := ""
var mouse := Vector2.ZERO
var clock := 0.0
var window_size := Vector2.ZERO
var ui_scale := 1.0
var screen_origin := Vector2.ZERO

var card_w := 254.0
var market_pick := -1
var r_garden := Rect2()
var r_market := Rect2()
var r_supply := Rect2()
var p_garden := Rect2()
var p_market := Rect2()
var p_supply := Rect2()
var h_left := Rect2()
var h_center := Rect2()
var h_right := Rect2()
var s_res := Rect2()
var s_dice := Rect2()
var s_end := Rect2()

var font: Font
var font_bold: Font
var font_heavy: Font
var font_title: Font
var style := StyleBoxFlat.new()
var base_xform := Transform2D.IDENTITY

func _ready() -> void:
	_load_fonts()
	_load_best()
	_recompute_layout()
	get_viewport().size_changed.connect(_recompute_layout)
	_validate_data()
	_new_run(run_seed if run_seed != 0 else randi_range(1, 999999))

func _load_fonts() -> void:
	var ts := TextServerManager.get_primary_interface()
	var wght := ts.name_to_tag("wght")
	var sans_path := "res://assets/fonts/DMSans-VariableFont.ttf"
	var serif_path := "res://assets/fonts/Fraunces-VariableFont.ttf"
	font = ThemeDB.fallback_font
	font_bold = ThemeDB.fallback_font
	font_heavy = ThemeDB.fallback_font
	if ResourceLoader.exists(sans_path):
		var sans: Font = load(sans_path)
		font = _variation(sans, {wght: 450})
		font_bold = _variation(sans, {wght: 700})
	if ResourceLoader.exists(serif_path):
		var serif: Font = load(serif_path)
		font_heavy = _variation(serif, {wght: 700, ts.name_to_tag("opsz"): 72, ts.name_to_tag("SOFT"): 50})
	font_title = font_heavy

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
	var garden_w := gw + PANEL_PAD * 2.0
	var supply_w := 560.0
	var x0 := (UI_W - market_w - garden_w - supply_w - COL_GAP * 2.0) * 0.5
	p_market = Rect2(x0, BODY_TOP, market_w, ph)
	p_garden = Rect2(p_market.end.x + COL_GAP, BODY_TOP, garden_w, ph)
	p_supply = Rect2(p_garden.end.x + COL_GAP, BODY_TOP, supply_w, ph)
	r_garden = Rect2(p_garden.position.x + PANEL_PAD, BODY_TOP + PANEL_HEAD, gw, gh)
	r_market = Rect2(p_market.position.x + PANEL_PAD, r_garden.position.y, card_w * 2.0 + CARD_GAP, gh)
	r_supply = Rect2(p_supply.position.x + PANEL_PAD, r_garden.position.y, supply_w - PANEL_PAD * 2.0, gh)
	h_left = Rect2(p_market.position.x, HEADER_Y, market_w, HEADER_H)
	h_center = Rect2(p_garden.position.x, HEADER_Y, p_garden.size.x, HEADER_H)
	h_right = Rect2(p_supply.position.x, HEADER_Y, supply_w, HEADER_H)
	s_res = Rect2(r_supply.position, Vector2(r_supply.size.x, 500.0))
	s_dice = Rect2(r_supply.position.x, s_res.end.y + 20.0, r_supply.size.x, 344.0)
	s_end = Rect2(r_supply.position.x, s_dice.end.y + 20.0, r_supply.size.x, r_supply.end.y - s_dice.end.y - 20.0)

func _validate_data() -> void:
	for id: String in D.CARDS:
		var c: Dictionary = D.CARDS[id]
		var p: Dictionary = c.get("pattern", {})
		if not p.is_empty() and not D.PATTERNS.has(p["kind"]):
			push_warning("Card %s has unknown pattern %s" % [id, p["kind"]])
		if int(c["value"]) < 1 or int(c["value"]) > 7:
			push_warning("Card %s value out of range" % id)

func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = int(cfg.get_value("run", "best", -1))

func _save_best() -> void:
	if score <= best_score:
		return
	best_score = score
	var cfg := ConfigFile.new()
	cfg.set_value("run", "best", best_score)
	cfg.save(SAVE_PATH)

func _new_run(s: int) -> void:
	seed_used = s
	rng.seed = s
	phase = Phase.ACTION
	round_n = 1
	strikes = 0
	debt = 0
	score = 0
	game_result = ""
	res = D.STARTING_RESOURCES.duplicate()
	next_uid = 1
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
		var copies := int(c.get("copies", low_value_copies if int(c["value"]) <= low_value_max else high_value_copies))
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
		_say("Market deck reshuffled")
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
		return {"id": "clear_skies", "weak": false, "revealed": false}
	return {"id": pool[rng.randi_range(0, pool.size() - 1)], "weak": false, "revealed": false}

func _start_round() -> void:
	mods = {"cost_plus": {}, "refresh_plus": 0, "dice_delta": 0}
	act_vp = 0
	activations = 0
	types_activated = {}
	selected_die = -1
	choice = {}
	market_pick = -1
	choice_queue.clear()
	round_notes.clear()
	dice_notes.clear()
	for inst in board:
		if inst != null:
			inst.activated = false
			inst.pending.clear()
			inst.used_values.clear()
	var ev: Dictionary = forecast[0]
	var ev_name := _event_name(ev)
	for m: Dictionary in _event_mods(ev):
		_apply_mod(m, ev_name)
	for m: Dictionary in queued_penalties:
		_apply_mod(m, "Penalty")
	queued_penalties.clear()
	var extra := extra_dice_next
	extra_dice_next = 0
	if extra > 0:
		dice_notes.push_front("+%d from abilities" % extra)
	var n := clampi(base_dice + extra + int(mods["dice_delta"]), min_dice, max_dice)
	_roll(n)
	phase = Phase.ACTION

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
			round_notes.append("%s: -%d dice (%d cards on board)" % [source, amt, _board_count()])
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
				round_notes.append("%s: %s pays half value" % [source, _inst_name(u)])
		"dormant":
			var u := _target_uid(String(m["target"]))
			if u >= 0:
				_inst_by_uid(u).dormant = true
				round_notes.append("%s: %s went dormant" % [source, _inst_name(u)])
		"pollen_locked":
			mods["pollen_locked"] = true
			round_notes.append("%s: Pollen can't be spent" % source)
		"exchange_rate":
			mods["exchange_rate"] = int(m["rate"])
		_:
			push_warning("Unknown modifier %s" % kind)

func _target_uid(target: String) -> int:
	var best: CardInst = null
	for inst in board:
		if inst == null or inst.dormant:
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
	return int(D.CARDS[inst.id]["value"])

func _effective_value(inst: CardInst) -> int:
	var v := _base_value(inst)
	if int(mods.get("halve_value_uid", -1)) == inst.uid:
		v = floori(v * 0.5)
	return v

func _base_pattern(id: String) -> Dictionary:
	return D.CARDS[id].get("pattern", {})

func _effective_pattern(inst: CardInst) -> Dictionary:
	var overrides: Dictionary = mods.get("pattern_override", {})
	return overrides.get(inst.uid, _base_pattern(inst.id))

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

func _free_slot() -> int:
	for i in board.size():
		if board[i] == null:
			return i
	return -1

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

func _passive_vp() -> int:
	var total := 0
	for inst in board:
		if inst != null and not inst.dormant:
			total += _effective_value(inst)
	return total

func _round_vp() -> int:
	return _passive_vp() + act_vp

func _target_for(r: int) -> int:
	var t: int = D.TARGETS[clampi(r - 1, 0, D.TARGETS.size() - 1)]
	if r == round_n:
		t += debt
	return t

func _pollen_locked() -> bool:
	return bool(mods.get("pollen_locked", false))

func _rule_cost(id: String) -> Dictionary:
	var c: Dictionary = D.CARDS[id]
	var v := clampi(int(c["value"]), 1, 7)
	var base: Dictionary = D.COST_TIERS[v]["cost"]
	var out := {}
	for r: String in base:
		var key := r
		if r == "premium":
			key = String(c.get("premium", "pollen" if c["type"] == "pollen" else "sunlight"))
		out[key] = int(out.get(key, 0)) + int(base[r])
	return out

func _cost(id: String) -> Dictionary:
	var c: Dictionary = D.CARDS[id]
	var out := _rule_cost(id)
	var cp: Dictionary = mods.get("cost_plus", {})
	for r: String in cp:
		out[r] = int(out.get(r, 0)) + int(cp[r])
	return out

func _say(msg: String) -> void:
	toast = msg
	toast_t = clock

func _float(at: Vector2, text: String, col: Color) -> void:
	var f := FloatText.new()
	f.pos = at + Vector2(0.0, -float_burst * 38.0)
	f.text = text
	f.color = col
	floaters.append(f)
	float_burst += 1

func _roll(n: int) -> void:
	dice.clear()
	for i in n:
		var d := Die.new()
		d.value = rng.randi_range(1, 6)
		d.shown = d.value
		d.roll_t = 0.35 + i * 0.08
		dice.append(d)
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
	var v := dice[di].value
	if inst.dormant:
		return ""
	if inst.activated:
		return "Already activated this round"
	var p := _effective_pattern(inst)
	var need := _dice_needed(p)
	if need == 0:
		return "This card can't be activated"
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
	var first := dice[inst.pending[0]].value
	return "" if _fits2(p, first, v) else "%d and %d don't make %s" % [first, v, _pattern_label(p)]

func _convert_short(inst: CardInst) -> String:
	for e: Dictionary in D.CARDS[inst.id]["effects"]:
		if String(e["kind"]) == "convert":
			var pay: Dictionary = e["pay"]
			for r: String in pay:
				if _r(r) < int(pay[r]):
					return "Needs %d %s to convert" % [int(pay[r]), D.RES_NAMES[r]]
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
		_float(at, "Restored", c_good)
		_say("%s restored" % _card_name(inst.id))
	elif _dice_needed(_effective_pattern(inst)) == 2 and inst.pending.is_empty():
		inst.pending.append(di)
		d.card_uid = inst.uid
	else:
		for pi in inst.pending:
			dice[pi].used = true
			dice[pi].card_uid = -1
			inst.used_values.append(dice[pi].value)
		inst.pending.clear()
		d.used = true
		inst.used_values.append(d.value)
		_activate(inst)
	selected_die = -1
	_next_choice()

func _return_pending(inst: CardInst) -> void:
	for pi in inst.pending:
		dice[pi].card_uid = -1
	inst.pending.clear()

func _activate(inst: CardInst) -> void:
	inst.activated = true
	inst.flash = 1.0
	activations += 1
	types_activated[_card_type(inst.id)] = true
	var half := int(mods.get("halve_output_uid", -1)) == inst.uid
	for e: Dictionary in D.CARDS[inst.id]["effects"]:
		_run_effect(e, inst, half)

func _halve(amt: int, half: bool) -> int:
	return floori(amt * 0.5) if half else amt

func _run_effect(e: Dictionary, inst: CardInst, half: bool) -> void:
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
		"vp":
			_add_vp(_halve(int(e["amount"]), half), at)
		"vp_per":
			_add_vp(_halve(_count_per(e) * int(e["amount"]), half), at)
		"extra_die":
			extra_dice_next += int(e["amount"])
			_float(at, "+%d die next round" % int(e["amount"]), c_accent)
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
				_say("%s delayed a round" % _event_name(t))
		"forecast_cancel":
			var s := int(e["slot"])
			if s < forecast.size():
				_say("%s cancelled" % _event_name(forecast[s]))
				forecast[s] = {"id": "clear_skies", "weak": false, "revealed": true}
		"forecast_reveal":
			for ev in forecast:
				ev["revealed"] = true
		"refresh_market":
			_refresh_market()
		"gain_random_card":
			var id := _deal_card()
			if id == "":
				_say("Market deck is empty")
			else:
				var slot := _free_slot()
				if slot >= 0:
					board[slot] = _make_inst(id)
					board[slot].flash = 1.0
					_say("Gained %s" % _card_name(id))
				else:
					discard.append(id)
					_say("Gained %s, but the board was full (lost)" % _card_name(id))
		"convert":
			var pay: Dictionary = e["pay"]
			for r: String in pay:
				res[r] = _r(r) - int(pay[r])
				_float(at, "-%d %s" % [int(pay[r]), D.RES_NAMES[r]], _tcol(r))
			_add_vp(_halve(int(e["vp"]), half), at)
		"replace_market", "peek_swap", "refresh_type", "restore_dormant":
			choice_queue.append(e.duplicate())
		_:
			push_warning("Unknown effect %s" % kind)

func _add_vp(amt: int, at: Vector2) -> void:
	act_vp += amt
	_float(at, "+%d VP" % amt, c_gold.darkened(0.25))

func _count_per(e: Dictionary) -> int:
	match String(e["per"]):
		"board_type":
			var n := 0
			for inst in board:
				if inst != null and _card_type(inst.id) == String(e["type"]):
					n += 1
			return n
		"activations":
			return activations
		"distinct_types":
			return types_activated.size()
		"market_cards":
			return _market_count()
		"empty_slots":
			return board_slots - _board_count()
	return 0

func _next_choice() -> void:
	while choice.is_empty() and not choice_queue.is_empty():
		var e: Dictionary = choice_queue.pop_front()
		var kind := String(e["kind"])
		if kind == "restore_dormant":
			if _dormant_count() == 0:
				_say("No dormant card to restore")
			else:
				choice = {"kind": kind, "prompt": "Choose a dormant card to restore"}
		elif kind == "replace_market":
			if _market_count() > 0:
				choice = {"kind": kind, "prompt": "Choose a market card to replace"}
		elif kind == "peek_swap":
			var cards: Array[String] = []
			for i in int(e.get("count", 3)):
				var id := _deal_card()
				if id != "":
					cards.append(id)
			if cards.is_empty():
				_say("Market deck is empty")
			else:
				choice = {"kind": kind, "cards": cards, "picked": -1, "prompt": "Pick a card to swap into the market"}
		elif kind == "refresh_type":
			choice = {"kind": kind, "prompt": "Choose a type to refresh in the market"}

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
	choice["prompt"] = "Now click a market slot to swap it into"

func _return_peek(keep: int) -> void:
	var cards: Array[String] = choice["cards"]
	for i in range(cards.size() - 1, -1, -1):
		if i != keep:
			deck.append(cards[i])

func _buy_block(i: int) -> String:
	if phase != Phase.ACTION:
		return "Not now"
	if bool(mods.get("market_frozen", false)):
		return "The market is frozen this round"
	var id := market[i]
	if id == "":
		return "Empty slot"
	var cost := _cost(id)
	if cost.has("pollen") and _pollen_locked():
		return "Pollen can't be spent this round"
	var short: Array[String] = []
	for r: String in cost:
		if _r(r) < int(cost[r]):
			short.append("%d %s" % [int(cost[r]) - _r(r), D.RES_NAMES[r]])
	if not short.is_empty():
		return "Need " + ", ".join(short) + " more"
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
			_say("Pick one of the revealed cards first")
			return
		var cards: Array[String] = choice["cards"]
		if market[i] != "":
			discard.append(market[i])
		market[i] = cards[picked]
		_say("Swapped %s into the market" % _card_name(cards[picked]))
		_return_peek(picked)
		_finish_choice()
		return
	if not choice.is_empty() or market[i] == "":
		return
	market_pick = -1 if market_pick == i else i

func _buy_pick() -> void:
	var i := market_pick
	market_pick = -1
	if i < 0 or not choice.is_empty():
		return
	var why := _buy_block(i)
	if why != "":
		_say(why)
		return
	var slot := _free_slot()
	if slot < 0:
		choice = {"kind": "discard_for", "market": i, "prompt": "Board full: choose a card to discard (no refund)"}
		return
	_complete_buy(i, slot)

func _complete_buy(i: int, slot: int) -> void:
	var id := market[i]
	var cost := _cost(id)
	for r: String in cost:
		res[r] = _r(r) - int(cost[r])
	var inst := _make_inst(id)
	inst.flash = 1.0
	board[slot] = inst
	market[i] = _deal_card()
	_say("Planted %s" % _card_name(id))

func _remove_from_board(slot: int) -> void:
	var inst := board[slot]
	if inst == null:
		return
	_return_pending(inst)
	if not D.STARTING_BOARD.has(inst.id):
		discard.append(inst.id)
	board[slot] = null
	_say("Discarded %s" % _card_name(inst.id))

func _on_board(slot: int) -> void:
	market_pick = -1
	var inst := board[slot]
	var kind := String(choice.get("kind", ""))
	if kind == "discard_for":
		if inst == null:
			return
		var mi := int(choice["market"])
		choice = {}
		_remove_from_board(slot)
		_complete_buy(mi, slot)
		_next_choice()
		return
	if kind == "restore_dormant":
		if inst != null and inst.dormant:
			inst.dormant = false
			inst.flash = 1.0
			_say("%s restored" % _card_name(inst.id))
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

func _on_die(i: int) -> void:
	market_pick = -1
	if phase != Phase.ACTION or not _die_free(i):
		return
	selected_die = -1 if selected_die == i else i

func _refresh_price() -> int:
	return refresh_cost + int(mods.get("refresh_plus", 0))

func _refresh_block() -> String:
	if bool(mods.get("market_frozen", false)) or bool(mods.get("refresh_frozen", false)):
		return "The market can't be refreshed this round"
	if _r("seed") < _refresh_price():
		return "Need %d Seeds" % _refresh_price()
	return ""

func _seed_refresh() -> void:
	var why := _refresh_block()
	if why != "" or not choice.is_empty():
		_say(why)
		return
	res["seed"] = _r("seed") - _refresh_price()
	_refresh_market()
	_say("Market refreshed")

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
	_say("Refreshed %d %s card%s" % [n, D.TYPE_NAMES[t], "" if n == 1 else "s"])
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
		if r == "pollen" and _pollen_locked():
			_say("Pollen can't be spent this round")
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

func _trade_target() -> int:
	if _die_free(selected_die):
		return selected_die
	for i in range(dice.size() - 1, -1, -1):
		if _die_free(i):
			return i
	return -1

func _trade_block() -> String:
	if phase != Phase.ACTION or not choice.is_empty():
		return "Not now"
	if _trade_target() < 0:
		return "No unused dice"
	return ""

func _trade_die() -> void:
	var why := _trade_block()
	if why != "":
		_say(why)
		return
	var i := _trade_target()
	dice[i].used = true
	res["seed"] = _r("seed") + trade_die_seeds
	_float(_die_home(i), "+%d Seed%s" % [trade_die_seeds, "" if trade_die_seeds == 1 else "s"], _tcol("seed"))
	selected_die = -1

func _pollen_block(price: int) -> String:
	if phase != Phase.ACTION or not choice.is_empty():
		return "Not now"
	if _pollen_locked():
		return "Pollen can't be spent this round"
	if _r("pollen") < price:
		return "Need %d Pollen" % price
	return ""

func _add_die_block() -> String:
	if dice.size() >= max_dice:
		return "Max %d dice per day" % max_dice
	return _pollen_block(add_die_cost)

func _add_die() -> void:
	var why := _add_die_block()
	if why != "":
		_say(why)
		return
	res["pollen"] = _r("pollen") - add_die_cost
	var d := Die.new()
	d.value = rng.randi_range(1, 6)
	d.roll_t = 0.35
	dice.append(d)

func _reroll_block() -> String:
	var any := false
	for i in dice.size():
		if _die_free(i):
			any = true
	if not any:
		return "No unused dice"
	return _pollen_block(reroll_cost)

func _reroll_all() -> void:
	var why := _reroll_block()
	if why != "":
		_say(why)
		return
	res["pollen"] = _r("pollen") - reroll_cost
	for i in dice.size():
		if _die_free(i):
			dice[i].value = rng.randi_range(1, 6)
			dice[i].roll_t = 0.35 + i * 0.05
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
			return "Activate a %s card" % D.TYPE_NAMES[cond["type"]]
		"activations_at_least":
			return "Activate %d cards (%d so far)" % [int(cond["amount"]), activations]
	return ""

func _end_round() -> void:
	if phase != Phase.ACTION or not choice.is_empty():
		return
	for inst in board:
		if inst != null:
			_return_pending(inst)
	var passive := _passive_vp()
	var vp := passive + act_vp
	var target := _target_for(round_n)
	var hit := vp >= target
	var rep := {"round": round_n, "passive": passive, "act": act_vp, "vp": vp, "target": target,
		"hit": hit, "activations": activations, "event": _event_name(forecast[0])}
	if hit:
		rep["surplus"] = vp - target
		score += vp - target
		debt = 0
	elif miss_rule == MissRule.STRIKES:
		strikes += 1
		rep["strike"] = strikes
	else:
		debt = target - vp
		rep["debt"] = debt
	var cond := _event_condition(forecast[0])
	if not cond.is_empty():
		var ok := _condition_met(cond)
		rep["cond"] = {"name": _event_name(forecast[0]), "ok": ok, "text": _event_text(forecast[0])}
		if not ok:
			queued_penalties.append_array(D.EVENTS[forecast[0]["id"]].get("penalty", []))
	var lost := {}
	for r: String in D.TYPES:
		if storage_cap > 0 and _r(r) > storage_cap:
			lost[r] = _r(r) - storage_cap
			res[r] = storage_cap
	rep["lost"] = lost
	rep["notes"] = round_notes.duplicate()
	forecast.pop_front()
	forecast.append(_new_event(round_n + forecast_length))
	history.append(rep)
	var out := (miss_rule == MissRule.STRIKES and strikes >= strikes_to_lose) or (miss_rule == MissRule.DEBT and not hit and round_n >= rounds_per_run)
	if out:
		game_result = "lost"
	elif round_n >= rounds_per_run:
		game_result = "won"
	report = rep
	selected_die = -1
	phase = Phase.REPORT

func _continue() -> void:
	if game_result != "":
		phase = Phase.GAMEOVER
		_save_best()
		return
	round_n += 1
	_refresh_market()
	_start_round()

func _primary_action() -> void:
	if show_help:
		show_help = false
		return
	match phase:
		Phase.ACTION:
			_end_round()
		Phase.REPORT:
			_continue()
		Phase.GAMEOVER:
			_new_run(randi_range(1, 999999))

func _debug_skip_round() -> void:
	if round_n >= rounds_per_run:
		return
	forecast.pop_front()
	forecast.append(_new_event(round_n + forecast_length))
	round_n += 1
	_say("Debug: skipped to round %d" % round_n)
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
	float_burst = 0
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
	for i in range(floaters.size() - 1, -1, -1):
		var f := floaters[i]
		f.life -= delta
		f.pos.y -= 55.0 * delta
		if f.life <= 0.0:
			floaters.remove_at(i)
	queue_redraw()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		var p := _ui_mouse()
		if mb.button_index == MOUSE_BUTTON_LEFT:
			for i in range(buttons.size() - 1, -1, -1):
				if buttons[i].rect.has_point(p):
					buttons[i].cb.call()
					return
			if phase == Phase.ACTION and choice.is_empty():
				selected_die = -1
				market_pick = -1
		elif mb.button_index == MOUSE_BUTTON_RIGHT and phase == Phase.ACTION:
			for i in board.size():
				if board[i] != null and _board_rect(i).has_point(p) and not board[i].pending.is_empty():
					_return_pending(board[i])
					return
			selected_die = -1
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var key := (ev as InputEventKey).keycode
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
			KEY_H:
				show_help = not show_help
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
		return Rect2(r_garden.get_center(), Vector2.ZERO)
	var col := i % GRID_COLS
	var row := floori(i / float(GRID_COLS))
	return Rect2(r_garden.position.x + col * (card_w + CARD_GAP), r_garden.position.y + row * (CARD_H + CARD_GAP), card_w, CARD_H)

func _res_row_rect(i: int) -> Rect2:
	return Rect2(s_res.position.x + 12.0, s_res.position.y + 62.0 + i * 68.0, s_res.size.x - 24.0, 60.0)

func _die_home(i: int) -> Vector2:
	return Vector2(s_dice.position.x + 24.0 + DIE_SIZE * 0.5 + i * DIE_STEP, s_dice.position.y + 60.0 + (s_dice.size.y - 60.0 - 96.0) * 0.5 - 4.0)

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

func _register(r: Rect2, cb: Callable) -> void:
	if not ui_live:
		return
	var b := UiButton.new()
	b.rect = r
	b.cb = cb
	buttons.append(b)

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
		"water":
			draw_circle(c + Vector2(0, rad * 0.28), rad * 0.7, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad), c + Vector2(-rad * 0.62, rad * 0.12), c + Vector2(rad * 0.62, rad * 0.12)]), col)
		"sunlight":
			for i in 8:
				var dir := Vector2.from_angle(i * TAU / 8.0)
				draw_line(c + dir * rad * 0.6, c + dir * rad, col, maxf(2.0, rad * 0.2), true)
			draw_circle(c, rad * 0.5, col)
		"nutrient":
			var pts := PackedVector2Array()
			for i in 6:
				pts.append(c + Vector2.from_angle(i * TAU / 6.0 + PI / 6.0) * rad * 0.9)
			draw_colored_polygon(pts, col)
			draw_circle(c, rad * 0.3, col.lightened(0.45))
		"seed":
			var pts := PackedVector2Array()
			for i in 18:
				var a := i * TAU / 18.0
				pts.append(c + Vector2(cos(a) * rad * 0.58, sin(a) * rad).rotated(0.5))
			draw_colored_polygon(pts, col)
		"pollen":
			_star(c, rad, rad * 0.48, col)

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
	hover_tip = ""
	hover_forecast = -1
	draw_rect(Rect2(Vector2.ZERO, window_size), c_bg)
	mouse = _ui_mouse()
	base_xform = Transform2D(0.0, Vector2(ui_scale, ui_scale), 0.0, screen_origin)
	draw_set_transform_matrix(base_xform)
	var picker := _picker_active() and phase == Phase.ACTION
	ui_live = phase == Phase.ACTION and not show_help and not picker
	_draw_header()
	_draw_market()
	_draw_garden()
	_draw_supply()
	_draw_floaters()
	ui_live = phase == Phase.ACTION and not show_help
	if picker:
		_draw_picker()
	else:
		_draw_banner()
	ui_live = true
	if phase == Phase.REPORT:
		_draw_report()
	elif phase == Phase.GAMEOVER:
		_draw_gameover()
	if show_help:
		_draw_help()
	if debug_on:
		_draw_debug()
	if hover_tip != "":
		_draw_tooltip(hover_tip)
	draw_set_transform(Vector2.ZERO)

func _region(p: Rect2, title: String, fill: Color) -> void:
	_panel(p, fill, 28)
	_heavy(Vector2(p.position.x + PANEL_PAD, p.position.y + 44.0), title, T_LG, c_ink)

func _tile(r: Rect2, border: Color = Color(0, 0, 0, 0)) -> void:
	_shadow(r, 20, 4.0)
	_panel(r, c_card, 20, border, 3 if border.a > 0.0 else 0)

func _draw_header() -> void:
	var l := h_left
	_tile(l)
	_text(Vector2(l.position.x + 28.0, l.position.y + 44.0), "BOTANICAL GARDEN", T_XS, c_muted, true)
	var day := "Day %d" % round_n
	_heavy(Vector2(l.position.x + 28.0, l.position.y + 112.0), day, T_HERO, c_ink)
	_text(Vector2(l.position.x + 40.0 + _heavy_w(day, T_HERO), l.position.y + 110.0), "of %d" % rounds_per_run, T_LG, c_muted, true)
	for i in rounds_per_run:
		var c := Vector2(l.end.x - 35.0 - (rounds_per_run - 1 - i) * 22.0, l.position.y + 38.0)
		if i < history.size():
			draw_circle(c, 7.0, c_good if bool(history[i]["hit"]) else c_bad)
		elif i == round_n - 1:
			draw_circle(c, 7.0, c_ink)
		else:
			draw_circle(c, 7.0, c_line)
	_text_right(l.end.x - 28.0, l.position.y + 110.0, "Score %d  ·  Best %s" % [score, "-" if best_score < 0 else str(best_score)], T_SM, c_muted, true)
	_tip(Rect2(l.end.x - 300.0, l.position.y, 300.0, 60.0), "Days so far: green met the target, red missed it.")
	var tw := (h_center.size.x - 2 * 16.0) / 3.0
	for i in mini(forecast.size(), 3):
		_draw_forecast_tile(Rect2(h_center.position.x + i * (tw + 16.0), HEADER_Y, tw, HEADER_H), i)
	var r := h_right
	_tile(r)
	var x := r.position.x + 28.0
	_text(Vector2(x, r.position.y + 44.0), "VICTORY POINTS", T_XS, c_muted, true)
	var vp := _round_vp()
	var target := _target_for(round_n)
	var met := vp >= target
	var vs := str(vp)
	_heavy(Vector2(x, r.position.y + 106.0), vs, T_HERO, c_good if met else c_ink)
	_text(Vector2(x + _heavy_w(vs, T_HERO) + 10.0, r.position.y + 104.0), "/ %d" % target, T_LG, c_muted, true)
	var bar := Rect2(x, r.position.y + 120.0, r.size.x - 56.0, 6.0)
	_panel(bar, c_line, 3)
	var fill := clampf(float(vp) / maxf(1.0, target), 0.0, 1.0)
	if fill > 0.0:
		_panel(Rect2(bar.position, Vector2(maxf(6.0, bar.size.x * fill), bar.size.y)), c_good if met else c_warn, 3)
	var hc := Vector2(r.end.x - 42.0, r.position.y + 38.0)
	var hr := Rect2(hc - Vector2(20, 20), Vector2(40, 40))
	draw_circle(hc, 20.0, Color(c_ink, 0.12 if ui_live and hr.has_point(mouse) else 0.06))
	_heavy_center(hr, "?", T_MD, c_ink)
	_register(hr, func() -> void: show_help = true)
	if miss_rule == MissRule.STRIKES:
		_text_right(r.end.x - 76.0, r.position.y + 44.0, "STRIKES", T_XS, c_muted, true)
		for i in strikes_to_lose:
			var c := Vector2(r.end.x - 39.0 - (strikes_to_lose - 1 - i) * 32.0, r.position.y + 88.0)
			draw_circle(c, 11.0, c_bad if i < strikes else c_line)
	else:
		_text_right(r.end.x - 76.0, r.position.y + 44.0, "DEBT %d" % debt, T_XS, c_bad if debt > 0 else c_muted, true)
	var tip := "Round VP = %d from cards + %d from activations.\nMeet the target or take a strike. VP does not carry over." % [_passive_vp(), act_vp]
	_tip(Rect2(r.position, Vector2(r.size.x - 80.0, r.size.y)), tip)

func _draw_forecast_tile(r: Rect2, i: int) -> void:
	var ev: Dictionary = forecast[i]
	var e: Dictionary = D.EVENTS[ev["id"]]
	var known := i < forecast_visible or bool(ev.get("revealed", false))
	var tier := String(e["tier"])
	var tcol: Color = {"mild": c_good, "moderate": c_warn, "severe": c_bad}.get(tier, c_muted)
	var today := i == 0
	_tile(r, Color(tcol, 0.8) if today else Color(0, 0, 0, 0))
	var x := r.position.x + 22.0
	var label: String = "TODAY" if today else ("TOMORROW" if i == 1 else "DAY %d" % (round_n + i))
	if round_n + i <= rounds_per_run:
		label += "  ·  %d VP" % _target_for(round_n + i)
	_text(Vector2(x, r.position.y + 38.0), label, T_XS, c_muted, true)
	draw_circle(Vector2(x + 6.0, r.position.y + 64.0), 7.0, tcol)
	if not known:
		_heavy(Vector2(x + 22.0, r.position.y + 74.0), "%s event" % String(e["category"]).capitalize(), T_MD, c_muted)
		_text(Vector2(x, r.position.y + 106.0), "Details revealed tomorrow", T_XS, c_muted)
		if debug_on:
			_register(r, _debug_cycle_event.bind(i))
		return
	var title := String(e["name"]) + (" (weakened)" if bool(ev.get("weak", false)) else "")
	_heavy(Vector2(x + 22.0, r.position.y + 74.0), title, _fit(title, r.size.x - 70.0, T_MD), c_ink)
	_wrap(Vector2(x, r.position.y + 84.0), _event_text(ev), r.size.x - 44.0, T_XS, Color(c_ink, 0.7), false, 2)
	var cond := _event_condition(ev)
	if today and not cond.is_empty():
		var ok := _condition_met(cond)
		var tag := "Goal met" if ok else "Goal open"
		var tw := _text_w(tag, T_XS, true) + 20.0
		var tr := Rect2(r.end.x - tw - 16.0, r.position.y + 16.0, tw, 28.0)
		_panel(tr, Color(c_good if ok else c_warn, 0.15), 14)
		_text_center(tr, tag, T_XS, c_good if ok else c_warn, true)
	if r.has_point(mouse) and ui_live:
		hover_forecast = i
	var lines: Array[String] = [String(e["name"]) + ": " + _event_text(ev)]
	if not cond.is_empty():
		lines.append("Goal: " + _condition_text(cond))
	var tu := _event_target_uid(ev) if i > 0 else -1
	if tu >= 0:
		lines.append("Will hit: " + _inst_name(tu))
	if today:
		lines.append_array(round_notes)
	_tip(r, "\n".join(lines))
	if debug_on and i > 0:
		_register(r, _debug_cycle_event.bind(i))

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
			_leaf(Vector2(x - 6.0 * k, y + 6.0 * k), -0.8, 16.0 * k, 8.0 * k, light)
			x += step
		y += step
		row += 1
	var c := inner.get_center()
	draw_circle(c, 38.0 * k, Color.WHITE)
	_icon("sprout", c, 22.0 * k)

func _pile_label(r: Rect2, text: String) -> void:
	var w := _text_w(text, T_SM, true) + 28.0
	var pr := Rect2(r.get_center().x - w * 0.5, r.end.y - 54.0, w, 36.0)
	_material(pr, Color.WHITE, 18)
	_text_center(pr, text, T_SM, c_ink, true)

func _draw_market() -> void:
	_region(p_market, "Market", c_panel)
	var kind := String(choice.get("kind", ""))
	var picking := kind == "replace_market" or (kind == "peek_swap" and int(choice["picked"]) >= 0)
	var frozen := bool(mods.get("market_frozen", false))
	for i in market.size():
		var r := _market_rect(i)
		var id := market[i]
		if id == "":
			_panel(r, Color(c_ink, 0.04), 16)
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
		_draw_card(r, id, null, "market", glow)
		var k := r.size.y / 340.0
		if frozen:
			_panel(r, Color(c_ice, 0.7), int(16.0 * k))
			_heavy_center(r, "Frozen", T_XL, Color("2b5d7a"))
		_register(r, _on_market.bind(i))
		if market_pick == i and choice.is_empty() and not frozen:
			_panel(r, Color(c_ink, 0.42), int(16.0 * k))
			var why := _buy_block(i)
			if why == "":
				var br := Rect2(r.get_center() - Vector2(84.0, 30.0) * k, Vector2(168.0, 60.0) * k)
				_button(br, "Buy", _buy_pick, true, c_accent, T_LG)
			else:
				var msg := why.replace(" this round", "")
				var mw := minf(_text_w(msg, T_SM, true) + 36.0, r.size.x - 24.0 * k)
				var size := T_SM
				while size > 13 and _text_w(msg, size, true) + 36.0 > mw:
					size -= 1
				var mr := Rect2(r.get_center() - Vector2(mw, 52.0 * k) * 0.5, Vector2(mw, 52.0 * k))
				_material(mr, Color.WHITE, int(26.0 * k))
				_text_center(mr, msg, size, c_bad, true)
		elif choice.is_empty():
			_tip(r, _card_tip(id) + "\n" + _cost_explain(id))
	var d0 := _pile_rect(0)
	if deck.is_empty():
		_panel(d0, Color(c_ink, 0.04), 16)
	else:
		for n in mini(3, deck.size() - 1):
			var off := Vector2(4.0, 4.0) * (mini(3, deck.size() - 1) - n)
			_panel(Rect2(d0.position + off, d0.size), Color.WHITE.darkened(0.06 + n * 0.02), 16)
		_shadow(d0, 16)
		_card_back(d0)
	_pile_label(d0, "Deck %d" % deck.size())
	_tip(d0, "Cards still to be dealt into the market.
%d in the discard pile, shuffled back in when the deck runs out." % discard.size())
	var d2 := _pile_rect(1)
	var why_refresh := _refresh_block()
	var can_refresh := why_refresh == "" and choice.is_empty() and phase == Phase.ACTION
	var hov := can_refresh and ui_live and d2.has_point(mouse)
	_panel(d2, Color(c_accent, 0.14 if hov else 0.08) if can_refresh else Color(c_ink, 0.04), 16, Color(c_accent, 0.5) if can_refresh else c_line, 2)
	var cc := d2.get_center() + Vector2(0, -30)
	draw_circle(cc, 34.0, Color.WHITE)
	_icon("swap", cc, 18.0)
	_text_center(Rect2(d2.position.x, cc.y + 44.0, d2.size.x, 34.0), "Refresh market", T_MD, c_ink if can_refresh else c_muted, true)
	_text_center(Rect2(d2.position.x, cc.y + 76.0, d2.size.x, 30.0), "%d Seeds" % _refresh_price(), T_SM, c_accent if can_refresh else c_muted, true)
	if can_refresh:
		_register(d2, _seed_refresh)
	_tip(d2, (why_refresh + "\n" if why_refresh != "" else "") + "Discard the market and deal new cards.")

func _cost_explain(id: String) -> String:
	var v := clampi(int(D.CARDS[id]["value"]), 1, 7)
	return "%s card (value %d)." % [D.COST_TIERS[v]["tier"], v]

func _draw_garden() -> void:
	_region(p_garden, "Garden", c_soil)
	_text_right(p_garden.end.x - PANEL_PAD, p_garden.position.y + 42.0, "%d VP from cards" % _passive_vp(), T_SM, c_muted, true)
	var kind := String(choice.get("kind", ""))
	var warned := {}
	for j in range(1, forecast.size()):
		if j < forecast_visible or bool(forecast[j].get("revealed", false)):
			var u := _event_target_uid(forecast[j])
			if u >= 0 and not warned.has(u):
				warned[u] = "%s %s" % [_event_name(forecast[j]), "tomorrow" if j == 1 else "in %d days" % j]
	var hover_uid := _event_target_uid(forecast[hover_forecast]) if hover_forecast > 0 else -1
	for i in board_slots:
		var r := _board_rect(i)
		var inst := board[i]
		if inst == null:
			_panel(r, Color(c_ink, 0.045), 20)
			var cc := r.get_center()
			draw_line(cc - Vector2(14, 0), cc + Vector2(14, 0), Color(c_ink, 0.15), 3.0, true)
			draw_line(cc - Vector2(0, 14), cc + Vector2(0, 14), Color(c_ink, 0.15), 3.0, true)
			continue
		var glow := Color(0, 0, 0, 0)
		var tip := ""
		if kind == "discard_for":
			glow = Color(c_bad, 0.45 + 0.25 * sin(clock * 5.0))
			tip = "Discard %s" % _card_name(inst.id)
		elif kind == "restore_dormant" and inst.dormant:
			glow = Color(c_gold, 0.55 + 0.3 * sin(clock * 5.0))
		elif hover_uid == inst.uid:
			glow = Color(c_bad, 0.6)
		elif selected_die >= 0 and choice.is_empty():
			var why := _block_reason(inst, selected_die)
			if why == "":
				glow = Color(c_good, 0.45 + 0.3 * sin(clock * 6.0))
			tip = why
		_draw_card(r, inst.id, inst, "board", glow)
		var tags: Array[String] = []
		if int(mods.get("halve_output_uid", -1)) == inst.uid:
			tags.append("Half output today")
		if int(mods.get("halve_value_uid", -1)) == inst.uid:
			tags.append("Half value today")
		if warned.has(inst.uid):
			tags.append(warned[inst.uid])
		for t in tags.size():
			var w := _text_w(tags[t], T_XS, true) + 24.0
			var tr := Rect2(r.get_center().x - w * 0.5, r.end.y - 14.0 - t * 34.0, w, 30.0)
			_panel(tr, c_bad, 15)
			_text_center(tr, tags[t], T_XS, Color.WHITE, true)
		_register(r, _on_board.bind(i))
		if tip == "" and not inst.pending.is_empty():
			tip = "Click or right-click to take the die back"
		if tip == "":
			tip = _card_tip(inst.id)
		_tip(r, tip)

func _draw_supply() -> void:
	_region(p_supply, "Supply", c_panel)
	_text_right(p_supply.end.x - PANEL_PAD, p_supply.position.y + 42.0, "Yours to spend", T_SM, c_muted, true)
	var exchanging := String(choice.get("kind", "")) == "exchange"
	var give := String(choice.get("give", ""))
	var roles := {
		"seed": "Every card costs Seeds; cheap cards cost only Seeds. Also refreshes the market. Trade a die for 1.",
		"water": "Medium and pricier cards cost Water. Converter cards turn Water into VP.",
		"nutrient": "Expensive cards cost Nutrients.",
		"pollen": "Reroll all dice or add a die. Some very expensive cards cost Pollen.",
		"sunlight": "Converter cards turn Sunlight into big VP. Some very expensive cards cost Sunlight.",
	}
	_tile(s_res)
	_text(Vector2(s_res.position.x + 24.0, s_res.position.y + 42.0), "RESOURCES", T_XS, c_muted, true)
	if storage_cap > 0:
		_text_right(s_res.end.x - 24.0, s_res.position.y + 42.0, "CAP %d EACH" % storage_cap, T_XS, c_muted, true)
	for i in D.TYPES.size():
		var k: String = D.TYPES[i]
		var rr := _res_row_rect(i)
		var pick := exchanging and k != give
		var over := storage_cap > 0 and _r(k) > storage_cap
		if exchanging and k == give:
			_panel(rr, Color(_tcol(k), 0.18), 14)
		elif pick and rr.has_point(mouse) and ui_live:
			_panel(rr, Color(c_gold, 0.3), 14)
		elif pick:
			_panel(rr, Color(c_gold, 0.1), 14)
		elif i % 2 == 0:
			_panel(rr, Color(c_bg, 0.7), 14)
		_res_icon(k, Vector2(rr.position.x + 30.0, rr.get_center().y), 15.0)
		_text(Vector2(rr.position.x + 60.0, rr.get_center().y + _vc(font_bold, T_MD)), D.RES_NAMES[k], T_MD, c_ink, true)
		var cap := "/ %d" % storage_cap if storage_cap > 0 else ""
		_text_right(rr.end.x - 16.0, rr.get_center().y + _vc(font_bold, T_SM), cap, T_SM, c_muted, true)
		_heavy_right(rr.end.x - 24.0 - _text_w(cap, T_SM, true), rr.get_center().y + _vc(font_heavy, T_XL), str(_r(k)), T_XL, c_bad if over else c_ink)
		if k == "pollen" and _pollen_locked():
			_text(Vector2(rr.position.x + 180.0, rr.get_center().y + _vc(font_bold, T_XS)), "LOCKED", T_XS, c_bad, true)
		var tip: String = "%s: %s" % [D.RES_NAMES[k], roles[k]]
		if over:
			tip += "\nAbove the cap: %d will be lost at round end." % (_r(k) - storage_cap)
		_tip(rr, tip)
		if pick:
			_register(rr, _on_chip.bind(k))
	var ey := s_res.end.y - 74.0
	_ghost(Rect2(s_res.position.x + 24.0, ey, 230.0, 50.0), "Exchange %d:1" % _rate(), _start_exchange, choice.is_empty() and phase == Phase.ACTION)
	var cp: Dictionary = mods.get("cost_plus", {})
	var notes: Array[String] = []
	for k: String in cp:
		notes.append("Cards +%d %s" % [int(cp[k]), D.RES_NAMES[k]])
	if not notes.is_empty():
		_text_right(s_res.end.x - 24.0, ey + 33.0, ", ".join(notes), T_SM, c_bad, true)
	_tile(s_dice)
	var dx := s_dice.position.x + 24.0
	_text(Vector2(dx, s_dice.position.y + 42.0), "DICE", T_XS, c_muted, true)
	var count := "%d today" % dice.size()
	if extra_dice_next > 0:
		count += "  ·  +%d tomorrow" % extra_dice_next
	_text_right(s_dice.end.x - 24.0, s_dice.position.y + 42.0, count.to_upper(), T_XS, c_accent if extra_dice_next > 0 else c_muted, true)
	var why_note := "%d base" % base_dice
	if not dice_notes.is_empty():
		why_note += ", " + ", ".join(dice_notes)
	_tip(Rect2(s_dice.position.x, s_dice.position.y, s_dice.size.x, 60.0), "Dice this round: %s (always %d-%d)." % [why_note, min_dice, max_dice])
	for i in dice.size():
		var d := dice[i]
		var home := _die_home(i)
		var box := Rect2(home - Vector2(DIE_SIZE, DIE_SIZE) * 0.5, Vector2(DIE_SIZE, DIE_SIZE))
		if d.used or d.card_uid != -1:
			_panel(box, Color(c_ink, 0.05), 20)
			continue
		var sel := i == selected_die
		var lift := -10.0 if sel else (-4.0 if box.has_point(mouse) and ui_live else 0.0)
		if d.roll_t > 0.0:
			lift = -absf(sin(d.roll_t * 22.0)) * 16.0
		_die_body(home + Vector2(0, lift), DIE_SIZE, d.shown, Color.WHITE, c_ink, c_good if sel else Color(0, 0, 0, 0))
		_register(box.grow(6.0), _on_die.bind(i))
	var bw := (s_dice.size.x - 48.0 - 24.0) / 3.0
	var by := s_dice.end.y - 24.0 - 72.0
	var pollen := _tcol("pollen")
	var b1 := Rect2(dx, by, bw, 72.0)
	var b2 := Rect2(dx + bw + 12.0, by, bw, 72.0)
	var b3 := Rect2(dx + (bw + 12.0) * 2.0, by, bw, 72.0)
	var trade_why := _trade_block()
	_button(b1, "-1 die", _trade_die, trade_why == "", _tcol("seed"), T_MD, "+%d Seed" % trade_die_seeds)
	_button(b2, "+1 die", _add_die, _add_die_block() == "", pollen, T_MD, "%d Pollen" % add_die_cost)
	_button(b3, "Reroll all", _reroll_all, _reroll_block() == "", pollen, T_MD, "%d Pollen" % reroll_cost)
	_tip(b1, trade_why if trade_why != "" else "Give up %s for %d Seed." % ["the selected die" if _die_free(selected_die) else "an unused die", trade_die_seeds])
	_tip(b2, _add_die_block() if _add_die_block() != "" else "Roll one more die today.")
	_tip(b3, _reroll_block() if _reroll_block() != "" else "Reroll every unused die.")
	_tile(s_end)
	var vp := _round_vp()
	var target := _target_for(round_n)
	var free := 0
	for i in dice.size():
		if _die_free(i):
			free += 1
	var met := vp >= target
	var head := "Target met" if met else "Short by %d VP" % (target - vp)
	_heavy(Vector2(s_end.position.x + 24.0, s_end.position.y + 54.0), head, T_LG, c_good if met else c_warn)
	if free > 0:
		_text_right(s_end.end.x - 24.0, s_end.position.y + 52.0, "%d unused %s" % [free, "die" if free == 1 else "dice"], T_SM, c_muted, true)
	var eb := Rect2(s_end.position.x + 24.0, s_end.end.y - 24.0 - 104.0, s_end.size.x - 48.0, 104.0)
	_button(eb, "End Day", _end_round, phase == Phase.ACTION and choice.is_empty(), c_accent if met else c_ink, T_XL)

func _card_tip(id: String) -> String:
	var c: Dictionary = D.CARDS[id]
	var p := _base_pattern(id)
	var s := "%s (%s, value %d)\n%s" % [c["name"], D.TYPE_NAMES[c["type"]], int(c["value"]), c["text"]]
	if not p.is_empty():
		s += "\nActivate with: %s (%s)" % [_pattern_label(p), _pattern_rule(p)]
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
						line.append_array([{"icon": String(e["type"])}, "card"])
					"activations":
						line.append("card activated")
					"distinct_types":
						line.append("type activated")
					"market_cards":
						line.append("market card")
					"empty_slots":
						line.append("empty slot")
			"extra_die":
				line = ["+%d" % int(e["amount"]), {"icon": "die"}, "tomorrow"]
			"forecast_weaken":
				line = [{"icon": "cloud"}, "Weaken tomorrow"]
			"forecast_delay":
				line = [{"icon": "cloud"}, "Delay tomorrow"]
			"forecast_cancel":
				line = [{"icon": "cloud"}, "Cancel tomorrow"]
			"forecast_reveal":
				line = [{"icon": "cloud"}, "Reveal the forecast"]
			"restore_dormant":
				line = [{"icon": "sprout"}, "Restore a dormant card"]
			"replace_market":
				line = [{"icon": "swap"}, "Replace a market card"]
			"peek_swap":
				line = [{"icon": "eye"}, "Peek %d, swap 1 in" % int(e.get("count", 3))]
			"gain_random_card":
				line = [{"icon": "card"}, "Plant a random card"]
			"refresh_type":
				line = [{"icon": "swap"}, "Refresh one type"]
			"refresh_market":
				line = [{"icon": "swap"}, "Refresh the market"]
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
		"cloud":
			var col := Color("8aa0b4")
			draw_circle(c + Vector2(-rad * 0.45, rad * 0.15), rad * 0.45, col)
			draw_circle(c + Vector2(rad * 0.1, -rad * 0.2), rad * 0.58, col)
			draw_circle(c + Vector2(rad * 0.55, rad * 0.2), rad * 0.4, col)
			draw_rect(Rect2(c + Vector2(-rad * 0.45, rad * 0.05), Vector2(rad, rad * 0.55)), col)
		"sprout":
			draw_line(c + Vector2(0, rad), c + Vector2(0, -rad * 0.1), c_good, maxf(2.0, rad * 0.2), true)
			_leaf(c + Vector2(0, -rad * 0.1), -2.5, rad * 1.1, rad * 0.6, c_good)
			_leaf(c + Vector2(0, -rad * 0.1), -0.64, rad * 1.1, rad * 0.6, c_good.lightened(0.15))
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

func _tokens_w(cost: Dictionary, rad: float, size: int) -> float:
	var w := 0.0
	for r: String in D.TYPES:
		if cost.has(r):
			w += _heavy_w(str(int(cost[r])), size) + 3.0 + rad * 2.0 + 14.0
	return maxf(0.0, w - 14.0)

func _draw_card(r: Rect2, id: String, inst: CardInst, where: String, glow: Color) -> void:
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
	_panel(r, Color.WHITE, radius)
	var inner := r.grow(-9.0 * k)
	var ir := int(10.0 * k)
	_panel(inner, tcol.lerp(Color.WHITE, 0.6), ir)
	var pad := 8.0 * k
	var bar := Rect2(inner.position + Vector2(pad, pad), Vector2(inner.size.x - pad * 2.0, 70.0 * k))
	var lines := _ability_lines(id)
	var strip := Rect2(inner.position.x, inner.end.y - 10.0 * k - 84.0 * k, inner.size.x, 84.0 * k)
	_draw_art(inner, id, tcol, bar.end.y - 24.0 * k, strip.position.y + 10.0 * k)
	_material(bar, Color.WHITE, int(12.0 * k))
	var badge := bar.position + Vector2(24.0 * k, bar.size.y * 0.5)
	var value := _effective_value(inst) if inst != null else int(c["value"])
	draw_circle(badge, 16.0 * k, tcol)
	_heavy_center(Rect2(badge - Vector2(16, 17) * k, Vector2(32, 32) * k), str(value), int(19.0 * k), Color.WHITE)
	var nx := bar.position.x + 48.0 * k
	var name := String(c["name"])
	var nsz := _fit(name, bar.end.x - 8.0 * k - nx, int(22.0 * k))
	_heavy(Vector2(nx, bar.position.y + 30.0 * k), name, nsz, c_ink)
	_tokens(nx, bar.position.y + 52.0 * k, _cost(id), 9.0 * k, int(18.0 * k), where == "market")
	_material(strip, Color("fbf9f2"), 0)
	var lh := 26.0 * k
	var top := strip.position.y + 18.0 * k
	var ly := top + (strip.end.y - 4.0 * k - top - lines.size() * lh) * 0.5 + lh * 0.5
	for line: Array in lines:
		_draw_token_line(Vector2(inner.position.x + 12.0 * k, ly), line, int(17.0 * k), k * 0.9)
		ly += lh
	var p := _effective_pattern(inst) if inst != null else _base_pattern(id)
	var need := _dice_needed(p)
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
		_heavy_center(Rect2(pill.position, Vector2(pw, 48.0 * k)), "Dormant", int(24.0 * k), c_ink)
		_text_center(Rect2(pill.position + Vector2(0, 42.0 * k), Vector2(pw, 28.0 * k)), "Any die restores it", int(15.0 * k), c_muted, true)

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

func _leaf(base: Vector2, ang: float, length: float, width: float, col: Color) -> void:
	var dir := Vector2.from_angle(ang)
	var nrm := dir.orthogonal()
	var pts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		pts.append(base + dir * length * t + nrm * sin(t * PI) * width * 0.5)
	for i in range(7, 0, -1):
		var t := i / 8.0
		pts.append(base + dir * length * t - nrm * sin(t * PI) * width * 0.5)
	draw_colored_polygon(pts, col)

func _bez(a: Vector2, b: Vector2, c: Vector2, n: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := i / float(n)
		pts.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
	return pts

func _draw_art(r: Rect2, id: String, tcol: Color, top: float, ground: float) -> void:
	var a: Dictionary = D.CARDS[id].get("art", {})
	var k := r.size.y / 340.0
	var br := minf(r.size.x * 0.4, (ground - top) * 0.5)
	draw_circle(Vector2(r.get_center().x, top + (ground - top) * 0.5), br, tcol.lerp(Color.WHITE, 0.78))
	_dome(Vector2(r.get_center().x, r.end.y), r.size.x * 0.46, 22.0 * k, tcol.lerp(Color.WHITE, 0.42))
	var s := minf((ground - top) / 160.0, r.size.x / 150.0)
	var origin := Vector2(r.get_center().x - 80.0 * s, ground - 160.0 * s)
	draw_set_transform_matrix(base_xform * Transform2D(0.0, Vector2(s, s), 0.0, origin))
	_draw_plant(a)
	draw_set_transform_matrix(base_xform)

func _draw_plant(a: Dictionary) -> void:
	var leaf := Color(a.get("leaf", "5e8a3a"))
	var bloom := Color(a.get("bloom", "e8892b"))
	match String(a.get("form", "sprout")):
		"flower":
			var hgt := float(a.get("height", 92))
			var sz := float(a.get("size", 1.0))
			var top := Vector2(80, 156 - hgt)
			var stem := _bez(Vector2(80, 158), Vector2(88, 156 - hgt * 0.5), top)
			draw_polyline(stem, leaf.darkened(0.1), 4.0, true)
			_leaf(stem[10], -2.6, 34, 13, leaf)
			_leaf(stem[7], -0.5, 32, 12, leaf.lightened(0.1))
			var n := int(a.get("petals", 6))
			for i in n:
				var ang := i * TAU / n - PI / 2
				_ell(top + Vector2.from_angle(ang) * 14 * sz, 13 * sz, 7 * sz, ang, bloom)
			for i in n:
				var ang := (i + 0.5) * TAU / n - PI / 2
				_ell(top + Vector2.from_angle(ang) * 9 * sz, 9 * sz, 5 * sz, ang, bloom.lightened(0.18))
			draw_circle(top, 8 * sz, Color(a.get("center", "8a4a1c")))
		"fern":
			var pts := _bez(Vector2(86, 158), Vector2(92, 74), Vector2(52, 24), 20)
			draw_polyline(pts, leaf.darkened(0.25), 3.0, true)
			for i in range(2, 20, 2):
				var tang := (pts[i + 1] - pts[i - 1]).angle()
				var ln := lerpf(38, 12, i / 20.0)
				_leaf(pts[i], tang - 1.25, ln, ln * 0.34, leaf)
				_leaf(pts[i], tang + 1.25, ln, ln * 0.34, leaf.lightened(0.12))
			var p2 := _bez(Vector2(66, 158), Vector2(60, 124), Vector2(30, 108), 10)
			draw_polyline(p2, leaf.darkened(0.15), 2.5, true)
			for i in range(2, 10, 2):
				var tang := (p2[i + 1] - p2[i - 1]).angle()
				_leaf(p2[i], tang - 1.2, 18 - i, 6, leaf.lightened(0.2))
				_leaf(p2[i], tang + 1.2, 18 - i, 6, leaf.lightened(0.28))
		"tree":
			var canopy := Color(a.get("canopy", "4f7f3a"))
			draw_colored_polygon(PackedVector2Array([Vector2(73, 158), Vector2(87, 158), Vector2(84, 92), Vector2(76, 92)]), Color("6b4a32"))
			draw_line(Vector2(80, 108), Vector2(62, 88), Color("6b4a32"), 4.0, true)
			draw_line(Vector2(80, 102), Vector2(100, 84), Color("6b4a32"), 4.0, true)
			if bool(a.get("droop", false)):
				_ell(Vector2(80, 66), 50, 32, 0.0, canopy)
				for i in 11:
					var x := 34.0 + i * 9.2
					var bot := 132.0 - absf(i - 5) * 7.0
					draw_polyline(_bez(Vector2(x, 70), Vector2(x - 6, (70 + bot) * 0.5), Vector2(x - 2, bot), 8), canopy.darkened(0.12), 3.5, true)
				_ell(Vector2(70, 56), 26, 16, 0.0, canopy.lightened(0.12))
			else:
				var blobs := [[Vector2(80, 56), 34.0], [Vector2(50, 74), 26.0], [Vector2(110, 74), 26.0], [Vector2(64, 42), 24.0], [Vector2(98, 40), 24.0]]
				for i in blobs.size():
					draw_circle(blobs[i][0], blobs[i][1], canopy if i % 2 == 0 else canopy.lightened(0.1))
				if canopy.r > canopy.g:
					_ell(Vector2(124, 124), 5, 3, 0.6, canopy)
					_ell(Vector2(36, 138), 5, 3, -0.4, canopy.lightened(0.1))
		"reeds":
			for i in 7:
				var x0 := 44.0 + i * 12.0
				var hgt := 70.0 + float((i * 37) % 3) * 24.0
				var tip := Vector2(x0 + (i - 3) * 6.0, 156.0 - hgt)
				draw_polyline(_bez(Vector2(x0, 158), Vector2(x0, 156 - hgt * 0.6), tip, 10), leaf if i % 2 == 0 else leaf.lightened(0.12), 4.0, true)
				if i == 1 or i == 4:
					_ell(tip + Vector2(0, 16), 5, 14, (i - 3) * 0.06, Color("7a4b2a"))
		"pad":
			_ell(Vector2(80, 150), 64, 12, 0.0, Color("4a86b8").lightened(0.35))
			_ell(Vector2(46, 126), 34, 10, 0.0, leaf)
			_ell(Vector2(116, 132), 26, 8, 0.0, leaf.lightened(0.12))
			var fc := Vector2(80, 110)
			for i in 7:
				var ang := -PI + (i + 0.5) * PI / 7.0
				_ell(fc + Vector2.from_angle(ang) * 13, 15, 5.5, ang, bloom if i % 2 == 0 else bloom.lightened(0.15))
			draw_circle(fc, 6, Color("f2c230"))
		"clover":
			var tops := [Vector2(54, 96), Vector2(82, 74), Vector2(108, 100)]
			for i in 3:
				var tp: Vector2 = tops[i]
				draw_polyline(_bez(Vector2(80, 158), Vector2(80 + (tp.x - 80) * 0.3, 120), tp, 10), leaf.darkened(0.1), 3.0, true)
				if i == 1:
					for j in 12:
						draw_circle(tp + Vector2.from_angle(j * 2.4) * (3.0 + j * 0.7), 4.5, bloom if j % 2 == 0 else bloom.lightened(0.2))
				else:
					for j in 3:
						draw_circle(tp + Vector2.from_angle(j * TAU / 3.0 - PI / 2) * 8, 9, leaf if j % 2 == 0 else leaf.lightened(0.1))
		"vine":
			draw_line(Vector2(80, 158), Vector2(80, 18), Color("8a6a48"), 5.0, true)
			var vpts := PackedVector2Array()
			for i in 34:
				var y := 156.0 - i * 4.0
				vpts.append(Vector2(80 + sin(y * 0.12) * 16.0, y))
			draw_polyline(vpts, leaf.darkened(0.1), 3.0, true)
			for i in range(3, 34, 6):
				_leaf(vpts[i], PI if (i / 6) % 2 == 0 else 0.0, 22, 13, leaf if i % 12 < 6 else leaf.lightened(0.12))
			_ell(vpts[9] + Vector2(10, 14), 4, 13, 0.2, bloom.darkened(0.15))
			_ell(vpts[21] + Vector2(-10, 14), 4, 13, -0.2, bloom.darkened(0.15))
		"bell":
			var tall := bool(a.get("tall", false))
			var stem := _bez(Vector2(78, 158), Vector2(74, 90), Vector2(92, 18 if tall else 40), 20)
			draw_polyline(stem, leaf.darkened(0.1), 3.5, true)
			_leaf(Vector2(78, 154), -2.8, 42, 15, leaf)
			_leaf(Vector2(78, 154), -0.35, 42, 15, leaf.lightened(0.1))
			var count := 6 if tall else 4
			for i in count:
				var p: Vector2 = stem[8 + i * (12 / count)]
				var sz := 1.0 - i * 0.08
				var b := p + Vector2(6, 2)
				draw_colored_polygon(PackedVector2Array([b + Vector2(0, -2) * sz, b + Vector2(12, -2) * sz, b + Vector2(17, 16) * sz, b + Vector2(-5, 16) * sz]), bloom)
				_ell(b + Vector2(6, 16) * sz, 11 * sz, 3.5 * sz, 0.0, bloom.darkened(0.2))
		"mushroom":
			for i in 5:
				var y := 150.0 + i * 1.5
				draw_polyline(_bez(Vector2(20 + i * 6, y), Vector2(80, y - 10), Vector2(140 - i * 5, y), 10), Color(1, 1, 1, 0.55), 1.5, true)
			var caps := [[Vector2(64, 156), 40.0, 1.0], [Vector2(104, 156), 26.0, 0.75]]
			for m: Array in caps:
				var base: Vector2 = m[0]
				var hgt: float = m[1]
				var sz: float = m[2]
				draw_rect(Rect2(base + Vector2(-6 * sz, -hgt), Vector2(12 * sz, hgt)), Color("f1e6d0"))
				_dome(base + Vector2(0, -hgt + 2), 26 * sz, 22 * sz, bloom)
				for j in 3:
					draw_circle(base + Vector2((j - 1) * 10 * sz, -hgt - 10 * sz + absf(j - 1) * 5 * sz), 3 * sz, Color(1, 1, 1, 0.85))
		"puff":
			draw_polyline(_bez(Vector2(80, 158), Vector2(84, 110), Vector2(78, 60), 12), leaf.darkened(0.1), 3.0, true)
			_leaf(Vector2(80, 154), -2.7, 40, 12, leaf)
			_leaf(Vector2(80, 154), -0.4, 38, 12, leaf.lightened(0.1))
			var hc := Vector2(78, 50)
			for i in 26:
				var dir := Vector2.from_angle(i * TAU / 26.0)
				draw_line(hc, hc + dir * 24, Color("9aa58e"), 1.2, true)
				draw_circle(hc + dir * 25, 2.6, Color.WHITE)
			draw_circle(hc, 5, Color("c9b98e"))
			for sp: Vector2 in [Vector2(122, 40), Vector2(134, 22), Vector2(110, 18)]:
				draw_line(sp, sp + Vector2(-5, 7), Color("9aa58e"), 1.2, true)
				draw_circle(sp, 2.6, Color.WHITE)
		"spike":
			for i in 3:
				var base := Vector2(72 + i * 8, 158)
				var top := Vector2(56 + i * 24, 34 + (i % 2) * 16)
				draw_line(base, top, leaf.darkened(0.1), 2.5, true)
				for j in 8:
					var p := top.lerp(base, j * 0.055)
					_ell(p + Vector2(3.0 if j % 2 == 0 else -3.0, 0), 3.6, 5.5, 0.0, bloom if j % 2 == 0 else bloom.lightened(0.15))
			_leaf(Vector2(80, 156), -2.2, 34, 7, leaf)
			_leaf(Vector2(80, 156), -0.9, 34, 7, leaf.lightened(0.1))
		"burst":
			draw_line(Vector2(80, 158), Vector2(80, 62), leaf.darkened(0.1), 4.0, true)
			_leaf(Vector2(80, 118), -2.7, 32, 12, leaf)
			_leaf(Vector2(80, 112), -0.45, 32, 12, leaf.lightened(0.1))
			var bc := Vector2(80, 54)
			for i in 11:
				var ang := -PI - 0.15 + i * (PI + 0.3) / 10.0
				var tip := bc + Vector2.from_angle(ang) * 30
				draw_line(bc, tip, bloom, 4.5, true)
				draw_circle(tip, 3.6, bloom.lightened(0.22))
			draw_circle(bc, 10, bloom.darkened(0.3))
			_ell(Vector2(130, 34), 5, 3.5, -0.4, Color(1, 1, 1, 0.8))
			_ell(Vector2(126, 30), 5, 3.5, 0.4, Color(1, 1, 1, 0.8))
			_ell(Vector2(130, 40), 8, 6, 0.2, Color("e9b949"))
			draw_line(Vector2(129, 35), Vector2(127, 45), Color("1e2b22"), 2.0, true)
		"cluster":
			draw_line(Vector2(80, 158), Vector2(80, 68), leaf.darkened(0.1), 4.0, true)
			_leaf(Vector2(80, 124), -2.6, 34, 13, leaf)
			_leaf(Vector2(80, 116), -0.5, 34, 13, leaf.lightened(0.1))
			var cc := Vector2(80, 66)
			for row in 4:
				var hw := 30.0 - row * 7.0
				var x := -hw
				while x <= hw:
					draw_circle(cc + Vector2(x + (row % 2) * 4.0, -row * 8.0), 4.8, bloom.lightened(row * 0.07))
					x += 8.0
		"sprout":
			_dome(Vector2(80, 158), 46, 14, Color("8b6a4f").lightened(0.2))
			draw_line(Vector2(80, 150), Vector2(80, 100), leaf.darkened(0.1), 4.0, true)
			_leaf(Vector2(80, 102), -2.5, 42, 22, leaf)
			_leaf(Vector2(80, 102), -0.64, 42, 22, leaf.lightened(0.12))
		"spring":
			var water := Color("4a86b8")
			_ell(Vector2(80, 150), 50, 9, 0.0, Color(water, 0.55))
			for side: float in [-1.0, 1.0]:
				var arc := PackedVector2Array()
				for i in 13:
					var t := i / 12.0
					arc.append(Vector2(80 + side * t * 36.0, 140 - 84.0 * t * (1.6 - t)))
				draw_polyline(arc, water, 4.0, true)
				draw_circle(arc[12] + Vector2(side * 4, 6), 3.5, water)
			draw_line(Vector2(80, 142), Vector2(80, 60), water.lightened(0.2), 5.0, true)
			draw_circle(Vector2(80, 56), 5, water.lightened(0.2))
			_ell(Vector2(50, 152), 22, 9, 0.0, Color("9aa39a"))
			_ell(Vector2(108, 154), 26, 8, 0.0, Color("8a948b"))
			_ell(Vector2(80, 156), 16, 7, 0.0, Color("b3bbb2"))
		"barrel":
			var wood := Color("8b5e3c")
			draw_colored_polygon(PackedVector2Array([Vector2(46, 158), Vector2(114, 158), Vector2(119, 114), Vector2(114, 74), Vector2(46, 74), Vector2(41, 114)]), wood)
			for x: float in [58.0, 70.0, 82.0, 94.0, 106.0]:
				draw_line(Vector2(x, 78), Vector2(x, 154), wood.darkened(0.15), 1.5, true)
			draw_line(Vector2(43, 94), Vector2(117, 94), Color("5a3b22"), 5.0, true)
			draw_line(Vector2(43, 136), Vector2(117, 136), Color("5a3b22"), 5.0, true)
			_ell(Vector2(80, 74), 34, 8, 0.0, Color("4a86b8"))
			for dp: Vector2 in [Vector2(58, 34), Vector2(84, 18), Vector2(104, 42)]:
				draw_circle(dp + Vector2(0, 4), 4.5, Color("4a86b8"))
				draw_colored_polygon(PackedVector2Array([dp + Vector2(0, -6), dp + Vector2(-4, 2), dp + Vector2(4, 2)]), Color("4a86b8"))

func _draw_banner() -> void:
	var kind := String(choice.get("kind", ""))
	var text := ""
	var action := ""
	var alpha := 1.0
	if kind != "":
		text = String(choice["prompt"])
		action = "Cancel" if kind == "discard_for" or kind == "exchange" else "Skip"
	elif _die_free(selected_die) and phase == Phase.ACTION:
		var v := dice[selected_die].value
		text = "Place the %d on a glowing card" % v
		var fits := false
		for inst in board:
			if inst != null and _block_reason(inst, selected_die) == "":
				fits = true
		if not fits:
			text = "No card takes a %d. Trade it for a Seed or pick another die" % v
	elif toast != "" and clock - toast_t < 3.0 and phase == Phase.ACTION:
		text = toast
		alpha = clampf((3.0 - (clock - toast_t)) / 0.5, 0.0, 1.0)
	if text == "":
		return
	var size := T_SM
	var aw := _text_w(action, size, true) + 36.0 if action != "" else 0.0
	var max_w := p_garden.size.x - 420.0
	while size > 14 and _text_w(text, size, true) + 48.0 + aw > max_w:
		size -= 1
	aw = _text_w(action, size, true) + 36.0 if action != "" else 0.0
	var w := _text_w(text, size, true) + 48.0 + aw
	var r := Rect2(p_garden.get_center().x - w * 0.5, p_garden.position.y + 12.0, w, 44.0)
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
			_button(Rect2((UI_W - total) * 0.5 + j * (bw + 16.0), cy - 60.0, bw, 90.0), D.TYPE_NAMES[t], _refresh_type.bind(t), true, _tcol(t), T_LG, "%d in market" % n)
	_ghost(Rect2(UI_W * 0.5 - 110.0, cy + 190.0, 220.0, 56.0), "Skip", _skip_choice, true, Color.WHITE)

func _draw_floaters() -> void:
	for f in floaters:
		var a := clampf(f.life / 0.5, 0.0, 1.0)
		var w := _heavy_w(f.text, T_LG)
		_heavy(f.pos - Vector2(w * 0.5, 0.0), f.text, T_LG, Color(f.color, a))

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
	_panel(r, c_card, 28)
	return r

func _row(x: float, w: float, y: float, label: String, value: String, col: Color = c_ink) -> void:
	_text(Vector2(x, y), label, T_MD, c_muted, true)
	_heavy_right(x + w, y, value, T_LG, col)

func _draw_report() -> void:
	var extra := int(report.has("cond")) + (report["lost"] as Dictionary).size() + (report["notes"] as Array).size()
	var r := _modal(900.0, 620.0 + extra * 40.0)
	var hit := bool(report["hit"])
	var x := r.position.x + 64.0
	var w := r.size.x - 128.0
	_text(Vector2(x, r.position.y + 76.0), "DAY %d  ·  %s" % [int(report["round"]), String(report["event"]).to_upper()], T_SM, c_muted, true)
	_heavy(Vector2(x, r.position.y + 146.0), "Target met" if hit else "Target missed", T_HERO, c_good if hit else c_bad)
	var y := r.position.y + 228.0
	_row(x, w, y, "From cards", str(int(report["passive"])))
	y += 48.0
	var n := int(report["activations"])
	_row(x, w, y, "From activations (%d card%s)" % [n, "" if n == 1 else "s"], str(int(report["act"])))
	y += 22.0
	draw_line(Vector2(x, y), Vector2(x + w, y), c_line, 2.0)
	y += 44.0
	_row(x, w, y, "Total", "%d / %d" % [int(report["vp"]), int(report["target"])], c_good if hit else c_bad)
	y += 72.0
	var lines: Array = []
	if hit:
		var surplus := int(report["surplus"])
		if surplus > 0:
			lines.append(["+%d surplus added to score (now %d)" % [surplus, score], c_good])
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
			lines.append(["%s: goal missed, penalty tomorrow" % cd["name"], c_bad])
	var lost: Dictionary = report["lost"]
	for k: String in lost:
		lines.append(["Storage cap: lost %d %s" % [int(lost[k]), D.RES_NAMES[k]], c_warn])
	for note: String in report["notes"]:
		lines.append([note, c_muted])
	for l: Array in lines:
		_text(Vector2(x, y), String(l[0]), T_MD, l[1], true)
		y += 40.0
	var label := "Next day"
	if game_result == "won":
		label = "See results"
	elif game_result == "lost":
		label = "See results"
	_button(Rect2(r.get_center().x - 180.0, r.end.y - 116.0, 360.0, 80.0), label, _continue, true, c_accent, T_LG)

func _draw_gameover() -> void:
	var r := _modal(1400.0, 940.0)
	var won := game_result == "won"
	var x := r.position.x + 70.0
	_heavy(Vector2(x, r.position.y + 120.0), "Your garden thrived" if won else "Your garden withered", T_HERO, c_good if won else c_bad)
	_text(Vector2(x, r.position.y + 172.0), "%s after %d days  ·  seed %d" % ["Survived" if won else "Eliminated", history.size(), seed_used], T_MD, c_muted, true)
	var sc := "Score %d" % score
	_heavy(Vector2(x, r.position.y + 260.0), sc, T_HERO - 8, c_ink)
	var best_txt := "New best" if score >= best_score and score > 0 else "Best %d" % best_score
	_text(Vector2(x + _heavy_w(sc, T_HERO - 8) + 28.0, r.position.y + 256.0), best_txt, T_LG, c_accent, true)
	var tp := 0
	var ta := 0
	for h in history:
		tp += int(h["passive"])
		ta += int(h["act"])
	_text(Vector2(x, r.position.y + 310.0), "%d%% of VP came from activations" % roundi(100.0 * ta / maxi(1, tp + ta)), T_MD, c_muted, true)
	var chart := Rect2(x, r.position.y + 360.0, r.size.x - 140.0, 360.0)
	var top := 1
	for h in history:
		top = maxi(top, maxi(int(h["vp"]), int(h["target"])))
	var bw := chart.size.x / maxf(1.0, rounds_per_run)
	for i in history.size():
		var h: Dictionary = history[i]
		var bx := chart.position.x + i * bw + bw * 0.2
		var bww := bw * 0.6
		var ph := chart.size.y * int(h["passive"]) / top
		var ah := chart.size.y * int(h["act"]) / top
		var base_y := chart.end.y
		_panel(Rect2(bx, base_y - ph, bww, ph), Color(c_accent, 0.5), 4)
		if ah > 0.0:
			_panel(Rect2(bx, base_y - ph - ah, bww, ah), c_gold, 4)
		var ty := base_y - chart.size.y * int(h["target"]) / top
		draw_line(Vector2(bx - 8.0, ty), Vector2(bx + bww + 8.0, ty), c_bad if not bool(h["hit"]) else c_ink, 3.0)
		_text_center(Rect2(bx, base_y + 6.0, bww, 32.0), str(i + 1), T_SM, c_muted, true)
	_text(Vector2(chart.position.x, chart.end.y + 70.0), "Green: from cards   Gold: from activations   Line: target", T_SM, c_muted, true)
	_button(Rect2(r.end.x - 430.0, r.end.y - 116.0, 360.0, 80.0), "New run", func() -> void: _new_run(randi_range(1, 999999)), true, c_accent, T_LG)
	_ghost(Rect2(r.end.x - 810.0, r.end.y - 116.0, 360.0, 80.0), "Replay seed", func() -> void: _new_run(seed_used), true)

func _draw_help() -> void:
	var r := _modal(1800.0, 1100.0)
	var x := r.position.x + 70.0
	var col_w := (r.size.x - 200.0) / 2.0
	_heavy(Vector2(x, r.position.y + 96.0), "How to play", T_HERO - 12, c_ink)
	var left := "\n".join([
		"Each day:",
		"1. Today's forecast event takes effect.",
		"2. Roll %d dice (always %d-%d after modifiers)." % [base_dice, min_dice, max_dice],
		"3. Click a die, then a garden card whose pattern it matches. Each card activates once per day. Two-die patterns activate once both dice are placed.",
		"4. Buy market cards (they go straight into the garden), refresh the market for %d Seeds, exchange %d:1, trade an unused die for %d Seed, or spend Pollen on dice (%d: +1 die, %d: reroll all)." % [refresh_cost, exchange_rate, trade_die_seeds, add_die_cost, reroll_cost],
		"5. End the day. VP = card values + activation VP. Meet the target or take a strike (%d strikes ends the run). VP does not carry over." % strikes_to_lose,
		"6. The forecast moves forward." if storage_cap <= 0 else "6. Resources above %d are lost. The forecast moves forward." % storage_cap,
		"",
		"Dormant cards don't score and can't activate. Any die restores one, without triggering its ability.",
	])
	_wrap(Vector2(x, r.position.y + 140.0), left, col_w, T_MD, c_ink)
	var rx := x + col_w + 60.0
	var right := "\n".join([
		"Costs by card value:",
		"- Inexpensive (1-2): Seeds only.",
		"- Medium (3-4): Seeds and Water.",
		"- Expensive (5): Seeds, Water and Nutrients.",
		"- Very expensive (6-7): Seeds, Water, Nutrients, plus Sunlight or Pollen.",
		"Converter cards spend Water or Sunlight for VP.",
		"",
		"Patterns: Odd, Even, Low (1-3), High (4-6), Exactly N, N+, N or less, Any, Pair, Sum N+, Sum = N, Run (two consecutive values).",
		"",
		"Hover anything for details.",
		"Keys: Enter = end day / continue, Esc = cancel, H = help, F1 = debug.",
	])
	_wrap(Vector2(rx, r.position.y + 140.0), right, col_w, T_MD, c_ink)
	ui_live = true
	_button(Rect2(r.get_center().x - 160.0, r.end.y - 110.0, 320.0, 72.0), "Got it", func() -> void: show_help = false, true, c_accent, T_LG)

func _draw_debug() -> void:
	var r := Rect2(40.0, UI_H - 140.0, 620.0, 100.0)
	_panel(r, Color(0, 0, 0, 0.8), 14)
	var lines := "DEBUG  ·  1-6 set selected die  ·  R +1 all resources\nD add a die  ·  N skip day  ·  click forecast day 2/3 to cycle"
	_wrap(r.position + Vector2(18.0, 14.0), lines, r.size.x - 36.0, T_SM, Color("9ef0a8"), true)
