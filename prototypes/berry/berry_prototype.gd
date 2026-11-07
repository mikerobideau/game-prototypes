extends Node2D
class_name BerryPrototype

# --- Tunable feel parameters (edit live in the Inspector while running) ---
@export_group("Grab")
@export var grab_radius: float = 170.0          # nozzle catches a berry within this
@export var follow_stiffness: float = 55.0      # how hard a caught berry chases the nozzle

@export_group("Stem")
@export var rest_len: float = 34.0              # slack before a stem resists
@export var stem_tension_linear: float = 12.0   # baseline pull toward the branch
@export var stem_tension_max: float = 2600.0    # peak resistance right before the snap
@export var pop_stretch: float = 150.0          # stretch distance that snaps the stem
@export var stem_damping: float = 9.0           # settle speed (higher = less jiggle)

@export_group("Juice")
@export var launch_speed: float = 1500.0        # how hard a popped berry rockets to the nozzle
@export var shake_per_pop: float = 9.0
@export var combo_window: float = 0.55          # seconds to chain pops for a combo

@export_group("Gun")
@export var fire_rate: float = 0.16             # seconds between shots (hold to auto-fire)
@export var gun_damage: float = 1.0
@export var aim_radius: float = 60.0            # how forgiving the aim is
@export var knockback: float = 280.0

@export_group("Robots")
@export var robot_speed: float = 165.0
@export var robot_hp: float = 3.0
@export var bite_dps: float = 10.0              # plant health drained per second while eating
@export var spawn_interval_start: float = 3.0
@export var spawn_interval_min: float = 0.9
@export var spawn_ramp: float = 0.94            # each spawn shortens the next interval
@export var plant_max_hp: float = 100.0
@export var plant_regen: float = 3.0            # plant health recovered per second

enum State { ATTACHED, DETACHED, COLLECTED }

class Berry:
	var anchor: Vector2      # fixed attach point on the branch
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var radius: float
	var color: Color
	var state: int = State.ATTACHED
	var squash: float = 0.0  # pop deformation impulse, decays to 0
	var wobble: float = 0.0
	var wobble_seed: float = 0.0
	var grabbed: bool = false

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

class Robot:
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var hp: float
	var max_hp: float
	var target: Vector2      # a point on the branch it wants to chew
	var eating: bool = false
	var hit_flash: float = 0.0
	var bob_seed: float = 0.0
	var dead: bool = false

var berries: Array[Berry] = []
var particles: Array[Particle] = []
var popups: Array[CustomPopup] = []
var robots: Array[Robot] = []

var view_size: Vector2
var branch_y: float
var shake_amt: float = 0.0
var combo: int = 0
var combo_timer: float = 0.0
var score: int = 0
var kills: int = 0
var time: float = 0.0

# gun / defense
var turret_pos: Vector2
var fire_cooldown: float = 0.0
var beam_life: float = 0.0
var beam_end: Vector2 = Vector2.ZERO
var plant_hp: float = 100.0
var flash_amt: float = 0.0
var robot_spawn_timer: float = 2.0
var spawn_interval: float = 3.0

# audio pool
var pop_stream: AudioStreamWAV
var collect_stream: AudioStreamWAV
var zap_stream: AudioStreamWAV
var explode_stream: AudioStreamWAV
var players: Array[AudioStreamPlayer] = []
var player_idx: int = 0

var font: Font

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	view_size = get_viewport_rect().size
	branch_y = view_size.y * 0.16
	turret_pos = Vector2(view_size.x * 0.5, view_size.y * 0.9)
	plant_hp = plant_max_hp
	spawn_interval = spawn_interval_start
	get_viewport().size_changed.connect(_on_resize)
	_build_audio()
	_spawn_cluster()
	set_process(true)

func _on_resize() -> void:
	view_size = get_viewport_rect().size
	branch_y = view_size.y * 0.16
	turret_pos = Vector2(view_size.x * 0.5, view_size.y * 0.9)

# ---------------------------------------------------------------- audio
func _build_audio() -> void:
	pop_stream = _make_pop(880.0, 150.0, 0.11)
	collect_stream = _make_pop(1400.0, 1900.0, 0.06)
	zap_stream = _make_pop(2200.0, 500.0, 0.05)
	explode_stream = _make_explosion(0.32)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

