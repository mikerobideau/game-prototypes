class_name HoldingsCard
extends Resource

const SECTORS := {"Finance": "cash", "Services": "labor", "Industry": "equipment", "Tech": "intel", "Consumer": "advertising"}

@export var id: String = ""
@export var name: String = ""
@export_enum("Finance", "Services", "Industry", "Tech", "Consumer") var sector: String = "Finance"
@export_range(0, 10) var value: int = 1
@export_enum("common", "uncommon", "rare") var rarity: String = "common"

@export_group("Price")
@export var custom_cost: bool = false
@export var cost_cash: int = 0
@export var cost_labor: int = 0
@export var cost_equipment: int = 0
@export var cost_intel: int = 0
@export var cost_advertising: int = 0

@export_group("Dice")
@export_enum("none", "odd", "even", "low", "high", "exact", "at_least", "at_most", "any", "pair", "sum_at_least", "sum_exactly", "run") var pattern: String = "any"
@export var pattern_param: int = 0
@export var chain_left: bool = false
@export var copy_left: bool = false

@export_group("Text")
@export_multiline var text: String = ""
@export_multiline var short_text: String = ""
@export var tags: PackedStringArray = PackedStringArray()

@export_group("Abilities")
@export var abilities: Array[HoldingsAbility] = []

@export_group("Passive rules")
@export var prevent_distress: bool = false
@export var prevent_distress_brand: int = 0
@export var repeat_same_die: bool = false
@export var adjacent_any_die: bool = false
@export_enum("none", "Finance", "Services", "Industry", "Tech", "Consumer") var adjacent_value_sector: String = "none"
@export var adjacent_value_amount: int = 0
@export_enum("none", "Finance", "Services", "Industry", "Tech", "Consumer") var adjacent_die_plus_sector: String = "none"
@export var adjacent_die_plus_amount: int = 0

@export_group("Fallback art")
@export var art: Dictionary = {}

func to_dict() -> Dictionary:
	var c := {"name": name, "type": SECTORS[sector], "value": value, "rarity": rarity, "text": text}
	var p := {}
	if pattern != "none":
		p["kind"] = pattern
		if pattern in ["exact", "at_least", "at_most", "sum_at_least", "sum_exactly"]:
			p["param"] = pattern_param
	c["pattern"] = p
	if short_text != "":
		c["short"] = short_text
	if not tags.is_empty():
		c["tags"] = Array(tags)
	if chain_left:
		c["chain_left"] = true
	if copy_left:
		c["copy_left"] = true
	var effects: Array = []
	var triggers := {}
	for a in abilities:
		if a == null:
			continue
		if a.when == "operate":
			effects.append(a.to_dict())
		else:
			if not triggers.has(a.when):
				triggers[a.when] = []
			triggers[a.when].append(a.to_dict())
	c["effects"] = effects
	if not triggers.is_empty():
		c["triggers"] = triggers
	var pas := {}
	if prevent_distress:
		pas["prevent_distress"] = {"vp": prevent_distress_brand}
	if repeat_same_die:
		pas["repeat_same_die"] = true
	if adjacent_any_die:
		pas["adjacent_any_die"] = true
	if adjacent_value_sector != "none":
		pas["adjacent_value"] = {"type": SECTORS[adjacent_value_sector], "amount": adjacent_value_amount}
	if adjacent_die_plus_sector != "none":
		pas["adjacent_die_plus"] = {"type": SECTORS[adjacent_die_plus_sector], "amount": adjacent_die_plus_amount}
	if not pas.is_empty():
		c["passive"] = pas
	if custom_cost:
		var cost := {}
		for r in ["cash", "labor", "equipment", "intel", "advertising"]:
			if int(get("cost_" + r)) > 0:
				cost[r] = int(get("cost_" + r))
		c["cost"] = cost
	c["art"] = art.duplicate(true)
	return c
