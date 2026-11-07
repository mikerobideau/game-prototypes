extends "res://prototypes/dj_engine/dj_engine.gd"

var pv_disc: Disc = null

func _ready() -> void:
	_ui_ready()
	rng.randomize()

func _process(delta: float) -> void:
	_ui_process(delta)

func _unhandled_input(_ev: InputEvent) -> void:
	pass

func _recompute_layout() -> void:
	window_size = get_viewport_rect().size
	ui_scale = 1.0
	screen_origin = Vector2.ZERO

func set_card(c: Dictionary) -> void:
	if c.is_empty():
		pv_disc = null
	else:
		pv_disc = _make_disc(_card_to_album(c))
		pv_disc.edition = ""
	queue_redraw()

func describe() -> Dictionary:
	if pv_disc == null:
		return {}
	return {"label": _cond_label(pv_disc), "text": _cond_text(pv_disc)}

func _draw() -> void:
	var full := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, full), Color("1b1d21"))
	var k := clampf(minf(full.x / 640.0, full.y / 820.0), 0.4, 1.3)
	ui_scale = k
	screen_origin = (full - Vector2(640.0, 820.0) * k) * 0.5
	draw_set_transform(screen_origin, 0.0, Vector2(k, k))
	var sz := Vector2(640.0, 820.0)
	_panel(Rect2(Vector2.ZERO, sz), Color("23272d"), 20, Color("353a42"), 2)
	if pv_disc == null:
		_text_center(Rect2(0.0, 0.0, sz.x, sz.y), "Select or add a card", T_MD, Color("8d939b"), true)
		return
	var d := pv_disc
	var c := Vector2(sz.x * 0.5, 215.0)
	draw_circle(c + Vector2(0.0, 8.0), 184.0, Color(0, 0, 0, 0.4))
	_disc_face(c, 170.0, d)
	_disc_marks(c, 170.0, d)
	_heavy_center(Rect2(20.0, 420.0, sz.x - 40.0, 50.0), d.title if d.title != "" else "Untitled", T_LG, Color.WHITE)
	_text_center(Rect2(20.0, 472.0, sz.x - 40.0, 30.0), "by %s" % (d.band if d.band != "" else "Various Artists"), T_SM, Color("b8c0cc"), true)
	var chips: Array = [[D.GENRES[d.genre].to_upper(), Color("5d626a")], [D.ERAS[d.era], Color("5d626a")], ["%d POINTS" % d.sound, Color(D.SOUND_COLOR)], [D.LABELS[d.label]["short"].to_upper(), Color(D.LABELS[d.label]["color"])]]
	var total := 0.0
	for ch: Array in chips:
		total += _text_w(String(ch[0]), T_XS, true) + 18.0 + 8.0
	var x := (sz.x - total + 8.0) * 0.5
	for ch: Array in chips:
		var w := _text_w(String(ch[0]), T_XS, true) + 18.0
		var r := Rect2(x, 520.0, w, 32.0)
		_panel(r, ch[1], 12)
		_text_center(r, String(ch[0]), T_XS, Color.WHITE, true)
		x += w + 8.0
	_text(Vector2(40.0, 620.0), "EFFECT", T_XS, c_gold, true)
	_text(Vector2(40.0, 656.0), _cond_label(d), T_MD, Color.WHITE, true)
	_wrap(Vector2(40.0, 690.0), _cond_text(d), sz.x - 300.0, T_SM, Color("e8ecf2"))
	var sc := Vector2(sz.x - 130.0, 690.0)
	draw_circle(sc + Vector2(0.0, 6.0), DISC_R + 8.0, Color(0, 0, 0, 0.35))
	_disc_face(sc, DISC_R, d)
	_disc_marks(sc, DISC_R, d)
	_text_center(Rect2(sc.x - 100.0, sc.y + DISC_R + 8.0, 200.0, 24.0), "In the changer or hand", T_XS, Color("8d939b"), true)