func _make_explosion(dur: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var t := float(i) / n
		var env: float = pow(1.0 - t, 1.8)
		var noise: float = (randf() * 2.0 - 1.0)
		var rumble: float = sin(TAU * 70.0 * (float(i) / rate))
		var s: float = (noise * 0.7 + rumble * 0.5) * env
		var v := int(clamp(s, -1.0, 1.0) * 30000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w

func _make_pop(f_start: float, f_end: float, dur: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / n
		# frequency glides start->end, amplitude decays fast (the "pop")
		var freq: float = lerp(f_start, f_end, t * t)
		phase += TAU * freq / rate
		var env: float = pow(1.0 - t, 2.4)
		var s: float = sin(phase) * env
		# a touch of attack noise for the "pft" of the snap
		if t < 0.06:
			s += (randf() * 2.0 - 1.0) * (1.0 - t / 0.06) * 0.5 * env
		var v := int(clamp(s, -1.0, 1.0) * 32000.0)
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

# ---------------------------------------------------------------- spawn
func _spawn_cluster() -> void:
	berries.clear()
	var count := randi_range(9, 14)
	var margin := view_size.x * 0.12
	for i in range(count):
		var b := Berry.new()
		var ax: float = randf_range(margin, view_size.x - margin)
		b.anchor = Vector2(ax, branch_y + randf_range(-8, 22))
		b.radius = randf_range(30, 52)
		b.pos = b.anchor + Vector2(randf_range(-10, 10), rest_len + b.radius)
		b.wobble_seed = randf() * TAU
		var hue := randf_range(0.92, 1.02)
		hue = fmod(hue, 1.0)
		b.color = Color.from_hsv(hue, randf_range(0.55, 0.8), randf_range(0.72, 0.95))
		berries.append(b)

# ---------------------------------------------------------------- update
func _process(delta: float) -> void:
	time += delta
	var mouse := get_local_mouse_position()
	var holding := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)  # pull berries
	var firing := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)    # shoot robots

	# combo decay
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

	var any_attached := false
	for b in berries:
		match b.state:
			State.ATTACHED:
				any_attached = true
				_update_attached(b, delta, mouse, holding)
			State.DETACHED:
				_update_detached(b, delta, mouse)
		b.squash = move_toward(b.squash, 0.0, delta * 4.0)

	var kept: Array[Berry] = []
	for b in berries:
		if b.state != State.COLLECTED:
			kept.append(b)
	berries = kept
	if not any_attached and berries.is_empty():
		_spawn_cluster()

	_update_robots(delta)
	_try_fire(delta, mouse, firing)

	# plant slowly recovers; low-health warning flash fades
	plant_hp = min(plant_max_hp, plant_hp + plant_regen * delta)
	beam_life = move_toward(beam_life, 0.0, delta * 8.0)
	flash_amt = move_toward(flash_amt, 0.0, delta * 2.0)

	_update_particles(delta)
	_update_popups(delta)

	if shake_amt > 0.0:
		shake_amt = move_toward(shake_amt, 0.0, delta * 60.0)
		position = Vector2(randf_range(-shake_amt, shake_amt), randf_range(-shake_amt, shake_amt))
	else:
		position = Vector2.ZERO

	queue_redraw()

func _update_attached(b: Berry, delta: float, mouse: Vector2, holding: bool) -> void:
	# gravity so berries hang naturally
	var force := Vector2(0, 380.0)

	# stem tension: pulls back toward the branch, ramping hard near the snap
	var to_anchor := b.anchor - b.pos
	var dist := to_anchor.length()
	var stretch: float = dist - rest_len
	if stretch > 0.0 and dist > 0.001:
		var dir := to_anchor / dist
		var t: float = clamp(stretch / pop_stretch, 0.0, 1.0)
		var tension: float = stem_tension_linear * stretch + stem_tension_max * t * t
		force += dir * tension

	# grab: once the nozzle catches a berry it stays latched and chases the
	# cursor, so dragging away from the branch keeps stretching until it snaps
	if holding:
		if not b.grabbed and (mouse - b.pos).length() < grab_radius:
			b.grabbed = true
	else:
		b.grabbed = false
	if b.grabbed:
		force += (mouse - b.pos) * follow_stiffness

	b.vel += force * delta
	b.vel *= exp(-stem_damping * delta)
	b.pos += b.vel * delta

	# recompute stretch after move for the pop test
	var new_stretch: float = (b.anchor - b.pos).length() - rest_len
	if new_stretch > pop_stretch:
		_pop(b, mouse)

func _pop(b: Berry, mouse: Vector2) -> void:
	b.state = State.DETACHED
	b.squash = 1.0
	var dir := (mouse - b.pos)
	if dir.length() > 0.001:
		dir = dir.normalized()
	else:
		dir = Vector2.UP
	b.vel = dir * launch_speed + b.vel * 0.3

	combo += 1
	combo_timer = combo_window
	var gain: int = combo
	score += gain

	shake_amt = min(shake_amt + shake_per_pop, 26.0)
	var pitch: float = (60.0 / b.radius) * randf_range(0.95, 1.08) * (1.0 + (combo - 1) * 0.05)
	_play(pop_stream, clamp(pitch, 0.6, 2.2))
	_spawn_splatter(b)

	var pop := CustomPopup.new()
	pop.pos = b.pos
	pop.life = 1.0
	pop.text = "+%d" % gain if combo < 2 else "x%d  +%d" % [combo, gain]
	pop.color = b.color.lightened(0.4)
	pop.scale = 1.0 + min(combo * 0.12, 1.2)
	popups.append(pop)

func _update_detached(b: Berry, delta: float, mouse: Vector2) -> void:
	# home into the nozzle, accelerating
	var to_suction := mouse - b.pos
	var sd := to_suction.length()
	if sd > 0.001:
		b.vel += (to_suction / sd) * 6000.0 * delta
	b.vel *= exp(-2.5 * delta)
	b.pos += b.vel * delta
	if sd < 46.0:
		b.state = State.COLLECTED
		_play(collect_stream, randf_range(0.9, 1.2))
		for i in range(4):
			_spawn_spark(mouse, b.color)

func _spawn_splatter(b: Berry) -> void:
	var n := int(10 + b.radius * 0.25)
	for i in range(n):
		var p := Particle.new()
		p.pos = b.pos
		var ang := randf() * TAU
		var spd := randf_range(120, 520)
		p.vel = Vector2(cos(ang), sin(ang)) * spd
		p.max_life = randf_range(0.35, 0.7)
		p.life = p.max_life
		p.size = randf_range(3, 9)
		p.color = b.color.lightened(randf_range(0.0, 0.35))
		particles.append(p)

func _spawn_spark(at: Vector2, col: Color) -> void:
	var p := Particle.new()
	p.pos = at
	var ang := randf() * TAU
	p.vel = Vector2(cos(ang), sin(ang)) * randf_range(80, 240)
	p.max_life = 0.3
	p.life = 0.3
	p.size = randf_range(2, 5)
	p.color = col.lightened(0.5)
	particles.append(p)

func _update_particles(delta: float) -> void:
	for p in particles:
		p.vel += Vector2(0, 900) * delta
		p.vel *= exp(-1.5 * delta)
		p.pos += p.vel * delta
		p.life -= delta
	var kept: Array[Particle] = []
	for p in particles:
		if p.life > 0.0:
			kept.append(p)
	particles = kept

func _update_popups(delta: float) -> void:
	for p in popups:
		p.pos.y -= 60.0 * delta
		p.life -= delta
	var kept: Array[CustomPopup] = []
	for p in popups:
		if p.life > 0.0:
			kept.append(p)
	popups = kept

# ---------------------------------------------------------------- robots + gun
func _spawn_robot() -> void:
	var r := Robot.new()
	var edge := randi() % 3
	match edge:
		0: r.pos = Vector2(randf_range(0, view_size.x), -60)          # top
		1: r.pos = Vector2(-60, randf_range(-40, view_size.y * 0.5))  # left
		_: r.pos = Vector2(view_size.x + 60, randf_range(-40, view_size.y * 0.5))
	r.target = Vector2(randf_range(view_size.x * 0.15, view_size.x * 0.85), branch_y)
	r.max_hp = robot_hp
	r.hp = robot_hp
	r.bob_seed = randf() * TAU
	robots.append(r)

func _update_robots(delta: float) -> void:
	robot_spawn_timer -= delta
	if robot_spawn_timer <= 0.0:
		_spawn_robot()
		spawn_interval = max(spawn_interval_min, spawn_interval * spawn_ramp)
		robot_spawn_timer = spawn_interval

	for r in robots:
		if r.dead:
			continue
		r.hit_flash = move_toward(r.hit_flash, 0.0, delta * 4.0)
		var to_t := r.target - r.pos
		var d := to_t.length()
		if d > 66.0:
			r.eating = false
			var desired := (to_t / d) * robot_speed
			r.vel = r.vel.lerp(desired, 1.0 - exp(-3.0 * delta))
		else:
			r.eating = true
			r.vel *= exp(-6.0 * delta)
			var before := plant_hp
			plant_hp = max(0.0, plant_hp - bite_dps * delta)
			if before > 0.0 and plant_hp <= 0.0:
				_plant_overrun()
			if plant_hp < plant_max_hp * 0.35:
				flash_amt = max(flash_amt, 0.5)
		r.pos += r.vel * delta

	var kept: Array[Robot] = []
	for r in robots:
		if not r.dead:
			kept.append(r)
	robots = kept

func _try_fire(delta: float, cursor: Vector2, firing: bool) -> void:
	fire_cooldown -= delta
	if firing and fire_cooldown <= 0.0:
		fire_cooldown = fire_rate
		_fire(cursor)

func _fire(cursor: Vector2) -> void:
	beam_end = cursor
	beam_life = 1.0
	_play(zap_stream, randf_range(0.9, 1.15))

	var best: Robot = null
	var best_d := aim_radius
	for r in robots:
		if r.dead:
			continue
		var dd := (r.pos - cursor).length()
		if dd < best_d:
			best_d = dd
			best = r
	if best == null:
		_spawn_spark(cursor, Color(0.6, 0.9, 1.0))
		return

	best.hp -= gun_damage
	best.hit_flash = 1.0
	best.vel += (best.pos - turret_pos).normalized() * knockback
	for i in range(3):
		_spawn_spark(best.pos, Color(1.0, 0.7, 0.3))
	if best.hp <= 0.0:
		_kill_robot(best)

func _kill_robot(r: Robot) -> void:
	r.dead = true
	kills += 1
	shake_amt = min(shake_amt + 6.0, 26.0)
	_play(explode_stream, randf_range(0.9, 1.15))
	for i in range(16):
		var p := Particle.new()
		p.pos = r.pos
		var ang := randf() * TAU
		p.vel = Vector2(cos(ang), sin(ang)) * randf_range(120, 460)
		p.max_life = randf_range(0.3, 0.6)
		p.life = p.max_life
		p.size = randf_range(3, 8)
		var warm := randf() < 0.5
		p.color = Color(1.0, 0.6, 0.2) if warm else Color(0.6, 0.62, 0.68)
		particles.append(p)

func _plant_overrun() -> void:
	# soft failure: you lose the current harvest but the plant regrows -- no dead end
	shake_amt = 24.0
	flash_amt = 1.0
	_play(explode_stream, 0.6)
	for b in berries:
		if b.state == State.ATTACHED:
			_spawn_splatter(b)
			b.state = State.COLLECTED  # destroyed harvest, not collected into the nozzle
	for r in robots:
		r.vel += (r.pos - Vector2(view_size.x * 0.5, branch_y)).normalized() * 260.0
	plant_hp = plant_max_hp * 0.5

# ---------------------------------------------------------------- draw
func _draw() -> void:
	_draw_background()
	_draw_branch()

	var mouse := get_local_mouse_position()
	var pulling := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	for b in berries:
		if b.state == State.ATTACHED:
			_draw_stem(b)
	for b in berries:
		_draw_berry(b)

	for r in robots:
		_draw_robot(r)

	for p in particles:
		var a: float = p.life / p.max_life
		draw_circle(p.pos, p.size * a, Color(p.color.r, p.color.g, p.color.b, a))

	_draw_turret(mouse)
	if beam_life > 0.0:
		draw_line(turret_pos, beam_end, Color(0.6, 0.95, 1.0, beam_life), lerp(2.0, 9.0, beam_life))
		draw_circle(beam_end, lerp(4.0, 20.0, beam_life), Color(0.8, 1.0, 1.0, beam_life * 0.8))
	_draw_nozzle(mouse, pulling)

	for p in popups:
		_draw_popup(p)

	if flash_amt > 0.0:
		var fpad := 80.0
		draw_rect(Rect2(-fpad, -fpad, view_size.x + fpad * 2, view_size.y + fpad * 2),
			Color(0.9, 0.15, 0.1, flash_amt * 0.35))

	_draw_plant_bar()

	# hud
	draw_string(font, Vector2(40, 60), "Score: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.WHITE)
	draw_string(font, Vector2(40, 104), "Robots down: %d" % kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.8, 0.9, 1.0))
	if combo >= 2:
		draw_string(font, Vector2(40, 148), "Combo x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1, 0.85, 0.4))
	draw_string(font, Vector2(40, view_size.y - 40),
		"RIGHT-DRAG near berries to pull  •  LEFT-CLICK to shoot robots",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.6))

func _draw_plant_bar() -> void:
	var bw := view_size.x * 0.32
	var bx := view_size.x * 0.5 - bw * 0.5
	var by := 34.0
	var frac: float = clamp(plant_hp / plant_max_hp, 0.0, 1.0)
	draw_rect(Rect2(bx - 3, by - 3, bw + 6, 28), Color(0, 0, 0, 0.45))
	var hc := Color(0.85, 0.3, 0.2).lerp(Color(0.35, 0.8, 0.35), frac)
	draw_rect(Rect2(bx, by, bw * frac, 22), hc)
	draw_string(font, Vector2(bx, by - 8), "PLANT", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.7))

