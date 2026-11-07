extends "res://prototypes/nine_pocket/nine_pocket.gd"

const RD_SET := 5
const RD_HAND := 8

const R_MATRIX := Rect2(70.0, 130.0, 1100.0, 860.0)
const R_RING := Rect2(1200.0, 130.0, 1290.0, 860.0)
const RING_C := Vector2(1625.0, 575.0)
const RING_R := 250.0
const SLOT_R := 82.0
const CELL_W := 128.0
const CELL_H := 88.0
const CELL_PX := 136.0
const CELL_PY := 96.0
const CARD_WD := 286.0
const CARD_HT := 396.0
const CARD_TOP := 1024.0
const TAG_OPEN := 1
const TAG_CLOSE := 2
const INK := Color("23262b")
const GOLD := Color("e9b949")

var rd_hand: Array[Disc] = []
var rd_tags: Array[int] = []
var rd_line: Array[int] = []
var rd_label := false
var rd_hover := -1

func _ready() -> void:
	_ui_ready()
	rng.randomize()
	_load_albums()
	_rd_deal(false)

func _process(delta: float) -> void:
	_ui_process(delta)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_ui_click(_ui_mouse())

func _rd_deal(wide: bool) -> void:
	rd_hand.clear()
	rd_tags.clear()
	rd_line.clear()
	var cells: Array = []
	if wide:
		for g in D.GENRES.size():
			for e in D.ERAS.size():
				cells.append(Vector2i(g, e))
	else:
		var gs: Array = range(D.GENRES.size())
		_shuffle(gs)
		var start := rng.randi_range(0, D.ERAS.size() - 3)
		for g in gs.slice(0, 3):
			for e in range(start, start + 3):
				cells.append(Vector2i(g, e))
	_shuffle(cells)
	var pick: Array = cells.slice(0, RD_HAND)
	pick.sort_custom(func(a: Vector2i, b: Vector2i): return a.x < b.x or (a.x == b.x and a.y < b.y))
	var used := {}
	for c: Vector2i in pick:
		var pool: Array = albums.filter(func(a): return a["genre"] == c.x and not used.has(a["cover"]))
		var a: Dictionary = pool.pick_random()
		used[a["cover"]] = true
		var d := _make_disc(a)
		d.era = c.y
		d.edition = ""
		rd_hand.append(d)
		var roll := rng.randf()
		rd_tags.append(TAG_OPEN if roll < 0.2 else (TAG_CLOSE if roll < 0.4 else (TAG_OPEN | TAG_CLOSE if roll < 0.46 else 0)))

func _rd_undo() -> void:
	if not rd_line.is_empty():
		rd_line.pop_back()

func _rd_reset() -> void:
	rd_line.clear()

func _rd_toggle_label() -> void:
	rd_label = not rd_label

func _rd_click(i: int) -> void:
	if rd_label:
		rd_tags[i] = (rd_tags[i] + 1) % 4
	elif rd_line.size() < RD_SET and not rd_line.has(i):
		rd_line.append(i)

func _rd_link(a: Disc, b: Disc) -> bool:
	return a.genre == b.genre or a.era == b.era

func _rd_state() -> Dictionary:
	var flows: Array[int] = []
	var links: Array[bool] = []
	var pts: Array[int] = []
	var bonus: Array[bool] = []
	var ring := false
	var total := 0
	for i in rd_line.size():
		var d := rd_hand[rd_line[i]]
		var tag := rd_tags[rd_line[i]]
		var f := 1
		var lk := false
		if i > 0:
			lk = _rd_link(d, rd_hand[rd_line[i - 1]])
			if lk:
				f = mini(D.FLOW_MAX, flows[i - 1] + 1)
		if i == RD_SET - 1 and _rd_link(d, rd_hand[rd_line[0]]):
			ring = true
			f = mini(D.FLOW_MAX + 1, f + 1)
		var p := d.sound
		var tagged := (i == 0 and (tag & TAG_OPEN) != 0) or (i == RD_SET - 1 and (tag & TAG_CLOSE) != 0)
		if tagged:
			p += 3
		flows.append(f)
		links.append(lk)
		pts.append(p)
		bonus.append(tagged)
		total += p * f
	return {"flows": flows, "links": links, "pts": pts, "bonus": bonus, "ring": ring, "total": total}

