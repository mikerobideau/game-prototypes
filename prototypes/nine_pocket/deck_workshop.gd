extends Control

const D := preload("res://prototypes/nine_pocket/nine_pocket_data.gd")
const DECKS_PATH := "res://prototypes/nine_pocket/data/decks.json"
const CARDS_PATH := "res://prototypes/nine_pocket/data/cards.json"
const MAX_COUNT := 20
const MAX_MIXES := 12
const BG := Color("1b1d21")
const PANEL := Color("23272d")
const EDGE := Color("353a42")
const ACCENT := Color("6fa8dc")
const MUTED := Color("8d939b")
const TEXT := Color("e8ecf2")
const GOOD := Color("6aa84f")
const BAD := Color("e07a5f")

var decks: Array = []
var cards: Array = []
var sel := -1
var shown: Array[int] = []
var dirty := false
var loading := false
var filling := false
var warn_decks: Array[int] = []

var flt_state: OptionButton
var list: ItemList
var count_label: Label
var f_id: LineEdit
var f_name: LineEdit
var f_idea: LineEdit
var f_enabled: CheckBox
var f_mixes: SpinBox
var f_summary: Label
var c_search: LineEdit
var c_genre: OptionButton
var c_only: CheckBox
var tree: Tree
var warn_list: ItemList
var warn_badge: Label
var warn_badge_panel: PanelContainer
var status: Label
var confirm: ConfirmationDialog

func _sb(bg: Color, border: Color, radius: int = 4, pad: float = 6.0) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(1)
	b.set_corner_radius_all(radius)
	b.content_margin_left = pad + 4.0
	b.content_margin_right = pad + 4.0
	b.content_margin_top = pad
	b.content_margin_bottom = pad
	return b

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 15
	for cls in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", cls, _sb(Color("30343b"), Color("454b55")))
		t.set_stylebox("hover", cls, _sb(Color("3b4048"), Color("7a808a")))
		t.set_stylebox("pressed", cls, _sb(Color("282b31"), Color("9aa0a8")))
		t.set_stylebox("disabled", cls, _sb(Color("272a30"), Color("353a42")))
		t.set_stylebox("focus", cls, _sb(Color(0, 0, 0, 0), ACCENT))
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_hover_color", cls, Color.WHITE)
		t.set_color("font_pressed_color", cls, Color.WHITE)
		t.set_color("font_disabled_color", cls, Color("6a6f77"))
	for cls in ["LineEdit", "TextEdit"]:
		t.set_stylebox("normal", cls, _sb(Color("18191d"), EDGE))
		t.set_stylebox("read_only", cls, _sb(Color("1e2024"), Color("2b2e34")))
		t.set_stylebox("focus", cls, _sb(Color("18191d"), ACCENT))
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_uneditable_color", cls, MUTED)
		t.set_color("caret_color", cls, Color.WHITE)
	for cls in ["ItemList", "Tree"]:
		t.set_stylebox("panel", cls, _sb(Color("18191d"), EDGE))
		t.set_stylebox("focus", cls, _sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
		t.set_stylebox("selected", cls, _sb(Color("2d4a66"), ACCENT))
		t.set_stylebox("selected_focus", cls, _sb(Color("2d4a66"), ACCENT))
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_selected_color", cls, Color.WHITE)
	t.set_color("title_button_color", "Tree", ACCENT)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "CheckBox", TEXT)
	return t

func _ready() -> void:
	theme = _make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_load_cards()
	_load_decks()
	_refresh_all()

func _unhandled_key_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and k.ctrl_pressed and k.keycode == KEY_S:
		_save()
		get_viewport().set_input_as_handled()

func _label(t: String, col: Color = TEXT, size: int = 0) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", col)
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	return l

func _opt(items: Array, with_all: String = "") -> OptionButton:
	var o := OptionButton.new()
	if with_all != "":
		o.add_item(with_all)
	for it in items:
		o.add_item(String(it))
	return o

func _button(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(cb)
	return b

func _box(parent: Node, bg: Color = PANEL, pad: float = 12.0) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(bg, EDGE, 8, pad))
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	return v

func _section(parent: Control, title: String) -> GridContainer:
	parent.add_child(_label(title.to_upper(), ACCENT, 14))
	parent.add_child(HSeparator.new())
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 8)
	parent.add_child(g)
	return g

