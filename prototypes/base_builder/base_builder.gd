extends Node2D
class_name BaseBuilder

# ---- Tunable balance (edit live in the Inspector) ----
@export_group("Economy")
@export var start_seeds: int = 60
@export var bush_cost: int = 12
@export var turret_cost: int = 25
@export var wall_cost: int = 5
@export var bush_max_berries: int = 5
@export var bush_grow_time: float = 2.2      # seconds per berry
@export var berry_value: int = 3             # seeds per berry harvested
@export var kill_bounty: int = 2             # seeds per robot destroyed

@export_group("Defense")
@export var turret_range: float = 300.0
@export var turret_fire_rate: float = 0.55
@export var turret_damage: float = 1.0
@export var bullet_speed: float = 780.0

@export_group("Enemies")
@export var robot_speed: float = 58.0
@export var robot_hp: float = 3.0
@export var robot_damage: float = 2.5        # structure hp drained per second
@export var wave_build_time: float = 14.0    # calm phase length
@export var wave_spawn_gap: float = 0.8

@export_group("Structure HP")
@export var core_hp: float = 30.0
@export var bush_hp: float = 6.0
@export var turret_hp: float = 6.0
@export var wall_hp: float = 14.0

const CELL := 96.0
const MARGIN_TOP := 150.0
const MARGIN_BOTTOM := 170.0

enum Kind { CORE, BUSH, TURRET, WALL }
enum Phase { BUILD, WAVE }

class Structure:
	var kind: int
	var cell: Vector2i
	var pos: Vector2
	var hp: float
	var max_hp: float
	var berries: int = 0
	var grow_timer: float = 0.0
	var cooldown: float = 0.0
	var aim: float = -PI / 2.0
	var flash: float = 0.0

class Robot:
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var hp: float
	var max_hp: float
	var hit_flash: float = 0.0
	var bob_seed: float = 0.0
	var dead: bool = false

class Bullet:
	var pos: Vector2
	var vel: Vector2
	var life: float = 1.2
	var damage: float

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

var structures: Dictionary = {}      # Vector2i -> Structure
var core: Structure = null
var robots: Array[Robot] = []
var bullets: Array[Bullet] = []
var particles: Array[Particle] = []
var popups: Array[CustomPopup] = []

var view_size: Vector2
var grid_origin: Vector2
var cols: int
var rows: int

var seeds: int = 60
var mode: int = -1                   # -1 = harvest/select, else a Kind to build
var phase: int = Phase.BUILD
var build_timer: float = 0.0
var wave_number: int = 0
var wave_to_spawn: int = 0
var spawn_timer: float = 0.0
var game_over: bool = false

var shake_amt: float = 0.0
var flash_amt: float = 0.0
var time: float = 0.0

var toolbar: Array = []              # [{rect, mode, label, cost, key}]

# audio
var players: Array[AudioStreamPlayer] = []
var player_idx: int = 0
var s_harvest: AudioStreamWAV
var s_shoot: AudioStreamWAV
var s_explode: AudioStreamWAV
var s_place: AudioStreamWAV
var s_error: AudioStreamWAV

var font: Font

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	view_size = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_resize)
	_build_audio()
	_layout()
	_reset_game()
	set_process(true)

func _on_resize() -> void:
	view_size = get_viewport_rect().size
	_layout()
	for s in structures.values():
		s.pos = _cell_center(s.cell)

func _layout() -> void:
	var play_h := view_size.y - MARGIN_TOP - MARGIN_BOTTOM
	cols = int(view_size.x / CELL)
	rows = int(play_h / CELL)
	grid_origin = Vector2(
		(view_size.x - cols * CELL) * 0.5,
		MARGIN_TOP + (play_h - rows * CELL) * 0.5)
	# toolbar buttons
	toolbar = []
	var defs := [
		{"mode": -1, "label": "Harvest", "cost": 0, "key": "1"},
		{"mode": Kind.BUSH, "label": "Bush", "cost": bush_cost, "key": "2"},
		{"mode": Kind.TURRET, "label": "Turret", "cost": turret_cost, "key": "3"},
		{"mode": Kind.WALL, "label": "Wall", "cost": wall_cost, "key": "4"},
	]
	var bw := 240.0
	var bh := 96.0
	var gap := 20.0
	var total := defs.size() * bw + (defs.size() - 1) * gap
	var x := (view_size.x - total) * 0.5
	var y := view_size.y - MARGIN_BOTTOM + 30.0
	for d in defs:
		toolbar.append({"rect": Rect2(x, y, bw, bh), "mode": d.mode, "label": d.label, "cost": d.cost, "key": d.key})
		x += bw + gap

