class_name HoldingsData
extends RefCounted

const TYPES := ["cash", "labor", "equipment", "intel", "advertising"]
const TYPE_NAMES := {"cash": "Finance", "labor": "Services", "equipment": "Industry", "intel": "Tech", "advertising": "Consumer"}
const RES_NAMES := {"cash": "Cash", "labor": "Labor", "equipment": "Equipment", "intel": "Intelligence", "advertising": "Advertising"}
const TYPE_COLORS := {"cash": "4f8a5b", "labor": "4a7fb0", "equipment": "8a6d4b", "intel": "7a63b8", "advertising": "d0607a"}

const QUARTERS_PER_YEAR := 4
const YEAR_TARGETS := [20, 45, 80, 120, 165, 215, 270]

const STARTING_RESOURCES := {"cash": 4, "labor": 2, "equipment": 2, "intel": 2, "advertising": 2}

const COST_EXTRA := 1
const GATE_VALUE := 5
const GATE_RES := "equipment"
const COST_FILLER := {"cash": "labor"}
const DEFAULT_FILLER := "cash"

const LOCKED_LOTS := 3
const LOCK_PAY := 3
const STARTING_BOARD: Array[String] = []

const TUTORIAL_SHEET := "blank_ledger"
const TUTORIAL_SEED := 20261027
const TUTORIAL_EVENT := "steady_market"
const TUTORIAL_MARKET: Array[String] = ["lemonade_stand", "consulting_firm", "cloud_provider", "temp_agency"]
const TUTORIAL_DICE: Array[int] = [5, 2, 6, 1]
const TUTORIAL_LOT := 4

const EVENT_TIERS := [
	{"until": 8, "tiers": ["mild"]},
	{"until": 16, "tiers": ["mild", "moderate"]},
	{"until": 999, "tiers": ["moderate", "severe"]},
]

const PATTERNS := {
	"odd": {"dice": 1, "label": "Odd", "short": "Odd", "rule": "1, 3 or 5"},
	"even": {"dice": 1, "label": "Even", "short": "Even", "rule": "2, 4 or 6"},
	"low": {"dice": 1, "label": "Low", "short": "1-3", "rule": "1-3"},
	"high": {"dice": 1, "label": "High", "short": "4-6", "rule": "4-6"},
	"exact": {"dice": 1, "label": "Exactly %d", "short": "%d", "rule": "equals %d"},
	"at_least": {"dice": 1, "label": "%d+", "short": "%d-6", "rule": "%d or higher"},
	"at_most": {"dice": 1, "label": "%d or less", "short": "1-%d", "rule": "%d or lower"},
	"any": {"dice": 1, "label": "Any", "short": "Any", "rule": "any die"},
	"pair": {"dice": 2, "label": "Pair", "short": "Pair", "rule": "two equal dice"},
	"sum_at_least": {"dice": 2, "label": "Sum %d+", "short": "Sum %d+", "rule": "two dice total %d+"},
	"sum_exactly": {"dice": 2, "label": "Sum = %d", "short": "Sum %d", "rule": "two dice total exactly %d"},
	"run": {"dice": 2, "label": "Run", "short": "Run", "rule": "two consecutive values"},
}

const RARITY_COPIES := {"common": 3, "uncommon": 2, "rare": 1}
const RARITY_COLORS := {"uncommon": "4a7fb0", "rare": "d9a13b"}

static var CARDS := {}

static var MEETING_OFFERS := {}
static var EDITIONS := {}
static var EDITION_OFFERS := {}

const POCKET_MODS := {
	"gold": {"name": "Gold", "color": "d9a13b"},
	"express": {"name": "Express", "color": "4a90d9"},
}

static var EVENTS := {}
static var SHEETS := {}
static var TUTORIAL: Array[Dictionary] = []

const DATA_DIR := "res://prototypes/holdings/data/"
static var loaded := false

static func load_tables() -> void:
	if loaded:
		return
	loaded = true
	for r in _resources("cards"):
		CARDS[_id(r)] = r.to_dict()
	for r in _resources("events"):
		EVENTS[_id(r)] = r.to_dict()
	for r in _resources("offers"):
		var o: Dictionary = r.to_dict()
		if o.has("edition"):
			EDITION_OFFERS[_id(r)] = o
		else:
			MEETING_OFFERS[_id(r)] = o
	for r in _resources("editions"):
		EDITIONS[_id(r)] = r.to_dict()
	var sheets: Array = []
	for r in _resources("sheets"):
		sheets.append([r.to_dict(), _id(r)])
	sheets.sort_custom(func(x, y): return int(x[0]["order"]) < int(y[0]["order"]))
	for pair in sheets:
		SHEETS[pair[1]] = pair[0]
	for r in _resources("tutorial"):
		TUTORIAL.append(r.to_dict())

static func _id(r: Resource) -> String:
	var id := String(r.get("id"))
	if id == "":
		id = r.resource_path.get_file().get_basename()
	return id

static func _resources(folder: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open(DATA_DIR + folder)
	if dir == null:
		push_error("Holdings: missing data folder %s" % (DATA_DIR + folder))
		return out
	var files: Array[String] = []
	for f in dir.get_files():
		var name := f.trim_suffix(".remap")
		if name.ends_with(".tres") or name.ends_with(".res"):
			files.append(name)
	files.sort()
	for f in files:
		var r := load(DATA_DIR + folder + "/" + f)
		if r == null or not r.has_method("to_dict"):
			push_error("Holdings: %s/%s is not a Holdings data resource" % [folder, f])
			continue
		out.append(r)
	return out
