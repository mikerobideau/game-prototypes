extends Node2D
class_name CozyFarm

# ---- Berry pull feel ----
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
@export var combo_window: float = 0.65

@export_group("Garden")
@export var bush_max_berries: int = 8
@export var bush_grow_time: float = 1.1        # seconds per new berry
@export var bush_mature_time: float = 2.5      # seed -> fruiting
@export var starting_bushes: int = 3
@export var plot_count: int = 7

@export_group("Round")
@export var start_energy: float = 45.0
@export var harvest_cost: float = 1.0          # energy per berry popped
@export var plant_energy: float = 5.0          # energy to plant a bush
@export var combo_rebate: float = 0.6          # energy refunded per pop during a combo
@export var combo_rebate_min: int = 3          # combo needed before rebates kick in

@export_group("Economy")
@export var berry_value: int = 2               # coins per pop, times combo

const BUSH_HEIGHT := 300.0
const CANOPY_R := 110.0
const KIND_HUES := [0.99, 0.60, 0.13]          # red, blue, gold

enum State { ATTACHED, DETACHED, COLLECTED }
enum Phase { PLAYING, SHOP, GAMEOVER }
enum GoalType { MONEY, BERRIES, COMBO, PLOTS }

class Bush:
	var pos: Vector2
	var growth: float = 0.0
	var mature: bool = false
	var berry_timer: float = 0.0
	var seed_hue: float = 0.0
	var kind: int = 0

class Berry:
	var owner_bush: Bush
	var anchor: Vector2
	var pos: Vector2
	var vel: Vector2 = Vector2.ZERO
	var radius: float
	var color: Color
	var kind: int = 0
	var state: int = State.ATTACHED
	var squash: float = 0.0
	var wobble_seed: float = 0.0
	var grabbed: bool = false

class Spot:
	var pos: Vector2
	var bush: Bush = null

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
var particles: Array[Particle] = []
var popups: Array[CustomPopup] = []

var view_size: Vector2
var ground_y: float

var money: int = 0
var energy: float = 45.0
var energy_max: float = 45.0
var carrying: bool = false
var combo: int = 0
var combo_timer: float = 0.0

var phase: int = Phase.PLAYING
var round_number: int = 1
var round_earned: int = 0
var goal: Dictionary = {}
var goal_met: bool = false

var time: float = 0.0
var flash_amt: float = 0.0

# ui
var upgrades: Array = []
var shop_continue_rect: Rect2 = Rect2()
var end_round_rect: Rect2 = Rect2()
var defaults: Dictionary = {}

# audio
var players: Array[AudioStreamPlayer] = []
var player_idx: int = 0
var s_pop: AudioStreamWAV
var s_collect: AudioStreamWAV
var s_load: AudioStreamWAV
var s_plant: AudioStreamWAV
var s_error: AudioStreamWAV
var s_chime: AudioStreamWAV

var font: Font