func _rd_keeps(i: int) -> bool:
	return not rd_line.is_empty() and not rd_line.has(i) and _rd_link(rd_hand[i], rd_hand[rd_line.back()])

func _rd_closes(i: int) -> bool:
	return rd_line.size() == RD_SET - 1 and not rd_line.has(i) and _rd_link(rd_hand[i], rd_hand[rd_line[0]])

func _rd_card(i: int) -> Rect2:
	var gap := (UI_W - 2.0 * 84.0 - RD_HAND * CARD_WD) / (RD_HAND - 1)
	return Rect2(84.0 + i * (CARD_WD + gap), CARD_TOP, CARD_WD, CARD_HT)

func _rd_cell(g: int, e: int) -> Rect2:
	return Rect2(R_MATRIX.position.x + 244.0 + e * CELL_PX, R_MATRIX.position.y + 132.0 + g * CELL_PY, CELL_W, CELL_H)

func _rd_cell_of(d: Disc) -> Rect2:
	return _rd_cell(d.genre, d.era)

func _draw() -> void:
	_begin_draw()
	ui_live = true
	rd_hover = -1
	for i in rd_hand.size():
		if not rd_line.has(i) and _rd_card(i).has_point(mouse):
			rd_hover = i
	draw_rect(Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0), Color("2a2724"))
	_surface(Rect2(-800.0, 1000.0, UI_W + 1600.0, 640.0), 0.0, "wood", Color("6b4a32"), Color("4a3222"), 700.0)
	draw_rect(Rect2(-800.0, 1000.0, UI_W + 1600.0, 6.0), Color("8a6446"))
	var st := _rd_state()
	_rd_top_bar()
	_rd_matrix(st)
	_rd_ring(st)
	_rd_cards(st)
	_end_draw()

func _rd_top_bar() -> void:
	_heavy(Vector2(70.0, 84.0), "Ring demo", T_XL, Color("f4efe4"))
	_text_i(Vector2(340.0, 84.0), "Genre × decade map and a ring changer. A separate prototype; the main round is untouched.", T_MD, Color("b8c0cc"))
	var items := [
		["Undo", _rd_undo, not rd_line.is_empty(), Color("6a6f77"), 150.0],
		["Reset set", _rd_reset, not rd_line.is_empty(), Color("6a6f77"), 190.0],
		["Deal 3×3", _rd_deal.bind(false), true, Color("c9a227"), 200.0],
		["Deal wide", _rd_deal.bind(true), true, Color("c9a227"), 200.0],
		["Label maker", _rd_toggle_label, true, Color("3f9b5a") if rd_label else Color("3d4148"), 250.0],
	]
	var x := UI_W - 70.0
	for k in range(items.size() - 1, -1, -1):
		var it: Array = items[k]
		x -= float(it[4])
		_hw_button(Rect2(x, 40.0, float(it[4]), 60.0), String(it[0]), it[1], bool(it[2]), it[3], T_SM)
		x -= 14.0

func _rd_chip(center: Vector2, text: String, col: Color, size: int = T_XS) -> void:
	var w := _text_w(text, size, true) + 22.0
	var r := Rect2(center - Vector2(w * 0.5, (size + 14.0) * 0.5), Vector2(w, size + 14.0))
	_panel(r, col, 8, Color(0, 0, 0, 0.45), 1)
	var ink := Color.WHITE if col.get_luminance() < 0.6 else INK
	_text_center(r, text, size, ink, true)

