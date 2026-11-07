extends Control

const D := preload("res://prototypes/dj_engine/dj_engine_data.gd")
const PREVIEW := preload("res://prototypes/dj_engine/card_preview.gd")
const CATALOG_PATH := "res://prototypes/dj_engine/data/cards.json"
const COVER_DIR := "res://prototypes/dj_engine/art/covers/"
const MUSIC_DIR := "res://prototypes/dj_engine/music/"
const RARITIES: Array[String] = ["common", "uncommon", "rare"]
const RARITY_COLORS := {"common": Color("6aa84f"), "uncommon": Color("3d85c6"), "rare": Color("c2689a")}
const CONDITIONS: Array[String] = ["always", "first", "last", "next_empty", "prev_empty", "per_empty", "odd", "even", "slot1", "slot2", "slot3", "slot4", "prev_is", "next_is", "per_before", "per_hand"]
const COND_NAMES := {
	"always": "Always",
	"first": "Played first",
	"last": "Played last",
	"next_empty": "The next slot is empty",
	"prev_empty": "The previous slot is empty",
	"per_empty": "For each empty slot",
	"odd": "In an odd slot",
	"even": "In an even slot",
	"slot1": "In slot 1",
	"slot2": "In slot 2",
	"slot3": "In slot 3",
	"slot4": "In slot 4",
	"prev_is": "The song before is...",
	"next_is": "The song after is...",
	"per_before": "For each earlier song of...",
	"per_hand": "For each song left in hand of...",
}
const COND_NEEDS_PARAM: Array[String] = ["prev_is", "next_is", "per_before", "per_hand"]
const EFFECT_KINDS: Array[String] = ["none", "points", "mult", "flow_add", "flow_mult", "cash", "copy", "consumable"]
const EFFECT_NAMES := {
	"none": "No effect",
	"points": "Add points",
	"mult": "Multiply the score",
	"flow_add": "Raise flow",
	"flow_mult": "Multiply flow",
	"cash": "Add cash",
	"copy": "Copy the previous song's effect",
	"consumable": "Make a consumable",
}
const TARGET_NAMES := {
	"self": "This song",
	"next": "The next song",
	"later": "Every later song",
	"later_genre": "Later songs of a genre",
	"later_decade": "Later songs of a decade",
	"set": "The whole set (flow)",
	"turn": "Start of next turn",
}
const COND_POWER := {"always": 1.0, "first": 0.6, "last": 0.6, "next_empty": 0.7, "prev_empty": 0.7, "per_empty": 0.9, "odd": 0.5, "even": 0.5, "slot1": 0.3, "slot2": 0.3, "slot3": 0.3, "slot4": 0.3, "prev_is": 0.45, "next_is": 0.45, "per_before": 1.6, "per_hand": 0.9}
const BG := Color("1b1d21")
const PANEL := Color("23272d")
const EDGE := Color("353a42")
const ACCENT := Color("6fa8dc")
const MUTED := Color("8d939b")
const TEXT := Color("e8ecf2")

var cards: Array = []
var sel := -1
var shown: Array[int] = []
var dirty := false
var loading := false
var thumbs := {}
var preview: Node2D
var player: AudioStreamPlayer

var f_search: LineEdit
var flt_genre: OptionButton
var flt_decade: OptionButton
var flt_cond: OptionButton
var flt_effect: OptionButton
var flt_rarity: OptionButton
var list: ItemList
var count_label: Label
var f_id: LineEdit
var f_title: LineEdit
var f_band: LineEdit
var f_genre: OptionButton
var f_decade: OptionButton
var f_rarity: OptionButton
var f_points: SpinBox
var f_cond: OptionButton
var f_cparam: OptionButton
var f_eff: OptionButton
var f_value: SpinBox
var f_tgt: OptionButton
var f_tparam: OptionButton
var f_cover: LineEdit
var f_song: LineEdit
var power_bar: ProgressBar
var power_label: Label
var f_text: Label
var heat := {}
var heat_row_totals := {}
var heat_col_totals := {}
var heat_grand: Label
var rar_count := {}
var rar_power := {}
var warn_list: ItemList
var warn_cards: Array[int] = []
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
	t.set_stylebox("panel", "ItemList", _sb(Color("18191d"), EDGE))
	t.set_stylebox("focus", "ItemList", _sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	t.set_stylebox("selected", "ItemList", _sb(Color("2d4a66"), ACCENT))
	t.set_stylebox("selected_focus", "ItemList", _sb(Color("2d4a66"), ACCENT))
	t.set_color("font_color", "ItemList", TEXT)
	t.set_color("font_selected_color", "ItemList", Color.WHITE)
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("background", "ProgressBar", _sb(Color("18191d"), EDGE, 6, 4.0))
	t.set_stylebox("fill", "ProgressBar", _sb(Color("3d85c6"), Color(0, 0, 0, 0), 6, 4.0))
	return t

func _ready() -> void:
	theme = _make_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	get_window().files_dropped.connect(_on_files_dropped)
	_load_catalog()
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

func _named(keys: Array, names: Dictionary) -> Array:
	var out: Array = []
	for k in keys:
		out.append(names[k])
	return out

func _button(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.pressed.connect(cb)
	return b

func _box(child_parent: Node, bg: Color = PANEL, pad: float = 12.0) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(bg, EDGE, 8, pad))
	child_parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	return v

func _section(parent: Control, title: String) -> GridContainer:
	var h := _label(title.to_upper(), ACCENT, 14)
	parent.add_child(h)
	parent.add_child(HSeparator.new())
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 8)
	parent.add_child(g)
	return g