func _draw_turret(cursor: Vector2) -> void:
	var aim := cursor - turret_pos
	var ang := aim.angle()
	draw_set_transform(turret_pos, ang, Vector2.ONE)
	draw_rect(Rect2(0, -7, 58, 14), Color(0.4, 0.42, 0.48))
	draw_rect(Rect2(48, -9, 10, 18), Color(0.55, 0.58, 0.64))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(turret_pos, 28, Color(0.22, 0.24, 0.28))
	draw_circle(turret_pos, 22, Color(0.32, 0.35, 0.4))
	draw_circle(turret_pos, 9, Color(0.5, 0.9, 1.0, 0.8))

func _draw_robot(r: Robot) -> void:
	var bob := Vector2(0, sin(time * 6.0 + r.bob_seed) * 6.0)
	var p := r.pos + bob
	# spinning rotor
	var ra := time * 26.0 + r.bob_seed
	var rc := p + Vector2(0, -20)
	var rd := Vector2(cos(ra), sin(ra) * 0.35) * 26.0
	draw_line(rc - rd, rc + rd, Color(0.75, 0.78, 0.82, 0.5), 4.0)
	draw_line(rc, p, Color(0.3, 0.32, 0.36), 3.0)
	# body
	var body := Color(0.46, 0.48, 0.54)
	if r.hit_flash > 0.0:
		body = body.lerp(Color.WHITE, r.hit_flash)
	draw_circle(p, 22, body.darkened(0.25))
	draw_circle(p, 18, body)
	# eye (red while flying, orange while chewing)
	var eye := Color(1.0, 0.6, 0.15) if r.eating else Color(1.0, 0.25, 0.2)
	draw_circle(p + Vector2(0, 2), 8, eye)
	draw_circle(p + Vector2(-2, 0), 3, Color(1, 1, 1, 0.85))
	# hp pips
	if r.hp < r.max_hp:
		var bw := 34.0
		draw_rect(Rect2(p.x - bw * 0.5, p.y - 34, bw, 5), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(p.x - bw * 0.5, p.y - 34, bw * clamp(r.hp / r.max_hp, 0, 1), 5), Color(0.4, 0.9, 0.4))