# ---------------------------------------------------------------- grid helpers
func _cell_at(p: Vector2) -> Vector2i:
	return Vector2i(int(floor((p.x - grid_origin.x) / CELL)), int(floor((p.y - grid_origin.y) / CELL)))

func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows

func _cell_center(c: Vector2i) -> Vector2:
	return grid_origin + Vector2((c.x + 0.5) * CELL, (c.y + 0.5) * CELL)

# ---------------------------------------------------------------- setup / reset
func _reset_game() -> void:
	structures.clear()
	robots.clear()
	bullets.clear()
	particles.clear()
	popups.clear()
	seeds = start_seeds
	wave_number = 0
	phase = Phase.BUILD
	build_timer = wave_build_time
	game_over = false
	mode = -1
	var mid := Vector2i(int(cols / 2.0), int(rows / 2.0))
	core = _make_struct(Kind.CORE, mid)
	structures[mid] = core
	# a couple of starter bushes flanking the core
	_place_free(Kind.BUSH, mid + Vector2i(-2, 0))
	_place_free(Kind.BUSH, mid + Vector2i(2, 0))

func _make_struct(kind: int, cell: Vector2i) -> Structure:
	var s := Structure.new()
	s.kind = kind
	s.cell = cell
	s.pos = _cell_center(cell)
	match kind:
		Kind.CORE: s.max_hp = core_hp
		Kind.BUSH: s.max_hp = bush_hp
		Kind.TURRET: s.max_hp = turret_hp
		Kind.WALL: s.max_hp = wall_hp
	s.hp = s.max_hp
	s.grow_timer = bush_grow_time
	return s

func _place_free(kind: int, cell: Vector2i) -> void:
	if _in_grid(cell) and not structures.has(cell):
		structures[cell] = _make_struct(kind, cell)

func _cost_of(kind: int) -> int:
	match kind:
		Kind.BUSH: return bush_cost
		Kind.TURRET: return turret_cost
		Kind.WALL: return wall_cost
	return 0

# ---------------------------------------------------------------- input
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: mode = -1
			KEY_2: mode = Kind.BUSH
			KEY_3: mode = Kind.TURRET
			KEY_4: mode = Kind.WALL
			KEY_ESCAPE: mode = -1
			KEY_SPACE:
				if phase == Phase.BUILD and not game_over:
					_start_wave()
			KEY_R:
				if game_over:
					_reset_game()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			mode = -1
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(get_local_mouse_position())

func _on_left_click(m: Vector2) -> void:
	if game_over:
		_reset_game()
		return
	# toolbar first
	for b in toolbar:
		if (b.rect as Rect2).has_point(m):
			mode = b.mode
			return
	var cell := _cell_at(m)
	if not _in_grid(cell):
		return
	if mode == -1:
		_harvest(cell)
	else:
		_try_place(cell)

func _harvest(cell: Vector2i) -> void:
	if not structures.has(cell):
		return
	var s: Structure = structures[cell]
	if s.kind != Kind.BUSH or s.berries <= 0:
		return
	var gain: int = s.berries * berry_value
	seeds += gain
	_play(s_harvest, randf_range(0.95, 1.15))
	for i in range(s.berries * 3):
		_spawn_splatter(s.pos, Color(0.8, 0.2, 0.4))
	_popup(s.pos, "+%d" % gain, Color(1, 0.9, 0.5), 1.0)
	s.berries = 0
	s.grow_timer = bush_grow_time

func _try_place(cell: Vector2i) -> void:
	if structures.has(cell):
		return
	var cost := _cost_of(mode)
	if seeds < cost:
		_play(s_error, 1.0)
		flash_amt = 0.4
		return
	seeds -= cost
	structures[cell] = _make_struct(mode, cell)
	_play(s_place, randf_range(0.95, 1.05))
	for i in range(6):
		_spawn_splatter(_cell_center(cell), Color(0.7, 0.7, 0.5))