func _row(grid: GridContainer, label: String, w: Control) -> void:
	var l := _label(label, Color("a8afb8"), 14)
	l.custom_minimum_size = Vector2(120.0, 0.0)
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
	top.add_child(_label("Card workshop", Color.WHITE, 22))
	warn_badge_panel = PanelContainer.new()
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
	left_box.get_parent().custom_minimum_size = Vector2(400.0, 0.0)
	left_box.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lh := HBoxContainer.new()
	lh.add_child(_label("LIBRARY", ACCENT, 13))
	count_label = _label("", Color("a8afb8"), 13)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lh.add_child(count_label)
	left_box.add_child(lh)
	f_search = LineEdit.new()
	f_search.placeholder_text = "Search title or band"
	f_search.clear_button_enabled = true
	f_search.text_changed.connect(func(_t: String) -> void: _refresh_list())
	left_box.add_child(f_search)
	var filters := GridContainer.new()
	filters.columns = 2
	filters.add_theme_constant_override("h_separation", 6)
	filters.add_theme_constant_override("v_separation", 6)
	left_box.add_child(filters)
	flt_genre = _opt(D.GENRES, "All genres")
	flt_decade = _opt(D.ERAS, "All decades")
	flt_cond = _opt(_named(CONDITIONS, COND_NAMES), "All conditions")
	flt_effect = _opt(_named(EFFECT_KINDS, EFFECT_NAMES), "All effects")
	flt_rarity = _opt(RARITIES, "All rarities")
	for o: OptionButton in [flt_genre, flt_decade, flt_cond, flt_effect, flt_rarity]:
		o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		o.item_selected.connect(func(_i: int) -> void: _refresh_list())
		filters.add_child(o)
	filters.add_child(_button("Clear filters", _clear_filters))
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.fixed_icon_size = Vector2i(52, 52)
	list.item_selected.connect(_on_list_selected)
	left_box.add_child(list)
	var lb := HBoxContainer.new()
	lb.add_theme_constant_override("separation", 6)
	lb.add_child(_button("New card", _on_new))
	lb.add_child(_button("Duplicate", _on_duplicate))
	lb.add_child(_button("Delete", _on_delete))
	left_box.add_child(lb)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 10)
	body.add_child(center)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svc.custom_minimum_size = Vector2(520.0, 420.0)
	var vp := SubViewport.new()
	svc.add_child(vp)
	preview = Node2D.new()
	preview.set_script(PREVIEW)
	vp.add_child(preview)
	center.add_child(svc)
	var sum := _box(center)
	var ph := HBoxContainer.new()
	ph.add_child(_label("RULE SUMMARY", ACCENT, 13))
	power_label = _label("", Color("a8afb8"), 14)
	power_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ph.add_child(power_label)
	sum.add_child(ph)
	f_text = _label("", TEXT, 15)
	f_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum.add_child(f_text)
	power_bar = ProgressBar.new()
	power_bar.max_value = 30.0
	power_bar.show_percentage = false
	power_bar.custom_minimum_size = Vector2(0.0, 14.0)
	sum.add_child(power_bar)

	var right_box := _box(body)
	right_box.get_parent().custom_minimum_size = Vector2(470.0, 0.0)
	right_box.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_box.add_child(scroll)
	var insp := VBoxContainer.new()
	insp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp.add_theme_constant_override("separation", 10)
	scroll.add_child(insp)

	var g1 := _section(insp, "Identity")
	f_id = LineEdit.new()
	f_id.editable = false
	_row(g1, "ID", f_id)
	f_title = LineEdit.new()
	_row(g1, "Title", f_title)
	f_band = LineEdit.new()
	_row(g1, "Band", f_band)
	f_genre = _opt(D.GENRES)
	_row(g1, "Genre", f_genre)
	f_decade = _opt(D.ERAS)
	_row(g1, "Decade", f_decade)
	f_rarity = _opt(RARITIES)
	_row(g1, "Rarity", f_rarity)
	var g2 := _section(insp, "Scoring")
	f_points = SpinBox.new()
	f_points.min_value = 0
	f_points.max_value = 99
	f_points.step = 1
	_row(g2, "Points", f_points)
	var g3 := _section(insp, "Rule")
	f_cond = _opt(_named(CONDITIONS, COND_NAMES))
	_row(g3, "Condition", f_cond)
	f_cparam = OptionButton.new()
	_row(g3, "Condition target", f_cparam)
	f_eff = _opt(_named(EFFECT_KINDS, EFFECT_NAMES))
	_row(g3, "Effect", f_eff)
	f_value = SpinBox.new()
	f_value.min_value = 0
	f_value.max_value = 99
	f_value.step = 0.25
	_row(g3, "Effect value", f_value)
	f_tgt = OptionButton.new()
	_row(g3, "Effect target", f_tgt)
	f_tparam = OptionButton.new()
	_row(g3, "Target filter", f_tparam)
	var g4 := _section(insp, "Assets")
	f_cover = LineEdit.new()
	f_cover.editable = false
	var cover_row := HBoxContainer.new()
	f_cover.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cover_row.add_child(f_cover)
	cover_row.add_child(_button("Browse", func() -> void: _browse("cover")))
	_row(g4, "Artwork", cover_row)
	f_song = LineEdit.new()
	f_song.editable = false
	var song_row := HBoxContainer.new()
	f_song.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	song_row.add_child(f_song)
	song_row.add_child(_button("Browse", func() -> void: _browse("song")))
	var music_row := VBoxContainer.new()
	music_row.add_child(song_row)
	var play_row := HBoxContainer.new()
	play_row.add_child(_button("Play", _play_song))
	play_row.add_child(_button("Stop", func() -> void: player.stop()))
	music_row.add_child(play_row)
	_row(g4, "Music", music_row)
	var hint := _label("Drop an image on the window to set the artwork (several images create new cards). Drop an mp3 to attach music to the selected card.", Color("a8afb8"), 13)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp.add_child(hint)

	f_title.text_changed.connect(_on_edit)
	f_band.text_changed.connect(_on_edit)
	f_genre.item_selected.connect(_on_edit)
	f_decade.item_selected.connect(_on_edit)
	f_rarity.item_selected.connect(_on_edit)
	f_points.value_changed.connect(_on_edit)
	f_cond.item_selected.connect(_on_cond_changed)
	f_cparam.item_selected.connect(_on_edit)
	f_eff.item_selected.connect(_on_effect_changed)
	f_value.value_changed.connect(_on_edit)
	f_tgt.item_selected.connect(_on_target_changed)
	f_tparam.item_selected.connect(_on_edit)

	var dock := PanelContainer.new()
	dock.add_theme_stylebox_override("panel", _sb(PANEL, EDGE, 8, 12.0))
	dock.custom_minimum_size = Vector2(0.0, 250.0)
	root.add_child(dock)
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 22)
	dock.add_child(dh)
	var heat_box := VBoxContainer.new()
	heat_box.add_theme_constant_override("separation", 6)
	dh.add_child(heat_box)
	heat_box.add_child(_label("COVERAGE BY GENRE AND DECADE  (click a cell to filter)", ACCENT, 13))
	var hg := GridContainer.new()
	hg.columns = D.ERAS.size() + 2
	hg.add_theme_constant_override("h_separation", 4)
	hg.add_theme_constant_override("v_separation", 4)
	heat_box.add_child(hg)
	hg.add_child(_label(""))
	for e in D.ERAS:
		var hl := _label(String(e), Color("a8afb8"), 14)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hg.add_child(hl)
	var tl := _label("Total", Color("a8afb8"), 14)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hg.add_child(tl)
	for gi in D.GENRES.size():
		var rl := _label(String(D.GENRES[gi]), Color("a8afb8"), 14)
		rl.custom_minimum_size = Vector2(120.0, 0.0)
		hg.add_child(rl)
		for di in D.ERAS.size():
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(60.0, 28.0)
			cell.add_theme_font_size_override("font_size", 15)
			cell.pressed.connect(_on_heat_clicked.bind(gi, di))
			hg.add_child(cell)
			heat["%d|%d" % [gi, di]] = cell
		var rt := _label("", TEXT, 14)
		rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hg.add_child(rt)
		heat_row_totals[gi] = rt
	hg.add_child(_label("Total", Color("a8afb8"), 14))
	for di in D.ERAS.size():
		var ct := _label("", TEXT, 14)
		ct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hg.add_child(ct)
		heat_col_totals[di] = ct
	heat_grand = _label("", Color.WHITE, 14)
	heat_grand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hg.add_child(heat_grand)

	var rar_box := VBoxContainer.new()
	rar_box.add_theme_constant_override("separation", 8)
	dh.add_child(rar_box)
	rar_box.add_child(_label("RARITY", ACCENT, 13))
	for r in RARITIES:
		var pc := PanelContainer.new()
		var sb := _sb(Color("1e2126"), EDGE, 6, 8.0)
		sb.border_width_left = 4
		sb.border_color = RARITY_COLORS[r]
		pc.add_theme_stylebox_override("panel", sb)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		pc.add_child(hb)
		var name_l := _label(String(r).capitalize(), TEXT, 15)
		name_l.custom_minimum_size = Vector2(90.0, 0.0)
		hb.add_child(name_l)
		var cl := _label("", Color.WHITE, 18)
		cl.custom_minimum_size = Vector2(36.0, 0.0)
		hb.add_child(cl)
		var pl := _label("", Color("a8afb8"), 13)
		hb.add_child(pl)
		rar_count[r] = cl
		rar_power[r] = pl
		rar_box.add_child(pc)

	var warn_box := VBoxContainer.new()
	warn_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warn_box.add_theme_constant_override("separation", 6)
	dh.add_child(warn_box)
	warn_box.add_child(_label("CHECKS  (click a warning to open the card)", ACCENT, 13))
	warn_list = ItemList.new()
	warn_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	warn_list.item_selected.connect(_on_warning_clicked)
	warn_box.add_child(warn_list)

	player = AudioStreamPlayer.new()
	add_child(player)
	confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Delete this card?"
	confirm.confirmed.connect(_delete_selected)
	add_child(confirm)

