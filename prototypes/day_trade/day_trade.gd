extends Node2D
class_name DayTradePrototype

## Day Trade — a psychic's trading game, played on a board. A stock trading roguelike prototype.
## Each morning you draw tomorrow's headline and trade. Then you roll one die per stock card you own
## and set each die into a card's hole: the card's outcome row turns the die into the day's gain or loss.
## Fortune cards, bought from the shop with Insight, are one-shot tricks. Survive 20 trading days of bills.

@export_group("Run")
@export var total_days: int = 20
@export var starting_cash: float = 100.0
@export var portfolio_slots: int = 5
@export var market_size: int = 5
@export var bill_base: float = 3.0
@export var bill_growth: float = 1.17
@export var sell_fee: float = 0.02

@export_group("Market")
## Every outcome-table face is shifted by this many percentage points. Placing dice is strong; this pays for it.
@export var table_shift: float = -6.0
## Random wobble on each face of a new stock's table, in percentage points (plus a bit for big faces).
@export var face_jitter: float = 2.0
## Tomorrow's headline moves the stocks it names by a random amount in this range.
@export var news_shift_min: float = 0.05
@export var news_shift_max: float = 0.15
@export var quiet_news_chance: float = 0.15
## Each listing is a pack of shares sold whole. A pack is worth about pack_base on day 1, growing by pack_growth a day.
@export var pack_base: float = 15.0
@export var pack_growth: float = 1.15
## Chance that one listing a day is a premium stock sold as a single pricey share, whatever the pack value.
@export var premium_chance: float = 0.35
## Chance per listing that the market offers another pack of a stock you already own.
@export var owned_pack_chance: float = 0.25
## At least this many packs cost no more than affordable_share of your net worth.
@export var min_affordable: int = 3
@export var affordable_share: float = 0.4
## How often a new stock's dice pattern is wide (half the faces), medium (a third) or narrow (one face).
@export var pattern_tier_weights: Array[float] = [0.5, 0.3, 0.2]
@export var dividend_rate: float = 0.02

@export_group("Mania")
## Each level of mania in a sector multiplies its stocks' gains by this much more (losses are untouched).
@export var mania_step: float = 0.25
@export var mania_max: int = 4
## Chance per level, each day, that a manic sector crashes at the bell: its stocks lose crash_drop and mania resets.
@export var crash_per_level: float = 0.06
@export var crash_drop: float = 0.30
@export var mania_price: int = 3

@export_group("Fortune cards")
## Insight earned at every bell: this much, plus 1 per stock that closes up (up to the cap).
@export var ip_per_day: int = 1
@export var ip_green_cap: int = 3
## Cards offered in the fortune shop each day, and what a fresh shuffle costs.
@export var shop_size: int = 4
@export var reshuffle_cost: int = 1
@export var hand_size: int = 5
@export var starting_hand: Array[String] = ["reroll", "nudge_up"]

@export_group("Feel")
@export var close_anim_seconds: float = 1.6
@export var paper_anim_seconds: float = 0.85
@export var roll_seconds: float = 1.0

enum Phase { NEWS, TRADE, ROLL, PLACE, CLOSING, REPORT, GAMEOVER }

# Each type of stock is a six-face outcome table, in percent. The table's shape is what matters:
# which faces a stock wants decides where your dice should go.
var archetypes := {
	"blue": {"label": "Blue Chip", "shape": "Steady", "price": Vector2(5, 2500), "sectors": ["Tech", "Finance", "Consumer", "Energy"],
		"faces": [-6, -2, 3, 8, 13, 18]},
	"dividend": {"label": "Dividend", "shape": "Flat, pays dividends", "price": Vector2(5, 2500), "sectors": ["Energy", "Finance", "Consumer"],
		"faces": [-4, 0, 3, 6, 9, 12]},
	"growth": {"label": "Growth", "shape": "Climber", "price": Vector2(5, 2500), "sectors": ["Tech", "Health", "Consumer"],
		"faces": [-20, -10, 0, 10, 20, 30]},
	"cyclical": {"label": "Cyclical", "shape": "Wants the middle", "price": Vector2(5, 2500), "sectors": ["Energy", "Finance", "Consumer"],
		"faces": [-20, 5, 25, 25, 5, -20]},
	"bear": {"label": "Bear Fund", "shape": "Wants low rolls", "price": Vector2(5, 2500), "sectors": ["Finance"],
		"faces": [30, 20, 10, 0, -10, -20]},
	"biotech": {"label": "Biotech", "shape": "Long shot", "price": Vector2(5, 2500), "sectors": ["Health"],
		"faces": [-40, -28, -15, -5, 10, 55]},
	"meme": {"label": "Meme", "shape": "Odd faces up", "price": Vector2(5, 2500), "sectors": ["Tech", "Consumer", "Finance"],
		"faces": [25, -20, 25, -20, 35, -25]},
	"penny": {"label": "Penny", "shape": "Cliff", "price": Vector2(1, 5), "sectors": ["Energy", "Tech", "Health"],
		"faces": [-75, -50, -25, -5, 25, 70]},
}
var risky_archetypes: Array[String] = ["biotech", "meme", "penny"]

var sector_names: Array[String] = ["Tech", "Energy", "Health", "Consumer", "Finance"]

var name_prefixes: Array[String] = ["Maple", "Lantern", "Copper", "Juniper", "Harbor", "Quill", "Pebble", "Saffron",
	"Willow", "Orbit", "Tidewater", "Fern", "Honey", "Birch", "Cobalt", "Meadow", "Ember", "Atlas", "Pine", "Kestrel",
	"Clover", "Ridge", "Marble", "Nimbus", "Otter", "Sable", "Velvet", "Acorn", "Lumen", "Brook"]
var name_suffixes := {
	"Tech": ["Systems", "Labs", "Software", "Networks", "Robotics"],
	"Energy": ["Power", "Grid", "Solar", "Petroleum", "Hydro"],
	"Health": ["Bio", "Therapeutics", "Health", "Genomics", "Pharma"],
	"Consumer": ["Goods", "Market", "Brands", "Coffee", "Outfitters"],
	"Finance": ["Capital", "Trust", "Bancorp", "Holdings", "Mutual"],
}
var headlines := {
	"Tech": [["Chip shortage finally eases", "Antitrust probe widens"], ["AI spending spree continues", "Cloud budgets get trimmed"]],
	"Energy": [["Heat wave lifts power demand", "Oil glut deepens"], ["Pipeline deal approved", "Mild winter forecast"]],
	"Health": [["Regulator fast-tracks approvals", "Drug pricing bill advances"], ["Breakthrough trial results", "Hospital spending slows"]],
	"Consumer": [["Holiday shopping surges", "Shoppers tighten their belts"], ["Consumer confidence jumps", "Shipping costs spike"]],
	"Finance": [["Rate cut rumors swirl", "Regional bank jitters"], ["Record IPO week", "Loan defaults tick up"]],
}
var arch_headlines := {
	"blue": [["Investors flee to safety", "Big names stumble on weak guidance"]],
	"dividend": [["Yield hunters are back", "Dividend cuts spook income investors"]],
	"growth": [["Growth is back in fashion", "Growth stocks sink on rate fears"]],
	"cyclical": [["Factory orders boom", "Recession fears grip the Street"]],
	"bear": [["Short sellers smell blood", "Short squeeze burns the bears"]],
	"biotech": [["Biotech buyout frenzy", "Trial halted, biotech sector reels"]],
	"meme": [["Retail traders pile into meme stocks", "Meme stock bubble pops"]],
	"penny": [["Penny stock mania sweeps message boards", "Regulators crack down on pump-and-dumps"]],
}
var quiet_headlines: Array[String] = ["Markets brace for a quiet day", "Traders take a long lunch", "Nothing to see here, says Street"]

# Dice patterns: every stock prints one, with an ability beside it. If the die placed on the card fits the
# pattern, the ability fires on top of the table result. tier 0 patterns fit half the faces, tier 1 a third,
# tier 2 a single face, so narrower patterns pay more. "Neighbours" are the cards directly left and right of
# it in your portfolio. A stock's ability goes with it when it's sold or wiped out.
var pattern_defs := {
	"even": {"label": "Even", "tier": 0, "desc": "an even number (2, 4 or 6)"},
	"odd": {"label": "Odd", "tier": 0, "desc": "an odd number (1, 3 or 5)"},
	"high": {"label": "4-6", "tier": 0, "desc": "4, 5 or 6"},
	"low": {"label": "1-3", "tier": 0, "desc": "1, 2 or 3"},
	"edges": {"label": "1 or 6", "tier": 1, "desc": "1 or 6"},
	"middle": {"label": "3 or 4", "tier": 1, "desc": "3 or 4"},
	"pair": {"label": "Pair", "tier": 1, "desc": "the same number as another of your dice"},
	"exact": {"label": "{N}", "tier": 2, "desc": "exactly {N}"},
}

# Abilities. vals holds the strength for a wide, medium and narrow pattern; min_tier keeps the strongest
# abilities on narrow patterns only.
var ability_defs := {
	"boost": {"name": "Boost", "min_tier": 0, "vals": [0.05, 0.10, 0.20]},
	"surge": {"name": "Surge", "min_tier": 0, "vals": [1.5, 2.0, 3.0]},
	"shield": {"name": "Shield", "min_tier": 0, "vals": [0.0, 0.05, 0.10]},
	"insight": {"name": "Insight", "min_tier": 0, "vals": [1, 2, 3]},
	"tip": {"name": "Tip Jar", "min_tier": 0, "vals": [0.03, 0.06, 0.12]},
	"rent": {"name": "Landlord", "min_tier": 0, "vals": [0.15, 0.30, 0.60]},
	"card": {"name": "Insider", "min_tier": 1, "vals": [1, 1, 2]},
	"cheer": {"name": "Cheerleader", "min_tier": 1, "vals": [1, 1, 2]},
	"guard": {"name": "Lightning Rod", "min_tier": 1, "vals": [0, 0, 0]},
	"ace": {"name": "Ace", "min_tier": 2, "vals": [0, 0, 0]},
}

# Fortune cards: one-shot tricks bought from the shop with Insight and kept in your hand until played.
# target: what you click after playing it ("die", "stock", or "none" to take effect at once).
# when: "roll" after the dice are thrown, "trade" while the market is open, "any" for either.
var fortune_defs := {
	"nudge_up": {"name": "Nudge Up", "price": 2, "target": "die", "when": "roll", "desc": "Add 1 to a die."},
	"nudge_down": {"name": "Nudge Down", "price": 2, "target": "die", "when": "roll", "desc": "Take 1 from a die."},
	"flip": {"name": "Flip", "price": 3, "target": "die", "when": "roll", "desc": "Turn a die to its opposite face."},
	"reroll": {"name": "Reroll", "price": 1, "target": "die", "when": "roll", "desc": "Throw a die again."},
	"destiny": {"name": "Destiny", "price": 5, "target": "die", "when": "roll", "desc": "Set a die to 6."},
	"double_down": {"name": "Double Down", "price": 3, "target": "stock", "when": "roll", "desc": "Double a stock's gain or loss today."},
	"safety_net": {"name": "Safety Net", "price": 3, "target": "stock", "when": "any", "desc": "A stock can't lose money today."},
	"extra_die": {"name": "Extra Die", "price": 4, "target": "none", "when": "roll", "desc": "Throw one more die into the tray."},
	"refresh": {"name": "Fresh Listings", "price": 1, "target": "none", "when": "trade", "desc": "Replace every stock in the market."},
	"clairvoyance": {"name": "Clairvoyance", "price": 1, "target": "none", "when": "any", "desc": "See exactly how much tomorrow's headline moves its stocks."},
	"windfall": {"name": "Windfall", "price": 3, "target": "none", "when": "any", "desc": "Gain cash now. Pays more later in the run."},
	"rent_cut": {"name": "Landlord's Mercy", "price": 3, "target": "none", "when": "any", "desc": "Halve today's bill."},
}

class Stock:
	var ticker := ""
	var name := ""
	var sector := ""
	var arch := ""
	var faces := PackedFloat32Array()  # six returns, as fractions
	var price := 0.0
	var history := PackedFloat32Array()
	var pattern := ""
	var pattern_n := 0  # the number an "exact" pattern wants
	var ability := ""
	var pack := 0  # shares in this stock's market listing

