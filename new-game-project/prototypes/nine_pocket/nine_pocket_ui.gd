extends Node2D

const SOUND_DIR := "res://prototypes/holdings/sound/"

class UiButton:
	var rect: Rect2
	var cb: Callable

const UI_W := 2560.0
const UI_H := 1440.0
const CARD_W := 290.0
const CARD_H := 352.0
const GAP := 20.0
const BINDER_BORDER := 36.0
const BINDER_RINGS := 70.0
const BINDER_TOP := 214.0
const SLEEVE_GLOSS := 0.1

const T_XS := 16
const T_SM := 20
const T_MD := 24
const T_LG := 30
const T_XL := 40
const T_HERO := 64

const C_LEATHER := Color("33373e")

var c_page := Color("141a24")
var c_card := Color("ffffff")
var c_ink := Color("1e2633")
var c_body := Color("4f5866")
var c_muted := Color("7a8290")
var c_line := Color("d4dae0")
var c_good := Color("3e7b4f")
var c_bad := Color("c4553f")
var c_gold := Color("e9b949")

var window_size := Vector2.ZERO
var ui_scale := 1.0
var screen_origin := Vector2.ZERO
var p_binder := Rect2()
var r_grid := Rect2()

var font: Font
var font_bold: Font
var font_heavy: Font
var font_italic: Font
var style := StyleBoxFlat.new()
var buttons: Array[UiButton] = []
var ui_live := true
var hover_tip := ""
var hover_rect := Rect2()
var mouse := Vector2.ZERO
var clock := 0.0
var sfx := {}

func _ui_ready() -> void:
	_load_fonts()
	_load_sounds()
	_recompute_layout()
	get_viewport().size_changed.connect(_recompute_layout)

func _ui_process(delta: float) -> void:
	clock += delta
	var over := Rect2()
	var mp := _ui_mouse()
	for i in range(buttons.size() - 1, -1, -1):
		if buttons[i].rect.has_point(mp):
			over = buttons[i].rect
			break
	if over != hover_rect:
		hover_rect = over
		if over.has_area():
			_sfx("mouseover")
	queue_redraw()

func _ui_click(p: Vector2) -> bool:
	for i in range(buttons.size() - 1, -1, -1):
		if buttons[i].rect.has_point(p):
			_sfx("click")
			buttons[i].cb.call()
			return true
	return false

func _begin_draw() -> void:
	buttons.clear()
	hover_tip = ""
	draw_rect(Rect2(Vector2.ZERO, window_size), c_page)
	mouse = _ui_mouse()
	draw_set_transform(screen_origin, 0.0, Vector2(ui_scale, ui_scale))

func _end_draw() -> void:
	if hover_tip != "":
		_draw_tooltip(hover_tip)
	draw_set_transform(Vector2.ZERO)

func _load_fonts() -> void:
	var ts := TextServerManager.get_primary_interface()
	var wght := ts.name_to_tag("wght")
	var sans_path := "res://assets/fonts/DMSans-VariableFont.ttf"
	var serif_path := "res://assets/fonts/Fraunces-VariableFont.ttf"
	font = ThemeDB.fallback_font
	font_bold = ThemeDB.fallback_font
	font_heavy = ThemeDB.fallback_font
	font_italic = ThemeDB.fallback_font
	if ResourceLoader.exists(sans_path):
		var sans: Font = load(sans_path)
		font = _variation(sans, {wght: 450})
		font_bold = _variation(sans, {wght: 700})
		var it := _variation(sans, {wght: 450})
		it.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.22, 1.0), Vector2.ZERO)
		font_italic = it
	if ResourceLoader.exists(serif_path):
		var serif: Font = load(serif_path)
		font_heavy = _variation(serif, {wght: 700, ts.name_to_tag("opsz"): 72, ts.name_to_tag("SOFT"): 50})

func _variation(base: Font, axes: Dictionary) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = axes
	return v

