extends SceneTree

const OUT := "res://prototypes/dj_engine/data/cards.json"
const PLAN := [
	["common", "plain", 14], ["common", "set1", 3], ["common", "set2", 3], ["common", "odd", 2], ["common", "even", 2],
	["common", "opener", 3], ["common", "closer", 3], ["common", "after_genre", 4], ["common", "after_decade", 3], ["common", "hype", 1],
	["uncommon", "plain", 3], ["uncommon", "above_genre", 3], ["uncommon", "above_decade", 3], ["uncommon", "fans", 3], ["uncommon", "anthem", 3], ["uncommon", "hype", 2],
	["rare", "boost", 3], ["rare", "mirror", 2], ["rare", "plain", 1], ["rare", "closer", 1], ["rare", "anthem", 1],
]
const POINTS := {"common": [5, 3], "uncommon": [9, 5], "rare": [14, 7]}

var game
var wait := 30

func _initialize() -> void:
	game = load("res://prototypes/dj_engine/dj_engine.tscn").instantiate()
	root.add_child(game)

func _slug(t: String) -> String:
	var out := ""
	for ch in t.to_lower():
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "-"
	while out.contains("--"):
		out = out.replace("--", "-")
	return out.strip_edges().trim_prefix("-").trim_suffix("-")

func _process(_d: float) -> bool:
	wait -= 1
	if wait > 0:
		return false
	var D = game.D
	game.albums.clear()
	game._legacy_albums()
	game.album_music.clear()
	game._load_music()
	var albums: Array = game.albums.duplicate()
	albums.sort_custom(func(a, b): return [a["genre"], a["band"], a["title"]] < [b["genre"], b["band"], b["title"]])
	var quota: Array = []
	for p in PLAN:
		for i in int(p[2]):
			quota.append([p[0], p[1]])
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260101
	for i in range(quota.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = quota[i]
		quota[i] = quota[j]
		quota[j] = t
	var cards: Array = []
	var used := {}
	for i in albums.size():
		var a: Dictionary = albums[i]
		var q: Array = quota[i % quota.size()]
		var rarity := String(q[0])
		var effect := String(q[1])
		var own_g := int(a["genre"])
		var param := ""
		if effect == "fans" or effect == "anthem":
			param = D.GENRES[own_g]
		elif effect.ends_with("genre"):
			var g := rng.randi_range(0, D.GENRES.size() - 2)
			if g >= own_g:
				g += 1
			param = D.GENRES[g]
		elif effect.ends_with("decade"):
			param = D.ERAS[rng.randi_range(0, D.ERAS.size() - 1)]
		var pts_row: Array = POINTS[rarity]
		var points := int(pts_row[0]) if effect == "plain" else int(pts_row[1])
		var id := _slug("%s-%s" % [a["band"], a["title"]])
		var base := id
		var n := 2
		while used.has(id):
			id = "%s-%d" % [base, n]
			n += 1
		used[id] = true
		var r: Dictionary = game._legacy_rule_named(effect, param)
		cards.append({
			"id": id,
			"title": a["title"],
			"band": a["band"],
			"cover": a["cover"],
			"song": String(game.album_music.get(a["cover"], "")),
			"genre": D.GENRES[own_g],
			"decade": D.ERAS[int(a["era"])],
			"rarity": rarity,
			"points": points,
			"condition": r["condition"],
			"cond_param": r["cparam"],
			"effect": r["effect"],
			"value": r["value"],
			"target": r["target"],
			"target_param": r["tparam"],
		})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(cards, "\t", false))
	f.close()
	var with_song := 0
	for c in cards:
		if String(c["song"]) != "":
			with_song += 1
	print("SV: wrote ", cards.size(), " cards, ", with_song, " with music")
	return true