func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	view_size = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_resize)
	defaults = {
		"energy_max": start_energy, "berry_value": berry_value,
		"bush_grow_time": bush_grow_time, "bush_max_berries": bush_max_berries,
		"harvest_cost": harvest_cost, "combo_rebate": combo_rebate,
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
	money = 0
	round_number = 1
	energy_max = start_energy
	energy = energy_max
	round_earned = 0
	combo = 0
	carrying = false
	goal_met = false
	phase = Phase.PLAYING
	berries.clear()
	particles.clear()
	popups.clear()
	berry_value = defaults.berry_value
	bush_grow_time = defaults.bush_grow_time
	bush_max_berries = defaults.bush_max_berries
	harvest_cost = defaults.harvest_cost
	combo_rebate = defaults.combo_rebate
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
	goal = _make_goal(round_number)

func _layout() -> void:
	ground_y = view_size.y * 0.86
	var margin := view_size.x * 0.1
	var span := view_size.x - margin * 2.0
	var new_spots: Array[Spot] = []
	for i in range(plot_count):
		var s := Spot.new()
		s.pos = Vector2(margin + span * (i / float(max(1, plot_count - 1))), ground_y)
		new_spots.append(s)
	for i in range(min(spots.size(), new_spots.size())):
		new_spots[i].bush = spots[i].bush
		if new_spots[i].bush != null:
			new_spots[i].bush.pos = new_spots[i].pos
	spots = new_spots
	_layout_ui()

func _layout_ui() -> void:
	var cw := 320.0
	var ch := 210.0
	var gap := 24.0
	var total = upgrades.size() * cw + max(0, upgrades.size() - 1) * gap
	var sx = (view_size.x - total) * 0.5
	var sy := view_size.y * 0.34
	for i in range(upgrades.size()):
		upgrades[i].rect = Rect2(sx + i * (cw + gap), sy, cw, ch)
	shop_continue_rect = Rect2(view_size.x * 0.5 - 170.0, view_size.y * 0.72, 340.0, 92.0)
	end_round_rect = Rect2(view_size.x - 360.0, view_size.y - 130.0, 320.0, 88.0)

func _build_upgrades() -> void:
	upgrades = [
		{"id": "battery", "label": "Bigger Battery", "desc": "+8 max energy", "base": 18, "mult": 1.5, "level": 0, "rect": Rect2()},
		{"id": "soil", "label": "Rich Soil", "desc": "+1 coin per berry", "base": 22, "mult": 1.7, "level": 0, "rect": Rect2()},
		{"id": "growth", "label": "Fast Growth", "desc": "berries ripen faster", "base": 18, "mult": 1.6, "level": 0, "rect": Rect2()},
		{"id": "thumb", "label": "Green Thumb", "desc": "+2 berries per bush", "base": 20, "mult": 1.6, "level": 0, "rect": Rect2()},
		{"id": "charm", "label": "Combo Charm", "desc": "combos refund more energy", "base": 20, "mult": 1.6, "level": 0, "rect": Rect2()},
	]

func _upg_cost(up: Dictionary) -> int:
	return int(round(up.base * pow(up.mult, up.level)))

func _buy_upgrade(up: Dictionary) -> void:
	var cost := _upg_cost(up)
	if money < cost:
		_play(s_error, 1.0)
		return
	money -= cost
	up.level += 1
	_apply_upgrade(up.id)
	_play(s_plant, 1.15)

func _apply_upgrade(id: String) -> void:
	match id:
		"battery": energy_max += 8.0
		"soil": berry_value += 1
		"growth": bush_grow_time = max(0.35, bush_grow_time * 0.85)
		"thumb": bush_max_berries += 2
		"charm": combo_rebate = min(1.0, combo_rebate + 0.2)

func _middle_spots(count: int) -> Array:
	var mid := int(spots.size() / 2.0)
	var out: Array = []
	var offs := [0, -1, 1, -2, 2, -3, 3]
	for k in range(count):
		out.append(clamp(mid + offs[k], 0, spots.size() - 1))
	return out

# ---------------------------------------------------------------- goals
func _make_goal(r: int) -> Dictionary:
	var types := [GoalType.MONEY, GoalType.BERRIES, GoalType.COMBO, GoalType.PLOTS]
	var t: int = types[randi() % types.size()]
	var g := {"type": t, "progress": 0, "target": 0, "desc": ""}
	match t:
		GoalType.MONEY:
			g.target = 40 + (r - 1) * 25
			g.desc = "Earn %d coins" % g.target
		GoalType.BERRIES:
			g.target = 12 + (r - 1) * 5
			g.desc = "Harvest %d berries" % g.target
		GoalType.COMBO:
			g.target = 4 + (r - 1)
			g.desc = "Reach a x%d combo" % g.target
		GoalType.PLOTS:
			g.target = plot_count
			g.desc = "Fill all %d plots" % g.target
	return g

func _goal_add(kind: int, amount: int) -> void:
	if goal_met:
		return
	match goal.type:
		GoalType.MONEY:
			goal.progress = round_earned
		GoalType.BERRIES:
			if kind == GoalType.BERRIES:
				goal.progress += amount
		GoalType.COMBO:
			goal.progress = max(goal.progress, combo)
		GoalType.PLOTS:
			goal.progress = _count_bushes()
	if goal.progress >= goal.target:
		goal_met = true
		_play(s_chime, 1.0)
		_popup(Vector2(view_size.x * 0.5, view_size.y * 0.24), "GOAL COMPLETE!", Color(0.7, 1.0, 0.7), 1.6)

func _count_bushes() -> int:
	var c := 0
	for spot in spots:
		if spot.bush != null:
			c += 1
	return c

func _end_round() -> void:
	if goal_met:
		phase = Phase.SHOP
		_play(s_chime, 0.9)
	else:
		phase = Phase.GAMEOVER
		flash_amt = 0.5

func _leave_shop() -> void:
	round_number += 1
	energy = energy_max
	round_earned = 0
	combo = 0
	combo_timer = 0.0
	carrying = false
	goal_met = false
	goal = _make_goal(round_number)
	phase = Phase.PLAYING

# ---------------------------------------------------------------- bushes / berries
func _plant_bush(spot: Spot) -> void:
	if spot.bush != null:
		return
	var b := Bush.new()
	b.pos = spot.pos
	b.kind = randi() % KIND_HUES.size()
	b.seed_hue = KIND_HUES[b.kind]
	b.berry_timer = bush_grow_time
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
	var ang := randf_range(PI * 0.15, PI * 0.85)
	var anchor := canopy + Vector2(cos(ang), sin(ang) * 0.7) * CANOPY_R * randf_range(0.55, 0.95)
	var berry := Berry.new()
	berry.owner_bush = b
	berry.anchor = anchor
	berry.radius = randf_range(28, 46)
	berry.pos = anchor + Vector2(randf_range(-8, 8), rest_len + berry.radius)
	berry.wobble_seed = randf() * TAU
	berry.kind = b.kind
	berry.color = Color.from_hsv(b.seed_hue, randf_range(0.6, 0.82), randf_range(0.75, 0.95))
	berries.append(berry)

func _update_bushes(delta: float) -> void:
	for spot in spots:
		var b := spot.bush
		if b == null:
			continue
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

# ---------------------------------------------------------------- input
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and phase == Phase.GAMEOVER:
			_reset_run()
		elif event.keycode == KEY_SPACE and phase == Phase.PLAYING:
			if carrying:
				carrying = false
			elif energy >= plant_energy:
				carrying = true
				_play(s_load, 1.0)
			else:
				_play(s_error, 1.0)
				flash_amt = 0.25
		elif event.keycode == KEY_ESCAPE:
			carrying = false
	elif event is InputEventMouseButton and event.pressed:
		var m := get_local_mouse_position()
		if phase == Phase.GAMEOVER:
			_reset_run()
			return
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
		# PLAYING
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if carrying:
				carrying = false
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not carrying and goal_met and end_round_rect.has_point(m):
				_end_round()
				return
			if carrying:
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
	if energy < plant_energy:
		_play(s_error, 1.0)
		return
	energy -= plant_energy
	_plant_bush(spot)
	carrying = false
	_play(s_plant, randf_range(0.95, 1.05))
	for i in range(10):
		_spawn_splatter(spot.pos, Color(0.55, 0.4, 0.25))
	_popup(spot.pos + Vector2(0, -40), "planted", Color(0.7, 1, 0.7), 1.0)
	_goal_add(GoalType.PLOTS, 0)

# ---------------------------------------------------------------- update
func _process(delta: float) -> void:
	time += delta
	var mouse := get_local_mouse_position()
	var in_play := phase == Phase.PLAYING
	var pulling := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not carrying and in_play

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

	if in_play:
		_update_bushes(delta)
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
		if energy <= 0.0:
			energy = 0.0
			_end_round()

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
	round_earned += gain

	# energy: pops cost energy, but a good combo refunds most of it
	energy -= harvest_cost
	if combo >= combo_rebate_min:
		energy = min(energy_max, energy + combo_rebate)

	_goal_add(GoalType.BERRIES, 1)
	_goal_add(GoalType.COMBO, 0)

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
	s_load = _make_tone(300.0, 620.0, 0.09, 0.0)
	s_plant = _make_tone(220.0, 400.0, 0.12, 0.2)
	s_error = _make_tone(200.0, 150.0, 0.12, 0.0)
	s_chime = _make_tone(700.0, 1300.0, 0.22, 0.0)
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
	for p in particles:
		var a: float = p.life / p.max_life
		draw_circle(p.pos, p.size * a, Color(p.color.r, p.color.g, p.color.b, a))

	if carrying:
		var spot := _nearest_empty_spot(mouse, 160.0)
		if spot != null:
			var ok := energy >= plant_energy
			draw_circle(spot.pos, 34, Color(0.4, 1.0, 0.5, 0.3) if ok else Color(1.0, 0.4, 0.4, 0.3))
			draw_arc(spot.pos, 34, 0, TAU, 24, Color(0.5, 1, 0.6, 0.7) if ok else Color(1, 0.5, 0.5, 0.7), 3.0)

	_draw_nozzle(mouse, pulling)
	for p in popups:
		_draw_popup(p)
	if flash_amt > 0.0:
		draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.9, 0.5, 0.2, flash_amt * 0.3))

	_draw_hud(mouse)
	if phase == Phase.GAMEOVER:
		_draw_gameover()

