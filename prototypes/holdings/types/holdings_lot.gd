class_name HoldingsLot
extends Resource

const SECTORS := {"Finance": "cash", "Services": "labor", "Industry": "equipment", "Tech": "intel", "Consumer": "advertising"}

@export_group("Accepts")
@export_enum("any", "sector", "value") var rule: String = "any"
@export_enum("Finance", "Services", "Industry", "Tech", "Consumer") var rule_sector: String = "Finance"
@export var value_min: int = 1
@export var value_max: int = 99

@export_group("Lock")
@export_enum("open", "pay", "adjacent", "count", "value") var lock: String = "open"
@export_enum("cash", "labor", "equipment", "intel", "advertising") var lock_resource: String = "cash"
@export var lock_amount: int = 3
@export_enum("Finance", "Services", "Industry", "Tech", "Consumer") var lock_sector: String = "Finance"

@export_group("Pocket")
@export_enum("none", "gold", "express") var pocket: String = "none"

func to_rule() -> Dictionary:
	match rule:
		"sector":
			return {"kind": "sector", "type": SECTORS[rule_sector]}
		"value":
			return {"kind": "cap", "min": value_min, "max": value_max}
	return {"kind": "any"}

func to_lock() -> Dictionary:
	match lock:
		"pay":
			return {"kind": "pay", "res": lock_resource, "amount": lock_amount}
		"adjacent":
			return {"kind": "adjacent", "type": SECTORS[lock_sector]}
		"count":
			return {"kind": "count", "n": lock_amount}
		"value":
			return {"kind": "value", "min": lock_amount}
	return {}
