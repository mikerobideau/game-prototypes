extends Node2D
class_name Orchard

# ---- Pull feel (bubble-wrap pop) ----
@export_group("Vacuum")
@export var suction_radius: float = 210.0
@export var follow_stiffness: float = 55.0
@export var nozzle_offset: float = 34.0

@export_group("Stem")
@export var rest_len: float = 20.0
@export var stem_tension_linear: float = 12.0
@export var stem_tension_max: float = 2600.0
@export var pop_stretch: float = 130.0
@export var stem_damping: float = 9.0
@export var launch_speed: float = 1400.0

@export_group("Character")
@export var move_accel: float = 14.0
@export var move_speed: float = 560.0
@export var carry_capacity: int = 15

@export_group("Ripeness")
@export var t_ripe: float = 3.5        # unripe -> ripe
@export var t_plump: float = 6.5       # ripe -> plump (premium)
@export var t_rot: float = 9.5         # plump -> rotted (lost)
@export var value_ripe: int = 2
@export var value_plump: int = 4

@export_group("Bushes")
@export var bush_fruit_max: int = 5
@export var bush_spawn_time: float = 1.6
@export var combo_window: float = 0.6

const CANOPY_R := 78.0

enum State { ATTACHED, DETACHED, COLLECTED, ROTTED }
enum Stage { UNRIPE, RIPE, PLUMP }

class Bush:
	var pos: Vector2
	var spawn_timer: float = 0.0
	var hue: float = 0.0

class Fruit:
	var owner_bush: Bush
	var anchor: Vector2
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var age: float = 0.0
	var stage: int = Stage.UNRIPE
	var radius: float = 12.0
	var full_radius: float = 34.0
	var value: int = 0
	var state: int = State.ATTACHED
	var grabbed: bool = false
	var squash: float = 0.0
	var wobble_seed: float = 0.0
	var hue: float = 0.0

class Particle:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var size: float
	var color: Color

class CustomPopup:
	var pos: Vector2
	var life: float
	var text: String
	var color: Color
	var scale: float

var bushes: Array[Bush] = []
var fruits: Array[Fruit] = []
var particles: Array[Particle] = []
var popups: Array[CustomPopup] = []

var view_size: Vector2
var field: Rect2
var basket_pos: Vector2

var char_pos: Vector2
var char_vel: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN

var carried_count: int = 0
var carried_value: int = 0
var score: int = 0
var deposited: int = 0
var rotted: int = 0
var combo: int = 0
var combo_timer: float = 0.0

var time: float = 0.0
var deposit_flash: float = 0.0

# audio
var players: Array[AudioStreamPlayer] = []
var player_idx: int = 0
var s_pop: AudioStreamWAV
var s_collect: AudioStreamWAV
var s_deposit: AudioStreamWAV
var s_rot: AudioStreamWAV

var font: Font

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	view_size = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_resize)
	_build_audio()
	_layout()
	char_pos = field.get_center()
	set_process(true)

func _on_resize() -> void:
	view_size = get_viewport_rect().size
	_layout()

func _layout() -> void:
	field = Rect2(70, 180, view_size.x - 140, view_size.y - 320)
	basket_pos = Vector2(field.position.x + 90, field.end.y - 70)
	if bushes.is_empty():
		_scatter_bushes()

func _scatter_bushes() -> void:
	bushes.clear()
	# a loose grid of bushes, kept away from the basket corner
	var cols := 4
	var rows := 2
	for r in range(rows):
		for c in range(cols):
			var b := Bush.new()
			var fx: float = field.position.x + field.size.x * (0.22 + 0.52 * c / float(cols - 1))
			var fy: float = field.position.y + field.size.y * (0.28 + 0.5 * r / float(rows - 1))
			b.pos = Vector2(fx, fy) + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			b.hue = fmod(randf_range(0.95, 1.05), 1.0)
			b.spawn_timer = randf_range(0.0, bush_spawn_time)
			bushes.append(b)