func _say(t: String) -> void:
	status.text = t

func _set_dirty(v: bool) -> void:
	dirty = v
	if v:
		_say("Unsaved changes")

func _clear_filters() -> void:
	f_search.text = ""
	for o: OptionButton in [flt_genre, flt_decade, flt_cond, flt_effect, flt_rarity]:
		o.select(0)
	_refresh_list()
	_refresh_stats()

func _on_heat_clicked(gi: int, di: int) -> void:
	var same := flt_genre.selected == gi + 1 and flt_decade.selected == di + 1
	flt_genre.select(0 if same else gi + 1)
	flt_decade.select(0 if same else di + 1)
	_refresh_list()
	_refresh_stats()

func _on_warning_clicked(idx: int) -> void:
	if idx >= 0 and idx < warn_cards.size() and warn_cards[idx] >= 0:
		_select_card(warn_cards[idx])

func _load_catalog() -> void:
	cards.clear()
	if FileAccess.file_exists(CATALOG_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
		if data is Array:
			cards = data
	sel = 0 if not cards.is_empty() else -1
	dirty = false
	_say("Loaded %d cards from %s" % [cards.size(), CATALOG_PATH])

func _save() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CATALOG_PATH.get_base_dir()))
	var f := FileAccess.open(CATALOG_PATH, FileAccess.WRITE)
	if f == null:
		_say("Could not write %s" % CATALOG_PATH)
		return
	f.store_string(JSON.stringify(cards, "\t", false))
	f.close()
	dirty = false
	_say("Saved %d cards" % cards.size())