func _row(grid: GridContainer, label: String, w: Control) -> void:
	var l := _label(label, Color("a8afb8"), 14)
	l.custom_minimum_size = Vector2(110.0, 0.0)
	grid.add_child(l)
	w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(w)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(_label("DECK WORKSHOP", TEXT, 20))
	warn_badge_panel = PanelContainer.new()
	warn_badge_panel.add_theme_stylebox_override("panel", _sb(Color("3a3d42"), Color("3a3d42"), 10, 2.0))
	warn_badge = _label("", Color.WHITE, 13)
	warn_badge_panel.add_child(warn_badge)
	top.add_child(warn_badge_panel)
	status = _label("", Color("a8afb8"), 14)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(status)
	top.add_child(_button("Reload from disk", _on_reload))
	var save := _button("Save  (Ctrl+S)", _save)
	save.add_theme_stylebox_override("normal", _sb(Color("2f7d4f"), Color("43a06a")))
	save.add_theme_stylebox_override("hover", _sb(Color("379259"), Color("5cc084")))
	save.add_theme_stylebox_override("pressed", _sb(Color("286b44"), Color("43a06a")))
	top.add_child(save)
	root.add_child(top)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var left_box := _box(body)
	left_box.get_parent().custom_minimum_size = Vector2(340.0, 0.0)
	left_box.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lh := HBoxContainer.new()
	lh.add_child(_label("DECKS", ACCENT, 14))
	count_label = _label("", Color("a8afb8"), 13)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lh.add_child(count_label)
	left_box.add_child(lh)
	flt_state = _opt(["Enabled", "Disabled"], "All states")
	flt_state.item_selected.connect(func(_i: int) -> void: _refresh_list())
	left_box.add_child(flt_state)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(_on_list_selected)
	left_box.add_child(list)
	var lb := HBoxContainer.new()
	lb.add_theme_constant_override("separation", 6)
	lb.add_child(_button("New deck", _on_new))
	lb.add_child(_button("Duplicate", _on_duplicate))
	lb.add_child(_button("Delete", _on_delete))
	left_box.add_child(lb)
	confirm = ConfirmationDialog.new()
	confirm.confirmed.connect(_delete_selected)
	add_child(confirm)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	body.add_child(right)

	var id_box := _box(right)
	var g1 := _section(id_box, "Deck")
	f_id = LineEdit.new()
	f_id.editable = false
	_row(g1, "ID", f_id)
	f_name = LineEdit.new()
	f_name.text_changed.connect(_on_edit)
	_row(g1, "Name", f_name)
	f_idea = LineEdit.new()
	f_idea.placeholder_text = "One line shown on the deck screen"
	f_idea.text_changed.connect(_on_edit)
	_row(g1, "Description", f_idea)
	f_enabled = CheckBox.new()
	f_enabled.text = "Appears on the deck screen (untick to keep it as a draft)"
	f_enabled.toggled.connect(_on_edit)
	_row(g1, "Enabled", f_enabled)
	f_mixes = SpinBox.new()
	f_mixes.min_value = 0
	f_mixes.max_value = MAX_MIXES
	f_mixes.value_changed.connect(_on_edit)
	_row(g1, "Mixes", f_mixes)
	f_summary = _label("", Color("a8afb8"), 13)
	f_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	id_box.add_child(f_summary)

	var cards_box := _box(right)
	cards_box.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_box.add_child(_label("CARDS  (set how many copies of each card the deck starts with)", ACCENT, 14))
	var cf := HBoxContainer.new()
	cf.add_theme_constant_override("separation", 6)
	c_search = LineEdit.new()
	c_search.placeholder_text = "Search title or band"
	c_search.clear_button_enabled = true
	c_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_search.text_changed.connect(func(_t: String) -> void: _fill_tree())
	cf.add_child(c_search)
	c_genre = _opt(D.GENRES, "All genres")
	c_genre.item_selected.connect(func(_i: int) -> void: _fill_tree())
	cf.add_child(c_genre)
	c_only = CheckBox.new()
	c_only.text = "Only cards in this deck"
	c_only.toggled.connect(func(_b: bool) -> void: _fill_tree())
	cf.add_child(c_only)
	cards_box.add_child(cf)
	tree = Tree.new()
	tree.columns = 6
	tree.column_titles_visible = true
	tree.hide_root = true
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var heads := ["Card", "Genre", "Decade", "Rarity", "Points", "Copies"]
	for i in heads.size():
		tree.set_column_title(i, heads[i])
		tree.set_column_expand(i, i == 0)
		tree.set_column_custom_minimum_width(i, 90 if i > 0 else 200)
	tree.item_edited.connect(_on_tree_edited)
	cards_box.add_child(tree)

	var warn_box := _box(right)
	warn_box.add_child(_label("CHECKS", ACCENT, 14))
	warn_list = ItemList.new()
	warn_list.custom_minimum_size = Vector2(0.0, 90.0)
	warn_list.item_selected.connect(_on_warn_selected)
	warn_box.add_child(warn_list)