class Holding:
	var stock: Stock
	var shares := 0
	var invested := 0.0
	var days_held := 0
	var last_ret := 0.0
	var last_face := 0
	var has_last := false
	var anim_from := 0.0
	var anim_to := 0.0
	var flash := 0.0
	var double_today := false
	var safe_today := false
	var last_fired := false

	func value() -> float:
		return float(shares) * stock.price

class Die:
	var face := 1
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
	var size := 32

class UiButton:
	var rect: Rect2
	var cb: Callable

# ---------------------------------------------------------------- palette
# The board is printed deep indigo with a faint star chart; cards are clean white stock.
var c_board := Color("27324c")
var c_board_dark := Color("1c2438")
var c_board_line := Color("38476a")
var c_board_ink := Color("8494b6")
var c_board_text := Color("c9d3ea")
var c_well := Color("18203a")
var c_stock := Color("fcfcfa")
var c_ivory := Color("fffdf7")
var c_ink := Color("1c2232")
var c_muted := Color("7d8596")
var c_up := Color("23936b")
var c_up_light := Color("6fd3a5")
var c_up_soft := Color("dcf3e8")
var c_down := Color("d9503f")
var c_down_light := Color("ff8a78")
var c_down_soft := Color("fbe1dc")
var c_green := c_up
var c_red := c_down
var c_gold := Color("e7b54c")
var c_gold_dark := Color("a77a1f")
var c_gold_chip := Color("c9932c")
var c_down_chip := Color("c95546")
var c_violet := Color("7a5bd6")
var c_violet_dark := Color("4b3592")
var c_violet_light := Color("b9a3ff")
var c_violet_card := Color("3b2d72")
var c_accent := Color("2f8a6a")
var c_paper := Color("f2ead9")
var c_newsprint := Color("1f1c18")
var sector_colors := {
	"Tech": Color("4f7be0"), "Energy": Color("e98a2e"), "Health": Color("2fae8d"),
	"Consumer": Color("d65c9e"), "Finance": Color("8a6be0"),
}
# Chips for the stock types that matter most at a glance. Other types get a plain grey chip.
var arch_chip_colors := {
	"penny": Color("b8692f"), "blue": Color("1d3c8c"), "biotech": Color("c2416b"), "meme": Color("8e44c9"),
}
var kind_colors := {
	"Research": Color("4f7be0"), "Synergy": Color("2f8a6a"), "Safety": Color("6c7690"),
	"Economy": Color("c9932c"), "Learning": Color("c4613f"), "Psychic": Color("7a5bd6"),
}

# ---------------------------------------------------------------- state
var phase := Phase.NEWS
var day := 1
var cash := 0.0
var ip := 0
var holdings: Array[Holding] = []
var market: Array[Stock] = []
var hand: Array[String] = []
var shop: Array[String] = []
var shop_sold: Array[bool] = []
var cards_played := 0
var clair_today := false
var rent_cut_today := false
var bill_relief := 0.0
var frame_outcomes := {}
var mania := {}  # sector -> mania level
var crashed := {}  # sectors that crashed at today's bell
var dice: Array[Die] = []
var drag_die: Die
var armed_card := -1  # index into hand of a card waiting for its target
var news_kind := ""  # "sector", "arch", or "" on a quiet day
var news_target := ""
var news_value := 0.0
var news_text := ""
var news_t := 0.0
var report := {}
var pending_ip := 0
var anim_t := 0.0
var bankrupt := false
var peak_worth := 0.0
var best_call := ""
var best_call_ret := -1.0
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
var desk_y := 0.0
var clock := 0.0
var cur_offset := Vector2.ZERO  # transform of whatever is being drawn now, so buttons register in room space
var cur_scale := 1.0
var r_top := Rect2()
var r_port := Rect2()
var r_shop := Rect2()
var r_market := Rect2()
var r_felt := Rect2()  # the dice tray
var r_track := Rect2()
var r_res := Rect2()
var r_event := Rect2()
var r_hand := Rect2()

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
const CARD_H := 346.0
const CARD_GAP := 22.0

func _ready() -> void:
	randomize()
	for sec in sector_names:
		fortune_defs["mania_" + sec] = {"type": "mania", "sector": sec, "name": "%s Mania" % sec, "price": mania_price,
			"target": "none", "when": "any",
			"desc": "%s mania +1. Bigger gains, but it may crash." % sec}
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
	r_track = Rect2(40, 26, 2480, 112)
	r_port = Rect2(40, 166, 1390, 426)
	r_market = Rect2(40, 612, 1390, 426)
	r_shop = Rect2(40, 1058, 1390, 352)
	var x0 := 1462.0
	var w := 2520.0 - x0
	r_res = Rect2(x0, 166, w, 108)
	r_event = Rect2(x0, 292, w, 156)
	r_felt = Rect2(x0, 474, w, 430)
	r_hand = Rect2(x0, 930, w, 480)

# ---------------------------------------------------------------- stocks
func _make_stock() -> Stock:
	var keys := archetypes.keys()
	var arch: String = keys[randi() % keys.size()]
	var a: Dictionary = archetypes[arch]
	var sectors: Array = a["sectors"]
	var s := Stock.new()
	s.arch = arch
	s.sector = sectors[randi() % sectors.size()]
	var base: Array = a["faces"]
	for v in base:
		var pct: float = float(v) + table_shift
		pct += randf_range(-1.0, 1.0) * (face_jitter + absf(pct) * 0.12)
		s.faces.append(roundf(pct) / 100.0)
	var pr: Vector2 = a["price"]
	# Share prices are spread evenly on a log scale, so $3 and $300 stocks are equally common.
	s.price = snappedf(exp(randf_range(log(pr.x), log(pr.y))), 0.01)
	_roll_ability(s)
	# Fake a short price history so the sparkline has something to say.
	var hist: Array[float] = [s.price]
	var p := s.price
	for k in 11:
		p = p / (1.0 + s.faces[randi() % 6] * 0.35)
		hist.push_front(p)
	s.history = PackedFloat32Array(hist)
	_name_stock(s)
	return s

func _name_stock(s: Stock) -> void:
	var taken := {}
	for h in holdings:
		taken[h.stock.ticker] = true
	for m in market:
		taken[m.ticker] = true
	var suffixes: Array = name_suffixes[s.sector]
	for attempt in 40:
		var pre: String = name_prefixes[randi() % name_prefixes.size()]
		var suf: String = suffixes[randi() % suffixes.size()]
		var ticker := (pre.substr(0, 3) + suf.substr(0, 1)).to_upper()
		if attempt > 20:
			ticker = (pre.substr(0, 2) + suf.substr(0, 2)).to_upper()
		if not taken.has(ticker):
			s.name = pre + " " + suf
			s.ticker = ticker
			return
	s.name = "Mystery Corp"
	s.ticker = "MYS%d" % (randi() % 10)

func _pack_target() -> float:
	return pack_base * pow(pack_growth, day - 1)

func _size_pack(st: Stock) -> void:
	# A pack holds however many shares make it worth roughly today's pack value. Pricey stocks come one at a time.
	var target := _pack_target() * randf_range(0.7, 1.3)
	st.pack = maxi(1, roundi(target / st.price))

func _pack_cost(st: Stock) -> float:
	return float(st.pack) * st.price

func _fill_market() -> void:
	market.clear()
	var has_premium := false
	for i in market_size:
		var owned_pick: Stock = null
		if not holdings.is_empty() and randf() < owned_pack_chance:
			var h := holdings[randi() % holdings.size()]
			if not market.has(h.stock):
				owned_pick = h.stock
		var st := owned_pick
		if st == null:
			if not has_premium and randf() < premium_chance:
				st = _make_stock()
				has_premium = st.price > _pack_target() * 1.3
			else:
				st = _listing_stock()
		_size_pack(st)
		market.append(st)
	_ensure_affordable()

func _listing_stock() -> Stock:
	# Most listings are priced so a pack of them lands near today's pack value.
	var st := _make_stock()
	for attempt in 40:
		if st.price <= _pack_target() * 1.3:
			break
		st = _make_stock()
	return st

func _ensure_affordable() -> void:
	# Pricey listings are something to grow into, but most of the market should be within reach.
	var budget := maxf(_pack_target() * 1.3, _net_worth() * affordable_share)
	var cheap := 0
	for st in market:
		if _pack_cost(st) <= budget:
			cheap += 1
	var i := market.size() - 1
	while cheap < min_affordable and i >= 0:
		if _pack_cost(market[i]) > budget and _holding_for(market[i]) == null:
			for attempt in 60:
				var st := _make_stock()
				_size_pack(st)
				if _pack_cost(st) <= budget:
					market[i] = st
					cheap += 1
					break
		i -= 1

func _arch_label(s: Stock) -> String:
	var a: Dictionary = archetypes[s.arch]
	return a["label"]

func _arch_shape(s: Stock) -> String:
	var a: Dictionary = archetypes[s.arch]
	return a["shape"]

# ---------------------------------------------------------------- tomorrow's paper
func _roll_news() -> void:
	# Pick a stock that's actually on screen so the headline always matters, then report on its sector or its type.
	news_kind = ""
	news_target = ""
	news_value = 0.0
	var pool: Array[Stock] = market.duplicate()
	for h in holdings:
		pool.append(h.stock)
	if pool.is_empty() or randf() < quiet_news_chance:
		news_text = quiet_headlines[randi() % quiet_headlines.size()]
		return
	var pick := pool[randi() % pool.size()]
	var good := randf() < 0.5
	var lines: Array
	if randf() < 0.55:
		news_kind = "sector"
		news_target = pick.sector
		lines = headlines[news_target]
	else:
		news_kind = "arch"
		news_target = pick.arch
		lines = arch_headlines[news_target]
	var amount := snappedf(randf_range(news_shift_min, news_shift_max), 0.01)
	news_value = amount if good else -amount
	var pair: Array = lines[randi() % lines.size()]
	news_text = pair[0] if good else pair[1]

func _news_hits(s: Stock) -> bool:
	if news_kind == "sector":
		return s.sector == news_target
	if news_kind == "arch":
		return s.arch == news_target
	return false

func _news_group() -> String:
	if news_kind == "sector":
		return "%s stocks" % news_target
	if news_kind == "arch":
		var a: Dictionary = archetypes[news_target]
		return "%s stocks" % a["label"]
	return ""

func _news_effect() -> String:
	if news_kind == "":
		return "No stocks affected"
	if clair_today:
		return "%s %+d%% at the bell" % [_news_group(), int(round(news_value * 100.0))]
	return "%s will %s at the bell" % [_news_group(), "rise" if news_value > 0.0 else "fall"]

func _news_result() -> String:
	if news_kind == "":
		return "No stocks affected"
	return "%s %s %d%%" % [_news_group(), "rose" if news_value > 0.0 else "fell", int(round(absf(news_value) * 100.0))]

func _dismiss_news() -> void:
	if phase == Phase.NEWS:
		phase = Phase.TRADE

# ---------------------------------------------------------------- run flow
func _new_run() -> void:
	day = 1
	cash = starting_cash
	ip = 0
	holdings.clear()
	market.clear()
	hand.clear()
	hand.append_array(starting_hand)
	mania.clear()
	shop.clear()
	shop_sold.clear()
	cards_played = 0
	floaters.clear()
	dice.clear()
	bankrupt = false
	peak_worth = starting_cash
	best_call = ""
	best_call_ret = -1.0
	_start_day()

func _start_day() -> void:
	_roll_shop()
	dice.clear()
	drag_die = null
	crashed.clear()
	armed_card = -1
	clair_today = false
	rent_cut_today = false
	bill_relief = 0.0
	for h in holdings:
		h.double_today = false
		h.safe_today = false
	_fill_market()
	_roll_news()
	news_t = 0.0
	phase = Phase.NEWS
	_play(tone_paper, randf_range(0.95, 1.05), -6.0)

func _bill_for(d: int) -> float:
	var b := roundf(bill_base * pow(bill_growth, d - 1))
	if d == day and rent_cut_today:
		b = roundf(b * 0.5 * 100.0) / 100.0
	return b