func _on_reload() -> void:
	_load_catalog()
	_refresh_all()

func _refresh_all() -> void:
	_refresh_list()
	_load_form()
	_update_preview()
	_refresh_stats()

func _thumb(path: String) -> Texture2D:
	if thumbs.has(path):
		return thumbs[path]
	var tex: Texture2D = null
	if path != "":
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img:
			img.resize(52, 52, Image.INTERPOLATE_BILINEAR)
			tex = ImageTexture.create_from_image(img)
	thumbs[path] = tex
	return tex

func _refresh_list() -> void:
	var q := f_search.text.strip_edges().to_lower()
	list.clear()
	shown.clear()
	for i in cards.size():
		var c: Dictionary = cards[i]
		if q != "" and not (String(c.get("title", "")).to_lower().contains(q) or String(c.get("band", "")).to_lower().contains(q)):
			continue
		if flt_genre.selected > 0 and String(c.get("genre", "")) != D.GENRES[flt_genre.selected - 1]:
			continue
		if flt_decade.selected > 0 and String(c.get("decade", "")) != D.ERAS[flt_decade.selected - 1]:
			continue
		if flt_cond.selected > 0 and String(c.get("condition", "")) != CONDITIONS[flt_cond.selected - 1]:
			continue
		if flt_effect.selected > 0 and String(c.get("effect", "")) != EFFECT_KINDS[flt_effect.selected - 1]:
			continue
		if flt_rarity.selected > 0 and String(c.get("rarity", "")) != RARITIES[flt_rarity.selected - 1]:
			continue
		shown.append(i)
		list.add_item("%s  (%s)" % [c.get("title", ""), c.get("band", "")], _thumb(String(c.get("cover", ""))))
		list.set_item_tooltip(list.item_count - 1, "%s %s, %d points, %s, power %s" % [c.get("decade", ""), c.get("genre", ""), int(c.get("points", 0)), String(c.get("rarity", "")), String.num(_power(c), 1)])
		if i == sel:
			list.select(list.item_count - 1)
	count_label.text = "%d of %d cards" % [shown.size(), cards.size()]

