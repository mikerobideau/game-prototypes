extends Node2D
class_name ThockPrototype

@export_group("Round")
@export var round_seconds: float = 30.0
@export var target_score: int = 2000

@export_group("Scoring")
@export var base_points: int = 10
@export var wrong_penalty: int = 8
@export var combo_step: float = 0.1
@export var combo_mult_cap: float = 5.0

@export_group("Feel")
@export var scroll_stiffness: float = 13.0
@export var focus_ratio: float = 0.30
@export var passage_font_size: int = 74

const PENDING := 0
const CORRECT := 1
const WRONG := 2

const ROWS := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

var passages := [
	"It was the best of times, it was the worst of times, it was the age of wisdom.",
	"Call me Ishmael. Some years ago, never mind how long precisely, I went to sea.",
	"It is a truth universally acknowledged that a single man must be in want of a wife.",
	"The quick brown fox jumps over the lazy dog while the sleepy cat naps by the fire.",
	"All happy families are alike; each unhappy family is unhappy in its own way.",
	"In the beginning the universe was created and this made a lot of people angry.",
	"Two roads diverged in a wood, and I took the one less traveled by, and that mattered.",
]

class ScorePop:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var text: String
	var color: Color
	var size: float

var text := ""
var char_x := PackedFloat32Array()
var status := PackedInt32Array()
var cursor := 0

var scroll := 0.0
var view_size: Vector2
var focus_x := 0.0
var passage_y := 0.0

var score := 0
var combo := 0
var typed := 0
var errors := 0
var time_left := 0.0
var started := false
var game_over := false
var won := false
var blink := 0.0
var shake := 0.0

var key_rects := {}
var key_anim := {}
var key_wrong := {}
var space_rect := Rect2()
var space_anim := 0.0
var space_wrong := 0.0

var popups: Array[ScorePop] = []

var thock_variants: Array[AudioStreamWAV] = []
var space_thock: AudioStreamWAV
var dud_thock: AudioStreamWAV
var players: Array[AudioStreamPlayer] = []
var player_idx := 0

var font: Font

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	_recompute_layout()
	get_viewport().size_changed.connect(_recompute_layout)
	_build_audio()
	_reset_game()

func _recompute_layout() -> void:
	view_size = get_viewport_rect().size
	focus_x = view_size.x * focus_ratio
	passage_y = view_size.y * 0.30
	_layout_keyboard()

func _layout_keyboard() -> void:
	key_rects.clear()
	var kw: float = min(view_size.x * 0.062, 132.0)
	var gap: float = kw * 0.14
	var row_h := kw + gap
	var board_w := ROWS[0].length() * kw + (ROWS[0].length() - 1) * gap
	var left := (view_size.x - board_w) * 0.5
	var top := view_size.y - row_h * 3.0 - kw * 1.3 - view_size.y * 0.06
	var stagger := [0.0, 0.55, 1.55]
	for r in range(ROWS.size()):
		var row: String = ROWS[r]
		var x := left + float(stagger[r]) * (kw + gap)
		var y := top + r * row_h
		for c in row.length():
			key_rects[row[c]] = Rect2(x, y, kw, kw)
			x += kw + gap
	var space_w := board_w * 0.52
	space_rect = Rect2((view_size.x - space_w) * 0.5, top + 3 * row_h, space_w, kw * 0.85)

# ---------------------------------------------------------------- audio
func _build_audio() -> void:
	for i in range(5):
		var body := 120.0 + i * 22.0
		thock_variants.append(_make_thock(body, 0.13, 1.0, 0.32))
	space_thock = _make_thock(84.0, 0.17, 1.15, 0.5)
	dud_thock = _make_thock(70.0, 0.11, 0.4, 0.7)
	for i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)

