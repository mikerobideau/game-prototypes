class_name HoldingsEdition
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var text: String = ""
@export var color: Color = Color.WHITE

func to_dict() -> Dictionary:
	return {"name": name, "text": text, "color": color.to_html(false)}
