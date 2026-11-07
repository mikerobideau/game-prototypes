extends Node2D
class_name MainStreetPrototype

@export_group("Run")
@export var total_days: int = 20
@export var starting_cash: float = 40.0
@export var market_size: int = 3
@export var bill_base: float = 3.0
@export var bill_growth: float = 1.18

@export_group("Properties")
@export var size_prices := {"penny": 8.0, "small": 14.0, "mid": 22.0, "blue": 32.0}
@export var max_level: int = 3
@export var sell_rate: float = 0.8
## Every event's money is multiplied by this. Turn it up or down to make the whole game richer or poorer.
@export var event_scale: float = 1.0

@export_group("Partners")
@export var retail_bonus: float = 0.5
@export var finance_rent_cut: float = 0.15

@export_group("Plans")
@export var hand_size: int = 3
@export var starting_hand: Array[String] = ["reroll", "nudge_up"]

@export_group("Feel")
@export var close_anim_seconds: float = 1.6
@export var roll_seconds: float = 1.0

enum Phase { TRADE, ROLL, PLACE, CLOSING, REPORT, GAMEOVER }

const STREET_COLS := 3
const LOTS := STREET_COLS * 2
const WILD := 2

var sector_names: Array[String] = []
var size_defs := {
	"penny": {"label": "Penny", "chip": Color("b8692f")},
	"small": {"label": "Small Cap", "chip": Color("6b7486")},
	"mid": {"label": "Mid Cap", "chip": Color("3f5f7a")},
	"blue": {"label": "Blue Chip", "chip": Color("1d3c8c")},
}
# How each card groups the die faces. "faces" lists which group each face (1-6) falls in.
var split_defs := {
	"parity": {"labels": ["Odd", "Even"], "faces": [0, 1, 0, 1, 0, 1]},
	"split": {"labels": ["1-3", "4-6"], "faces": [0, 0, 0, 1, 1, 1]},
	"six": {"labels": ["1-5", "6"], "faces": [0, 0, 0, 0, 0, 1]},
	"one": {"labels": ["1", "2-6"], "faces": [0, 1, 1, 1, 1, 1]},
	"hml": {"labels": ["1-2", "3-4", "5-6"], "faces": [0, 0, 1, 1, 2, 2]},
	"ends": {"labels": ["1", "2-5", "6"], "faces": [0, 1, 1, 1, 1, 2]},
}
const COLOR_NAMES := ["Red", "Orange", "Yellow", "Green", "Blue", "Purple"]
var sector_defs := {
	"Retail": {"color": 1, "perk": "Foot traffic", "desc": "Retail partners make 50% more money."},
	"Industry": {"color": 0, "perk": "Supply chain", "desc": "Industry partners' dice count 1 higher."},
	"Finance": {"color": 3, "perk": "Syndicate", "desc": "Each Finance partnership takes 15% off the day's rent."},
	"Tech": {"color": 4, "perk": "Network", "desc": "Each Tech partnership draws a plan every morning."},
	"Services": {"color": 5, "perk": "Coverage", "desc": "Services partners can't suffer bad effects."},
}

var fortune_defs := {
	"nudge_up": {"name": "Hustle", "target": "die", "desc": "Add 1 to a die."},
	"nudge_down": {"name": "Slow Day", "target": "die", "desc": "Take 1 from a die."},
	"flip": {"name": "Turnaround", "target": "die", "desc": "Turn a die to its opposite face."},
	"reroll": {"name": "Second Wind", "target": "die", "desc": "Throw a die again."},
	"extra_die": {"name": "Extra Shift", "target": "none", "desc": "Throw one more die into the road."},
}

class Stock:
	var card := -1  # index into MainStreetCards.CARDS
	var name := ""
	var sector := ""
	var size := ""
	var split := ""
	var events: Array = []
	var price := 0.0

class Holding:
	var stock: Stock
	var level := 1
	var invested := 0.0
	var last_profit := 0.0
	var last_part := -1
	var has_last := false
	var anim_from := 0.0
	var anim_to := 0.0
	var flash := 0.0

	func value() -> float:
		return stock.price * level

class Die:
	var face := 1
	var colors: Array[int] = []
	var shown_face := 1  # what's drawn; flickers while tumbling
	var pos := Vector2.ZERO  # screen space
	var home := Vector2.ZERO
	var start := Vector2.ZERO
	var holding: Holding
	var roll_t := 0.0  # seconds of tumbling left
	var roll_dur := 1.0
	var ang := 0.0
	var spin := 0.0
	var rest_ang := 0.0
	var flash := 0.0
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

# ---------------------------------------------------------------- palette
var c_board := Color("f6f0e4")
var c_board_dark := Color("e9dfcb")
var c_board_line := Color("d8c9ac")
var c_board_ink := Color("8a7c66")
var c_board_text := Color("2a2633")
var c_well := Color("1d4f6e")
var c_road := Color("3d4250")
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
var c_violet_card := Color("4a2f9a")
var tile_colors: Array[Color] = [Color("e2453a"), Color("f07f22"), Color("f4b23e"), Color("1f9d55"), Color("2f6fe0"), Color("7c4fd8")]

# ---------------------------------------------------------------- state
var phase := Phase.TRADE
var day := 1
var cash := 0.0
var holdings: Array[Holding] = []
var market: Array[Stock] = []
var hand: Array[String] = []
var cards_played := 0
var rent_shift := 0.0  # today's rent moves by this share, from events
var deck: Array[int] = []  # property cards not owned and not for sale
var extra_dice := 0  # extra dice in tomorrow's roll
var frame_outcomes := {}
var dice: Array[Die] = []
var drag_die: Die
var die_colors: Array = []
var drag_holding: Holding
var armed_card := -1  # index into hand of a card waiting for its target
var report := {}
var anim_t := 0.0
var bankrupt := false
var peak_worth := 0.0
var best_call := ""
var best_call_ret := -INF
var total_profit := 0.0
var floaters: Array[FloatText] = []

var buttons: Array[UiButton] = []
var ui_live := true
var tips_live := true
var hover_tip := ""
var mouse := Vector2.ZERO

var view_size := Vector2.ZERO  # the game screen's own resolution; everything on the monitor is laid out in this space
var ui_size := Vector2(2560, 1440)
var window_size := Vector2.ZERO
var screen_rect := Rect2()  # where the 2560x1440 board sits in the window
var ui_scale := 1.0
var clock := 0.0
var cur_offset := Vector2.ZERO  # transform of whatever is being drawn now, so buttons register in room space
var cur_scale := 1.0
var r_port := Rect2()
var r_market := Rect2()
var r_felt := Rect2()
var r_track := Rect2()
var r_hand := Rect2()
var r_stats := Rect2()

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
const HOLE_SIZE := 84.0
const CARD_W := 250.0
const CARD_H := 304.0
const CARD_GAP := 16.0
const PLAN_W := 200.0

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
const LOT_GAP := SP * 6
const ROW_H := 40.0

func _ready() -> void:
	randomize()
	sector_names.assign(MainStreetCards.SECTORS)
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

func _recompute_layout() -> void:
	# The board is laid out at 2560x1440 and scaled to fit the window; extra space is plain board.
	window_size = get_viewport_rect().size
	view_size = ui_size
	ui_scale = minf(window_size.x / ui_size.x, window_size.y / ui_size.y)
	screen_rect = Rect2((window_size - ui_size * ui_scale) * 0.5, ui_size * ui_scale)
	var top := SP * 3
	var bottom := ui_size.y - SP * 3
	r_track = Rect2(MARGIN, top, TRACK_W, bottom - top)
	var x0 := r_track.end.x + GAP
	var right := ui_size.x - MARGIN
	var row_h := ZONE_HEAD + CARD_H + SP * 2
	r_market = Rect2(x0, top, PAD * 2 + market_size * CARD_W + (market_size - 1) * CARD_GAP, row_h)
	r_hand = Rect2(r_market.end.x + GAP, top, PAD * 2 + hand_size * PLAN_W + (hand_size - 1) * CARD_GAP, row_h)
	r_stats = Rect2(r_hand.end.x + GAP, top, right - r_hand.end.x - GAP, row_h)
	r_port = Rect2(x0, r_market.end.y + GAP, right - x0, bottom - r_market.end.y - GAP)
	var road_top := r_port.position.y + ZONE_HEAD + CARD_H + SP * 2
	var road_bottom := r_port.end.y - PAD - CARD_H - SP * 2
	r_felt = Rect2(r_port.position.x + PAD, road_top, r_port.size.x - PAD * 2, road_bottom - road_top)

# ---------------------------------------------------------------- businesses
func _stock_from_card(i: int) -> Stock:
	var c: Dictionary = MainStreetCards.CARDS[i]
	var s := Stock.new()
	s.card = i
	s.name = c["name"]
	s.sector = c["sector"]
	s.size = c["size"]
	s.split = c["split"]
	s.events = c["events"]
	s.price = float(size_prices.get(s.size, 10.0))
	return s

func _draw_from_deck() -> Stock:
	if deck.is_empty():
		return null
	return _stock_from_card(deck.pop_front())

func _return_to_deck(s: Stock) -> void:
	if s.card >= 0 and not deck.has(s.card):
		deck.insert(randi_range(0, deck.size()), s.card)

func _fill_market() -> void:
	# Unsold listings go back into the deck, and a fresh row is dealt.
	for st in market:
		_return_to_deck(st)
	market.clear()
	for i in market_size:
		var st := _draw_from_deck()
		if st == null:
			break
		market.append(st)

func _size_label(s: Stock) -> String:
	return size_defs[s.size]["label"]

func _sector_color_index(sec: String) -> int:
	return int(sector_defs[sec]["color"])

