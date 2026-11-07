extends Node2D
class_name GardenPrototype

# ---- Berry pull feel (from v1) ----
@export_group("Grab")
@export var grab_radius: float = 170.0
@export var follow_stiffness: float = 55.0

@export_group("Stem")
@export var rest_len: float = 34.0
@export var stem_tension_linear: float = 12.0
@export var stem_tension_max: float = 2600.0
@export var pop_stretch: float = 150.0
@export var stem_damping: float = 9.0

@export_group("Juice")
@export var launch_speed: float = 1500.0
@export var combo_window: float = 0.6

@export_group("Gun")
@export var fire_rate: float = 0.16
@export var gun_damage: float = 1.0
@export var aim_radius: float = 60.0
@export var knockback: float = 280.0

@export_group("Robots")
@export var robot_speed: float = 110.0
@export var robot_hp: float = 3.0
@export var bite_dps: float = 4.0            # bush hp per second
@export var berry_steal_time: float = 1.2    # a chewing robot knocks a berry off this often
@export var wave_spawn_gap: float = 1.1      # seconds between robots within a wave

@export_group("Economy")
@export var start_money: int = 40
@export var plant_cost: int = 18
@export var berry_value: int = 2             # money per pop, times combo
@export var bush_max_berries: int = 6
@export var bush_grow_time: float = 2.0      # seconds per new berry
@export var bush_mature_time: float = 3.5    # seed -> fruiting
@export var bush_hp: float = 24.0
@export var starting_bushes: int = 3

@export_group("Rounds")
@export var waves_per_round: int = 3         # waves cleared before the shop opens
@export var downtime_time: float = 8.0       # seconds to harvest/plant before a wave auto-starts

const BUSH_HEIGHT := 300.0
const CANOPY_R := 110.0

enum State { ATTACHED, DETACHED, COLLECTED }
enum Phase { DOWNTIME, SHOP, WAVE }

class Bush:
	var pos: Vector2            # base at the soil
	var growth: float = 0.0     # 0..1 while sprouting
	var mature: bool = false
	var berry_timer: float = 0.0
	var steal_timer: float = 0.0
	var hp: float
	var max_hp: float
	var flash: float = 0.0
	var seed_hue: float = 0.0

class Berry:
	var owner_bush: Bush
	var anchor: Vector2
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var radius: float
	var color: Color
	var state: int = State.ATTACHED
	var squash: float = 0.0
	var wobble_seed: float = 0.0
	var grabbed: bool = false

class Spot:
	var pos: Vector2
	var bush: Bush = null

class Robot:
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var hp: float
	var max_hp: float
	var hit_flash: float = 0.0
	var bob_seed: float = 0.0
	var dead: bool = false

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

var spots: Array[Spot] = []
var berries: Array[Berry] = []
var robots: Array[Robot] = []
var particles: Array[Particle] = []
var popups: Array[CustomPopup] = []

var view_size: Vector2
var ground_y: float
var turret_pos: Vector2

var money: int = 40
var carrying: bool = false      # a seed is loaded in the nozzle
var combo: int = 0
var combo_timer: float = 0.0

var flash_amt: float = 0.0
var time: float = 0.0
var fire_cooldown: float = 0.0
var beam_life: float = 0.0
var beam_end: Vector2 = Vector2.ZERO

# progression
var phase: int = Phase.DOWNTIME
var round_number: int = 1
var wave_number: int = 0
var wave_in_round: int = 0
var wave_to_spawn: int = 0
var wave_spawn_timer: float = 0.0
var downtime_timer: float = 0.0
var game_over: bool = false
var upgrades: Array = []             # [{id,label,desc,base,mult,level,rect}]
var shop_continue_rect: Rect2 = Rect2()
var defaults: Dictionary = {}        # base stats, for restart

# audio
var players: Array[AudioStreamPlayer] = []
var player_idx: int = 0
var s_pop: AudioStreamWAV
var s_collect: AudioStreamWAV
var s_zap: AudioStreamWAV
var s_explode: AudioStreamWAV
var s_load: AudioStreamWAV
var s_plant: AudioStreamWAV
var s_error: AudioStreamWAV

var font: Font

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	view_size = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_resize)
	defaults = {
		"fire_rate": fire_rate, "gun_damage": gun_damage, "aim_radius": aim_radius,
		"grab_radius": grab_radius, "bush_grow_time": bush_grow_time, "bush_hp": bush_hp,
	}
	_build_audio()
	_build_upgrades()
	_layout()
	_reset_run()
	set_process(true)