# ---------------------------------------------------------------- update
func _process(delta: float) -> void:
	time += delta
	if not game_over:
		_update_phase(delta)
		_update_structures(delta)
		_update_robots(delta)
		_update_bullets(delta)
	_update_particles(delta)
	_update_popups(delta)

	shake_amt = move_toward(shake_amt, 0.0, delta * 60.0)
	flash_amt = move_toward(flash_amt, 0.0, delta * 1.5)
	position = Vector2(randf_range(-shake_amt, shake_amt), randf_range(-shake_amt, shake_amt)) if shake_amt > 0.0 else Vector2.ZERO
	queue_redraw()

func _update_phase(delta: float) -> void:
	if phase == Phase.BUILD:
		build_timer -= delta
		if build_timer <= 0.0:
			_start_wave()
	else:
		if wave_to_spawn > 0:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				_spawn_robot()
				wave_to_spawn -= 1
				spawn_timer = wave_spawn_gap
		elif robots.is_empty():
			# wave cleared -> reward + back to building
			phase = Phase.BUILD
			build_timer = wave_build_time
			seeds += wave_number * 5
			_popup(core.pos - Vector2(0, 90), "WAVE CLEARED  +%d" % (wave_number * 5), Color(0.6, 1, 0.7), 1.4)

func _start_wave() -> void:
	phase = Phase.WAVE
	wave_number += 1
	wave_to_spawn = 3 + wave_number * 2
	spawn_timer = 0.0

func _spawn_robot() -> void:
	var r := Robot.new()
	var edge := randi() % 4
	match edge:
		0: r.pos = Vector2(randf_range(0, view_size.x), grid_origin.y - 40)
		1: r.pos = Vector2(randf_range(0, view_size.x), grid_origin.y + rows * CELL + 40)
		2: r.pos = Vector2(grid_origin.x - 40, randf_range(grid_origin.y, grid_origin.y + rows * CELL))
		_: r.pos = Vector2(grid_origin.x + cols * CELL + 40, randf_range(grid_origin.y, grid_origin.y + rows * CELL))
	r.max_hp = robot_hp
	r.hp = robot_hp
	r.bob_seed = randf() * TAU
	robots.append(r)

func _update_structures(delta: float) -> void:
	for s in structures.values():
		s.flash = move_toward(s.flash, 0.0, delta * 4.0)
		if s.kind == Kind.BUSH:
			if s.berries < bush_max_berries:
				s.grow_timer -= delta
				if s.grow_timer <= 0.0:
					s.berries += 1
					s.grow_timer = bush_grow_time
		elif s.kind == Kind.TURRET:
			s.cooldown -= delta
			if s.cooldown <= 0.0:
				var target := _nearest_robot(s.pos, turret_range)
				if target != null:
					s.aim = (target.pos - s.pos).angle()
					_fire_bullet(s.pos, target)
					s.cooldown = turret_fire_rate

func _nearest_robot(from: Vector2, rng: float) -> Robot:
	var best: Robot = null
	var best_d := rng
	for r in robots:
		if r.dead:
			continue
		var d := (r.pos - from).length()
		if d < best_d:
			best_d = d
			best = r
	return best

func _fire_bullet(from: Vector2, target: Robot) -> void:
	var b := Bullet.new()
	b.pos = from
	b.damage = turret_damage
	var lead := target.pos + target.vel * 0.12
	b.vel = (lead - from).normalized() * bullet_speed
	bullets.append(b)
	_play(s_shoot, randf_range(0.95, 1.1))

func _update_robots(delta: float) -> void:
	for r in robots:
		if r.dead:
			continue
		r.hit_flash = move_toward(r.hit_flash, 0.0, delta * 4.0)
		var tgt := _robot_target(r)
		if tgt == null:
			continue
		var to := tgt.pos - r.pos
		var d := to.length()
		var reach := CELL * 0.5 + 18.0
		if d > reach:
			var desired := (to / d) * robot_speed
			r.vel = r.vel.lerp(desired, 1.0 - exp(-4.0 * delta))
			r.pos += r.vel * delta
		else:
			r.vel *= exp(-8.0 * delta)
			tgt.hp -= robot_damage * delta
			tgt.flash = 0.6
			if tgt.hp <= 0.0:
				_destroy_structure(tgt)
	var kept: Array[Robot] = []
	for r in robots:
		if not r.dead:
			kept.append(r)
	robots = kept