func _draw_background() -> void:
	var top := Color(0.42, 0.68, 0.82)
	var bot := Color(0.62, 0.82, 0.66)
	var pad := 60.0
	var pts := PackedVector2Array([
		Vector2(-pad, -pad), Vector2(view_size.x + pad, -pad),
		Vector2(view_size.x + pad, view_size.y + pad), Vector2(-pad, view_size.y + pad)])
	draw_polygon(pts, PackedColorArray([top, top, bot, bot]))
	draw_rect(Rect2(-pad, ground_y, view_size.x + pad * 2, view_size.y - ground_y + pad), Color(0.36, 0.26, 0.18))

func _draw_spot(spot: Spot) -> void:
	if spot.bush != null:
		return
	draw_circle(spot.pos + Vector2(0, 6), 30, Color(0.3, 0.22, 0.15))
	draw_circle(spot.pos, 26, Color(0.42, 0.31, 0.2))

func _draw_bush(b: Bush) -> void:
	var canopy := _canopy_pos(b)
	draw_line(b.pos, canopy, Color(0.36, 0.25, 0.16), lerp(6.0, 16.0, b.growth))
	var r := CANOPY_R * b.growth
	if r > 4.0:
		var leaf := Color.from_hsv(0.32, 0.4, 0.55)
		draw_circle(canopy, r, leaf.darkened(0.1))
		draw_circle(canopy + Vector2(-r * 0.4, -r * 0.2), r * 0.6, leaf)
		draw_circle(canopy + Vector2(r * 0.4, -r * 0.1), r * 0.55, leaf.lightened(0.06))
	if b.mature and _bush_attached_count(b) >= bush_max_berries:
		draw_arc(canopy, r + 6, 0, TAU, 28, Color(1, 0.9, 0.4, 0.4 + 0.25 * sin(time * 5.0)), 3.0)

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