func _net_worth() -> float:
	var total := cash
	for h in holdings:
		total += h.value()
	return total

func _invested() -> float:
	var total := 0.0
	for h in holdings:
		total += h.invested
	return total

func _holding_for(s: Stock) -> Holding:
	for h in holdings:
		if h.stock == s:
			return h
	return null

func _fee() -> float:
	return sell_fee

func _can_buy(s: Stock) -> bool:
	if phase != Phase.TRADE or not market.has(s):
		return false
	if _pack_cost(s) > cash + 0.0001:
		return false
	return _holding_for(s) != null or holdings.size() < portfolio_slots

func _buy(s: Stock) -> void:
	# One click buys the whole pack, and the listing leaves the market.
	if not _can_buy(s):
		return
	var cost := _pack_cost(s)
	var h: Holding = _holding_for(s)
	if h == null:
		h = Holding.new()
		h.stock = s
		holdings.append(h)
	h.shares += s.pack
	h.invested += cost
	cash -= cost
	if cash < 0.005:
		cash = 0.0
	market.erase(s)
	_play(tone_buy, randf_range(0.97, 1.05), -8.0)

func _sell(h: Holding) -> void:
	# One click sells every share.
	if phase != Phase.TRADE:
		return
	cash += h.value() * (1.0 - _fee())
	holdings.erase(h)
	_play(tone_sell, randf_range(0.97, 1.05), -8.0)

func _refresh_market() -> void:
	_fill_market()
	# The headline was foreseen against the old listings; make sure it still points at something.
	var any_hit := false
	for st in market:
		if _news_hits(st):
			any_hit = true
	for h in holdings:
		if _news_hits(h.stock):
			any_hit = true
	if news_kind != "" and not any_hit:
		_roll_news()

# ---------------------------------------------------------------- dice
func _throw_face() -> int:
	return randi_range(1, 6)

func _tray_home(i: int, n: int) -> Vector2:
	# Dice settle in rows across the tray, leaving the bottom-right corner for the coin.
	var area := Rect2(r_felt.position.x + 30.0, r_felt.position.y + 70.0, r_felt.size.x - 260.0, r_felt.size.y - 150.0)
	var per_row := 6
	var rows := ceili(float(n) / per_row)
	var row := floori(float(i) / per_row)
	var in_row := mini(per_row, n - row * per_row)
	var col := i - row * per_row
	var spacing := 124.0
	var cx := area.get_center().x + (col - (in_row - 1) * 0.5) * spacing
	var cy := area.get_center().y + (row - (rows - 1) * 0.5) * 136.0
	return Vector2(cx, cy)

func _start_roll() -> void:
	if phase != Phase.TRADE:
		return
	if holdings.is_empty():
		# Nothing to roll for. Straight to the bell and the bills.
		_close_market()
		return
	dice.clear()
	var n := holdings.size()
	for i in n:
		var d := Die.new()
		d.face = _throw_face()
		d.shown_face = randi_range(1, 6)
		d.home = _tray_home(i, n)
		d.start = Vector2(r_felt.position.x + randf_range(40.0, r_felt.size.x - 300.0), r_felt.position.y - randf_range(120.0, 260.0))
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
			other.holding = d.holding  # swap: the bumped die takes this die's old spot (or the tray)
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
	# Greedy: keep taking the die/stock match that makes the whole portfolio the most money, perks included.
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
				var gain := _portfolio_gain(_outcomes(true))
				d.holding = null
				if gain > best_gain:
					best_gain = gain
					best_d = d
					best_h = h
		best_d.holding = best_h
		free_dice.erase(best_d)
		open.erase(best_h)
	_play(tone_clack, 1.0, -6.0)

func _portfolio_gain(o: Dictionary) -> float:
	var total := 0.0
	for h in o.keys():
		var r: Dictionary = o[h]
		var hh: Holding = h
		total += hh.value() * float(r["ret"]) + float(r["cash"]) + float(r["bill_cut"]) + float(r["insight"]) * 2.0 + float(r["cards"]) * 3.0
	return total

func _card_def(id: String) -> Dictionary:
	return fortune_defs[id]

func _card_usable(id: String) -> bool:
	var d := _card_def(id)
	var when: String = d["when"]
	var ok := false
	match when:
		"roll":
			ok = phase == Phase.PLACE
		"trade":
			ok = phase == Phase.TRADE
		_:
			ok = phase == Phase.TRADE or phase == Phase.PLACE
	if not ok:
		return false
	var dd := _card_def(id)
	if dd.get("type", "") == "mania":
		return int(mania.get(dd["sector"], 0)) < mania_max
	match id:
		"clairvoyance":
			return not clair_today and news_kind != ""
		"rent_cut":
			return not rent_cut_today
		"double_down", "safety_net":
			return not holdings.is_empty()
	return true

func _play_card(i: int) -> void:
	# Clicking a card in your hand: cards with a target wait for you to click it; others happen now.
	if i < 0 or i >= hand.size():
		return
	if armed_card == i:
		armed_card = -1
		return
	var id := hand[i]
	if not _card_usable(id):
		return
	var d := _card_def(id)
	if d.get("type", "") == "mania":
		var sec: String = d["sector"]
		mania[sec] = mini(mania_max, int(mania.get(sec, 0)) + 1)
		for h in holdings:
			if h.stock.sector == sec:
				h.flash = 1.0
		_spend_card(i)
		return
	if d["target"] != "none":
		armed_card = i
		_play(tone_power, 1.4, -12.0)
		return
	match id:
		"extra_die":
			var die := Die.new()
			die.face = _throw_face()
			die.home = _tray_home(dice.size(), dice.size() + 1)
			die.start = Vector2(r_felt.get_center().x, r_felt.position.y - 200.0)
			die.pos = die.start
			die.roll_dur = 0.6
			die.roll_t = die.roll_dur
			die.spin = randf_range(9.0, 13.0)
			dice.append(die)
			for k in dice.size():
				dice[k].home = _tray_home(k, dice.size())
			_play(tone_rattle, 1.2, -6.0)
		"refresh":
			_refresh_market()
		"clairvoyance":
			clair_today = true
		"windfall":
			cash += _windfall_amount()
		"rent_cut":
			rent_cut_today = true
	_spend_card(i)

func _windfall_amount() -> float:
	return 8.0 + 2.0 * day

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
		"destiny":
			if d.face == 6:
				return
			d.face = 6
		"reroll":
			d.face = _throw_face()
			d.start = d.pos + Vector2(randf_range(-30.0, 30.0), -70.0)
			d.roll_dur = 0.45
			d.roll_t = d.roll_dur
			d.spin = randf_range(8.0, 12.0)
	d.shown_face = d.face if d.roll_t <= 0.0 else d.shown_face
	d.flash = 1.0
	_spend_card(armed_card)

func _apply_card_stock(h: Holding) -> void:
	var id := hand[armed_card]
	match id:
		"double_down":
			if h.double_today:
				return
			h.double_today = true
		"safety_net":
			if h.safe_today:
				return
			h.safe_today = true
	h.flash = 1.0
	_spend_card(armed_card)

func _armed_target() -> String:
	if armed_card < 0 or armed_card >= hand.size():
		return ""
	var d := _card_def(hand[armed_card])
	return d["target"]

# ---------------------------------------------------------------- resolving the day
func _mania_mult(sector: String) -> float:
	return 1.0 + mania_step * int(mania.get(sector, 0))

func _crash_chance(sector: String) -> float:
	return crash_per_level * int(mania.get(sector, 0))

func _roll_ability(s: Stock) -> void:
	var roll := randf()
	var tier := 2
	if roll < pattern_tier_weights[0]:
		tier = 0
	elif roll < pattern_tier_weights[0] + pattern_tier_weights[1]:
		tier = 1
	var pats: Array = pattern_defs.keys().filter(func(k): return int(pattern_defs[k]["tier"]) == tier)
	s.pattern = pats[randi() % pats.size()]
	s.pattern_n = randi_range(1, 6) if s.pattern == "exact" else 0
	var abils: Array = ability_defs.keys().filter(func(k): return int(ability_defs[k]["min_tier"]) <= tier)
	s.ability = abils[randi() % abils.size()]

func _pattern_tier(st: Stock) -> int:
	return int(pattern_defs[st.pattern]["tier"])

func _ability_val(st: Stock) -> float:
	var vals: Array = ability_defs[st.ability]["vals"]
	return float(vals[_pattern_tier(st)])

func _pattern_label(st: Stock) -> String:
	var t: String = pattern_defs[st.pattern]["label"]
	return t.replace("{N}", str(st.pattern_n))

func _pattern_hit(st: Stock, face: int, face_counts: Dictionary) -> bool:
	match st.pattern:
		"even":
			return face % 2 == 0
		"odd":
			return face % 2 == 1
		"high":
			return face >= 4
		"low":
			return face <= 3
		"edges":
			return face == 1 or face == 6
		"middle":
			return face == 3 or face == 4
		"pair":
			return int(face_counts.get(face, 0)) >= 2
		"exact":
			return face == st.pattern_n
	return false

func _pct_s(v: float) -> String:
	return "%d%%" % int(round(v * 100.0))

func _ability_text(st: Stock) -> String:
	var v := _ability_val(st)
	match st.ability:
		"boost":
			return "+%s gain" % _pct_s(v)
		"surge":
			return "Gains x%s" % _fmt_mult(v)
		"shield":
			return "Can't lose" if v <= 0.0 else "No loss, +%s" % _pct_s(v)
		"insight":
			return "+%d Insight" % int(v)
		"tip":
			return "Pays %s cash" % _pct_s(v)
		"rent":
			return "Pays %s of bill" % _pct_s(v)
		"card":
			return "Draw a card" if int(v) == 1 else "Draw %d cards" % int(v)
		"cheer":
			return "Neighbours' dice +%d" % int(v)
		"guard":
			return "Shields neighbours"
		"ace":
			return "Reads best face"
	return ""

func _ability_desc(st: Stock) -> String:
	var v := _ability_val(st)
	var what := ""
	match st.ability:
		"boost":
			what = "it gains an extra %s." % _pct_s(v)
		"surge":
			what = "a gain is multiplied by %s (losses are untouched)." % _fmt_mult(v)
		"shield":
			what = "it can't lose money today." if v <= 0.0 else "it can't lose money today and gains an extra %s." % _pct_s(v)
		"insight":
			what = "you gain %d Insight." % int(v)
		"tip":
			what = "it pays you cash worth %s of its value." % _pct_s(v)
		"rent":
			what = "%s of today's bill is paid for you." % _pct_s(v)
		"card":
			what = "you draw %s (if your hand has room)." % ("a random fortune card" if int(v) == 1 else "%d random fortune cards" % int(v))
		"cheer":
			what = "its neighbours count their dice %d higher." % int(v)
		"guard":
			what = "its neighbours can't lose money today."
		"ace":
			what = "it reads its best face instead."
	var pd: String = pattern_defs[st.pattern]["desc"]
	return "If its die shows %s, %s" % [pd.replace("{N}", str(st.pattern_n)), what]

func _neighbours(h: Holding) -> Array[Holding]:
	# The cards directly left and right of this one in the portfolio rows.
	var out: Array[Holding] = []
	var idx := holdings.find(h)
	if idx < 0:
		return out
	if idx % 5 != 0 and idx - 1 >= 0:
		out.append(holdings[idx - 1])
	if (idx + 1) % 5 != 0 and idx + 1 < holdings.size():
		out.append(holdings[idx + 1])
	return out

