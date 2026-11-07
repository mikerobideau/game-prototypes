class_name HoldingsAbility
extends Resource

const SECTORS := {"Finance": "cash", "Services": "labor", "Industry": "equipment", "Tech": "intel", "Consumer": "advertising"}

@export_enum("operate", "quarter_end", "after_quarter", "neighbor_operate", "sell", "buy", "bad_event") var when: String = "operate"
@export_enum("gain", "gain_per", "gain_ctx", "pay", "convert", "vp", "vp_per", "vp_if", "grow", "grow_adjacent", "upgrade_adjacent", "mature", "absorb", "retrigger_adjacent", "distress_self", "restore_dormant", "extra_die", "gain_random_card", "peek_swap", "replace_market", "refresh_market", "refresh_type", "forecast_weaken", "forecast_delay", "forecast_cancel", "forecast_reveal") var kind: String = "gain"

@export_group("Resources (gain / pay / convert)")
@export var cash: int = 0
@export var labor: int = 0
@export var equipment: int = 0
@export var intel: int = 0
@export var advertising: int = 0
@export var brand_for_convert: int = 0

@export_group("Amounts")
@export var amount: int = 0
@export_enum("none", "cash", "labor", "equipment", "intel", "advertising") var resource: String = "none"
@export_enum("none", "board_type", "adjacent", "adjacent_type", "adjacent_other_type", "adjacent_empty", "adjacent_operated", "adjacent_type_operated", "row_type", "operated", "type_operated", "activations", "distinct_types", "market_cards", "empty_slots", "die_value", "copies", "resource", "spent", "goals_met", "distinct_dice", "unused_dice") var per: String = "none"
@export_enum("none", "Finance", "Services", "Industry", "Tech", "Consumer") var sector: String = "none"
@export var divide_by: int = 1
@export var max_count: int = 0

@export_group("Conditions")
@export_enum("none", "type_count_at_most", "adjacent_type_at_most", "ops_at_least") var condition: String = "none"
@export_enum("none", "Finance", "Services", "Industry", "Tech", "Consumer") var condition_sector: String = "none"
@export var condition_amount: int = 0
@export var else_amount: int = 0
@export_enum("none", "Finance", "Services", "Industry", "Tech", "Consumer") var only_if_neighbor_sector: String = "none"
@export var only_if_operated: bool = false
@export var on_die: int = 0

@export_group("Special")
@export var quarters: int = 0
@export var min_value: int = 0
@export_enum("none", "adjacent_type") var speed_per: String = "none"
@export var tag: String = ""
@export var count: int = 0
@export var forecast_slot: int = -1
@export var context_key: String = ""

func _amounts() -> Dictionary:
	var d := {}
	for r in ["cash", "labor", "equipment", "intel", "advertising"]:
		if int(get(r)) != 0:
			d[r] = int(get(r))
	return d

func to_dict() -> Dictionary:
	var d := {"kind": kind}
	match kind:
		"gain", "pay":
			d["res"] = _amounts()
		"convert":
			d["pay"] = _amounts()
			d["vp"] = brand_for_convert
		_:
			if resource != "none":
				d["res"] = resource
	if amount != 0:
		d["amount"] = amount
	if per != "none":
		d["per"] = per
	if sector != "none":
		d["type"] = SECTORS[sector]
	if divide_by > 1:
		d["div"] = divide_by
	if max_count > 0:
		d["max"] = max_count
	if condition != "none":
		var c := {"kind": condition}
		if condition_sector != "none":
			c["type"] = SECTORS[condition_sector]
		c["amount"] = condition_amount
		d["cond"] = c
	if else_amount != 0:
		d["else"] = else_amount
	if only_if_neighbor_sector != "none":
		d["if_source_type"] = SECTORS[only_if_neighbor_sector]
	if only_if_operated:
		d["if_operated"] = true
	if on_die > 0:
		d["on_die"] = on_die
	if quarters > 0:
		d["quarters"] = quarters
	if min_value > 0:
		d["min_value"] = min_value
	if speed_per != "none":
		d["speed_per"] = speed_per
	if tag != "":
		d["tag"] = tag
	if count > 0:
		d["count"] = count
	if forecast_slot >= 0:
		d["slot"] = forecast_slot
	if context_key != "":
		d["key"] = context_key
	return d