func _on_resize() -> void:
	view_size = get_viewport_rect().size
	_layout()

func _reset_run() -> void:
	money = start_money
	round_number = 1
	wave_number = 0
	wave_in_round = 0
	phase = Phase.DOWNTIME
	downtime_timer = downtime_time
	game_over = false
	carrying = false
	combo = 0
	robots.clear()
	berries.clear()
	particles.clear()
	popups.clear()
	fire_rate = defaults.fire_rate
	gun_damage = defaults.gun_damage
	aim_radius = defaults.aim_radius
	grab_radius = defaults.grab_radius
	bush_grow_time = defaults.bush_grow_time
	bush_hp = defaults.bush_hp
	for up in upgrades:
		up.level = 0
	for spot in spots:
		spot.bush = null
	var idx := _middle_spots(starting_bushes)
	for i in range(starting_bushes):
		var sp := spots[idx[i]]
		_plant_bush(sp)
		var b := sp.bush
		b.growth = 1.0
		b.mature = true
		for j in range(3):
			_spawn_berry(b)

func _layout() -> void:
	ground_y = view_size.y * 0.86
	turret_pos = Vector2(view_size.x * 0.5, view_size.y * 0.955)
	var n := 7
	var margin := view_size.x * 0.1
	var span := view_size.x - margin * 2.0
	var new_spots: Array[Spot] = []
	for i in range(n):
		var s := Spot.new()
		s.pos = Vector2(margin + span * (i / float(n - 1)), ground_y)
		new_spots.append(s)
	# preserve any existing bushes onto the nearest new spot index
	for i in range(min(spots.size(), new_spots.size())):
		new_spots[i].bush = spots[i].bush
		if new_spots[i].bush != null:
			new_spots[i].bush.pos = new_spots[i].pos
	spots = new_spots
	_layout_ui()

func _layout_ui() -> void:
	# shop screen: a centered row of upgrade cards
	var cw := 320.0
	var ch := 210.0
	var gap := 24.0
	var total = upgrades.size() * cw + max(0, upgrades.size() - 1) * gap
	var sx = (view_size.x - total) * 0.5
	var sy := view_size.y * 0.34
	for i in range(upgrades.size()):
		upgrades[i].rect = Rect2(sx + i * (cw + gap), sy, cw, ch)
	shop_continue_rect = Rect2(view_size.x * 0.5 - 170.0, view_size.y * 0.72, 340.0, 92.0)

func _build_upgrades() -> void:
	upgrades = [
		{"id": "fire", "label": "Rapid Fire", "desc": "shoot faster", "base": 20, "mult": 1.6, "level": 0, "rect": Rect2()},
		{"id": "dmg", "label": "Power Shot", "desc": "+1 damage", "base": 25, "mult": 1.7, "level": 0, "rect": Rect2()},
		{"id": "aim", "label": "Auto-Aim", "desc": "wider aim assist", "base": 18, "mult": 1.5, "level": 0, "rect": Rect2()},
		{"id": "hardy", "label": "Hardy Bushes", "desc": "+bush HP & heal", "base": 22, "mult": 1.6, "level": 0, "rect": Rect2()},
		{"id": "fert", "label": "Fertilizer", "desc": "berries grow faster", "base": 20, "mult": 1.6, "level": 0, "rect": Rect2()},
	]

func _upg_cost(up: Dictionary) -> int:
	return int(round(up.base * pow(up.mult, up.level)))

func _buy_upgrade(up: Dictionary) -> void:
	var cost := _upg_cost(up)
	if money < cost:
		_play(s_error, 1.0)
		flash_amt = 0.25
		return
	money -= cost
	up.level += 1
	_apply_upgrade(up.id)
	_play(s_plant, 1.15)

func _apply_upgrade(id: String) -> void:
	match id:
		"fire": fire_rate = max(0.05, fire_rate * 0.85)
		"dmg": gun_damage += 1.0
		"aim": aim_radius += 25.0
		"fert": bush_grow_time = max(0.4, bush_grow_time * 0.85)
		"hardy":
			bush_hp += 6.0
			for spot in spots:
				if spot.bush != null:
					spot.bush.max_hp += 6.0
					spot.bush.hp = spot.bush.max_hp