func _draw_nozzle(mouse: Vector2, pulling: bool) -> void:
	var ring_a := 0.10 + (0.14 if pulling else 0.0)
	draw_arc(mouse, grab_radius, 0, TAU, 48, Color(1, 1, 1, ring_a), 3.0)
	if pulling:
		for i in range(3):
			var p2: float = fmod(time * 1.4 + i / 3.0, 1.0)
			draw_arc(mouse, lerp(grab_radius * 0.9, 24.0, p2), 0, TAU, 40, Color(1, 1, 1, (1.0 - p2) * 0.35), 2.0)
	draw_circle(mouse, 34, Color(0.2, 0.22, 0.26))
	draw_arc(mouse, 34, 0, TAU, 32, Color(0.5, 0.55, 0.62), 4.0)
	draw_circle(mouse, 18, Color(0.08, 0.09, 0.11))
	if carrying:
		draw_circle(mouse, 11, Color(0.55, 0.4, 0.25))
		draw_circle(mouse + Vector2(-3, -3), 4, Color(0.7, 0.9, 0.5))

func _draw_popup(p: CustomPopup) -> void:
	var a: float = clamp(p.life, 0.0, 1.0)
	draw_string(font, p.pos - Vector2(60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, int(30 * p.scale), Color(p.color.r, p.color.g, p.color.b, a))

func _draw_hud(mouse: Vector2) -> void:
	draw_string(font, Vector2(40, 60), "Coins: %d" % money, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(1, 0.92, 0.5))
	draw_string(font, Vector2(40, 104), "Round %d" % round_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.85, 0.92, 1.0))
	if combo >= 2:
		draw_string(font, Vector2(40, 144), "Combo x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.85, 0.4))

	# energy bar (the round's limit)
	var ew := 420.0
	var ex := view_size.x - ew - 40.0
	var ey := 60.0
	var frac: float = clamp(energy / max(1.0, energy_max), 0.0, 1.0)
	draw_string(font, Vector2(ex, ey - 6), "Energy", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.8, 1.0, 0.9))
	draw_rect(Rect2(ex, ey + 6, ew, 26), Color(0, 0, 0, 0.4))
	var ecol := Color(0.4, 0.85, 0.5).lerp(Color(0.95, 0.75, 0.3), 1.0 - frac)
	draw_rect(Rect2(ex, ey + 6, ew * frac, 26), ecol)
	draw_string(font, Vector2(ex, ey + 60), "%d" % int(ceil(energy)), HORIZONTAL_ALIGNMENT_RIGHT, ew, 26, Color(1, 1, 1, 0.8))

	# goal card, centered top
	var gw := 640.0
	var gx := (view_size.x - gw) * 0.5
	var gy := 40.0
	draw_rect(Rect2(gx, gy, gw, 96), Color(0.15, 0.18, 0.22, 0.85))
	draw_rect(Rect2(gx, gy, gw, 96), Color(0.6, 1.0, 0.7, 0.6) if goal_met else Color(1, 1, 1, 0.25), false, 3.0)
	draw_string(font, Vector2(gx + 24, gy + 40), "GOAL:  %s" % goal.desc, HORIZONTAL_ALIGNMENT_LEFT, gw - 48, 30, Color.WHITE)
	var prog_txt := "done!" if goal_met else "%d / %d" % [int(goal.progress), int(goal.target)]
	draw_string(font, Vector2(gx + 24, gy + 78), prog_txt, HORIZONTAL_ALIGNMENT_LEFT, gw - 48, 26,
		Color(0.7, 1.0, 0.7) if goal_met else Color(1, 0.9, 0.6))

	var hint := "RIGHT-DRAG to pull berries  •  SPACE to load a seed, then LEFT-CLICK soil to plant"
	if carrying:
		hint = "Carrying seed — LEFT-CLICK a soil mound (costs %d energy)  •  RIGHT-CLICK to cancel" % int(plant_energy)
	draw_string(font, Vector2(40, view_size.y - 34), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.65))

	if goal_met:
		_draw_button(end_round_rect, "END ROUND  >", mouse, Color(0.28, 0.48, 0.3))

