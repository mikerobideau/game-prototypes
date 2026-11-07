extends SceneTree

const PATH := "res://prototypes/dj_engine/data/cards.json"

var game
var wait := 30

func _initialize() -> void:
	game = load("res://prototypes/dj_engine/dj_engine.tscn").instantiate()
	root.add_child(game)

func _process(_d: float) -> bool:
	wait -= 1
	if wait > 0:
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var out: Array = []
	var converted := 0
	for c: Dictionary in data:
		if c.has("condition"):
			out.append(c)
			continue
		var r: Dictionary = game._legacy_rule_named(String(c.get("effect", "plain")), String(c.get("param", "")))
		out.append({
			"id": c["id"],
			"title": c["title"],
			"band": c["band"],
			"cover": c["cover"],
			"song": c["song"],
			"genre": c["genre"],
			"decade": c["decade"],
			"rarity": c["rarity"],
			"points": c["points"],
			"condition": r["condition"],
			"cond_param": r["cparam"],
			"effect": r["effect"],
			"value": r["value"],
			"target": r["target"],
			"target_param": r["tparam"],
		})
		converted += 1
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t", false))
	f.close()
	print("SV: migrated ", converted, " of ", out.size())
	return true