func _middle_spots(count: int) -> Array:
	# indices centered in the row, for the starting bushes
	var mid := int(spots.size() / 2.0)
	var out: Array = []
	var offs := [0, -1, 1, -2, 2, -3, 3]
	for k in range(count):
		out.append(clamp(mid + offs[k], 0, spots.size() - 1))
	return out

# ---------------------------------------------------------------- bushes / berries
func _plant_bush(spot: Spot) -> void:
	if spot.bush != null:
		return
	var b := Bush.new()
	b.pos = spot.pos
	b.max_hp = bush_hp
	b.hp = bush_hp
	b.berry_timer = bush_grow_time
	b.seed_hue = fmod(randf_range(0.92, 1.02), 1.0)
	spot.bush = b

func _canopy_pos(b: Bush) -> Vector2:
	return b.pos + Vector2(0, -BUSH_HEIGHT * b.growth)

func _bush_attached_count(b: Bush) -> int:
	var c := 0
	for berry in berries:
		if berry.owner_bush == b and berry.state == State.ATTACHED:
			c += 1
	return c

func _spawn_berry(b: Bush) -> void:
	var canopy := _canopy_pos(b)
	var ang := randf_range(PI * 0.15, PI * 0.85)   # lower hemisphere of the canopy
	var anchor := canopy + Vector2(cos(ang), sin(ang) * 0.7) * CANOPY_R * randf_range(0.55, 0.95)
	var berry := Berry.new()
	berry.owner_bush = b
	berry.anchor = anchor
	berry.radius = randf_range(28, 46)
	berry.pos = anchor + Vector2(randf_range(-8, 8), rest_len + berry.radius)
	berry.wobble_seed = randf() * TAU
	berry.color = Color.from_hsv(b.seed_hue, randf_range(0.55, 0.8), randf_range(0.72, 0.95))
	berries.append(berry)

func _update_bushes(delta: float) -> void:
	if phase == Phase.SHOP:
		return   # garden is frozen while shopping
	for spot in spots:
		var b := spot.bush
		if b == null:
			continue
		b.flash = move_toward(b.flash, 0.0, delta * 4.0)
		if not b.mature:
			b.growth = min(1.0, b.growth + delta / bush_mature_time)
			if b.growth >= 1.0:
				b.mature = true
				b.berry_timer = bush_grow_time
		else:
			if _bush_attached_count(b) < bush_max_berries:
				b.berry_timer -= delta
				if b.berry_timer <= 0.0:
					_spawn_berry(b)
					b.berry_timer = bush_grow_time

func _destroy_bush(spot: Spot) -> void:
	var b := spot.bush
	if b == null:
		return
	spot.bush = null
	flash_amt = max(flash_amt, 0.6)
	_play(s_explode, 0.7)
	for berry in berries:
		if berry.owner_bush == b and berry.state == State.ATTACHED:
			_spawn_splatter(berry.pos, berry.color)
			berry.state = State.COLLECTED

# ---------------------------------------------------------------- input
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and game_over:
			_reset_run()
		elif event.keycode == KEY_SPACE and phase != Phase.SHOP:
			if carrying:
				carrying = false
			elif money >= plant_cost:
				carrying = true
				_play(s_load, 1.0)
			else:
				_play(s_error, 1.0)
				flash_amt = 0.3
		elif event.keycode == KEY_ESCAPE and phase != Phase.SHOP:
			carrying = false
	elif event is InputEventMouseButton and event.pressed:
		var m := get_local_mouse_position()
		if game_over:
			return
		# SHOP is a separate screen: only its buttons respond
		if phase == Phase.SHOP:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if shop_continue_rect.has_point(m):
					_leave_shop()
					return
				for up in upgrades:
					if (up.rect as Rect2).has_point(m):
						_buy_upgrade(up)
						return
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if carrying:
				carrying = false
			return
		if event.button_index == MOUSE_BUTTON_LEFT and carrying:
			_try_plant(m)

func _nearest_empty_spot(m: Vector2, max_dist: float) -> Spot:
	var best: Spot = null
	var best_d := max_dist
	for spot in spots:
		if spot.bush != null:
			continue
		var d := (spot.pos - m).length()
		if d < best_d:
			best_d = d
			best = spot
	return best

func _try_plant(m: Vector2) -> void:
	var spot := _nearest_empty_spot(m, 160.0)
	if spot == null:
		_play(s_error, 1.0)
		return
	if money < plant_cost:
		_play(s_error, 1.0)
		return
	money -= plant_cost
	_plant_bush(spot)
	carrying = false
	_play(s_plant, randf_range(0.95, 1.05))
	for i in range(10):
		_spawn_splatter(spot.pos, Color(0.55, 0.4, 0.25))
	_popup(spot.pos + Vector2(0, -40), "planted", Color(0.7, 1, 0.7), 1.0)