func _on_list_selected(idx: int) -> void:
	sel = shown[idx]
	_load_form()
	_update_preview()

func _allowed_targets(effect: String) -> Array:
	match effect:
		"points":
			return ["self", "next", "later", "later_genre", "later_decade", "turn"]
		"mult":
			return ["self", "next", "later", "later_genre", "later_decade"]
		"flow_add", "flow_mult":
			return ["set", "turn"]
		"cash":
			return ["self", "turn"]
	return ["self"]

func _fill_cparam(cond: String, current: String) -> void:
	f_cparam.clear()
	if not COND_NEEDS_PARAM.has(cond):
		f_cparam.add_item("not used")
		f_cparam.disabled = true
		return
	f_cparam.disabled = false
	var names: Array = []
	names.append_array(D.GENRES)
	names.append_array(D.ERAS)
	for n in names:
		f_cparam.add_item(String(n))
	f_cparam.select(maxi(0, names.find(current)))

func _fill_targets(effect: String, current: String) -> void:
	f_tgt.clear()
	var allowed := _allowed_targets(effect)
	for t in allowed:
		f_tgt.add_item(String(TARGET_NAMES[t]))
	f_tgt.select(maxi(0, allowed.find(current)))
	f_tgt.disabled = allowed.size() <= 1
	f_value.editable = effect in ["points", "mult", "flow_add", "flow_mult", "cash"]

func _fill_tparam(target: String, current: String) -> void:
	f_tparam.clear()
	var names: Array = []
	if target == "later_genre":
		names = D.GENRES
	elif target == "later_decade":
		names = D.ERAS
	if names.is_empty():
		f_tparam.add_item("not used")
		f_tparam.disabled = true
		return
	f_tparam.disabled = false
	for n in names:
		f_tparam.add_item(String(n))
	f_tparam.select(maxi(0, names.find(current)))

func _load_form() -> void:
	loading = true
	if sel < 0 or sel >= cards.size():
		for le: LineEdit in [f_id, f_title, f_band, f_cover, f_song]:
			le.text = ""
		loading = false
		return
	var c: Dictionary = cards[sel]
	f_id.text = String(c.get("id", ""))
	f_title.text = String(c.get("title", ""))
	f_band.text = String(c.get("band", ""))
	f_genre.select(maxi(0, D.GENRES.find(String(c.get("genre", "")))))
	f_decade.select(maxi(0, D.ERAS.find(String(c.get("decade", "")))))
	f_rarity.select(maxi(0, RARITIES.find(String(c.get("rarity", "common")))))
	f_points.value = int(c.get("points", 0))
	var cond := String(c.get("condition", "always"))
	f_cond.select(maxi(0, CONDITIONS.find(cond)))
	_fill_cparam(cond, String(c.get("cond_param", "")))
	var effect := String(c.get("effect", "none"))
	f_eff.select(maxi(0, EFFECT_KINDS.find(effect)))
	f_value.value = float(c.get("value", 0.0))
	var target := String(c.get("target", "self"))
	_fill_targets(effect, target)
	_fill_tparam(_allowed_targets(effect)[f_tgt.selected], String(c.get("target_param", "")))
	f_cover.text = String(c.get("cover", ""))
	f_song.text = String(c.get("song", ""))
	loading = false

func _read_form() -> void:
	if sel < 0 or sel >= cards.size():
		return
	var c: Dictionary = cards[sel]
	c["title"] = f_title.text
	c["band"] = f_band.text
	c["genre"] = D.GENRES[f_genre.selected]
	c["decade"] = D.ERAS[f_decade.selected]
	c["rarity"] = RARITIES[f_rarity.selected]
	c["points"] = int(f_points.value)
	var cond: String = CONDITIONS[f_cond.selected]
	c["condition"] = cond
	c["cond_param"] = f_cparam.get_item_text(f_cparam.selected) if COND_NEEDS_PARAM.has(cond) else ""
	var effect: String = EFFECT_KINDS[f_eff.selected]
	c["effect"] = effect
	c["value"] = f_value.value if effect in ["points", "mult", "flow_add", "flow_mult", "cash"] else 0.0
	var allowed := _allowed_targets(effect)
	var target: String = allowed[mini(f_tgt.selected, allowed.size() - 1)]
	c["target"] = target
	c["target_param"] = f_tparam.get_item_text(f_tparam.selected) if target in ["later_genre", "later_decade"] else ""