func _load_sounds() -> void:
	for n: String in ["click", "mouseover", "page_turn"]:
		var path := SOUND_DIR + "%s.%s" % [n, "mp3" if n == "page_turn" else "wav"]
		if not ResourceLoader.exists(path):
			continue
		var pl := AudioStreamPlayer.new()
		pl.stream = load(path)
		pl.volume_db = -10.0 if n == "mouseover" else -4.0
		add_child(pl)
		sfx[n] = pl

func _sfx(n: String) -> void:
	if not sfx.has(n):
		return
	var pl: AudioStreamPlayer = sfx[n]
	pl.play(0.5 if n == "page_turn" else 0.0)

func _recompute_layout() -> void:
	window_size = get_viewport_rect().size
	ui_scale = minf(window_size.x / UI_W, window_size.y / UI_H)
	screen_origin = (window_size - Vector2(UI_W, UI_H) * ui_scale) * 0.5
	var gw := 3.0 * CARD_W + 2.0 * GAP
	var gh := 3.0 * CARD_H + 2.0 * GAP
	var bw := gw + BINDER_RINGS + BINDER_BORDER * 2.0
	p_binder = Rect2(UI_W - 56.0 - bw, BINDER_TOP, bw, gh + BINDER_BORDER * 2.0)
	r_grid = Rect2(p_binder.position.x + BINDER_BORDER + BINDER_RINGS, p_binder.position.y + BINDER_BORDER, gw, gh)

func _ui_mouse() -> Vector2:
	return (get_local_mouse_position() - screen_origin) / maxf(ui_scale, 0.0001)

func _panel(r: Rect2, col: Color, radius: int = 18, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> void:
	style.bg_color = col
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(border_w)
	style.anti_aliasing = true
	draw_style_box(style, r)

func _shadow(r: Rect2, radius: int, depth: float = 6.0) -> void:
	_panel(Rect2(r.position + Vector2(0.0, depth), r.size), Color(0, 0, 0, 0.18), radius)
	_panel(Rect2(r.position + Vector2(0.0, depth * 0.4), r.size), Color(0, 0, 0, 0.12), radius)

func _round_points(r: Rect2, radius: float) -> PackedVector2Array:
	var rad := minf(radius, minf(r.size.x, r.size.y) * 0.5)
	var centers := [Vector2(r.end.x - rad, r.end.y - rad), Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad), Vector2(r.end.x - rad, r.position.y + rad)]
	var pts := PackedVector2Array()
	for q in 4:
		for i in 7:
			var a := (q + i / 6.0) * PI * 0.5
			pts.append(centers[q] + Vector2(cos(a), sin(a)) * rad)
	return pts

func _grad_panel(r: Rect2, radius: float, top: Color, bottom: Color) -> void:
	var pts := _round_points(r, radius)
	var cols := PackedColorArray()
	for pt in pts:
		cols.append(top.lerp(bottom, clampf((pt.y - r.position.y) / r.size.y, 0.0, 1.0)))
	draw_polygon(pts, cols)

func _f(bold: bool) -> Font:
	return font_bold if bold else font

func _vc(f: Font, size: int) -> float:
	return (f.get_ascent(size) - f.get_descent(size)) * 0.5