func _sector_color(sec: String) -> Color:
	return tile_colors[_sector_color_index(sec)]

func _matches(s: Stock, col: int) -> bool:
	return col == WILD or col == _sector_color_index(s.sector)

func _part_for(s: Stock, face: int) -> int:
	return int(split_defs[s.split]["faces"][clampi(face, 1, 6) - 1])

func _part_labels(s: Stock) -> Array:
	return split_defs[s.split]["labels"]

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

# ---------------------------------------------------------------- the street
func _lot_at(i: int) -> Holding:
	if i >= 0 and i < holdings.size():
		return holdings[i]
	return null

func _next_door(h: Holding) -> Array[Holding]:
	var out: Array[Holding] = []
	var i := holdings.find(h)
	if i < 0:
		return out
	var col := i % STREET_COLS
	if col > 0 and _lot_at(i - 1) != null:
		out.append(_lot_at(i - 1))
	if col < STREET_COLS - 1 and _lot_at(i + 1) != null:
		out.append(_lot_at(i + 1))
	return out

func _across(h: Holding) -> Holding:
	var i := holdings.find(h)
	if i < 0:
		return null
	return _lot_at(i + STREET_COLS if i < STREET_COLS else i - STREET_COLS)

func _neighbours(h: Holding) -> Array[Holding]:
	var out := _next_door(h)
	var a := _across(h)
	if a != null:
		out.append(a)
	return out

func _partners(h: Holding) -> Array[Holding]:
	var out: Array[Holding] = []
	for nb in _neighbours(h):
		if nb.stock.sector == h.stock.sector:
			out.append(nb)
	return out

func _partnerships(sec: String) -> int:
	var n := 0
	for i in holdings.size():
		for j in range(i + 1, holdings.size()):
			var a := holdings[i]
			var b := holdings[j]
			if a.stock.sector == sec and b.stock.sector == sec and _neighbours(a).has(b):
				n += 1
	return n

# ---------------------------------------------------------------- run flow
func _new_run() -> void:
	day = 1
	die_colors.clear()
	cash = starting_cash
	holdings.clear()
	market.clear()
	deck.clear()
	for i in MainStreetCards.CARDS.size():
		deck.append(i)
	deck.shuffle()
	hand.clear()
	hand.append_array(starting_hand)
	extra_dice = 0
	cards_played = 0
	floaters.clear()
	dice.clear()
	bankrupt = false
	peak_worth = starting_cash
	best_call = ""
	best_call_ret = -INF
	total_profit = 0.0
	_start_day()

func _start_day() -> void:
	dice.clear()
	drag_die = null
	drag_holding = null
	armed_card = -1
	rent_shift = 0.0
	for k in _partnerships("Tech"):
		if hand.size() < hand_size:
			hand.append(_random_plan())
	_fill_market()
	phase = Phase.TRADE

func _bill_for(d: int) -> float:
	return roundf(bill_base * pow(bill_growth, d - 1))

func _rent_preview() -> float:
	return maxf(0.0, _bill_for(day) * (1.0 - finance_rent_cut * _partnerships("Finance")))

func _net_worth() -> float:
	var total := cash
	for h in holdings:
		total += h.value()
	return total

func _can_buy(s: Stock) -> bool:
	if phase != Phase.TRADE or not market.has(s):
		return false
	if s.price > cash + 0.0001:
		return false
	return holdings.size() < LOTS

func _buy(s: Stock) -> void:
	if not _can_buy(s):
		return
	var h := Holding.new()
	h.stock = s
	h.invested = s.price
	holdings.append(h)
	cash = maxf(0.0, cash - s.price)
	market.erase(s)
	_play(tone_buy, randf_range(0.97, 1.05), -8.0)

func _upgrade_cost(h: Holding) -> float:
	return h.stock.price * h.level

func _can_upgrade(h: Holding) -> bool:
	return phase == Phase.TRADE and h.level < max_level and cash + 0.0001 >= _upgrade_cost(h)

func _upgrade(h: Holding) -> void:
	if not _can_upgrade(h):
		return
	var cost := _upgrade_cost(h)
	cash = maxf(0.0, cash - cost)
	h.invested += cost
	h.level += 1
	h.flash = 0.6
	h.has_last = false
	_play(tone_learn, 1.0, -8.0)

func _sell_value(h: Holding) -> float:
	return h.value() * sell_rate

func _sell(h: Holding) -> void:
	if phase != Phase.TRADE:
		return
	cash += _sell_value(h)
	holdings.erase(h)
	_return_to_deck(h.stock)
	_play(tone_sell, randf_range(0.97, 1.05), -8.0)

# ---------------------------------------------------------------- dice
func _throw_face() -> int:
	return randi_range(1, 6)

func _tray_home(i: int, n: int) -> Vector2:
	var area := Rect2(r_felt.position.x + 260.0, r_felt.position.y + 16.0, r_felt.size.x - 520.0, r_felt.size.y - 32.0)
	var per_row := 8
	var rows := ceili(float(n) / per_row)
	var row := floori(float(i) / per_row)
	var in_row := mini(per_row, n - row * per_row)
	var col := i - row * per_row
	var spacing := 124.0
	var cx := area.get_center().x + (col - (in_row - 1) * 0.5) * spacing
	var cy := area.get_center().y + (row - (rows - 1) * 0.5) * 120.0
	return Vector2(cx, cy)

func _start_roll() -> void:
	if phase != Phase.TRADE:
		return
	if holdings.is_empty():
		_close_market()
		return
	dice.clear()
	var n := holdings.size() + extra_dice
	extra_dice = 0
	for i in n:
		var d := Die.new()
		d.face = _throw_face()
		d.colors = _die_palette(i)
		d.shown_face = randi_range(1, 6)
		d.home = _tray_home(i, n)
		d.start = Vector2(r_felt.position.x - 80.0, r_felt.get_center().y + randf_range(-60.0, 60.0))
		d.pos = d.start
		d.roll_dur = roll_seconds + i * 0.06 + randf_range(0.0, 0.15)
		d.roll_t = d.roll_dur
		d.spin = randf_range(9.0, 15.0) * (1.0 if randf() < 0.5 else -1.0)
		d.rest_ang = randf_range(-0.18, 0.18)
		dice.append(d)
	armed_card = -1
	phase = Phase.ROLL
	_play(tone_rattle, 1.0, -3.0)

func _die_on(h: Holding) -> Die:
	for d in dice:
		if d.holding == h:
			return d
	return null

func _all_placed() -> bool:
	for h in holdings:
		if _die_on(h) == null:
			return false
	return true

func _assign(d: Die, h: Holding) -> void:
	if h != null:
		var other := _die_on(h)
		if other != null and other != d:
			other.holding = d.holding
	d.holding = h
	_play(tone_clack, randf_range(0.9, 1.1), -6.0)

func _return_all() -> void:
	if phase != Phase.PLACE:
		return
	for d in dice:
		d.holding = null
	_play(tone_clack, 0.8, -8.0)

func _socket_rect(i: int) -> Rect2:
	return _hole_rect(_holding_rect(i))

func _holding_at(p: Vector2) -> Holding:
	for i in holdings.size():
		if _holding_rect(i).has_point(p):
			return holdings[i]
	return null

func _die_at(p: Vector2) -> Die:
	for i in range(dice.size() - 1, -1, -1):
		var d := dice[i]
		if d.roll_t <= 0.0 and absf(p.x - d.pos.x) < DIE_SIZE * 0.55 and absf(p.y - d.pos.y) < DIE_SIZE * 0.55:
			return d
	return null

func _auto_place() -> void:
	if phase != Phase.PLACE:
		return
	for d in dice:
		d.holding = null
	var free_dice: Array[Die] = dice.duplicate()
	var open: Array[Holding] = holdings.duplicate()
	while not open.is_empty() and not free_dice.is_empty():
		var best_gain := -INF
		var best_d: Die = null
		var best_h: Holding = null
		for d in free_dice:
			for h in open:
				d.holding = h
				var gain := _street_gain(_outcomes())
				d.holding = null
				if gain > best_gain:
					best_gain = gain
					best_d = d
					best_h = h
		best_d.holding = best_h
		free_dice.erase(best_d)
		open.erase(best_h)
	_play(tone_clack, 1.0, -6.0)

func _street_gain(o: Dictionary) -> float:
	var total := 0.0
	for h in o.keys():
		total += _outcome_value(h, o[h])
	return total

func _outcome_value(h: Holding, r: Dictionary) -> float:
	var v: float = r["cash"]
	v += float(r["upgrade"]) * h.stock.price * h.level * 0.6
	v += float(r["draw"]) * 2.0 + float(r["extra_die"]) * 2.0
	v -= float(r["rent"]) * _bill_for(day)
	v -= float(r["destroy"]) * h.value()
	return v

# ---------------------------------------------------------------- plans
func _card_def(id: String) -> Dictionary:
	return fortune_defs[id]

func _card_usable(_id: String) -> bool:
	return phase == Phase.PLACE

func _play_card(i: int) -> void:
	if i < 0 or i >= hand.size():
		return
	if armed_card == i:
		armed_card = -1
		return
	var id := hand[i]
	if not _card_usable(id):
		return
	var d := _card_def(id)
	if d["target"] != "none":
		armed_card = i
		_play(tone_power, 1.4, -12.0)
		return
	match id:
		"extra_die":
			var die := Die.new()
			die.face = _throw_face()
			die.colors = _die_palette(dice.size())
			die.home = _tray_home(dice.size(), dice.size() + 1)
			die.start = Vector2(r_felt.position.x - 80.0, r_felt.get_center().y)
			die.pos = die.start
			die.roll_dur = 0.6
			die.roll_t = die.roll_dur
			die.spin = randf_range(9.0, 13.0)
			dice.append(die)
			for k in dice.size():
				dice[k].home = _tray_home(k, dice.size())
			_play(tone_rattle, 1.2, -6.0)
	_spend_card(i)