# ---------------------------------------------------------------- update
func _process(delta: float) -> void:
	time += delta
	var mouse := get_local_mouse_position()
	var in_shop := phase == Phase.SHOP
	var pulling := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not carrying and not in_shop
	var firing := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not carrying and phase == Phase.WAVE and not game_over

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

	if not game_over and not in_shop:
		_update_phase(delta)
	_update_bushes(delta)

	if not in_shop:
		for b in berries:
			match b.state:
				State.ATTACHED:
					_update_attached(b, delta, mouse, pulling)
				State.DETACHED:
					_update_detached(b, delta, mouse)
			b.squash = move_toward(b.squash, 0.0, delta * 4.0)
		var kept: Array[Berry] = []
		for b in berries:
			if b.state != State.COLLECTED:
				kept.append(b)
		berries = kept

	if not game_over and not in_shop:
		_update_robots(delta)
		_try_fire(delta, mouse, firing)
		_check_defeat()

	beam_life = move_toward(beam_life, 0.0, delta * 8.0)
	flash_amt = move_toward(flash_amt, 0.0, delta * 1.5)
	_update_particles(delta)
	_update_popups(delta)
	queue_redraw()

func _update_attached(b: Berry, delta: float, mouse: Vector2, pulling: bool) -> void:
	var force := Vector2(0, 380.0)
	var to_anchor := b.anchor - b.pos
	var dist := to_anchor.length()
	var stretch: float = dist - rest_len
	if stretch > 0.0 and dist > 0.001:
		var dir := to_anchor / dist
		var t: float = clamp(stretch / pop_stretch, 0.0, 1.0)
		var tension: float = stem_tension_linear * stretch + stem_tension_max * t * t
		force += dir * tension
	if pulling:
		if not b.grabbed and (mouse - b.pos).length() < grab_radius:
			b.grabbed = true
	else:
		b.grabbed = false
	if b.grabbed:
		force += (mouse - b.pos) * follow_stiffness
	b.vel += force * delta
	b.vel *= exp(-stem_damping * delta)
	b.pos += b.vel * delta
	if (b.anchor - b.pos).length() - rest_len > pop_stretch:
		_pop(b, mouse)

func _pop(b: Berry, mouse: Vector2) -> void:
	b.state = State.DETACHED
	b.squash = 1.0
	var dir := mouse - b.pos
	dir = dir.normalized() if dir.length() > 0.001 else Vector2.UP
	b.vel = dir * launch_speed + b.vel * 0.3

	combo += 1
	combo_timer = combo_window
	var gain: int = berry_value * combo
	money += gain

	var pitch: float = (60.0 / b.radius) * randf_range(0.95, 1.08) * (1.0 + (combo - 1) * 0.05)
	_play(s_pop, clamp(pitch, 0.6, 2.2))
	_spawn_splatter(b.pos, b.color)
	_popup(b.pos, ("+%d" % gain) if combo < 2 else ("x%d  +%d" % [combo, gain]), b.color.lightened(0.4), 1.0 + min(combo * 0.1, 1.0))

func _update_detached(b: Berry, delta: float, mouse: Vector2) -> void:
	var to := mouse - b.pos
	var d := to.length()
	if d > 0.001:
		b.vel += (to / d) * 6000.0 * delta
	b.vel *= exp(-2.5 * delta)
	b.pos += b.vel * delta
	if d < 46.0:
		b.state = State.COLLECTED
		_play(s_collect, randf_range(0.9, 1.2))

# ---------------------------------------------------------------- robots + gun
# ---------------------------------------------------------------- waves / progression
func _update_phase(delta: float) -> void:
	if phase == Phase.DOWNTIME:
		# bushes slowly recover; the wave auto-starts when the timer runs out
		for spot in spots:
			if spot.bush != null and spot.bush.mature:
				spot.bush.hp = min(spot.bush.max_hp, spot.bush.hp + 5.0 * delta)
		downtime_timer -= delta
		if downtime_timer <= 0.0:
			_start_wave()
	elif phase == Phase.WAVE:
		if wave_to_spawn > 0:
			wave_spawn_timer -= delta
			if wave_spawn_timer <= 0.0:
				_spawn_robot()
				wave_to_spawn -= 1
				wave_spawn_timer = wave_spawn_gap
		elif robots.is_empty():
			_end_wave()