func _draw_background() -> void:
	var top := Color(0.36, 0.62, 0.78)
	var bot := Color(0.66, 0.82, 0.72)
	var pad := 60.0
	var pts := PackedVector2Array([
		Vector2(-pad, -pad), Vector2(view_size.x + pad, -pad),
		Vector2(view_size.x + pad, view_size.y + pad), Vector2(-pad, view_size.y + pad)])
	var cols := PackedColorArray([top, top, bot, bot])
	draw_polygon(pts, cols)

func _draw_branch() -> void:
	var col := Color(0.38, 0.26, 0.18)
	draw_line(Vector2(-40, branch_y - 26), Vector2(view_size.x + 40, branch_y - 10), col, 40.0)
	# little leaves
	for b in berries:
		if b.state == State.ATTACHED:
			var leaf := Color(0.3, 0.55, 0.25)
			draw_circle(b.anchor + Vector2(-6, -4), 9, leaf)
			draw_circle(b.anchor + Vector2(7, -6), 7, leaf.lightened(0.1))

func _draw_stem(b: Berry) -> void:
	var to_anchor := b.anchor - b.pos
	var dist := to_anchor.length()
	var stretch: float = clamp((dist - rest_len) / pop_stretch, 0.0, 1.0)
	# stem thins and reddens as it strains
	var width: float = lerp(7.0, 2.0, stretch)
	var col := Color(0.35, 0.5, 0.22).lerp(Color(0.75, 0.35, 0.3), stretch)
	# slight bowed curve using a midpoint, with tension wobble
	var mid := b.pos.lerp(b.anchor, 0.5)
	var perp := to_anchor.orthogonal().normalized()
	var wob: float = sin(time * 18.0 + b.wobble_seed) * (2.0 + stretch * 6.0)
	mid += perp * wob
	var prev := b.pos
	var steps := 10
	for i in range(1, steps + 1):
		var t := float(i) / steps
		var q := b.pos.lerp(mid, t).lerp(mid.lerp(b.anchor, t), t)
		draw_line(prev, q, col, width)
		prev = q