func _on_cond_changed(_i: int) -> void:
	if loading:
		return
	_fill_cparam(CONDITIONS[f_cond.selected], "")
	_on_edit()

func _on_effect_changed(_i: int) -> void:
	if loading:
		return
	var effect: String = EFFECT_KINDS[f_eff.selected]
	_fill_targets(effect, "")
	_fill_tparam(_allowed_targets(effect)[f_tgt.selected], "")
	loading = true
	match effect:
		"points":
			f_value.value = 5.0
		"mult":
			f_value.value = 2.0
		"flow_add":
			f_value.value = 1.0
		"flow_mult":
			f_value.value = 2.0
		"cash":
			f_value.value = 1.0
		_:
			f_value.value = 0.0
	loading = false
	_on_edit()

func _on_target_changed(_i: int) -> void:
	if loading:
		return
	var effect: String = EFFECT_KINDS[f_eff.selected]
	_fill_tparam(_allowed_targets(effect)[f_tgt.selected], "")
	_on_edit()

func _on_edit(_v = null) -> void:
	if loading or sel < 0:
		return
	_read_form()
	_set_dirty(true)
	_refresh_list()
	_update_preview()
	_refresh_stats()

func _power(c: Dictionary) -> float:
	var pts := float(c.get("points", 0))
	var eff := String(c.get("effect", "none"))
	var v := float(c.get("value", 0.0))
	var raw := 0.0
	match eff:
		"points":
			raw = v
		"mult":
			raw = (v - 1.0) * 12.0
		"flow_add":
			raw = v * 10.0
		"flow_mult":
			raw = (v - 1.0) * 10.0
		"cash":
			raw = v * 3.0
		"copy":
			raw = 6.0
	match String(c.get("target", "self")):
		"next":
			raw *= 1.1
		"later":
			raw *= 2.0
		"later_genre", "later_decade":
			raw *= 0.8
		"turn":
			raw *= 0.9
	return pts + raw * float(COND_POWER.get(String(c.get("condition", "always")), 1.0))

func _bar_fill(col: Color) -> void:
	power_bar.add_theme_stylebox_override("fill", _sb(col, Color(0, 0, 0, 0), 6, 4.0))

func _update_preview() -> void:
	var c: Dictionary = (cards[sel] as Dictionary) if sel >= 0 and sel < cards.size() else {}
	preview.call("set_card", c)
	if c.is_empty():
		power_label.text = ""
		f_text.text = ""
		power_bar.value = 0.0
		return
	var p := _power(c)
	var suggest := "common" if p <= 10.0 else ("uncommon" if p <= 18.0 else "rare")
	power_label.text = "Power %s  ·  suggests %s" % [String.num(p, 1), suggest]
	power_bar.value = p
	_bar_fill(RARITY_COLORS[suggest])
	f_text.text = String((preview.call("describe") as Dictionary).get("text", ""))

func _slug(t: String) -> String:
	var out := ""
	for ch in t.to_lower():
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "-"
	while out.contains("--"):
		out = out.replace("--", "-")
	return out.strip_edges().trim_prefix("-").trim_suffix("-")

func _unique_id(band: String, title: String) -> String:
	var base := _slug("%s-%s" % [band, title])
	var id := base
	var n := 2
	var taken := {}
	for c: Dictionary in cards:
		taken[String(c.get("id", ""))] = true
	while taken.has(id):
		id = "%s-%d" % [base, n]
		n += 1
	return id

func _new_card(title: String, band: String) -> Dictionary:
	return {"id": _unique_id(band, title), "title": title, "band": band, "cover": "", "song": "", "genre": D.GENRES[0], "decade": D.ERAS[3], "rarity": "common", "points": 5, "condition": "always", "cond_param": "", "effect": "none", "value": 0.0, "target": "self", "target_param": ""}

func _select_card(i: int) -> void:
	sel = i
	_refresh_all()

func _on_new() -> void:
	cards.append(_new_card("New card", "Various Artists"))
	_set_dirty(true)
	_select_card(cards.size() - 1)

func _on_duplicate() -> void:
	if sel < 0:
		return
	var c: Dictionary = (cards[sel] as Dictionary).duplicate(true)
	c["title"] = String(c["title"]) + " (copy)"
	c["id"] = _unique_id(String(c["band"]), String(c["title"]))
	cards.insert(sel + 1, c)
	_set_dirty(true)
	_select_card(sel + 1)

func _on_delete() -> void:
	if sel >= 0:
		confirm.popup_centered()

func _delete_selected() -> void:
	if sel < 0:
		return
	cards.remove_at(sel)
	sel = mini(sel, cards.size() - 1)
	_set_dirty(true)
	_refresh_all()