func _spend_card(i: int) -> void:
	hand.remove_at(i)
	armed_card = -1
	cards_played += 1
	_play(tone_power, 1.0, -5.0)

func _apply_card_die(d: Die) -> void:
	var id := hand[armed_card]
	match id:
		"nudge_up":
			if d.face >= 6:
				return
			d.face += 1
		"nudge_down":
			if d.face <= 1:
				return
			d.face -= 1
		"flip":
			d.face = 7 - d.face
		"reroll":
			d.face = _throw_face()
			d.start = d.pos + Vector2(randf_range(-30.0, 30.0), -70.0)
			d.roll_dur = 0.45
			d.roll_t = d.roll_dur
			d.spin = randf_range(8.0, 12.0)
	d.shown_face = d.face if d.roll_t <= 0.0 else d.shown_face
	d.flash = 1.0
	_spend_card(armed_card)

func _armed_target() -> String:
	if armed_card < 0 or armed_card >= hand.size():
		return ""
	return _card_def(hand[armed_card])["target"]

func _random_plan() -> String:
	var ids: Array = fortune_defs.keys()
	return ids[randi() % ids.size()]

# ---------------------------------------------------------------- resolving the day
func _fx_is_bad(k: String, v: float) -> bool:
	match k:
		"destroy":
			return true
		"rent":
			return v > 0.0
	return v < 0.0

func _fx_tone(fx: Dictionary) -> int:
	# 1 good, -1 bad, 2 risk/reward, 0 nothing.
	var good := false
	var bad := false
	for k in fx.keys():
		if _fx_is_bad(k, float(fx[k])):
			bad = true
		else:
			good = true
	if good and bad:
		return 2
	if good:
		return 1
	if bad:
		return -1
	return 0

func _event_need(s: Stock, part: int) -> int:
	return int(s.events[part].get("level", 1))

func _event_open(s: Stock, h: Holding, part: int) -> bool:
	return (h.level if h != null else 1) >= _event_need(s, part)

func _fx_money(v: float, h: Holding) -> float:
	return v * (h.level if h != null else 1) * event_scale

func _plan_count(n: int) -> String:
	return "a plan" if n == 1 else "%d plans" % n

func _fx_desc(fx: Dictionary, h: Holding) -> String:
	# The full wording for tooltips.
	if fx.is_empty():
		return "Nothing happens."
	var parts: Array[String] = []
	for k in fx.keys():
		var v := float(fx[k])
		match k:
			"cash":
				parts.append("You %s %s." % ["make" if v >= 0.0 else "lose", _money(absf(_fx_money(v, h)))])
			"upgrade":
				parts.append("This business goes %s %d level%s." % ["up" if v > 0.0 else "down", absi(int(v)), "" if absi(int(v)) == 1 else "s"])
			"bump":
				parts.append("The dice next door and across the street count %d %s." % [absi(int(v)), "higher" if v > 0.0 else "lower"])
			"guard":
				parts.append("The businesses next door and across the street can't suffer bad effects today.")
			"draw":
				parts.append("You draw %s (if your hand has room)." % _plan_count(int(v)))
			"extra_die":
				parts.append("Tomorrow you roll %d extra di%s." % [int(v), "e" if int(v) == 1 else "ce"])
			"rent":
				parts.append("Today's rent is %d%% %s." % [int(round(absf(v) * 100.0)), "lower" if v < 0.0 else "higher"])
			"destroy":
				parts.append("This business is destroyed.")
	return " ".join(parts)

func _outcomes() -> Dictionary:
	var base := {}
	var tint := {}
	for h in holdings:
		var d := _die_on(h)
		if d != null:
			base[h] = d.face
			tint[h] = _die_color(d, d.face)
	var bumps := {}
	var guarded := {}
	for h in holdings:
		if not _partners(h).is_empty():
			match h.stock.sector:
				"Industry":
					bumps[h] = int(bumps.get(h, 0)) + 1
				"Services":
					guarded[h] = true
	for h in base.keys():
		var hh: Holding = h
		var p0 := _part_for(hh.stock, int(base[h]))
		if not _event_open(hh.stock, hh, p0):
			continue
		var fx0: Dictionary = hh.stock.events[p0]["fx"]
		var m0 := 2 if _matches(hh.stock, int(tint[h])) else 1
		for nb in _neighbours(hh):
			if fx0.has("bump"):
				bumps[nb] = int(bumps.get(nb, 0)) + int(fx0["bump"]) * m0
			if fx0.has("guard"):
				guarded[nb] = true
	var res := {}
	for h in base.keys():
		var hh: Holding = h
		var st := hh.stock
		var eff := clampi(int(base[h]) + int(bumps.get(h, 0)), 1, 6)
		var part := _part_for(st, eff)
		var matched := _matches(st, int(tint[h]))
		var mult := 2.0 if matched else 1.0
		var o := {"face": base[h], "eff": eff, "bump": eff - int(base[h]), "part": part, "match": matched, "fired": false,
			"locked": not _event_open(st, hh, part), "guarded": guarded.has(h), "cash": 0.0, "upgrade": 0, "draw": 0,
			"extra_die": 0, "rent": 0.0, "destroy": 0, "ret": 0.0}
		if not o["locked"]:
			var fx: Dictionary = st.events[part]["fx"]
			o["fired"] = not fx.is_empty()
			for k in fx.keys():
				var v := float(fx[k])
				if guarded.has(h) and _fx_is_bad(k, v):
					continue
				match k:
					"cash":
						o["cash"] += _fx_money(v, hh) * mult
					"upgrade", "draw", "extra_die":
						o[k] += int(v * mult)
					"rent":
						o["rent"] += v * mult
					"destroy":
						o["destroy"] = 1
		var c: float = o["cash"]
		if c > 0.0 and st.sector == "Retail" and not _partners(hh).is_empty():
			c *= 1.0 + retail_bonus
		o["cash"] = c
		o["ret"] = c / maxf(hh.value(), 0.01)
		res[h] = o
	return res

func _outcome_note(o: Dictionary) -> String:
	# Everything an outcome did besides money, for the report.
	var bits: Array[String] = []
	if bool(o["match"]):
		bits.append("colour match x2")
	if int(o["bump"]) != 0:
		bits.append("die %+d" % int(o["bump"]))
	if int(o["draw"]) > 0:
		bits.append("drew %s" % _plan_count(int(o["draw"])))
	if int(o["upgrade"]) != 0:
		bits.append("%+d level" % int(o["upgrade"]))
	if float(o["rent"]) != 0.0:
		bits.append("rent %+d%%" % int(round(float(o["rent"]) * 100.0)))
	if int(o["extra_die"]) > 0:
		bits.append("+%d die tomorrow" % int(o["extra_die"]))
	if int(o["destroy"]) > 0:
		bits.append("destroyed")
	return ", ".join(bits)

func _primary_action() -> void:
	match phase:
		Phase.TRADE:
			_start_roll()
		Phase.PLACE:
			_close_market()

func _close_market() -> void:
	if phase == Phase.PLACE and not _all_placed():
		return
	if phase != Phase.PLACE and phase != Phase.TRADE:
		return
	drag_die = null
	armed_card = -1
	_play(tone_bell, 1.0, -4.0)
	var outs := _outcomes()
	var rows: Array[Dictionary] = []
	var drawn: Array[String] = []
	var log_lines: Array[String] = []
	var to_destroy: Array[Holding] = []
	rent_shift = -finance_rent_cut * _partnerships("Finance")
	for i in holdings.size():
		var h := holdings[i]
		var o: Dictionary = outs.get(h, {})
		if o.is_empty():
			continue
		var profit: float = o["cash"]
		cash += profit
		total_profit += profit
		for c in int(o["draw"]):
			if hand.size() < hand_size:
				var pid := _random_plan()
				hand.append(pid)
				drawn.append(fortune_defs[pid]["name"])
		if int(o["upgrade"]) != 0:
			var before := h.level
			h.level = clampi(h.level + int(o["upgrade"]), 1, max_level)
			if h.level != before:
				log_lines.append("%s is now level %d" % [h.stock.name, h.level])
		extra_dice += int(o["extra_die"])
		rent_shift += float(o["rent"])
		if int(o["destroy"]) > 0 and not to_destroy.has(h):
			to_destroy.append(h)
		h.last_profit = profit
		h.last_part = o["part"]
		h.has_last = true
		h.anim_from = 0.0
		h.anim_to = profit
		h.flash = 1.0
		if profit > best_call_ret:
			best_call_ret = profit
			best_call = "%s %s on a %d, day %d" % [h.stock.name, _signed_money(profit), int(o["face"]), day]
		var ev: Dictionary = h.stock.events[int(o["part"])]
		var title: String = ev["name"]
		if o["locked"]:
			title = "Locked: needs level %d" % _event_need(h.stock, int(o["part"]))
		rows.append({"ticker": h.stock.name, "name": title, "delta": profit, "face": o["face"], "note": _outcome_note(o), "ret": o["ret"]})
		var cr := _holding_rect(i)
		_spawn_floater(Vector2(cr.position.x + cr.size.x * 0.5, cr.position.y + cr.size.y * 0.55), _signed_money(profit), c_green if profit >= 0.0 else c_red, 36)
	report = {"rows": rows, "perk_cards": drawn, "log": log_lines, "to_destroy": to_destroy, "rent_shift": rent_shift}
	anim_t = 0.0
	phase = Phase.CLOSING