func _rd_plate(r: Rect2) -> void:
	_shadow(r, 10, 10.0)
	_brushed(r, 10.0, Color("b4b9bf"), 53)
	for ex in [r.position.x + 18.0, r.end.x - 18.0]:
		for ey in [r.position.y + 18.0, r.end.y - 18.0]:
			_screw(Vector2(ex, ey), 7.0)

func _rd_matrix(st: Dictionary) -> void:
	var P := R_MATRIX
	_rd_plate(P)
	_silk(Vector2(P.position.x + 50.0, P.position.y + 52.0), "GENRE × DECADE MAP", T_MD, INK)
	_silk(Vector2(P.end.x - 50.0 - _text_w("NOT A BOARD · IT SHOWS THE SET'S PATH", 13, true), P.position.y + 50.0), "NOT A BOARD · IT SHOWS THE SET'S PATH", 13, Color("3d4148"))
	var W := Rect2(P.position.x + 30.0, P.position.y + 76.0, P.size.x - 60.0, P.size.y - 106.0)
	_inset(W, 8.0, Color("0b0d10"))
	var has_cur := not rd_line.is_empty()
	var cur := rd_hand[rd_line.back()] if has_cur else null
	var op := rd_hand[rd_line[0]] if has_cur else null
	var closing := rd_line.size() == RD_SET - 1
	var seqs := {}
	for i in rd_line.size():
		var d := rd_hand[rd_line[i]]
		var k := d.genre * 10 + d.era
		if not seqs.has(k):
			seqs[k] = []
		seqs[k].append(i + 1)
	var owned := {}
	for i in rd_hand.size():
		if not rd_line.has(i):
			var k := rd_hand[i].genre * 10 + rd_hand[i].era
			owned[k] = int(owned.get(k, 0)) + 1
	for e in D.ERAS.size():
		var hr := _rd_cell(0, e)
		_text_center(Rect2(hr.position.x, W.position.y + 14.0, CELL_W, 40.0), D.ERAS[e], T_MD, Color("aab0b8"), true)
	for g in D.GENRES.size():
		var gr := _rd_cell(g, 0)
		var gc := Color(D.GENRE_COLORS[g]).lightened(0.3)
		draw_circle(Vector2(W.position.x + 34.0, gr.get_center().y), 7.0, gc)
		_silk(Vector2(W.position.x + 54.0, gr.get_center().y + 7.0), String(D.GENRES[g]).to_upper(), T_SM, Color("aab0b8"))
	var pulse := 0.55 + 0.45 * sin(clock * 5.0)
	for g in D.GENRES.size():
		for e in D.ERAS.size():
			var r := _rd_cell(g, e)
			var k := g * 10 + e
			var gc := Color(D.GENRE_COLORS[g]).lightened(0.25)
			_panel(r, Color("14181d"), 6, Color(1, 1, 1, 0.05), 1)
			var on_cur := has_cur and (g == cur.genre or e == cur.era)
			var on_op := has_cur and (g == op.genre or e == op.era)
			if on_cur:
				_panel(r, Color(Color(D.FLOW_COLOR), 0.12), 6)
			if on_op:
				_panel(r, Color(GOLD, 0.12), 6)
			var n := int(owned.get(k, 0))
			for q in mini(n, 4):
				draw_circle(Vector2(r.position.x + 16.0 + q * 16.0, r.end.y - 14.0), 5.0, Color(gc, 0.85))
			if n > 0 and on_cur and not closing:
				_panel(r, Color(0, 0, 0, 0), 6, Color(Color(D.FLOW_COLOR), 0.5 + 0.5 * pulse), 3)
			if closing and n > 0 and on_op:
				_panel(r, Color(0, 0, 0, 0), 6, Color(GOLD, 0.5 + 0.5 * pulse), 4)
				_text_center(Rect2(r.position.x, r.position.y + 4.0, r.size.x, 24.0), "CLOSE", 14, Color(GOLD, 0.6 + 0.4 * pulse), true)
			if seqs.has(k):
				var is_cur := has_cur and cur.genre == g and cur.era == e
				var glow := 0.55 + 0.45 * sin(clock * 7.0) if is_cur else 1.0
				_panel(r.grow(6.0), Color(gc, 0.2 * glow), 10)
				_grad_panel(r, 6.0, gc.lightened(0.15), gc.darkened(0.35))
				_panel(r, Color(0, 0, 0, 0), 6, Color(1, 1, 1, 0.55 * glow), 2)
				var label := "·".join((seqs[k] as Array).map(func(v): return str(v)))
				var bw := _text_w(label, T_MD, true) + 20.0
				var br := Rect2(r.end.x - bw - 8.0, r.position.y + 8.0, bw, 32.0)
				_panel(br, Color(0, 0, 0, 0.6), 12)
				_text_center(br, label, T_MD, Color.WHITE, true)
				if (seqs[k] as Array).has(1):
					_text(r.position + Vector2(8.0, 20.0), "OPEN", 13, Color(1, 1, 1, 0.9), true)
	var links: Array = st["links"]
	for i in range(1, rd_line.size()):
		var a := _rd_cell_of(rd_hand[rd_line[i - 1]]).get_center()
		var b := _rd_cell_of(rd_hand[rd_line[i]]).get_center()
		if a.distance_to(b) < 1.0:
			continue
		var col := Color(D.FLOW_COLOR).lightened(0.35) if links[i] else c_bad.lightened(0.2)
		draw_line(a, b, Color(0, 0, 0, 0.5), 9.0, true)
		draw_line(a, b, col, 5.0, true)
		var dir := (b - a).normalized()
		var m := (a + b) * 0.5
		var side := dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([m + dir * 14.0, m - dir * 10.0 + side * 11.0, m - dir * 10.0 - side * 11.0]), col)
	if bool(st["ring"]):
		var a2 := _rd_cell_of(rd_hand[rd_line.back()]).get_center()
		var b2 := _rd_cell_of(rd_hand[rd_line[0]]).get_center()
		if a2.distance_to(b2) > 1.0:
			draw_dashed_line(a2, b2, GOLD, 6.0, 14.0)
	if rd_hover >= 0 and not rd_label and rd_line.size() < RD_SET:
		var hd := rd_hand[rd_hover]
		var hr2 := _rd_cell_of(hd)
		if has_cur:
			var c0 := _rd_cell_of(cur).get_center()
			if c0.distance_to(hr2.get_center()) > 1.0:
				draw_dashed_line(c0, hr2.get_center(), Color(1, 1, 1, 0.75), 4.0, 10.0)
		if closing and _rd_link(hd, op):
			var c1 := _rd_cell_of(op).get_center()
			if c1.distance_to(hr2.get_center()) > 1.0:
				draw_dashed_line(hr2.get_center(), c1, Color(GOLD, 0.9), 4.0, 10.0)
		_panel(hr2.grow(5.0), Color(0, 0, 0, 0), 9, Color(1, 1, 1, 0.5 + 0.5 * pulse), 4)