func _start_wave() -> void:
	phase = Phase.WAVE
	wave_number += 1
	wave_in_round += 1
	wave_to_spawn = 3 + (wave_number - 1) * 2
	wave_spawn_timer = 0.4

func _end_wave() -> void:
	var bonus := 10 + wave_number * 5
	money += bonus
	_play(s_collect, 0.8)
	if wave_in_round >= waves_per_round:
		# round complete -> shop opens automatically
		wave_in_round = 0
		round_number += 1
		phase = Phase.SHOP
		_popup(Vector2(view_size.x * 0.5, view_size.y * 0.35),
			"ROUND CLEARED   +%d" % bonus, Color(0.6, 1.0, 0.7), 1.6)
	else:
		phase = Phase.DOWNTIME
		downtime_timer = downtime_time
		_popup(Vector2(view_size.x * 0.5, view_size.y * 0.35),
			"WAVE %d CLEARED   +%d" % [wave_number, bonus], Color(0.6, 1.0, 0.7), 1.6)

func _leave_shop() -> void:
	phase = Phase.DOWNTIME
	downtime_timer = downtime_time

func _count_bushes() -> int:
	var c := 0
	for spot in spots:
		if spot.bush != null:
			c += 1
	return c

func _check_defeat() -> void:
	if _count_bushes() == 0 and money < plant_cost:
		game_over = true
		flash_amt = 1.0

func _spawn_robot() -> void:
	var r := Robot.new()
	if randf() < 0.6:
		r.pos = Vector2(randf_range(0, view_size.x), -60)
	elif randf() < 0.5:
		r.pos = Vector2(-60, randf_range(-40, view_size.y * 0.4))
	else:
		r.pos = Vector2(view_size.x + 60, randf_range(-40, view_size.y * 0.4))
	# tougher robots in later waves
	r.max_hp = robot_hp + int((wave_number - 1) / 3)
	r.hp = r.max_hp
	r.bob_seed = randf() * TAU
	robots.append(r)

func _nearest_bush(from: Vector2) -> Bush:
	var best: Bush = null
	var best_d := INF
	for spot in spots:
		if spot.bush == null:
			continue
		var d := (spot.bush.pos - from).length()
		if d < best_d:
			best_d = d
			best = spot.bush
	return best

func _update_robots(delta: float) -> void:
	for r in robots:
		if r.dead:
			continue
		r.hit_flash = move_toward(r.hit_flash, 0.0, delta * 4.0)
		var bush := _nearest_bush(r.pos)
		var target := _canopy_pos(bush) if bush != null else Vector2(view_size.x * 0.5, ground_y - 120)
		var to := target - r.pos
		var d := to.length()
		if d > 74.0 or bush == null:
			var desired = (to / max(d, 0.001)) * robot_speed
			r.vel = r.vel.lerp(desired, 1.0 - exp(-3.0 * delta))
		else:
			r.vel *= exp(-6.0 * delta)
			bush.hp -= bite_dps * delta
			bush.flash = 0.6
			bush.steal_timer -= delta
			if bush.steal_timer <= 0.0:
				bush.steal_timer = berry_steal_time
				_steal_berry(bush)
			if bush.hp <= 0.0:
				for spot in spots:
					if spot.bush == bush:
						_destroy_bush(spot)
						break
		r.pos += r.vel * delta

	var kept: Array[Robot] = []
	for r in robots:
		if not r.dead:
			kept.append(r)
	robots = kept

func _steal_berry(b: Bush) -> void:
	for berry in berries:
		if berry.owner_bush == b and berry.state == State.ATTACHED:
			_spawn_splatter(berry.pos, berry.color)
			berry.state = State.COLLECTED
			return

func _try_fire(delta: float, cursor: Vector2, firing: bool) -> void:
	fire_cooldown -= delta
	if firing and fire_cooldown <= 0.0:
		fire_cooldown = fire_rate
		_fire(cursor)

func _fire(cursor: Vector2) -> void:
	beam_end = cursor
	beam_life = 1.0
	_play(s_zap, randf_range(0.9, 1.15))
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
		_spawn_splatter(cursor, Color(0.6, 0.9, 1.0))
		return
	best.hp -= gun_damage
	best.hit_flash = 1.0
	best.vel += (best.pos - turret_pos).normalized() * knockback
	for i in range(3):
		_spawn_splatter(best.pos, Color(1.0, 0.7, 0.3))
	if best.hp <= 0.0:
		_kill_robot(best)