func _draw_button(rect: Rect2, label: String, mouse: Vector2, base: Color) -> void:
	var bg := base
	if rect.has_point(mouse):
		bg = base.lightened(0.15)
	draw_rect(rect, bg)
	draw_rect(rect, Color(1, 1, 1, 0.5), false, 3.0)
	draw_string(font, rect.position + Vector2(0, rect.size.y * 0.5 + 12), label,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 32, Color.WHITE)

func _draw_shop(mouse: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0.13, 0.16, 0.14))
	draw_string(font, Vector2(0, view_size.y * 0.16), "HARVEST DONE", HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 54, Color(0.7, 1.0, 0.75))
	draw_string(font, Vector2(0, view_size.y * 0.22), "SHOP", HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 70, Color(1, 0.92, 0.6))
	draw_string(font, Vector2(0, view_size.y * 0.27), "Coins: %d" % money, HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 40, Color(1, 0.92, 0.5))
	for up in upgrades:
		var rect: Rect2 = up.rect
		var cost := _upg_cost(up)
		var afford := money >= cost
		var bg := Color(0.2, 0.24, 0.22)
		if rect.has_point(mouse):
			bg = Color(0.27, 0.33, 0.3)
		draw_rect(rect, bg)
		draw_rect(rect, Color(1, 1, 1, 0.25) if afford else Color(1, 0.4, 0.4, 0.4), false, 2.0)
		draw_string(font, rect.position + Vector2(18, 48), up.label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 30,
			Color.WHITE if afford else Color(1, 0.6, 0.6))
		draw_string(font, rect.position + Vector2(18, 92), up.desc, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 36, 23, Color(0.85, 0.95, 0.88))
		draw_string(font, rect.position + Vector2(18, 150), "Lv %d" % up.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.7, 0.85, 0.72))
		draw_string(font, rect.position + Vector2(0, 150), "%d " % cost, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 18, 30, Color(1, 0.9, 0.5))
	_draw_button(shop_continue_rect, "NEXT ROUND  >", mouse, Color(0.28, 0.48, 0.3))

func _draw_gameover() -> void:
	draw_rect(Rect2(Vector2.ZERO, view_size), Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(0, view_size.y * 0.42), "THE SEASON ENDED", HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 72, Color(1, 0.8, 0.5))
	draw_string(font, Vector2(0, view_size.y * 0.5), "You reached round %d  —  click or press R to start a new run" % round_number,
		HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 38, Color(1, 1, 1, 0.85))
	draw_string(font, Vector2(0, view_size.y * 0.56), "Goal was: %s" % goal.desc, HORIZONTAL_ALIGNMENT_CENTER, view_size.x, 30, Color(1, 0.7, 0.6))