func _make_thock(body_freq: float, dur: float, click_amt: float, low_mix: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var p1 := 0.0
	var p2 := 0.0
	var p3 := 0.0
	var f1 := body_freq
	var f2 := body_freq * 1.94
	var f3 := body_freq * 0.62
	var last_noise := 0.0
	for i in range(n):
		var t := float(i) / n
		var secs := float(i) / rate
		p1 += TAU * f1 / rate
		p2 += TAU * f2 / rate
		p3 += TAU * f3 / rate
		var body_env: float = exp(-secs / (dur * 0.16))
		var body: float = (sin(p1) * 0.6 + sin(p2) * 0.22 + sin(p3) * low_mix) * body_env
		var click := 0.0
		if secs < 0.006:
			var raw := randf() * 2.0 - 1.0
			last_noise = last_noise * 0.55 + raw * 0.45
			var raw_hp := raw - last_noise
			click = raw_hp * click_amt * (1.0 - secs / 0.006)
		var mid := 0.0
		if secs < 0.03:
			mid = sin(TAU * 520.0 * secs) * 0.18 * exp(-secs / 0.012)
		var s: float = clamp(body * 0.8 + click * 0.9 + mid, -1.0, 1.0)
		if t > 0.85:
			s *= (1.0 - t) / 0.15
		var v := int(s * 30000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w

func _play(stream: AudioStreamWAV, pitch: float, vol_db: float) -> void:
	var p := players[player_idx]
	player_idx = (player_idx + 1) % players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()

# ---------------------------------------------------------------- game
func _reset_game() -> void:
	text = ""
	char_x = PackedFloat32Array()
	status = PackedInt32Array()
	cursor = 0
	scroll = 0.0
	score = 0
	combo = 0
	typed = 0
	errors = 0
	time_left = round_seconds
	started = false
	game_over = false
	won = false
	popups.clear()
	_append_passage()
	_append_passage()
	scroll = char_x[0]

func _append_passage() -> void:
	var chunk: String = passages[randi() % passages.size()]
	if text.length() > 0:
		chunk = "   " + chunk
	var start := text.length()
	text += chunk
	var x: float
	if char_x.is_empty():
		char_x.append(0.0)
		x = 0.0
	else:
		x = char_x[char_x.size() - 1]
	for i in range(start, text.length()):
		var adv: float = font.get_char_size(text.unicode_at(i), passage_font_size).x
		x += adv
		char_x.append(x)
		status.append(PENDING)

func _process(delta: float) -> void:
	blink += delta
	if started and not game_over:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			game_over = true
			won = score >= target_score
	var target_scroll: float = char_x[cursor] if cursor < char_x.size() else char_x[char_x.size() - 1]
	scroll = lerp(scroll, target_scroll, 1.0 - exp(-delta * scroll_stiffness))
	shake = max(0.0, shake - delta * 40.0)
	for label in key_anim.keys():
		key_anim[label] = max(0.0, key_anim[label] - delta * 6.0)
		key_wrong[label] = max(0.0, key_wrong.get(label, 0.0) - delta * 4.0)
	space_anim = max(0.0, space_anim - delta * 6.0)
	space_wrong = max(0.0, space_wrong - delta * 4.0)
	for i in range(popups.size() - 1, -1, -1):
		var pu := popups[i]
		pu.life -= delta
		pu.pos += pu.vel * delta
		pu.vel.y += 340.0 * delta
		if pu.life <= 0.0:
			popups.remove_at(i)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if game_over:
			if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
				_reset_game()
			return
		if event.keycode == KEY_BACKSPACE:
			return
		var u: int = event.unicode
		if u <= 0:
			return
		_type_char(char(u))

func _type_char(ch: String) -> void:
	if cursor >= text.length():
		return
	if not started:
		started = true
	var expected := text[cursor]
	var hit := ch.to_lower() == expected.to_lower()
	var label := expected.to_upper()
	var is_space := expected == " "

	if is_space:
		space_anim = 1.0
		if not hit:
			space_wrong = 1.0
	elif key_rects.has(label):
		key_anim[label] = 1.0
		if not hit:
			key_wrong[label] = 1.0

	if hit:
		if is_space:
			_play(space_thock, randf_range(0.96, 1.04), -3.0)
		else:
			_play(thock_variants[randi() % thock_variants.size()], randf_range(0.92, 1.09), -4.0)
		status[cursor] = CORRECT
		combo += 1
		var mult: float = clamp(1.0 + combo * combo_step, 1.0, combo_mult_cap)
		var gained := int(base_points * mult)
		score += gained
		typed += 1
		if combo >= 5:
			_spawn_popup("+%d" % gained, Color(0.6, 0.95, 0.65))
	else:
		_play(dud_thock, randf_range(0.9, 1.02), -5.0)
		status[cursor] = WRONG
		combo = 0
		score = max(0, score - wrong_penalty)
		errors += 1
		typed += 1
		shake = 9.0
		_spawn_popup("-%d" % wrong_penalty, Color(0.95, 0.45, 0.47))

	cursor += 1
	if cursor > text.length() - 60:
		_append_passage()

func _spawn_popup(t: String, col: Color) -> void:
	var pu := ScorePop.new()
	pu.pos = Vector2(focus_x, passage_y - 70.0) + Vector2(randf_range(-10, 10), 0)
	pu.vel = Vector2(randf_range(-30, 30), -150.0)
	pu.max_life = 0.8
	pu.life = pu.max_life
	pu.text = t
	pu.color = col
	pu.size = 40.0
	popups.append(pu)

# ---------------------------------------------------------------- draw
func _draw() -> void:
	var shake_off := Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.055, 0.065, 0.085))
	draw_rect(Rect2(0, 0, view_size.x, passage_y * 2.0), Color(0.04, 0.05, 0.07))

	_draw_passage(shake_off)
	_draw_caret()
	_draw_popups()
	_draw_keyboard()
	_draw_hud()
	if game_over:
		_draw_gameover()

