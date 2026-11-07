class_name HoldingsSheet
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export_range(1, 3) var difficulty: int = 1
@export var order: int = 0
@export var random_layout: bool = false
@export var lots: Array[HoldingsLot] = []

@export_group("Starting bonus")
@export var bonus_cash: int = 0
@export var bonus_labor: int = 0
@export var bonus_equipment: int = 0
@export var bonus_intel: int = 0
@export var bonus_advertising: int = 0

func to_dict() -> Dictionary:
	var rules: Array = []
	var locks: Array = []
	var pockets: Array = []
	for lot in lots:
		if lot == null:
			lot = HoldingsLot.new()
		rules.append(lot.to_rule())
		locks.append(lot.to_lock())
		pockets.append("" if lot.pocket == "none" else lot.pocket)
	var bonus := {}
	for r in ["cash", "labor", "equipment", "intel", "advertising"]:
		if int(get("bonus_" + r)) != 0:
			bonus[r] = int(get("bonus_" + r))
	return {"name": name, "description": description, "difficulty": difficulty, "order": order, "random": random_layout,
		"rules": rules, "locks": locks, "pockets": pockets, "bonus": bonus}