func _copy_into(src: String, dir: String) -> String:
	var fname := src.get_file()
	var dest := dir + fname
	var abs_dest := ProjectSettings.globalize_path(dest)
	DirAccess.make_dir_recursive_absolute(abs_dest.get_base_dir())
	if abs_dest.simplify_path() == src.simplify_path():
		return dest
	if FileAccess.file_exists(dest):
		var same := FileAccess.get_file_as_bytes(src).size() == FileAccess.get_file_as_bytes(dest).size()
		if same:
			return dest
		var n := 2
		while FileAccess.file_exists(dir + "%s_%d.%s" % [fname.get_basename(), n, fname.get_extension()]):
			n += 1
		dest = dir + "%s_%d.%s" % [fname.get_basename(), n, fname.get_extension()]
		abs_dest = ProjectSettings.globalize_path(dest)
	var err := DirAccess.copy_absolute(src, abs_dest)
	if err != OK:
		_say("Could not copy %s (error %d)" % [src.get_file(), err])
		return ""
	return dest

func _attach_cover(i: int, src: String) -> void:
	var dest := _copy_into(src, COVER_DIR)
	if dest == "":
		return
	var c: Dictionary = cards[i]
	c["cover"] = dest
	thumbs.erase(dest)
	_set_dirty(true)

func _attach_song(i: int, src: String) -> void:
	var c: Dictionary = cards[i]
	var dest := _copy_into(src, MUSIC_DIR + String(c.get("genre", "")) + "/")
	if dest == "":
		return
	c["song"] = dest
	_set_dirty(true)

func _card_from_image(src: String) -> void:
	var dest := _copy_into(src, COVER_DIR)
	if dest == "":
		return
	var base := src.get_file().get_basename()
	var parts := base.split(" - ", true, 1)
	var band := String(parts[0]) if parts.size() == 2 else "Various Artists"
	var title := String(parts[1]) if parts.size() == 2 else base
	var c := _new_card(title, band)
	c["cover"] = dest
	thumbs.erase(dest)
	cards.append(c)
	_set_dirty(true)

func _find_card_for_audio(src: String) -> int:
	var base := src.get_file().get_basename().to_lower()
	for i in cards.size():
		var c: Dictionary = cards[i]
		if ("%s - %s" % [c.get("band", ""), c.get("title", "")]).to_lower() == base:
			return i
		var cover_base := String(c.get("cover", "")).get_file().get_basename().to_lower()
		if cover_base != "" and cover_base == base:
			return i
	return -1

func _on_files_dropped(files: PackedStringArray) -> void:
	var imgs: Array = []
	var auds: Array = []
	for p in files:
		var ext := p.get_extension().to_lower()
		if ext in ["jpg", "jpeg", "png", "webp"]:
			imgs.append(p)
		elif ext in ["mp3", "ogg", "wav"]:
			auds.append(p)
	if imgs.size() == 1 and sel >= 0:
		_attach_cover(sel, String(imgs[0]))
	else:
		var first := cards.size()
		for p in imgs:
			_card_from_image(String(p))
		if cards.size() > first:
			sel = first
	for p in auds:
		var i := _find_card_for_audio(String(p))
		if i < 0 and auds.size() == 1:
			i = sel
		if i >= 0:
			_attach_song(i, String(p))
		else:
			_say("No card matches %s. Select a card first." % String(p).get_file())
	_refresh_all()

func _browse(kind: String) -> void:
	if sel < 0:
		return
	var filters := PackedStringArray(["*.jpg,*.jpeg,*.png,*.webp;Images"]) if kind == "cover" else PackedStringArray(["*.mp3,*.ogg,*.wav;Audio"])
	DisplayServer.file_dialog_show("Choose a file", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filters, func(ok: bool, paths: PackedStringArray, _f: int) -> void:
		if ok and not paths.is_empty() and sel >= 0:
			if kind == "cover":
				_attach_cover(sel, paths[0])
			else:
				_attach_song(sel, paths[0])
			_refresh_all())

func _play_song() -> void:
	if sel < 0:
		return
	var path := String((cards[sel] as Dictionary).get("song", ""))
	if path == "":
		_say("This card has no music yet")
		return
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	elif path.get_extension().to_lower() == "mp3" and FileAccess.file_exists(path):
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(path)
		stream = mp3
	if stream == null:
		_say("Could not load %s" % path.get_file())
		return
	player.stream = stream
	player.play()