func _rd_ring_pos(i: int) -> Vector2:
	return RING_C + Vector2.from_angle(-PI * 0.5 + TAU / RD_SET * i) * RING_R

func _rd_ring(st: Dictionary) -> void:
	var P := R_RING
	_rd_plate(P)
	_silk(Vector2(P.position.x + 50.0, P.position.y + 52.0), "RING CHANGER", T_MD, INK)
	var flows: Array = st["flows"]
	var links: Array = st["links"]
	var pts: Array = st["pts"]
	var bonus: Array = st["bonus"]
	var ring := bool(st["ring"])
	var n := rd_line.size()
	var pulse := 0.55 + 0.45 * sin(clock * 5.0)
	draw_arc(RING_C, RING_R, 0.0, TAU, 160, Color("0d0f12"), 40.0, true)
	draw_arc(RING_C, RING_R + 20.0, 0.0, TAU, 160, Color(1, 1, 1, 0.25), 2.0, true)
	draw_arc(RING_C, RING_R - 20.0, 0.0, TAU, 160, Color(0, 0, 0, 0.5), 2.0, true)
	for i in RD_SET:
		var a0 := -PI * 0.5 + TAU / RD_SET * i + 0.42
		var a1 := -PI * 0.5 + TAU / RD_SET * (i + 1) - 0.42
		var closing_seg := i == RD_SET - 1
		var col := Color(0, 0, 0, 0)
		var live := false
		if closing_seg:
			if n == RD_SET:
				live = true
				col = GOLD if ring else c_bad
			elif n == RD_SET - 1:
				col = Color(GOLD, 0.25 + 0.3 * pulse)
				live = true
		elif i + 1 < n:
			live = true
			col = Color(D.FLOW_COLOR).lightened(0.3) if links[i + 1] else c_bad
		if live:
			for q in 3:
				draw_arc(RING_C, RING_R, a0, a1, 24, Color(col, 0.12 / (q + 1)), 18.0 + q * 12.0, true)
			draw_arc(RING_C, RING_R, a0, a1, 24, col, 10.0, true)
		else:
			draw_arc(RING_C, RING_R, a0, a1, 24, Color(1, 1, 1, 0.07), 8.0, true)
	for i in RD_SET:
		var pos := _rd_ring_pos(i)
		var out := Vector2.from_angle(-PI * 0.5 + TAU / RD_SET * i)
		if i < n:
			var d := rd_hand[rd_line[i]]
			_cd_art(pos, SLOT_R, _cover_tex(d.cover), clock * 0.6 if i == n - 1 else 0.0)
			var f := int(flows[i])
			var fc := GOLD if f > D.FLOW_MAX else (Color(D.FLOW_COLOR).lightened(0.2) if f > 1 else c_bad.lightened(0.2))
			_rd_chip(pos + out * (SLOT_R + 32.0), "%d × %d" % [int(pts[i]), f], fc, T_SM)
			if bool(bonus[i]):
				_rd_chip(pos + out * (SLOT_R + 32.0) + Vector2(0.0, 34.0 if out.y > 0.3 else -34.0), "OPENER +3" if i == 0 else "CLOSER +3", GOLD, 13)
		else:
			var open := i == n
			draw_circle(pos, SLOT_R + 6.0, Color("0d0f12"))
			draw_circle(pos, SLOT_R - 4.0, Color("1c1f24"))
			draw_arc(pos, SLOT_R - 4.0, 0.0, TAU, 48, Color(GOLD, 0.25 + 0.6 * pulse) if open else Color(1, 1, 1, 0.12), 4.0 if open else 2.0, true)
			_heavy_center(Rect2(pos - Vector2(SLOT_R, SLOT_R), Vector2(SLOT_R, SLOT_R) * 2.0), str(i + 1), T_HERO, Color(1, 1, 1, 0.5 if open else 0.18))
	var cf := int(flows.back()) if n > 0 else 0
	var lcd_col := GOLD if cf > D.FLOW_MAX else Color(D.FLOW_COLOR).lightened(0.2)
	_silk(Vector2(RING_C.x - 110.0, RING_C.y - 112.0), "FLOW", T_SM, INK)
	_lcd(Rect2(RING_C.x - 110.0, RING_C.y - 98.0, 220.0, 96.0), "×%d" % cf if n > 0 else "–", lcd_col, 64, "×8")
	for k in D.FLOW_MAX + 1:
		var on := 1.0 if k < cf else 0.0
		_led(Vector2(RING_C.x + (k - 2) * 46.0, RING_C.y + 36.0), 9.0, GOLD if k == D.FLOW_MAX else Color(D.FLOW_COLOR), on)
	var ring_on := 1.0 if ring else (0.3 + 0.7 * pulse if n == RD_SET - 1 else 0.0)
	_led(Vector2(RING_C.x - 56.0, RING_C.y + 94.0), 11.0, GOLD, ring_on)
	_silk(Vector2(RING_C.x - 32.0, RING_C.y + 104.0), "RING CLOSED" if ring else "RING", T_SM, INK)
	var lx := P.end.x - 430.0
	_silk(Vector2(lx, P.position.y + 100.0), "READING THE MAP", T_SM, INK)
	var legend := [
		["played", "Played, numbered in order"],
		["now", "Last played, blinking"],
		["keep", "A CD here keeps the flow"],
		["band", "Row and column of the last CD"],
		["open", "Row and column of the opener"],
		["close", "A CD here closes the ring"],
		["hand", "CDs left in your hand"],
	]
	var ly := P.position.y + 130.0
	for it: Array in legend:
		_rd_swatch(String(it[0]), Rect2(lx, ly, 64.0, 44.0))
		_text(Vector2(lx + 82.0, ly + 29.0), String(it[1]), T_SM, INK, true)
		ly += 62.0
	var rules := "Closing the ring: the last CD shares a genre or decade with the opener. +1 flow, and the cap rises from ×4 to ×5."
	_wrap(Vector2(lx, ly + 22.0), rules, 400.0, 18, Color("3d4148"), true, 4)
	var msg := ""
	var keeps := 0
	var closes := 0
	for i in rd_hand.size():
		if _rd_keeps(i):
			keeps += 1
		if _rd_closes(i):
			closes += 1
	match n:
		0:
			msg = "Pick an opener. Its row and column on the map decide where the ring can close."
		RD_SET:
			msg = "Set complete. %s Total %d." % ["The ring closed." if ring else "The ring stayed open.", int(st["total"])]
		RD_SET - 1:
			msg = "Slot 5: %d %s close the ring and %d keep the flow." % [closes, "CD" if closes == 1 else "CDs", keeps]
		_:
			msg = "Slot %d: %d %s keep the flow." % [n + 1, keeps, "CD keeps" if keeps == 1 else "CDs keep"]
	_wrap(Vector2(P.position.x + 50.0, P.end.y - 66.0), msg, P.size.x - 480.0, T_MD, INK, true, 2)
	_silk(Vector2(P.end.x - 410.0, P.end.y - 92.0), "SET SCORE", T_SM, INK)
	_lcd(Rect2(P.end.x - 410.0, P.end.y - 78.0, 360.0, 52.0), str(int(st["total"])), Color(D.SOUND_COLOR).lightened(0.3), 36, "8888")