func _robot_target(r: Robot) -> Structure:
	if core == null:
		return null
	var dir := core.pos - r.pos
	if dir.length() < 1.0:
		return core
	dir = dir.normalized()
	var ahead := _cell_at(r.pos + dir * CELL * 0.6)
	if structures.has(ahead):
		return structures[ahead]
	return core

func _destroy_structure(s: Structure) -> void:
	structures.erase(s.cell)
	shake_amt = min(shake_amt + 8.0, 26.0)
	_play(s_explode, randf_range(0.8, 1.0))
	for i in range(12):
		_spawn_splatter(s.pos, Color(0.6, 0.6, 0.62))
	if s == core:
		core = null
		game_over = true
		flash_amt = 1.0
		shake_amt = 26.0

func _update_bullets(delta: float) -> void:
	for b in bullets:
		b.pos += b.vel * delta
		b.life -= delta
		for r in robots:
			if r.dead:
				continue
			if (r.pos - b.pos).length() < 24.0:
				r.hp -= b.damage
				r.hit_flash = 1.0
				b.life = 0.0
				_spawn_splatter(b.pos, Color(1, 0.7, 0.3))
				if r.hp <= 0.0:
					_kill_robot(r)
				break
	var kept: Array[Bullet] = []
	for b in bullets:
		if b.life > 0.0:
			kept.append(b)
	bullets = kept

func _kill_robot(r: Robot) -> void:
	r.dead = true
	seeds += kill_bounty
	shake_amt = min(shake_amt + 5.0, 26.0)
	_play(s_explode, randf_range(0.95, 1.15))
	for i in range(14):
		var p := Particle.new()
		p.pos = r.pos
		var ang := randf() * TAU
		p.vel = Vector2(cos(ang), sin(ang)) * randf_range(120, 420)
		p.max_life = randf_range(0.3, 0.6)
		p.life = p.max_life
		p.size = randf_range(3, 8)
		p.color = Color(1.0, 0.6, 0.2) if randf() < 0.5 else Color(0.6, 0.62, 0.68)
		particles.append(p)

# ---------------------------------------------------------------- fx helpers
func _spawn_splatter(at: Vector2, col: Color) -> void:
	var p := Particle.new()
	p.pos = at
	var ang := randf() * TAU
	p.vel = Vector2(cos(ang), sin(ang)) * randf_range(80, 360)
	p.max_life = randf_range(0.3, 0.6)
	p.life = p.max_life
	p.size = randf_range(3, 8)
	p.color = col.lightened(randf_range(0.0, 0.3))
	particles.append(p)

func _popup(at: Vector2, text: String, col: Color, scale: float) -> void:
	var p := CustomPopup.new()
	p.pos = at
	p.life = 1.2
	p.text = text
	p.color = col
	p.scale = scale
	popups.append(p)

func _update_particles(delta: float) -> void:
	for p in particles:
		p.vel *= exp(-2.0 * delta)
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

# ---------------------------------------------------------------- audio
func _build_audio() -> void:
	s_harvest = _make_tone(880.0, 150.0, 0.11, 0.5)
	s_shoot = _make_tone(1600.0, 700.0, 0.05, 0.3)
	s_explode = _make_noise(0.3)
	s_place = _make_tone(300.0, 520.0, 0.08, 0.0)
	s_error = _make_tone(200.0, 140.0, 0.12, 0.0)
	for i in range(10):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