func _finish_close() -> void:
	var log_lines: Array[String] = report.get("log", [] as Array[String])
	var gone: Array[Holding] = report.get("to_destroy", [] as Array[Holding])
	for h in gone:
		if holdings.has(h):
			var d := _die_on(h)
			if d != null:
				dice.erase(d)
			holdings.erase(h)
			_return_to_deck(h.stock)
			log_lines.append("%s was destroyed" % h.stock.name)
	var bill := maxf(0.0, _bill_for(day) * (1.0 + rent_shift))
	cash -= bill
	var forced: Array[String] = []
	while cash < -0.0001 and not holdings.is_empty():
		var smallest := holdings[0]
		for h in holdings:
			if h.value() < smallest.value():
				smallest = h
		cash += _sell_value(smallest)
		var sd := _die_on(smallest)
		if sd != null:
			dice.erase(sd)
		holdings.erase(smallest)
		_return_to_deck(smallest.stock)
		forced.append("Sold %s for %s to cover the rent" % [smallest.stock.name, _money(_sell_value(smallest))])
	if cash < -0.0001:
		bankrupt = true
	elif cash < 0.0:
		cash = 0.0
	peak_worth = maxf(peak_worth, _net_worth())
	report["bill"] = bill
	report["forced"] = forced
	report["log"] = log_lines
	report["worth"] = _net_worth()
	phase = Phase.REPORT

func _continue_from_report() -> void:
	if bankrupt or day >= total_days:
		phase = Phase.GAMEOVER
		return
	_next_day()

func _next_day() -> void:
	day += 1
	_start_day()

# ---------------------------------------------------------------- audio
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
	# Filtered noise that swells and slaps down: a newspaper landing on the desk.
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
	# Wooden clacks: short knocks scattered through the clip, getting quieter as the dice settle.
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
	if phase == Phase.CLOSING:
		anim_t += delta / maxf(close_anim_seconds, 0.05)
		if anim_t >= 1.0:
			anim_t = 1.0
			_finish_close()
	for h in holdings:
		h.flash = maxf(0.0, h.flash - delta * 0.5)
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
	for d in dice:
		d.flash = maxf(0.0, d.flash - delta * 2.0)
		if d.roll_t > 0.0:
			d.roll_t = maxf(0.0, d.roll_t - delta)
			var t := 1.0 - d.roll_t / d.roll_dur
			var e := 1.0 - pow(1.0 - t, 3.0)
			var target := d.home if d.holding == null else _socket_rect(holdings.find(d.holding)).get_center()
			d.pos = d.start.lerp(target, e) + Vector2(0.0, -absf(sin(t * PI * 3.0)) * 50.0 * (1.0 - t))
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
		elif d.holding != null:
			var idx := holdings.find(d.holding)
			if idx >= 0:
				goal = _socket_rect(idx).get_center()
		var k := 1.0 if d == drag_die else 1.0 - exp(-delta * 16.0)
		d.pos = d.pos.lerp(goal, k)
		d.ang = lerpf(d.ang, 0.0 if d.holding != null or d == drag_die else d.rest_ang, 1.0 - exp(-delta * 10.0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var ui_p := _ui_mouse()
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var target := _armed_target()
			if phase == Phase.PLACE:
				var d := _die_at(ui_p)
				if d != null:
					if target == "die":
						_apply_card_die(d)
					elif target == "":
						drag_die = d
						_play(tone_clack, 1.25, -14.0)
					queue_redraw()
					return
			var p := get_local_mouse_position()
			for i in range(buttons.size() - 1, -1, -1):
				if buttons[i].rect.has_point(p):
					buttons[i].cb.call()
					queue_redraw()
					return
			if phase == Phase.TRADE:
				drag_holding = _holding_at(ui_p)
			armed_card = -1
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and drag_die != null:
			var target := _holding_at(ui_p)
			if target != null:
				_assign(drag_die, target)
			elif r_felt.grow(30.0).has_point(ui_p):
				_assign(drag_die, null)
			# Dropped somewhere else: it springs back to wherever it was.
			drag_die = null
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and drag_holding != null:
			var target := _holding_at(ui_p)
			if target != null and target != drag_holding:
				var a := holdings.find(drag_holding)
				var b := holdings.find(target)
				holdings[a] = target
				holdings[b] = drag_holding
			drag_holding = null
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if armed_card >= 0:
				armed_card = -1
			elif phase == Phase.PLACE:
				var d := _die_at(ui_p)
				if d != null and d.holding != null:
					_assign(d, null)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE:
			armed_card = -1
		elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE:
			match phase:
				Phase.TRADE, Phase.PLACE:
					_primary_action()
				Phase.REPORT:
					_continue_from_report()
				Phase.GAMEOVER:
					_new_run()

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

# ---------------------------------------------------------------- formatting
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
	# Prices are whole dollars, so tags skip the cents.
	var t := _money(roundf(v))
	return t.trim_suffix(".00")

func _ret_color(v: float) -> Color:
	if v > 0.005:
		return c_green
	if v < -0.005:
		return c_red
	return c_muted

# ---------------------------------------------------------------- layout
func _row_x(area: Rect2, n: int, w: float, gap: float) -> float:
	return area.get_center().x - (n * w + (n - 1) * gap) * 0.5

func _holding_rect(i: int) -> Rect2:
	var col := i % STREET_COLS
	var side := floori(float(i) / STREET_COLS)
	var x0 := _row_x(r_port, STREET_COLS, CARD_W, LOT_GAP)
	var y := r_port.position.y + ZONE_HEAD if side == 0 else r_port.end.y - PAD - CARD_H
	return Rect2(x0 + col * (CARD_W + LOT_GAP), y, CARD_W, CARD_H)

func _market_rect(i: int) -> Rect2:
	var x0 := _row_x(r_market, market_size, CARD_W, CARD_GAP)
	var y0 := r_market.position.y + ZONE_HEAD
	return Rect2(x0 + i * (CARD_W + CARD_GAP), y0, CARD_W, CARD_H)

func _hand_rect(i: int) -> Rect2:
	var x0 := _row_x(r_hand, hand_size, PLAN_W, CARD_GAP)
	return Rect2(x0 + i * (PLAN_W + CARD_GAP), r_hand.position.y + ZONE_HEAD, PLAN_W, CARD_H)

func _hole_rect(card: Rect2) -> Rect2:
	return Rect2(card.position.x + 16.0, card.position.y + 52.0, HOLE_SIZE, HOLE_SIZE)

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
	# Cards and tokens cast a soft, offset shadow onto the board.
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
	if tips_live and armed_card < 0 and r.has_point(mouse):
		hover_tip = text

func _screen_xform() -> Transform2D:
	return Transform2D(0.0, Vector2(cur_scale, cur_scale), 0.0, cur_offset)

func _vgradient(r: Rect2, top_col: Color, bottom_col: Color) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var cols := PackedColorArray([top_col, top_col, bottom_col, bottom_col])
	draw_polygon(pts, cols)

func _dashed_rect(r: Rect2, col: Color, width: float = 2.0, dash: float = 14.0, gap: float = 10.0) -> void:
	# A printed dashed outline, the kind a board uses to show where a card goes.
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
	# A chunky printed button with a thick bottom edge, like a cardboard token.
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
	# The big gold coin you press to roll the dice and ring the bell.
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

func _draw_die(d: Die) -> void:
	var size := DIE_SIZE
	if d.holding != null and d != drag_die and d.roll_t <= 0.0:
		size = HOLE_SIZE - 12.0
	var hovered := phase == Phase.PLACE and drag_die == null and absf(mouse.x - d.pos.x) < size * 0.55 and absf(mouse.y - d.pos.y) < size * 0.55
	var lift := 1.08 if d == drag_die else (1.04 if hovered else 1.0)
	draw_set_transform_matrix(_screen_xform() * Transform2D(d.ang, Vector2(lift, lift), 0.0, d.pos))
	if d.holding == null or d == drag_die:
		var depth := 22.0 if d == drag_die else 10.0
		_panel(Rect2(Vector2(-size, -size) * 0.5 + Vector2(4, depth), Vector2(size, size)), Color(c_shadow, 0.5 * (0.35)), int(size * 0.2))
	var outline := Color(0, 0, 0, 0)
	if _armed_target() == "die" and hovered:
		outline = c_violet
	elif hovered:
		outline = c_gold
	var ci := _die_color(d, d.shown_face)
	var body := (tile_colors[ci] as Color).lerp(Color.WHITE, d.flash * 0.6)
	_draw_die_body(Vector2.ZERO, size, d.shown_face, body, c_ink if ci == 2 else Color.WHITE, outline)
	if d.flash > 0.0:
		_panel(Rect2(Vector2(-size, -size) * 0.5 - Vector2(8, 8), Vector2(size + 16.0, size + 16.0)), Color(0, 0, 0, 0), int(size * 0.25), Color(c_violet_light, d.flash), 4)
	draw_set_transform_matrix(_screen_xform())

# ---------------------------------------------------------------- draw
func _draw() -> void:
	buttons.clear()
	hover_tip = ""
	draw_rect(Rect2(Vector2.ZERO, window_size), c_board)
	cur_offset = screen_rect.position
	cur_scale = ui_scale
	mouse = _ui_mouse()
	draw_set_transform_matrix(_screen_xform())
	frame_outcomes = _outcomes() if phase == Phase.PLACE else {}

	var modal := phase == Phase.REPORT or phase == Phase.GAMEOVER
	ui_live = phase == Phase.TRADE or phase == Phase.PLACE
	tips_live = not modal and drag_die == null
	_draw_board()
	_draw_track()
	_draw_street()
	_draw_market()
	_draw_hand()
	_draw_stats()
	for d in dice:
		if d != drag_die:
			_draw_die(d)
	if drag_die != null:
		_draw_die(drag_die)
	_draw_floaters()
	if _armed_target() != "":
		var hint := "%s: click a die" % _card_def(hand[armed_card])["name"]
		var hw := _heavy_w(hint, T_MD) + 40.0
		var hr := Rect2(mouse + Vector2(26.0, 18.0), Vector2(hw, 46.0))
		_panel(hr, c_violet, 23)
		_heavy_center(hr, hint, T_MD, Color.WHITE)
	ui_live = true
	tips_live = true
	match phase:
		Phase.REPORT:
			_draw_report()
		Phase.GAMEOVER:
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
	# A printed area of the board: a pale panel with a coloured edge, its name beside a tile.
	_shadow(r, 26, 4.0, 0.12)
	_panel(r, Color(c_stock, 0.82), 26, Color(c_board_line, 0.9), 2)
	_panel_corners(Rect2(r.position, Vector2(r.size.x, 8.0)), accent, 26, 26, 0, 0)
	_diamond(r.position + Vector2(PAD + 9.0, 34.0), 10.0, accent)
	var tx := r.position.x + PAD + 30.0
	_heavy(Vector2(tx, r.position.y + 44.0), title, T_LG, c_board_text)
	if note != "":
		_text(Vector2(tx + SP * 2 + _heavy_w(title, T_LG), r.position.y + 43.0), note, T_MD, c_board_ink)

func _diamond(c: Vector2, rad: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad), c + Vector2(rad, 0), c + Vector2(0, rad), c + Vector2(-rad, 0)]), col)