func _draw_passage(shake_off: Vector2) -> void:
	var base_y := passage_y + passage_font_size * 0.35
	var col_pending := Color(0.42, 0.46, 0.55)
	var col_correct := Color(0.62, 0.92, 0.68)
	var col_wrong := Color(0.96, 0.42, 0.45)
	for i in range(text.length()):
		var sx := focus_x + char_x[i] - scroll
		if sx < -80 or sx > view_size.x + 40:
			continue
		var col := col_pending
		if i < status.size():
			match status[i]:
				CORRECT: col = col_correct
				WRONG: col = col_wrong
		if i == cursor:
			col = Color(0.95, 0.97, 1.0)
		var cc := text[i]
		if cc == " " and i < status.size() and status[i] == WRONG:
			draw_rect(Rect2(sx, base_y - passage_font_size * 0.6, 16, passage_font_size * 0.7), col_wrong.darkened(0.1))
		draw_char(font, Vector2(sx, base_y) + shake_off, cc, passage_font_size, col)

func _draw_caret() -> void:
	var base_y := passage_y + passage_font_size * 0.35
	var a: float = 0.35 + 0.35 * sin(blink * 6.0)
	if started:
		a = 0.85
	draw_rect(Rect2(focus_x - 3, base_y - passage_font_size * 0.72, 5, passage_font_size * 0.82), Color(0.55, 0.72, 1.0, a))

func _draw_popups() -> void:
	for pu in popups:
		var a: float = clamp(pu.life / pu.max_life, 0.0, 1.0)
		var c := pu.color
		c.a = a
		draw_string(font, pu.pos, pu.text, HORIZONTAL_ALIGNMENT_CENTER, -1, int(pu.size), c)

func _draw_keyboard() -> void:
	var next_label := ""
	if cursor < text.length():
		var e := text[cursor]
		next_label = "SPACE" if e == " " else e.to_upper()
	for r in range(ROWS.size()):
		var row: String = ROWS[r]
		for c in row.length():
			var label: String = row[c]
			_draw_key(key_rects[label], label, key_anim.get(label, 0.0), key_wrong.get(label, 0.0), label == next_label)
	_draw_key(space_rect, "", space_anim, space_wrong, next_label == "SPACE")