func _outcomes(include_news: bool) -> Dictionary:
	# Works out every placed die's result together, since perks look at neighbours, sectors and other dice.
	# Returns Holding -> {face, eff, ret, fired, cash, insight, cards, bill_cut}.
	var base := {}
	for h in holdings:
		var d := _die_on(h)
		if d != null:
			base[h] = d.face
	var face_counts := {}
	for h in base.keys():
		var f: int = base[h]
		face_counts[f] = int(face_counts.get(f, 0)) + 1
	# Abilities that reach the neighbours go first: they change which face a neighbour reads, or shield it.
	var eff := {}
	var fired := {}
	var shielded := {}
	for h in base.keys():
		eff[h] = base[h]
	for h in base.keys():
		var hh: Holding = h
		if not _pattern_hit(hh.stock, int(base[h]), face_counts):
			continue
		match hh.stock.ability:
			"cheer":
				fired[h] = true
				for n in _neighbours(hh):
					if eff.has(n):
						eff[n] = int(eff[n]) + int(_ability_val(hh.stock))
			"guard":
				fired[h] = true
				for n in _neighbours(hh):
					shielded[n] = true

	# Then each card's result. Patterns always read the die itself; the table reads the effective face.
	var res := {}
	for h in base.keys():
		var hh: Holding = h
		var st := hh.stock
		var e := clampi(int(eff[h]), 1, 6)
		var hit := _pattern_hit(st, int(base[h]), face_counts)
		var v := _ability_val(st)
		if hit and st.ability == "ace":
			for k in 6:
				if st.faces[k] > st.faces[e - 1]:
					e = k + 1
		var r: float = st.faces[e - 1]
		var no_loss := hh.safe_today or shielded.has(h)
		var cash_gain := 0.0
		var insight := 0
		var cards := 0
		var bill_cut := 0.0
		var on := bool(fired.get(h, false)) or hit
		if include_news and _news_hits(st):
			r += news_value
		if hit:
			match st.ability:
				"boost":
					r += v
				"surge":
					if r > 0.0:
						r *= v
				"shield":
					no_loss = true
					r += v
				"insight":
					insight += int(v)
				"tip":
					cash_gain += hh.value() * v
				"rent":
					bill_cut += _bill_for(day) * v
				"card":
					cards += int(v)
		# Mania boosts gains only. A crash hits everything in the sector.
		if r > 0.0:
			r *= _mania_mult(st.sector)
		if crashed.has(st.sector):
			r -= crash_drop
		if hh.double_today:
			r *= 2.0
		if no_loss:
			r = maxf(r, 0.0)
		r = clampf(r, -1.0, 3.0)
		res[h] = {"face": int(base[h]), "eff": e, "ret": r, "fired": on, "cash": cash_gain, "insight": insight, "cards": cards, "bill_cut": bill_cut}
	return res

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
	# Bubbles may burst before the results are worked out.
	crashed.clear()
	for sec in mania.keys():
		if int(mania[sec]) > 0 and randf() < _crash_chance(sec):
			crashed[sec] = true
	var outs := _outcomes(true)
	var rows: Array[Dictionary] = []
	var perk_cash := 0.0
	var perk_insight := 0
	var perk_cards: Array[String] = []
	bill_relief = 0.0
	var green := 0
	var red := 0
	var dividends := 0.0
	var interest := 0.0
	for i in holdings.size():
		var h := holdings[i]
		var o: Dictionary = outs.get(h, {})
		var face: int = o.get("face", 0)
		var before := h.value()
		var r: float = o.get("ret", 0.0)
		h.last_fired = bool(o.get("fired", false))
		perk_cash += float(o.get("cash", 0.0))
		perk_insight += int(o.get("insight", 0))
		bill_relief += float(o.get("bill_cut", 0.0))
		for c in int(o.get("cards", 0)):
			if hand.size() < hand_size:
				var ids: Array = fortune_defs.keys()
				var drawn: String = ids[randi() % ids.size()]
				hand.append(drawn)
				perk_cards.append(_card_def(drawn)["name"])
		h.stock.price = maxf(h.stock.price * (1.0 + r), 0.0)
		h.stock.history.append(h.stock.price)
		h.last_ret = r
		h.last_face = face
		h.has_last = true
		h.days_held += 1
		var after := h.value()
		h.anim_from = before
		h.anim_to = after
		h.flash = 1.0
		if h.stock.arch == "dividend" and after > 0.0:
			dividends += after * dividend_rate
		if r > 0.0:
			green += 1
		elif r < 0.0:
			red += 1
		if r > best_call_ret:
			best_call_ret = r
			best_call = "%s %+.0f%% on a %d, day %d" % [h.stock.ticker, r * 100.0, face, day]
		var perk_name := ""
		if h.last_fired:
			perk_name = ability_defs[h.stock.ability]["name"]
		rows.append({"ticker": h.stock.ticker, "name": h.stock.name, "ret": r, "delta": after - before,
			"wiped": after <= 0.0001, "face": face, "perk": perk_name})
		var cr := _holding_rect(i)
		_spawn_floater(Vector2(cr.position.x + cr.size.x * 0.45, cr.position.y + cr.size.y * 0.55), "%+.1f%%" % (r * 100.0), c_green if r >= 0.0 else c_red, 40)
	cash += dividends + interest + perk_cash
	pending_ip = ip_per_day + mini(ip_green_cap, green) + perk_insight
	var crash_list: Array[String] = []
	for sec in crashed.keys():
		crash_list.append(sec)
		mania[sec] = 0
	report = {"crashes": crash_list, "rows": rows, "dividends": dividends, "interest": interest, "news": "%s  ·  %s" % [news_text, _news_result()], "forced": [] as Array[String],
		"perk_cash": perk_cash, "perk_insight": perk_insight, "perk_cards": perk_cards, "bill_relief": bill_relief}
	anim_t = 0.0
	phase = Phase.CLOSING

func _finish_close() -> void:
	# Delisted holdings disappear; then the bills come due.
	for i in range(holdings.size() - 1, -1, -1):
		if holdings[i].value() <= 0.0001:
			var d := _die_on(holdings[i])
			if d != null:
				dice.erase(d)
			holdings.remove_at(i)
	var bill := maxf(0.0, _bill_for(day) - bill_relief)
	cash -= bill
	var forced: Array[String] = []
	while cash < -0.0001 and not holdings.is_empty():
		var smallest := holdings[0]
		for h in holdings:
			if h.value() < smallest.value():
				smallest = h
		var need := -cash
		var full := smallest.value() * (1.0 - _fee())
		if full <= need:
			cash += full
			var sd := _die_on(smallest)
			if sd != null:
				dice.erase(sd)
			holdings.erase(smallest)
			forced.append("Sold all of %s to cover bills" % smallest.stock.ticker)
		else:
			var per_share := smallest.stock.price * (1.0 - _fee())
			var qty := clampi(ceili(need / per_share - 0.0001), 1, smallest.shares)
			smallest.invested *= 1.0 - float(qty) / float(smallest.shares)
			smallest.shares -= qty
			cash += float(qty) * per_share
			forced.append("Sold %d share%s of %s to cover bills" % [qty, "" if qty == 1 else "s", smallest.stock.ticker])
	if cash < -0.0001:
		bankrupt = true
	elif cash < 0.0:
		cash = 0.0
	ip += pending_ip
	peak_worth = maxf(peak_worth, _net_worth())
	report["bill"] = bill
	report["forced"] = forced
	report["ip"] = pending_ip
	report["worth"] = _net_worth()
	phase = Phase.REPORT

func _continue_from_report() -> void:
	if bankrupt or day >= total_days:
		phase = Phase.GAMEOVER
		return
	_next_day()

func _roll_shop() -> void:
	var ids: Array = fortune_defs.keys()
	ids.shuffle()
	shop.clear()
	shop_sold.clear()
	for k in mini(shop_size, ids.size()):
		shop.append(ids[k])
		shop_sold.append(false)

func _card_price(id: String) -> int:
	var d := _card_def(id)
	return d["price"]

func _buy_card(i: int) -> void:
	if not (phase == Phase.TRADE or phase == Phase.PLACE) or shop_sold[i] or hand.size() >= hand_size:
		return
	var price := _card_price(shop[i])
	if ip < price:
		return
	ip -= price
	hand.append(shop[i])
	shop_sold[i] = true
	_play(tone_learn, 1.0, -6.0)

func _reshuffle_shop() -> void:
	if ip < reshuffle_cost or not (phase == Phase.TRADE or phase == Phase.PLACE):
		return
	ip -= reshuffle_cost
	_roll_shop()
	_play(tone_sell, 1.3, -10.0)

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
	if phase == Phase.NEWS:
		news_t = minf(1.0, news_t + delta / maxf(paper_anim_seconds, 0.05))
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
			# Tumbling: skid in from the side of the tray, bouncing less each hop, face flickering.
			d.roll_t = maxf(0.0, d.roll_t - delta)
			var t := 1.0 - d.roll_t / d.roll_dur
			var e := 1.0 - pow(1.0 - t, 3.0)
			var target := d.home if d.holding == null else _socket_rect(holdings.find(d.holding)).get_center()
			d.pos = d.start.lerp(target, e) + Vector2(0.0, -absf(sin(t * PI * 3.0)) * 70.0 * (1.0 - t))
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
			if target == "stock":
				var th := _holding_at(ui_p)
				if th != null:
					_apply_card_stock(th)
					queue_redraw()
					return
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
			armed_card = -1
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and drag_die != null:
			var target := _holding_at(ui_p)
			if target != null:
				_assign(drag_die, target)
			elif r_felt.grow(30.0).has_point(ui_p):
				_assign(drag_die, null)
			# Dropped somewhere else: it springs back to wherever it was.
			drag_die = null
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
				Phase.NEWS:
					if news_t >= 1.0:
						_dismiss_news()
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

func _pct(v: float) -> String:
	return "%+.1f%%" % (v * 100.0)

func _face_pct(v: float) -> String:
	var p := int(round(v * 100.0))
	return "%+d%%" % p if p != 0 else "0%"

func _ret_color(v: float) -> Color:
	if v > 0.005:
		return c_green
	if v < -0.005:
		return c_red
	return c_muted

# ---------------------------------------------------------------- layout
func _holding_rect(i: int) -> Rect2:
	var cols := 5
	var col := i % cols
	var row := floori(float(i) / cols)
	var x0 := r_port.position.x + 24.0
	var y0 := r_port.position.y + 60.0
	return Rect2(x0 + col * (CARD_W + CARD_GAP), y0 + row * (CARD_H + CARD_GAP), CARD_W, CARD_H)

func _market_rect(i: int) -> Rect2:
	var x0 := r_market.position.x + 24.0
	var y0 := r_market.position.y + 60.0
	return Rect2(x0 + i * (CARD_W + CARD_GAP), y0, CARD_W, CARD_H)

func _hole_rect(card: Rect2) -> Rect2:
	return Rect2(card.get_center().x - HOLE_SIZE * 0.5, card.position.y + 97.0, HOLE_SIZE, HOLE_SIZE)

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
	_panel(Rect2(r.position + Vector2(0.0, depth), r.size), Color(0.02, 0.03, 0.08, alpha), radius)
	_panel(Rect2(r.position + Vector2(-2.0, depth * 0.5), r.size + Vector2(4.0, 2.0)), Color(0.02, 0.03, 0.08, alpha * 0.35), radius + 2)

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