func _validate() -> Array:
	var out: Array = []
	var seen := {}
	for i in cards.size():
		var c: Dictionary = cards[i]
		var cname := "%s (%s)" % [c.get("title", "?"), c.get("band", "?")]
		if String(c.get("title", "")).strip_edges() == "":
			out.append({"text": "%s: missing title" % cname, "idx": i})
		var cover := String(c.get("cover", ""))
		if cover == "" or not FileAccess.file_exists(cover):
			out.append({"text": "%s: artwork missing" % cname, "idx": i})
		var song := String(c.get("song", ""))
		if song == "" or not FileAccess.file_exists(song):
			out.append({"text": "%s: no music" % cname, "idx": i})
		var key := ("%s|%s" % [c.get("band", ""), c.get("title", "")]).to_lower()
		if seen.has(key):
			out.append({"text": "%s: duplicate title and band" % cname, "idx": i})
		seen[key] = true
		if int(c.get("points", 0)) <= 0:
			out.append({"text": "%s: points is 0" % cname, "idx": i})
		var cond := String(c.get("condition", "always"))
		if COND_NEEDS_PARAM.has(cond) and String(c.get("cond_param", "")) == "":
			out.append({"text": "%s: condition needs a genre or decade" % cname, "idx": i})
		var eff := String(c.get("effect", "none"))
		var target := String(c.get("target", "self"))
		if eff in ["points", "mult", "flow_add", "flow_mult", "cash"] and float(c.get("value", 0.0)) <= 0.0:
			out.append({"text": "%s: effect value is 0" % cname, "idx": i})
		if eff == "mult" and float(c.get("value", 1.0)) < 1.0:
			out.append({"text": "%s: a multiplier below 1 lowers the score" % cname, "idx": i})
		if target in ["later_genre", "later_decade"] and String(c.get("target_param", "")) == "":
			out.append({"text": "%s: target needs a genre or decade" % cname, "idx": i})
		if not _allowed_targets(eff).has(target):
			out.append({"text": "%s: %s cannot target %s" % [cname, eff, target], "idx": i})
	return out

func _heat_style(n: int, selected: bool) -> StyleBoxFlat:
	var col := Color("5a2a2a")
	if n == 1:
		col = Color("2d3b4d")
	elif n == 2:
		col = Color("2f5575")
	elif n >= 3:
		col = Color("2f7d4f")
	var b := _sb(col, ACCENT if selected else col.lightened(0.15), 4, 2.0)
	if selected:
		b.set_border_width_all(2)
	return b

func _refresh_stats() -> void:
	var by_rarity := {}
	var power_sum := {}
	var grid := {}
	var row_t := {}
	var col_t := {}
	for c: Dictionary in cards:
		var rk := String(c.get("rarity", ""))
		by_rarity[rk] = int(by_rarity.get(rk, 0)) + 1
		power_sum[rk] = float(power_sum.get(rk, 0.0)) + _power(c)
		var gi := D.GENRES.find(String(c.get("genre", "")))
		var di := D.ERAS.find(String(c.get("decade", "")))
		if gi >= 0 and di >= 0:
			grid["%d|%d" % [gi, di]] = int(grid.get("%d|%d" % [gi, di], 0)) + 1
			row_t[gi] = int(row_t.get(gi, 0)) + 1
			col_t[di] = int(col_t.get(di, 0)) + 1
	for gi in D.GENRES.size():
		for di in D.ERAS.size():
			var n := int(grid.get("%d|%d" % [gi, di], 0))
			var cell: Button = heat["%d|%d" % [gi, di]]
			cell.text = str(n)
			var on := flt_genre.selected == gi + 1 and flt_decade.selected == di + 1
			for st in ["normal", "hover", "pressed", "focus"]:
				cell.add_theme_stylebox_override(st, _heat_style(n, on))
			cell.add_theme_color_override("font_color", Color("ffb3a8") if n == 0 else Color.WHITE)
			cell.add_theme_color_override("font_hover_color", Color.WHITE)
			cell.add_theme_color_override("font_pressed_color", Color.WHITE)
	for gi in D.GENRES.size():
		(heat_row_totals[gi] as Label).text = str(int(row_t.get(gi, 0)))
	for di in D.ERAS.size():
		(heat_col_totals[di] as Label).text = str(int(col_t.get(di, 0)))
	heat_grand.text = str(cards.size())
	for r in RARITIES:
		var n := int(by_rarity.get(r, 0))
		(rar_count[r] as Label).text = str(n)
		(rar_power[r] as Label).text = "average power %s" % String.num(float(power_sum.get(r, 0.0)) / maxf(1.0, n), 1)
	var warn := _validate()
	warn_list.clear()
	warn_cards.clear()
	for w: Dictionary in warn:
		warn_list.add_item(String(w["text"]))
		warn_cards.append(int(w["idx"]))
	if warn.is_empty():
		warn_list.add_item("No problems found")
		warn_cards.append(-1)
	warn_badge.text = "%d warnings" % warn.size() if not warn.is_empty() else "All checks pass"
	warn_badge_panel.add_theme_stylebox_override("panel", _sb(Color("7a3b1f") if not warn.is_empty() else Color("2f6b45"), Color(0, 0, 0, 0), 10, 3.0))