func _make_tone(f_start: float, f_end: float, dur: float, noise_amt: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / n
		var freq: float = lerp(f_start, f_end, t * t)
		phase += TAU * freq / rate
		var env: float = pow(1.0 - t, 2.2)
		var s: float = sin(phase) * env
		if noise_amt > 0.0 and t < 0.06:
			s += (randf() * 2.0 - 1.0) * (1.0 - t / 0.06) * noise_amt * env
		var v := int(clamp(s, -1.0, 1.0) * 30000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return _wav(bytes, rate)

func _make_noise(dur: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var t := float(i) / n
		var env: float = pow(1.0 - t, 1.8)
		var s: float = ((randf() * 2.0 - 1.0) * 0.7 + sin(TAU * 70.0 * (float(i) / rate)) * 0.5) * env
		var v := int(clamp(s, -1.0, 1.0) * 30000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return _wav(bytes, rate)

func _wav(bytes: PackedByteArray, rate: int) -> AudioStreamWAV:
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

# ---------------------------------------------------------------- draw
func _draw() -> void:
	_draw_ground()
	_draw_grid()

	var m := get_local_mouse_position()
	var hover := _cell_at(m)

	for s in structures.values():
		_draw_structure(s)

	# build ghost
	if mode != -1 and _in_grid(hover) and not _is_over_toolbar(m):
		var can := not structures.has(hover) and seeds >= _cost_of(mode)
		var c := _cell_center(hover)
		var col := Color(0.4, 1.0, 0.5, 0.35) if can else Color(1.0, 0.3, 0.3, 0.35)
		draw_rect(Rect2(c - Vector2(CELL, CELL) * 0.5 + Vector2(4, 4), Vector2(CELL - 8, CELL - 8)), col)

	for r in robots:
		if not r.dead:
			_draw_robot(r)
	for b in bullets:
		draw_circle(b.pos, 6.0, Color(0.7, 0.95, 1.0))
		draw_circle(b.pos, 10.0, Color(0.7, 0.95, 1.0, 0.25))

	for p in particles:
		var a: float = p.life / p.max_life
		draw_circle(p.pos, p.size * a, Color(p.color.r, p.color.g, p.color.b, a))
	for p in popups:
		_draw_popup(p)

	if flash_amt > 0.0:
		draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.9, 0.15, 0.1, flash_amt * 0.35))

	_draw_hud()
	_draw_toolbar(m)
	if game_over:
		_draw_game_over()

func _draw_ground() -> void:
	draw_rect(Rect2(-80, -80, view_size.x + 160, view_size.y + 160), Color(0.28, 0.34, 0.24))

func _draw_grid() -> void:
	var gcol := Color(1, 1, 1, 0.06)
	draw_rect(Rect2(grid_origin, Vector2(cols * CELL, rows * CELL)), Color(0.32, 0.4, 0.28))
	for x in range(cols + 1):
		var px := grid_origin.x + x * CELL
		draw_line(Vector2(px, grid_origin.y), Vector2(px, grid_origin.y + rows * CELL), gcol, 2.0)
	for y in range(rows + 1):
		var py := grid_origin.y + y * CELL
		draw_line(Vector2(grid_origin.x, py), Vector2(grid_origin.x + cols * CELL, py), gcol, 2.0)

func _draw_structure(s: Structure) -> void:
	var c := s.pos
	var r := CELL * 0.42
	match s.kind:
		Kind.CORE:
			draw_circle(c, r + 4, Color(0.15, 0.3, 0.45))
			draw_circle(c, r, Color(0.3, 0.6, 0.9))
			draw_circle(c, r * 0.5, Color(0.7, 0.9, 1.0, 0.8 + 0.2 * sin(time * 3.0)))
		Kind.BUSH:
			draw_circle(c, r, Color(0.2, 0.5, 0.25))
			draw_circle(c, r * 0.8, Color(0.28, 0.62, 0.32))
			# berries growing on it
			for i in range(s.berries):
				var ang := TAU * i / float(bush_max_berries) - PI / 2.0
				var bp := c + Vector2(cos(ang), sin(ang)) * r * 0.55
				draw_circle(bp, 9.0, Color(0.85, 0.2, 0.4))
				draw_circle(bp + Vector2(-2, -2), 3.0, Color(1, 0.7, 0.8, 0.8))
			if s.berries >= bush_max_berries:
				draw_arc(c, r + 6, 0, TAU, 28, Color(1, 0.9, 0.4, 0.5 + 0.3 * sin(time * 6.0)), 3.0)
		Kind.TURRET:
			draw_circle(c, r, Color(0.3, 0.32, 0.36))
			draw_set_transform(c, s.aim, Vector2.ONE)
			draw_rect(Rect2(0, -8, r + 16, 16), Color(0.5, 0.53, 0.6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(c, r * 0.4, Color(0.55, 0.85, 1.0))
		Kind.WALL:
			draw_rect(Rect2(c - Vector2(r, r), Vector2(r * 2, r * 2)), Color(0.45, 0.42, 0.38))
			draw_rect(Rect2(c - Vector2(r, r) + Vector2(6, 6), Vector2(r * 2 - 12, r * 2 - 12)), Color(0.55, 0.5, 0.44))
	if s.flash > 0.0:
		draw_circle(c, r, Color(1, 0.4, 0.3, s.flash * 0.5))
	# hp bar
	if s.hp < s.max_hp:
		var bw := CELL * 0.7
		var frac: float = clamp(s.hp / s.max_hp, 0.0, 1.0)
		draw_rect(Rect2(c.x - bw * 0.5, c.y - r - 16, bw, 7), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(c.x - bw * 0.5, c.y - r - 16, bw * frac, 7), Color(0.4, 0.85, 0.4).lerp(Color(0.9, 0.3, 0.2), 1.0 - frac))

func _draw_robot(r: Robot) -> void:
	var bob := Vector2(0, sin(time * 6.0 + r.bob_seed) * 5.0)
	var p := r.pos + bob
	var ra := time * 26.0 + r.bob_seed
	var rd := Vector2(cos(ra), sin(ra) * 0.4) * 24.0
	draw_line(p - rd, p + rd, Color(0.75, 0.78, 0.82, 0.5), 4.0)
	var body := Color(0.46, 0.48, 0.54)
	if r.hit_flash > 0.0:
		body = body.lerp(Color.WHITE, r.hit_flash)
	draw_circle(p, 20, body.darkened(0.25))
	draw_circle(p, 16, body)
	draw_circle(p, 6, Color(1.0, 0.25, 0.2))
	if r.hp < r.max_hp:
		var bw := 32.0
		draw_rect(Rect2(p.x - bw * 0.5, p.y - 30, bw, 5), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(p.x - bw * 0.5, p.y - 30, bw * clamp(r.hp / r.max_hp, 0, 1), 5), Color(0.4, 0.9, 0.4))

func _draw_popup(p: CustomPopup) -> void:
	var a: float = clamp(p.life, 0.0, 1.0)
	draw_string(font, p.pos - Vector2(60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, int(30 * p.scale), Color(p.color.r, p.color.g, p.color.b, a))

func _draw_hud() -> void:
	draw_string(font, Vector2(40, 60), "Seeds: %d" % seeds, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(1, 0.92, 0.5))
	var phase_txt := ""
	if phase == Phase.BUILD:
		phase_txt = "BUILD  —  next wave in %d  (SPACE to start)" % int(ceil(build_timer))
	else:
		phase_txt = "WAVE %d  —  robots left: %d" % [wave_number, robots.size() + wave_to_spawn]
	draw_string(font, Vector2(40, 108), phase_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
		Color(0.7, 1, 0.8) if phase == Phase.BUILD else Color(1, 0.7, 0.6))
	if core != null:
		var s := "Core HP: %d" % int(ceil(core.hp))
		draw_string(font, Vector2(view_size.x - 320, 60), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.6, 0.85, 1.0))

func _is_over_toolbar(m: Vector2) -> bool:
	for b in toolbar:
		if (b.rect as Rect2).has_point(m):
			return true
	return false

func _draw_toolbar(m: Vector2) -> void:
	for b in toolbar:
		var rect: Rect2 = b.rect
		var active: bool = (mode == b.mode)
		var afford: bool = b.cost == 0 or seeds >= b.cost
		var bg := Color(0.2, 0.22, 0.26)
		if active:
			bg = Color(0.3, 0.45, 0.35)
		elif rect.has_point(m):
			bg = Color(0.26, 0.28, 0.32)
		draw_rect(rect, bg)
		draw_rect(rect, Color(1, 1, 1, 0.9 if active else 0.25), false, 3.0)
		var tcol := Color.WHITE if afford else Color(1, 0.5, 0.5)
		draw_string(font, rect.position + Vector2(18, 44), "%s. %s" % [b.key, b.label], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, tcol)
		var cost_txt := "free" if b.cost == 0 else ("%d seeds" % b.cost)
		draw_string(font, rect.position + Vector2(18, 80), cost_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.9, 0.5, 0.9))

func _draw_game_over() -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(0, view_size.y * 0.44), "THE ROBOTS ATE YOUR CORE", HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 72, Color(1, 0.4, 0.35))
	draw_string(font, Vector2(0, view_size.y * 0.52), "Survived %d waves  —  click or press R to rebuild" % wave_number, HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 40, Color(1, 1, 1, 0.8))