func _say(t: String) -> void:
	status.text = t

func _read_file(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Array else []

func _load_cards() -> void:
	cards = _read_file(CARDS_PATH)

func _load_decks() -> void:
	decks = _read_file(DECKS_PATH)
	for dk: Dictionary in decks:
		var src: Dictionary = dk.get("cards", {})
		var counts := {}
		for k in src.keys():
			counts[String(k)] = int(src[k])
		dk["cards"] = counts
		dk["mixes"] = int(dk.get("mixes", 0))
		dk["enabled"] = bool(dk.get("enabled", true))
		dk["idea"] = String(dk.get("idea", ""))
	sel = 0 if not decks.is_empty() else -1
	_set_dirty(false)

func _set_dirty(v: bool) -> void:
	dirty = v
	get_window().title = "Deck Workshop%s" % (" *" if dirty else "")

func _card(id: String) -> Dictionary:
	for c: Dictionary in cards:
		if String(c["id"]) == id:
			return c
	return {}

func _is_enabled(dk: Dictionary) -> bool:
	return bool(dk.get("enabled", true))

func _size_of(dk: Dictionary) -> int:
	var n := 0
	for k in (dk["cards"] as Dictionary).keys():
		n += int(dk["cards"][k])
	return n

func _row_text(dk: Dictionary) -> String:
	var t := "%s   ·   %d CDs   ·   %d mixes" % [dk["name"], _size_of(dk), int(dk["mixes"])]
	return t if _is_enabled(dk) else "(draft)  " + t

func _refresh_all() -> void:
	_refresh_list()
	_load_form()
	_fill_tree()
	_refresh_warnings()

func _refresh_list() -> void:
	list.clear()
	shown.clear()
	for i in decks.size():
		var dk: Dictionary = decks[i]
		if flt_state.selected == 1 and not _is_enabled(dk):
			continue
		if flt_state.selected == 2 and _is_enabled(dk):
			continue
		shown.append(i)
		list.add_item(_row_text(dk))
		if i == sel:
			list.select(list.item_count - 1)
	count_label.text = "%d of %d" % [shown.size(), decks.size()]

func _on_list_selected(idx: int) -> void:
	_read_form()
	sel = shown[idx]
	_load_form()
	_fill_tree()
	_refresh_warnings()

func _load_form() -> void:
	loading = true
	if sel < 0 or sel >= decks.size():
		f_id.text = ""
		f_name.text = ""
		f_idea.text = ""
		f_enabled.button_pressed = false
		f_mixes.value = 0
		f_summary.text = ""
		loading = false
		return
	var dk: Dictionary = decks[sel]
	f_id.text = String(dk["id"])
	f_name.text = String(dk["name"])
	f_idea.text = String(dk["idea"])
	f_enabled.button_pressed = _is_enabled(dk)
	f_mixes.value = float(dk["mixes"])
	loading = false
	_update_summary()

func _read_form() -> void:
	if loading or sel < 0 or sel >= decks.size():
		return
	var dk: Dictionary = decks[sel]
	dk["name"] = f_name.text
	dk["idea"] = f_idea.text
	dk["enabled"] = f_enabled.button_pressed
	dk["mixes"] = int(f_mixes.value)

func _on_edit(_v = null) -> void:
	if loading:
		return
	_read_form()
	_set_dirty(true)
	_after_change()

func _after_change() -> void:
	_update_summary()
	_refresh_warnings()
	var row := shown.find(sel)
	if row >= 0:
		list.set_item_text(row, _row_text(decks[sel]))
	if flt_state.selected > 0:
		_refresh_list()

func _update_summary() -> void:
	if sel < 0 or sel >= decks.size():
		f_summary.text = ""
		return
	var dk: Dictionary = decks[sel]
	var by_genre := {}
	var by_era := {}
	var pts := 0
	var n := 0
	for id in (dk["cards"] as Dictionary).keys():
		var c := _card(String(id))
		var k := int(dk["cards"][id])
		if c.is_empty() or k <= 0:
			continue
		by_genre[String(c["genre"])] = int(by_genre.get(String(c["genre"]), 0)) + k
		by_era[String(c["decade"])] = int(by_era.get(String(c["decade"]), 0)) + k
		pts += int(c["points"]) * k
		n += k
	var gt := ", ".join(D.GENRES.filter(func(g): return by_genre.has(g)).map(func(g): return "%s %d" % [g, by_genre[g]]))
	var et := ", ".join(D.ERAS.filter(func(e): return by_era.has(e)).map(func(e): return "%s %d" % [e, by_era[e]]))
	var avg := "%.1f" % (float(pts) / float(n)) if n > 0 else "-"
	f_summary.text = "%d CDs and %d mixes.  Average base points %s.\nGenres: %s\nDecades: %s" % [n, int(dk["mixes"]), avg, gt if gt != "" else "none", et if et != "" else "none"]

func _fill_tree() -> void:
	filling = true
	tree.clear()
	var root := tree.create_item()
	if sel >= 0 and sel < decks.size():
		var dk: Dictionary = decks[sel]
		var counts: Dictionary = dk["cards"]
		var q := c_search.text.strip_edges().to_lower()
		for c: Dictionary in cards:
			var id := String(c["id"])
			var have := int(counts.get(id, 0))
			if c_only.button_pressed and have == 0:
				continue
			if c_genre.selected > 0 and String(c["genre"]) != D.GENRES[c_genre.selected - 1]:
				continue
			if q != "" and not (String(c["title"]).to_lower().contains(q) or String(c.get("band", "")).to_lower().contains(q)):
				continue
			var it := tree.create_item(root)
			var band := String(c.get("band", ""))
			it.set_text(0, String(c["title"]) if band == "" else "%s  (%s)" % [c["title"], band])
			it.set_text(1, String(c["genre"]))
			it.set_text(2, String(c["decade"]))
			it.set_text(3, String(c["rarity"]))
			it.set_text(4, str(int(c["points"])))
			_set_count_cell(it, id, have)
		for id in counts.keys():
			if not _card(String(id)).is_empty():
				continue
			var it := tree.create_item(root)
			it.set_text(0, "(missing)  %s" % id)
			it.set_custom_color(0, BAD)
			_set_count_cell(it, String(id), int(counts[id]))
	filling = false

func _set_count_cell(it: TreeItem, id: String, have: int) -> void:
	it.set_metadata(0, id)
	it.set_cell_mode(5, TreeItem.CELL_MODE_RANGE)
	it.set_range_config(5, 0, MAX_COUNT, 1)
	it.set_range(5, have)
	it.set_editable(5, true)
	if have > 0:
		it.set_custom_color(5, GOOD)

func _on_tree_edited() -> void:
	if filling or sel < 0 or sel >= decks.size():
		return
	var it := tree.get_edited()
	if it == null:
		return
	var id := String(it.get_metadata(0))
	var v := int(it.get_range(5))
	var counts: Dictionary = decks[sel]["cards"]
	if v > 0:
		counts[id] = v
	else:
		counts.erase(id)
	it.set_custom_color(5, GOOD if v > 0 else TEXT)
	_set_dirty(true)
	_after_change()

func _slug(t: String) -> String:
	var out := ""
	for ch in t.to_lower():
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	while out.contains("__"):
		out = out.replace("__", "_")
	out = out.strip_edges().trim_prefix("_").trim_suffix("_")
	return out if out != "" else "deck"

func _unique_id(name: String) -> String:
	var base := _slug(name)
	var id := base
	var n := 2
	while decks.any(func(d): return String(d["id"]) == id):
		id = "%s_%d" % [base, n]
		n += 1
	return id

func _add_deck(dk: Dictionary) -> void:
	decks.append(dk)
	flt_state.select(0)
	sel = decks.size() - 1
	_set_dirty(true)
	_refresh_all()
	f_name.grab_focus()
	f_name.select_all()

func _on_new() -> void:
	_read_form()
	_add_deck({"id": _unique_id("New deck"), "name": "New deck", "idea": "", "enabled": false, "mixes": 0, "cards": {}})
	_say("Added a new deck. Name it, then set the copies of each card.")

func _on_duplicate() -> void:
	if sel < 0 or sel >= decks.size():
		return
	_read_form()
	var src: Dictionary = decks[sel]
	var dk: Dictionary = src.duplicate(true)
	dk["name"] = "%s copy" % src["name"]
	dk["id"] = _unique_id(String(dk["name"]))
	dk["enabled"] = false
	_add_deck(dk)
	_say("Duplicated %s." % src["name"])

func _on_delete() -> void:
	if sel < 0 or sel >= decks.size():
		return
	confirm.dialog_text = "Delete %s? This removes it from the game when you save." % decks[sel]["name"]
	confirm.popup_centered()

func _delete_selected() -> void:
	if sel < 0 or sel >= decks.size():
		return
	var nm := String(decks[sel]["name"])
	decks.remove_at(sel)
	sel = mini(sel, decks.size() - 1)
	_set_dirty(true)
	_refresh_all()
	_say("Deleted %s." % nm)

func _validate() -> Array:
	var out: Array = []
	var names := {}
	var enabled := 0
	for i in decks.size():
		var dk: Dictionary = decks[i]
		var nm := String(dk["name"]).strip_edges()
		if _is_enabled(dk):
			enabled += 1
		if nm == "":
			out.append({"text": "A deck has no name", "idx": i})
			nm = String(dk["id"])
		elif names.has(nm.to_lower()):
			out.append({"text": "%s: another deck has the same name" % nm, "idx": i})
		names[nm.to_lower()] = true
		var n := 0
		var missing := 0
		for id in (dk["cards"] as Dictionary).keys():
			if _card(String(id)).is_empty():
				missing += 1
			else:
				n += int(dk["cards"][id])
		if missing > 0:
			out.append({"text": "%s: %d card%s no longer exist in the card workshop (set to 0 copies to drop)" % [nm, missing, "" if missing == 1 else "s"], "idx": i})
		if n == 0:
			out.append({"text": "%s: has no cards" % nm, "idx": i})
		elif n < D.HAND:
			out.append({"text": "%s: only %d CDs, fewer than a hand of %d" % [nm, n, D.HAND], "idx": i})
		if _is_enabled(dk) and String(dk["idea"]).strip_edges() == "":
			out.append({"text": "%s: no description for the deck screen" % nm, "idx": i})
	if enabled == 0:
		out.append({"text": "No deck is enabled; the game will offer one deck with every card", "idx": -1})
	elif enabled > D.DECKS_SHOWN:
		out.append({"text": "%d decks are enabled but the deck screen shows only %d" % [enabled, D.DECKS_SHOWN], "idx": -1})
	return out

func _refresh_warnings() -> void:
	var problems := _validate()
	warn_list.clear()
	warn_decks.clear()
	for p: Dictionary in problems:
		warn_list.add_item(String(p["text"]))
		warn_decks.append(int(p["idx"]))
	var n := problems.size()
	warn_badge.text = "  %s  " % ("all clear" if n == 0 else "%d to check" % n)
	warn_badge_panel.add_theme_stylebox_override("panel", _sb(Color("2f7d4f") if n == 0 else Color("a05a2c"), Color("3a3d42"), 10, 2.0))

func _on_warn_selected(i: int) -> void:
	var idx := warn_decks[i]
	if idx < 0 or idx >= decks.size():
		return
	_read_form()
	sel = idx
	flt_state.select(0)
	_refresh_all()

func _clean_deck(dk: Dictionary) -> Dictionary:
	var counts := {}
	for id in (dk["cards"] as Dictionary).keys():
		if int(dk["cards"][id]) > 0:
			counts[String(id)] = int(dk["cards"][id])
	return {"id": String(dk["id"]), "name": String(dk["name"]), "idea": String(dk["idea"]), "enabled": _is_enabled(dk), "mixes": int(dk["mixes"]), "cards": counts}

func _save() -> void:
	_read_form()
	var out: Array = []
	for dk: Dictionary in decks:
		out.append(_clean_deck(dk))
	var f := FileAccess.open(DECKS_PATH, FileAccess.WRITE)
	if f == null:
		_say("Could not write %s" % DECKS_PATH)
		return
	f.store_string(JSON.stringify(out, "\t") + "\n")
	f.close()
	_set_dirty(false)
	_say("Saved %d decks." % out.size())

func _on_reload() -> void:
	_load_cards()
	_load_decks()
	_refresh_all()
	_say("Reloaded from disk.")
