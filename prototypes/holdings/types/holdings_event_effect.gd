class_name HoldingsEventEffect
extends Resource

@export_enum("dice_minus", "dice_minus_per_cards", "odd_minus", "cap_highest", "cost_plus", "refresh_plus", "market_frozen", "refresh_frozen", "lose_half", "halve_output", "halve_value", "dormant", "intel_locked", "exchange_rate") var kind: String = "dice_minus"
@export var amount: int = 0
@export_enum("none", "cash", "labor", "equipment", "intel", "advertising") var resource: String = "none"
@export_enum("none", "highest_value", "highest_value_ability", "lowest_value") var target: String = "none"
@export var cap: int = 0
@export var per_businesses: int = 0
@export var rate: int = 0

func to_dict() -> Dictionary:
	var d := {"kind": kind}
	if amount != 0:
		d["amount"] = amount
	if resource != "none":
		d["res"] = resource
	if target != "none":
		d["target"] = target
	if cap > 0:
		d["cap"] = cap
	if per_businesses > 0:
		d["per"] = per_businesses
	if rate > 0:
		d["rate"] = rate
	return d