func _draw_berry(b: Berry) -> void:
	var r := b.radius
	# squash & stretch: elongate toward the pull while attached, squish on pop
	var dirv := Vector2.DOWN
	var stretch_amt := 0.0
	if b.state == State.ATTACHED:
		var to_anchor := b.anchor - b.pos
		if to_anchor.length() > 0.001:
			dirv = -to_anchor.normalized()
		stretch_amt = clamp(((b.anchor - b.pos).length() - rest_len) / pop_stretch, 0.0, 1.0) * 0.4
	var pop_squash := b.squash * 0.5
	var sx: float = 1.0 - stretch_amt * 0.5 + pop_squash
	var sy: float = 1.0 + stretch_amt - pop_squash

	var ang := dirv.angle() - PI / 2.0
	draw_set_transform(b.pos, ang, Vector2(sx, sy))
	# body
	draw_circle(Vector2.ZERO, r, b.color.darkened(0.1))
	draw_circle(Vector2.ZERO, r * 0.92, b.color)
	# highlight
	draw_circle(Vector2(-r * 0.3, -r * 0.35), r * 0.28, b.color.lightened(0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_nozzle(mouse: Vector2, holding: bool) -> void:
	var base := Color(0.2, 0.22, 0.26)
	var rim := Color(0.5, 0.55, 0.62)
	# intake range ring
	var ring_a := 0.10 + (0.14 if holding else 0.0)
	draw_arc(mouse, grab_radius, 0, TAU, 48, Color(1, 1, 1, ring_a), 3.0)
	# animated suck rings when active
	if holding:
		for i in range(3):
			var phase: float = fmod(time * 1.4 + i / 3.0, 1.0)
			var rr: float = lerp(grab_radius * 0.9, 24.0, phase)
			draw_arc(mouse, rr, 0, TAU, 40, Color(1, 1, 1, (1.0 - phase) * 0.35), 2.0)
	# nozzle body
	draw_circle(mouse, 34, base)
	draw_arc(mouse, 34, 0, TAU, 32, rim, 4.0)
	draw_circle(mouse, 18, Color(0.08, 0.09, 0.11))
	if holding:
		draw_arc(mouse, 26, 0, TAU, 24, Color(0.4, 0.8, 1.0, 0.8), 3.0)

func _draw_popup(p: CustomPopup) -> void:
	var a: float = clamp(p.life, 0.0, 1.0)
	var sz := int(30 * p.scale)
	var col := Color(p.color.r, p.color.g, p.color.b, a)
	draw_string(font, p.pos - Vector2(20, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, -1, sz, col)