func _draw_track() -> void:
	var r := r_track
	_heavy_center(Rect2(r.position.x, r.position.y, r.size.x, 36.0), "Main", T_LG, c_board_text)
	_heavy_center(Rect2(r.position.x, r.position.y + 30.0, r.size.x, 36.0), "Street", T_LG, c_board_text)
	var tw := (r.size.x - 40.0) / tile_colors.size()
	for k in tile_colors.size():
		_panel(Rect2(r.position.x + 20.0 + k * tw + 2.0, r.position.y + 70.0, tw - 4.0, 8.0), tile_colors[k], 3)
	var y0 := r.position.y + 92.0
	var gap := 6.0
	var sh := (r.end.y - y0 - gap * (total_days - 1)) / total_days
	for d in total_days:
		var day_n := d + 1
		var sr := Rect2(r.position.x, y0 + d * (sh + gap), r.size.x, sh)
		var past := day_n < day or (day_n == day and phase == Phase.REPORT)
		var now := day_n == day
		var fill := Color(c_stock, 0.85)
		if past:
			fill = Color(c_board_dark, 0.8)
		_panel(sr, fill, 12, c_gold if now else Color(c_board_line, 0.9), 3 if now else 2)
		var cy := sr.get_center().y
		_text(Vector2(sr.position.x + 12.0, cy + 6.0), str(day_n), T_SM, c_board_ink, true)
		var bill_s := "$%d" % int(roundf(_bill_for(day_n)))
		var bill_col := c_board_text if not past else Color(c_board_ink, 0.6)
		if now:
			bill_col = c_down
		_heavy_right(sr.end.x - 12.0, cy + 8.0, bill_s, T_MD, bill_col)
		if past:
			var bw := _heavy_w(bill_s, T_MD)
			draw_line(Vector2(sr.end.x - 16.0 - bw, cy), Vector2(sr.end.x - 8.0, cy), Color(c_board_ink, 0.6), 2.0)
		if now:
			_draw_pawn(Vector2(sr.position.x + 50.0, cy - 4.0))
		var when := "Paid" if past else "Due at closing"
		_tip(sr, "Day %d. Rent: %s. %s." % [day_n, _money(_bill_for(day_n)), when])

func _draw_pawn(c: Vector2) -> void:
	var col := c_violet
	draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 18), c + Vector2(11, 18), c + Vector2(5, 2), c + Vector2(-5, 2)]), col.darkened(0.1))
	draw_circle(c + Vector2(0, -4), 9.0, col)
	draw_circle(c + Vector2(-3, -7), 3.0, Color(1, 1, 1, 0.35))

func _street_note() -> String:
	match phase:
		Phase.TRADE:
			return "Buy and upgrade businesses, then roll" if not holdings.is_empty() else "Buy a business to open your street"
		Phase.PLACE:
			var left := 0
			for h in holdings:
				if _die_on(h) == null:
					left += 1
			return "Drag each die into a business's door" if left > 0 else "Every business has a die"
	return ""

func _draw_street() -> void:
	_zone(r_port, "Your street", _street_note(), c_up)
	_draw_road()
	for i in LOTS:
		var a := _holding_rect(i)
		var col := i % STREET_COLS
		if col < STREET_COLS - 1:
			var b := _holding_rect(i + 1)
			var ha := _lot_at(i)
			var hb := _lot_at(i + 1)
			var paired := ha != null and hb != null and ha.stock.sector == hb.stock.sector
			var lc := _sector_color(ha.stock.sector) if paired else c_board_line
			var cy := a.position.y + 96.0
			var link := Rect2(a.end.x - 4.0, cy - 5.0, b.position.x - a.end.x + 8.0, 10.0)
			_panel(link, lc, 5)
			draw_circle(Vector2(link.get_center().x, cy), 10.0 if paired else 8.0, lc)
			if paired:
				_tip(link.grow(12.0), "%s partners next door: %s. %s" % [ha.stock.sector, sector_defs[ha.stock.sector]["perk"], sector_defs[ha.stock.sector]["desc"]])
		if i < STREET_COLS:
			var ha2 := _lot_at(i)
			var hb2 := _lot_at(i + STREET_COLS)
			if ha2 != null and hb2 != null and ha2.stock.sector == hb2.stock.sector:
				var b2 := _holding_rect(i + STREET_COLS)
				var x := a.position.x + 28.0
				var lr := Rect2(x - 5.0, a.end.y - 4.0, 10.0, b2.position.y - a.end.y + 8.0)
				_panel(lr, _sector_color(ha2.stock.sector), 5)
				_tip(lr.grow(10.0), "%s partners across the street: %s. %s" % [ha2.stock.sector, sector_defs[ha2.stock.sector]["perk"], sector_defs[ha2.stock.sector]["desc"]])
	for i in LOTS:
		var cr := _holding_rect(i)
		if i < holdings.size():
			_draw_stock_card(cr, holdings[i].stock, holdings[i])
		else:
			_panel(cr, Color(c_board_dark, 0.5), 20, Color(c_board_line, 0.9), 2)
			_fx_icon("house", cr.get_center() + Vector2(0.0, -30.0), 26.0, Color(c_board_line, 0.9))
			_text_center(Rect2(cr.position.x, cr.get_center().y + 14.0, cr.size.x, 36.0), "Empty lot", T_MD, c_board_ink, true)

func _draw_road() -> void:
	var r := r_felt
	_panel(r, c_road, 22)
	_panel(Rect2(r.position.x, r.position.y, r.size.x, 6.0), Color(1, 1, 1, 0.12), 3)
	_panel(Rect2(r.position.x, r.end.y - 6.0, r.size.x, 6.0), Color(0, 0, 0, 0.18), 3)
	var cy := r.get_center().y
	var x := r.position.x + 240.0
	while x < r.end.x - 280.0:
		_panel(Rect2(x, cy - 3.0, 44.0, 6.0), Color(c_gold, 0.55), 3)
		x += 86.0
	if phase == Phase.PLACE:
		_pill(Rect2(r.position.x + PAD, cy - 52.0, 190.0, 44.0), "Auto-place", _auto_place, true, "light", T_SM)
		_pill(Rect2(r.position.x + PAD, cy + 8.0, 190.0, 44.0), "Return all", _return_all, true, "light", T_SM)
	var cc := Vector2(r.end.x - 110.0, cy)
	match phase:
		Phase.TRADE:
			_coin(cc, 84.0, "Roll" if not holdings.is_empty() else "Close\nup", _primary_action, true)
		Phase.PLACE:
			var left := 0
			for h in holdings:
				if _die_on(h) == null:
					left += 1
			_coin(cc, 84.0, "Close\nup" if left == 0 else "%d to\nplace" % left, _primary_action, left == 0)
		_:
			_coin(cc, 84.0, "...", _primary_action, false)

func _draw_market() -> void:
	_zone(r_market, "For sale", "Click a business to buy it" if phase == Phase.TRADE else "Back tomorrow", c_blue)
	for i in market_size:
		if i < market.size():
			_draw_stock_card(_market_rect(i), market[i], null)
		else:
			var er := _market_rect(i)
			_dashed_rect(er, Color(c_board_line, 0.9))
			_text_center(er, "Sold", T_MD, c_board_ink, true)
	if phase != Phase.TRADE:
		_panel(r_market, Color(c_board, 0.5), 26)

func _level_pips(c: Vector2, level: int, col: Color) -> void:
	for k in max_level:
		_diamond(c + Vector2(k * 16.0, 0.0), 6.0, col if k < level else Color(c_board_line, 0.9))

