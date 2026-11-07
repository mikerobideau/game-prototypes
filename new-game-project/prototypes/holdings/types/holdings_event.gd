class_name HoldingsEvent
extends Resource

const SECTORS := {"Finance": "cash", "Services": "labor", "Industry": "equipment", "Tech": "intel", "Consumer": "advertising"}

@export var id: String = ""
@export var name: String = ""
@export_enum("mild", "moderate", "severe", "none") var tier: String = "mild"
@export_enum("dice", "economy", "market", "business", "conditional", "none") var category: String = "economy"
@export_multiline var text: String = ""
@export var effects: Array[HoldingsEventEffect] = []

@export_group("Weakened version")
@export_multiline var weak_text: String = ""
@export var weak_effects: Array[HoldingsEventEffect] = []

@export_group("Goal")
@export_enum("none", "type_activated", "activations_at_least") var goal: String = "none"
@export_enum("none", "Finance", "Services", "Industry", "Tech", "Consumer") var goal_sector: String = "none"
@export var goal_amount: int = 0
@export var penalty: Array[HoldingsEventEffect] = []

func _list(a: Array[HoldingsEventEffect]) -> Array:
	var out: Array = []
	for m in a:
		if m != null:
			out.append(m.to_dict())
	return out

func to_dict() -> Dictionary:
	var e := {"name": name, "tier": tier, "category": category, "text": text, "full": not weak_effects.is_empty()}
	var mods := _list(effects)
	if not mods.is_empty():
		e["mods"] = mods
	if weak_text != "":
		e["weak_text"] = weak_text
	var weak := _list(weak_effects)
	if not weak.is_empty():
		e["weak"] = weak
	if goal != "none":
		var c := {"kind": goal}
		if goal_sector != "none":
			c["type"] = SECTORS[goal_sector]
		if goal_amount != 0:
			c["amount"] = goal_amount
		e["condition"] = c
	var pen := _list(penalty)
	if not pen.is_empty():
		e["penalty"] = pen
	return e
