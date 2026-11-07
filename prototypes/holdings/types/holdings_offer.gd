class_name HoldingsOffer
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var text: String = ""
@export_enum("card", "cash", "check", "die", "lock", "swap", "vp", "wrench") var icon: String = "card"
@export_enum("none", "gold", "holo", "bluechip", "franchise") var edition: String = "none"

func to_dict() -> Dictionary:
	var o := {"name": name, "text": text, "icon": icon}
	if edition != "none":
		o["edition"] = edition
	return o