func _draw_key(rect: Rect2, label: String, anim: float, wrong: float, is_next: bool) -> void:
	var press := anim * 5.0
	var body := Rect2(rect.position + Vector2(0, press), rect.size)
	draw_rect(Rect2(rect.position + Vector2(0, 6), rect.size), Color(0.02, 0.025, 0.04))
	var face := Color(0.16, 0.17, 0.21)
	if is_next:
		face = Color(0.20, 0.26, 0.36)
	face = face.lerp(Color(0.45, 0.6, 0.95), anim * 0.7)
	if wrong > 0.0:
		face = face.lerp(Color(0.7, 0.22, 0.26), wrong)
	draw_rect(body, face)
	draw_rect(Rect2(body.position, Vector2(body.size.x, body.size.y * 0.32)), face.lightened(0.12))
	if is_next:
		draw_rect(body, Color(0.6, 0.78, 1.0, 0.9), false, 3.0)
	if label != "":
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 34)
		var tp := body.position + Vector2((body.size.x - ts.x) * 0.5, body.size.y * 0.62)
		draw_string(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.82, 0.86, 0.94))

func _draw_hud() -> void:
	var pad := 40.0
	draw_string(font, Vector2(pad, 70), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.5, 0.55, 0.65))
	draw_string(font, Vector2(pad, 132), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Color(0.95, 0.97, 1.0))
	draw_string(font, Vector2(pad, 172), "target %d" % target_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.5, 0.55, 0.65))

	var mult: float = clamp(1.0 + combo * combo_step, 1.0, combo_mult_cap)
	var mcol := Color(0.6, 0.7, 0.85).lerp(Color(1.0, 0.85, 0.3), (mult - 1.0) / (combo_mult_cap - 1.0))
	draw_string(font, Vector2(view_size.x - pad - 220, 132), "x%.1f" % mult, HORIZONTAL_ALIGNMENT_RIGHT, 220, 56, mcol)
	draw_string(font, Vector2(view_size.x - pad - 220, 172), "combo %d" % combo, HORIZONTAL_ALIGNMENT_RIGHT, 220, 24, Color(0.5, 0.55, 0.65))

	var bar_w := view_size.x * 0.5
	var bx := (view_size.x - bar_w) * 0.5
	var by := 60.0
	draw_rect(Rect2(bx, by, bar_w, 16), Color(0.14, 0.15, 0.19))
	var frac: float = clamp(time_left / round_seconds, 0.0, 1.0)
	var tcol := Color(0.4, 0.75, 0.95)
	if frac < 0.3:
		tcol = Color(0.95, 0.5, 0.4)
	draw_rect(Rect2(bx, by, bar_w * frac, 16), tcol)
	var sfrac: float = clamp(float(score) / float(target_score), 0.0, 1.0)
	draw_rect(Rect2(bx, by + 20, bar_w * sfrac, 6), Color(0.6, 0.9, 0.65))
	draw_string(font, Vector2(bx, by - 10), "%0.1fs" % time_left, HORIZONTAL_ALIGNMENT_CENTER, bar_w, 24, Color(0.7, 0.75, 0.82))

	if not started:
		draw_string(font, Vector2(0, passage_y + 150), "start typing the words above", HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 34, Color(0.55, 0.6, 0.7, 0.7 + 0.3 * sin(blink * 4.0)))

func _draw_gameover() -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.02, 0.03, 0.05, 0.82))
	var title := "ROUND CLEARED" if won else "ROUND FAILED"
	var tcol := Color(0.6, 0.95, 0.68) if won else Color(0.96, 0.45, 0.47)
	draw_string(font, Vector2(0, view_size.y * 0.4), title, HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 90, tcol)
	var acc := 100.0 if typed == 0 else 100.0 * float(typed - errors) / float(typed)
	var wpm := 0.0 if round_seconds <= 0 else (typed / 5.0) / (round_seconds / 60.0)
	var line := "score %d  /  target %d      accuracy %d%%      %d wpm" % [score, target_score, int(acc), int(wpm)]
	draw_string(font, Vector2(0, view_size.y * 0.5), line, HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 36, Color(0.8, 0.84, 0.9))
	draw_string(font, Vector2(0, view_size.y * 0.6), "press ENTER to play again", HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 30, Color(0.55, 0.6, 0.7))