# ---------------------------------------------------------------- audio
func _build_audio() -> void:
	s_pop = _make_tone(880.0, 150.0, 0.11, 0.5)
	s_collect = _make_tone(1400.0, 1900.0, 0.06, 0.0)
	s_deposit = _make_tone(400.0, 900.0, 0.16, 0.1)
	s_rot = _make_tone(240.0, 90.0, 0.18, 0.3)
	for i in range(10):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

func _make_tone(f_start: float, f_end: float, dur: float, noise_amt: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var ph := 0.0
	for i in range(n):
		var t := float(i) / n
		var freq: float = lerp(f_start, f_end, t * t)
		ph += TAU * freq / rate
		var env: float = pow(1.0 - t, 2.2)
		var s: float = sin(ph) * env
		if noise_amt > 0.0 and t < 0.06:
			s += (randf() * 2.0 - 1.0) * (1.0 - t / 0.06) * noise_amt * env
		var v := int(clamp(s, -1.0, 1.0) * 30000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w

func _play(stream: AudioStreamWAV, pitch: float) -> void:
	var p := players[player_idx]
	player_idx = (player_idx + 1) % players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()

# ---------------------------------------------------------------- bushes / fruit
func _fruit_count(b: Bush) -> int:
	var c := 0
	for f in fruits:
		if f.owner_bush == b and f.state == State.ATTACHED:
			c += 1
	return c

func _spawn_fruit(b: Bush) -> void:
	var f := Fruit.new()
	f.owner_bush = b
	var ang := randf() * TAU
	f.anchor = b.pos + Vector2(cos(ang), sin(ang)) * CANOPY_R * randf_range(0.35, 1.0)
	f.pos = f.anchor
	f.full_radius = randf_range(28, 40)
	f.wobble_seed = randf() * TAU
	f.hue = b.hue
	fruits.append(f)

func _update_bushes(delta: float) -> void:
	for b in bushes:
		if _fruit_count(b) < bush_fruit_max:
			b.spawn_timer -= delta
			if b.spawn_timer <= 0.0:
				_spawn_fruit(b)
				b.spawn_timer = bush_spawn_time

func _ripen(f: Fruit) -> void:
	if f.age < t_ripe:
		f.stage = Stage.UNRIPE
		f.radius = lerp(12.0, f.full_radius, clamp(f.age / t_ripe, 0.0, 1.0))
		f.value = 0
	elif f.age < t_plump:
		f.stage = Stage.RIPE
		f.radius = f.full_radius
		f.value = value_ripe
	else:
		f.stage = Stage.PLUMP
		f.radius = f.full_radius * 1.12
		f.value = value_plump

func _stage_color(f: Fruit) -> Color:
	match f.stage:
		Stage.UNRIPE:
			return Color.from_hsv(0.28, 0.55, 0.6)          # green
		Stage.PLUMP:
			return Color.from_hsv(0.11, 0.85, 1.0)          # gold, premium
		_:
			return Color.from_hsv(f.hue, 0.8, 0.9)          # ripe red

# ---------------------------------------------------------------- update
func _process(delta: float) -> void:
	time += delta
	_move_character(delta)

	var sucking := Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var nozzle := char_pos + facing * nozzle_offset

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

	_update_bushes(delta)

	for f in fruits:
		match f.state:
			State.ATTACHED:
				_update_attached(f, delta, nozzle, sucking)
			State.DETACHED:
				_update_detached(f, delta)
		f.squash = move_toward(f.squash, 0.0, delta * 4.0)

	var kept: Array[Fruit] = []
	for f in fruits:
		if f.state != State.COLLECTED and f.state != State.ROTTED:
			kept.append(f)
	fruits = kept

	# deposit when standing on the basket
	if carried_count > 0 and char_pos.distance_to(basket_pos) < 92.0:
		_deposit()

	deposit_flash = move_toward(deposit_flash, 0.0, delta * 2.0)
	_update_particles(delta)
	_update_popups(delta)
	queue_redraw()

func _move_character(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		facing = facing.lerp(dir, 1.0 - exp(-12.0 * delta)).normalized()
	var target := dir * move_speed
	char_vel = char_vel.lerp(target, 1.0 - exp(-move_accel * delta))
	char_pos += char_vel * delta
	char_pos.x = clamp(char_pos.x, field.position.x, field.end.x)
	char_pos.y = clamp(char_pos.y, field.position.y, field.end.y)

func _update_attached(f: Fruit, delta: float, nozzle: Vector2, sucking: bool) -> void:
	f.age += delta
	_ripen(f)

	if f.age > t_rot:
		_rot_fruit(f)
		return

	var can_grab := sucking and f.stage != Stage.UNRIPE and carried_count < carry_capacity
	if can_grab and not f.grabbed and (nozzle - f.pos).length() < suction_radius:
		f.grabbed = true
	if not sucking or carried_count >= carry_capacity:
		f.grabbed = false

	var force := Vector2.ZERO
	var to_anchor := f.anchor - f.pos
	var dist := to_anchor.length()
	var stretch: float = dist - rest_len
	if stretch > 0.0 and dist > 0.001:
		var d := to_anchor / dist
		var t: float = clamp(stretch / pop_stretch, 0.0, 1.0)
		force += d * (stem_tension_linear * stretch + stem_tension_max * t * t)
	if f.grabbed:
		force += (nozzle - f.pos) * follow_stiffness

	f.vel += force * delta
	f.vel *= exp(-stem_damping * delta)
	f.pos += f.vel * delta

	if (f.anchor - f.pos).length() - rest_len > pop_stretch:
		_pop(f, nozzle)

func _pop(f: Fruit, nozzle: Vector2) -> void:
	f.state = State.DETACHED
	f.squash = 1.0
	var dir := nozzle - f.pos
	dir = dir.normalized() if dir.length() > 0.001 else Vector2.UP
	f.vel = dir * launch_speed + f.vel * 0.3

	combo += 1
	combo_timer = combo_window
	var gain: int = f.value + (combo - 1)
	f.value = gain

	_play(s_pop, clamp((60.0 / f.radius) * randf_range(0.95, 1.08) * (1.0 + (combo - 1) * 0.05), 0.6, 2.2))
	_spawn_splatter(f.pos, _stage_color(f))
	var txt := ("+%d" % gain) if combo < 2 else ("x%d  +%d" % [combo, gain])
	_popup(f.pos, txt, _stage_color(f).lightened(0.4), 1.0 + min(combo * 0.1, 1.0))

func _update_detached(f: Fruit, delta: float) -> void:
	var to := char_pos - f.pos
	var d := to.length()
	if d > 0.001:
		f.vel += (to / d) * 6500.0 * delta
	f.vel *= exp(-2.5 * delta)
	f.pos += f.vel * delta
	if d < 44.0:
		f.state = State.COLLECTED
		carried_count += 1
		carried_value += f.value
		_play(s_collect, randf_range(0.9, 1.2))

func _rot_fruit(f: Fruit) -> void:
	f.state = State.ROTTED
	rotted += 1
	_play(s_rot, randf_range(0.9, 1.1))
	for i in range(6):
		_spawn_splatter(f.pos, Color(0.35, 0.25, 0.12))

func _deposit() -> void:
	score += carried_value
	deposited += carried_count
	_popup(basket_pos + Vector2(0, -80), "+%d" % carried_value, Color(1, 0.9, 0.5), 1.6)
	_play(s_deposit, randf_range(0.95, 1.05))
	deposit_flash = 1.0
	carried_count = 0
	carried_value = 0

# ---------------------------------------------------------------- fx
func _spawn_splatter(at: Vector2, col: Color) -> void:
	var p := Particle.new()
	p.pos = at
	var ang := randf() * TAU
	p.vel = Vector2(cos(ang), sin(ang)) * randf_range(80, 380)
	p.max_life = randf_range(0.3, 0.6)
	p.life = p.max_life
	p.size = randf_range(3, 9)
	p.color = col.lightened(randf_range(0.0, 0.3))
	particles.append(p)

func _popup(at: Vector2, text: String, col: Color, scale: float) -> void:
	var p := CustomPopup.new()
	p.pos = at
	p.life = 1.1
	p.text = text
	p.color = col
	p.scale = scale
	popups.append(p)

func _update_particles(delta: float) -> void:
	for p in particles:
		p.vel *= exp(-2.2 * delta)
		p.pos += p.vel * delta
		p.life -= delta
	var kept: Array[Particle] = []
	for p in particles:
		if p.life > 0.0:
			kept.append(p)
	particles = kept

func _update_popups(delta: float) -> void:
	for p in popups:
		p.pos.y -= 55.0 * delta
		p.life -= delta
	var kept: Array[CustomPopup] = []
	for p in popups:
		if p.life > 0.0:
			kept.append(p)
	popups = kept

# ---------------------------------------------------------------- draw
func _draw() -> void:
	_draw_ground()

	# bushes (behind fruit)
	for b in bushes:
		draw_circle(b.pos + Vector2(0, 8), CANOPY_R, Color(0.16, 0.34, 0.18, 0.5))
		draw_circle(b.pos, CANOPY_R, Color(0.22, 0.46, 0.24))
		draw_circle(b.pos + Vector2(-20, -14), CANOPY_R * 0.55, Color(0.26, 0.52, 0.28))

	_draw_basket()

	for f in fruits:
		if f.state == State.ATTACHED:
			_draw_stem(f)
	for f in fruits:
		_draw_fruit(f)

	for p in particles:
		var a: float = p.life / p.max_life
		draw_circle(p.pos, p.size * a, Color(p.color.r, p.color.g, p.color.b, a))

	_draw_character()

	for p in popups:
		_draw_popup(p)

	_draw_hud()

func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.45, 0.6, 0.4))
	draw_rect(field.grow(24.0), Color(0.4, 0.55, 0.35))
	draw_rect(field, Color(0.5, 0.62, 0.42))

func _draw_basket() -> void:
	var glow := 0.3 + deposit_flash * 0.5
	if carried_count > 0:
		draw_arc(basket_pos, 92.0, 0, TAU, 40, Color(1, 0.9, 0.5, 0.25 + 0.2 * sin(time * 4.0)), 3.0)
	draw_circle(basket_pos + Vector2(0, 10), 60, Color(0.2, 0.14, 0.08, 0.4))
	draw_rect(Rect2(basket_pos.x - 55, basket_pos.y - 40, 110, 70), Color(0.55, 0.38, 0.2))
	draw_rect(Rect2(basket_pos.x - 55, basket_pos.y - 40, 110, 70), Color(0.7, 0.5, 0.28, glow), false, 5.0)
	# woven lines
	for i in range(1, 4):
		var yy := basket_pos.y - 40 + i * 17.0
		draw_line(Vector2(basket_pos.x - 55, yy), Vector2(basket_pos.x + 55, yy), Color(0.4, 0.27, 0.14), 3.0)
	draw_string(font, basket_pos + Vector2(-55, -54), "BASKET", HORIZONTAL_ALIGNMENT_CENTER, 110, 24, Color(1, 1, 1, 0.7))

func _draw_stem(f: Fruit) -> void:
	var to_anchor := f.anchor - f.pos
	var dist := to_anchor.length()
	if dist < 2.0:
		return
	var stretch: float = clamp((dist - rest_len) / pop_stretch, 0.0, 1.0)
	var col := Color(0.3, 0.45, 0.2).lerp(Color(0.7, 0.35, 0.3), stretch)
	draw_line(f.pos, f.anchor, col, lerp(6.0, 2.0, stretch))

func _draw_fruit(f: Fruit) -> void:
	var r := f.radius
	var col := _stage_color(f)
	var pop_squash := f.squash * 0.5
	var dirv := Vector2.UP
	if f.state == State.ATTACHED:
		var to_anchor := f.anchor - f.pos
		if to_anchor.length() > 0.001:
			dirv = -to_anchor.normalized()
	var sx: float = 1.0 + pop_squash
	var sy: float = 1.0 - pop_squash
	draw_set_transform(f.pos, dirv.angle() - PI / 2.0, Vector2(sx, sy))
	draw_circle(Vector2.ZERO, r, col.darkened(0.12))
	draw_circle(Vector2.ZERO, r * 0.9, col)
	draw_circle(Vector2(-r * 0.3, -r * 0.32), r * 0.26, col.lightened(0.45))
	# plump fruit sparkle
	if f.stage == Stage.PLUMP:
		draw_circle(Vector2(r * 0.32, -r * 0.3), r * 0.12, Color(1, 1, 1, 0.7 + 0.3 * sin(time * 8.0 + f.wobble_seed)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_character() -> void:
	var nozzle := char_pos + facing * nozzle_offset
	var sucking := Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	# suction range while active
	if sucking:
		draw_arc(nozzle, suction_radius, 0, TAU, 48, Color(1, 1, 1, 0.12), 2.0)
		for i in range(3):
			var ph: float = fmod(time * 1.5 + i / 3.0, 1.0)
			draw_arc(nozzle, lerp(suction_radius * 0.9, 20.0, ph), 0, TAU, 40, Color(0.7, 0.95, 1.0, (1.0 - ph) * 0.25), 2.0)
	# shadow + body
	draw_circle(char_pos + Vector2(0, 22), 24, Color(0, 0, 0, 0.25))
	draw_circle(char_pos, 26, Color(0.9, 0.7, 0.45))
	draw_circle(char_pos, 22, Color(0.95, 0.8, 0.55))
	# nozzle in facing direction
	var perp := facing.orthogonal()
	var tip := char_pos + facing * (nozzle_offset + 14.0)
	var pts := PackedVector2Array([
		char_pos + perp * 10.0, char_pos - perp * 10.0,
		tip - perp * 16.0, tip + perp * 16.0])
	draw_colored_polygon(pts, Color(0.35, 0.38, 0.44))
	draw_circle(tip, 16, Color(0.28, 0.3, 0.35))
	draw_circle(tip, 9, Color(0.1, 0.1, 0.12))
	if sucking:
		draw_arc(tip, 13, 0, TAU, 20, Color(0.5, 0.9, 1.0, 0.8), 3.0)

func _draw_popup(p: CustomPopup) -> void:
	var a: float = clamp(p.life, 0.0, 1.0)
	draw_string(font, p.pos - Vector2(60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, int(30 * p.scale), Color(p.color.r, p.color.g, p.color.b, a))

func _draw_hud() -> void:
	draw_string(font, Vector2(40, 62), "Score: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(1, 0.92, 0.5))
	var carry_col := Color(0.8, 1.0, 0.85) if carried_count < carry_capacity else Color(1, 0.6, 0.5)
	draw_string(font, Vector2(40, 110), "Basket: %d / %d  (worth %d)" % [carried_count, carry_capacity, carried_value],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 30, carry_col)
	if carried_count >= carry_capacity:
		draw_string(font, Vector2(40, 150), "FULL — go dump it in the basket!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.6, 0.5))
	draw_string(font, Vector2(view_size.x - 320, 62), "Rotted: %d" % rotted, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(0.75, 0.55, 0.4))
	if combo >= 2:
		draw_string(font, Vector2(view_size.x - 320, 104), "Combo x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.85, 0.4))
	draw_string(font, Vector2(40, view_size.y - 34),
		"WASD / arrows to move  •  hold SPACE or LEFT-MOUSE to vacuum ripe fruit  •  walk to the basket to deposit",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.65))