func _text_right(right_x: float, y: float, s: String, size: int, col: Color, bold: bool = false) -> void:
	draw_string(_f(bold), Vector2(right_x - _text_w(s, size, bold), y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

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
	_panel(Rect2(r.position + Vector2(0, 6), r.size), Color(0.02, 0.03, 0.08, 0.35), radius)
	_panel(Rect2(r.position + Vector2(0, 5), r.size), edge, radius)
	var top := Rect2(r.position + Vector2(0, press), r.size)
	_panel(top, face.lightened(0.06) if hovered else face, radius)
	_heavy_center(top, label, size, ink)
	if live:
		_register(r, cb)

func _chip_token(c: Vector2, rad: float, label: String, cb: Callable, enabled: bool, col: Color, tip: String = "") -> void:
	# A poker-chip style token, with dashes around the rim.
	var live := enabled and ui_live
	var box := Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2.0)
	var hovered := live and box.has_point(mouse)
	var face := col if enabled else c_board_line
	draw_circle(c + Vector2(0, 5), rad, Color(0.02, 0.03, 0.08, 0.4))
	draw_circle(c + Vector2(0, 3), rad, face.darkened(0.3))
	var cc := c + Vector2(0, -2.0 if hovered else 0.0)
	draw_circle(cc, rad, face)
	for k in 8:
		var a := TAU * k / 8.0
		draw_arc(cc, rad - 5.0, a, a + 0.28, 4, Color(1, 1, 1, 0.75 if enabled else 0.25), 5.0, true)
	draw_circle(cc, rad - 11.0, face.lightened(0.08))
	_heavy_center(Rect2(cc - Vector2(rad, rad), Vector2(rad, rad) * 2.0), label, 19 if label.length() <= 4 else 16, Color.WHITE if enabled else c_board_ink)
	if live:
		_register(box, cb)
	if tip != "":
		_tip(box, tip)

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
	draw_circle(c + Vector2(0, 9), rad, Color(0.02, 0.03, 0.08, 0.45))
	draw_circle(c + Vector2(0, 6), rad, face.darkened(0.35))
	var cc := c + Vector2(0, 2.0 if hovered else 0.0)
	draw_circle(cc, rad, face)
	draw_arc(cc, rad - 12.0, 0.0, TAU, 48, face.darkened(0.18), 3.0, true)
	draw_arc(cc, rad - 3.0, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.35), 4.0, true)
	var lines := label.split("\n")
	var size := 30 if lines.size() == 1 else 26
	var ink := c_ink if enabled else c_board_ink
	var total_h := lines.size() * size * 1.05
	for i in lines.size():
		var y := cc.y - total_h * 0.5 + (i + 0.82) * size * 1.05
		_heavy(Vector2(cc.x - _heavy_w(lines[i], size) * 0.5, y), lines[i], size, ink)
	if live:
		_register(box, cb)

func _gem(c: Vector2, rad: float, filled: bool) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -rad), c + Vector2(rad * 0.8, -rad * 0.2), c + Vector2(0, rad), c + Vector2(-rad * 0.8, -rad * 0.2)])
	if filled:
		draw_colored_polygon(pts, c_violet_light)
		draw_colored_polygon(PackedVector2Array([pts[0], pts[1], c + Vector2(0, -rad * 0.2)]), Color(1, 1, 1, 0.35))
	else:
		pts.append(pts[0])
		draw_polyline(pts, c_board_ink, 2.0, true)

func _gold_coin_icon(c: Vector2, rad: float) -> void:
	draw_circle(c + Vector2(0, 3), rad, c_gold_dark)
	draw_circle(c, rad, c_gold)
	draw_arc(c, rad - 4.0, 0.0, TAU, 24, c_gold_dark, 2.0, true)

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
		_panel(Rect2(Vector2(-size, -size) * 0.5 + Vector2(4, depth), Vector2(size, size)), Color(0.02, 0.03, 0.08, 0.35), int(size * 0.2))
	var outline := Color(0, 0, 0, 0)
	if _armed_target() == "die" and hovered:
		outline = c_violet
	elif hovered:
		outline = c_gold
	var body := c_ivory.lerp(Color("e4dcfb"), d.flash)
	_draw_die_body(Vector2.ZERO, size, d.shown_face, body, c_ink, outline)
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
	frame_outcomes = _outcomes(clair_today) if phase == Phase.PLACE else {}

	var modal := phase == Phase.NEWS or phase == Phase.REPORT or phase == Phase.GAMEOVER
	ui_live = phase == Phase.TRADE or phase == Phase.PLACE
	tips_live = not modal and drag_die == null
	_draw_board()
	_draw_track()
	_draw_portfolio()
	_draw_market()
	_draw_shop()
	_draw_resources()
	_draw_event_slot()
	_draw_tray()
	_draw_hand()
	for d in dice:
		if d != drag_die:
			_draw_die(d)
	if drag_die != null:
		_draw_die(drag_die)
	_draw_floaters()
	if _armed_target() != "":
		var pd := _card_def(hand[armed_card])
		var hint := "%s: click %s" % [pd["name"], "a die" if _armed_target() == "die" else "one of your stocks"]
		var hw := _heavy_w(hint, 22) + 40.0
		var hr := Rect2(mouse + Vector2(26.0, 18.0), Vector2(hw, 46.0))
		_panel(hr, c_violet, 23)
		_heavy_center(hr, hint, 22, Color.WHITE)
	ui_live = true
	tips_live = true
	match phase:
		Phase.NEWS:
			_draw_event_reveal()
		Phase.REPORT:
			_draw_report()
		Phase.GAMEOVER:
			_draw_gameover()
	if hover_tip != "":
		_draw_tooltip(hover_tip, view_size)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_board() -> void:
	# The printed board: deep indigo with a faint star chart, and a soft lighter centre.
	var b := Rect2(Vector2(-400, -400), view_size + Vector2(800, 800))
	draw_rect(b, c_board)
	for i in 5:
		draw_circle(view_size * 0.5, view_size.x * (0.55 - i * 0.09), Color(1, 1, 1, 0.012))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var stars: Array[Vector2] = []
	for i in 70:
		var p := Vector2(rng.randf() * view_size.x, rng.randf() * view_size.y)
		stars.append(p)
		draw_circle(p, rng.randf_range(1.2, 2.8), Color(c_board_ink, rng.randf_range(0.10, 0.28)))
	for i in 22:
		var a := stars[rng.randi() % stars.size()]
		var best := Vector2.ZERO
		var best_d := INF
		for s in stars:
			var dd := a.distance_to(s)
			if dd > 20.0 and dd < best_d:
				best_d = dd
				best = s
		if best_d < 320.0:
			draw_line(a, best, Color(c_board_ink, 0.07), 1.5, true)

func _zone(r: Rect2, title: String, note: String) -> void:
	# A printed area of the board: a faint inset panel with its name in board ink.
	_panel(r, Color(c_board_dark, 0.55), 26)
	_panel(r, Color(0, 0, 0, 0), 26, Color(c_board_line, 0.9), 2)
	_heavy(r.position + Vector2(26.0, 42.0), title, 28, c_board_text)
	if note != "":
		_text(Vector2(r.position.x + 40.0 + _heavy_w(title, 28), r.position.y + 41.0), note, 20, c_board_ink)

func _draw_track() -> void:
	# The day track: twenty printed spaces, each showing the bill due that day. Your pawn stands on today.
	var r := r_track
	_heavy(Vector2(r.position.x, r.position.y + 62.0), "Day Trade", 52, c_stock)
	_text(Vector2(r.position.x + 2.0, r.position.y + 96.0), "A psychic's trading game", 21, c_board_ink, true)
	var x0 := r.position.x + 330.0
	var gap := 8.0
	var w := (r.end.x - x0 - gap * (total_days - 1)) / total_days
	for d in total_days:
		var day_n := d + 1
		var sr := Rect2(x0 + d * (w + gap), r.position.y + 6.0, w, r.size.y - 6.0)
		var past := day_n < day or (day_n == day and phase == Phase.REPORT)
		var now := day_n == day
		var fill := Color(c_board_dark, 0.7)
		if past:
			fill = Color(c_board_line, 0.55)
		_panel(sr, fill, 14, c_gold if now else Color(c_board_line, 0.9), 3 if now else 2)
		_text(sr.position + Vector2(12.0, 26.0), str(day_n), 18, c_board_ink, true)
		var bill_s := "$%d" % int(roundf(_bill_for(day_n)))
		var bill_col := c_board_text if not past else Color(c_board_ink, 0.6)
		if now:
			bill_col = c_down_light
		_heavy_center(Rect2(sr.position.x, sr.end.y - 46.0, sr.size.x, 36.0), bill_s, 24, bill_col)
		if past:
			draw_line(Vector2(sr.position.x + 22.0, sr.end.y - 28.0), Vector2(sr.end.x - 22.0, sr.end.y - 28.0), Color(c_board_ink, 0.6), 2.0)
		if now:
			_draw_pawn(Vector2(sr.end.x - 26.0, sr.position.y + 30.0))
		var when := "Paid" if past else "Due at the bell"
		_tip(sr, "Day %d. Bill: %s. %s." % [day_n, _money(_bill_for(day_n)), when])

func _draw_pawn(c: Vector2) -> void:
	var col := c_violet_light
	draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 18), c + Vector2(11, 18), c + Vector2(5, 2), c + Vector2(-5, 2)]), col.darkened(0.1))
	draw_circle(c + Vector2(0, -4), 9.0, col)
	draw_circle(c + Vector2(-3, -7), 3.0, Color(1, 1, 1, 0.35))

func _draw_portfolio() -> void:
	var value := 0.0
	for h in holdings:
		value += h.value()
	var pl := value - _invested()
	_zone(r_port, "Your portfolio", "%d of %d" % [holdings.size(), portfolio_slots])
	var right := r_port.end.x - 26.0
	var pl_s := "Profit %s" % _signed_money(pl)
	_heavy_right(right, r_port.position.y + 42.0, pl_s, 22, c_up_light if pl >= 0.0 else c_down_light)
	_text_right(right - _heavy_w(pl_s, 22) - 28.0, r_port.position.y + 41.0, "Value %s" % _money(value), 20, c_board_ink, true)
	for i in portfolio_slots:
		var cr := _holding_rect(i)
		if i < holdings.size():
			_draw_stock_card(cr, holdings[i].stock, holdings[i], i)
		else:
			_dashed_rect(cr, Color(c_board_line, 0.9))
			if i == 0:
				_text_center(Rect2(cr.position.x, cr.get_center().y - 40.0, cr.size.x, 40.0), "Buy a stock", 22, c_board_ink, true)
				_text_center(Rect2(cr.position.x, cr.get_center().y, cr.size.x, 40.0), "from the market", 22, c_board_ink, true)

func _draw_market() -> void:
	var note := "Click a pack to buy it whole" if phase == Phase.TRADE else "Closed until tomorrow"
	_zone(r_market, "Market", note)
	for i in market_size:
		if i < market.size():
			_draw_stock_card(_market_rect(i), market[i], null, -1)
		else:
			var er := _market_rect(i)
			_dashed_rect(er, Color(c_board_line, 0.9))
			_text_center(er, "Sold", 22, c_board_ink, true)