func _draw_stock_card(r: Rect2, s: Stock, h: Holding) -> void:
	var trade_hover := phase == Phase.TRADE and drag_die == null and armed_card < 0 and r.has_point(mouse)
	var lift := -8.0 if trade_hover else 0.0
	var cr := Rect2(r.position + Vector2(0, lift), r.size)
	_shadow(r, 20, 8.0 - lift * 0.8)
	var sec_col := _sector_color(s.sector)
	var body := c_stock.lerp(sec_col, 0.08)
	if h != null and h.flash > 0.0 and h.has_last:
		body = body.lerp(c_up_soft if h.last_profit >= 0.0 else c_down_soft, clampf(h.flash * 1.4, 0.0, 1.0))
	elif h != null and h.flash > 0.0:
		body = body.lerp(Color("fcecc4"), clampf(h.flash * 1.4, 0.0, 1.0))
	var placing := phase == Phase.PLACE
	if h != null and drag_die != null and cr.has_point(mouse):
		_panel(cr.grow(6.0), Color(0, 0, 0, 0), 26, c_gold, 5)
	_panel(cr, body, 20, sec_col, 6)
	var band := Rect2(cr.position, Vector2(cr.size.x, 40.0))
	_panel_corners(band, sec_col, 20, 20, 0, 0)
	var x := cr.position.x + 22.0
	var rx := cr.end.x - 12.0
	if h != null and not _partners(h).is_empty():
		var bc := Vector2(rx - 16.0, band.get_center().y)
		draw_circle(bc, 15.0, Color.WHITE)
		draw_arc(bc + Vector2(-4.0, 0.0), 6.0, 0.0, TAU, 16, sec_col, 3.0, true)
		draw_arc(bc + Vector2(4.0, 0.0), 6.0, 0.0, TAU, 16, sec_col, 3.0, true)
		var names: Array[String] = []
		for p in _partners(h):
			names.append(p.stock.name)
		_tip(Rect2(bc - Vector2(18, 18), Vector2(36, 36)), "Partners with %s.\n%s: %s" % [", ".join(names), sector_defs[s.sector]["perk"], sector_defs[s.sector]["desc"]])
		rx = bc.x - 22.0
	_heavy(Vector2(x, band.position.y + 29.0), s.sector.to_upper(), T_MD, Color.WHITE)
	_tip(Rect2(band.position, Vector2(rx - band.position.x, band.size.y)), "%s sector. %s partners: %s. %s" % [s.sector, s.sector, sector_defs[s.sector]["perk"], sector_defs[s.sector]["desc"]])

	var hole := _hole_rect(cr)
	_draw_hole(hole, h != null and placing and _die_on(h) == null, sec_col)
	_tip(hole, "A %s or yellow die doubles this card's event." % COLOR_NAMES[_sector_color_index(s.sector)].to_lower())
	var ob: Dictionary = frame_outcomes.get(h, {}) if h != null else {}
	if not ob.is_empty() and int(ob["bump"]) != 0:
		var bc2 := Vector2(hole.end.x - 2.0, hole.position.y + 2.0)
		draw_circle(bc2, 14.0, c_gold if int(ob["bump"]) > 0 else c_down)
		_heavy_center(Rect2(bc2 - Vector2(14, 14), Vector2(28, 28)), "%+d" % int(ob["bump"]), T_SM, c_ink if int(ob["bump"]) > 0 else Color.WHITE)
		_tip(Rect2(bc2 - Vector2(16, 16), Vector2(32, 32)), "Its neighbours move this die %+d: it reads as a %d." % [int(ob["bump"]), int(ob["eff"])])
	if not ob.is_empty() and bool(ob["match"]):
		var mc := Vector2(hole.end.x - 2.0, hole.end.y - 2.0)
		draw_circle(mc, 15.0, c_gold)
		_heavy_center(Rect2(mc - Vector2(15, 15), Vector2(30, 30)), "x2", T_SM, c_ink)
		_tip(Rect2(mc - Vector2(16, 16), Vector2(32, 32)), "Colour match: this event is doubled.")

	var nx := hole.end.x + 14.0
	var nw := cr.end.x - 16.0 - nx
	var words := s.name.split(" ", false, 1)
	var ny := cr.position.y + 74.0
	for wd in words:
		var size := T_LG
		while size > 13 and _heavy_w(wd, size) > nw:
			size -= 1
		_heavy(Vector2(nx, ny), wd, size, c_ink)
		ny += 26.0
	var lbl := _size_label(s).to_upper()
	var chip_bg: Color = size_defs[s.size]["chip"]
	var csize := T_XS
	while csize > 10 and _heavy_w(lbl, csize) + 16.0 > nw:
		csize -= 1
	var chip := Rect2(nx, cr.position.y + 108.0, minf(nw, _heavy_w(lbl, csize) + 16.0), 26.0)
	_panel(chip, chip_bg, 13)
	_heavy_center(chip, lbl, csize, Color.WHITE)
	_tip(Rect2(nx, cr.position.y + 48.0, nw, 90.0), "%s\n%s, %s." % [s.name, _size_label(s), s.sector])

	# Events: one row per group of die faces. The row the die picks lights up.
	var o: Dictionary = frame_outcomes.get(h, {}) if h != null else {}
	var d: Die = _die_on(h) if h != null else null
	var lit := -1
	if d != null and d.roll_t <= 0.0 and not o.is_empty():
		lit = int(o["part"])
	if h != null and (phase == Phase.CLOSING or phase == Phase.REPORT) and h.has_last:
		lit = h.last_part
	var labels := _part_labels(s)
	var top := cr.position.y + 144.0
	for k in labels.size():
		var rr := Rect2(cr.position.x + 12.0, top + k * ROW_H, cr.size.x - 24.0, ROW_H - 4.0)
		var ev: Dictionary = s.events[k]
		var fx: Dictionary = ev["fx"]
		var bg := Color("eceef2")
		var ink := c_muted
		match _fx_tone(fx):
			1:
				bg = c_up_soft
				ink = c_up
			-1:
				bg = c_down_soft
				ink = c_down
			2:
				bg = Color("fbefd3")
				ink = c_gold_dark
		var need := _event_need(s, k)
		var locked := not _event_open(s, h, k)
		if locked:
			bg = Color("dfe1e6")
			ink = Color(c_muted, 0.7)
		var on := k == lit
		_panel(rr, bg, 8, c_gold if on else Color(0, 0, 0, 0), 3 if on else 0)
		var lab: String = labels[k]
		var cw := maxf(_heavy_w(lab, T_SM) + 12.0, 26.0)
		var pr := Rect2(rr.position.x + 3.0, rr.position.y + 3.0, cw, rr.size.y - 6.0)
		_panel(pr, c_gold_dark if on else c_ink, 6)
		_heavy_center(pr, lab, T_SM, Color.WHITE)
		var tr := Rect2(pr.end.x + SP, rr.position.y, rr.end.x - pr.end.x - SP * 2, rr.size.y)
		var nm: String = ev["name"]
		var ns := T_MD
		var need_s := "Lv %d" % need
		var lrad := 7.0
		var lock_w := SP + lrad * 2.0 + 3.0 + _heavy_w(need_s, T_SM) if locked else 0.0
		while ns > 11 and _heavy_w(nm, ns) + lock_w > tr.size.x:
			ns -= 1
		var cy := tr.get_center().y
		_heavy(Vector2(tr.position.x, cy + font_heavy.get_ascent(ns) * 0.38), nm, ns, ink)
		if locked:
			var lc := Vector2(tr.position.x + _heavy_w(nm, ns) + SP + lrad, cy)
			_fx_icon("lock", lc, lrad, c_muted)
			_heavy(Vector2(lc.x + lrad + 3.0, cy + font_heavy.get_ascent(T_SM) * 0.38), need_s, T_SM, c_muted)
		var tip := "%s: %s (%s)\n%s" % [lab, nm, ev["title"], _fx_desc(fx, h)]
		if need > 1:
			tip += "\nNeeds level %d (%s)." % [need, "unlocked" if not locked else "locked"]
		_tip(rr, tip)

	var by := cr.end.y - 14.0
	if h != null:
		if trade_hover:
			var half := (cr.size.x - 28.0 - SP) * 0.5
			var ur := Rect2(Vector2(cr.position.x + 14.0, by - 30.0), Vector2(half, 38.0))
			var sr := Rect2(Vector2(ur.end.x + SP, by - 30.0), Vector2(half, 38.0))
			if h.level < max_level:
				var can_up := _can_upgrade(h)
				_panel(ur, c_up if can_up else c_board_line, 19)
				_heavy_center(ur, "Up %s" % _whole_money(_upgrade_cost(h)), T_MD, Color.WHITE if can_up else c_board_text)
				_tip(ur, "Upgrade to level %d for %s. Its money grows and it unlocks level %d events." % [h.level + 1, _money(_upgrade_cost(h)), h.level + 1])
				if can_up:
					_register(ur, _upgrade.bind(h))
			else:
				_text_center(ur, "Max level", T_SM, c_muted, true)
			_panel(sr, c_down_chip, 19)
			_heavy_center(sr, "Sell %s" % _whole_money(_sell_value(h)), T_MD, Color.WHITE)
			_tip(sr, "Sell for %s (%d%% of its %s worth)." % [_money(_sell_value(h)), int(round(sell_rate * 100.0)), _money(h.value())])
			_register(sr, _sell.bind(h))
		else:
			_level_pips(Vector2(x + 4.0, by - 7.0), h.level, c_gold_dark)
			_heavy(Vector2(x + 16.0 * max_level + 6.0, by), _money(h.value()), T_MD, c_ink)
			_tip(Rect2(x - 6.0, by - 22.0, 150.0, 28.0), "Level %d of %d. It's worth %s." % [h.level, max_level, _money(h.value())])
			var shown := 0.0
			var show := false
			if placing and not o.is_empty():
				shown = float(o["cash"])
				show = true
			elif h.has_last and phase == Phase.CLOSING:
				shown = lerpf(h.anim_from, h.anim_to, 1.0 - pow(1.0 - anim_t, 3.0))
				show = true
			elif h.has_last and phase == Phase.REPORT:
				shown = h.last_profit
				show = true
			if show:
				_heavy_right(cr.end.x - 18.0, by, _signed_money(shown), T_MD, _ret_color(shown))
	else:
		_heavy(Vector2(x, by), _money(s.price), T_LG, c_ink)
		if phase == Phase.TRADE:
			var can := _can_buy(s)
			if trade_hover:
				var hint := "Buy"
				if not can:
					hint = "Street full" if holdings.size() >= LOTS else "Too pricey"
				var hw := maxf(_heavy_w(hint, T_MD) + 40.0, 96.0)
				var hr := Rect2(Vector2(cr.end.x - 16.0 - hw, by - 32.0), Vector2(hw, 42.0))
				_panel(hr, c_gold if can else c_board_line, 21)
				_heavy_center(hr, hint, T_MD, c_ink if can else c_board_text)
			if can:
				_register(r, _buy.bind(s))