func _text(pos: Vector2, s: String, size: int, col: Color, bold: bool = false) -> void:
	draw_string(_f(bold), pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _text_w(s: String, size: int, bold: bool = false) -> float:
	return _f(bold).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _text_right(right_x: float, y: float, s: String, size: int, col: Color, bold: bool = false) -> void:
	_text(Vector2(right_x - _text_w(s, size, bold), y), s, size, col, bold)

func _text_center(r: Rect2, s: String, size: int, col: Color, bold: bool = false) -> void:
	var f := _f(bold)
	draw_string(f, Vector2(r.position.x + (r.size.x - _text_w(s, size, bold)) * 0.5, r.get_center().y + _vc(f, size)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _heavy(pos: Vector2, s: String, size: int, col: Color) -> void:
	draw_string(font_heavy, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _heavy_w(s: String, size: int) -> float:
	return font_heavy.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _heavy_center(r: Rect2, s: String, size: int, col: Color) -> void:
	_heavy(Vector2(r.position.x + (r.size.x - _heavy_w(s, size)) * 0.5, r.get_center().y + _vc(font_heavy, size)), s, size, col)

func _heavy_right(right_x: float, y: float, s: String, size: int, col: Color) -> void:
	_heavy(Vector2(right_x - _heavy_w(s, size), y), s, size, col)

func _wrap(pos: Vector2, s: String, width: float, size: int, col: Color, bold: bool = false, max_lines: int = -1) -> void:
	draw_multiline_string(_f(bold), pos + Vector2(0.0, _f(bold).get_ascent(size)), s, HORIZONTAL_ALIGNMENT_LEFT, width, size, max_lines, col)

func _register(r: Rect2, cb: Callable) -> void:
	if not ui_live:
		return
	var b := UiButton.new()
	b.rect = r
	b.cb = cb
	buttons.append(b)

func _tip(r: Rect2, text: String) -> void:
	if ui_live and text != "" and r.has_point(mouse):
		hover_tip = text

func _text_i(pos: Vector2, s: String, size: int, col: Color) -> void:
	draw_string(font_italic, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _ghost(r: Rect2, label: String, cb: Callable, enabled: bool, ink: Color) -> void:
	var hovered := enabled and ui_live and r.has_point(mouse)
	var radius := int(minf(r.size.y * 0.5, 16.0))
	if hovered:
		_panel(r, Color(ink, 0.1), radius)
	_panel(r, Color(0, 0, 0, 0), radius, Color(ink, 0.45 if enabled else 0.2), 2)
	_text_center(r, label, T_MD, ink if enabled else Color(ink, 0.4), true)
	if enabled:
		_register(r, cb)

func _stitch_rect(st: Rect2, col: Color) -> void:
	var x := st.position.x + 18.0
	while x < st.end.x - 18.0:
		draw_line(Vector2(x, st.position.y), Vector2(x + 8.0, st.position.y), col, 2.0)
		draw_line(Vector2(x, st.end.y), Vector2(x + 8.0, st.end.y), col, 2.0)
		x += 14.0
	var y := st.position.y + 18.0
	while y < st.end.y - 18.0:
		draw_line(Vector2(st.position.x, y), Vector2(st.position.x, y + 8.0), col, 2.0)
		draw_line(Vector2(st.end.x, y), Vector2(st.end.x, y + 8.0), col, 2.0)
		y += 14.0

func _grain(r: Rect2, seed_n: int, density: float) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = seed_n
	for i in int(r.size.x * r.size.y / density):
		var pt := Vector2(g.randf_range(r.position.x + 6.0, r.end.x - 6.0), g.randf_range(r.position.y + 6.0, r.end.y - 6.0))
		draw_rect(Rect2(pt, Vector2(1.6, 1.6)), Color(0, 0, 0, 0.12) if i % 3 else Color(1, 1, 1, 0.05))

func _disc(c: Vector2, rad: float) -> void:
	draw_circle(c + Vector2(0, rad * 0.08), rad, Color(0, 0, 0, 0.25))
	draw_circle(c, rad, Color("d5dae0"))
	var hues := [Color("ff9ec4"), Color("ffe08a"), Color("9effa8"), Color("8fe9ff"), Color("c3a8ff")]
	for i in hues.size():
		var a0 := -0.9 + i * 0.22 + clock * 0.15
		draw_arc(c, rad * (0.55 + i * 0.08), a0, a0 + 1.1, 16, Color(hues[i], 0.5), maxf(1.0, rad * 0.07), true)
		draw_arc(c, rad * (0.55 + i * 0.08), a0 + PI, a0 + PI + 1.1, 16, Color(hues[i], 0.35), maxf(1.0, rad * 0.07), true)
	draw_arc(c, rad, 0, TAU, 40, Color(0, 0, 0, 0.2), maxf(1.0, rad * 0.05), true)
	draw_circle(c, rad * 0.34, Color("eef1f4"))
	draw_arc(c, rad * 0.34, 0, TAU, 24, Color(0, 0, 0, 0.12), maxf(1.0, rad * 0.03), true)
	draw_circle(c, rad * 0.13, Color("30343b"))

func _pocket_lip(pocket: Rect2) -> void:
	_panel(Rect2(pocket.position + Vector2(4.0, 3.0), Vector2(pocket.size.x - 8.0, 7.0)), Color(0, 0, 0, 0.22), 3)
	var notch := Vector2(pocket.get_center().x, pocket.position.y + 4.0)
	var pts := PackedVector2Array()
	for a in 13:
		var t := a / 12.0 * PI
		pts.append(notch + Vector2(cos(t) * 26.0, sin(t) * 13.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.22))

func _sleeve_gloss(r: Rect2) -> void:
	var a := r.grow(-6.0)
	draw_colored_polygon(PackedVector2Array([a.position, a.position + Vector2(a.size.x * 0.62, 0), a.position + Vector2(0, a.size.y * 0.42)]), Color(1, 1, 1, SLEEVE_GLOSS))
	draw_colored_polygon(PackedVector2Array([a.position + Vector2(a.size.x * 0.8, 0), a.position + Vector2(a.size.x * 0.9, 0), a.position + Vector2(0, a.size.y * 0.66), a.position + Vector2(0, a.size.y * 0.58)]), Color(1, 1, 1, SLEEVE_GLOSS * 0.6))

func _fill_piece(piece: PackedVector2Array, col: Color) -> void:
	if Geometry2D.triangulate_polygon(piece).is_empty():
		return
	draw_colored_polygon(piece, col)

func _draw_art(r: Rect2, seed_n: int, title: String, tc: Color, trim: Color) -> void:
	var k := r.size.y / 152.0
	var h := absi(seed_n)
	var hue := fmod(tc.h + ((h % 40) - 20) / 100.0 + 1.0, 1.0)
	var a := Color.from_hsv(hue, 0.5, 0.92)
	var b := Color.from_hsv(fmod(hue + 0.07, 1.0), 0.75, 0.42)
	var accent := Color.from_hsv(fmod(hue + 0.5, 1.0), 0.45, 0.98)
	_panel(Rect2(r.position + Vector2(2, 3) * k, r.size), Color(0, 0, 0, 0.35), int(3.0 * k))
	_grad_panel(r, 3.0 * k, a, b)
	var c := r.get_center()
	match (h / 3) % 5:
		0:
			var sun := Vector2(c.x, r.position.y + r.size.y * 0.52)
			draw_circle(sun, r.size.y * 0.3, accent)
			for j in 5:
				var y := sun.y + j * 8.0 * k
				draw_rect(Rect2(r.position.x, y, r.size.x, (1.5 + j) * k), b)
			draw_rect(Rect2(r.position.x, sun.y + 40.0 * k, r.size.x, r.end.y - sun.y - 40.0 * k), b)
		1:
			var x := r.position.x
			var j := 0
			while x < r.end.x:
				var w := (8.0 + ((h >> j) % 4) * 7.0) * k
				var cols := [accent, b, a.lightened(0.3), trim]
				draw_rect(Rect2(x, r.position.y, minf(w, r.end.x - x), r.size.y), Color(cols[j % cols.size()], 0.85))
				x += w
				j += 1
		2:
			for gy in 5:
				for gx in 5:
					var p := r.position + Vector2((gx + 0.5) * r.size.x / 5.0, (gy + 0.5) * r.size.y / 5.0)
					var rad := (3.0 + ((h >> (gx + gy)) % 5) * 2.2) * k
					draw_circle(p, rad, accent if (gx + gy) % 2 == 0 else a.lightened(0.35))
		3:
			for j in 6:
				var pts := PackedVector2Array()
				var y0 := r.position.y + r.size.y * (0.3 + j * 0.12)
				for i in 25:
					var t := i / 24.0
					pts.append(Vector2(r.position.x + t * r.size.x, y0 + sin(t * TAU * 1.5 + j * 0.9 + h % 7) * 8.0 * k))
				draw_polyline(pts, accent if j % 2 == 0 else a.lightened(0.4), 4.0 * k, true)
		_:
			var letter := title.left(1)
			_heavy(Vector2(r.position.x + r.size.x * 0.18, r.end.y - 14.0 * k), letter, _fs(130.0, k), Color(accent, 0.9))
			draw_line(Vector2(r.position.x + 10.0 * k, r.position.y + 40.0 * k), Vector2(r.end.x - 10.0 * k, r.position.y + 40.0 * k), Color(1, 1, 1, 0.7), 2.0 * k)

func _cd_art(c: Vector2, rad: float, tex: Texture2D, spin: float = 0.0) -> void:
	if tex == null:
		_disc(c, rad)
		return
	draw_circle(c + Vector2(0, rad * 0.06), rad, Color(0, 0, 0, 0.35))
	var hole := rad * 0.14
	var uv_hole := 0.5 * hole / rad
	var mid := Vector2(0.5, 0.5)
	var ts := tex.get_size()
	var crop := Vector2(minf(1.0, ts.y / ts.x), minf(1.0, ts.x / ts.y))
	var white := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	var n := 72
	for i in n:
		var d0 := Vector2.from_angle(TAU * i / n)
		var d1 := Vector2.from_angle(TAU * (i + 1) / n)
		var pts := PackedVector2Array([c + d0 * hole, c + d0 * rad, c + d1 * rad, c + d1 * hole])
		var u0 := d0.rotated(-spin)
		var u1 := d1.rotated(-spin)
		var uvs := PackedVector2Array([mid + u0 * uv_hole * crop, mid + u0 * 0.5 * crop, mid + u1 * 0.5 * crop, mid + u1 * uv_hole * crop])
		draw_primitive(pts, white, uvs, tex)
	draw_arc(c, (hole + rad * 0.33) * 0.5, 0, TAU, 48, Color(1, 1, 1, 0.22), rad * 0.33 - hole, true)
	draw_arc(c, rad * 0.33, 0, TAU, 48, Color(1, 1, 1, 0.35), maxf(1.0, rad * 0.012), true)
	draw_arc(c, rad * 0.2, 0, TAU, 32, Color(0, 0, 0, 0.18), maxf(1.0, rad * 0.01), true)
	draw_arc(c, hole, 0, TAU, 32, Color(1, 1, 1, 0.5), maxf(1.0, rad * 0.015), true)
	var hues := [Color("ff9ec4"), Color("ffe08a"), Color("9effa8"), Color("8fe9ff"), Color("c3a8ff")]
	for i in hues.size():
		var a0 := -0.9 + i * 0.12 + clock * 0.15
		var rr := rad * (0.45 + i * 0.1)
		draw_arc(c, rr, a0, a0 + 0.9, 16, Color(hues[i], 0.16), maxf(1.0, rad * 0.06), true)
		draw_arc(c, rr, a0 + PI, a0 + PI + 0.9, 16, Color(hues[i], 0.12), maxf(1.0, rad * 0.06), true)
	draw_arc(c, rad - 1.0, 0, TAU, 72, Color(1, 1, 1, 0.55), maxf(1.0, rad * 0.018), true)

func _fs(size: float, k: float) -> int:
	return maxi(8, int(round(size * k)))

func _draw_tooltip(text: String) -> void:
	var w := 520.0
	var ts := font_bold.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, T_SM)
	var box := Rect2(mouse + Vector2(24.0, 24.0), Vector2(minf(ts.x, w) + 36.0, ts.y + 26.0))
	if box.end.x > UI_W - 12.0:
		box.position.x = mouse.x - box.size.x - 16.0
	if box.end.y > UI_H - 12.0:
		box.position.y = mouse.y - box.size.y - 16.0
	_panel(box, c_ink, 14, Color(1, 1, 1, 0.15), 2)
	_wrap(box.position + Vector2(18.0, 13.0), text, w, T_SM, Color.WHITE, true)