func _draw_stock_card(r: Rect2, s: Stock, h: Holding, idx: int) -> void:
	# A clean stock card: ticker, shape, a hole for the die, its six outcomes, and its value.
	var trade_hover := phase == Phase.TRADE and drag_die == null and r.has_point(mouse)
	var lift := -8.0 if trade_hover else 0.0
	var cr := Rect2(r.position + Vector2(0, lift), r.size)
	_shadow(r, 20, 8.0 - lift * 0.8)
	var sec_col: Color = sector_colors[s.sector]
	var body := c_stock.lerp(sec_col, 0.10)
	if h != null and h.flash > 0.0 and h.has_last:
		body = body.lerp(c_up_soft if h.last_ret >= 0.0 else c_down_soft, clampf(h.flash * 1.4, 0.0, 1.0))
	var placing := phase == Phase.PLACE
	var glow := Color(0, 0, 0, 0)
	if h != null and drag_die != null and cr.has_point(mouse):
		glow = c_gold
	elif h != null and _armed_target() == "stock":
		glow = c_violet if cr.has_point(mouse) else Color(c_violet_light, 0.5 + 0.3 * sin(clock * 5.0))
	if glow.a > 0.0:
		_panel(cr.grow(6.0), Color(0, 0, 0, 0), 26, glow, 5)
	# The whole card wears its sector: a tinted face, a coloured frame and a header band.
	_panel(cr, body, 20, sec_col, 6)
	var band := Rect2(cr.position, Vector2(cr.size.x, 40.0))
	_panel_corners(band, sec_col, 20, 20, 0, 0)
	var x := cr.position.x + 22.0
	_heavy(Vector2(x, band.position.y + 29.0), s.sector.to_upper(), 18, Color.WHITE)
	_tip(Rect2(band.position, Vector2(band.size.x * 0.5, band.size.y)), "%s sector" % s.sector)
	var rx := cr.end.x - 12.0
	var lvl := int(mania.get(s.sector, 0))
	if lvl > 0:
		var mt := "x%s" % _fmt_mult(_mania_mult(s.sector))
		var mw := _heavy_w(mt, 16) + 40.0
		var mr := Rect2(rx - mw, band.position.y + 7.0, mw, 26.0)
		_panel(mr, Color.WHITE, 13)
		_flame(Vector2(mr.position.x + 14.0, mr.get_center().y + 2.0), 8.5, sec_col.darkened(0.15))
		_heavy_center(Rect2(mr.position.x + 16.0, mr.position.y, mr.size.x - 16.0, mr.size.y), mt, 16, sec_col.darkened(0.35))
		_tip(mr, "%s mania, level %d: gains x%s.\n%d%% chance it crashes at the bell (-%d%% and the mania resets)." % [s.sector, lvl, _fmt_mult(_mania_mult(s.sector)), int(round(_crash_chance(s.sector) * 100.0)), int(round(crash_drop * 100.0))])
		rx = mr.position.x - 8.0
	if _news_hits(s):
		var nc := Vector2(rx - 14.0, band.get_center().y)
		draw_circle(nc, 15.0, Color.WHITE)
		draw_circle(nc, 12.0, c_violet)
		var up := news_value > 0.0
		var tri := PackedVector2Array([nc + Vector2(-6, 4), nc + Vector2(6, 4), nc + Vector2(0, -6)]) if up else PackedVector2Array([nc + Vector2(-6, -4), nc + Vector2(6, -4), nc + Vector2(0, 6)])
		draw_colored_polygon(tri, Color.WHITE)
		_tip(Rect2(nc - Vector2(18, 18), Vector2(36, 36)), "In tomorrow's paper: \"%s\"\n%s." % [news_text, _news_effect()])
	# Ticker, with the stock's type on a chip beside it.
	_heavy(Vector2(x, cr.position.y + 80.0), s.ticker, 30, c_ink)
	var lbl := _arch_label(s).to_upper()
	var chip_bg: Color = arch_chip_colors.get(s.arch, Color("e3e6ee"))
	var chip_ink := Color.WHITE if arch_chip_colors.has(s.arch) else Color("4a5266")
	var cw := _heavy_w(lbl, 16) + 22.0
	var chip := Rect2(cr.end.x - 16.0 - cw, cr.position.y + 53.0, cw, 32.0)
	_panel(chip, chip_bg, 16)
	_heavy_center(chip, lbl, 16, chip_ink)
	_tip(Rect2(cr.position.x, cr.position.y + 44.0, cr.size.x, 46.0), "%s, %s\n%s stock. %s." % [s.ticker, s.name, _arch_label(s), _arch_shape(s)])

	# The hole cut into the card. Dice sit in it.
	var hole := _hole_rect(cr)
	if h != null and (h.double_today or h.safe_today):
		var bx := cr.position.x + 40.0
		if h.double_today:
			_badge(Vector2(bx, hole.get_center().y), "x2", c_gold, "Double Down: today's gain or loss is doubled.")
			bx += 0.0
		if h.safe_today:
			_badge(Vector2(cr.end.x - 40.0, hole.get_center().y), "", c_up, "Safety Net: this stock can't lose money today.")
	_draw_hole(hole, h != null and placing and _die_on(h) == null)

	# Outcomes: one column per die face.
	var d: Die = _die_on(h) if h != null else null
	var face := 0
	var fired := false
	var o: Dictionary = frame_outcomes.get(h, {}) if h != null else {}
	if d != null and d.roll_t <= 0.0 and not o.is_empty():
		face = int(o["eff"])
		fired = bool(o["fired"])
	if h != null and (phase == Phase.CLOSING or phase == Phase.REPORT):
		face = h.last_face if h.has_last else 0
		fired = h.last_fired
	_draw_outcomes(Rect2(cr.position.x + 12.0, cr.position.y + 192.0, cr.size.x - 24.0, 64.0), s, h, face)
	if s.ability != "":
		_draw_ability_band(Rect2(cr.position.x + 12.0, cr.position.y + 262.0, cr.size.x - 24.0, 38.0), s, fired)

	# Bottom line: what it's worth, and what the die will do.
	var by := cr.end.y - 13.0
	if h != null:
		var shown := h.value()
		if phase == Phase.CLOSING:
			shown = lerpf(h.anim_from, h.anim_to, 1.0 - pow(1.0 - anim_t, 3.0))
		_heavy(Vector2(x, by), _money(shown), 26, c_ink)
		if not placing and not (h.has_last and phase != Phase.TRADE):
			_text(Vector2(x + _heavy_w(_money(shown), 26) + 10.0, by), "%d sh" % h.shares, 17, c_muted, true)
		if placing and not o.is_empty():
			var include_news := clair_today or not _news_hits(s)
			var ret: float = o["ret"]
			var pv := _pct(ret)
			_heavy_right(cr.end.x - 20.0, by, pv, 24, _ret_color(ret))
			if not include_news:
				var mc := Vector2(cr.end.x - 32.0 - _heavy_w(pv, 24), by - 9.0)
				draw_circle(mc, 10.0, c_violet)
				var up2 := news_value > 0.0
				draw_colored_polygon(PackedVector2Array([mc + Vector2(-4, 3), mc + Vector2(4, 3), mc + Vector2(0, -4)]) if up2 else PackedVector2Array([mc + Vector2(-4, -3), mc + Vector2(4, -3), mc + Vector2(0, 4)]), Color.WHITE)
				_tip(Rect2(cr.position.x, by - 30.0, cr.size.x, 40.0), "Plus tomorrow's news, which you can't measure yet.")
		elif h.has_last and phase != Phase.TRADE:
			_heavy_right(cr.end.x - 20.0, by, _pct(h.last_ret), 20, _ret_color(h.last_ret))
	else:
		_heavy(Vector2(x, by), _money(_pack_cost(s)), 26, c_ink)
		var owned := _holding_for(s) != null
		var pack_s := ("adds %d sh" % s.pack) if owned else ("%d sh at %s" % [s.pack, _money(s.price)])
		_text(Vector2(x + _heavy_w(_money(_pack_cost(s)), 26) + 8.0, by), pack_s, 15, c_accent if owned else c_muted, true)

	# In the trading phase, one click buys a pack or sells a holding.
	if phase == Phase.TRADE:
		if h != null:
			if trade_hover:
				var sell_s := "Sell %s" % _money(h.value() * (1.0 - _fee()))
				var sw := _heavy_w(sell_s, 21) + 36.0
				var sr := Rect2(hole.get_center() - Vector2(sw * 0.5, 24), Vector2(sw, 48))
				_panel(sr, c_down_chip, 24)
				_heavy_center(sr, sell_s, 21, Color.WHITE)
				_tip(sr, "Sell all %d shares (after the %d%% fee)." % [h.shares, int(round(_fee() * 100.0))])
			_register(r, _sell.bind(h))
		else:
			var can := _can_buy(s)
			if trade_hover:
				var hint := "Buy pack"
				if not can:
					hint = "Portfolio full" if _holding_for(s) == null and holdings.size() >= portfolio_slots else "Too pricey"
				var hw := _heavy_w(hint, 21) + 36.0
				var hr := Rect2(hole.get_center() - Vector2(hw * 0.5, 24), Vector2(hw, 48))
				_panel(hr, c_gold if can else c_board_line, 24)
				_heavy_center(hr, hint, 21, c_ink if can else c_board_text)
			if can:
				_register(r, _buy.bind(s))

func _fmt_mult(m: float) -> String:
	var t := "%.2f" % m
	while t.ends_with("0"):
		t = t.substr(0, t.length() - 1)
	return t.trim_suffix(".")

func _flame(c: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -rad * 1.4), c + Vector2(rad * 0.75, -rad * 0.1), c + Vector2(rad * 0.6, rad * 0.7),
		c + Vector2(0, rad), c + Vector2(-rad * 0.6, rad * 0.7), c + Vector2(-rad * 0.75, -rad * 0.1), c + Vector2(-rad * 0.15, -rad * 0.6)])
	draw_colored_polygon(pts, col)

func _draw_ability_band(r: Rect2, st: Stock, fired: bool) -> void:
	# The stock's dice pattern and the ability it unlocks. It glows gold when the pattern is met.
	var bg := Color("efeafc")
	var ink := c_violet_dark
	var border := Color(0, 0, 0, 0)
	if fired:
		bg = Color("fcecc4")
		ink = c_ink
		border = c_gold
	_panel(r, bg, 10, border, 2 if fired else 0)
	var lbl := _pattern_label(st)
	var pw := maxf(_heavy_w(lbl, 15) + 18.0, 32.0)
	var pr := Rect2(r.position.x + 5.0, r.position.y + 5.0, pw, r.size.y - 10.0)
	_panel(pr, c_gold_dark if fired else c_ink, 8)
	_heavy_center(pr, lbl, 15, Color.WHITE)
	var t := _ability_text(st)
	var tr := Rect2(pr.end.x + 4.0, r.position.y, r.end.x - pr.end.x - 8.0, r.size.y)
	var size := 17
	while size > 12 and font_bold.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > tr.size.x:
		size -= 1
	_text_center(tr, t, size, ink, true)
	var state := "\nActive today." if fired and phase == Phase.PLACE else ""
	_tip(r, "%s\n%s%s" % [ability_defs[st.ability]["name"], _ability_desc(st), state])

func _draw_hole(r: Rect2, inviting: bool) -> void:
	# A die-shaped hole punched through the card, showing the board beneath.
	_panel(r.grow(3.0), c_stock.darkened(0.07), 20)
	_panel(r, c_board, 17)
	_vgradient(Rect2(r.position.x + 7.0, r.position.y + 2.0, r.size.x - 14.0, 16.0), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.0))
	draw_line(Vector2(r.position.x + 16.0, r.end.y - 2.0), Vector2(r.end.x - 16.0, r.end.y - 2.0), Color(1, 1, 1, 0.12), 2.0)
	if inviting:
		var a := 0.35 + 0.25 * sin(clock * 4.0)
		_panel(r.grow(-10.0), Color(0, 0, 0, 0), 14, Color(c_gold, a), 3)

func _draw_outcomes(r: Rect2, s: Stock, h: Holding, chosen: int) -> void:
	var cw := r.size.x / 6.0
	for i in 6:
		var col_r := Rect2(r.position.x + i * cw, r.position.y, cw, r.size.y)
		var v: float = s.faces[i]
		var p := int(round(v * 100.0))
		var tile := Rect2(col_r.position.x + 2.0, col_r.position.y + 26.0, cw - 4.0, 34.0)
		var tint := c_up_soft if p > 0 else (c_down_soft if p < 0 else Color("eceef2"))
		var ink := c_up if p > 0 else (c_down if p < 0 else c_muted)
		if chosen == i + 1:
			tint = c_gold
			ink = c_ink
			_panel(Rect2(col_r.position.x, col_r.position.y - 2.0, cw, col_r.size.y + 4.0), Color(c_gold, 0.25), 10)
		_text_center(Rect2(col_r.position.x, col_r.position.y, cw, 24.0), str(i + 1), 16, c_ink if chosen == i + 1 else c_muted, true)
		_panel(tile, tint, 8)
		_heavy_center(tile, str(absi(p)) if p > 0 else str(p), 18, ink)
		_tip(col_r, "Roll a %d: %s" % [i + 1, _face_pct(v)])

func _draw_resources() -> void:
	var r := r_res
	var w := (r.size.x - 3.0 * 16.0) / 4.0
	var items := ["Cash", "Net worth", "Insight", "Mania"]
	for i in 4:
		var pr := Rect2(r.position.x + i * (w + 16.0), r.position.y, w, r.size.y)
		_panel(pr, Color(c_board_dark, 0.55), 20, Color(c_board_line, 0.9), 2)
		var label: String = items[i]
		_text(pr.position + Vector2(20.0, 34.0), label, 19, c_board_ink, true)
		match label:
			"Cash":
				_heavy(pr.position + Vector2(20.0, 84.0), _money(cash), 38, c_stock)
			"Net worth":
				_heavy(pr.position + Vector2(20.0, 84.0), _money(_net_worth()), 38, c_stock)
			"Insight":
				_gold_coin_icon(pr.position + Vector2(36.0, 70.0), 16.0)
				_heavy(pr.position + Vector2(64.0, 84.0), str(ip), 38, c_gold)
				_tip(pr, "Insight buys cards from the fortune shop.\nYou earn 1 a day, plus 1 for each stock that closes up (up to 3).")
			"Mania":
				var mtip := "Mania boosts a sector's gains; each level also adds a chance of a crash."
				for k in sector_names.size():
					var sec := sector_names[k]
					var c := pr.position + Vector2(34.0 + k * 48.0, 66.0)
					var lv := int(mania.get(sec, 0))
					draw_circle(c, 11.0, sector_colors[sec] if lv > 0 else Color(sector_colors[sec], 0.35))
					for n in mania_max:
						var pr2 := Rect2(c + Vector2(-11.0 + n * 6.0, 18.0), Vector2(4.0, 8.0))
						draw_rect(pr2, c_gold if n < lv else Color(c_board_ink, 0.4))
					if lv > 0:
						mtip += "\n%s: level %d, gains x%s, crash %d%%" % [sec, lv, _fmt_mult(_mania_mult(sec)), int(round(_crash_chance(sec) * 100.0))]
				_tip(pr, mtip)

