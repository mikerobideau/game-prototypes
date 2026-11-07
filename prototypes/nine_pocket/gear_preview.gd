extends "res://prototypes/nine_pocket/nine_pocket.gd"

var pv_id := ""
var pv_gear := {}

func _ready() -> void:
	_ui_ready()
	_load_gear()
	rng.randomize()
	_load_albums()

func _process(delta: float) -> void:
	_ui_process(delta)

func _unhandled_input(_ev: InputEvent) -> void:
	pass

func _recompute_layout() -> void:
	window_size = get_viewport_rect().size
	ui_scale = 1.0
	screen_origin = Vector2.ZERO

func show_unit(id: String) -> void:
	pv_id = id
	pv_gear = _make_gear(id) if gear_defs.has(id) else {}
	queue_redraw()

func _draw() -> void:
	var full := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, full), Color("1b1d21"))
	var k := clampf(minf(full.x / 640.0, full.y / 640.0), 0.4, 1.3)
	ui_scale = k
	screen_origin = (full - Vector2(640.0, 640.0) * k) * 0.5
	draw_set_transform(screen_origin, 0.0, Vector2(k, k))
	var sz := Vector2(640.0, 640.0)
	_panel(Rect2(Vector2.ZERO, sz), Color("23272d"), 20, Color("353a42"), 2)
	if pv_gear.is_empty():
		_text_center(Rect2(0.0, 0.0, sz.x, sz.y), "Select a unit", T_MD, Color("8d939b"), true)
		return
	var def: Dictionary = gear_defs[pv_id]
	var is_full := String(def["size"]) == "full"
	var r := Rect2(42.0, 60.0, 556.0, 316.0) if is_full else Rect2(184.0, 60.0, 272.0, 316.0)
	_draw_gear(r, pv_gear, 0.5 + 0.5 * sin(clock * 3.0), -1)
	var sell := maxi(1, int(def["price"]) / 2)
	var lines: Array = [
		"%s unit  ·  $%d  ·  sells for $%d" % ["Full" if is_full else "Half", int(def["price"]), sell],
		"Activates: %s" % String(def.get("activates", "song")),
	]
	var y := 430.0
	for ln in lines:
		_text_center(Rect2(20.0, y, sz.x - 40.0, 30.0), String(ln), T_SM, Color("b8c0cc"), true)
		y += 36.0

func _cash_of(res: Dictionary) -> int:
	var c := 0
	for sl: Dictionary in res["slots"]:
		c += int(sl["cash"])
	return c

func _lift_setup() -> bool:
	if albums.is_empty():
		return false
	collection.clear()
	for a: Dictionary in _random_albums(8):
		var d := _make_disc(a)
		d.edition = ""
		collection.append(d)
	wallet.clear()
	for i in D.HAND:
		wallet.append(-1)
	wallet[4] = 4
	wallet[5] = 5
	tray.clear()
	for i in D.TRAYS:
		tray.append(i if i < D.SETLIST else -1)
	venue = (D.VENUES[rng.randi_range(0, D.VENUES.size() - 1)] as Dictionary).duplicate(true)
	crowd_move = {}
	return true

func _score_with(ids: Array, bay: int = -1) -> Array:
	rack.clear()
	for i in D.RACK_SLOTS:
		rack.append({})
	for k in ids.size():
		var g := _make_gear(String(ids[k]))
		if g.has("count"):
			g["count"] = 10
		if bay >= 0 and k == ids.size() - 1:
			rack[bay] = g
		else:
			_place_free(g)
	var res := _score_set([0, 1, 2, 3], [0, 1, 2, 3])
	return [float(res["total"]), float(_cash_of(res))]

func _lift_ids(id: String) -> Array:
	if id == "wah":
		return [["clean_boost", "clean_boost", "clean_boost"], ["clean_boost", "clean_boost", "clean_boost", "wah"]]
	return [[], [id]]

func lift(ids: Array, trials: int) -> Dictionary:
	var out := {}
	for id in ids:
		out[id] = {"points": 0.0, "cash": 0.0}
	if not gear_defs.is_empty():
		var done := 0
		for t in trials:
			if not _lift_setup():
				break
			done += 1
			for id in ids:
				var cfg: Array = _lift_ids(String(id))
				var a: Array = _score_with(cfg[0])
				for bay in D.SETLIST:
					var b: Array = _score_with(cfg[1], bay if String(id) != "wah" else 3)
					out[id]["points"] = float(out[id]["points"]) + (b[0] - a[0]) / float(D.SETLIST)
					out[id]["cash"] = float(out[id]["cash"]) + (b[1] - a[1]) / float(D.SETLIST)
		for id in ids:
			out[id]["points"] = float(out[id]["points"]) / maxf(1.0, float(done))
			out[id]["cash"] = float(out[id]["cash"]) / maxf(1.0, float(done))
	return out
