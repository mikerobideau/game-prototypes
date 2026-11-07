extends RefCounted

const CATALOG := "res://prototypes/nine_pocket/art/covers/catalog.json"

const GENRES: Array[String] = ["Classic Rock", "Indie", "Metal", "Punk", "Psychedelic"]
const GENRE_SHORT: Array[String] = ["ROCK", "INDIE", "METAL", "PUNK", "PSYCH"]
const GENRE_COLORS: Array[String] = ["b4532a", "2f6b4f", "3a3d42", "c0392b", "6a4bb5"]
const ERAS: Array[String] = ["70s", "80s", "90s", "00s"]
const ERA_COLORS: Array[String] = ["8a6d4b", "d4508f", "1f4e79", "d9821c"]

const TURNS := 15
const PLAYS_PER_TURN := 2
const START_CASH := 3
const INCOME := 1
const HAND_MAX := 6
const ROW_SIZE := 3
const REFRESH_COST := 1
const COPIES := 3
const COST_MAX := 4
const PLACED_CHANCE := 0.6
const OBJECTIVE_CHOICES := 3

const PLACED := [
	{"cond": "always", "per": false, "min": 1, "gives": {"vp": 2}, "cost": 1},
	{"cond": "always", "per": false, "min": 1, "gives": {"cash": 2}, "cost": 0},
	{"cond": "always", "per": false, "min": 1, "gives": {"draw": 1}, "cost": 1},
	{"cond": "always", "per": false, "min": 1, "gives": {"play": 1}, "cost": 2},
	{"cond": "adj", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "adj_genre", "per": true, "min": 1, "gives": {"vp": 2}, "cost": 2},
	{"cond": "adj_era", "per": true, "min": 1, "gives": {"vp": 2}, "cost": 2},
	{"cond": "row_genre", "per": true, "min": 1, "gives": {"vp": 2}, "cost": 2},
	{"cond": "col_era", "per": true, "min": 1, "gives": {"vp": 2}, "cost": 2},
	{"cond": "bind_genre", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "bind_era", "per": true, "min": 1, "gives": {"cash": 1}, "cost": 1},
	{"cond": "hand", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "corner", "per": false, "min": 1, "gives": {"vp": 4}, "cost": 2},
	{"cond": "center", "per": false, "min": 1, "gives": {"vp": 4}, "cost": 2},
]

const PLAYED := [
	{"cond": "always", "per": false, "min": 1, "gives": {"vp": 1}, "cost": 0},
	{"cond": "always", "per": false, "min": 1, "gives": {"cash": 2}, "cost": 1},
	{"cond": "always", "per": false, "min": 1, "gives": {"draw": 1}, "cost": 1},
	{"cond": "always", "per": false, "min": 1, "gives": {"vp": 1, "cash": 1}, "cost": 2},
	{"cond": "adj", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "adj", "per": true, "min": 1, "gives": {"cash": 1}, "cost": 1},
	{"cond": "adj_genre", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "adj_era", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "row_genre", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "col_era", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "bind_genre", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 3},
	{"cond": "bind_era", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 3},
	{"cond": "hand", "per": true, "min": 1, "gives": {"vp": 1}, "cost": 1},
	{"cond": "corner", "per": false, "min": 1, "gives": {"vp": 3}, "cost": 1},
	{"cond": "center", "per": false, "min": 1, "gives": {"vp": 3}, "cost": 1},
	{"cond": "edge", "per": false, "min": 1, "gives": {"vp": 2}, "cost": 1},
	{"cond": "adj_genre", "per": false, "min": 2, "gives": {"play": 1}, "cost": 3},
	{"cond": "bind_era", "per": false, "min": 3, "gives": {"play": 1}, "cost": 3},
]

const OBJECTIVES := [
	{"id": "genre_lines", "name": "Genre Lines", "text": "4 VP for each row or column whose three CDs share a genre."},
	{"id": "era_lines", "name": "Decade Lines", "text": "4 VP for each row or column whose three CDs share a decade."},
	{"id": "corners", "name": "Four Corners", "text": "10 VP if your four corners are four different decades."},
	{"id": "full_page", "name": "Full Page", "text": "1 VP per CD in your binder, plus 6 VP if all nine pockets are full."},
	{"id": "spread", "name": "Well Rounded", "text": "3 VP for each genre with at least 2 CDs in your binder."},
	{"id": "specialist", "name": "Specialist", "text": "2 VP for each CD of your most common genre."},
	{"id": "hub", "name": "The Hub", "text": "3 VP for each neighbour of the center CD that shares its genre."},
	{"id": "stash", "name": "Stash", "text": "1 VP per CD left in your hand and 1 VP per 2 Cash."},
	{"id": "diagonal", "name": "Diagonals", "text": "10 VP for each diagonal whose three CDs share a genre."},
	{"id": "decade_sweep", "name": "Decade Sweep", "text": "4 VP for each decade with at least 2 CDs in your binder."},
]

const RANKS := [
	{"vp": 0, "name": "Garage Sale"},
	{"vp": 25, "name": "Weekend Crate Digger"},
	{"vp": 45, "name": "Record Store Regular"},
	{"vp": 65, "name": "Collector's Collector"},
]

static func describe(h: Dictionary) -> String:
	var g: Dictionary = h["gives"]
	var parts: Array[String] = []
	if g.has("vp"):
		parts.append("+%d VP" % g["vp"])
	if g.has("cash"):
		parts.append("+%d Cash" % g["cash"])
	if g.has("play"):
		parts.append("+%d Play%s" % [g["play"], "" if int(g["play"]) == 1 else "s"])
	if g.has("draw"):
		parts.append("Draw %d CD%s" % [g["draw"], "" if int(g["draw"]) == 1 else "s"])
	var gain := ", ".join(parts)
	var cond: String = h["cond"]
	var bits := cond.split("_")
	var scope: String = bits[0]
	var thing := "CD"
	if bits.size() > 1:
		thing = GENRES[h["genre"]] if bits[1] == "genre" else ERAS[h["era"]]
	var per: bool = h["per"]
	var min_n: int = h["min"]
	match scope:
		"always":
			return gain
		"corner":
			return "%s if in a corner" % gain
		"center":
			return "%s if in the center" % gain
		"edge":
			return "%s if on an edge" % gain
		"hand":
			return "%s per CD in your hand" % gain
		"adj":
			return ("%s per adjacent %s" % [gain, thing]) if per else ("%s if next to %d+ %s" % [gain, min_n, thing])
		"row":
			return ("%s per other %s in this row" % [gain, thing]) if per else ("%s if %d+ other %s in this row" % [gain, min_n, thing])
		"col":
			return ("%s per other %s in this column" % [gain, thing]) if per else ("%s if %d+ other %s in this column" % [gain, min_n, thing])
		"bind":
			return ("%s per other %s in your binder" % [gain, thing]) if per else ("%s if %d+ other %s in your binder" % [gain, min_n, thing])
	return gain