func _flame(c: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -rad * 1.4), c + Vector2(rad * 0.75, -rad * 0.1), c + Vector2(rad * 0.6, rad * 0.7),
		c + Vector2(0, rad), c + Vector2(-rad * 0.6, rad * 0.7), c + Vector2(-rad * 0.75, -rad * 0.1), c + Vector2(-rad * 0.15, -rad * 0.6)])
	draw_colored_polygon(pts, col)


func _fx_icon(icon: String, c: Vector2, rad: float, col: Color) -> void:
	var w := Color.WHITE
	match icon:
		"coin":
			draw_circle(c, rad, col)
			draw_arc(c, rad * 0.72, 0.0, TAU, 20, Color(w, 0.55), maxf(1.0, rad * 0.14), true)
			_heavy_center(Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0), "$", int(rad * 1.3), w)
		"share":
			_panel(Rect2(c + Vector2(-rad * 0.55, -rad), Vector2(rad * 1.5, rad * 1.5)), Color(col, 0.45), int(rad * 0.3))
			_panel(Rect2(c + Vector2(-rad * 0.95, -rad * 0.5), Vector2(rad * 1.5, rad * 1.5)), col, int(rad * 0.3))
			draw_line(c + Vector2(-rad * 0.6, rad * 0.1), c + Vector2(rad * 0.2, rad * 0.1), w, maxf(1.0, rad * 0.16))
			draw_line(c + Vector2(-rad * 0.6, rad * 0.5), c + Vector2(rad * 0.05, rad * 0.5), w, maxf(1.0, rad * 0.16))
		"card":
			_panel(Rect2(c - Vector2(rad * 0.7, rad), Vector2(rad * 1.4, rad * 2.0)), col, int(rad * 0.3))
			_panel(Rect2(c - Vector2(rad * 0.4, rad * 0.7), Vector2(rad * 0.8, rad * 1.4)), Color(0, 0, 0, 0), int(rad * 0.2), Color(w, 0.7), maxi(1, int(rad * 0.15)))
		"copy":
			_panel(Rect2(c + Vector2(-rad * 0.3, -rad), Vector2(rad * 1.2, rad * 1.6)), Color(col, 0.45), int(rad * 0.3))
			_panel(Rect2(c + Vector2(-rad * 0.9, -rad * 0.6), Vector2(rad * 1.2, rad * 1.6)), col, int(rad * 0.3))
		"die":
			_draw_die_body(c, rad * 1.8, 5, col, w)
		"shield":
			_shield(c + Vector2(0, -rad * 0.1), rad * 0.85, col)
		"flame":
			_flame(c + Vector2(0, rad * 0.2), rad * 0.8, col)
		"house":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad), c + Vector2(rad, -rad * 0.1), c + Vector2(rad * 0.75, -rad * 0.1),
				c + Vector2(rad * 0.75, rad), c + Vector2(-rad * 0.75, rad), c + Vector2(-rad * 0.75, -rad * 0.1), c + Vector2(-rad, -rad * 0.1)]), col)
			draw_rect(Rect2(c + Vector2(-rad * 0.2, rad * 0.3), Vector2(rad * 0.4, rad * 0.7)), w)
		"tag":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-rad, -rad * 0.6), c + Vector2(rad * 0.4, -rad * 0.6), c + Vector2(rad, 0),
				c + Vector2(rad * 0.4, rad * 0.6), c + Vector2(-rad, rad * 0.6)]), col)
			draw_circle(c + Vector2(rad * 0.35, 0), rad * 0.18, w)
		"eye":
			var pts := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				pts.append(c + Vector2(cos(a) * rad, sin(a) * rad * 0.6))
			draw_colored_polygon(pts, col)
			draw_circle(c, rad * 0.35, w)
			draw_circle(c, rad * 0.16, col)
		"grow":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -rad), c + Vector2(rad * 0.9, 0), c + Vector2(rad * 0.35, 0),
				c + Vector2(rad * 0.35, rad), c + Vector2(-rad * 0.35, rad), c + Vector2(-rad * 0.35, 0), c + Vector2(-rad * 0.9, 0)]), col)
		"next":
			_panel(Rect2(c - Vector2(rad, rad * 0.8), Vector2(rad * 2.0, rad * 1.8)), col, int(rad * 0.3))
			draw_rect(Rect2(c + Vector2(-rad * 0.7, -rad * 0.2), Vector2(rad * 1.4, rad * 0.8)), w)
			draw_line(c + Vector2(-rad * 0.45, -rad), c + Vector2(-rad * 0.45, -rad * 0.55), col, maxf(1.0, rad * 0.25))
			draw_line(c + Vector2(rad * 0.45, -rad), c + Vector2(rad * 0.45, -rad * 0.55), col, maxf(1.0, rad * 0.25))
		"bill":
			_panel(Rect2(c - Vector2(rad * 0.75, rad), Vector2(rad * 1.5, rad * 2.0)), col, int(rad * 0.2))
			for i in 3:
				var ly := c.y - rad * 0.45 + i * rad * 0.45
				draw_line(Vector2(c.x - rad * 0.4, ly), Vector2(c.x + rad * 0.4, ly), w, maxf(1.0, rad * 0.15))
		"shut":
			draw_arc(c, rad * 0.8, 0.0, TAU, 20, col, maxf(1.5, rad * 0.3), true)
			draw_line(c + Vector2(-rad * 0.55, rad * 0.55), c + Vector2(rad * 0.55, -rad * 0.55), col, maxf(1.5, rad * 0.3))
		"boom":
			draw_line(c + Vector2(-rad * 0.75, -rad * 0.75), c + Vector2(rad * 0.75, rad * 0.75), col, maxf(2.0, rad * 0.4))
			draw_line(c + Vector2(-rad * 0.75, rad * 0.75), c + Vector2(rad * 0.75, -rad * 0.75), col, maxf(2.0, rad * 0.4))
		"lock", "unlock":
			var shackle := c + Vector2(rad * 0.35 if icon == "unlock" else 0.0, -rad * 0.25)
			draw_arc(shackle, rad * 0.45, PI, TAU, 10, col, maxf(1.0, rad * 0.25), true)
			draw_line(shackle + Vector2(-rad * 0.45, 0), shackle + Vector2(-rad * 0.45, rad * 0.2), col, maxf(1.0, rad * 0.25))
			draw_line(shackle + Vector2(rad * 0.45, 0), shackle + Vector2(rad * 0.45, rad * 0.2), col, maxf(1.0, rad * 0.25))
			_panel(Rect2(c + Vector2(-rad * 0.7, -rad * 0.1), Vector2(rad * 1.4, rad * 1.05)), col, int(rad * 0.2))

func _shield(c: Vector2, rad: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-rad, -rad), c + Vector2(rad, -rad), c + Vector2(rad, rad * 0.2),
		c + Vector2(0, rad * 1.2), c + Vector2(-rad, rad * 0.2)]), col)

func _draw_hole(r: Rect2, inviting: bool, frame: Color) -> void:
	_panel(r.grow(4.0), frame, 21)
	_panel(r, c_well, 17)
	_vgradient(Rect2(r.position.x + 7.0, r.position.y + 2.0, r.size.x - 14.0, 16.0), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.0))
	if inviting:
		var a := 0.35 + 0.25 * sin(clock * 4.0)
		_panel(r.grow(-10.0), Color(0, 0, 0, 0), 14, Color(c_gold, a), 3)

func _draw_stats() -> void:
	_zone(r_stats, "Ledger", "", c_gold)
	var r := Rect2(r_stats.position.x + PAD, r_stats.position.y + ZONE_HEAD, r_stats.size.x - PAD * 2.0, r_stats.size.y - ZONE_HEAD - PAD)
	var cw := (r.size.x - SP * 2.0) / 2.0
	var cells := [
		["Cash", _money(cash), c_board_text, ""],
		["Net worth", _money(_net_worth()), c_board_text, ""],
		["Rent today", _money(_rent_preview()), c_down, "Due at closing. Finance partners and some events lower it."],
		["Profit so far", _signed_money(total_profit), c_up if total_profit >= 0.0 else c_down, ""],
	]
	for i in cells.size():
		var cell: Array = cells[i]
		var cr := Rect2(r.position.x + (i % 2) * (cw + SP * 2.0), r.position.y + floori(i / 2.0) * 84.0, cw, 80.0)
		_text(cr.position + Vector2(0.0, 20.0), cell[0], T_SM, c_board_ink, true)
		var size := T_XL
		while size > T_MD and _heavy_w(cell[1], size) > cw:
			size -= 1
		_heavy(cr.position + Vector2(0.0, 62.0), cell[1], size, cell[2])
		if cell[3] != "":
			_tip(cr, cell[3])
	var y := r.position.y + 190.0
	_text(Vector2(r.position.x, y), "Partners", T_SM, c_board_ink, true)
	var any := false
	for sec in sector_names:
		var n := _partnerships(sec)
		if n == 0:
			continue
		any = true
		y += 26.0
		_diamond(Vector2(r.position.x + 8.0, y - 6.0), 7.0, _sector_color(sec))
		var line := "%s: %s%s" % [sec, sector_defs[sec]["perk"], "" if n == 1 else " x%d" % n]
		_heavy(Vector2(r.position.x + 24.0, y), line, T_SM, c_board_text)
		_tip(Rect2(r.position.x, y - 20.0, r.size.x, 26.0), sector_defs[sec]["desc"])
	if not any:
		_wrap(Vector2(r.position.x, y + 26.0), "Put two businesses of one sector next door or across the street.", r.size.x, T_SM, c_board_ink, true, 3)