func _draw_event_slot() -> void:
	var r := r_event
	if phase == Phase.NEWS:
		_dashed_rect(r, Color(c_board_line, 0.9))
		_text_center(r, "Tomorrow's paper", 22, c_board_ink, true)
		return
	_draw_paper_card(r, false)
	_tip(r, "Tomorrow's headline, seen today. %s.\nStocks it affects carry a violet arrow." % _news_effect())

func _draw_paper_card(r: Rect2, big: bool) -> void:
	_shadow(r, 16)
	_panel(r, c_paper, 16)
	var pad := 44.0 if big else 24.0
	var x := r.position.x + pad
	var right := r.end.x - pad
	var mast_size := 64 if big else 22
	var y := r.position.y + (96.0 if big else 38.0)
	_heavy(Vector2(x, y), "The Daily Ticker", mast_size, c_newsprint)
	_text_right(right, y - (8.0 if big else 2.0), "Tomorrow's edition", 22 if big else 16, c_violet, true)
	draw_line(Vector2(x, y + (22.0 if big else 10.0)), Vector2(right, y + (22.0 if big else 10.0)), c_newsprint, 3.0 if big else 2.0)
	var head_size := 58 if big else 28
	var hy := y + (100.0 if big else 50.0)
	var w := right - x
	draw_multiline_string(font_heavy, Vector2(x, hy), news_text, HORIZONTAL_ALIGNMENT_LEFT, w, head_size, 2, c_newsprint)
	var lines := 1 if font_heavy.get_string_size(news_text, HORIZONTAL_ALIGNMENT_LEFT, -1, head_size).x <= w else 2
	var ey := hy + (lines - 1) * head_size * 1.15 + (60.0 if big else 34.0)
	var ecol := c_newsprint.lerp(c_muted, 0.4)
	if news_kind != "":
		ecol = c_up if news_value > 0.0 else c_down
	if big or lines == 1:
		_heavy(Vector2(x, ey), _news_effect(), 30 if big else 19, ecol)
	if big:
		var hits: Array[String] = []
		for s in market:
			if _news_hits(s):
				hits.append(s.ticker)
		for h in holdings:
			if _news_hits(h.stock) and not hits.has(h.stock.ticker):
				hits.append("%s (yours)" % h.stock.ticker)
		var story := "In the story: %s" % ", ".join(hits) if not hits.is_empty() else "No listed stocks are in tomorrow's story."
		_text(Vector2(x, ey + 56.0), story, 24, c_newsprint, true)

func _draw_tray() -> void:
	# The dice tray: a recessed well in the board, with the gold coin that drives the day.
	var r := r_felt
	_panel(r.grow(8.0), Color(c_board_line, 0.9), 34)
	_panel(r, c_well, 28)
	_vgradient(Rect2(r.position.x + 14.0, r.position.y + 2.0, r.size.x - 28.0, 34.0), Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.0))
	_heavy(r.position + Vector2(26.0, 44.0), "Dice tray", 26, Color(c_board_text, 0.7))
	var live := phase == Phase.PLACE
	if live:
		_pill(Rect2(r.end.x - 24.0 - 180.0, r.position.y + 18.0, 180.0, 46.0), "Auto-place", _auto_place, true, "light", 20)
		_pill(Rect2(r.end.x - 24.0 - 180.0 - 14.0 - 180.0, r.position.y + 18.0, 180.0, 46.0), "Return all", _return_all, true, "light", 20)
	var unused := 0
	for d in dice:
		if d.holding == null:
			unused += 1
	var msg := ""
	if phase == Phase.TRADE:
		msg = "Buy stocks, then roll one die for each" if not holdings.is_empty() else "Buy a stock first"
	elif phase == Phase.PLACE and unused == 0:
		msg = "Every die is placed"
	elif phase == Phase.PLACE and _all_placed():
		msg = "The spare die can stay here"
	elif phase == Phase.PLACE:
		msg = "Drag each die into a card's hole"
	if msg != "":
		_text_center(Rect2(r.position.x, r.end.y - 70.0, r.size.x - 220.0, 40.0), msg, 22, Color(c_board_text, 0.55), true)
	var cc := Vector2(r.end.x - 108.0, r.end.y - 106.0)
	match phase:
		Phase.TRADE:
			_coin(cc, 80.0, "Roll" if not holdings.is_empty() else "Ring\nbell", _primary_action, true)
		Phase.PLACE:
			var left := 0
			for h in holdings:
				if _die_on(h) == null:
					left += 1
			_coin(cc, 80.0, "Ring\nbell" if left == 0 else "%d to\nplace" % left, _primary_action, left == 0)
		_:
			_coin(cc, 80.0, "...", _primary_action, false)

func _badge(c: Vector2, label: String, col: Color, tip: String) -> void:
	draw_circle(c + Vector2(0, 3), 22.0, col.darkened(0.35))
	draw_circle(c, 22.0, col)
	if label != "":
		_heavy_center(Rect2(c - Vector2(22, 22), Vector2(44, 44)), label, 20, c_ink if col == c_gold else Color.WHITE)
	else:
		_shield(c, 11.0, Color.WHITE)
	_tip(Rect2(c - Vector2(24, 24), Vector2(48, 48)), tip)

func _shield(c: Vector2, rad: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(-rad, -rad), c + Vector2(rad, -rad), c + Vector2(rad, rad * 0.2),
		c + Vector2(0, rad * 1.2), c + Vector2(-rad, rad * 0.2)]), col)

func _draw_hand() -> void:
	# Your hand of fortune cards. Click one to play it.
	var r := r_hand
	_heavy(r.position + Vector2(0.0, 34.0), "Fortune cards", 26, c_board_text)
	var note := "Click a card to play it"
	if hand.is_empty():
		note = "Buy cards from the shop with Insight"
	_text(Vector2(r.position.x + _heavy_w("Fortune cards", 26) + 16.0, r.position.y + 33.0), note, 20, c_board_ink, true)
	var top := r.position.y + 58.0
	var gap := 18.0
	var cw := (r.size.x - gap * (hand_size - 1)) / hand_size
	var ch := minf(330.0, r.end.y - top)
	for i in hand_size:
		var base := Rect2(r.position.x + i * (cw + gap), top, cw, ch)
		if i >= hand.size():
			_dashed_rect(base, Color(c_board_line, 0.8))
			continue
		var id := hand[i]
		var usable := _card_usable(id) and ui_live
		var armed := armed_card == i
		var hovered := usable and base.has_point(mouse)
		var lift := -18.0 if armed else (-10.0 if hovered else 0.0)
		var cr := Rect2(base.position + Vector2(0, lift), base.size)
		_draw_fortune_card(cr, id, usable or armed, armed, base, lift)
		if usable or armed:
			_register(base, _play_card.bind(i))
		var d := _card_def(id)
		var when := _when_text(id)
		_tip(base, "%s\n%s\n%s" % [d["name"], d["desc"], when if usable else "Can't be played right now. " + when])

func _when_text(id: String) -> String:
	var d := _card_def(id)
	match d["when"]:
		"roll":
			return "Play after you roll."
		"trade":
			return "Play while the market is open."
	return "Play any time during the day."

