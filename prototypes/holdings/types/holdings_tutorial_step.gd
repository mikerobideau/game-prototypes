class_name HoldingsTutorialStep
extends Resource

@export var title: String = ""
@export_multiline var body: String = ""
@export var targets: PackedStringArray = PackedStringArray()
@export_enum("next", "intro_closed", "market_pick", "buy", "placed", "operated", "resource", "scout", "end_quarter", "next_quarter", "meeting") var wait: String = "next"

func to_dict() -> Dictionary:
	return {"title": title, "body": body, "targets": Array(targets), "wait": wait}