func _draw_hand() -> void:
	_zone(r_hand, "Plans", "Play after you roll" if phase != Phase.PLACE else "Click a plan, then a die", c_violet)
	for i in hand_size:
		var base := _hand_rect(i)
		if i >= hand.size():
			_dashed_rect(base, Color(c_board_line, 0.9))
			continue
		var id := hand[i]
		var usable := _card_usable(id) and ui_live
		var armed := armed_card == i
		var hovered := usable and base.has_point(mouse)
		var lift := -14.0 if armed else (-8.0 if hovered else 0.0)
		var cr := Rect2(base.position + Vector2(0, lift), base.size)
		_draw_fortune_card(cr, id, usable or armed, armed, base, lift)
		if usable or armed:
			_register(base, _play_card.bind(i))
		var d := _card_def(id)
		_tip(base, "%s\n%s\n%s" % [d["name"], d["desc"], "Play it after you roll." if not usable else "Click to play."])

func _draw_fortune_card(cr: Rect2, id: String, bright: bool, armed: bool, shadow_base: Rect2, lift: float) -> void:
	var d := _card_def(id)
	_shadow(shadow_base, 20, 8.0 - lift * 0.8)
	var face := c_violet_card if bright else c_violet_card.lerp(c_board, 0.5)
	_panel(cr, face, 20, c_gold if armed else Color(c_violet_light, 0.3), 4 if armed else 2)
	_panel(cr.grow(-10.0), Color(0, 0, 0, 0), 14, Color(c_gold, 0.45 if bright else 0.2), 2)
	var a := 1.0 if bright else 0.45
	_text_center(Rect2(cr.position.x, cr.position.y + 12.0, cr.size.x, 30.0), "Plan", T_SM, Color(c_gold, 0.85 * a), true)
	_draw_fortune_icon(id, Vector2(cr.get_center().x, cr.position.y + cr.size.y * 0.3), 1.0, a)
	var ny := cr.position.y + cr.size.y * 0.58
	draw_multiline_string(font_heavy, Vector2(cr.position.x + 18.0, ny), d["name"], HORIZONTAL_ALIGNMENT_CENTER, cr.size.x - 36.0, T_LG, 2, Color(1, 1, 1, a))
	_wrap(Vector2(cr.position.x + 18.0, ny + 40.0), d["desc"], cr.size.x - 36.0, T_SM, Color(Color("d6ccf5"), a), true, 3, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_fortune_icon(id: String, c: Vector2, k: float, a: float) -> void:
	var gold := Color(c_gold, a)
	var ivory := Color(c_ivory, a)
	match id:
		"nudge_up", "nudge_down", "flip", "reroll":
			_draw_die_body(c - Vector2(14.0 * k, 0), 56.0 * k, 1 if id == "flip" else 3, ivory, Color(c_ink, a))
			var m := c + Vector2(40.0 * k, 0.0)
			match id:
				"nudge_up":
					draw_colored_polygon(PackedVector2Array([m + Vector2(-12, 8) * k, m + Vector2(12, 8) * k, m + Vector2(0, -12) * k]), gold)
				"nudge_down":
					draw_colored_polygon(PackedVector2Array([m + Vector2(-12, -8) * k, m + Vector2(12, -8) * k, m + Vector2(0, 12) * k]), gold)
				"flip":
					draw_arc(m, 15.0 * k, -PI * 0.8, PI * 0.8, 18, gold, 4.0 * k, true)
				"reroll":
					draw_arc(m, 15.0 * k, 0.0, PI * 1.6, 18, gold, 4.0 * k, true)
					draw_circle(m + Vector2(15, 0) * k, 5.0 * k, gold)
		"extra_die":
			_draw_die_body(c + Vector2(-22, 8) * k, 50.0 * k, 2, ivory, Color(c_ink, a))
			_draw_die_body(c + Vector2(20, -8) * k, 50.0 * k, 5, ivory, Color(c_ink, a))

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

func _draw_report() -> void:
	_dim()
	var rows: Array[Dictionary] = report.get("rows", [] as Array[Dictionary])
	var forced: Array[String] = report.get("forced", [] as Array[String])
	var lines: Array = []
	var drawn: Array[String] = report.get("perk_cards", [] as Array[String])
	if not drawn.is_empty():
		lines.append(["Plans drawn", ", ".join(drawn), c_violet])
	var shift: float = report.get("rent_shift", 0.0)
	var rent_label := "Rent paid"
	if absf(shift) > 0.001:
		rent_label = "Rent paid (%+d%% from events and partners)" % int(round(shift * 100.0))
	lines.append([rent_label, "-" + _money(report.get("bill", 0.0)), c_down])
	var log_lines: Array[String] = report.get("log", [] as Array[String])

	var w := 1040.0
	var row_h := 66.0
	var h := 150.0 + maxi(1, rows.size()) * row_h + 30.0 + lines.size() * 46.0 + (forced.size() + log_lines.size()) * 32.0 + 110.0 + 120.0
	var r := Rect2((view_size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_shadow(r, 28, 14.0)
	_panel(r, c_stock, 28)
	var x := r.position.x + 56.0
	var right := r.end.x - 56.0
	var y := r.position.y + 82.0
	_heavy(Vector2(x, y), "Day %d closes" % day, T_HERO, c_ink)
	y += 30.0
	if rows.is_empty():
		y += 50.0
		_text(Vector2(x, y), "Your street was empty today.", T_LG, c_muted, true)
	for row in rows:
		y += row_h
		var face: int = row["face"]
		var delta: float = row["delta"]
		_draw_die_body(Vector2(x + 22.0, y - 18.0), 40.0, face, c_ivory, c_ink, Color("d9dde6"))
		_heavy(Vector2(x + 62.0, y - 14.0), row["ticker"], T_LG, c_ink)
		var nx := x + 62.0 + _heavy_w(row["ticker"], T_LG) + 18.0
		_text(Vector2(nx, y - 15.0), row["name"], T_MD, c_gold_dark, true)
		var note: String = row.get("note", "")
		if note != "":
			_text(Vector2(x + 62.0, y + 12.0), note, T_MD, c_muted, true)
		_heavy_right(right, y - 6.0, _signed_money(delta), T_LG, _ret_color(delta))
	y += 30.0
	draw_line(Vector2(x, y), Vector2(right, y), Color("e4e7ee"), 2.0)
	for ln in lines:
		y += 46.0
		_text(Vector2(x, y - 8.0), ln[0], T_LG, c_ink, true)
		_heavy_right(right, y - 8.0, ln[1], T_LG, ln[2])
	for ll in log_lines:
		y += 32.0
		_text(Vector2(x + 18.0, y - 6.0), ll, T_MD, c_violet_dark, true)
	for fl in forced:
		y += 32.0
		_text(Vector2(x + 18.0, y - 6.0), fl, T_MD, c_down, true)
	y += 74.0
	_heavy(Vector2(x, y), "Net worth", T_XL, c_ink)
	_heavy_right(right, y, _money(report.get("worth", 0.0)), T_HERO, c_ink)
	var last := bankrupt or day >= total_days
	_pill(Rect2(right - 340.0, r.end.y - 52.0 - 74.0, 340.0, 74.0), "See how it went" if last else "Start day %d" % (day + 1), _continue_from_report, true, "gold", T_LG)

func _draw_gameover() -> void:
	_dim()
	var w := 1040.0
	var h := 760.0
	var r := Rect2((view_size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_shadow(r, 28, 14.0)
	_panel(r, c_stock, 28)
	var x := r.position.x + 64.0
	var right := r.end.x - 64.0
	var won := not bankrupt
	var title := "Main Street made it through all %d days" % total_days if won else "Closed for good on day %d" % day
	_heavy(Vector2(x, r.position.y + 100.0), title, T_HERO, c_up if won else c_down)
	var sub := "The last shutter comes down and the rent is paid." if won else "The rent came due with nothing left to sell."
	_text(Vector2(x, r.position.y + 148.0), sub, T_LG, c_muted, true)
	var stats := [
		["Final net worth", _money(_net_worth())],
		["Peak net worth", _money(peak_worth)],
		["Total profit", _signed_money(total_profit)],
		["Best day", best_call if best_call != "" else "None"],
		["Plans played", str(cards_played)],
		["Days open", "%d of %d" % [day, total_days]],
	]
	var y := r.position.y + 236.0
	for st in stats:
		_text(Vector2(x, y), st[0], T_LG, c_muted, true)
		_heavy_right(right, y, st[1], T_XL, c_ink)
		y += 62.0
	_pill(Rect2(right - 320.0, r.end.y - 52.0 - 76.0, 320.0, 76.0), "Play again", _new_run, true, "gold", T_XL)