func _draw_fortune_card(cr: Rect2, id: String, bright: bool, armed: bool, shadow_base: Rect2, lift: float) -> void:
	# Fortune cards are deep violet with a thin gold frame, like a tarot deck.
	var d := _card_def(id)
	_shadow(shadow_base, 20, 8.0 - lift * 0.8)
	var is_mania: bool = d.get("type", "") == "mania"
	var base_col: Color = (sector_colors[d["sector"]] as Color).darkened(0.45) if is_mania else c_violet_card
	var face := base_col if bright else base_col.lerp(c_board, 0.5)
	_panel(cr, face, 20, c_gold if armed else Color(c_violet_light, 0.3), 4 if armed else 2)
	_panel(cr.grow(-10.0), Color(0, 0, 0, 0), 14, Color(c_gold, 0.45 if bright else 0.2), 2)
	var a := 1.0 if bright else 0.45
	var big := cr.size.x > 240.0 and cr.size.y > 400.0
	_text_center(Rect2(cr.position.x, cr.position.y + 12.0, cr.size.x, 30.0), "Mania" if is_mania else "Fortune", 18 if big else 15, Color(c_gold, 0.85 * a), true)
	var icon_c := Vector2(cr.get_center().x, cr.position.y + cr.size.y * 0.3)
	_draw_fortune_icon(id, icon_c, (1.4 if big else 1.0), a)
	var name_size := 30 if big else 23
	var ny := cr.position.y + cr.size.y * 0.55
	draw_multiline_string(font_heavy, Vector2(cr.position.x + 22.0, ny), d["name"], HORIZONTAL_ALIGNMENT_CENTER, cr.size.x - 44.0, name_size, 2, Color(1, 1, 1, a))
	var name_lines := 1 if font_heavy.get_string_size(d["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x <= cr.size.x - 44.0 else 2
	var desc_y := ny + name_lines * name_size * 1.1 + (14.0 if big else 6.0)
	var desc: String = d["desc"]
	if id == "windfall":
		desc = "Gain %s now." % _money(_windfall_amount())
	_wrap(Vector2(cr.position.x + 22.0, desc_y), desc, cr.size.x - 44.0, 21 if big else 18, Color(Color("d6ccf5"), a), true, 4, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_fortune_icon(id: String, c: Vector2, k: float, a: float) -> void:
	var gold := Color(c_gold, a)
	var ivory := Color(c_ivory, a)
	match id:
		"nudge_up", "nudge_down", "flip", "reroll", "destiny":
			var face := 3
			if id == "flip":
				face = 1
			elif id == "destiny":
				face = 6
			_draw_die_body(c - Vector2(14.0 * k, 0), 56.0 * k, face, ivory, Color(c_ink, a))
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
				"destiny":
					_star(m, 16.0 * k, gold)
		"extra_die":
			_draw_die_body(c + Vector2(-22, 8) * k, 50.0 * k, 2, ivory, Color(c_ink, a))
			_draw_die_body(c + Vector2(20, -8) * k, 50.0 * k, 5, ivory, Color(c_ink, a))
		"double_down":
			draw_circle(c, 40.0 * k, gold)
			_heavy_center(Rect2(c - Vector2(40, 40) * k, Vector2(80, 80) * k), "x2", int(36 * k), Color(c_ink, a))
		"safety_net":
			_shield(c, 30.0 * k, Color(c_up_light, a))
		"refresh":
			for n in 3:
				_panel(Rect2(c + Vector2(-34 + n * 18, -26 + n * 4) * k, Vector2(34, 48) * k), Color(ivory, a), int(6 * k), Color(c_violet_card, a), 2)
			draw_arc(c + Vector2(0, 4) * k, 46.0 * k, -0.4, PI * 1.2, 24, gold, 4.0 * k, true)
		"clairvoyance":
			var pts := PackedVector2Array()
			for n in 33:
				var t := TAU * n / 32.0
				pts.append(c + Vector2(cos(t) * 46.0, sin(t) * 22.0 * absf(sin(t))) * k)
			draw_polyline(pts, gold, 4.0 * k, true)
			draw_circle(c, 15.0 * k, gold)
			draw_circle(c, 6.0 * k, Color(c_violet_card, a))
		"windfall":
			for n in 3:
				_gold_coin_icon(c + Vector2(-20 + n * 20, 10 - n * 10) * k, 22.0 * k)
		_ when id.begins_with("mania_"):
			_flame(c + Vector2(0, 4) * k, 34.0 * k, gold)
			_flame(c + Vector2(0, 14) * k, 18.0 * k, Color(ivory, a))
		"rent_cut":
			_panel(Rect2(c - Vector2(34, 26) * k, Vector2(68, 52) * k), ivory, int(8 * k))
			_heavy_center(Rect2(c - Vector2(34, 26) * k, Vector2(68, 52) * k), "1/2", int(28 * k), Color(c_down, a))

func _star(c: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for n in 10:
		var t := -PI * 0.5 + TAU * n / 10.0
		var rr := rad if n % 2 == 0 else rad * 0.45
		pts.append(c + Vector2(cos(t), sin(t)) * rr)
	draw_colored_polygon(pts, col)

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
	var size := 21
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
	draw_rect(Rect2(Vector2(-400, -400), view_size + Vector2(800, 800)), Color(0.03, 0.04, 0.10, minf(0.94, 0.8 * amount)))

func _ease_out_bounce(t: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75
	if t < 1.0 / d1:
		return n1 * t * t
	elif t < 2.0 / d1:
		t -= 1.5 / d1
		return n1 * t * t + 0.75
	elif t < 2.5 / d1:
		t -= 2.25 / d1
		return n1 * t * t + 0.9375
	t -= 2.625 / d1
	return n1 * t * t + 0.984375

# ---------------------------------------------------------------- overlays
func _draw_event_reveal() -> void:
	# Each morning an event card is drawn from the deck and flipped: tomorrow's paper.
	_dim(clampf(news_t * 3.0, 0.0, 1.0))
	var size := Vector2(1180.0, 520.0)
	var center := view_size * 0.5 + Vector2(0.0, -30.0)
	var grow := 0.85 + 0.15 * clampf(news_t * 2.5, 0.0, 1.0)
	var flip := clampf((news_t - 0.25) / 0.6, 0.0, 1.0)
	var sx := absf(cos(flip * PI))
	var showing_front := flip >= 0.5
	draw_set_transform_matrix(_screen_xform() * Transform2D(0.0, Vector2(maxf(sx, 0.02) * grow, grow), 0.0, center))
	var r := Rect2(-size * 0.5, size)
	if showing_front:
		_draw_paper_card(r, true)
	else:
		_shadow(r, 24, 12.0)
		_panel(r, c_violet_card, 24, c_gold, 4)
		_panel(r.grow(-22.0), Color(0, 0, 0, 0), 16, Color(c_gold, 0.5), 2)
		var eye := Vector2.ZERO
		var pts := PackedVector2Array()
		for k in 33:
			var a := TAU * k / 32.0
			pts.append(eye + Vector2(cos(a) * 120.0, sin(a) * 56.0 * absf(sin(a)) * 1.0 + sin(a) * 4.0))
		draw_polyline(pts, c_gold, 6.0, true)
		draw_circle(eye, 36.0, c_gold)
		draw_circle(eye, 16.0, c_violet_card)
		_heavy_center(Rect2(r.position.x, r.end.y - 110.0, r.size.x, 60.0), "Tomorrow", 40, c_gold)
	draw_set_transform_matrix(_screen_xform())
	if news_t >= 1.0:
		var full := Rect2(center - size * 0.5, size)
		_register(full, _dismiss_news)
		_text_center(Rect2(0.0, full.end.y + 30.0, view_size.x, 40.0), "Click the paper to start trading", 24, c_board_text, true)

func _draw_report() -> void:
	_dim()
	var rows: Array[Dictionary] = report.get("rows", [] as Array[Dictionary])
	var forced: Array[String] = report.get("forced", [] as Array[String])
	var lines: Array = []
	var dividends: float = report.get("dividends", 0.0)
	var interest: float = report.get("interest", 0.0)
	if dividends > 0.0:
		lines.append(["Dividends", _signed_money(dividends), c_up])
	if interest > 0.0:
		lines.append(["Savings interest", _signed_money(interest), c_up])
	var perk_cash: float = report.get("perk_cash", 0.0)
	if perk_cash > 0.0:
		lines.append(["Perk payouts", _signed_money(perk_cash), c_up])
	var relief: float = report.get("bill_relief", 0.0)
	if relief > 0.0:
		lines.append(["Bill covered by perks", _signed_money(relief), c_up])
	var drawn: Array[String] = report.get("perk_cards", [] as Array[String])
	if not drawn.is_empty():
		lines.append(["Cards drawn", ", ".join(drawn), c_violet])
	var crashes: Array[String] = report.get("crashes", [] as Array[String])
	for sec in crashes:
		lines.append(["%s mania burst" % sec, "-%d%% on %s stocks" % [int(round(crash_drop * 100.0)), sec], c_down])
	lines.append(["Bill paid", "-" + _money(report.get("bill", 0.0)), c_down])
	lines.append(["Insight earned", "+%d" % int(report.get("ip", 0)), c_gold_dark])

	var w := 1040.0
	var row_h := 54.0
	var h := 190.0 + maxi(1, rows.size()) * row_h + 30.0 + lines.size() * 46.0 + forced.size() * 32.0 + 110.0 + 120.0
	var r := Rect2((view_size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_shadow(r, 28, 14.0)
	_panel(r, c_stock, 28)
	var x := r.position.x + 56.0
	var right := r.end.x - 56.0
	var y := r.position.y + 82.0
	_heavy(Vector2(x, y), "Day %d closes" % day, 48, c_ink)
	y += 44.0
	_text(Vector2(x, y), report.get("news", ""), 22, c_muted, true)
	y += 30.0
	if rows.is_empty():
		y += 50.0
		_text(Vector2(x, y), "You held nothing today.", 24, c_muted, true)
	for row in rows:
		y += row_h
		var ret: float = row["ret"]
		var delta: float = row["delta"]
		var col := _ret_color(ret)
		var face: int = row["face"]
		_draw_die_body(Vector2(x + 22.0, y - 18.0), 40.0, face, c_ivory, c_ink, Color("d9dde6"))
		_heavy(Vector2(x + 62.0, y - 6.0), row["ticker"], 28, c_ink)
		var perk_name: String = row.get("perk", "")
		if perk_name != "":
			_star(Vector2(x + 192.0, y - 14.0), 9.0, c_gold_dark)
			_text(Vector2(x + 208.0, y - 7.0), perk_name, 21, c_gold_dark, true)
		else:
			_text(Vector2(x + 180.0, y - 7.0), row["name"], 21, c_muted, true)
		var ret_s := "Delisted" if bool(row["wiped"]) else _pct(ret)
		_heavy_right(right - 220.0, y - 6.0, ret_s, 26, col)
		_heavy_right(right, y - 6.0, _signed_money(delta), 26, col)
	y += 30.0
	draw_line(Vector2(x, y), Vector2(right, y), Color("e4e7ee"), 2.0)
	for ln in lines:
		y += 46.0
		_text(Vector2(x, y - 8.0), ln[0], 24, c_ink, true)
		_heavy_right(right, y - 8.0, ln[1], 26, ln[2])
	for fl in forced:
		y += 32.0
		_text(Vector2(x + 18.0, y - 6.0), fl, 20, c_down, true)
	y += 74.0
	_heavy(Vector2(x, y), "Net worth", 32, c_ink)
	_heavy_right(right, y, _money(report.get("worth", 0.0)), 46, c_ink)
	var last := bankrupt or day >= total_days
	_pill(Rect2(right - 340.0, r.end.y - 52.0 - 74.0, 340.0, 74.0), "See how it went" if last else "Start day %d" % (day + 1), _continue_from_report, true, "gold", 28)

func _draw_shop() -> void:
	# The fortune shop: a row of cards for sale for Insight, restocked every morning.
	var open := phase == Phase.TRADE or phase == Phase.PLACE
	var note := "Spend Insight on cards" if open else "Opens with the market"
	if open and hand.size() >= hand_size:
		note = "Your hand is full"
	_zone(r_shop, "Fortune shop", note)
	var coin_x := r_shop.end.x - 26.0
	var ip_s := "%d Insight" % ip
	_heavy_right(coin_x, r_shop.position.y + 42.0, ip_s, 24, c_gold)
	_gold_coin_icon(Vector2(coin_x - _heavy_w(ip_s, 24) - 22.0, r_shop.position.y + 34.0), 14.0)
	var gap := 22.0
	var btn_w := 230.0
	var x0 := r_shop.position.x + 24.0
	var top := r_shop.position.y + 60.0
	var ch := r_shop.end.y - 16.0 - top
	var n := shop_size
	var cw := (r_shop.size.x - 48.0 - btn_w - gap * n) / n
	for i in n:
		var base := Rect2(x0 + i * (cw + gap), top, cw, ch)
		if i >= shop.size() or shop_sold[i]:
			_dashed_rect(base, Color(c_board_line, 0.9))
			_text_center(base, "Sold" if i < shop.size() else "", 22, c_board_ink, true)
			continue
		var id := shop[i]
		var price := _card_price(id)
		var can := open and ip >= price and hand.size() < hand_size
		var hovered := open and base.has_point(mouse)
		var lift := -8.0 if hovered and can else 0.0
		var cr := Rect2(base.position + Vector2(0, lift), base.size)
		_draw_fortune_card(cr, id, can, false, base, lift)
		var pc := Vector2(cr.end.x - 30.0, cr.position.y + 30.0)
		_gold_coin_icon(pc, 20.0)
		_heavy_center(Rect2(pc - Vector2(20, 20), Vector2(40, 40)), str(price), 21, c_ink)
		if hovered:
			var hint := "Buy"
			if hand.size() >= hand_size:
				hint = "Hand full"
			elif ip < price:
				hint = "Need %d more" % (price - ip)
			var hw := _heavy_w(hint, 21) + 36.0
			var hr := Rect2(Vector2(cr.get_center().x - hw * 0.5, cr.position.y + cr.size.y * 0.3 - 24.0), Vector2(hw, 48.0))
			_panel(hr, c_gold if can else c_board_line, 24)
			_heavy_center(hr, hint, 21, c_ink if can else c_board_text)
		_tip(base, "%s, %d Insight\n%s\n%s" % [_card_def(id)["name"], price, _card_def(id)["desc"], _when_text(id)])
		if can:
			_register(base, _buy_card.bind(i))
	var br := Rect2(r_shop.end.x - 24.0 - btn_w, top + ch * 0.5 - 38.0, btn_w, 76.0)
	_pill(br, "Reshuffle (%d)" % reshuffle_cost, _reshuffle_shop, open and ip >= reshuffle_cost, "light", 24)
	_tip(br, "Spend %d Insight to restock the shop with new cards." % reshuffle_cost)

func _draw_gameover() -> void:
	_dim()
	var w := 1040.0
	var h := 700.0
	var r := Rect2((view_size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_shadow(r, 28, 14.0)
	_panel(r, c_stock, 28)
	var x := r.position.x + 64.0
	var right := r.end.x - 64.0
	var won := not bankrupt
	var title := "You saw all %d days coming" % total_days if won else "The visions fade on day %d" % day
	_heavy(Vector2(x, r.position.y + 100.0), title, 50, c_up if won else c_down)
	var sub := "The last bell rings and the bills are paid." if won else "The bill came due with nothing left to sell."
	_text(Vector2(x, r.position.y + 148.0), sub, 24, c_muted, true)
	var stats := [
		["Final net worth", _money(_net_worth())],
		["Peak net worth", _money(peak_worth)],
		["Best call", best_call if best_call != "" else "None"],
		["Fortune cards played", str(cards_played)],
		["Days traded", "%d of %d" % [day, total_days]],
	]
	var y := r.position.y + 236.0
	for st in stats:
		_text(Vector2(x, y), st[0], 26, c_muted, true)
		_heavy_right(right, y, st[1], 30, c_ink)
		y += 62.0
	_pill(Rect2(right - 320.0, r.end.y - 52.0 - 76.0, 320.0, 76.0), "Play again", _new_run, true, "gold", 30)