func _rd_swatch(kind: String, r: Rect2) -> void:
	var gc := Color(D.GENRE_COLORS[5]).lightened(0.25)
	var pulse := 0.55 + 0.45 * sin(clock * 5.0)
	_panel(r, Color("14181d"), 6, Color(1, 1, 1, 0.05), 1)
	match kind:
		"played":
			_grad_panel(r, 6.0, gc.lightened(0.15), gc.darkened(0.35))
			_panel(r, Color(0, 0, 0, 0), 6, Color(1, 1, 1, 0.55), 2)
			_heavy_center(r, "2", T_LG, Color.WHITE)
		"now":
			var glow := 0.55 + 0.45 * sin(clock * 7.0)
			_panel(r.grow(5.0), Color(gc, 0.2 * glow), 10)
			_grad_panel(r, 6.0, gc.lightened(0.15), gc.darkened(0.35))
			_panel(r, Color(0, 0, 0, 0), 6, Color(1, 1, 1, 0.55 * glow), 2)
			_heavy_center(r, "3", T_LG, Color.WHITE)
		"keep":
			_panel(r, Color(Color(D.FLOW_COLOR), 0.12), 6)
			_panel(r, Color(0, 0, 0, 0), 6, Color(Color(D.FLOW_COLOR), 0.5 + 0.5 * pulse), 3)
			draw_circle(r.position + Vector2(14.0, r.size.y - 10.0), 4.0, Color(gc, 0.85))
		"band":
			_panel(r, Color(Color(D.FLOW_COLOR), 0.22), 6)
		"open":
			_panel(r, Color(GOLD, 0.22), 6)
		"close":
			_panel(r, Color(GOLD, 0.12), 6)
			_panel(r, Color(0, 0, 0, 0), 6, Color(GOLD, 0.5 + 0.5 * pulse), 4)
			draw_circle(r.position + Vector2(14.0, r.size.y - 10.0), 4.0, Color(gc, 0.85))
		"hand":
			for q in 3:
				draw_circle(r.position + Vector2(14.0 + q * 14.0, r.size.y - 10.0), 4.0, Color(gc, 0.85))