func _kill_robot(r: Robot) -> void:
	r.dead = true
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

# ---------------------------------------------------------------- fx
func _spawn_splatter(at: Vector2, col: Color) -> void:
	var p := Particle.new()
	p.pos = at
	var ang := randf() * TAU
	p.vel = Vector2(cos(ang), sin(ang)) * randf_range(80, 420)
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
		p.vel += Vector2(0, 700) * delta
		p.vel *= exp(-1.6 * delta)
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
	s_pop = _make_tone(880.0, 150.0, 0.11, 0.5)
	s_collect = _make_tone(1400.0, 1900.0, 0.06, 0.0)
	s_zap = _make_tone(2200.0, 500.0, 0.05, 0.3)
	s_explode = _make_noise(0.32)
	s_load = _make_tone(300.0, 620.0, 0.09, 0.0)
	s_plant = _make_tone(220.0, 400.0, 0.12, 0.2)
	s_error = _make_tone(200.0, 150.0, 0.12, 0.0)
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
	var mouse := get_local_mouse_position()
	if phase == Phase.SHOP:
		_draw_shop(mouse)
		return

	_draw_background()
	var pulling := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not carrying

	for spot in spots:
		_draw_spot(spot)
	for spot in spots:
		if spot.bush != null:
			_draw_bush(spot.bush)

	for b in berries:
		if b.state == State.ATTACHED:
			_draw_stem(b)
	for b in berries:
		_draw_berry(b)

	for r in robots:
		if not r.dead:
			_draw_robot(r)

	for p in particles:
		var a: float = p.life / p.max_life
		draw_circle(p.pos, p.size * a, Color(p.color.r, p.color.g, p.color.b, a))

	_draw_turret(mouse)
	if beam_life > 0.0:
		draw_line(turret_pos, beam_end, Color(0.6, 0.95, 1.0, beam_life), lerp(2.0, 9.0, beam_life))
		draw_circle(beam_end, lerp(4.0, 20.0, beam_life), Color(0.8, 1.0, 1.0, beam_life * 0.8))

	# plant ghost when carrying a seed
	if carrying:
		var spot := _nearest_empty_spot(mouse, 160.0)
		if spot != null:
			draw_circle(spot.pos, 34, Color(0.4, 1.0, 0.5, 0.3))
			draw_arc(spot.pos, 34, 0, TAU, 24, Color(0.5, 1, 0.6, 0.7), 3.0)

	_draw_nozzle(mouse, pulling)

	for p in popups:
		_draw_popup(p)

	if flash_amt > 0.0:
		draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.9, 0.15, 0.1, flash_amt * 0.35))

	_draw_hud(mouse)
	_draw_ui(mouse)

func _draw_background() -> void:
	var top := Color(0.36, 0.62, 0.78)
	var bot := Color(0.55, 0.74, 0.6)
	var pad := 60.0
	var pts := PackedVector2Array([
		Vector2(-pad, -pad), Vector2(view_size.x + pad, -pad),
		Vector2(view_size.x + pad, view_size.y + pad), Vector2(-pad, view_size.y + pad)])
	draw_polygon(pts, PackedColorArray([top, top, bot, bot]))
	# soil strip
	draw_rect(Rect2(-pad, ground_y, view_size.x + pad * 2, view_size.y - ground_y + pad), Color(0.32, 0.23, 0.16))

func _draw_spot(spot: Spot) -> void:
	if spot.bush != null:
		return
	# a bare mound of soil
	draw_circle(spot.pos + Vector2(0, 6), 30, Color(0.28, 0.2, 0.14))
	draw_circle(spot.pos, 26, Color(0.4, 0.29, 0.19))