func _rd_cards(st: Dictionary) -> void:
	for i in rd_hand.size():
		var d := rd_hand[i]
		var slot := rd_line.find(i)
		var base := _rd_card(i)
		var lift := -14.0 if i == rd_hover or (rd_label and base.has_point(mouse)) else 0.0
		var r := Rect2(base.position + Vector2(0.0, lift), base.size)
		_shadow(r, 10, 10.0)
		_panel(r, Color("f4efe4"), 10)
		var art := Rect2(r.position + Vector2(14.0, 14.0), Vector2(CARD_WD - 28.0, CARD_WD - 28.0))
		var tex := _cover_tex(d.cover)
		if tex != null:
			draw_texture_rect(tex, art, false)
		else:
			_panel(art, Color(D.GENRE_COLORS[d.genre]), 6)
		_panel(art, Color(0, 0, 0, 0), 4, Color(0, 0, 0, 0.3), 1)
		var py := art.end.y + 24.0
		var gcol := Color(D.GENRE_COLORS[d.genre])
		var gp := Rect2(art.position.x, py - 15.0, _text_w(D.GENRE_SHORT[d.genre], T_XS, true) + 20.0, 30.0)
		_panel(gp, gcol, 12)
		_text_center(gp, D.GENRE_SHORT[d.genre], T_XS, Color.WHITE, true)
		var ep := Rect2(gp.end.x + 8.0, gp.position.y, _text_w(D.ERAS[d.era], T_XS, true) + 20.0, 30.0)
		_panel(ep, Color("5d626a"), 12)
		_text_center(ep, D.ERAS[d.era], T_XS, Color.WHITE, true)
		_text_right(art.end.x, py + 6.0, "%d pts" % d.sound, T_SM, c_muted, true)
		_wrap(Vector2(art.position.x, py + 33.0), d.title, art.size.x, T_SM, c_ink, true, 1)
		var tag := rd_tags[i]
		var ty := r.end.y - 26.0
		var tx := art.position.x
		if (tag & TAG_OPEN) != 0:
			var w := _text_w("OPENER", 13, true) + 20.0
			_panel(Rect2(tx, ty - 13.0, w, 26.0), GOLD, 10)
			_text_center(Rect2(tx, ty - 13.0, w, 26.0), "OPENER", 13, INK, true)
			tx += w + 8.0
		if (tag & TAG_CLOSE) != 0:
			var w2 := _text_w("CLOSER", 13, true) + 20.0
			_panel(Rect2(tx, ty - 13.0, w2, 26.0), Color("4a90d9"), 10)
			_text_center(Rect2(tx, ty - 13.0, w2, 26.0), "CLOSER", 13, Color.WHITE, true)
		if tag == 0:
			_text_i(Vector2(art.position.x, ty + 6.0), "no position tag", T_XS, c_muted)
		if rd_label:
			_text_right(art.end.x, ty + 6.0, "click to relabel", 13, c_good, true)
		if slot >= 0:
			_panel(r, Color(0.08, 0.07, 0.06, 0.72), 10)
			_heavy_center(r, "IN SLOT %d" % (slot + 1), T_XL, Color("f4efe4"))
		else:
			if _rd_keeps(i):
				_rd_chip(art.position + Vector2(66.0, 26.0), "FLOW +1", Color(D.FLOW_COLOR).lightened(0.1))
			if _rd_closes(i):
				_rd_chip(art.position + Vector2(78.0, 66.0), "CLOSES RING", GOLD)
		_register(base, _rd_click.bind(i))