func _draw_bush(b: Bush) -> void:
	var canopy := _canopy_pos(b)
	# trunk
	draw_line(b.pos, canopy, Color(0.36, 0.25, 0.16), lerp(6.0, 16.0, b.growth))
	# canopy foliage
	var r := CANOPY_R * b.growth
	if r > 4.0:
		draw_circle(canopy, r, Color(0.2, 0.5, 0.25))
		draw_circle(canopy + Vector2(-r * 0.4, -r * 0.2), r * 0.6, Color(0.26, 0.58, 0.3))
		draw_circle(canopy + Vector2(r * 0.4, -r * 0.1), r * 0.55, Color(0.24, 0.55, 0.28))
	if b.flash > 0.0:
		draw_circle(canopy, r, Color(1, 0.4, 0.3, b.flash * 0.4))
	if b.hp < b.max_hp:
		var bw := 90.0
		var frac: float = clamp(b.hp / b.max_hp, 0.0, 1.0)
		draw_rect(Rect2(canopy.x - bw * 0.5, canopy.y - r - 22, bw, 8), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(canopy.x - bw * 0.5, canopy.y - r - 22, bw * frac, 8), Color(0.4, 0.85, 0.4).lerp(Color(0.9, 0.3, 0.2), 1.0 - frac))

func _draw_stem(b: Berry) -> void:
	var to_anchor := b.anchor - b.pos
	var dist := to_anchor.length()
	var stretch: float = clamp((dist - rest_len) / pop_stretch, 0.0, 1.0)
	var width: float = lerp(7.0, 2.0, stretch)
	var col := Color(0.35, 0.5, 0.22).lerp(Color(0.75, 0.35, 0.3), stretch)
	var mid := b.pos.lerp(b.anchor, 0.5)
	var perp := to_anchor.orthogonal().normalized()
	mid += perp * sin(time * 18.0 + b.wobble_seed) * (2.0 + stretch * 6.0)
	var prev := b.pos
	for i in range(1, 11):
		var t := float(i) / 10.0
		var q := b.pos.lerp(mid, t).lerp(mid.lerp(b.anchor, t), t)
		draw_line(prev, q, col, width)
		prev = q

func _draw_berry(b: Berry) -> void:
	var r := b.radius
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
	draw_set_transform(b.pos, dirv.angle() - PI / 2.0, Vector2(sx, sy))
	draw_circle(Vector2.ZERO, r, b.color.darkened(0.1))
	draw_circle(Vector2.ZERO, r * 0.92, b.color)
	draw_circle(Vector2(-r * 0.3, -r * 0.35), r * 0.28, b.color.lightened(0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
	draw_circle(p + Vector2(0, 1), 6, Color(1.0, 0.25, 0.2))
	if r.hp < r.max_hp:
		var bw := 32.0
		draw_rect(Rect2(p.x - bw * 0.5, p.y - 30, bw, 5), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(p.x - bw * 0.5, p.y - 30, bw * clamp(r.hp / r.max_hp, 0, 1), 5), Color(0.4, 0.9, 0.4))

func _draw_turret(cursor: Vector2) -> void:
	var ang := (cursor - turret_pos).angle()
	draw_set_transform(turret_pos, ang, Vector2.ONE)
	draw_rect(Rect2(0, -7, 58, 14), Color(0.4, 0.42, 0.48))
	draw_rect(Rect2(48, -9, 10, 18), Color(0.55, 0.58, 0.64))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(turret_pos, 28, Color(0.22, 0.24, 0.28))
	draw_circle(turret_pos, 22, Color(0.32, 0.35, 0.4))
	draw_circle(turret_pos, 9, Color(0.5, 0.9, 1.0, 0.8))

func _draw_nozzle(mouse: Vector2, pulling: bool) -> void:
	var ring_a := 0.10 + (0.14 if pulling else 0.0)
	draw_arc(mouse, grab_radius, 0, TAU, 48, Color(1, 1, 1, ring_a), 3.0)
	if pulling:
		for i in range(3):
			var phase: float = fmod(time * 1.4 + i / 3.0, 1.0)
			draw_arc(mouse, lerp(grab_radius * 0.9, 24.0, phase), 0, TAU, 40, Color(1, 1, 1, (1.0 - phase) * 0.35), 2.0)
	draw_circle(mouse, 34, Color(0.2, 0.22, 0.26))
	draw_arc(mouse, 34, 0, TAU, 32, Color(0.5, 0.55, 0.62), 4.0)
	draw_circle(mouse, 18, Color(0.08, 0.09, 0.11))
	# carried seed
	if carrying:
		draw_circle(mouse, 11, Color(0.55, 0.4, 0.25))
		draw_circle(mouse + Vector2(-3, -3), 4, Color(0.7, 0.9, 0.5))

func _draw_popup(p: CustomPopup) -> void:
	var a: float = clamp(p.life, 0.0, 1.0)
	draw_string(font, p.pos - Vector2(60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, int(30 * p.scale), Color(p.color.r, p.color.g, p.color.b, a))

func _draw_hud(mouse: Vector2) -> void:
	draw_string(font, Vector2(40, 60), "Money: %d" % money, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(1, 0.92, 0.5))
	if combo >= 2:
		draw_string(font, Vector2(40, 108), "Combo x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1, 0.85, 0.4))
	draw_string(font, Vector2(40, 152), "Round %d" % round_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.8, 0.9, 1.0))
	var hint := "DOWNTIME — RIGHT-DRAG to pull berries  •  SPACE to load a seed (%d), then LEFT-CLICK soil to plant" % plant_cost
	if carrying:
		hint = "Carrying seed — LEFT-CLICK a soil mound to plant  •  RIGHT-CLICK to cancel"
	elif phase == Phase.WAVE:
		hint = "WAVE %d — LEFT-CLICK to shoot the robots • protect your bushes" % wave_number
	draw_string(font, Vector2(40, view_size.y - 34), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.65))

func _draw_ui(mouse: Vector2) -> void:
	if game_over:
		draw_rect(Rect2(Vector2.ZERO, view_size), Color(0, 0, 0, 0.62))
		draw_string(font, Vector2(0, view_size.y * 0.44), "YOUR GARDEN IS OVERRUN",
			HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 72, Color(1, 0.45, 0.4))
		draw_string(font, Vector2(0, view_size.y * 0.52), "Reached wave %d  —  press R to replant" % wave_number,
			HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 40, Color(1, 1, 1, 0.85))
		return
	if phase == Phase.WAVE:
		var left := robots.size() + wave_to_spawn
		draw_string(font, Vector2(0, 64), "WAVE %d   —   robots left: %d" % [wave_number, left],
			HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 38, Color(1, 0.65, 0.55))
		return
	# DOWNTIME: countdown to the next (auto-starting) wave
	var secs: int = int(ceil(max(0.0, downtime_timer)))
	draw_string(font, Vector2(0, 64), "NEXT WAVE IN  %d" % secs,
		HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 40, Color(1, 0.85, 0.5))
	# countdown bar
	var bw := 520.0
	var bx := (view_size.x - bw) * 0.5
	var frac: float = clamp(downtime_timer / max(0.01, downtime_time), 0.0, 1.0)
	draw_rect(Rect2(bx, 84, bw, 14), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(bx, 84, bw * frac, 14), Color(1, 0.8, 0.4))

func _draw_button(rect: Rect2, label: String, mouse: Vector2, base: Color) -> void:
	var bg := base
	if rect.has_point(mouse):
		bg = base.lightened(0.15)
	draw_rect(rect, bg)
	draw_rect(rect, Color(1, 1, 1, 0.5), false, 3.0)
	draw_string(font, rect.position + Vector2(0, rect.size.y * 0.5 + 12), label,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 32, Color.WHITE)

func _draw_shop(mouse: Vector2) -> void:
	# a dedicated screen, not the garden
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.12, 0.14, 0.18))
	draw_string(font, Vector2(0, view_size.y * 0.16), "ROUND %d COMPLETE" % (round_number - 1), HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 54, Color(0.7, 1.0, 0.75))
	draw_string(font, Vector2(0, view_size.y * 0.22), "SHOP", HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 70, Color(1, 0.92, 0.6))
	draw_string(font, Vector2(0, view_size.y * 0.27), "Money: %d" % money, HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 40, Color(1, 0.92, 0.5))
	for up in upgrades:
		var rect: Rect2 = up.rect
		var cost := _upg_cost(up)
		var afford := money >= cost
		var bg := Color(0.2, 0.22, 0.28)
		if rect.has_point(mouse):
			bg = Color(0.27, 0.31, 0.38)
		draw_rect(rect, bg)
		draw_rect(rect, Color(1, 1, 1, 0.25) if afford else Color(1, 0.4, 0.4, 0.4), false, 2.0)
		draw_string(font, rect.position + Vector2(18, 48), up.label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 30,
			Color.WHITE if afford else Color(1, 0.6, 0.6))
		draw_string(font, rect.position + Vector2(18, 92), up.desc, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 24, Color(0.8, 0.85, 0.95))
		draw_string(font, rect.position + Vector2(18, 150), "Lv %d" % up.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.7, 0.8, 0.7))
		draw_string(font, rect.position + Vector2(0, 150), "%d " % cost, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 18, 30, Color(1, 0.9, 0.5))
	_draw_button(shop_continue_rect, "CONTINUE  >", mouse, Color(0.28, 0.48, 0.3))
