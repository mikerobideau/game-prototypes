extends "res://prototypes/dj_engine/dj_engine_ui.gd"

const D := preload("res://prototypes/dj_engine/dj_engine_data.gd")

const DRAG_MIN := 24.0
const DRAG_START := 14.0
const SETTLE_T := 0.14
const WELL_R := 106.0
const DISC_R := 96.0
const WELL_PITCH := 314.0
const CELL := 208.0
const CELL_GAP := 18.0
const SPINE := 70.0
const WALLET_BORDER := 34.0
const STEP_TIME := 0.32
const SCORE_TIME := 0.5
const BINDER_SPREAD := 18

class Disc:
	var uid := 0
	var title := ""
	var band := ""
	var cover := ""
	var genre := 0
	var era := 0
	var label := 0
	var sound := 3
	var rule := {}
	var edition := ""
	var cdr := false
	var mix_cover := ""
	var rarity := "common"
	var song := ""
	var hook := -1.0

var rng := RandomNumberGenerator.new()
var albums: Array = []
var collection: Array[Disc] = []
var draw_pile: Array[int] = []
var discard: Array[int] = []
var wallet: Array[int] = []
var tray: Array[int] = []
var play_ids: Array = []
var play_slots: Array = []
var held := -1
var rec_pop := 0.0
var drag_pending := false
var drag_active := false
var drag_kind := ""
var drag_idx := -1
var drag_disc := -1
var drag_pos := Vector2.ZERO
var drag_lift := 0.0
var drag_hover: Array = []
var settles: Array = []
var held_from := -1
var press_pos := Vector2.ZERO
var gig_n := 1
var cash := 0
var rack: Array = []
var gear_defs := {}
var deck_defs: Array = []
var shop_items: Array = []
var pack := {}
var pack_sel: Array[int] = []
var pack_t := 0.0
var pack_slide := 0.0
var pack_rig_open := false
var hold_key := ""
var hold_t := 0.0
var hold_rect := Rect2()
var hold_cb: Callable
var hold_targets: Array = []
var pack_burst := false
var pack_skipped := false
var pack_revealed: Array[int] = []
var pack_sparks: Array = []
var pack_fx: Array = []
var install_queue: Array = []
var install_price := 0
var install_src := -1
var opt_discards := 2
var opt_cash := 15
var reroll_n := 0
var shop_hint: Dictionary = {}
var install_refund := -1
var install_refund_price := 0
var reward := {}
var show_cash := 0
var next_uid := 1
var binder_open := false
var venue := {}
var last_venue := -1
var score_tot := 0
var score_live := 0
var resolving := false
var label_title := true
var sel_slot := -1
var set_res := {}
var pending_kit := 0
var flow_live := 1.0
var gear_sel := -1
var burn_mode := false
var burn_marks: Array[int] = []
var peek_open := false
var settings_open := false
var settings_tab := "scoring"
var anim_idx := 1
var peek_ids: Array[int] = []
var tuner_bonus := 0
var booed := false
var tour: Array = []
var tour_at := 0
var tour_path: Array[int] = []
var map_seed := 0
var forks_done := 0
var boss_venue: Dictionary = {}
var doomed: Array = []
var play_ctx: Dictionary = {}
var set_live := false
var play_order: Array = []
var sel_hand := -1
var finale := 0
var finale_flow := 1.0
var turn_pts := 0
var turn_base := 0
var cash_pulse := 0.0
var song_cash := 0
const EQ_COLS := 16
const EQ_SEGS := 8
var eq_level: Array = []
var eq_peak: Array = []
var eq_hue: Array = []
var eq_prev_run := 0
var fin_t := -1.0
var fin_from := 0
var fin_to := 0
var fin_boomed := false
var fin_boom_t := 0.0
var fin_accum := 0.0
var fin_tick_t := 0.0
var fin_shake := 0.0
var fin_flash := 0.0
var pts_pulse := 0.0
var boss_intro_t := 0.0 # counts down while the "Incoming Boss" vignette and banner show
var move_flash := 0.0 # counts down while the boss ability row is highlighted
var move_flash_pending := false
var shake_t := {} # shop item key -> seconds left of its "can't buy" shake
var song_bus := -1
var fx_bus := -1
var song_hpf: AudioEffectHighPassFilter
var song_lpf: AudioEffectLowPassFilter
var song_rev: AudioEffectReverb
var fx_rev: AudioEffectReverb
var song_heat := 0.0
var song_muffled := false
var song_drop := false
var duck_t := 0.0
var sfx_last := {}
var sfx_base_db := {}
var skip_on := false
var skip_rect := Rect2()
var chain_i := 0
var chain_n := 0
var turn_pace := 1.0
var slot_elapsed := 0.0
var slot_hook := 0.0
var slot_last := false
var music_age := 0.0
var hitstop_t := 0.0
var combo_n := 0
var tray_punch: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var gear_punch: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var pops: Array = []
var ev_pts := 0
var ev_flow := 0.0
var pts_roll := 0.0
var flow_roll := 1.0
var pts_flash := 0.0
var flow_flash := 0.0
var zoom_pulse := 0.0
var fin_riser := false
var slowmo_end_ms := 0
var boss_order: Array = []
var swap_first := -1
var say_queue: Array[String] = []
var library_pending := false
var hand_pulse: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var gear_seen := {}
var top_mag := 99.0
var xf_origin := Vector2.ZERO
var xf_scale := 1.0
var music_vol := 50
var sfx_vol := 50
var vol_drag := ""
var vol_tracks := {}
var music_bus := -1
var sfx_bus := -1
var door_prev_ch := 0.0
var door_prev_hand := 0.0
var door_dir_ch := 0.0
var door_dir_hand := 0.0
var hand_after_shop := false # open the hand door once the shop door has finished closing
var vignette_tex: GradientTexture2D
var flow_pulse := 0.0
var sparks: Array = []
var tick_player: AudioStreamPlayer
var fork_gigs := 0
var fork_roads: Array = []
var road_stops: Array = []
var fork_towns: Array = []
var tour_cols := 1
var pickup := {}
var pickup_shake := 0.0
var pickups_since_gear := 0
var played: Array[int] = []
var done_slots: Array[int] = []
var crowd_move := {}
var turn_n := 1
var bank_in := {}
var blocked_slot := -1
var boss_blocked: Array = []
var boss_last_genre := -1
var turn_dmg := 0
var move_met := false
var turn_note := ""
var turn_cash0 := 0
var song_slot := -1
var binder_pick := -1
var consumables: Array = ["", ""]
var consume_mode := ""
var tbrowse: Dictionary = {}
var shop_open := false
var ch_door := 1.0
var hand_hold := true
var ch_shop := true
var hand_t := 1.0
var discard_pending := false
var stall: Array = []
var install_stall := -1
var tape_view: Dictionary = {}
var consume_slot := -1
var trade_count := 0
var services: Array = []
var bench := -1
var binder_page := 0
var digs := 0
var dig_mode := false
var dig_marks: Array[int] = []
var dig_offer: Array[int] = []
var dig_slot := -1
var gig_score := 0
var target := 0
var plays := {}
var phase := "gig"
var playing := false
var result := {}
var steps: Array = []
var step_i := 0
var step_t := 0.0
var now_slot := -1
var readout: Array = []
var comp_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var slot_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var spin := 0.0
var font_marker: Font
var music_player: AudioStreamPlayer
var bg_player: AudioStreamPlayer
var bg_files: Array = []
var bg_idx := -1
var bg_gain := 0.0
var gig_done := false
var audition_player: AudioStreamPlayer
var audition_target: Disc = null
var audition_cur: Disc = null
var audition_gain := 0.0
var music_t := 0.0
var menu_album: Dictionary = {}
var pile_with_hand := false
var link_log: Array = []
var menu_fade := 0.0
var menu_music := false
var album_music := {}
var xfade_pos := 0.5
var set_total := 0
var set_sound := 0.0
var sort_key := ""
var live_energy := 1
var floats: Array = []
var message := ""
var message_t := 0.0
var hover_disc: Disc = null
var covers := {}
var prewarm_i := 0
var textures := {}

var r_changer := Rect2(800.0, 496.0, 1616.0, 345.0)
var r_score := Rect2(60.0, 40.0, 640.0, 1320.0)
var r_wallet := Rect2(800.0, 1044.0, 1616.0, 230.0)
var r_side := Rect2(1350.0, 796.0, 490.0, 500.0)
var r_cash := Rect2(2244.0, 40.0, 251.0, 80.0)
var r_rack := Rect2(800.0, 202.0, 1616.0, 155.0)
var r_actions := Rect2(1698.0, 1170.0, 797.0, 190.0)
var r_bin := Rect2(70.0, 200.0, 1000.0, 420.0)
var r_counter := Rect2(70.0, 690.0, 1000.0, 690.0)
var r_shelf := Rect2(1110.0, 180.0, 730.0, 1200.0)

const COL_W := 251.0
const COL_G := 22.0
const GEAR_H := 155.0
const CHANGER_Y := 387.0
const CHANGER_H := 440.0
const TRAY_Y := CHANGER_Y + (CHANGER_H - COL_W * 0.886) * 0.5
# The hand sits low on the screen (the usual spot in card games), with a clear band between it
# and the stage. Play / Discard / Next Set sit centred just below the hand, near the bottom edge.
const HAND_PLATE_Y := 1018.0
const HAND_Y := HAND_PLATE_Y + 26.0
const BUTTON_Y := HAND_PLATE_Y + 280.0 + 24.0
const STAGE_BOTTOM := CHANGER_Y + CHANGER_H
const GUTTER_GAP := 120.0
const GUTTER_NUDGE := 14.0
const HOVER_LIFT := 10.0
const HOVER_SCALE := 1.04
const HOVER_WASH := 0.12
const SHOW_TOWER_LCDS := false
const PACK_PANEL_FX := 0.62
const PACK_SIDE_W := 190.0
var hover_gear: Dictionary = {}
var gear_tip_off := false

func _tray_blocked(s: int) -> bool:
	return s == blocked_slot or s in boss_blocked

func _max_play() -> int:
	return D.SETLIST - (2 if _boss_tier() >= 3 else 1) if _boss_kind() == "exec" else D.SETLIST

func _boss_tier() -> int:
	return clampi(int((venue.get("challenge", {}) as Dictionary).get("tier", 0)), 0, D.BOSS_TIERS - 1)

func _boss_count() -> int:
	return 1 + _boss_tier() / 2

func _boss_mult() -> float:
	match _boss_kind():
		"purist":
			return float(D.PURIST_TIERS[_boss_tier()])
		"critic":
			return float(D.CRITIC_TIERS[_boss_tier()])
	return D.BOSS_DEBUFF_MULT

func _roll_boss_blocks() -> void:
	boss_blocked.clear()
	if _boss_kind() != "heckler":
		return
	var pool: Array = []
	for k in D.TRAYS:
		if k != blocked_slot:
			pool.append(k)
	_shuffle(pool)
	boss_blocked.assign(pool.slice(0, _boss_count()))

func _boss_title() -> String:
	return String((venue.get("challenge", {}) as Dictionary).get("title", ""))

func _boss_text() -> String:
	var ch: Dictionary = venue.get("challenge", {})
	match String(ch.get("kind", "")):
		"heckler":
			var nb := _boss_count()
			return ("%d trays are blocked every turn, and their gear is off." % nb) if nb > 1 else "One tray is blocked every turn, and its gear is off."
		"purist":
			return "Only %s songs score in full. Every other genre scores at %d%%." % [D.GENRES[int(ch.get("genre", 0))], int(round(_boss_mult() * 100.0))]
		"critic":
			var pc := int(round(_boss_mult() * 100.0))
			if boss_last_genre >= 0:
				return "You played the most %s last turn, so %s songs score at %d%% this turn." % [D.GENRES[boss_last_genre], D.GENRES[boss_last_genre], pc]
			return "The genre you play the most each turn scores at %d%% on the next turn." % pc
		"engineer":
			var names: Array = ch.get("names", [])
			if not names.is_empty():
				return ("%s is switched off for the whole gig." if names.size() == 1 else "%s are switched off for the whole gig.") % " and ".join(names)
			return "%d of your gear units are switched off for the whole gig." % _boss_count()
		"exec":
			return "You can play only %d CDs a turn, and tapes are locked." % _max_play()
	return ""

func _make_boss_venue(bi: int) -> Dictionary:
	var bix := mini(bi, D.BOSSES.size() - 1)
	if not boss_order.is_empty():
		bix = int(boss_order[bi % boss_order.size()])
	var b: Dictionary = D.BOSSES[bix]
	var ch := {"kind": String(b["kind"]), "title": String(b["title"]), "tier": bi}
	if String(b["kind"]) == "purist":
		ch["genre"] = rng.randi_range(0, D.GENRES.size() - 1)
	return {"name": String(b["venue"]), "likes": [], "dislikes": [], "headliner": true, "challenge": ch}

func _gx() -> float:
	return 472.0 if phase == "shop" or phase == "reward" or (not pack.is_empty() and phase != "show") else 800.0

func _col_x(i: int) -> float:
	return _gx() + i * (COL_W + COL_G)

func _ready() -> void:
	_ui_ready()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rng.randomize()
	_load_gear()
	_load_albums()
	_load_decks()
	_load_music()
	_load_prefs()
	_load_finale_sounds()
	_load_score_sounds()
	_load_file_sfx()
	_setup_buses()
	_to_title()

func _load_prefs() -> void:
	var cf := ConfigFile.new()
	if cf.load(D.PREFS_PATH) == OK:
		anim_idx = clampi(int(cf.get_value("game", "anim_speed", 1)), 0, D.ANIM_SCALE.size() - 1)
		opt_discards = clampi(int(cf.get_value("game", "discards", D.DIGS)), 1, 3)
		opt_cash = clampi(int(cf.get_value("game", "start_cash", D.START_CASH)), 0, 99)
		music_vol = clampi(int(cf.get_value("game", "music_pct", 50)), 0, 100)
		sfx_vol = clampi(int(cf.get_value("game", "sfx_pct", 50)), 0, 100)

func _save_prefs() -> void:
	var cf := ConfigFile.new()
	cf.load(D.PREFS_PATH)
	cf.set_value("game", "anim_speed", anim_idx)
	cf.set_value("game", "discards", opt_discards)
	cf.set_value("game", "start_cash", opt_cash)
	cf.set_value("game", "music_pct", music_vol)
	cf.set_value("game", "sfx_pct", sfx_vol)
	cf.save(D.PREFS_PATH)

func _anim() -> float:
	return float(D.ANIM_SCALE[anim_idx])

func _set_discards(n: int) -> void:
	opt_discards = clampi(n, 1, 3)
	_save_prefs()

func _adj_cash(delta: int) -> void:
	opt_cash = clampi(opt_cash + delta, 0, 99)
	_save_prefs()

func _set_anim(i: int) -> void:
	anim_idx = i
	_save_prefs()

func _open_settings() -> void:
	settings_open = true

func _close_settings() -> void:
	settings_open = false

func _load_finale_sounds() -> void:
	if sfx.has("click"):
		tick_player = AudioStreamPlayer.new()
		tick_player.stream = (sfx["click"] as AudioStreamPlayer).stream
		tick_player.volume_db = -8.0
		add_child(tick_player)
	var rate := 22050
	var n := int(rate * 0.7)
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	var nr := RandomNumberGenerator.new()
	nr.seed = 3
	for i in n:
		var t := float(i) / rate
		ph += TAU * (36.0 + 60.0 * exp(-t * 16.0)) / rate
		var v := sin(ph) * 0.95 * exp(-t * 6.5) * minf(1.0, t * 300.0) + nr.randf_range(-1.0, 1.0) * 0.08 * exp(-t * 45.0)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	var pl := AudioStreamPlayer.new()
	pl.stream = w
	pl.volume_db = -1.0
	add_child(pl)
	sfx["boom"] = pl
	var cn := int(rate * 0.55)
	var cd := PackedByteArray()
	cd.resize(cn * 2)
	for i in cn:
		var t := float(i) / rate
		var v := 0.0
		for note: Array in [[0.0, 1318.5, 16.0], [0.085, 1760.0, 7.0]]:
			var tt := t - float(note[0])
			if tt < 0.0:
				continue
			var env := exp(-tt * float(note[2])) * minf(1.0, tt * 600.0)
			var f0 := float(note[1])
			v += env * (sin(TAU * f0 * tt) * 0.5 + sin(TAU * f0 * 2.76 * tt) * 0.22 + sin(TAU * f0 * 5.4 * tt) * 0.1)
		cd.encode_s16(i * 2, int(clampf(v * 0.7, -1.0, 1.0) * 30000.0))
	var cw := AudioStreamWAV.new()
	cw.format = AudioStreamWAV.FORMAT_16_BITS
	cw.mix_rate = rate
	cw.stereo = false
	cw.data = cd
	var cpl := AudioStreamPlayer.new()
	cpl.stream = cw
	cpl.volume_db = -6.0
	add_child(cpl)
	sfx["coin"] = cpl
	# Boss intro: a low two-note brass-like stinger (falling a fifth) with a slow tremolo.
	var boss_in_fn := func(t: float) -> float:
		var v := 0.0
		for nt: Array in [[0.0, 110.0, 0.55], [0.42, 73.4, 1.08]]:
			var tt := t - float(nt[0])
			if tt < 0.0 or tt > float(nt[2]):
				continue
			var env := minf(1.0, tt * 30.0) * minf(1.0, (float(nt[2]) - tt) * 4.0)
			var f0 := float(nt[1])
			var tone := 0.0
			for h in 6:
				tone += sin(TAU * f0 * (h + 1) * tt) / float(h + 1)
			v += tone * env * (0.85 + 0.15 * sin(TAU * 5.0 * tt))
		return v * 0.38
	_synth_sfx("boss_in", 1.5, -4.0, boss_in_fn)
	# Boss ability change: two quick falling alert blips.
	var boss_move_fn := func(t: float) -> float:
		var v := 0.0
		for nt: Array in [[0.0, 880.0], [0.14, 587.3]]:
			var tt := t - float(nt[0])
			if tt < 0.0 or tt > 0.2:
				continue
			var env := minf(1.0, tt * 400.0) * exp(-tt * 12.0)
			var s := sin(TAU * float(nt[1]) * tt)
			v += (0.6 * signf(s) + 0.4 * s) * env
		return v * 0.35
	_synth_sfx("boss_move", 0.4, -6.0, boss_move_fn)
	# Can't buy: a short low double buzz (the usual "insufficient funds" cue).
	var deny_fn := func(t: float) -> float:
		var v := 0.0
		for st: float in [0.0, 0.11]:
			var tt := t - st
			if tt < 0.0 or tt > 0.085:
				continue
			var env := minf(1.0, tt * 500.0) * minf(1.0, (0.085 - tt) * 200.0)
			var sq := signf(sin(TAU * 155.0 * tt))
			v += (0.55 * sq + 0.45 * sin(TAU * 310.0 * tt)) * env
		return v * 0.3
	_synth_sfx("deny", 0.22, -5.0, deny_fn)

# Builds a mono 22 kHz sound from fn(t) -> sample in -1..1 and registers it as sfx[key].
func _synth_sfx(key: String, secs: float, vol_db: float, fn: Callable, bus: String = "", poly: int = 1) -> void:
	var rate := 22050
	var n := int(rate * secs)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(float(fn.call(float(i) / rate)), -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	var pl := AudioStreamPlayer.new()
	pl.stream = w
	pl.volume_db = vol_db
	pl.max_polyphony = poly
	if bus != "":
		pl.bus = bus
	add_child(pl)
	sfx[key] = pl
	sfx_base_db[key] = vol_db

func _make_bus(bus_name: String) -> int:
	var i := AudioServer.get_bus_index(bus_name)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")
	while AudioServer.get_bus_effect_count(i) > 0:
		AudioServer.remove_bus_effect(i, 0)
	return i

func _load_file_sfx() -> void:
	var dir := DirAccess.open(D.SFX_DIR)
	if dir == null:
		return
	for fname in dir.get_files():
		var f := String(fname)
		if f.ends_with(".import"):
			f = f.trim_suffix(".import")
		var ext := f.get_extension().to_lower()
		if not ext in ["mp3", "wav", "ogg"]:
			continue
		var key := "f_" + f.get_basename().split("-")[0].strip_edges()
		if sfx.has(key):
			continue
		var path := D.SFX_DIR + f
		var stream: AudioStream = null
		if ResourceLoader.exists(path):
			stream = load(path)
		elif ext == "mp3" and FileAccess.file_exists(path):
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			stream = mp3
		if stream == null:
			continue
		var pl := AudioStreamPlayer.new()
		pl.stream = stream
		pl.volume_db = float(D.SFX_FILE_DB.get(key, -6.0))
		pl.max_polyphony = 4
		add_child(pl)
		sfx[key] = pl
		sfx_base_db[key] = pl.volume_db

func _tick_door_sounds() -> void:
	var cd := ch_door - door_prev_ch
	var hd := hand_t - door_prev_hand
	door_prev_ch = ch_door
	door_prev_hand = hand_t
	var cdir := signf(cd) if absf(cd) > 0.00001 else 0.0
	var hdir := signf(hd) if absf(hd) > 0.00001 else 0.0
	if cdir != 0.0 and cdir != door_dir_ch and phase == "show":
		_sc_sfx("f_metal_door_open", 0.6, 0.12)
	if hdir != 0.0 and hdir != door_dir_hand and phase == "show":
		_sc_sfx("f_metal_door_open", 0.5, 0.12)
	door_dir_ch = cdir
	door_dir_hand = hdir

func _setup_buses() -> void:
	music_bus = _make_bus("Music")
	sfx_bus = _make_bus("SFX")
	song_bus = _make_bus("Songs")
	AudioServer.set_bus_send(song_bus, "Music")
	song_hpf = AudioEffectHighPassFilter.new()
	song_hpf.cutoff_hz = 20.0
	song_lpf = AudioEffectLowPassFilter.new()
	song_lpf.cutoff_hz = 20000.0
	song_rev = AudioEffectReverb.new()
	song_rev.room_size = 0.65
	song_rev.damping = 0.4
	song_rev.wet = 0.0
	song_rev.dry = 1.0
	AudioServer.add_bus_effect(song_bus, song_hpf)
	AudioServer.add_bus_effect(song_bus, song_lpf)
	AudioServer.add_bus_effect(song_bus, song_rev)
	fx_bus = _make_bus("ScoreFX")
	AudioServer.set_bus_send(fx_bus, "SFX")
	fx_rev = AudioEffectReverb.new()
	fx_rev.room_size = 0.55
	fx_rev.wet = 0.06
	fx_rev.dry = 1.0
	AudioServer.add_bus_effect(fx_bus, fx_rev)
	if music_player != null:
		music_player.bus = "Songs"
	if bg_player != null:
		bg_player.bus = "Music"
	if audition_player != null:
		audition_player.bus = "Music"
	if tick_player != null:
		tick_player.bus = "ScoreFX"
	for k in sfx.keys():
		var ks := String(k)
		if ks.begins_with("sc_") or ks.begins_with("gear_") or ks in ["scratch", "whoosh", "riser", "impact", "roar", "f_click_switch"]:
			(sfx[k] as AudioStreamPlayer).bus = "ScoreFX"
		else:
			(sfx[k] as AudioStreamPlayer).bus = "SFX"

func _tick_audio_fx(delta: float) -> void:
	if song_bus < 0:
		return
	var want_heat := clampf((flow_live - 1.0) / 4.0, 0.0, 1.0) if resolving else 0.0
	song_heat = move_toward(song_heat, want_heat, delta * 1.5)
	song_hpf.cutoff_hz = lerpf(20.0, 240.0, song_heat * song_heat)
	song_rev.wet = lerpf(0.0, 0.18, song_heat)
	song_lpf.cutoff_hz = move_toward(song_lpf.cutoff_hz, 700.0 if song_muffled else 20000.0, delta * 60000.0)
	duck_t = maxf(0.0, duck_t - delta)
	var drop := 80.0 if song_drop else 0.0
	AudioServer.set_bus_volume_db(song_bus, lerpf(0.0, 2.0, song_heat) - (2.5 if duck_t > 0.0 else 0.0) - drop)
	AudioServer.set_bus_volume_db(fx_bus, 0.0)
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(maxf(_music_gain(), 0.0001)))
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(maxf(_sfx_gain(), 0.0001)))
	fx_rev.wet = move_toward(fx_rev.wet, 0.06, delta * 0.25)

func _sc_sfx(key: String, mag: float = 0.5, gap: float = 0.11, pitch: float = 1.0) -> void:
	if not sfx.has(key) or sfx_vol == 0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if gap > 0.0 and now - float(sfx_last.get(key, -9.0)) < gap:
		return
	sfx_last[key] = now
	var pl: AudioStreamPlayer = sfx[key]
	pl.pitch_scale = pitch * rng.randf_range(0.97, 1.03)
	pl.volume_db = float(sfx_base_db.get(key, 0.0)) + lerpf(-6.0, 3.0, clampf(mag, 0.0, 1.0)) + rng.randf_range(-1.0, 1.0)
	pl.play()

func _load_score_sounds() -> void:
	var nz := RandomNumberGenerator.new()
	nz.seed = 77
	var tick_fn := func(t: float) -> float:
		return nz.randf_range(-1.0, 1.0) * exp(-t * 170.0) * minf(1.0, t * 4000.0)
	_synth_sfx("sc_tick", 0.05, -9.0, tick_fn, "", 6)
	var thud_fn := func(t: float) -> float:
		var ph := TAU * (45.0 * t + 75.0 * (1.0 - exp(-t * 22.0)) / 22.0)
		return (sin(ph) * exp(-t * 16.0) + nz.randf_range(-1.0, 1.0) * 0.35 * exp(-t * 90.0)) * minf(1.0, t * 2000.0) * 0.9
	_synth_sfx("sc_thud", 0.22, -6.0, thud_fn, "", 4)
	var zip_fn := func(t: float) -> float:
		var u := t / 0.12
		var ph := 70.0 * t + 175.0 * t * u
		var pulse := 1.0 if fposmod(ph, 1.0) < 0.18 else 0.0
		return pulse * nz.randf_range(0.2, 1.0) * sin(PI * clampf(u, 0.0, 1.0)) * 0.7
	_synth_sfx("sc_zip", 0.12, -8.0, zip_fn, "", 6)
	for b in D.TRAYS:
		var gap := 0.014 + 0.006 * b
		var cut := 0.12 + 0.08 * b
		var dec := 70.0 + 14.0 * b
		var st := {"y": 0.0}
		var gear_fn := func(t: float) -> float:
			var x := nz.randf_range(-1.0, 1.0)
			st["y"] = float(st["y"]) + cut * (x - float(st["y"]))
			var e := exp(-t * dec) + (0.7 * exp(-(t - gap) * dec) if t >= gap else 0.0)
			return float(st["y"]) * e * 2.2
		_synth_sfx("gear_%d" % b, 0.12, -7.0, gear_fn, "", 3)
	var sst := {"y": 0.0}
	var scratch_fn := func(t: float) -> float:
		var f := 250.0 + 1100.0 * absf(sin(t * 17.0))
		var saw := fposmod(t * f, 1.0) * 2.0 - 1.0
		var x := nz.randf_range(-1.0, 1.0)
		sst["y"] = float(sst["y"]) + 0.35 * (x - float(sst["y"]))
		var env := minf(1.0, t * 60.0) * clampf((0.34 - t) * 12.0, 0.0, 1.0)
		return (saw * 0.45 + float(sst["y"]) * 0.8) * env * 0.6
	_synth_sfx("scratch", 0.35, -6.0, scratch_fn)
	var wst := {"y": 0.0}
	var whoosh_fn := func(t: float) -> float:
		var u := t / 0.5
		var a := lerpf(0.02, 0.35, sin(PI * u))
		wst["y"] = float(wst["y"]) + a * (nz.randf_range(-1.0, 1.0) - float(wst["y"]))
		return float(wst["y"]) * sin(PI * u) * 1.4
	_synth_sfx("whoosh", 0.5, -6.0, whoosh_fn)
	var rst := {"y": 0.0, "x": 0.0}
	var riser_fn := func(t: float) -> float:
		var u := t / 0.6
		var x := nz.randf_range(-1.0, 1.0)
		var hp := x - float(rst["x"])
		rst["x"] = x
		rst["y"] = float(rst["y"]) + lerpf(0.05, 0.9, u) * (hp - float(rst["y"]))
		var clicks := 1.0 if fposmod(t * lerpf(8.0, 40.0, u * u), 1.0) < 0.12 else 0.0
		return (float(rst["y"]) * 0.9 + clicks * 0.3) * u * u * 0.9
	_synth_sfx("riser", 0.6, -5.0, riser_fn)
	var ist := {"x": 0.0}
	var impact_fn := func(t: float) -> float:
		var ph := TAU * (32.0 * t + 70.0 * (1.0 - exp(-t * 6.0)) / 6.0)
		var bass := sin(ph) * exp(-t * 2.4) * minf(1.0, t * 800.0)
		var x := nz.randf_range(-1.0, 1.0)
		var hp := x - float(ist["x"])
		ist["x"] = x
		var crash := hp * exp(-t * 2.2) * 0.55
		return clampf((bass * 1.1 + crash) * 0.8, -1.0, 1.0)
	_synth_sfx("impact", 1.6, -3.0, impact_fn)
	var cst := {"y": 0.0}
	var roar_fn := func(t: float) -> float:
		cst["y"] = float(cst["y"]) + 0.09 * (nz.randf_range(-1.0, 1.0) - float(cst["y"]))
		var am := 0.7 + 0.15 * sin(t * 23.0) + 0.1 * sin(t * 37.0 + 1.3) + 0.05 * sin(t * 61.0 + 0.4)
		var env := minf(1.0, t / 0.25) * exp(-maxf(0.0, t - 0.5) * 1.6)
		return float(cst["y"]) * 3.2 * am * env
	_synth_sfx("roar", 2.2, -6.0, roar_fn)

func _cash_lcd() -> Rect2:
	return Rect2(r_cash.position.x, r_cash.position.y + 8.0, r_cash.size.x, 64.0)

func _cash_fx(amount: int, slot: int) -> void:
	if amount <= 0:
		return
	cash += amount
	cash_pulse = 1.0
	var from := _well_center(slot) if slot >= 0 else r_changer.get_center()
	var to := _cash_lcd().get_center()
	for i in clampi(amount, 2, 6):
		sparks.append({"kind": "coin", "a": from, "b": to, "t": -0.07 * i, "life": 0.5, "bend": rng.randf_range(-120.0, 120.0), "col": Color("ffd96a"), "r": rng.randf_range(9.0, 13.0), "p": from})
	if sfx.has("f_money_collect"):
		_sc_sfx("f_money_collect", clampf(float(amount) / 10.0, 0.4, 1.0), 0.08)
	elif sfx.has("coin"):
		(sfx["coin"] as AudioStreamPlayer).pitch_scale = 1.0 + minf(float(amount), 10.0) * 0.025
		_sfx("coin")

func _score_lcd() -> Rect2:
	return Rect2(r_score.position.x + 40.0, r_score.position.y + 50.0, r_score.size.x - 80.0, 160.0)

func _pts_lcd() -> Rect2:
	return Rect2(r_score.position.x + 40.0, r_score.position.y + 700.0, 250.0, 104.0)

func _flow_lcd() -> Rect2:
	return Rect2(r_score.position.x + 40.0, r_score.position.y + 880.0, 250.0, 104.0)

func _tick_eq(delta: float) -> void:
	if eq_level.is_empty():
		for i in EQ_COLS:
			eq_level.append(0.0)
			eq_peak.append(0.0)
			eq_hue.append(0.0)
	for i in EQ_COLS:
		eq_level[i] = maxf(0.0, float(eq_level[i]) - delta * 1.5)
		eq_peak[i] = maxf(float(eq_level[i]), float(eq_peak[i]) - delta * 0.6)

func _kick_eq(power: float, flow: bool = false) -> void:
	if eq_level.is_empty():
		_tick_eq(0.0)
	for i in EQ_COLS:
		var bell := 1.0 - absf(float(i) - (EQ_COLS - 1) * 0.5) / EQ_COLS * 0.9
		var v := clampf(power * bell * rng.randf_range(0.55, 1.0), 0.0, 1.0)
		if v >= float(eq_level[i]):
			eq_hue[i] = 1.0 if flow else 0.0
		eq_level[i] = maxf(float(eq_level[i]), v)
		eq_peak[i] = maxf(float(eq_peak[i]), v)

func _eq_strip(r: Rect2) -> void:
	_inset(r, 6.0, Color("0b0c0e"))
	if eq_level.is_empty():
		return
	var cw := (r.size.x - 24.0) / EQ_COLS
	var sh := (r.size.y - 16.0) / EQ_SEGS
	for i in EQ_COLS:
		var lv := float(eq_level[i]) * EQ_SEGS
		var pk := int(ceil(float(eq_peak[i]) * EQ_SEGS)) - 1
		for k in EQ_SEGS:
			var t := float(k) / (EQ_SEGS - 1)
			var col := (Color(D.FLOW_COLOR) if float(eq_hue[i]) > 0.5 else Color(D.SOUND_COLOR)).lightened(t * 0.35)
			var on := float(k) < lv
			var sr := Rect2(r.position.x + 12.0 + i * cw, r.end.y - 8.0 - (k + 1) * sh + 2.0, cw - 4.0, sh - 3.0)
			_panel(sr, col if on else (Color(col.lightened(0.3), 0.9) if k == pk and pk >= 0 else Color(col, 0.1)), 2)

func _tick() -> void:
	if tick_player != null:
		tick_player.pitch_scale = rng.randf_range(1.0, 1.5)
		tick_player.play()

func _fin_u() -> float:
	return clampf((fin_t - (D.FIN_WIND * _anim())) / (D.FIN_STREAM * _anim()), 0.0, 1.0)

func _fin_value() -> int:
	if fin_boomed:
		return fin_to
	return fin_from + int(round((fin_to - fin_from) * pow(_fin_u(), 2.2)))

func _spawn_stream() -> void:
	var a := (_flow_lcd().get_center() + _pts_lcd().get_center()) * 0.5 if SHOW_TOWER_LCDS else _slam_center()
	var b := _score_lcd().get_center()
	sparks.append({"kind": "stream", "a": a, "b": b, "t": 0.0, "life": 0.42, "bend": rng.randf_range(-160.0, 160.0), "col": Color(D.FLOW_COLOR).lightened(0.4), "r": rng.randf_range(5.0, 9.0), "p": a})

func _boom() -> void:
	fin_boomed = true
	fin_boom_t = fin_t
	score_tot = fin_to
	score_live = fin_to
	pts_pulse = 1.0
	song_drop = false
	_music_stop()
	var tgt := float(_gig_target())
	var cleared := fin_to >= _gig_target()
	var over := clampf((float(fin_to) - tgt) / tgt, 0.0, 2.0) if cleared else 0.0
	var big := clampf(float(fin_to - fin_from) / tgt, 0.0, 1.0)
	var power := maxf(big, minf(over, 1.0))
	fin_flash = (0.7 + 0.3 * minf(over, 1.0)) if cleared else 0.35
	zoom_pulse = 1.0
	fin_shake = (0.3 + 0.3 * minf(over, 1.0)) if cleared else (0.12 + 0.12 * big)
	if fx_rev != null:
		fx_rev.wet = lerpf(0.15, 0.45, minf(over, 1.0))
	_sc_sfx("impact", 0.6 + 0.4 * power, 0.0)
	if cleared or big >= 0.4:
		_sc_sfx("roar", 0.4 + 0.6 * minf(over + big * 0.5, 1.0), 0.0)
	_burst(_slam_center(), Color("ffd96a"), 40 + int(40.0 * minf(over, 1.0)), 1400.0)
	_burst(_slam_center(), Color(D.FLOW_COLOR).lightened(0.4), 20, 900.0)
	if not skip_on:
		Engine.time_scale = D.SLAM_SLOWMO
		slowmo_end_ms = Time.get_ticks_msec() + int(D.SLAM_SLOWMO_SECS * 1000.0)


func _tick_finale(delta: float) -> void:
	fin_t += delta
	var wind: float = (D.FIN_WIND * _anim())
	var end_stream: float = (D.FIN_WIND * _anim()) + (D.FIN_STREAM * _anim())
	if not fin_riser and fin_t >= maxf(0.0, end_stream - D.SLAM_DROP - D.SLAM_RISER):
		fin_riser = true
		_sc_sfx("riser", 0.8, 0.0)
	if not fin_boomed and fin_t >= end_stream - D.SLAM_DROP:
		song_drop = true
	if fin_t < wind:
		flow_pulse = maxf(flow_pulse, 0.5 + 0.5 * sin(fin_t * 14.0))
	elif fin_t < end_stream:
		var u := _fin_u()
		if fin_to >= _gig_target():
			fin_shake = maxf(fin_shake, 0.04 + 0.1 * u)
		fin_accum += delta * lerpf(10.0, 34.0, u)
		while fin_accum >= 1.0:
			fin_accum -= 1.0
			if fin_t < end_stream - 0.4:
				_spawn_stream()
		fin_tick_t -= delta
		if fin_tick_t <= 0.0 and tick_player != null and fin_t < end_stream - D.SLAM_DROP:
			fin_tick_t = lerpf(0.12, 0.06, u)
			tick_player.pitch_scale = lerpf(0.9, 1.7, u)
			tick_player.play()
	elif not fin_boomed:
		_boom()
	if fin_boomed and fin_t - fin_boom_t >= (D.FIN_HOLD * _anim()):
		fin_t = -1.0
		_end_turn()

func _tick_sparks(delta: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var f: Dictionary = sparks[i]
		f["t"] = float(f["t"]) + delta
		if String(f["kind"]) in ["stream", "coin"]:
			var u := clampf(float(f["t"]) / float(f["life"]), 0.0, 1.0)
			var a: Vector2 = f["a"]
			var b: Vector2 = f["b"]
			f["p"] = a.lerp(b, u) + Vector2(0.0, sin(u * PI) * float(f["bend"]))
			if u >= 1.0:
				if String(f["kind"]) == "coin":
					cash_pulse = maxf(cash_pulse, 0.8)
				else:
					pts_pulse = maxf(pts_pulse, 0.7)
				sparks.remove_at(i)
		else:
			var v: Vector2 = f["v"]
			v.y += 1800.0 * delta
			f["v"] = v
			f["p"] = Vector2(f["p"]) + v * delta
			if float(f["t"]) >= float(f["life"]):
				sparks.remove_at(i)

func _draw_finale() -> void:
	if fin_flash > 0.0:
		draw_rect(Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0), Color(1, 0.97, 0.85, 0.7 * fin_flash))
	for f: Dictionary in sparks:
		var p: Vector2 = f["p"]
		var col: Color = f["col"]
		if float(f["t"]) < 0.0:
			continue
		if String(f["kind"]) == "coin":
			draw_circle(p, float(f["r"]) * 1.7, Color(col, 0.28))
			draw_circle(p, float(f["r"]), col)
			draw_arc(p, float(f["r"]) * 0.65, 0.0, TAU, 16, Color(0.62, 0.45, 0.08), 2.0, true)
		elif String(f["kind"]) == "stream":
			draw_circle(p, float(f["r"]) * 1.8, Color(col, 0.25))
			draw_circle(p, float(f["r"]), col)
		else:
			var a := clampf(1.0 - float(f["t"]) / float(f["life"]), 0.0, 1.0)
			var v: Vector2 = f["v"]
			draw_line(p, p - v * 0.02, Color(col, a), float(f["r"]))
	if fin_t < 0.0:
		return
	_draw_slam()

func _mag_pts(v: float) -> float:
	var ref := maxf(20.0, float(_gig_target()) * 0.15)
	return clampf(log(1.0 + absf(v)) / log(1.0 + ref), 0.0, 1.5)

func _flow_heat(_fl: float) -> Color:
	return Color(D.FLOW_COLOR).lightened(0.2)
func _beat_pos(b: Dictionary) -> Vector2:
	var i := int(b["i"])
	match String(b["k"]):
		"hand":
			hand_pulse[i] = 1.0
			return _pocket_rect(i).get_center()
		"play":
			var sl := int(play_slots[i]) if i < play_slots.size() else i
			tray_punch[sl] = maxf(tray_punch[sl], 0.8)
			return _case_rect(sl).get_center()
		"bay":
			gear_punch[i] = 1.0
			return _bay_rect(i).get_center()
	return _slam_center()

func _event_juice(st: Dictionary, _n: int, src: String) -> void:
	var ci := int(st["ci"])
	var beat: Dictionary = st.get("beat", {})
	var bk := int(st.get("beat_k", 0))
	var bn := int(st.get("beat_n", 1))
	var owner_pulse := beat.is_empty() or bk == 0 or bk == bn - 1
	var src_pos := _bay_rect(ci).get_center() if ci >= 0 else _case_rect(song_slot).get_center()
	if ci >= 0 and owner_pulse:
		gear_punch[ci] = 1.0
		if beat.is_empty() or bk == 0:
			combo_n += 1
			if not sfx.has("f_click_switch"):
				_sc_sfx("gear_%d" % clampi(ci, 0, D.TRAYS - 1), 0.6, 0.06)
	elif ci < 0 and song_slot >= 0 and owner_pulse:
		tray_punch[song_slot] = maxf(tray_punch[song_slot], 0.7)
	if not beat.is_empty():
		src_pos = _beat_pos(beat)
	var word := String(st.get("word", ""))
	if word != "" and ev_pts == 0 and absf(ev_flow) < 0.0001 and not st.has("cash"):
		var wkey := "f_click_switch" if sfx.has("f_click_switch") else "sc_tick"
		_spawn_pop(src_pos, word, c_gold, 0.25, "", false, String(st.get("elabel", "")), "", [[wkey, 0.25, 0.04, 1.25]], true)
		return
	var esc := 1.0 + 0.1 * bk
	var big := 0.0
	var is_top := false
	var label := ""
	var gid := String(rack[ci]["id"]) if ci >= 0 and ci < rack.size() and not rack[ci].is_empty() else ""
	if ev_pts != 0 or absf(ev_flow) > 0.0001:
		var m0 := _mag_pts(float(ev_pts)) if ev_pts != 0 else clampf(absf(ev_flow) / 1.5, 0.1, 1.3)
		is_top = m0 >= top_mag - 0.0001 and m0 >= 0.45 and (beat.is_empty() or bk == bn - 1)
		if gid != "" and (is_top or not gear_seen.has(gid)) and (beat.is_empty() or bk == 0):
			label = String(gear_defs[gid]["name"])
			gear_seen[gid] = true
		elif st.has("elabel") and (beat.is_empty() or bk == 0):
			label = String(st["elabel"])
		elif is_top and src in ["fx", "bank", "carry"] and song_slot >= 0 and tray[song_slot] >= 0:
			label = _effect_name(collection[tray[song_slot]])
	var count_tag := ("x%d" % (bk + 1)) if not beat.is_empty() and bn > 1 else (("x%d" % bn) if bn > 1 else "")
	if ev_pts != 0:
		var m := _mag_pts(float(ev_pts)) * esc
		big = maxf(big, m)
		var ptxt := ("+" if ev_pts > 0 else "-") + _fmt_int(absi(ev_pts))
		if st.has("m"):
			ptxt = "x" + _ff(float(st["m"]))
		var gap := 0.04 if not beat.is_empty() else 0.06
		var psfx: Array = [["f_click_switch", m, gap, lerpf(1.12, 0.88, clampf(m, 0.0, 1.0)) * esc]]
		if not sfx.has("f_click_switch"):
			psfx = [["sc_tick", m, gap, lerpf(1.15, 0.85, clampf(m, 0.0, 1.0)) * esc]]
			if m > 0.6:
				psfx.append(["sc_thud", m, 0.1, 1.0])
		_spawn_pop(src_pos, ptxt, Color(D.SOUND_COLOR).lightened(0.25) if ev_pts > 0 else c_bad.lightened(0.3), m, "pts", is_top, label, count_tag, psfx)
		label = ""
	if absf(ev_flow) > 0.0001:
		var mf := clampf(absf(ev_flow) / 1.5, 0.1, 1.3) * esc
		big = maxf(big, mf)
		var off := Vector2(0.0, -44.0) if ev_pts != 0 else Vector2.ZERO
		var ftxt := ("+" if ev_flow > 0.0 else "-") + _ff(absf(ev_flow))
		if st.has("fm"):
			ftxt = "x" + _ff(float(st["fm"]))
		var fkey := "f_click_switch" if sfx.has("f_click_switch") else "sc_zip"
		_spawn_pop(src_pos + off, ftxt, Color(D.FLOW_COLOR).lightened(0.2), mf, "flow", is_top, label, count_tag, [[fkey, mf, 0.04 if not beat.is_empty() else 0.06, lerpf(1.1, 1.35, clampf(mf, 0.0, 1.0)) * esc]])
	if is_top and big >= 0.6:
		hitstop_t = D.HITSTOP
		fin_shake = maxf(fin_shake, 0.06 + 0.06 * big)
		duck_t = 0.25

func _spawn_pop(pos: Vector2, text: String, col: Color, mag: float, dest: String, top: bool = false, label: String = "", tag: String = "", sfx: Array = [], word: bool = false) -> void:
	for o: Dictionary in pops:
		if float(o["t"]) < D.POP_TIME and Vector2(o["p0"]).distance_to(pos) < 60.0:
			o["p0"] = Vector2(o["p0"]) + Vector2(0.0, -56.0)
	var tier := 0 if mag < 0.35 else (1 if mag < 0.7 else 2)
	if top:
		tier = 3
	var p := pos + Vector2(rng.randf_range(-18.0, 18.0), 0.0)
	var bend := rng.randf_range(-140.0, 140.0) * (1.0 + 0.35 * tier)
	pops.append({"p0": p, "p": p, "text": text, "col": col, "mag": mag, "dest": dest, "t": -D.POP_DELAY, "trail": [], "bend": bend, "rot": deg_to_rad(rng.randf_range(-5.0, 5.0)), "tier": tier, "label": label, "tag": tag, "sfx": sfx, "hold": D.POP_TIME + 0.05 * tier, "streak": D.STREAK_TIME * (1.0 - 0.12 * tier), "word": word})

func _tick_pops(pd: float, _delta: float) -> void:
	for i in range(hand_pulse.size()):
		hand_pulse[i] = maxf(0.0, hand_pulse[i] - pd * 4.0)
	for i in range(pops.size() - 1, -1, -1):
		var f: Dictionary = pops[i]
		var t0 := float(f["t"])
		f["t"] = t0 + pd
		var t := float(f["t"])
		var p0: Vector2 = f["p0"]
		if t < 0.0:
			f["p"] = p0
			continue
		if t0 < 0.0:
			for sx: Array in (f["sfx"] as Array):
				_sc_sfx(String(sx[0]), float(sx[1]), float(sx[2]), float(sx[3]))
			if float(f["mag"]) > 0.0:
				_burst(p0, f["col"], 4 + int(8.0 * float(f["mag"])) + 6 * int(f["tier"]), 420.0 + 300.0 * float(f["mag"]))
		var lift := p0 + Vector2(0.0, -20.0)
		if String(f["dest"]) == "":
			f["p"] = p0 + Vector2(0.0, -60.0 * clampf(t, 0.0, 1.0))
			if t >= 1.0:
				pops.remove_at(i)
			continue
		var hold := float(f["hold"])
		if t < hold:
			f["p"] = p0.lerp(lift, clampf(t / hold, 0.0, 1.0))
			continue
		var u := clampf((t - hold) / float(f["streak"]), 0.0, 1.0)
		var b := _pop_dest(String(f["dest"]))
		f["p"] = lift.lerp(b, u * u) + Vector2(0.0, -sin(u * PI) * float(f["bend"]))
		var tr: Array = f["trail"]
		tr.append(f["p"])
		if tr.size() > 6 + 3 * int(f["tier"]):
			tr.pop_front()
		if u >= 1.0:
			if String(f["dest"]) == "pts":
				pts_pulse = 1.0
				pts_flash = 1.0
			else:
				flow_pulse = 1.0
				flow_flash = 1.0
			_burst(b, f["col"], 6 + int(8.0 * float(f["mag"])), 380.0)
			pops.remove_at(i)

func _draw_pops() -> void:
	for f: Dictionary in pops:
		var t := float(f["t"])
		if t < 0.0:
			continue
		var mag := float(f["mag"])
		var tier := int(f["tier"])
		var col: Color = f["col"]
		var tr: Array = f["trail"]
		for k in range(tr.size() - 1):
			var w := (3.0 + 3.0 * tier) * float(k + 1) / tr.size()
			draw_line(tr[k], tr[k + 1], Color(col, 0.15 + 0.5 * float(k) / tr.size()), w, true)
		var fly := String(f["dest"]) == ""
		var hold := float(f["hold"])
		var ps := _pop_scale(minf(t, 0.25), mag, hold, float(f["streak"]), tier) if fly else _pop_scale(t, mag, hold, float(f["streak"]), tier)
		var holding := t < hold
		if tier == 3 and holding:
			ps *= 1.0 + 0.06 * sin(clock * 30.0)
		var fs := int((T_LG + 26.0 * minf(mag, 1.2)) * ps)
		if fs < 6:
			continue
		var a := clampf((1.0 - t) / 0.3, 0.0, 1.0) if fly else 1.0
		var text := String(f["text"])
		var tw := _heavy_w(text, fs)
		var fill := col
		var oc := Color(0, 0, 0, 0.85)
		var ow := 2.0 + float(tier)
		var glow := 0.0
		var shake := 0.0
		match tier:
			1:
				glow = 0.12
			2:
				glow = 0.22
				shake = 2.0
			3:
				glow = 0.3 + 0.12 * sin(clock * 12.0)
				shake = 4.0
		var jit := Vector2(sin(clock * 91.0 + t * 7.0), cos(clock * 77.0 + t * 5.0)) * shake if holding else Vector2.ZERO
		draw_set_transform(xf_origin + (Vector2(f["p"]) + jit) * xf_scale, float(f["rot"]), Vector2(xf_scale, xf_scale))
		if glow > 0.0:
			_panel(Rect2(-tw * 0.5 - fs * 0.35, -fs * 0.62, tw + fs * 0.7, fs * 1.24), Color(col, glow * a), int(fs * 0.55))
		var lp := Vector2(-tw * 0.5, fs * 0.35)
		if bool(f.get("word", false)):
			for k in 8:
				_rich_heavy(lp + Vector2.from_angle(k * TAU / 8.0) * 3.0, text, fs, Color(0, 0, 0, 0.85 * a))
			_rich_heavy(lp, text, fs, Color(fill, a))
		else:
			_heavy(lp + Vector2(3.0, 5.0), text, fs, Color(0, 0, 0, 0.5 * a))
			for k in 8:
				_heavy(lp + Vector2.from_angle(k * TAU / 8.0) * ow, text, fs, Color(oc, oc.a * a))
			_heavy(lp, text, fs, Color(fill, a))
		var tag := String(f["tag"])
		if tag != "" and not bool(f.get("word", false)):
			var tfs := int(fs * 0.42)
			_heavy(Vector2(tw * 0.5 + 6.0, -fs * 0.1) + Vector2(2.0, 2.0), tag, tfs, Color(0, 0, 0, 0.6 * a))
			_heavy(Vector2(tw * 0.5 + 6.0, -fs * 0.1), tag, tfs, Color(1, 1, 1, 0.9 * a))
		var label := String(f["label"])
		if label != "" and (fly or t < hold + float(f["streak"]) * 0.5):
			var lfs := T_SM
			var lw := _text_w(label, lfs, true)
			_text(Vector2(-lw * 0.5 + 2.0, fs * 0.35 + lfs + 8.0), label, lfs, Color(0, 0, 0, 0.7 * a), true)
			_text(Vector2(-lw * 0.5, fs * 0.35 + lfs + 6.0), label, lfs, Color(1, 1, 1, 0.92 * a), true)
		draw_set_transform(xf_origin, 0.0, Vector2(xf_scale, xf_scale))

func _expand_beats(src: Array, flow0: float) -> Array:
	var out: Array = []
	var prev_run := 0
	var prev_flow := flow0
	for st0 in src:
		var st: Dictionary = st0
		var silent := int(st["run"]) == prev_run and not st.has("cash") and String(st.get("word", "")) == "" and (not st.has("flow") or absf(float(st["flow"]) - prev_flow) < 0.0001)
		if silent:
			continue
		var bs: Array = st.get("beats", [])
		var n := bs.size()
		if n > 1 and n <= D.BEAT_MAX:
			for k in n:
				var sub: Dictionary = st.duplicate()
				sub.erase("beats")
				sub["beat"] = bs[k]
				sub["beat_k"] = k
				sub["beat_n"] = n
				sub["run"] = prev_run + int(round(float(int(st["run"]) - prev_run) * float(k + 1) / float(n)))
				if st.has("flow"):
					sub["flow"] = prev_flow + (float(st["flow"]) - prev_flow) * float(k + 1) / float(n)
				if st.has("cash"):
					var c := int(st["cash"])
					sub["cash"] = c * (k + 1) / n - c * k / n
				out.append(sub)
		else:
			var one: Dictionary = st.duplicate()
			one.erase("beats")
			if n > D.BEAT_MAX:
				one["beat_n"] = n
			out.append(one)
		prev_run = int(st["run"])
		if st.has("flow"):
			prev_flow = float(st["flow"])
	return out

func _beat_step(n: int) -> float:
	return (D.BEAT_STEP if n <= 5 else D.BEAT_STEP_FAST) * _anim() * turn_pace

func _tag_effect(out: Array, from: int, ename: String) -> void:
	if ename == "" or ename == "Effect":
		return
	for k in range(from, out.size()):
		var st: Dictionary = out[k]
		if not st.has("elabel"):
			st["elabel"] = ename
			return

func _tag_beats(out: Array, bs: Array) -> void:
	if bs.size() > 1 and not out.is_empty():
		(out.back() as Dictionary)["beats"] = bs

func _gear_beats(r: Dictionary, e: Dictionary, d: Disc, s: int, ids: Array, fx: Dictionary) -> Array:
	var bs: Array = []
	match String(r.get("per", "none")):
		"hand_of_genre":
			var hgi := D.GENRES.find(String(r.get("rparam", "")))
			for p in wallet.size():
				if wallet[p] >= 0 and collection[wallet[p]].genre == hgi:
					bs.append({"k": "hand", "i": p})
		"earlier_genre", "later_genre":
			var egi := D.GENRES.find(String(r.get("rparam", "")))
			for j in ids.size():
				var de := _ids_disc(ids, j)
				if de != null and de.genre == egi and ((j < s) if String(r.get("per", "")) == "earlier_genre" else (j > s)):
					bs.append({"k": "play", "i": j})
		"earlier_same_genre":
			if d.genre >= 0:
				for j in s:
					var dj := _ids_disc(ids, j)
					if dj != null and _in_genre(dj, d.genre):
						bs.append({"k": "play", "i": j})
		"units_fired":
			for fk in (fx.get("gf", {}) as Dictionary):
				if int(fk) < int(e["ci"]):
					bs.append({"k": "bay", "i": int(fk)})
	var cap := int(r.get("cap", 0))
	if cap > 0 and bs.size() > cap:
		bs = bs.slice(0, cap)
	return bs

func _card_beats(rule: Dictionary, s: int, ids: Array) -> Array:
	var bs: Array = []
	var p := String(rule.get("cparam", ""))
	match String(rule.get("condition", "")):
		"per_before":
			for j in s:
				var dj := _ids_disc(ids, j)
				if dj != null and _name_matches(dj, p):
					bs.append({"k": "play", "i": j})
		"per_hand":
			for w in wallet.size():
				if wallet[w] >= 0 and _name_matches(collection[wallet[w]], p):
					bs.append({"k": "hand", "i": w})
	return bs
func _pop_dest(dest: String) -> Vector2:
	if not SHOW_TOWER_LCDS:
		return _gutter_pos(dest, pts_roll, flow_roll)
	return (_pts_lcd() if dest == "pts" else _flow_lcd()).get_center()

func _ease_out_back(u: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(u - 1.0, 3.0) + c1 * pow(u - 1.0, 2.0)

func _pop_scale(t: float, mag: float, hold: float = D.POP_TIME, streak: float = D.STREAK_TIME, tier: int = 0) -> float:
	var peak := 1.2 + 0.2 * minf(mag, 1.0) + 0.15 * maxf(0.0, float(tier - 1))
	if t < 0.12:
		return peak * _ease_out_back(t / 0.12) / 1.1
	if t < hold:
		return lerpf(peak, 1.0, (t - 0.12) / maxf(0.01, hold - 0.12))
	return lerpf(1.0, 0.55, clampf((t - hold) / streak, 0.0, 1.0))
func _burst(pos: Vector2, col: Color, n: int, speed: float) -> void:
	for i in n:
		var v := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(speed * 0.35, speed)
		v.y -= speed * 0.3
		sparks.append({"kind": "burst", "p": pos, "v": v, "t": 0.0, "life": rng.randf_range(0.3, 0.6), "col": col, "r": rng.randf_range(2.5, 5.0)})

func _draw_column_focus() -> void:
	if not (resolving and playing and now_slot >= 0 and phase == "show"):
		return
	for k in D.TRAYS:
		if k == now_slot or gear_punch[k] > 0.05:
			continue
		var top := _bay_rect(k).position.y - 8.0
		_panel(Rect2(_col_x(k) - 8.0, top, COL_W + 16.0, STAGE_BOTTOM - top), Color(0.02, 0.02, 0.03, 0.4), 10)

func _slam_center() -> Vector2:
	return Vector2(1608.0, (STAGE_BOTTOM + HAND_PLATE_Y) * 0.5 + GUTTER_NUDGE)

func _gutter_pos(dest: String, pv: float, fv: float, k: float = 1.0) -> Vector2:
	var c := _slam_center()
	var pfs := int(T_HERO * 1.2)
	if dest == "pts":
		var wp := _heavy_w(_fmt_int(int(round(pv))), pfs)
		return c + Vector2(-(GUTTER_GAP * k + wp * 0.5 * lerpf(0.15, 1.0, k)), 0.0)
	var wf := _heavy_w(_ff(fv), pfs)
	return c + Vector2(GUTTER_GAP * k + wf * 0.5 * lerpf(0.15, 1.0, k), 0.0)

func _draw_gutter_score() -> void:
	if SHOW_TOWER_LCDS or phase != "show" or not resolving or fin_t >= 0.0:
		return
	var c := _slam_center()
	var pfs := int(T_HERO * 1.2)
	var pc := Color(D.SOUND_COLOR).lightened(0.35)
	var fc := _flow_heat(flow_roll)
	var pp := _gutter_pos("pts", pts_roll, flow_roll)
	var fp := _gutter_pos("flow", pts_roll, flow_roll)
	if pts_pulse > 0.0:
		_panel(Rect2(pp - Vector2(120.0, 55.0), Vector2(240.0, 110.0)).grow(10.0 * pts_pulse), Color(pc, 0.25 * pts_pulse + 0.15 * pts_flash), 30)
	if flow_pulse > 0.0 or flow_roll >= 4.0:
		var fg := maxf(flow_pulse + 0.6 * flow_flash, 0.5 + 0.2 * sin(clock * 8.0) if flow_roll >= 4.0 else 0.0)
		_panel(Rect2(fp - Vector2(120.0, 55.0), Vector2(240.0, 110.0)).grow(10.0 * fg), Color(fc, 0.25 * fg), 30)
	_slam_text(pp + Vector2(0.0, -pfs * 0.85), "POINTS", T_SM, Color(1, 1, 1, 0.7))
	_slam_text(fp + Vector2(0.0, -pfs * 0.85), "FLOW", T_SM, Color(1, 1, 1, 0.7))
	_slam_text(pp, _fmt_int(int(round(pts_roll))), int(pfs * (1.0 + 0.1 * pts_pulse)), pc)
	_slam_text(fp, _ff(flow_roll), int(pfs * (1.0 + 0.1 * flow_pulse)), fc)
	_slam_text(c, "x", T_LG, Color(1, 1, 1, 0.8))

func _slam_text(pos: Vector2, text: String, fs: int, col: Color) -> void:
	var tw := _heavy_w(text, fs)
	var p := pos + Vector2(-tw * 0.5, fs * 0.35)
	for o in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
		_heavy(p + o, text, fs, Color(0, 0, 0, col.a * 0.85))
	_heavy(p + Vector2(4.0, 6.0), text, fs, Color(0, 0, 0, col.a * 0.5))
	_heavy(p, text, fs, col)

func _draw_slam() -> void:
	var c := _slam_center()
	var wind := D.FIN_WIND * _anim()
	var end_stream := wind + D.FIN_STREAM * _anim()
	var hold := D.FIN_HOLD * _anim()
	var bt := fin_t - fin_boom_t if fin_boomed else 0.0
	var a := clampf(fin_t / maxf(wind, 0.01), 0.0, 1.0)
	if fin_boomed:
		a = clampf((hold - bt) / 0.3, 0.0, 1.0)
	draw_rect(Rect2(720.0, 160.0, 1776.0, HAND_PLATE_Y - 160.0), Color(0, 0, 0, 0.35 * a))
	if not fin_boomed:
		var u := clampf(fin_t / maxf(end_stream, 0.01), 0.0, 1.0)
		var k := 1.0 - u * u * u
		var jit := Vector2(sin(fin_t * 63.0), cos(fin_t * 57.0)) * 6.0 * u
		var pfs := int(T_HERO * (1.2 + 0.25 * u))
		var pp := _gutter_pos("pts", float(turn_base), finale_flow, k)
		var fp := _gutter_pos("flow", float(turn_base), finale_flow, k)
		var la := 0.7 * a * k
		_slam_text(pp + jit, _fmt_int(turn_base), pfs, Color(Color(D.SOUND_COLOR).lightened(0.35), a))
		_slam_text(fp - jit, _ff(finale_flow), pfs, Color(_flow_heat(finale_flow), a))
		_slam_text(c, "x", T_LG, Color(1, 1, 1, 0.8 * a * k))
		_slam_text(pp + Vector2(0.0, -pfs * 0.85), "POINTS", T_SM, Color(1, 1, 1, la))
		_slam_text(fp + Vector2(0.0, -pfs * 0.85), "FLOW", T_SM, Color(1, 1, 1, la))
		return
	var gain := fin_to - fin_from
	var punch := 1.0 + 1.2 * maxf(0.0, 1.0 - bt / 0.18)
	var nfs := int(minf(T_HERO * 2.2 * punch, 320.0))
	_slam_text(c, "+" + _fmt_int(gain), nfs, Color(Color("ffd96a"), a))
	var tgt := _gig_target()
	var y := c.y - T_HERO * 2.0
	if fin_to >= tgt:
		var ratio := float(fin_to) / float(tgt)
		var rank := "LEGENDARY" if ratio >= 2.5 else ("HUGE" if ratio >= 1.5 else "NICE")
		var rcol := Color("ff6ad5") if ratio >= 2.5 else (Color("ff9a3c") if ratio >= 1.5 else Color("7fe0a0"))
		var rpop := 1.0 + 0.5 * maxf(0.0, 1.0 - (bt - 0.12) / 0.2) if bt >= 0.12 else 0.0
		if rpop > 0.0:
			_slam_text(Vector2(c.x, y), rank, int(T_XL * 1.4 * rpop), Color(rcol, a))
		var sub := "TARGET SCORE CLEARED" if fin_to - tgt <= 0 else "OVERDRIVE +%d%%" % int(round((ratio - 1.0) * 100.0))
		y -= T_XL * 1.5
		_slam_text(Vector2(c.x, y), sub, T_LG, Color(1, 1, 1, 0.9 * a))
	if combo_n > 1:
		y -= T_LG * 1.6
		_slam_text(Vector2(c.x, y), "%d GEAR TRIGGERS" % combo_n, T_MD, Color(Color(D.ENERGY_COLOR).lightened(0.4), a))

func _process(delta: float) -> void:
	_prewarm_step()
	if slowmo_end_ms > 0 and Time.get_ticks_msec() >= slowmo_end_ms:
		slowmo_end_ms = 0
		Engine.time_scale = 1.0
	var pd := delta * (D.SKIP_SPEED if skip_on else 1.0)
	if hitstop_t > 0.0:
		hitstop_t = maxf(0.0, hitstop_t - delta)
		pd = 0.0
	_tick_pops(pd, delta)
	pts_pulse = maxf(0.0, pts_pulse - delta * 2.5)
	move_flash = maxf(0.0, move_flash - delta)
	for sk in shake_t.keys():
		shake_t[sk] = float(shake_t[sk]) - delta
		if float(shake_t[sk]) <= 0.0:
			shake_t.erase(sk)
	if vol_drag != "":
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_vol_set_from_mouse()
		else:
			if vol_drag == "sfx":
				_sfx("click")
			vol_drag = ""
			_save_prefs()
	if hand_after_shop and not ch_shop:
		hand_after_shop = false
		hand_hold = false
	if boss_intro_t > 0.0:
		boss_intro_t = maxf(0.0, boss_intro_t - delta)
		if boss_intro_t <= 0.0 and move_flash_pending:
			move_flash_pending = false
			_flag_move_change()
	var want_shop := shop_open and phase == "show"
	if ch_shop != want_shop:
		ch_door = move_toward(ch_door, 1.0, delta * 2.33)
		if ch_door >= 0.999:
			ch_shop = want_shop
	else:
		ch_door = move_toward(ch_door, 0.0, delta * 2.33)
	hand_t = move_toward(hand_t, 1.0 if (hand_hold or discard_pending or library_pending) and phase == "show" else 0.0, delta * 2.33)
	_tick_door_sounds()
	if discard_pending and hand_t >= 0.999:
		discard_pending = false
		_discard_hand_now()
	if library_pending and hand_t >= 0.999:
		library_pending = false
		_library_swap()
	_tick_eq(delta)
	_tick_drag(delta)
	_tick_bg(delta)
	_tick_pack(delta)
	_tick_hold(delta)
	_tick_audition(delta)
	_tick_audio_fx(delta)
	rec_pop = maxf(0.0, rec_pop - delta * 4.0)
	flow_pulse = maxf(0.0, flow_pulse - delta * 2.5)
	cash_pulse = maxf(0.0, cash_pulse - delta * 2.5)
	fin_flash = maxf(0.0, fin_flash - delta * 2.2)
	zoom_pulse = maxf(0.0, zoom_pulse - delta * 3.0)
	pts_flash = maxf(0.0, pts_flash - delta * 5.0)
	flow_flash = maxf(0.0, flow_flash - delta * 5.0)
	for i in tray_punch.size():
		tray_punch[i] = maxf(0.0, tray_punch[i] - pd * 10.0)
		gear_punch[i] = maxf(0.0, gear_punch[i] - pd * 10.0)
	if resolving:
		pts_roll = lerpf(pts_roll, float(turn_pts), 1.0 - exp(-delta * 14.0))
		flow_roll = lerpf(flow_roll, flow_live, 1.0 - exp(-delta * 14.0))
	else:
		pts_roll = float(turn_pts)
		flow_roll = flow_live
	fin_shake = maxf(0.0, fin_shake - delta * (0.5 if fin_t >= 0.0 and not fin_boomed else 2.2))
	if not sparks.is_empty():
		_tick_sparks(delta)
	if fin_t >= 0.0:
		_tick_finale(pd)
	_flush_say_queue()
	message_t = maxf(0.0, message_t - delta)
	pickup_shake = maxf(0.0, pickup_shake - delta)
	for i in comp_flash.size():
		comp_flash[i] = maxf(0.0, comp_flash[i] - delta * 2.2)
	for i in D.SETLIST:
		slot_flash[i] = maxf(0.0, slot_flash[i] - delta * 3.0)
	for i in range(floats.size() - 1, -1, -1):
		var f: Dictionary = floats[i]
		f["life"] = float(f["life"]) - delta
		f["pos"] = Vector2(f["pos"]) + Vector2(0.0, -50.0 * delta)
		if float(f["life"]) <= 0.0:
			floats.remove_at(i)
	if playing:
		spin += delta * 5.0
		xfade_pos = lerpf(xfade_pos, 0.15 if now_slot % 2 == 0 else 0.85, minf(1.0, delta * 3.0))
		step_t -= pd
		slot_elapsed += pd
		if step_t <= 0.0:
			if step_i < steps.size():
				_play_step(steps[step_i])
				step_i += 1
				step_t = _chain_step()
				chain_i += 1
				if step_i < steps.size() and (steps[step_i] as Dictionary).has("beat") and int(steps[step_i]["beat_k"]) > 0:
					step_t = _beat_step(int(steps[step_i]["beat_n"]))
			elif step_i == steps.size():
				step_i += 1
				step_t = maxf(D.SONG_TAIL * _anim() * turn_pace, slot_hook - slot_elapsed)
				music_t = 999.0 if slot_last else step_t
			else:
				_finish_song()
	if resolving and music_t < 900.0:
		music_t = maxf(0.0, music_t - pd)
	if resolving and music_player != null and music_player.playing and not menu_music:
		music_age += delta
		var fade_in := clampf(music_age / D.HOOK_FADE_IN, 0.0, 1.0)
		var fade_out := clampf(music_t / 0.35, 0.0, 1.0)
		music_player.volume_db = linear_to_db(maxf(fade_in * fade_out, 0.0001))
	if menu_fade > 0.0:
		menu_fade = maxf(0.0, menu_fade - delta)
		if music_player != null and music_player.playing:
			music_player.volume_db = linear_to_db(clampf(menu_fade / D.MENU_FADE, 0.0001, 1.0))
		if menu_fade <= 0.0:
			_music_stop()
	_ui_process(delta)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if not pack.is_empty() and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not _pack_ready():
			pack_skipped = true
			pack_t = _pack_ready_time()
			return
		if resolving and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and skip_rect.has_point(_ui_mouse()):
			_skip_scoring()
			return
		if fin_t >= 0.0 and mb.pressed and not fin_boomed:
			fin_t = (D.FIN_WIND * _anim()) + (D.FIN_STREAM * _anim())
			return
		if binder_open and mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_flip_binder(-1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			press_pos = _ui_mouse()
			if not _try_drag_press(press_pos):
				_ui_click(press_pos)
		elif mb.button_index == MOUSE_BUTTON_LEFT and (drag_active or drag_pending):
			if drag_active:
				_end_drag()
			else:
				drag_pending = false
				_ui_click(press_pos)
		elif mb.button_index == MOUSE_BUTTON_LEFT and held >= 0 and press_pos.distance_to(_ui_mouse()) > DRAG_MIN:
			_ui_click(_ui_mouse())
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_cancel()
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		var key := (ev as InputEventKey).keycode
		if key == KEY_ESCAPE:
			_cancel()
		elif key == KEY_B and phase in ["show", "shop", "map", "fork"]:
			_toggle_binder()
		elif binder_open and key == KEY_LEFT:
			_flip_binder(-1)
		elif binder_open and key == KEY_RIGHT:
			_flip_binder(1)

func _cancel() -> void:
	swap_first = -1
	if drag_active or drag_pending:
		_cancel_drag()
		return
	if not dig_offer.is_empty():
		return
	if not tbrowse.is_empty():
		tbrowse = {}
		return
	if binder_open:
		binder_open = false
		binder_pick = -1
		return
	if peek_open:
		_close_peek()
		return
	if burn_mode:
		burn_mode = false
		burn_marks.clear()
		message_t = 0.0
		return
	if consume_mode != "":
		consume_mode = ""
		consume_slot = -1
		message_t = 0.0
		return
	if gear_sel >= 0:
		gear_sel = -1
		return
	if bench >= 0:
		bench = -1
		return
	if not install_queue.is_empty():
		install_queue.pop_front()
		install_price = 0
		install_src = -1
		if install_refund >= 0:
			cash += install_refund_price
			shop_items[install_refund]["sold"] = false
			install_refund = -1
		if install_stall >= 0 and install_stall < stall.size():
			cash += int(stall[install_stall]["price"])
			stall[install_stall]["sold"] = false
			install_stall = -1
		_after_placement()
	_return_held()
	sel_slot = -1
	sel_hand = -1
	dig_mode = false
	dig_marks.clear()

func _say(msg: String) -> void:
	if resolving and phase == "show":
		if not msg in say_queue:
			say_queue.append(msg)
		return
	message = msg
	message_t = 3.0

func _flush_say_queue() -> void:
	if say_queue.is_empty() or resolving:
		return
	var text := " ".join(say_queue)
	say_queue.clear()
	if message_t > 0.0 and message != "":
		text += " " + message
	message = text
	message_t = 3.5

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

func _load_gear() -> void:
	gear_defs.clear()
	if not FileAccess.file_exists(D.GEAR_PATH):
		push_error("Missing %s" % D.GEAR_PATH)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(D.GEAR_PATH))
	if data is Array:
		for u: Dictionary in data:
			gear_defs[String(u["id"])] = u

func _gp(id: String, key: String) -> float:
	return float((gear_defs[id]["params"] as Dictionary).get(key, 0.0))

func _gs(id: String, key: String) -> String:
	return String((gear_defs[id]["params"] as Dictionary).get(key, ""))

func _gear_fmt(def: Dictionary) -> String:
	var t := String(def["text"])
	var vals: Dictionary = (def["params"] as Dictionary).duplicate()
	var rl: Dictionary = def.get("rule", {})
	for k in ["amount", "cap", "aparam", "rparam", "rn", "gparam"]:
		if rl.has(k):
			vals[k] = rl[k]
	for k in vals.keys():
		var v = vals[k]
		t = t.replace("{%s}" % k, v if v is String else _ff(float(v)))
	return t

func _read_cards() -> Array:
	if not FileAccess.file_exists(D.CARDS_PATH):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(D.CARDS_PATH))
	return data if data is Array else []

func _card_to_album(c: Dictionary) -> Dictionary:
	var band := String(c.get("band", ""))
	var rule := {"condition": String(c.get("condition", "always")), "cparam": String(c.get("cond_param", "")), "effect": String(c.get("effect", "none")), "value": float(c.get("value", 0.0)), "target": String(c.get("target", "self")), "tparam": String(c.get("target_param", ""))}
	return {"id": String(c.get("id", "")), "title": String(c.get("title", "")), "orig": String(c.get("title", "")), "band": band, "cover": String(c.get("cover", "")), "song": String(c.get("song", "")), "genre": maxi(0, D.GENRES.find(String(c.get("genre", "")))), "era": maxi(0, D.ERAS.find(String(c.get("decade", "")))), "label": (absi(band.hash()) / 7) % D.LABELS.size(), "points": int(c.get("points", 3)), "rule": rule, "rarity": String(c.get("rarity", "common")), "starter": bool(c.get("starter", false)), "hook": float(c.get("hook_start", -1.0))}

func _legacy_rule(effect: String, cv: int) -> Dictionary:
	var p := ""
	if effect.ends_with("genre") or effect == "fans" or effect == "anthem":
		p = D.GENRES[clampi(cv, 0, D.GENRES.size() - 1)]
	elif effect.ends_with("decade"):
		p = D.ERAS[clampi(cv, 0, D.ERAS.size() - 1)]
	return _legacy_rule_named(effect, p)

func _legacy_rule_named(effect: String, p: String) -> Dictionary:
	var r := {"condition": "always", "cparam": "", "effect": "none", "value": 0.0, "target": "self", "tparam": ""}
	match effect:
		"odd", "even":
			r["condition"] = effect
			r["effect"] = "points"
			r["value"] = float(D.SIDE_BONUS)
		"opener":
			r["condition"] = "first"
			r["effect"] = "mult"
			r["value"] = D.OPENER_MULT
		"closer":
			r["condition"] = "last"
			r["effect"] = "mult"
			r["value"] = D.CLOSER_MULT
		"after_genre", "after_decade":
			r["condition"] = "prev_is"
			r["cparam"] = p
			r["effect"] = "mult"
			r["value"] = D.AFTER_MULT
		"hype":
			r["effect"] = "flow_add"
			r["value"] = D.AMP_ADD
			r["target"] = "set"
		"boost":
			r["effect"] = "flow_mult"
			r["value"] = D.SURGE_MULT
			r["target"] = "set"
		"fans":
			r["condition"] = "per_before"
			r["cparam"] = p
			r["effect"] = "flow_add"
			r["value"] = D.FANS_FLOW
			r["target"] = "set"
		"anthem":
			r["effect"] = "points"
			r["value"] = float(D.ANTHEM_ADD)
			r["target"] = "later_genre"
			r["tparam"] = p
		"mirror":
			r["effect"] = "copy"
	return r

func _load_albums() -> void:
	for c in _read_cards():
		albums.append(_card_to_album(c))
	if albums.is_empty():
		_legacy_albums()

func _legacy_albums() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(D.CATALOG))
	if not data is Array:
		push_error("Missing %s: run tools/make_covers.gd" % D.CATALOG)
		return
	var real := {}
	for a in data:
		var gname := String(a["genre"])
		if not real.has(gname):
			real[gname] = []
		real[gname].append(a)
	for gname: String in D.CATALOG_DATA.GENRES:
		var g := D.GENRES.find(gname)
		if g < 0 or not real.has(gname):
			continue
		var by_band := {}
		for rc0: Dictionary in real[gname]:
			if not by_band.has(rc0["band"]):
				by_band[rc0["band"]] = []
			by_band[rc0["band"]].append(rc0)
		var covers_g: Array = []
		for bk in by_band.keys():
			covers_g.append_array(by_band[bk])
		var cat_g: Array = D.CATALOG_DATA.albums_of_genre(gname)
		for k in mini(covers_g.size(), cat_g.size()):
			var rc: Dictionary = covers_g[k]
			var ca: Dictionary = cat_g[k]
			var h := absi(String(rc["band"]).hash())
			var e0 := D.ERAS.find(String(ca["decade"]))
			var rgn := RandomNumberGenerator.new()
			rgn.seed = absi(String(rc["cover"]).hash())
			var cr := _roll_cond(rgn, "")
			albums.append({"title": ca["album"], "orig": rc["album"], "band": rc["band"], "cover": rc["cover"], "genre": g, "era": e0, "label": (h / 7) % D.LABELS.size(), "points": cr["points"], "rule": _legacy_rule(String(cr["cond"]), int(cr["cond_v"]))})

func _roll_cond(rg: RandomNumberGenerator, cname: String) -> Dictionary:
	if cname == "":
		var tot := 0
		for ck in D.COND_WEIGHTS:
			tot += int(D.COND_WEIGHTS[ck])
		var roll := rg.randi_range(0, tot - 1)
		for ck in D.COND_WEIGHTS:
			roll -= int(D.COND_WEIGHTS[ck])
			if roll < 0:
				cname = String(ck)
				break
	var cv := 0
	if cname.ends_with("genre") or cname == "fans" or cname == "anthem":
		cv = rg.randi_range(0, D.GENRES.size() - 1)
	elif cname.ends_with("decade"):
		cv = rg.randi_range(0, D.ERAS.size() - 1)
	return {"cond": cname, "cond_v": cv, "points": int(D.COND_POINTS[cname])}

func _music_files(dir: String, out: Array) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_music_files(dir.path_join(sub), out)
	var seen := {}
	for f in DirAccess.get_files_at(dir):
		var name := f.trim_suffix(".import").trim_suffix(".remap")
		if name.get_extension().to_lower() in ["mp3", "ogg", "wav"] and not seen.has(name):
			seen[name] = true
			out.append(dir.path_join(name))

func _music_key(s: String) -> String:
	return " ".join(s.to_lower().split(" ", false))

func _load_music() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	bg_player = AudioStreamPlayer.new()
	bg_player.volume_db = -80.0
	add_child(bg_player)
	_music_files(D.BG_DIR, bg_files)
	audition_player = AudioStreamPlayer.new()
	audition_player.volume_db = -80.0
	add_child(audition_player)
	var files: Array = []
	_music_files(D.MUSIC_DIR, files)
	for a: Dictionary in albums:
		if String(a.get("cover", "")) == "":
			continue
		if String(a.get("song", "")) != "":
			album_music[a["cover"]] = String(a["song"])
			continue
		var key := _music_key("%s - %s" % [a["band"], a["orig"]])
		for f: String in files:
			var base := _music_key(f.get_file().get_basename())
			if base == key or base.begins_with(key + " -"):
				album_music[a["cover"]] = f
				break

func _bg_next() -> void:
	if bg_files.is_empty() or bg_player == null:
		return
	bg_idx = (bg_idx + 1) % bg_files.size() if bg_idx >= 0 else rng.randi_range(0, bg_files.size() - 1)
	var stream := _music_stream(String(bg_files[bg_idx]))
	if stream == null:
		return
	if bg_files.size() == 1 and "loop" in stream:
		stream.loop = true
	bg_player.stream = stream
	bg_player.stream_paused = false
	bg_player.play(0.0)

func _bg_wanted() -> bool:
	# Background music plays on the main menu (title, kit and deck pick) and during gigs.
	if not phase in ["title", "kits", "decks", "show"]:
		return false
	if resolving or playing:
		return false
	if audition_target != null or audition_cur != null or audition_gain > 0.02:
		return false
	if gig_done and phase in ["show", "end", "result", "over", "won"]:
		return false
	return true

func _tick_bg(delta: float) -> void:
	if bg_player == null or bg_files.is_empty():
		return
	if not (phase in ["show", "end", "result", "over", "won"]):
		gig_done = false
	if _bg_wanted():
		if bg_player.stream_paused:
			bg_player.stream_paused = false
		elif not bg_player.playing:
			_bg_next()
		bg_gain = move_toward(bg_gain, 1.0, delta / D.BG_FADE_IN)
	else:
		bg_gain = move_toward(bg_gain, 0.0, delta / D.BG_FADE_OUT)
		if bg_gain <= 0.0 and bg_player.playing:
			bg_player.stream_paused = true
	bg_player.volume_db = linear_to_db(maxf(bg_gain, 0.0001)) + D.BG_DB

func _audition(d: Disc) -> void:
	if d != null and not d.cdr and ui_live:
		audition_target = d

func _tick_audition(delta: float) -> void:
	if audition_player == null:
		return
	var tgt := audition_target
	if tgt != audition_cur:
		audition_gain = move_toward(audition_gain, 0.0, delta / 0.15)
		if audition_gain <= 0.0:
			audition_player.stop()
			audition_cur = null
			if tgt != null:
				var stream := _music_stream(_music_for(tgt))
				if stream != null:
					audition_cur = tgt
					audition_player.stream = stream
					var len := stream.get_length()
					audition_player.play(rng.randf_range(0.0, len - 20.0) if len > 25.0 else 0.0)
	else:
		audition_gain = move_toward(audition_gain, 1.0 if tgt != null else 0.0, delta / (0.25 if tgt != null else 0.3))
		if tgt == null and audition_gain <= 0.0 and audition_player.playing:
			audition_player.stop()
	audition_player.volume_db = linear_to_db(maxf(audition_gain, 0.0001)) + D.AUDITION_DB

func _music_for(d: Disc) -> String:
	if d.song != "" and not d.cdr:
		return d.song
	return String(album_music.get(d.mix_cover if d.cdr else d.cover, ""))

func _on_music_finished() -> void:
	if menu_music and phase in ["title", "kits", "decks"] and menu_fade <= 0.0:
		music_player.play(0.0)

func _music_stream(path: String) -> AudioStream:
	var stream: AudioStream
	if ResourceLoader.exists(path):
		stream = load(path)
	elif path.get_extension().to_lower() == "mp3":
		var mp3 := AudioStreamMP3.new()
		mp3.data = FileAccess.get_file_as_bytes(path)
		stream = mp3
	return stream

func _music_start(d: Disc) -> void:
	music_t = D.MUSIC_SECONDS
	menu_music = false
	menu_fade = 0.0
	var path := _music_for(d)
	if path == "" or music_player == null:
		return
	var stream := _music_stream(path)
	if stream == null:
		return
	music_player.stream = stream
	music_player.volume_db = linear_to_db(0.0001)
	music_age = 0.0
	var from := rng.randf_range(0.0, maxf(0.0, stream.get_length() - D.MUSIC_SECONDS - 1.0))
	if d.hook >= 0.0 and d.song != "" and not d.cdr:
		from = clampf(d.hook, 0.0, maxf(0.0, stream.get_length() - 1.0))
	music_player.play(from)

func _menu_song() -> void:
	menu_music = false
	menu_fade = 0.0
	_music_stop()
	menu_album = {}
	if not albums.is_empty():
		menu_album = albums[rng.randi_range(0, albums.size() - 1)]

func _menu_fade_out() -> void:
	if menu_music and music_player != null and music_player.playing:
		menu_fade = D.MENU_FADE
	menu_music = false

func _music_stop() -> void:
	if music_player != null:
		music_player.stop()

func _thumb_path(path: String) -> String:
	return D.THUMB_DIR + path.get_file().get_basename() + ".jpg"

func _make_thumb(img: Image, thumb: String) -> Image:
	var m := maxi(img.get_width(), img.get_height())
	if m <= D.THUMB_MAX:
		return img
	var k := float(D.THUMB_MAX) / float(m)
	img.resize(maxi(1, int(round(img.get_width() * k))), maxi(1, int(round(img.get_height() * k))), Image.INTERPOLATE_LANCZOS)
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(D.THUMB_DIR))
	img.save_jpg(ProjectSettings.globalize_path(thumb), 0.9)
	return img

func _prewarm_step() -> void:
	if prewarm_i >= albums.size():
		return
	_cover_tex(String(albums[prewarm_i]["cover"]))
	prewarm_i += 1

func _cover_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if not covers.has(path):
		var thumb := _thumb_path(path)
		var from_thumb := FileAccess.file_exists(thumb)
		var img := Image.load_from_file(ProjectSettings.globalize_path(thumb if from_thumb else path))
		if img and not from_thumb:
			img = _make_thumb(img, thumb)
		if img:
			img.generate_mipmaps()
			covers[path] = ImageTexture.create_from_image(img)
		else:
			covers[path] = null
	return covers[path]

func _tex(name: String) -> Texture2D:
	if not textures.has(name):
		textures[name] = null
		for ext in ["png", "jpg", "jpeg", "webp"]:
			var path := ProjectSettings.globalize_path(D.TEXTURES + name + "." + ext)
			if FileAccess.file_exists(path):
				var img := Image.load_from_file(path)
				if img:
					img.generate_mipmaps()
					textures[name] = ImageTexture.create_from_image(img)
				break
	return textures[name]

func _genre_tex(gi: int) -> Texture2D:
	if gi < 0 or gi >= D.GENRES.size():
		return null
	return _mask_tex("genre/" + String(D.GENRES[gi]).to_lower().replace(" ", "-"))

func _era_tex(ei: int) -> Texture2D:
	if ei < 0 or ei >= D.ERAS.size():
		return null
	return _mask_tex("decade/" + String(D.ERAS[ei]).to_lower())

# Icon <name>.png under D.ICON_DIR, turned into a white mask (dark pixels -> opaque) so it can be tinted.
# Godot 4.3's draw_circle is not anti-aliased; a smooth arc over the rim hides the stair-steps.
func _aa_circle(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r - 0.5, col)
	draw_arc(c, r - 0.75, 0.0, TAU, maxi(32, int(r * 1.5)), col, 1.5, true)

func _mask_tex(name: String) -> Texture2D:
	var key := "icon:" + name
	if textures.has(key):
		return textures[key]
	textures[key] = null
	var path := ProjectSettings.globalize_path(D.ICON_DIR + name + ".png")
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	# Keep icons at 256 px: mipmaps then give smooth edges at every size they are drawn.
	if img.get_width() > 256 or img.get_height() > 256:
		img.resize(256, maxi(1, int(256.0 * img.get_height() / img.get_width())), Image.INTERPOLATE_LANCZOS)
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(1, 1, 1, p.a * (1.0 - p.get_luminance())))
	img.generate_mipmaps()
	textures[key] = ImageTexture.create_from_image(img)
	return textures[key]

func _make_disc(a: Dictionary) -> Disc:
	var d := Disc.new()
	d.uid = next_uid
	next_uid += 1
	d.title = a["title"]
	d.band = a["band"]
	d.cover = a["cover"]
	d.song = String(a.get("song", ""))
	d.hook = float(a.get("hook", -1.0))
	d.genre = a["genre"]
	d.era = a["era"]
	d.label = a["label"]
	d.sound = int(a["points"])
	d.rule = (a["rule"] as Dictionary).duplicate()
	d.rarity = String(a.get("rarity", "common"))
	if rng.randf() < D.EDITION_CHANCE:
		var eds: Array = D.EDITIONS.keys()
		d.edition = eds[rng.randi_range(0, eds.size() - 1)]
	return d

func _resolve_mix(d: Disc) -> void:
	var mixable: Array = albums.filter(func(o): return not bool(o.get("starter", false)))
	var a: Dictionary = mixable[rng.randi_range(0, mixable.size() - 1)]
	d.genre = a["genre"]
	d.era = a["era"]
	d.mix_cover = a["cover"]

func _reset_mixes() -> void:
	for d in collection:
		if d.cdr:
			d.genre = -1
			d.era = -1
			d.mix_cover = ""

func _make_cdr() -> Disc:
	var d := Disc.new()
	d.uid = next_uid
	next_uid += 1
	d.title = "Blank CD-R"
	d.band = ""
	d.cover = ""
	d.genre = -1
	d.era = -1
	d.label = rng.randi_range(0, D.LABELS.size() - 1)
	d.sound = D.CDR_POINTS
	d.cdr = true
	return d

func _roll_rarity() -> String:
	var tot := 0
	for k in D.RARITY_WEIGHTS:
		tot += int(D.RARITY_WEIGHTS[k])
	var roll := rng.randi_range(0, tot - 1)
	for k in D.RARITY_WEIGHTS:
		roll -= int(D.RARITY_WEIGHTS[k])
		if roll < 0:
			return String(k)
	return "common"

func _pick_card(g: int, e: int, rarity: String, used: Array) -> Dictionary:
	var pool: Array = albums.filter(func(a): return not a.get("id", a["cover"]) in used and not bool(a.get("starter", false)))
	if pool.is_empty():
		pool = albums
	var steps: Array = []
	if rarity != "":
		steps = [[g, e, rarity], [g, -1, rarity], [-1, e, rarity], [-1, -1, rarity]]
	steps.append_array([[g, e, ""], [g, -1, ""], [-1, -1, ""]])
	for st: Array in steps:
		var cand: Array = pool.filter(func(a): return (int(st[0]) < 0 or int(a["genre"]) == int(st[0])) and (int(st[1]) < 0 or int(a["era"]) == int(st[1])) and (String(st[2]) == "" or String(a.get("rarity", "")) == String(st[2])))
		if not cand.is_empty():
			return (cand[rng.randi_range(0, cand.size() - 1)] as Dictionary).duplicate()
	return (albums[0] as Dictionary).duplicate()

func _random_albums(n: int, g0: int = -1, e0: int = -1) -> Array:
	var out: Array = []
	var used: Array = []
	for k in n:
		var g := g0 if k == 0 else -1
		var e := e0 if k == 0 else -1
		var a := _pick_card(g, e, _roll_rarity(), used)
		used.append(a.get("id", a["cover"]))
		out.append(a)
	return out

func _common(key: String, count: int) -> Array:
	var counts := {}
	for d in collection:
		if d.cdr:
			continue
		var v: int = d.genre if key == "genre" else d.era
		counts[v] = int(counts.get(v, 0)) + 1
	var out: Array = counts.keys().filter(func(v): return int(counts[v]) >= count)
	return out if not out.is_empty() else counts.keys()

func _gear_full(g: Dictionary) -> bool:
	return String(gear_defs[g["id"]]["size"]) == "full"

func _gear_cells(id: String) -> int:
	return 2 if String(gear_defs[id]["size"]) == "full" else 1

func _rand_pair(avoid: Array = []) -> Array:
	var pr: Array = []
	for _try in 20:
		var a := rng.randi_range(0, D.GENRES.size() - 1)
		var b := rng.randi_range(0, D.GENRES.size() - 2)
		if b >= a:
			b += 1
		pr = [a, b]
		if pr != avoid:
			break
	return pr

func _make_gear(id: String) -> Dictionary:
	var g := {"id": id, "used": 0, "broken": false, "done": false, "level": 0}
	var rl: Dictionary = gear_defs[id].get("rule", {})
	if String(rl.get("grow", "")) != "":
		g["count"] = 0
	if id == "piggy":
		g["pot"] = 0
	return g

func _resolve_clones() -> void:
	for i in rack.size():
		if rack[i].is_empty() or String(rack[i]["id"]) != "clone":
			continue
		if i + 1 < rack.size() and not rack[i + 1].is_empty() and String(rack[i + 1]["id"]) != "clone":
			var copy := _make_gear(String(rack[i + 1]["id"]))
			for k in ["count", "pot"]:
				if rack[i + 1].has(k):
					copy[k] = rack[i + 1][k]
			rack[i] = copy
			comp_flash[i] = 1.0

func _gear_text(g: Dictionary) -> String:
	var id := String(g["id"])
	if g.has("pairs"):
		var pr: Array = g["pairs"][0]
		if id == "octave":
			return "Songs of %s also count as %s." % [D.GENRES[int(pr[0])], D.GENRES[int(pr[1])]]
		return "Songs of %s pay $1 when they follow %s." % [D.GENRES[int(pr[0])], D.GENRES[int(pr[1])]]
	return _gear_fmt(gear_defs[id])

func _gear_max(_g: Dictionary) -> int:
	return 0

func _owned_gear() -> Array:
	var out: Array = []
	for g: Dictionary in rack:
		if not g.is_empty():
			out.append(g["id"])
	for g: Dictionary in install_queue:
		out.append(g["id"])
	return out

func _gear_pool() -> Array:
	return gear_defs.keys().filter(func(id): return bool(gear_defs[id].get("enabled", true)) and (D.CROWD_MOVES or not id in ["gate", "fog"]))

func _random_gear_ids(n: int, exclude: Array = []) -> Array:
	var owned := _owned_gear()
	var ids: Array = _gear_pool().filter(func(id): return not id in owned and not id in exclude)
	_shuffle(ids)
	return ids.slice(0, n)

func _slot_taken(i: int) -> bool:
	if not rack[i].is_empty():
		return true
	return i % 2 == 1 and not rack[i - 1].is_empty() and _gear_full(rack[i - 1])

func _anchor(i: int) -> int:
	if rack[i].is_empty() and i % 2 == 1 and not rack[i - 1].is_empty() and _gear_full(rack[i - 1]):
		return i - 1
	return i

func _can_fit(id: String) -> bool:
	if _gear_cells(id) == 2:
		for b in D.RACK_SLOTS / 2:
			if not _slot_taken(b * 2) and not _slot_taken(b * 2 + 1):
				return true
		return false
	for i in D.RACK_SLOTS:
		if not _slot_taken(i):
			return true
	return false

func _place_free(g: Dictionary) -> bool:
	if _gear_full(g):
		for b in D.RACK_SLOTS / 2:
			if not _slot_taken(b * 2) and not _slot_taken(b * 2 + 1):
				rack[b * 2] = g
				return true
		return false
	for i in D.RACK_SLOTS:
		if not _slot_taken(i):
			rack[i] = g
			return true
	return false

func _install_anchor(g: Dictionary, slot: int) -> int:
	if not _gear_full(g):
		return _anchor(slot)
	var a := (slot / 2) * 2
	var count := 0
	if not rack[a].is_empty():
		count += 1
	if not rack[a + 1].is_empty():
		count += 1
	return a if count < 2 else -1

func _put_unit(g: Dictionary, t: int) -> void:
	if _gear_full(g):
		rack[t] = g
		rack[t + 1] = {}
	else:
		rack[t] = g

func _chain() -> Array:
	var out: Array = []
	for i in rack.size():
		if not rack[i].is_empty() and not bool(rack[i].get("broken", false)):
			out.append(i)
	return out

func _gear_map() -> Dictionary:
	var out := {}
	var ch := _chain()
	for k in ch.size():
		var ci: int = ch[k]
		var g: Dictionary = rack[ci]
		out[ci] = {"g": g, "id": String(g["id"]), "ci": ci, "m": 1, "left": k, "lc": int(ch[k - 1]) if k > 0 else -1}
	return out

func _gear_m(id: String) -> int:
	return 1 if _bay_of(id) >= 0 else 0

func _octave_pairs() -> Array:
	return []

func _tray_on(ci: int) -> bool:
	return ci >= 0 and ci < tray.size() and tray[ci] >= 0

func _gear_act(id: String) -> String:
	return String(gear_defs[id].get("activates", "song"))

func _in_genre(d: Disc, gi: int) -> bool:
	if d.genre < 0 or gi < 0:
		return false
	if d.genre == gi:
		return true
	for pr: Array in _octave_pairs():
		if int(pr[0]) == d.genre and int(pr[1]) == gi:
			return true
	return false

func _nm_nb(d: Disc, nm: String) -> bool:
	if _name_matches(d, nm):
		return true
	return d.genre >= 0 and String(D.GENRES[d.genre]) == "Jazz" and D.GENRES.has(nm) and _bay_of("sax") >= 0

func _demand_bonus() -> int:
	var gm := _gear_map()
	var t := 0.0
	for key in gm:
		var e: Dictionary = gm[key]
		var r: Dictionary = gear_defs[e["id"]].get("rule", {})
		if String(r.get("effect", "")) == "block" and String(r.get("aparam", "")) == "demand" and _tray_on(int(e["ci"])):
			t += float(r.get("amount", 0.0)) * int(e["m"])
	return int(round(t))

func _crowd_block(kind: String) -> String:
	var gm := _gear_map()
	for key in gm:
		var e: Dictionary = gm[key]
		var r: Dictionary = gear_defs[e["id"]].get("rule", {})
		if String(r.get("effect", "")) == "block" and String(r.get("aparam", "")) == kind and _tray_on(int(e["ci"])):
			return String(gear_defs[e["id"]]["name"])
	return ""

func _refresh_move() -> void:
	var kind := String(crowd_move.get("kind", ""))
	if kind == "":
		return
	if bool(crowd_move.get("gated", false)):
		return
	var by := _crowd_block(kind)
	crowd_move["ignored"] = by != ""
	crowd_move["by"] = by
	blocked_slot = int(crowd_move.get("slot", -1)) if kind == "block" and by == "" else -1
	flow_live = float(_score_ctx()["fl"])

func _hand_genre_count() -> int:
	var seen := {}
	for i in wallet + tray:
		if i >= 0:
			var d: Disc = collection[i]
			if d.genre >= 0:
				seen[d.genre] = true
	return seen.size()

func _stored_flow(gm: Dictionary) -> float:
	return 0.0

func _gear_status(g: Dictionary, slot: int) -> String:
	var id := String(g["id"])
	var rl: Dictionary = gear_defs[id].get("rule", {})
	if String(rl.get("grow", "")) != "":
		return "Stored: %d" % int(g.get("count", 0))
	match id:
		"piggy":
			return "Sell value +$%d" % int(g.get("pot", 0))
		"gate":
			if phase != "show":
				return ""
			if bool(crowd_move.get("ignored", false)) and String(crowd_move.get("by", "")) != "":
				return "Cancelled this turn"
			return "Ready" if int(g.get("used", 0)) < 1 else "Used"
		"clone":
			return "Waiting for a unit to its right"
	return ""

func _new_run(kit_i: int = 0, deck: Dictionary = {}) -> void:
	gear_seen.clear()
	_menu_fade_out()
	collection.clear()
	next_uid = 1
	var kit: Dictionary = D.KITS[kit_i]
	var dk: Dictionary = deck
	if dk.is_empty():
		var all := _decks()
		dk = all[rng.randi_range(0, all.size() - 1)]
	for d: Disc in _deck_discs(dk):
		collection.append(d)
	rack.clear()
	for k in D.RACK_SLOTS:
		rack.append({})
	if D.USE_KITS:
		_place_free(_make_gear(String(kit["gear"])))
	cash = opt_cash
	consumables = ["", ""]
	consume_mode = ""
	tbrowse = {}
	tape_view = {}
	shop_open = false
	stall.clear()
	install_stall = -1
	trade_count = 0
	gig_n = 1
	plays = {}
	pack = {}
	install_queue.clear()
	last_venue = -1
	pickups_since_gear = 0
	message_t = 0.0
	if D.USE_FORK:
		_make_forks()
	else:
		_make_road()
	_back_on_road()

func _load_decks() -> void:
	deck_defs.clear()
	if FileAccess.file_exists(D.DECKS_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(D.DECKS_PATH))
		if data is Array:
			for dk: Dictionary in data:
				if bool(dk.get("enabled", true)):
					deck_defs.append(dk)
	if deck_defs.is_empty():
		var all := {}
		for a: Dictionary in albums:
			all[String(a.get("id", ""))] = 1
		deck_defs.append({"id": "all", "name": "Every card", "idea": "One of every card.", "mixes": 0, "cards": all})
	deck_defs = deck_defs.slice(0, D.DECKS_SHOWN)

func _decks() -> Array:
	return deck_defs

func _album_by_id(id: String) -> Dictionary:
	for a: Dictionary in albums:
		if String(a.get("id", "")) == id:
			return a
	return {}

func _deck_size(deck: Dictionary) -> int:
	var n := 0
	var cards: Dictionary = deck.get("cards", {})
	for id in cards.keys():
		if not _album_by_id(String(id)).is_empty():
			n += int(cards[id])
	return n

func _deck_lead(deck: Dictionary) -> Dictionary:
	var best := {}
	var top := 0
	var cards: Dictionary = deck.get("cards", {})
	for id in cards.keys():
		var a := _album_by_id(String(id))
		if not a.is_empty() and not bool(a.get("starter", false)) and int(cards[id]) > top:
			best = a
			top = int(cards[id])
	return best

func _deck_discs(deck: Dictionary) -> Array:
	var out: Array = []
	var cards: Dictionary = deck.get("cards", {})
	for id in cards.keys():
		var a := _album_by_id(String(id))
		if a.is_empty():
			continue
		for n in int(cards[id]):
			var d := _make_disc(a)
			d.edition = ""
			out.append(d)
	for n in int(deck.get("mixes", 0)):
		out.append(_make_cdr())
	return out

func _refill() -> void:
	for p in wallet.size():
		if wallet[p] < 0:
			wallet[p] = _draw_card()
	_apply_sort()

func _draw_card() -> int:
	if draw_pile.is_empty():
		draw_pile = discard.duplicate()
		discard.clear()
		_shuffle(draw_pile)
	if draw_pile.is_empty():
		return -1
	return draw_pile.pop_back()

func _st(k: int, src: String, text: String, col: String, sound: float, pool: float, score_tot: int, e0: int) -> Dictionary:
	return {"k": k, "src": src, "text": text, "col": col, "sound": sound, "pool": pool, "score_tot": score_tot, "egain": score_tot - e0}

func _num(x: float) -> String:
	if is_equal_approx(x, roundf(x)):
		return str(int(roundf(x)))
	return String.num(x, 1)

func _ff(v: float) -> String:
	var t := "%.2f" % v
	while t.contains(".") and (t.ends_with("0") or t.ends_with(".")):
		t = t.left(t.length() - 1)
	return t

func _fmt_int(n: int) -> String:
	var a := absi(n)
	var sgn := "-" if n < 0 else ""
	if a < 1000000:
		var s := str(a)
		var out := ""
		while s.length() > 3:
			out = "," + s.right(3) + out
			s = s.left(s.length() - 3)
		return sgn + s + out
	var units := [[1000000.0, "M"], [1000000000.0, "B"], [1000000000000.0, "T"]]
	var ui := 0
	for i in units.size():
		if float(a) >= float(units[i][0]):
			ui = i
	while ui < units.size():
		var txt := "%.3f" % (float(a) / float(units[ui][0]))
		if not txt.begins_with("1000."):
			return sgn + txt + String(units[ui][1])
		ui += 1
	var e := int(floor(log(float(a)) / log(10.0)))
	var mant := float(a) / pow(10.0, e)
	var mt := "%.3f" % mant
	if mt.begins_with("10."):
		e += 1
		mt = "%.3f" % (mant / 10.0)
	return "%s%se%d" % [sgn, mt, e]

func _fmt_flow(f: float) -> String:
	if f >= 1000.0:
		return _fmt_int(int(round(f)))
	return _ff(f)

func _lcd_size(r: Rect2, cap: int) -> int:
	var sz := cap
	while sz > 14 and _text_w("888.888M", sz, true) > r.size.x - 28.0:
		sz -= 1
	return sz

func _fit_size(s: String, size: int, maxw: float, floor_size: int = 9) -> int:
	var sz := size
	while sz > floor_size and _text_w(s, sz, true) > maxw:
		sz -= 1
	return sz

func _case_rect(s: int) -> Rect2:
	return Rect2(_col_x(s), TRAY_Y, COL_W, COL_W * 0.886)

func _case_cols(d: Disc) -> Array:
	if d.genre >= 0 and d.genre < D.SLEEVE_MAIN.size():
		return [Color(D.SLEEVE_MAIN[d.genre]), Color(D.SLEEVE_LIGHT[d.genre]), Color(D.SLEEVE_DARK[d.genre])]
	return [Color("4a4e55"), Color("eceff3"), Color("2b2e33")]

func _abbr(p: String) -> String:
	if D.ERAS.has(p):
		return p.left(2)
	if p == "":
		return ""
	return p.left(1).to_upper()

func _jewel_parts(d: Disc) -> Dictionary:
	if d.cdr and d.genre < 0:
		return {"cb": ["?"], "ei": "", "en": "?", "es": ""}
	var r: Dictionary = d.rule
	var eff := String(r.get("effect", "none"))
	if eff == "none":
		return {"cb": [], "ei": "", "en": "", "es": ""}
	if eff == "copy":
		return {"cb": ["@left", "="], "ei": "", "en": "=", "es": ""}
	var v := float(r.get("value", 0.0))
	var tgt := String(r.get("target", "self"))
	var tp := String(r.get("tparam", ""))
	var p := _abbr(String(r.get("cparam", "")))
	var cb: Array = []
	match String(r.get("condition", "always")):
		"first":
			cb = ["1"]
		"last":
			cb = [str(D.SETLIST)]
		"next_empty":
			cb = ["@right", "-"]
		"prev_empty":
			cb = ["@left", "-"]
		"per_empty":
			cb = ["@each", "-"]
		"odd":
			cb = ["O"]
		"even":
			cb = ["E"]
		"slot1", "slot2", "slot3", "slot4", "slot5", "slot6":
			cb = [String(r.get("condition", "")).substr(4)]
		"prev_is":
			cb = ["@left", p]
		"next_is":
			cb = ["@right", p]
		"per_before":
			cb = ["@each", p]
		"per_hand":
			cb = ["@hand", p]
	var ei := "note"
	var en := ("+$" + _ff(v)) if eff == "cash" else (("+" + _ff(v)) if eff == "points" or eff == "flow_add" else ("x" + _ff(v)))
	if eff == "consumable":
		ei = "tape"
		en = "+1"
	if eff == "flow_add" or eff == "flow_mult":
		ei = "wave"
	elif eff == "cash":
		ei = "coin"
	var es := ""
	match tgt:
		"next":
			es = "next"
		"later", "later_genre", "later_decade":
			es = "later"
		"turn":
			es = "turn"
	return {"cb": cb, "ei": ei, "en": en, "es": es}

func _icon(kind: String, c: Vector2, s: float, col: Color) -> void:
	# "g<n>" = genre n, "e<n>" = decade n: drawn from the icon images when present.
	if kind.length() == 2 and (kind[0] == "g" or kind[0] == "e") and kind[1].is_valid_int():
		var idx := int(kind[1])
		var gt := _genre_tex(idx) if kind[0] == "g" else _era_tex(idx)
		if gt:
			var sz := gt.get_size() * (s * 1.1 / maxf(gt.get_width(), gt.get_height()))
			draw_texture_rect(gt, Rect2(c - sz * 0.5, sz), false, col)
			return
		if kind[0] == "e":
			if idx >= 0 and idx < D.ERAS.size():
				var es := String(D.ERAS[idx])
				var fs := _fit_size(es, int(s * 0.7), s * 1.2, 7)
				_text_center(Rect2(c - Vector2(s, s) * 0.6, Vector2(s, s) * 1.2), es, fs, col, true)
			return
	var w := maxf(1.5, s * 0.12)
	var h := s * 0.5
	match kind:
		"note":
			draw_circle(c + Vector2(-h * 0.35, h * 0.55), h * 0.38, col)
			draw_line(c + Vector2(0.0, h * 0.5), c + Vector2(0.0, -h * 0.8), col, w)
			draw_line(c + Vector2(0.0, -h * 0.8), c + Vector2(h * 0.7, -h * 0.35), col, w)
		"tape":
			draw_rect(Rect2(c.x - h * 0.95, c.y - h * 0.6, h * 1.9, h * 1.2), col, false, w)
			draw_circle(c + Vector2(-h * 0.4, 0.0), h * 0.22, col)
			draw_circle(c + Vector2(h * 0.4, 0.0), h * 0.22, col)
		"wave":
			var pts := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				pts.append(c + Vector2(lerpf(-h, h, t), sin(t * TAU) * h * 0.45))
			draw_polyline(pts, col, w, true)
		"coin":
			draw_arc(c, h * 0.85, 0.0, TAU, 24, col, w, true)
			_text_center(Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0), "$", int(s * 0.6), col, true)
		"numbers":
			for i in 3:
				var y := c.y + (i - 1) * h * 0.6
				draw_circle(Vector2(c.x - h * 0.7, y), w * 0.7, col)
				draw_line(Vector2(c.x - h * 0.35, y), Vector2(c.x + h * 0.8, y), col, w)
		"right":
			draw_line(c + Vector2(-h * 0.8, 0.0), c + Vector2(h * 0.5, 0.0), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.95, 0.0), c + Vector2(h * 0.35, -h * 0.5), c + Vector2(h * 0.35, h * 0.5)]), col)
		"left":
			draw_line(c + Vector2(h * 0.8, 0.0), c + Vector2(-h * 0.5, 0.0), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.95, 0.0), c + Vector2(-h * 0.35, -h * 0.5), c + Vector2(-h * 0.35, h * 0.5)]), col)
		"up":
			draw_line(c + Vector2(0.0, h * 0.8), c + Vector2(0.0, -h * 0.5), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.0, -h * 0.95), c + Vector2(-h * 0.5, -h * 0.35), c + Vector2(h * 0.5, -h * 0.35)]), col)
		"flag":
			draw_line(c + Vector2(-h * 0.5, h * 0.9), c + Vector2(-h * 0.5, -h * 0.9), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.5, -h * 0.85), c + Vector2(h * 0.8, -h * 0.4), c + Vector2(-h * 0.5, h * 0.05)]), col)
		"sort":
			draw_line(c + Vector2(-h * 0.4, h * 0.8), c + Vector2(-h * 0.4, -h * 0.4), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.4, -h * 0.9), c + Vector2(-h * 0.8, -h * 0.35), c + Vector2(0.0, -h * 0.35)]), col)
			draw_line(c + Vector2(h * 0.4, -h * 0.8), c + Vector2(h * 0.4, h * 0.4), col, w)
			draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.4, h * 0.9), c + Vector2(0.0, h * 0.35), c + Vector2(h * 0.8, h * 0.35)]), col)
		"stack":
			for i in 3:
				var y := c.y + (i - 1) * h * 0.55
				draw_rect(Rect2(c.x - h * 0.8 + i * h * 0.15, y - h * 0.18, h * 1.4, h * 0.36), col)
		"finish":
			draw_line(c + Vector2(-h * 0.7, h * 0.9), c + Vector2(-h * 0.7, -h * 0.9), col, w)
			for i in 4:
				for q in 2:
					if (i + q) % 2 == 0:
						draw_rect(Rect2(c.x - h * 0.7 + i * h * 0.4, c.y - h * 0.85 + q * h * 0.4, h * 0.4, h * 0.4), col)
		"hand":
			for i in 3:
				draw_rect(Rect2(c.x - h * 0.8 + i * h * 0.55, c.y - h * 0.6 + abs(i - 1) * h * 0.25, h * 0.45, h * 1.3), col)
		"each":
			draw_line(c + Vector2(-h * 0.55, -h * 0.8), c + Vector2(0.0, h * 0.85), col, w)
			draw_line(c + Vector2(h * 0.55, -h * 0.8), c + Vector2(0.0, h * 0.85), col, w)
			draw_line(c + Vector2(-h * 0.3, -h * 0.1), c + Vector2(h * 0.3, -h * 0.1), col, w)
		"next":
			draw_polyline(PackedVector2Array([c + Vector2(-h * 0.4, -h * 0.7), c + Vector2(h * 0.4, 0.0), c + Vector2(-h * 0.4, h * 0.7)]), col, w, true)
		"later":
			draw_polyline(PackedVector2Array([c + Vector2(-h * 0.8, -h * 0.7), c + Vector2(0.0, 0.0), c + Vector2(-h * 0.8, h * 0.7)]), col, w, true)
			draw_polyline(PackedVector2Array([c + Vector2(0.0, -h * 0.7), c + Vector2(h * 0.8, 0.0), c + Vector2(0.0, h * 0.7)]), col, w, true)
		"turn":
			draw_arc(c, h * 0.75, PI * 0.25, PI * 1.8, 20, col, w, true)
			var e := c + Vector2.from_angle(PI * 0.25) * h * 0.75
			draw_colored_polygon(PackedVector2Array([e + Vector2(-h * 0.55, -h * 0.05), e + Vector2(h * 0.45, -h * 0.55), e + Vector2(h * 0.4, h * 0.45)]), col)
		"mix":
			_text_center(Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0), "?", int(s * 0.9), col, true)
		"g0":
			var star := PackedVector2Array()
			for i in 10:
				var ang := -PI * 0.5 + i * PI / 5.0
				star.append(c + Vector2.from_angle(ang) * (h * 1.05 if i % 2 == 0 else h * 0.45))
			draw_colored_polygon(star, col)
		"g1":
			draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.25, -h), c + Vector2(-h * 0.6, h * 0.1), c + Vector2(-h * 0.05, h * 0.1), c + Vector2(-h * 0.3, h), c + Vector2(h * 0.65, -h * 0.25), c + Vector2(h * 0.05, -h * 0.25)]), col)
		"g2":
			draw_arc(c, h * 0.64, 0.0, TAU, 28, col, h * 0.5, true)
		"g3":
			var moon := PackedVector2Array()
			for i in 25:
				moon.append(c + Vector2.from_angle(deg_to_rad(70.0 + i * 220.0 / 24.0)) * h)
			var ic := c + Vector2(h * 0.5, 0.0)
			for i in 25:
				moon.append(ic + Vector2.from_angle(deg_to_rad(260.3 - i * 160.6 / 24.0)) * h * 0.95)
			draw_colored_polygon(moon, col)

func _badge(c: Vector2, rad: float, fill: Color, dim: float) -> void:
	draw_circle(c + Vector2(0.0, rad * 0.12), rad * 1.05, Color(0, 0, 0, 0.5))
	draw_circle(c, rad, Color(0.94, 0.94, 0.96).darkened(dim * 0.7))
	draw_circle(c, rad * 0.9, fill.darkened(dim * 0.7))
	draw_arc(c, rad * 0.9, PI * 1.1, PI * 1.9, 24, Color(1, 1, 1, 0.18), maxf(1.0, rad * 0.06), true)

func _case_glow(r: Rect2, col: Color, a: float) -> void:
	var al := clampf(a, 0.0, 1.0)
	for k in 3:
		var g := 3.0 + k * 3.0
		_panel(r.grow(g), Color(col, al * (0.5 - k * 0.14)), 6 + int(g))

func _jewel_bounds(r: Rect2) -> Rect2:
	var cr := _jewel_box(r)
	var k := cr.size.y / 160.0
	var rad := cr.size.x * 0.135
	var off := rad * 0.55
	var b := cr.merge(Rect2(cr.position + Vector2(off, off) - Vector2(rad, rad) * 1.05, Vector2(rad, rad) * 2.1))
	var phi := 1.618034
	var pw := cr.size.x * 0.88
	var ph := pw / (phi * phi * phi)
	return b.merge(Rect2(cr.get_center().x - pw * 0.5, cr.end.y + ph * 0.236068 - ph, pw, ph + 5.0 * k))

func _jewel_box(r: Rect2) -> Rect2:
	var cs := Vector2(r.size.x, r.size.x * 0.886)
	return Rect2(r.get_center() - cs * 0.5, cs)

func _draw_jewel(r: Rect2, d: Disc, dim: float = 0.0, price: int = -1) -> void:
	var cs := Vector2(r.size.x, r.size.x * 0.886)
	var cr := Rect2(r.get_center() - cs * 0.5, cs)
	var k := cr.size.y / 160.0
	var cols := _case_cols(d)
	var main: Color = cols[0]
	var dark: Color = cols[2]
	var bw := maxi(1, int(round(2.0 * k)))
	_shadow(cr, int(6.0 * k), 5.0 * k)
	_panel(cr, Color("c9d2db"), int(4.0 * k))
	var body := cr.grow(-2.0 * k)
	_panel(body, Color("1b1e23"), int(3.0 * k))
	var pad := 5.0 * k
	var side := cr.size.y - 2.0 * pad
	var cover := Rect2(cr.end.x - side - pad, cr.position.y + pad, side, side)
	var spine := Rect2(body.position.x, body.position.y, cover.position.x - body.position.x - 2.0 * k, body.size.y)
	_grad_panel(spine, 2.0 * k, Color("3a4048"), Color("23272d"))
	for j in 3:
		var sx := spine.position.x + spine.size.x * (0.3 + j * 0.2)
		draw_line(Vector2(sx, spine.position.y + 8.0 * k), Vector2(sx, spine.end.y - 8.0 * k), Color(1, 1, 1, 0.12), maxf(1.0, 1.5 * k))
	_grad_panel(cover, 0.0, main.lightened(0.12), main.darkened(0.25))
	_disc_face(cover.get_center(), side * 0.45, d)
	_panel(cover, Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0.55), maxi(1, int(1.5 * k)))
	var gloss := PackedVector2Array([cr.position + Vector2(cr.size.x * 0.35, 0), cr.position + Vector2(cr.size.x * 0.62, 0), cr.position + Vector2(cr.size.x * 0.3, cr.size.y), cr.position + Vector2(cr.size.x * 0.03, cr.size.y)])
	draw_colored_polygon(gloss, Color(1, 1, 1, 0.07))
	draw_line(cr.position + Vector2(4.0 * k, 2.0 * k), Vector2(cr.end.x - 4.0 * k, cr.position.y + 2.0 * k), Color(1, 1, 1, 0.6), maxf(1.0, 1.5 * k))
	var title := "Mix CD" if d.cdr and d.genre < 0 else (d.title if d.title != "" else "Untitled")
	var rad := cr.size.x * 0.135
	var off := rad * 0.55
	var strip_h := cr.size.y * 0.19
	var strip := Rect2(body.position.x, body.position.y, body.size.x, strip_h)
	_grad_panel(Rect2(strip.position.x, strip.end.y, strip.size.x, 7.0 * k), 0.0, Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.0))
	draw_rect(strip, main)
	var tx := cr.position.x + off + rad + 10.0 * k
	var pfs := maxi(12, int(20.0 * k * 0.7))
	var reserve := 0.0
	if price >= 0:
		reserve = _heavy_w("$%d" % price, pfs) + 18.0 + 10.0 * k
	var tsz := _fit_size(title, int(round(strip_h * 0.66)), body.end.x - 8.0 * k - tx - reserve, 10)
	_text(Vector2(tx, strip.get_center().y + _vc(font_bold, tsz)), title, tsz, Color.WHITE, true)
	if price >= 0:
		_price_sticker(Vector2(body.end.x - 6.0 * k, strip.position.y + (strip_h - (pfs + 14.0)) * 0.5), "$%d" % price, k)
	if d.genre >= 0:
		# Two stickers stacked down the cover's right edge, in the gap between the title strip
		# and the note: genre on top (genre colour, white icon), decade below (white, dark icon).
		var srad := side * 0.15
		var sx := cover.position.x + side * 0.845
		var mid_y := cr.position.y + cr.size.y * 0.505
		var gap := cr.size.y * 0.01
		var gc := Vector2(sx, mid_y - srad - gap)
		var ec := Vector2(sx, mid_y + srad + gap)
		for sc in [gc, ec]:
			_aa_circle(sc + Vector2(0.0, 2.0 * k), srad, Color(0, 0, 0, 0.35))
		_aa_circle(gc, srad, Color.WHITE)
		_aa_circle(gc, srad - 2.0 * k, main)
		_icon("g%d" % d.genre, gc, srad * 1.2, Color.WHITE)
		_aa_circle(ec, srad, Color.WHITE)
		draw_arc(ec, srad - 1.5 * k, 0.0, TAU, 64, dark, 2.0 * k, true)
		_icon("e%d" % d.era, ec, srad * 1.2, dark)
	if d.edition != "":
		var ed: Dictionary = D.EDITIONS[d.edition]
		var esz := int(round(side * 0.065))
		var ew := _text_w(String(ed["short"]), esz, true) + 10.0 * k
		var er := Rect2(cover.position.x + side * 0.04, cover.position.y + side * 0.34, ew, side * 0.1)
		_panel(er, Color(ed["color"]), 3, Color.WHITE, bw)
		_text_center(er, String(ed["short"]), esz, Color.WHITE, true)
	if dim > 0.0:
		_panel(cr, Color(0, 0, 0, dim), int(4.0 * k))
	var white := Color(1, 1, 1, 1.0 - dim * 0.5)
	var charcoal := Color("2b2e33")
	var pc := cr.position + Vector2(off, off)
	_badge(pc, rad, Color(D.SOUND_COLOR), dim)
	var ps := _fmt_int(d.sound)
	var psz := _fit_size(ps, int(round(rad * 1.15)), rad * 1.45, 12)
	_text_center(Rect2(pc - Vector2(rad, rad), Vector2(rad, rad) * 2.0), ps, psz, white, true)
	var note := _note_tokens(d)
	if not note.is_empty():
		_draw_note(cr, k, note, dim)

func _draw_cd_player(r: Rect2, art: Texture2D = null, art_spin: float = 0.0, force_art: bool = false) -> void:
	_shadow(r, 14, 8.0)
	_grad_panel(r, 14.0, Color("34373c"), Color("202226"))
	_panel(r, Color(0, 0, 0, 0), 14, Color(0, 0, 0, 0.6), 2)
	var c := r.position + Vector2(r.size.x * 0.5, r.size.y * 0.49)
	var wr := r.size.x * 0.44
	draw_circle(c, wr + 5.0, Color("0b0c0e"))
	draw_circle(c, wr, Color("17181b"))
	draw_arc(c, wr - 8.0, 0.0, TAU, 96, Color(1, 1, 1, 0.07), 2.0, true)
	var d := _playing_disc()
	if force_art:
		_cd_art(c, wr * 0.9, art, art_spin)
	elif d != null:
		_disc_face(c, wr * 0.9 * lerpf(0.9, 1.0, 1.0 - rec_pop), d, spin)
	else:
		draw_circle(c, wr * 0.1, Color("2a2c31"))
		draw_arc(c, wr * 0.1, 0.0, TAU, 32, Color(1, 1, 1, 0.2), 2.0, true)
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(14.0, 10.0), r.position + Vector2(r.size.x * 0.62, 10.0), r.position + Vector2(14.0, r.size.y * 0.62)]), Color(1, 1, 1, 0.06))
	draw_circle(r.end - Vector2(22.0, 22.0), 5.0, Color("7fe0a0") if d != null or force_art else Color("4a4e55"))

func _setlist() -> Array:
	var ids: Array = []
	var slots: Array = []
	for s in tray.size():
		if tray[s] >= 0:
			ids.append(tray[s])
			slots.append(s)
	return [ids, slots]

func _cell_get(kind: String, idx: int) -> int:
	return tray[idx] if kind == "tray" else wallet[idx]

func _cell_set(kind: String, idx: int, v: int) -> void:
	if kind == "tray":
		tray[idx] = v
	else:
		wallet[idx] = v

func _cell_center(kind: String, idx: int) -> Vector2:
	return _well_center(idx) if kind == "tray" else _pocket_rect(idx).get_center()

func _can_drag() -> bool:
	return ui_live and phase == "show" and _hand_live() and not shop_open and consume_mode == "" and not resolving and not playing and dig_offer.is_empty() and not dig_mode and not burn_mode and not peek_open and not binder_open and not settings_open and pack.is_empty() and gear_sel < 0 and bench < 0 and install_queue.is_empty() and held < 0

func _drag_source_at(pos: Vector2) -> Array:
	for s in D.TRAYS:
		if tray[s] >= 0 and _case_rect(s).has_point(pos):
			return ["tray", s]
	for p in D.HAND:
		if wallet[p] >= 0 and _pocket_rect(p).has_point(pos):
			return ["wallet", p]
	return []

func _drop_target(pos: Vector2) -> Array:
	var best: Array = []
	var bestd := INF
	for s in D.TRAYS:
		if _tray_blocked(s):
			continue
		if tray[s] < 0 and drag_kind == "wallet" and _placed() >= _max_play():
			continue
		var rr := _case_rect(s).grow(16.0)
		if rr.has_point(pos):
			var d := pos.distance_to(rr.get_center())
			if d < bestd:
				bestd = d
				best = ["tray", s]
	for p in D.HAND:
		var r := _pocket_rect(p).grow(10.0)
		if r.has_point(pos):
			var d2 := pos.distance_to(r.get_center())
			if d2 < bestd:
				bestd = d2
				best = ["wallet", p]
	return best

func _cell_hidden(kind: String, idx: int) -> bool:
	if drag_active and drag_kind == kind and drag_idx == idx:
		return true
	for st: Dictionary in settles:
		if String(st["kind"]) == kind and int(st["idx"]) == idx:
			return true
	return false

func _try_drag_press(pos: Vector2) -> bool:
	if not _can_drag():
		return false
	var src := _drag_source_at(pos)
	if src.is_empty():
		return false
	drag_pending = true
	drag_kind = String(src[0])
	drag_idx = int(src[1])
	return true

func _start_drag() -> void:
	drag_pending = false
	drag_active = true
	drag_disc = _cell_get(drag_kind, drag_idx)
	drag_pos = _cell_center(drag_kind, drag_idx)
	drag_lift = 0.0
	drag_hover = []
	sel_slot = -1
	_sfx("click")

func _apply_drop(kind: String, idx: int) -> void:
	var a := drag_disc
	var b := _cell_get(kind, idx)
	_cell_set(kind, idx, a)
	_cell_set(drag_kind, drag_idx, b)
	settles.append({"disc": a, "kind": kind, "idx": idx, "from": drag_pos, "t": 0.0, "w0": _cell_w(drag_kind) * 1.1, "w1": _cell_w(kind)})
	if b >= 0:
		settles.append({"disc": b, "kind": drag_kind, "idx": drag_idx, "from": _cell_center(kind, idx), "t": 0.0, "w0": _cell_w(kind), "w1": _cell_w(drag_kind)})
	if kind == "tray":
		slot_flash[idx] = 1.0
	_refresh_move()
	_sfx("page_turn")

func _end_drag() -> void:
	var tgt := _drop_target(_ui_mouse())
	if tgt.is_empty() or (String(tgt[0]) == drag_kind and int(tgt[1]) == drag_idx):
		_cancel_drag()
		return
	_apply_drop(String(tgt[0]), int(tgt[1]))
	drag_active = false
	drag_disc = -1
	drag_hover = []

func _cancel_drag() -> void:
	if drag_active:
		settles.append({"disc": drag_disc, "kind": drag_kind, "idx": drag_idx, "from": drag_pos, "t": 0.0, "w0": _cell_w(drag_kind) * 1.1, "w1": _cell_w(drag_kind)})
	drag_active = false
	drag_pending = false
	drag_disc = -1
	drag_hover = []

func _tick_drag(delta: float) -> void:
	var mp := _ui_mouse()
	var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if drag_pending:
		if not down:
			drag_pending = false
		elif press_pos.distance_to(mp) > DRAG_START:
			_start_drag()
	if drag_active:
		if phase != "show" or resolving or playing:
			_cancel_drag()
		elif not down:
			_end_drag()
		else:
			drag_pos = drag_pos.lerp(mp, 1.0 - exp(-delta * 28.0))
			drag_lift = minf(1.0, drag_lift + delta * 10.0)
			drag_hover = _drop_target(mp)
	for i in range(settles.size() - 1, -1, -1):
		settles[i]["t"] = float(settles[i]["t"]) + delta
		if float(settles[i]["t"]) >= SETTLE_T:
			settles.remove_at(i)
	if drag_active:
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	elif _can_drag() and not _drag_source_at(mp).is_empty():
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _draw_lifted(di: int, pos: Vector2, w: float, sh: float) -> void:
	var r := Rect2(pos - Vector2(w, w) * 0.5, Vector2(w, w))
	_panel(Rect2(r.position + Vector2(8.0, 20.0) * sh + Vector2(0.0, w * 0.057), Vector2(w, w * 0.886)), Color(0, 0, 0, 0.22 * sh), 8)
	_draw_jewel(r, collection[di])

func _cell_rect(kind: String, idx: int) -> Rect2:
	if kind == "tray":
		return _case_rect(idx)
	return _pocket_rect(idx).grow(-8.0)

func _draw_drag() -> void:
	if drag_active:
		_panel(_cell_rect(drag_kind, drag_idx), Color(0, 0, 0, 0), 8, Color(1, 1, 1, 0.22), 3)
		var pulse := 0.16 + 0.08 * sin(clock * 5.0)
		for s in D.TRAYS:
			if not (drag_kind == "tray" and drag_idx == s) and not _tray_blocked(s):
				_panel(_case_rect(s).grow(6.0), Color(0, 0, 0, 0), 12, Color(c_gold, pulse), 3)
		for p in D.HAND:
			if not (drag_kind == "wallet" and drag_idx == p):
				_panel(_pocket_rect(p).grow(-4.0), Color(0, 0, 0, 0), 10, Color(c_gold, pulse), 3)
		if not drag_hover.is_empty() and not (String(drag_hover[0]) == drag_kind and int(drag_hover[1]) == drag_idx):
			var hr := _cell_rect(String(drag_hover[0]), int(drag_hover[1])).grow(8.0)
			_panel(hr, Color(c_gold, 0.14), 12, c_gold, 6)
	for st: Dictionary in settles:
		var u := clampf(float(st["t"]) / SETTLE_T, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - u, 3.0)
		var from: Vector2 = st["from"]
		var to := _cell_center(String(st["kind"]), int(st["idx"]))
		_draw_lifted(int(st["disc"]), from.lerp(to, e), lerpf(float(st["w0"]), float(st["w1"]), e), 1.0 - e)
	if drag_active:
		var lift := 1.0 - pow(1.0 - drag_lift, 3.0)
		_draw_lifted(drag_disc, drag_pos, _cell_w(drag_kind) * lerpf(1.0, 1.1, lift), lift)

func _return_held() -> void:
	gear_sel = -1
	if held < 0:
		return
	var p := held_from if held_from >= 0 and wallet[held_from] < 0 else wallet.find(-1)
	wallet[p] = held
	held = -1

func _placed() -> int:
	var n := 0
	for t in tray:
		if t >= 0:
			n += 1
	return n

func _can_play() -> bool:
	return ui_live and phase == "show" and not shop_open and not discard_pending and not resolving and not playing and not dig_mode and not burn_mode and not peek_open and dig_offer.is_empty() and _placed() >= 1

func _give_consumable(id: String = "") -> bool:
	var slot := consumables.find("")
	if slot < 0:
		return false
	if id == "":
		id = _tape_roll("", [])
	consumables[slot] = id
	_say("Got %s." % D.CONSUMABLES[id]["name"])
	_sfx("page_turn")
	return true

func _tape_roll(min_rar: String, exclude: Array) -> String:
	var depth := float(gig_n)
	var w := {"common": maxf(20.0, float(D.TAPE_WEIGHTS["common"]) - depth * 2.0), "uncommon": float(D.TAPE_WEIGHTS["uncommon"]), "rare": float(D.TAPE_WEIGHTS["rare"]) + depth, "legendary": float(D.TAPE_WEIGHTS["legendary"]) + depth * 0.2}
	if min_rar == "rare":
		w = {"common": 0.0, "uncommon": 0.0, "rare": 1.0, "legendary": 0.25}
	var pool: Array = []
	var tot := 0.0
	for id in D.CONSUMABLES:
		if id in exclude or (id == "quiet_down" and not D.CROWD_MOVES):
			continue
		var r := String(D.CONSUMABLES[id]["rarity"])
		if float(w[r]) <= 0.0:
			continue
		pool.append(id)
	if pool.is_empty():
		return String(D.CONSUMABLES.keys()[0])
	var per := {}
	for r in ["common", "uncommon", "rare", "legendary"]:
		var n := 0
		for id in pool:
			if String(D.CONSUMABLES[id]["rarity"]) == r:
				n += 1
		per[r] = n
	for id in pool:
		var r2 := String(D.CONSUMABLES[id]["rarity"])
		tot += float(w[r2]) / float(per[r2])
	var roll := rng.randf() * tot
	for id in pool:
		var r3 := String(D.CONSUMABLES[id]["rarity"])
		roll -= float(w[r3]) / float(per[r3])
		if roll <= 0.0:
			return String(id)
	return String(pool[pool.size() - 1])

func _tape_choices(n: int, min_rar: String) -> Array:
	var out: Array = []
	for k in n:
		out.append(_tape_roll(min_rar, out))
	return out

func _use_consumable(slot: int) -> void:
	var id := String(consumables[slot])
	if phase == "show" and _boss_kind() == "exec" and id != "":
		_say("The Label Exec has locked your consumables.")
		return
	if id == "" or binder_open or not tbrowse.is_empty():
		return
	if phase == "shop":
		if not install_queue.is_empty() or not pack.is_empty():
			return
	elif phase != "show" or resolving or playing or not dig_offer.is_empty() or dig_mode or burn_mode or peek_open:
		return
	if consume_mode != "" and consume_slot == slot:
		consume_mode = ""
		consume_slot = -1
		message_t = 0.0
		return
	var tgt := String(D.CONSUMABLES[id]["target"])
	if tgt == "cd" and (phase == "shop" or not _hand_live()):
		_open_tape_browser(slot)
		return
	if tgt != "":
		consume_mode = id
		consume_slot = slot
		swap_first = -1
		_say("Pick %s for %s. Right-click to cancel." % ["a CD in your hand" if tgt == "cd" else ("the first gear unit to swap" if id == "patch_bay" else "a gear unit"), D.CONSUMABLES[id]["name"]])
		return
	if phase == "shop":
		_say("%s can only be used during a gig." % D.CONSUMABLES[id]["name"])
		return
	match id:
		"overdrive":
			bank_in["fmult"] = float(bank_in.get("fmult", 1.0)) * 1.5
			flow_live = float(_score_ctx()["fl"])
		"wall_of_sound":
			bank_in["fmult"] = float(bank_in.get("fmult", 1.0)) * 2.5
			flow_live = float(_score_ctx()["fl"])
		"hype_reel":
			bank_in["flow"] = float(bank_in.get("flow", 0.0)) + 3.0
			flow_live = float(_score_ctx()["fl"])
		"golden_ticket":
			_cash_fx(15, -1)
		"amp_up":
			bank_in["flow"] = float(bank_in.get("flow", 0.0)) + 1.0
			flow_live = float(_score_ctx()["fl"])
		"quiet_down":
			if String(crowd_move.get("kind", "")) == "" or bool(crowd_move.get("ignored", false)):
				_say("There is nothing to quiet down this turn.")
				return
			crowd_move["ignored"] = true
			crowd_move["by"] = "Quiet Down"
			crowd_move["gated"] = true
			if String(crowd_move["kind"]) == "block":
				blocked_slot = -1
			flow_live = float(_score_ctx()["fl"])
	consumables[slot] = ""
	_sfx("page_turn")
	_say("Used %s." % D.CONSUMABLES[id]["name"])

func _cd_tape(id: String, d: Disc) -> bool:
	match id:
		"fast_forward":
			if d.era < 0 or d.era >= D.ERAS.size() - 1:
				_say("%s can't go any later." % d.title)
				return false
			d.era += 1
		"rewind":
			if d.era <= 0:
				_say("%s can't go any earlier." % d.title)
				return false
			d.era -= 1
		"remix":
			if d.genre < 0:
				return false
			var ng := d.genre
			while ng == d.genre:
				ng = rng.randi_range(0, D.GENRES.size() - 1)
			d.genre = ng
		"polish":
			d.sound += 2
		"press":
			if d.edition != "":
				_say("%s already has an edition." % d.title)
				return false
			var eds: Array = D.EDITIONS.keys()
			d.edition = String(eds[rng.randi_range(0, eds.size() - 1)])
		"bootleg":
			if not _cd_tape("dub", d):
				return false
			_cd_tape("dub", d)
		"platinum_master":
			d.sound += 8
			if d.edition == "":
				var eds3: Array = D.EDITIONS.keys()
				d.edition = String(eds3[rng.randi_range(0, eds3.size() - 1)])
		"master_tape":
			d.sound += 4
			if d.edition == "":
				var eds2: Array = D.EDITIONS.keys()
				d.edition = String(eds2[rng.randi_range(0, eds2.size() - 1)])
		"dub":
			var nd := Disc.new()
			nd.uid = next_uid
			next_uid += 1
			nd.title = d.title
			nd.band = d.band
			nd.cover = d.cover
			nd.song = d.song
			nd.genre = d.genre
			nd.era = d.era
			nd.label = d.label
			nd.sound = d.sound
			nd.rule = d.rule.duplicate()
			nd.rarity = d.rarity
			nd.edition = d.edition
			collection.append(nd)
			_enlist(nd)
	return true

func _apply_consumable(p: int) -> void:
	if p < 0 or wallet[p] < 0 or consume_mode == "" or String(D.CONSUMABLES[consume_mode]["target"]) != "cd":
		return
	var d: Disc = collection[wallet[p]]
	var id := consume_mode
	if id == "trade_in":
		doomed.append(d)
		wallet[p] = -1
	elif not _cd_tape(id, d):
		return
	consumables[consume_slot] = ""
	consume_mode = ""
	consume_slot = -1
	_sfx("page_turn")
	_say("%s used on %s." % [D.CONSUMABLES[id]["name"], d.title])

func _open_tape_browser(slot: int) -> void:
	var id := String(consumables[slot])
	var key := "%d_%s" % [slot, id]
	var cards: Array = []
	for d in (tape_view.get(key, []) as Array):
		if d in collection:
			cards.append(d)
	if cards.is_empty():
		var pool: Array = collection.duplicate()
		_shuffle(pool)
		cards = pool.slice(0, D.BROWSER_SHOW)
		tape_view[key] = cards
	tbrowse = {"id": id, "slot": slot, "cards": cards, "key": key}
	_sfx("page_turn")

func _browser_pick(d: Disc) -> void:
	if tbrowse.is_empty():
		return
	var id := String(tbrowse["id"])
	var slot := int(tbrowse["slot"])
	if id == "trade_in":
		if phase == "show":
			var ti := collection.find(d)
			draw_pile.erase(ti)
			discard.erase(ti)
			for wi in wallet.size():
				if wallet[wi] == ti:
					wallet[wi] = -1
			doomed.append(d)
		else:
			collection.erase(d)
		trade_count += 1
	elif not _cd_tape(id, d):
		return
	consumables[slot] = ""
	tape_view.erase(String(tbrowse["key"]))
	tbrowse = {}
	_sfx("page_turn")
	_say("%s used on %s." % [D.CONSUMABLES[id]["name"], d.title])

func _close_browser() -> void:
	tbrowse = {}

func _draw_tape_browser() -> void:
	hover_disc = null
	var full := Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600))
	draw_rect(full, Color(0.03, 0.04, 0.06, 0.88))
	_register(full, func(): pass)
	var id := String(tbrowse["id"])
	var def: Dictionary = D.CONSUMABLES[id]
	_heavy_center(Rect2(0.0, 120.0, UI_W, 80.0), "%s: pick a CD" % String(def["name"]), T_XL + 8, Color("f4efe4"))
	_text_center(Rect2(0.0, 210.0, UI_W, 44.0), "%s  ·  %d random CDs from your deck" % [String(def["text"]), (tbrowse["cards"] as Array).size()], T_MD, Color("b8c0cc"), true)
	var cards: Array = tbrowse["cards"]
	var cw := 330.0
	var ch := cw * 0.886
	var gap := 60.0
	var cols := 3
	var x0 := (UI_W - (cols * cw + (cols - 1) * gap)) * 0.5
	for k in cards.size():
		var d: Disc = cards[k]
		var r := Rect2(x0 + (k % cols) * (cw + gap), 320.0 + (k / cols) * (ch + 70.0), cw, ch)
		_shadow(r, 10, 10.0)
		var bhot := r.has_point(mouse)
		if bhot:
			_panel(_jewel_bounds(r).grow(8.0), Color(c_gold, 0.1), 14, c_gold, 5)
		_draw_case(r, d)
		if bhot:
			hover_disc = d
		_register(r, _browser_pick.bind(d))
	_hw_button(Rect2(UI_W * 0.5 - 130.0, 1240.0, 260.0, 90.0), "Cancel", _close_browser, true, Color("6a6f77"), T_LG)

func _gear_can_level(g: Dictionary) -> bool:
	return bool(gear_defs[g["id"]].get("levels", false)) and int(g.get("level", 0)) < D.LEVEL_NAMES.size() - 1

func _apply_consumable_gear(i: int) -> void:
	if consume_mode == "" or rack[i].is_empty() or not _gear_can_level(rack[i]):
		return
	var g: Dictionary = rack[i]
	g["level"] = int(g.get("level", 0)) + 1
	comp_flash[i] = 1.0
	var id := consume_mode
	consumables[consume_slot] = ""
	consume_mode = ""
	consume_slot = -1
	_sfx("page_turn")
	_say("%s is now %s." % [gear_defs[g["id"]]["name"], D.LEVEL_NAMES[int(g["level"])]])

func _cons_rect(i: int) -> Rect2:
	if phase == "shop":
		return Rect2(60.0 + i * (COL_W + COL_G), 1150.0, COL_W, GEAR_H)
	var x0 := r_score.position.x + (r_score.size.x - (2.0 * COL_W + COL_G)) * 0.5
	return Rect2(x0 + i * (COL_W + COL_G), r_score.end.y - 40.0 - GEAR_H, COL_W, GEAR_H)

func _draw_cons_tile(r: Rect2, id: String, targeting: bool, hot: bool) -> void:
	var def: Dictionary = D.CONSUMABLES[id]
	var col := Color(String(def["col"]))
	var w := r.size.x
	var h := r.size.y
	_shadow(r, 10, 8.0)
	_panel(r, col.lightened(0.08) if hot else col, 12, Color(0, 0, 0, 0.35), 2)
	for pt in [Vector2(14.0, 14.0), Vector2(w - 14.0, 14.0), Vector2(14.0, h - 14.0), Vector2(w - 14.0, h - 14.0)]:
		draw_circle(r.position + pt, 3.0, Color(0, 0, 0, 0.4))
	var lab := Rect2(r.position.x + w * 0.056, r.position.y + h * 0.077, w * 0.888, h * 0.568)
	_panel(lab, Color("efe6d2"), 6)
	draw_line(Vector2(lab.position.x + 16.0, lab.end.y - 12.0), Vector2(lab.end.x - 16.0, lab.end.y - 12.0), Color("cfc5ab"), 1.5)
	var nm := String(def["name"]).to_upper()
	var lines: Array[String] = [nm]
	var words := nm.split(" ")
	var maxw := lab.size.x - 28.0
	if words.size() >= 2 and _text_w(nm, 28, true) > maxw:
		lines = [String(words[0]), nm.substr(String(words[0]).length() + 1)]
	var fs := 28
	for ln in lines:
		while fs > 14 and _text_w(ln, fs, true) > maxw:
			fs -= 1
	var cy := lab.position.y + lab.size.y * 0.46
	for k in lines.size():
		_text_center(Rect2(lab.position.x, cy + (k - (lines.size() - 1) * 0.5) * fs * 1.2 - fs * 0.6, lab.size.x, fs * 1.2), lines[k], fs, Color("22252a"), true)
	var win := Rect2(r.position.x + w * 0.247, r.position.y + h * 0.70, w * 0.506, h * 0.22)
	_panel(win, Color(0.08, 0.09, 0.1, 0.8), int(win.size.y * 0.5))
	for rx in [0.35, 0.65]:
		draw_circle(r.position + Vector2(w * rx, h * 0.806), h * 0.077, Color(1, 1, 1, 0.27))
		draw_circle(r.position + Vector2(w * rx, h * 0.806), h * 0.026, Color("15171a"))
	if targeting or hot:
		_panel(r.grow(3.0), Color(0, 0, 0, 0), 14, c_gold, 4 if targeting else 2)
	if not gear_tip_off:
		_tip(r, _tape_tip(id), String(D.CONSUMABLES[id]["rarity"]))

func _draw_consumables() -> void:
	var bay := Rect2(_cons_rect(0).position - Vector2(26.0, 26.0), Vector2(2.0 * COL_W + COL_G + 52.0, GEAR_H + 52.0))
	_inset(bay, 14.0, Color("0b0c0e"))
	for bi in D.CONSUMABLE_SLOTS:
		_inset(_cons_rect(bi).grow(6.0), 10.0, Color("060708"))
	for i in D.CONSUMABLE_SLOTS:
		var r := _cons_rect(i)
		var id := String(consumables[i])
		if id == "":
			_text_center(r, "Tape %d" % (i + 1), T_XS, Color("4a4f57"), true)
			continue
		var targeting := consume_mode != "" and consume_slot == i
		var usable := ui_live and ((phase == "show" and not resolving and not playing) or (phase == "shop" and install_queue.is_empty()))
		_draw_cons_tile(r, id, targeting, usable and r.has_point(mouse))
		if usable:
			_register(r, _use_consumable.bind(i))

func _on_pocket(p: int) -> void:
	if not _hand_live():
		return
	if shop_open and consume_mode == "" and not dig_mode and not burn_mode:
		_say("Press Next Set to close the shop before placing CDs.")
		return
	if consume_mode != "":
		_apply_consumable(p)
		return
	if burn_mode:
		_on_burn_pick(p)
		return
	if dig_mode:
		if wallet[p] >= 0:
			if p in dig_marks:
				dig_marks.erase(p)
			else:
				dig_marks.assign([p])
		return
	if resolving or playing or not dig_offer.is_empty():
		return
	if sel_slot >= 0:
		var back := tray[sel_slot]
		tray[sel_slot] = wallet[p]
		wallet[p] = back
		slot_flash[sel_slot] = 1.0
		sel_slot = -1
		_refresh_move()
		_sfx("page_turn")
		return
	if wallet[p] < 0:
		return
	var o := -1
	if _placed() < _max_play():
		for k in D.TRAYS:
			if tray[k] < 0 and not _tray_blocked(k):
				o = k
				break
	if o < 0:
		_say("You can play four CDs at most. Click a CD in a tray to swap it or send it back.")
		return
	tray[o] = wallet[p]
	wallet[p] = -1
	slot_flash[o] = 1.0
	_refresh_move()
	_sfx("page_turn")

func _on_slot(s: int) -> void:
	if resolving or playing or not dig_offer.is_empty():
		return
	if _tray_blocked(s):
		return
	if sel_slot < 0:
		if tray[s] >= 0:
			sel_slot = s
			_sfx("click")
		return
	if s == sel_slot:
		var p := wallet.find(-1)
		if p >= 0:
			wallet[p] = tray[s]
			tray[s] = -1
		sel_slot = -1
		_refresh_move()
		_sfx("page_turn")
		return
	var t := tray[s]
	tray[s] = tray[sel_slot]
	tray[sel_slot] = t
	slot_flash[s] = 1.0
	sel_slot = -1
	_refresh_move()
	_sfx("page_turn")

func _set_sort(k: String) -> void:
	sort_key = "" if sort_key == k else k
	_apply_sort()

func _apply_sort() -> void:
	if sort_key == "":
		return
	var ids: Array = wallet.filter(func(x): return x >= 0)
	ids.sort_custom(func(a, b): return _sort_less(collection[a], collection[b]))
	for p in wallet.size():
		wallet[p] = int(ids[p]) if p < ids.size() else -1

func _sort_vals(d: Disc) -> Array:
	match sort_key:
		"genre":
			return [d.genre, d.era, d.title]
		"era":
			return [d.era, d.genre, d.title]
		"sound":
			return [-d.sound, d.genre, d.title]
		"ability":
			return [_reward_rank(d), d.genre, d.era, d.title]
	return [d.title, d.title, d.title]

func _sort_less(a: Disc, b: Disc) -> bool:
	var ka := _sort_vals(a)
	var kb := _sort_vals(b)
	for i in ka.size():
		if ka[i] != kb[i]:
			return ka[i] < kb[i]
	return false

func _hand_live() -> bool:
	return hand_t < 0.02 and not discard_pending and not library_pending

func _library_swap() -> void:
	burn_mode = false
	burn_marks.clear()
	for p in wallet.size():
		if wallet[p] >= 0:
			discard.append(wallet[p])
			wallet[p] = -1
	_refill()
	_sfx("page_turn")
	_say("Fresh hand from the Deep Library.")

func _discard_hand() -> void:
	if digs <= 0 or playing or resolving or discard_pending or not _hand_live():
		return
	if draw_pile.is_empty() and discard.is_empty():
		return
	_return_held()
	discard_pending = true
	_sfx("click")

func _discard_hand_now() -> void:
	if digs <= 0 or playing or resolving:
		return
	_return_held()
	var old: Array[int] = []
	for p in wallet.size():
		if wallet[p] >= 0:
			old.append(wallet[p])
			wallet[p] = -1
	if old.is_empty() and draw_pile.is_empty() and discard.is_empty():
		return
	for p in wallet.size():
		if draw_pile.is_empty() and not discard.is_empty():
			draw_pile = discard.duplicate()
			discard.clear()
			_shuffle(draw_pile)
		if not draw_pile.is_empty():
			wallet[p] = draw_pile.pop_back()
	var kept := 0
	for p in wallet.size():
		if wallet[p] < 0 and not old.is_empty():
			wallet[p] = old.pop_back()
			kept += 1
	var tuners := 0
	for ci in rack.size():
		if not rack[ci].is_empty() and String(rack[ci]["id"]) == "tuner" and _tray_on(ci):
			tuners += 1
			comp_flash[ci] = 1.0
	if tuners > 0:
		for oi in old:
			collection[oi].sound += tuners
	discard.append_array(old)
	digs -= 1
	_apply_sort()
	_sfx("page_turn")
	_say("Discarded your hand and drew %d new CDs." % (wallet.size() - kept))

func _start_dig() -> void:
	if not D.DIG_PICK:
		_discard_hand()
		return
	if digs <= 0 or playing:
		return
	_return_held()
	dig_mode = true
	dig_marks.clear()

func _confirm_dig() -> void:
	if dig_marks.is_empty() or digs <= 0:
		return
	var p: int = dig_marks[0]
	var gone := wallet[p]
	if draw_pile.size() < D.DIG_OFFERS and not discard.is_empty():
		draw_pile.append_array(discard)
		discard.clear()
		_shuffle(draw_pile)
	if draw_pile.is_empty():
		_say("There are no CDs left in the binder to draw.")
		dig_mode = false
		dig_marks.clear()
		return
	discard.append(gone)
	wallet[p] = -1
	dig_offer.clear()
	for k in mini(D.DIG_OFFERS, draw_pile.size()):
		dig_offer.append(draw_pile.pop_back())
	dig_slot = p
	digs -= 1
	dig_mode = false
	dig_marks.clear()
	_sfx("page_turn")
	_say("Discarded %s." % collection[gone].title)

func _take_offer(k: int) -> void:
	if k >= dig_offer.size():
		return
	var take: int = dig_offer[k]
	for j in dig_offer.size():
		if j != k:
			draw_pile.append(dig_offer[j])
	_shuffle(draw_pile)
	wallet[dig_slot] = take
	dig_offer.clear()
	dig_slot = -1
	_apply_sort()
	_sfx("page_turn")
	_say("Took %s." % collection[take].title)

func _toggle_pile_mode() -> void:
	pile_with_hand = not pile_with_hand
	_sfx("click")

func _pile_counts() -> Dictionary:
	var g: Array = []
	for k in D.GENRES.size():
		g.append(0)
	var e: Array = []
	for k in D.ERAS.size():
		e.append(0)
	var mix := 0
	var pool: Array = draw_pile.duplicate()
	if pile_with_hand:
		for w in wallet:
			if w >= 0:
				pool.append(w)
	for i in pool:
		var d := collection[i]
		if d.cdr and d.genre < 0:
			mix += 1
		else:
			g[d.genre] += 1
			e[d.era] += 1
	return {"genre": g, "era": e, "mix": mix, "total": pool.size()}

func _draw_pile_table(r: Rect2) -> void:
	var ink := Color("9aa1aa")
	var counts := _pile_counts()
	var x0 := r.position.x
	var w := r.size.x
	for row in 2:
		var is_genre := row == 0
		var n := D.GENRES.size() if is_genre else D.ERAS.size()
		var cw := w / n
		var ly := r.position.y + (24.0 if is_genre else 70.0)
		for k in n:
			var cell := Rect2(x0 + k * cw + 2.0, ly + 4.0, cw - 4.0, 24.0)
			var lab := String(D.GENRE_SHORT[k]) if is_genre else String(D.ERAS[k]).to_upper()
			var cnt := int((counts["genre"] if is_genre else counts["era"])[k])
			var keeps := _cell_keeps(is_genre, k)
			_silk(Vector2(cell.get_center().x - _text_w(lab, 12, true) * 0.5, ly), lab, 12, ink)
			_panel(cell, Color("0b0d0e"), 3, Color(D.FLOW_COLOR) if keeps else Color(0, 0, 0, 0.6), 2 if keeps else 1)
			var col := Color(D.FLOW_COLOR).lightened(0.3) if keeps else Color("ff9a6b")
			_text_center(cell, str(cnt), 18, col if cnt > 0 else Color(col, 0.25), true)
			if is_genre:
				draw_rect(Rect2(cell.position.x + 3.0, cell.end.y - 4.0, cell.size.x - 6.0, 2.0), Color(D.GENRE_COLORS[k]).lightened(0.35))

func _draw_dig_offer() -> void:
	var r := r_rack
	_shadow(r, 10, 14.0)
	_surface(r, 10.0, "metal_dark", Color("1d1f23"), Color("121316"))
	_panel(r, Color(0, 0, 0, 0), 10, Color(c_gold, 0.8), 3)
	var x := r.position.x + 40.0
	var w := r.size.x - 80.0
	var gone: Disc = collection[discard.back()]
	_heavy(Vector2(x, r.position.y + 76.0), "Choose 1 of %d" % dig_offer.size(), T_XL, Color("f4efe4"))
	_wrap(Vector2(x, r.position.y + 112.0), "You discarded %s. Pick a CD for the glowing slot in your hand." % gone.title, w, T_SM, Color("b8c0cc"), true)
	var ch := 372.0
	for k in dig_offer.size():
		var d: Disc = collection[dig_offer[k]]
		var cr := Rect2(x, r.position.y + 190.0 + k * (ch + 14.0), w, ch)
		_panel(cr, Color(1, 1, 1, 0.05), 12, Color(1, 1, 1, 0.14), 2)
		var dc := Vector2(cr.position.x + 120.0, cr.position.y + 124.0)
		_draw_jewel(Rect2(dc - Vector2(104.0, 104.0), Vector2(208.0, 208.0)), d)
		_tip_disc(Rect2(dc - Vector2(104.0, 92.0), Vector2(208.0, 184.0)), d)
		var tx := cr.position.x + 250.0
		var tw := cr.size.x - 270.0
		_wrap(Vector2(tx, cr.position.y + 44.0), d.title, tw, T_MD, Color.WHITE, true)
		var cx := tx
		if d.genre >= 0:
			cx += _info_chip(cx, cr.position.y + 112.0, String(D.GENRE_SHORT[d.genre]), Color("5d626a")) + 6.0
			_info_chip(cx, cr.position.y + 112.0, String(D.ERAS[d.era]), Color("5d626a"))
		else:
			_info_chip(cx, cr.position.y + 112.0, "MIX", Color("2b5fa8"))
		var body := "Becomes a random album when played." if d.cdr else _cond_text(d)
		if d.edition != "":
			body += "  " + String(D.EDITIONS[d.edition]["name"]) + " edition: " + String(D.EDITIONS[d.edition]["text"])
		_wrap(Vector2(tx, cr.position.y + 170.0), body, tw, 15, Color("e8ecf2"), true)
		_hw_button(Rect2(cr.position.x + 20.0, cr.end.y - 84.0, w - 40.0, 64.0), "Take this CD", _take_offer.bind(k), true, Color("3f9b5a"), T_SM)

func _well_center(s: int) -> Vector2:
	return _case_rect(s).get_center()

func _pocket_rect(p: int) -> Rect2:
	return Rect2(_col_x(p) - 8.0, HAND_Y - 8.0, COL_W + 16.0, COL_W * 0.886 + 16.0)

func _draw() -> void:
	_begin_draw()
	xf_origin = screen_origin
	xf_scale = ui_scale
	audition_target = null
	hold_targets.clear()
	if fin_shake > 0.0 or zoom_pulse > 0.0:
		var z := 1.0 + 0.045 * zoom_pulse
		var shake := Vector2(sin(clock * 91.0), cos(clock * 77.0)) * 16.0 * fin_shake * ui_scale
		var zoff := Vector2(UI_W, UI_H) * 0.5 * ui_scale * (1.0 - z)
		draw_set_transform(screen_origin + zoff + shake, 0.0, Vector2(ui_scale, ui_scale) * z)
		xf_origin = screen_origin + zoff + shake
		xf_scale = ui_scale * z
	var modal := phase in ["result", "over", "won", "end"] or not pack.is_empty() or binder_open or settings_open or not tbrowse.is_empty()
	ui_live = not modal and not playing
	hover_disc = null
	hover_gear = {}
	if phase == "map":
		_draw_map()
	elif phase == "fork":
		_draw_fork()
	elif phase == "boss":
		_draw_boss()
	elif phase == "title":
		_draw_title()
	elif phase == "kits":
		_draw_kits()
	elif phase == "decks":
		_draw_decks()
	elif phase == "pickup":
		_draw_pickup()
	elif phase == "reward":
		pass
	elif phase == "shop":
		_draw_shop()
		_draw_rack()
	else:
		_draw_room()
		_register(Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0), _return_held)
		_draw_changer()
		_draw_score_panel()
		_draw_wallet()
		_draw_gig_header()
		_draw_banner()
		_draw_rack()
		_draw_column_focus()
	_draw_floats()
	_draw_gutter_score()
	_draw_pops()
	_draw_finale()
	_draw_toast()
	_draw_boss_intro()
	_draw_held()
	_draw_drag()
	ui_live = true
	if not pack.is_empty():
		_draw_pack()
	if not dig_offer.is_empty():
		_draw_dig_offer()
	if peek_open:
		_draw_peek()
	if settings_open:
		_draw_settings()
	match phase:
		"result":
			_draw_result()
		"over":
			_draw_run_end(false)
		"won":
			_draw_run_end(true)
		"end":
			_draw_show_end()
	if not tbrowse.is_empty():
		_draw_tape_browser()
	elif binder_open:
		_draw_binder_overlay()
	elif (phase == "shop" and install_queue.is_empty()) or phase in ["map", "fork"]:
		_draw_binder_button()
	_draw_hold()
	if resolving:
		hover_tip = ""
	elif held < 0 and not drag_active and hover_disc != null:
		_draw_disc_tip(hover_disc)
	elif held < 0 and not drag_active and not hover_gear.is_empty() and hover_tip == "":
		_draw_gear_tip(hover_gear)
	_end_draw()

func _uvs(pts: PackedVector2Array, tile: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p / tile)
	return out

func _surface(r: Rect2, radius: float, mat: String, top: Color, bottom: Color, tile: float = 512.0) -> void:
	var tex := _tex(mat)
	if tex == null:
		_grad_panel(r, radius, top, bottom)
		return
	var pts := _round_points(r, radius)
	draw_colored_polygon(pts, top.lerp(bottom, 0.5).lightened(0.2), _uvs(pts, tile), tex)
	_grad_panel(r, radius, Color(1, 1, 1, 0.08), Color(0, 0, 0, 0.25))

func _brushed(r: Rect2, radius: float, base: Color, seed_n: int) -> void:
	if _tex("metal_brushed") != null:
		_surface(r, radius, "metal_brushed", base.lightened(0.1), base.darkened(0.1), 400.0)
	else:
		_grad_panel(r, radius, base.lightened(0.1), base.darkened(0.12))
		var g := RandomNumberGenerator.new()
		g.seed = seed_n
		var y := r.position.y + 3.0
		while y < r.end.y - 3.0:
			var a := g.randf_range(0.0, 0.07)
			draw_line(Vector2(r.position.x + radius * 0.3, y), Vector2(r.end.x - radius * 0.3, y), Color(1, 1, 1, a) if g.randf() < 0.55 else Color(0, 0, 0, a * 0.8), 1.0)
			y += g.randf_range(1.0, 3.0)
	draw_line(Vector2(r.position.x + radius, r.position.y + 1.0), Vector2(r.end.x - radius, r.position.y + 1.0), Color(1, 1, 1, 0.45), 2.0)
	draw_line(Vector2(r.position.x + radius, r.end.y - 1.0), Vector2(r.end.x - radius, r.end.y - 1.0), Color(0, 0, 0, 0.45), 2.0)
	_panel(r, Color(0, 0, 0, 0), int(radius), Color(0, 0, 0, 0.55), 1)

func _inset(r: Rect2, radius: float, col: Color) -> void:
	_panel(r, col, int(radius))
	_grad_panel(Rect2(r.position, Vector2(r.size.x, minf(r.size.y, 18.0))), radius, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.0))
	_panel(r, Color(0, 0, 0, 0), int(radius), Color(0, 0, 0, 0.7), 2)
	draw_line(Vector2(r.position.x + radius, r.end.y + 1.0), Vector2(r.end.x - radius, r.end.y + 1.0), Color(1, 1, 1, 0.18), 1.5)

func _screw(c: Vector2, rad: float) -> void:
	draw_circle(c + Vector2(0.0, 1.5), rad, Color(0, 0, 0, 0.4))
	draw_circle(c, rad, Color("7d838a"))
	draw_circle(c - Vector2(rad, rad) * 0.18, rad * 0.75, Color("c3c8ce"))
	draw_arc(c, rad, 0.0, TAU, 20, Color(0, 0, 0, 0.5), 1.0, true)
	var a := fmod(c.x * 0.37 + c.y * 0.11, PI)
	var d := Vector2.from_angle(a) * rad * 0.7
	draw_line(c - d, c + d, Color("3a3d42"), maxf(1.5, rad * 0.28))

func _led(c: Vector2, rad: float, col: Color, on: float) -> void:
	draw_circle(c, rad * 1.45, Color("111214"))
	draw_arc(c, rad * 1.45, 0.0, TAU, 20, Color(1, 1, 1, 0.12), 1.0, true)
	if on > 0.0:
		for k in 4:
			draw_circle(c, rad * (1.6 + k * 0.9), Color(col, 0.13 * on / (k + 1)))
	draw_circle(c, rad, col.darkened(0.78).lerp(col.lightened(0.2), on))
	draw_circle(c - Vector2(rad, rad) * 0.3, rad * 0.35, Color(1, 1, 1, 0.18 + 0.45 * on))

func _lcd(r: Rect2, text: String, col: Color, size: int, ghost: String = "", align: String = "right") -> void:
	_panel(r.grow(5.0), Color("0a0b0d"), 9)
	_grad_panel(r, 6.0, col.darkened(0.9).lerp(Color("0d1210"), 0.4), Color("06080a"))
	var g := ghost if ghost != "" else "8".repeat(text.length())
	var yb := r.get_center().y + _vc(font_bold, size)
	var gx := r.end.x - 14.0 - _text_w(g, size, true)
	var tx := r.end.x - 14.0 - _text_w(text, size, true)
	if align == "center":
		gx = r.get_center().x - _text_w(g, size, true) * 0.5
		tx = r.get_center().x - _text_w(text, size, true) * 0.5
	elif align == "left":
		gx = r.position.x + 14.0
		tx = r.position.x + 14.0
	_text(Vector2(gx, yb), g, size, Color(col, 0.04), true)
	_text(Vector2(tx, yb), text, size, col, true)
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(6, 4), r.position + Vector2(r.size.x * 0.45, 4), r.position + Vector2(r.size.x * 0.3, r.size.y * 0.5), r.position + Vector2(6, r.size.y * 0.5)]), Color(1, 1, 1, 0.04))

func _silk(pos: Vector2, s: String, size: int, col: Color = Color("d9dde2")) -> void:
	_text(pos, s, size, col, true)

func _knob(c: Vector2, rad: float, ang: float, cap: Color) -> void:
	draw_circle(c + Vector2(0.0, rad * 0.14), rad * 1.04, Color(0, 0, 0, 0.35))
	draw_circle(c + Vector2(0.0, rad * 0.06), rad * 1.0, Color(0, 0, 0, 0.3))
	draw_circle(c, rad, Color("1c1e22"))
	for i in 60:
		var d := Vector2.from_angle(TAU * i / 60.0)
		draw_line(c + d * rad * 0.8, c + d * rad * 0.98, Color(1, 1, 1, 0.1) if i % 2 == 0 else Color(0, 0, 0, 0.35), 2.0)
	draw_arc(c, rad - 1.0, PI * 1.1, PI * 1.9, 32, Color(1, 1, 1, 0.22), 2.0, true)
	var cr := rad * 0.74
	draw_circle(c, cr, cap)
	var g := RandomNumberGenerator.new()
	g.seed = int(c.x * 13.0 + c.y)
	var rr := cr * 0.08
	while rr < cr:
		draw_arc(c, rr, 0.0, TAU, 48, Color(1, 1, 1, g.randf_range(0.0, 0.07)) if g.randf() < 0.6 else Color(0, 0, 0, g.randf_range(0.0, 0.06)), 1.2, true)
		rr += g.randf_range(1.2, 2.6)
	draw_arc(c, cr * 0.6, -2.5, -1.7, 24, Color(1, 1, 1, 0.16), cr * 0.75, true)
	draw_arc(c, cr * 0.6, 0.65, 1.45, 24, Color(1, 1, 1, 0.09), cr * 0.75, true)
	draw_arc(c, cr, PI, TAU, 40, Color(1, 1, 1, 0.4), 2.0, true)
	draw_arc(c, cr, 0.0, PI, 40, Color(0, 0, 0, 0.45), 2.0, true)
	var pd := Vector2.from_angle(ang)
	draw_line(c + pd * cr * 0.3, c + pd * cr * 0.92, Color("b03a2e"), maxf(3.0, rad * 0.08))

func _fader_cap(r: Rect2, col: Color, lit: float) -> void:
	_panel(Rect2(r.position + Vector2(0.0, 5.0), r.size), Color(0, 0, 0, 0.45), 4)
	_grad_panel(r, 4.0, col.lightened(0.3), col.darkened(0.35))
	var mid := r.get_center()
	if r.size.x > r.size.y:
		draw_line(Vector2(r.position.x + 5.0, mid.y - 1.0), Vector2(r.end.x - 5.0, mid.y - 1.0), Color(0, 0, 0, 0.6), 2.0)
		draw_line(Vector2(r.position.x + 5.0, mid.y + 1.0), Vector2(r.end.x - 5.0, mid.y + 1.0), Color(1, 1, 1, 0.35), 1.0)
	else:
		draw_line(Vector2(mid.x - 1.0, r.position.y + 5.0), Vector2(mid.x - 1.0, r.end.y - 5.0), Color(0, 0, 0, 0.6), 2.0)
		draw_line(Vector2(mid.x + 1.0, r.position.y + 5.0), Vector2(mid.x + 1.0, r.end.y - 5.0), Color(1, 1, 1, 0.35), 1.0)
	draw_line(r.position + Vector2(3.0, 1.0), Vector2(r.end.x - 3.0, r.position.y + 1.0), Color(1, 1, 1, 0.5), 1.5)
	if lit > 0.0:
		_panel(r.grow(3.0), Color(0, 0, 0, 0), 6, Color(Color(D.SOUND_COLOR).lightened(0.3), lit), 3)
	_panel(r, Color(0, 0, 0, 0), 4, Color(0, 0, 0, 0.6), 1)

func _hw_button(r: Rect2, label: String, cb: Callable, enabled: bool, col: Color, size: int = T_LG) -> void:
	var hovered := enabled and ui_live and r.has_point(mouse)
	var down := 3.0 if hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else 0.0
	_panel(Rect2(r.position + Vector2(-4.0, -4.0), r.size + Vector2(8.0, 12.0)), Color("0d0e10"), 12)
	var body := Rect2(r.position + Vector2(0.0, down), r.size)
	_panel(Rect2(body.position + Vector2(0.0, 6.0 - down), body.size), col.darkened(0.6), 9)
	var c := col if enabled else col.lerp(Color("5a5d63"), 0.75)
	_grad_panel(body, 9.0, c.lightened(0.28 if hovered else 0.18), c.darkened(0.22))
	draw_line(body.position + Vector2(9.0, 2.0), Vector2(body.end.x - 9.0, body.position.y + 2.0), Color(1, 1, 1, 0.5 if enabled else 0.15), 2.0)
	_panel(body, Color(0, 0, 0, 0), 9, Color(0, 0, 0, 0.55), 1)
	var ink := Color.WHITE if c.get_luminance() < 0.55 else Color("1e2633")
	_text_center(body, label, size, Color(ink, 1.0 if enabled else 0.45), true)
	if enabled:
		_register(r, cb)

func _unit_plate(r: Rect2, kind: String) -> void:
	_shadow(r, 14, 12.0)
	_surface(r, 14.0, "metal_dark", Color("2b2e33"), Color("1a1c20"))
	draw_line(r.position + Vector2(14.0, 2.0), Vector2(r.end.x - 14.0, r.position.y + 2.0), Color(1, 1, 1, 0.22), 2.0)
	_panel(r, Color(0, 0, 0, 0), 14, Color("5c626b") if kind == "changer" else Color(0, 0, 0, 0.65), 3 if kind == "changer" else 2)
	if kind == "changer" or kind == "hand":
		_inset(Rect2(r.position.x + 10.0, r.position.y + 10.0, r.size.x - 20.0, r.size.y - 20.0), 10.0, Color("0e1013"))

func _draw_room() -> void:
	draw_rect(Rect2(-800, -800, UI_W + 1600, UI_H + 1600), Color("131518"))
	_unit_plate(Rect2(720.0, 172.0, 1776.0, 199.0), "rig")
	_unit_plate(Rect2(720.0, CHANGER_Y, 1776.0, CHANGER_H), "changer")
	_unit_plate(Rect2(720.0, HAND_PLATE_Y, 1776.0, 280.0), "hand")

func _door_face(r: Rect2, seed_n: int) -> void:
	_shadow(r, 8, 8.0)
	_brushed(r, 8.0, Color("9aa1a9"), seed_n)
	_panel(Rect2(r.get_center().x - 50.0, r.end.y - 16.0, 100.0, 8.0), Color("c3c8ce"), 4, Color(0, 0, 0, 0.5), 1)

func _draw_hand_door() -> void:
	if hand_t <= 0.01:
		return
	var e := hand_t * hand_t * (3.0 - 2.0 * hand_t)
	_door_face(Rect2(730.0, HAND_PLATE_Y + 10.0, 1756.0, maxf(12.0, 260.0 * e)), 91)

func _draw_bottom() -> void:
	var cx := 1608.0
	var y := BUTTON_Y
	var h := 100.0
	if shop_open and phase == "show":
		var ok := ui_live and _shop_live() and install_queue.is_empty() and pack.is_empty()
		_hw_button(Rect2(cx - 140.0, y, 280.0, h), "Next Set", _close_stall, ok, Color("2f6fc2"), T_LG)
		return
	skip_rect = Rect2()
	if resolving and phase == "show":
		skip_rect = Rect2(cx - 140.0, y, 280.0, h)
		_hw_button(skip_rect, "Skip  >>" if not skip_on else "Skipping", _skip_scoring, not skip_on, Color("a8861c"), T_LG)
		return
	if not _hand_live():
		return
	var dr := Rect2(cx - 14.0 - 280.0, y, 280.0, h)
	var pr := Rect2(cx + 14.0, y, 280.0, h)
	var can := ui_live and phase == "show" and not resolving and not discard_pending and _hand_live() and digs > 0 and draw_pile.size() + discard.size() > 0
	_hw_button(dr, "Discard", _start_dig, can, Color("c23a2e"), T_LG)
	var lamps := maxi(opt_discards, digs)
	for k in lamps:
		_led(Vector2(dr.end.x - 30.0 - (lamps - 1 - k) * 24.0, dr.position.y + 18.0), 6.0, Color("ffb347"), 1.0 if k < digs else 0.0)
	_hw_button(pr, "Play" if not resolving else "Playing", _play, _can_play(), Color("3f9b5a"), T_LG)

func _trays_live() -> bool:
	return not ch_shop and ch_door < 0.02 and not shop_open

func _shop_live() -> bool:
	return ch_shop and shop_open and ch_door < 0.02

func _draw_changer() -> void:
	if ch_shop:
		_draw_stall()
	else:
		for s in D.TRAYS:
			_draw_well(s)
			_draw_tray_disc(s)
	_draw_changer_door()

func _draw_changer_door() -> void:
	if ch_door <= 0.01:
		return
	var e := ch_door * ch_door * (3.0 - 2.0 * ch_door)
	_door_face(Rect2(730.0, CHANGER_Y + 10.0, 1756.0, maxf(12.0, (CHANGER_H - 20.0) * e)), 77)

func _draw_tray_disc(s: int) -> void:
	var cr := _case_rect(s)
	var c := Vector2(cr.get_center().x, cr.position.y - 32.0)
	var occupied := tray[s] >= 0
	var blocked := _tray_blocked(s)
	var ring := Color(1, 1, 1, 0.2)
	var ink := Color("6c727a")
	if blocked:
		ring = Color("ffb0a6")
		ink = ring
	elif occupied:
		ring = c_gold
		ink = c_gold
	draw_circle(c, 22.0, Color("0b0c0e"))
	draw_arc(c, 22.0, 0.0, TAU, 32, ring, 3.0 if (occupied or blocked) else 2.0, true)
	if _slot_met(s):
		draw_arc(c, 29.0, 0.0, TAU, 32, Color(c_gold, 0.5), 3.0, true)
	_text_center(Rect2(c - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), str(s + 1), T_MD, ink, true)

func _draw_links() -> void:
	var sl: Array = _setlist()[1]
	var y := TRAY_Y + COL_W * 0.886 + 150.0
	for k in sl.size():
		var cx: float = _case_rect(int(sl[k])).get_center().x
		var lab: String = ["1ST", "2ND", "3RD", "4TH"][k]
		_text_center(Rect2(cx - 40.0, y - 30.0, 80.0, 24.0), lab, 18, c_gold, true)
		draw_circle(Vector2(cx, y), 6.0, c_gold)
		if k + 1 < sl.size():
			var nx: float = _case_rect(int(sl[k + 1])).get_center().x
			var skipped := int(sl[k + 1]) - int(sl[k]) > 1
			var xx := cx + 12.0
			while xx < nx - 12.0:
				var xe := minf(xx + (10.0 if skipped else 22.0), nx - 12.0)
				draw_line(Vector2(xx, y), Vector2(xe, y), Color(c_gold, 0.85), 3.0)
				xx += 18.0 if skipped else 22.0
			draw_polyline(PackedVector2Array([Vector2(nx - 22.0, y - 9.0), Vector2(nx - 10.0, y), Vector2(nx - 22.0, y + 9.0)]), c_gold, 3.0, true)

func _slot_met(s: int) -> bool:
	var i := tray[s]
	if i < 0:
		return false
	var sl := _setlist()
	var ids: Array = sl[0]
	var slots: Array = sl[1]
	var pi := slots.find(s)
	var d := collection[i]
	if d.cdr:
		return false
	var rule: Dictionary = d.rule
	var eff := String(rule.get("effect", "none"))
	if eff == "none":
		return false
	var prev: Disc = _ids_disc(ids, pi - 1)
	var nxt: Disc = _ids_disc(ids, pi + 1)
	if eff == "copy":
		var csrc := _copy_source(ids, pi)
		if csrc == null:
			return false
		rule = csrc.rule
	if String(rule.get("condition", "always")) == "per_before":
		var c := 0
		for j in pi:
			if _name_matches(collection[int(ids[j])], String(rule.get("cparam", ""))):
				c += 1
		return c > 0
	return _cond_count(rule, pi, ids, prev, nxt) > 0

func _cell_w(kind: String) -> float:
	return COL_W

func _draw_well(s: int) -> void:
	var cr := _case_rect(s)
	var c := cr.get_center()
	_panel(cr, Color("0d0f11"), 6, Color("2a2d33"), 2)
	var open := sel_slot == s and not resolving
	var done := resolving and s in done_slots and now_slot != s
	var lock_tag := ""
	if _boss_kind() == "slot" and int(venue["challenge"]["slot"]) == s:
		lock_tag = "ONLY %s or %s" % [String(D.GENRES[int(venue["challenge"]["genre"])]).to_upper(), D.ERAS[int(venue["challenge"]["era"])]]
	var i := tray[s]
	var occ := i >= 0
	if ch_door >= 0.02:
		pass
	elif open:
		if occ:
			_case_glow(cr, c_gold, 1.0)
		else:
			_panel(cr.grow(10.0), Color(0, 0, 0, 0), 14, c_gold, 5)
	elif sel_slot >= 0 and not resolving:
		if occ:
			_case_glow(cr, c_gold, 0.4 + 0.2 * sin(clock * 4.0))
		else:
			_panel(cr.grow(8.0), Color(0, 0, 0, 0), 14, Color(c_gold, 0.25 + 0.15 * sin(clock * 4.0)), 3)
	if slot_flash[s] > 0.0:
		if occ:
			_case_glow(cr, c_gold, slot_flash[s])
		else:
			_panel(cr.grow(6.0), Color(0, 0, 0, 0), 12, Color(c_gold, slot_flash[s]), 5)
	if i >= 0 and not _cell_hidden("tray", s):
		var d := collection[i]
		var dimv := 0.0
		if done and now_slot != s:
			dimv = 0.3
		var jr := cr
		if now_slot == s:
			var main: Color = _case_cols(d)[0]
			var glow := 0.6 + 0.4 * sin(clock * 6.0)
			_panel(cr.grow(10.0 + 6.0 * tray_punch[s]), Color(main.lightened(0.3), 0.18 * glow), 16)
			_panel(cr.grow(6.0), Color(0, 0, 0, 0), 12, Color(main.lightened(0.45), 0.85), 4)
			var sc := 1.0 + 0.15 * tray_punch[s]
			jr = Rect2(cr.get_center() - cr.size * sc * 0.5, cr.size * sc)
		_draw_jewel(jr, d, dimv)
		if _trays_live():
			_tip_disc(cr, d)
	if _tray_blocked(s):
		draw_rect(cr, Color(0.35, 0.05, 0.05, 0.55))
		_text_center(cr, "BLOCKED", T_MD, Color("ffb0a6"), true)
	if lock_tag != "":
		var lr0 := Rect2(cr.position.x, cr.position.y + 4.0, cr.size.x, 30.0)
		_panel(lr0, Color("7a1f1f"), 8, Color("ffb0a6"), 2)
		_text_center(lr0, lock_tag, 13, Color.WHITE, true)
	if i < 0 and _placed() >= _max_play() and not resolving and not _tray_blocked(s):
		_text_center(cr, "FULL", T_SM, Color(1, 1, 1, 0.22), true)
	var ro: Dictionary = readout[s]
	var rfl := float(ro.get("fl", 0.0))
	if not ro.is_empty() and (ro.has("net") or rfl > 0.001):
		var by := _jewel_bounds(cr).end.y + 10.0 + T_MD * 0.8
		var rcx := cr.get_center().x
		var net := int(ro.get("net", 0))
		var ptxt := ("+" if net >= 0 else "-") + _fmt_int(absi(net))
		var pcol := Color(D.SOUND_COLOR).lightened(0.25) if net >= 0 else c_bad.lightened(0.3)
		var pw := _heavy_w(ptxt, T_MD)
		var px := rcx - 12.0 - pw if rfl > 0.001 else rcx - pw * 0.5
		_readout_text(Vector2(px, by), ptxt, pcol)
		if rfl > 0.001:
			draw_circle(Vector2(rcx, by - T_MD * 0.32), 3.0, Color(1, 1, 1, 0.35))
			_readout_text(Vector2(rcx + 12.0, by), "+" + _ff(rfl), Color(D.FLOW_COLOR).lightened(0.2))
	if ui_live and not dig_mode and not resolving and not playing and _trays_live():
		_register(cr.grow(10.0), _on_slot.bind(s))

func _readout_text(pos: Vector2, text: String, col: Color) -> void:
	for k in 8:
		_heavy(pos + Vector2.from_angle(k * TAU / 8.0) * 2.0, text, T_MD, Color(0, 0, 0, 0.8))
	_heavy(pos, text, T_MD, col)

func _tape_poly(c: Vector2, rr: float, hw: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(8, int((a1 - a0) * rr / 6.0))
	var jit := 4.0 / rr
	for i in n + 1:
		pts.append(c + Vector2.from_angle(a0 + (a1 - a0) * i / n) * (rr + hw))
	for k in range(1, 5):
		pts.append(c + Vector2.from_angle(a1 + (jit if k % 2 == 1 else -jit)) * (rr + hw - 2.0 * hw * k / 5.0))
	for i in n + 1:
		pts.append(c + Vector2.from_angle(a1 - (a1 - a0) * i / n) * (rr - hw))
	for k in range(1, 5):
		pts.append(c + Vector2.from_angle(a0 + (jit if k % 2 == 1 else -jit)) * (rr - hw + 2.0 * hw * k / 5.0))
	return pts

func _band_text(c: Vector2, rad: float, d: Disc) -> void:
	if d.genre < 0:
		return
	var label := "%s-%s" % [D.ERAS[d.era], D.GENRES[d.genre]]
	var split := String(D.ERAS[d.era]).length()
	if label_title:
		label = d.title if d.title != "" else "Untitled"
	var f := _marker_font()
	var rr := rad * 0.62
	var fs := maxi(10, int(rad * 0.18))
	var adv: Array[float] = []
	var total := 0.0
	for i in label.length():
		adv.append(f.get_string_size(label.substr(i, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		total += adv[i]
	var max_arc := rr * deg_to_rad(140.0)
	if total > max_arc:
		fs = maxi(7 if label_title else 9, int(fs * maxf(0.4 if label_title else 0.6, max_arc / total)))
		total = 0.0
		for i in adv.size():
			adv[i] = f.get_string_size(label.substr(i, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			total += adv[i]
	var ctr := -PI * 0.5 + ((d.uid * 37) % 7 - 3) * 0.035
	var half := total / rr * 0.5 + 0.2
	var hw := fs * 0.95
	var tape := _tape_poly(c, rr, hw, ctr - half, ctr + half)
	var drop := PackedVector2Array()
	for q in tape:
		drop.append(q + Vector2(0.0, 2.0))
	draw_colored_polygon(drop, Color(0, 0, 0, 0.3))
	draw_colored_polygon(tape, Color("eadfbf", 0.96))
	draw_arc(c, rr + hw * 0.7, ctr - half + 0.05, ctr + half - 0.05, 32, Color(1, 1, 1, 0.35), 1.5, true)
	draw_arc(c, rr - hw * 0.7, ctr - half + 0.05, ctr + half - 0.05, 32, Color(0.5, 0.42, 0.25, 0.18), 1.5, true)
	var base_ink := Color("17171b")
	var pos := -total * 0.5
	for i in label.length():
		var ch := label.substr(i, 1)
		var th := ctr + (pos + adv[i] * 0.5) / rr
		pos += adv[i]
		if ch == " ":
			continue
		var ink := base_ink
		if label_title:
			pass
		elif i < split:
			ink = _ring_ink(true, d.era, base_ink)
		elif i > split:
			ink = _ring_ink(false, d.genre, base_ink)
		draw_set_transform(screen_origin + (c + Vector2.from_angle(th) * rr) * ui_scale, th + PI * 0.5, Vector2(ui_scale, ui_scale))
		var p := Vector2(-adv[i] * 0.5, fs * 0.35)
		draw_string(f, p + Vector2(0.7, 0.5), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(ink, 0.5))
		draw_string(f, p, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
	draw_set_transform(screen_origin, 0.0, Vector2(ui_scale, ui_scale))

func _ring_ink(is_era: bool, v: int, base: Color) -> Color:
	var r := _tag_ring_val(is_era, v)
	if r.a <= 0.0:
		return base
	if r == c_bad:
		return Color("a01820")
	if r == c_gold:
		return Color("8a5a00")
	return Color("1f6b3a")

func _disc_face(c: Vector2, rad: float, d: Disc, spin: float = 0.0) -> void:
	if d.cdr and d.genre < 0:
		_cd_art(c, rad, null, spin)
		return
	_cd_art(c, rad, _cover_tex(d.mix_cover if d.cdr else d.cover), spin)

func _short_name(n: String) -> String:
	var gi := D.GENRES.find(n)
	if gi >= 0:
		return String(D.GENRE_SHORT[gi])
	return n.to_upper()

func _cond_label(d: Disc) -> String:
	var r: Dictionary = d.rule
	var eff := String(r.get("effect", "none"))
	if eff == "none":
		return "NO EFFECT" if d.cdr or d.genre < 0 else _trait_label(d.genre)
	if eff == "copy":
		return "COPY PREV"
	var v := float(r.get("value", 0.0))
	var tgt := String(r.get("target", "self"))
	var tp := _short_name(String(r.get("tparam", "")))
	var p := _short_name(String(r.get("cparam", "")))
	var sg := ("+$" + _ff(v)) if eff == "cash" else (("+" + _ff(v)) if eff == "points" or eff == "flow_add" else ("x" + _ff(v)))
	if eff == "consumable":
		sg = "+TAPE"
	var part := sg
	if tgt == "turn":
		part = "NEXT TURN " + (("FLOW " + sg) if eff == "flow_add" or eff == "flow_mult" else sg)
	elif eff == "flow_add" or eff == "flow_mult":
		part = "FLOW " + sg
	elif tgt == "next":
		part = "NEXT " + sg
	elif tgt == "later":
		part = "LATER " + sg
	elif tgt == "later_genre" or tgt == "later_decade":
		part = "LATER %s %s" % [tp, sg]
	var cp := ""
	match String(r.get("condition", "always")):
		"first":
			cp = "FIRST"
		"last":
			cp = "LAST"
		"next_empty":
			cp = "NEXT EMPTY"
		"prev_empty":
			cp = "PREV EMPTY"
		"per_empty":
			return "%s PER EMPTY" % part
		"odd":
			cp = "ODD"
		"even":
			cp = "EVEN"
		"slot1", "slot2", "slot3", "slot4", "slot5", "slot6":
			cp = "SLOT " + String(r.get("condition", "")).substr(4)
		"prev_is":
			cp = "AFTER " + p
		"next_is":
			cp = "BEFORE " + p
		"per_before":
			return "%s PER %s" % [part, p]
		"per_hand":
			return "%s PER %s IN HAND" % [part, p]
	return part if cp == "" else cp + " " + part

func _enlist(d: Disc) -> void:
	if phase != "show":
		return
	var idx := collection.find(d)
	if idx >= 0 and not (idx in draw_pile) and not (idx in discard):
		draw_pile.insert(rng.randi_range(0, draw_pile.size()), idx)

func _stall_kind() -> String:
	var w := {"album": 28, "gear": 24, "tape": 24, "album_pack": 8, "gear_pack": 8, "tape_pack": 8}
	var tot := 0
	for k in w:
		tot += int(w[k])
	var roll := rng.randi_range(0, tot - 1)
	for k in w:
		roll -= int(w[k])
		if roll < 0:
			return String(k)
	return "album"

func _stall_offer(kind: String) -> Dictionary:
	match kind:
		"album_pack":
			var ap: Dictionary = D.ALBUM_PACKS[rng.randi_range(0, D.ALBUM_PACKS.size() - 1)]
			return {"kind": kind, "pack": ap, "price": int(ap["price"]), "sold": false}
		"gear_pack":
			var gp: Dictionary = D.GEAR_PACKS[rng.randi_range(0, D.GEAR_PACKS.size() - 1)]
			return {"kind": kind, "pack": gp, "price": int(gp["price"]), "sold": false}
		"tape_pack":
			return {"kind": kind, "price": D.TAPE_PACK_PRICE, "sold": false}
		"gear":
			var have: Array = []
			for it in stall:
				if not bool(it["sold"]) and it.has("gear"):
					have.append(String(it["gear"]["id"]))
			var ids := _random_gear_ids(1, have)
			if not ids.is_empty():
				var id := String(ids[0])
				return {"kind": kind, "gear": _make_gear(id), "price": int(gear_defs[id]["price"]), "sold": false}
		"tape":
			var held: Array = []
			for it in stall:
				if not bool(it["sold"]) and it.has("tape"):
					held.append(String(it["tape"]))
			var tid := _tape_roll("", held)
			return {"kind": kind, "tape": tid, "price": int(D.CONSUMABLES[tid]["price"]), "sold": false}
	var d := _make_disc(_random_albums(1)[0])
	return {"kind": "album", "disc": d, "price": _album_price(d), "sold": false}

func _stall_refresh() -> void:
	while stall.size() < 5:
		stall.append({"sold": true, "kind": "", "price": 0})
	var fresh: Array = []
	var has_gear := false
	var has_pack := false
	for i in 5:
		var it: Dictionary = stall[i]
		if bool(it["sold"]):
			fresh.append(i)
		else:
			if String(it["kind"]) == "gear":
				has_gear = true
			if String(it["kind"]).ends_with("_pack"):
				has_pack = true
	var kinds: Array = []
	for k in fresh.size():
		kinds.append(_stall_kind())
	if not kinds.is_empty():
		if not has_gear and not ("gear" in kinds):
			kinds[0] = "gear"
		var packs_in := false
		for k in kinds:
			if String(k).ends_with("_pack"):
				packs_in = true
		if not has_pack and not packs_in:
			var gears := 0
			for k in kinds:
				if String(k) == "gear":
					gears += 1
			for q in range(kinds.size() - 1, -1, -1):
				if String(kinds[q]) != "gear" or gears > 1:
					kinds[q] = ["album_pack", "gear_pack", "tape_pack"][rng.randi_range(0, 2)]
					break
	for j in fresh.size():
		stall[int(fresh[j])] = _stall_offer(String(kinds[j]))

func _stall_free_bay() -> bool:
	for i in D.RACK_SLOTS:
		if not _slot_taken(i):
			return true
	return false

func _stall_room(it: Dictionary) -> bool:
	match String(it["kind"]):
		"gear":
			return _can_fit(String(it["gear"]["id"]))
		"gear_pack":
			return _stall_free_bay()
		"tape", "tape_pack":
			return consumables.find("") >= 0
	return true

func _stall_ok(it: Dictionary) -> bool:
	return not bool(it["sold"]) and cash >= int(it["price"]) and _stall_room(it)

func _stall_buy(i: int) -> void:
	if i < 0 or i >= stall.size() or phase != "show" or resolving or playing:
		return
	var it: Dictionary = stall[i]
	if not _stall_ok(it) or not install_queue.is_empty() or not pack.is_empty():
		return
	cash -= int(it["price"])
	it["sold"] = true
	_sfx("page_turn")
	match String(it["kind"]):
		"album":
			var d: Disc = it["disc"]
			collection.append(d)
			_enlist(d)
			_say("%s added to your deck." % d.title)
		"album_pack":
			var ap: Dictionary = it["pack"]
			var items: Array = []
			for a in _random_albums(int(ap["show"])):
				items.append(_make_disc(a))
			pack = {"kind": "album", "title": ap["name"], "pick": int(ap["pick"]), "items": items}
			pack_sel.clear()
			_pack_start()
		"gear":
			install_queue = [it["gear"]]
			install_price = 0
			install_src = -1
			install_refund = -1
			install_stall = i
			_say("Pick a bay for the %s. Right-click to take it back." % gear_defs[(it["gear"] as Dictionary)["id"]]["name"])
		"gear_pack":
			var gp: Dictionary = it["pack"]
			var gitems: Array = []
			for id in _random_gear_ids(int(gp["show"])):
				gitems.append(_make_gear(id))
			if gitems.is_empty():
				cash += int(it["price"])
				it["sold"] = false
				_say("You already own every kind of gear.")
				return
			pack = {"kind": "gear", "title": gp["name"], "pick": mini(int(gp["pick"]), gitems.size()), "items": gitems}
			pack_sel.clear()
			_pack_start()
		"tape":
			_give_consumable(String(it["tape"]))
		"tape_pack":
			pack = {"kind": "tape", "title": "Tape Pack", "pick": 1, "items": _tape_choices(D.TAPE_PACK_SHOW, "")}
			pack_sel.clear()
			_pack_start()

func _close_stall() -> void:
	if not install_queue.is_empty() or not pack.is_empty():
		return
	shop_open = false
	# The first shop of a gig is shopped blind. The hand door opens only after the shop door
	# has fully closed (see _process), so the two doors move one after the other.
	if hand_hold:
		hand_after_shop = true
	sel_slot = -1
	_sfx("page_turn")

func _open_stall() -> void:
	if phase != "show" or resolving or playing or stall.is_empty():
		return
	shop_open = true
	sel_slot = -1
	_sfx("page_turn")

# Clicking something you can't buy: it shakes and a short "denied" buzz plays. No label is drawn
# over the item; an optional reason (e.g. no free bay) goes to the toast below the stage.
func _deny(key: String, why: String = "") -> void:
	shake_t[key] = 0.4
	_sfx("deny")
	if why != "":
		_say(why)

func _shake_off(key: String) -> Vector2:
	if not shake_t.has(key):
		return Vector2.ZERO
	var t := float(shake_t[key])
	return Vector2(sin(t * 70.0) * 12.0 * (t / 0.4), 0.0)

# A sold offer is replaced by a solid white card the exact size and position of the item it
# replaced (so its bottom edge lines up with the unsold items), with SOLD in red.
func _sold_card(r: Rect2) -> void:
	_shadow(r, 8, 6.0)
	_panel(r, Color("f7f4ec"), 8, Color(0, 0, 0, 0.35), 2)
	_panel(r.grow(-7.0), Color(0, 0, 0, 0), 5, Color(c_bad, 0.55), 2)
	_heavy_center(r, "SOLD", _fit_size("SOLD", T_XL, r.size.x - 40.0, 16), c_bad.darkened(0.1))

func _stall_rect(i: int) -> Rect2:
	return Rect2(_col_x(i), CHANGER_Y + 50.0, COL_W, COL_W * 0.886)

func _draw_stall() -> void:
	var dr := Rect2(730.0, CHANGER_Y + 10.0, 1756.0, CHANGER_H - 20.0)
	_panel(dr, Color("9a7a55"), 8)
	var hole := Color("3a2a1a")
	var gy := dr.position.y + 16.0
	while gy < dr.end.y - 8.0:
		var gx := dr.position.x + 16.0
		while gx < dr.end.x - 8.0:
			draw_circle(Vector2(gx, gy), 3.4, hole)
			draw_circle(Vector2(gx, gy - 1.0), 2.2, Color("20150b"))
			gx += 26.0
		gy += 26.0
	_grad_panel(Rect2(dr.position, Vector2(dr.size.x, 46.0)), 8.0, Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.0))
	_panel(dr, Color(0, 0, 0, 0), 8, Color(0, 0, 0, 0.55), 3)
	var live := ui_live and _shop_live() and install_queue.is_empty() and pack.is_empty()
	for i in mini(5, stall.size()):
		var it: Dictionary = stall[i]
		var cell := _stall_rect(i)
		if bool(it["sold"]):
			var full_cell := String(it["kind"]) in ["album", "album_pack", ""]
			_sold_card(cell if full_cell else Rect2(cell.position.x, cell.end.y - GEAR_H, COL_W, GEAR_H))
			continue
		var ok := _stall_ok(it)
		var hot := live and cell.has_point(mouse)
		var lift := Vector2(0.0, -8.0 if hot else 0.0) + _shake_off("stall%d" % i)
		var shown := cell
		match String(it["kind"]):
			"album":
				_draw_case(Rect2(cell.position + lift, cell.size), it["disc"])
				if live:
					_tip_disc(cell, it["disc"])
				_hang_tag(Vector2(cell.get_center().x, cell.end.y + 46.0), "$%d" % int(it["price"]))
			"album_pack":
				var ap: Dictionary = it["pack"]
				_draw_case_pack(Rect2(cell.position + lift, cell.size), ap, -1)
				_hang_tag(Vector2(cell.get_center().x, cell.end.y + 46.0), "$%d" % int(it["price"]))
				if live:
					_tip(cell, "%s: open it and pick %d of %d albums for your deck." % [ap["name"], int(ap["pick"]), int(ap["show"])])
			"gear":
				shown = Rect2(cell.position.x, cell.end.y - GEAR_H, COL_W, GEAR_H)
				_draw_gear(Rect2(shown.position + lift, shown.size), it["gear"], 0.0)
				_hang_tag(Vector2(shown.get_center().x, shown.end.y + 34.0), "$%d" % int(it["price"]))
			"gear_pack":
				shown = Rect2(cell.position.x, cell.end.y - GEAR_H, COL_W, GEAR_H)
				var gp: Dictionary = it["pack"]
				_gear_box(Rect2(shown.position + lift, shown.size), String(gp["name"]), "PICK %d OF %d" % [int(gp["pick"]), int(gp["show"])])
				if live:
					_tip(shown, "%s: open it and keep %d of %d pieces of gear." % [gp["name"], int(gp["pick"]), int(gp["show"])])
				_hang_tag(Vector2(shown.get_center().x, shown.end.y + 34.0), "$%d" % int(it["price"]))
			"tape":
				shown = Rect2(cell.position.x, cell.end.y - GEAR_H, COL_W, GEAR_H)
				_draw_cons_tile(Rect2(shown.position + lift, shown.size), String(it["tape"]), false, false)
				_hang_tag(Vector2(shown.get_center().x, shown.end.y + 34.0), "$%d" % int(it["price"]))
			"tape_pack":
				shown = Rect2(cell.position.x, cell.end.y - GEAR_H, COL_W, GEAR_H)
				_gear_box(Rect2(shown.position + lift, shown.size), "Tape Pack", "PICK 1 OF %d" % D.TAPE_PACK_SHOW)
				if live:
					_tip(shown, "Tape Pack: open it and keep 1 of %d cassettes." % D.TAPE_PACK_SHOW)
				_hang_tag(Vector2(shown.get_center().x, shown.end.y + 34.0), "$%d" % int(it["price"]))
		if not live:
			pass
		elif ok:
			_hold(cell, "stall%d" % i, "Hold to buy", _stall_buy.bind(i))
		else:
			var why := "" if cash < int(it["price"]) else ("No free cassette slot." if String(it["kind"]) in ["tape", "tape_pack"] else "No free bay in the rig.")
			_register(cell, _deny.bind("stall%d" % i, why))

func _cond_text(d: Disc, with_trait: bool = true) -> String:
	var r: Dictionary = d.rule
	var eff := String(r.get("effect", "none"))
	var tr := "" if d.cdr or d.genre < 0 or not with_trait else _trait_text(d.genre)
	if eff == "none":
		if not with_trait:
			return ""
		return tr if tr != "" else "No effect. It is just points."
	if eff == "copy":
		return "Repeats the effect of the song before it. If that song is also a copy, it repeats the effect it copied." + ("  " + tr if tr != "" else "")
	var v := _ff(float(r.get("value", 0.0)))
	var tp := String(r.get("tparam", ""))
	var p := String(r.get("cparam", ""))
	var lead := ""
	match String(r.get("condition", "always")):
		"first":
			lead = "If it is played first, "
		"last":
			lead = "If it is played last, "
		"next_empty":
			lead = "If the next slot is empty, "
		"prev_empty":
			lead = "If the previous slot is empty, "
		"per_empty":
			lead = "For each empty slot in the tray, "
		"odd":
			lead = "In an odd slot (1, 3), "
		"even":
			lead = "In an even slot (2, 4), "
		"slot1", "slot2", "slot3", "slot4", "slot5", "slot6":
			lead = "In slot %s, " % String(r.get("condition", "")).substr(4)
		"prev_is":
			lead = "If the song before it is %s, " % p
		"next_is":
			lead = "If the song after it is %s, " % p
		"per_before":
			lead = "For each %s song played before it, " % p
		"per_hand":
			lead = "For each %s song left in your hand, " % p
	var tgt := String(r.get("target", "self"))
	var amount := ("+%s points" % v) if eff == "points" else ("x%s" % v)
	var body := ""
	var later := tgt == "turn"
	match eff:
		"flow_add":
			body = ("next turn starts with %s more flow." % v) if later else ("your flow goes up by %s." % v)
		"flow_mult":
			body = ("next turn starts with your flow multiplied by %s." % v) if later else ("your flow is multiplied by %s." % v)
		"consumable":
			body = "you get a random consumable if a slot is free."
		"cash":
			body = ("you earn $%s at the start of next turn." % v) if later else ("you earn $%s." % v)
		_:
			match tgt:
				"turn":
					body = "next turn starts with %s." % amount
				"next":
					body = "the next song scores %s." % amount
				"later":
					body = "every later song scores %s." % amount
				"later_genre", "later_decade":
					body = "every later %s song scores %s." % [tp, amount]
				_:
					body = "this song scores %s." % amount
	var out := lead + body
	out = out.left(1).to_upper() + out.substr(1)
	return out + ("  " + tr if tr != "" else "")

func _name_matches(d: Disc, nm: String) -> bool:
	if d.genre < 0 or nm == "":
		return false
	var gi := D.GENRES.find(nm)
	if gi >= 0:
		return _in_genre(d, gi)
	var ei := D.ERAS.find(nm)
	return ei >= 0 and _era_near(d.era, ei)

func _cond_part(rule: Dictionary, count: int) -> String:
	var p := String(rule.get("cparam", ""))
	match String(rule.get("condition", "always")):
		"first":
			return "First"
		"last":
			return "Last"
		"next_empty":
			return "Gap after"
		"prev_empty":
			return "Gap before"
		"per_empty":
			return "Gaps (%d)" % count
		"odd":
			return "Odd slot"
		"even":
			return "Even slot"
		"slot1", "slot2", "slot3", "slot4", "slot5", "slot6":
			return "Slot " + String(rule.get("condition", "")).substr(4)
		"prev_is":
			return "After %s" % p
		"next_is":
			return "Before %s" % p
		"per_before":
			return "Fans (%d %s)" % [count, p]
		"per_hand":
			return "Hand (%d %s)" % [count, p]
	return ""

func _rule_line(rule: Dictionary, count: int, amt: float) -> String:
	var cp := _cond_part(rule, count)
	var eff := String(rule.get("effect", "none"))
	if eff == "consumable":
		return (cp + ": makes a consumable") if cp != "" else "Makes a consumable"
	var tgt := String(rule.get("target", "self"))
	var tp := String(rule.get("tparam", ""))
	var sg := ("+$" + _ff(amt)) if eff == "cash" else (("+" + _ff(amt)) if eff == "points" or eff == "flow_add" else ("x" + _ff(amt)))
	var body := ""
	if tgt == "turn":
		match eff:
			"points":
				body = "next turn %s points" % sg
			"cash":
				body = "next turn %s" % sg
			_:
				body = "next turn flow %s" % sg
		return (cp + ": " + body) if cp != "" else body.left(1).to_upper() + body.substr(1)
	if eff == "cash":
		return (cp + " " + sg) if cp != "" else sg
	if eff == "flow_add" or eff == "flow_mult":
		body = "flow %s" % sg
	elif tgt == "next":
		body = "next song " + sg
	elif tgt == "later":
		body = "later songs " + sg
	elif tgt == "later_genre" or tgt == "later_decade":
		body = "later %s songs %s" % [tp, sg]
	else:
		return (cp if cp != "" else "Bonus") + " " + sg
	return (cp + ": " + body) if cp != "" else body.left(1).to_upper() + body.substr(1)

func _era_near(e: int, v: int) -> bool:
	return e == v or (_bay_of("pitch") >= 0 and absi(e - v) <= 1)

func _disc_marks(c: Vector2, rad: float, d: Disc) -> void:
	if d.cdr and d.genre < 0:
		_heavy_center(Rect2(c.x - rad, c.y - rad * 0.62, rad * 2.0, rad * 0.4), "MIX", int(rad * 0.3), Color("2b5fa8"))
		_text_center(Rect2(c.x - rad, c.y + rad * 0.32, rad * 2.0, rad * 0.3), "CD-R", int(rad * 0.16), Color("5d626a"), true)
	else:
		_band_text(c, rad, d)
		var lab := "MIX" if d.cdr else _cond_label(d)
		var fs := maxi(10, int(rad * 0.17))
		while fs > 8 and _heavy_w(lab, fs) + rad * 0.3 > rad * 1.7:
			fs -= 1
		var pw := minf(_heavy_w(lab, fs) + rad * 0.3, rad * 1.7)
		var pr := Rect2(c.x - pw * 0.5, c.y + rad * 0.5, pw, fs * 1.7)
		_panel(Rect2(pr.position + Vector2(1.0, 2.0), pr.size), Color(0, 0, 0, 0.45), int(fs * 0.8))
		_panel(pr, Color("14181d"), int(fs * 0.8), Color(D.FLOW_COLOR).lightened(0.2), maxi(1, int(rad * 0.02)))
		_heavy_center(pr, lab, fs, Color.WHITE)
	var tc := c + Vector2(-rad * 0.72, -rad * 0.72)
	var sc := Color(D.SOUND_COLOR)
	draw_circle(tc + Vector2(0, 3), rad * 0.2, Color(0, 0, 0, 0.4))
	draw_circle(tc, rad * 0.2, sc.darkened(0.15))
	draw_arc(tc, rad * 0.2, 0.0, TAU, 32, Color(1, 1, 1, 0.75), 2.0, true)
	_heavy_center(Rect2(tc - Vector2(rad, rad) * 0.2, Vector2(rad, rad) * 0.4), str(d.sound), int(rad * (0.24 if d.sound < 10 else 0.19)), Color.WHITE)
	if d.edition != "":
		_edition_marks(c, rad, d.edition)

func _debuff_marks(c: Vector2, rad: float, d: Disc, soft: bool) -> void:
	if not soft:
		draw_circle(c, rad, Color(0.34, 0.35, 0.38, 0.62))
		draw_arc(c, rad, 0.0, TAU, 64, Color(c_bad, 0.6), 3.0, true)
	var bc := c + Vector2(-rad * 0.72, rad * 0.72)
	var br := rad * 0.2
	var u := br * 0.5
	draw_circle(bc + Vector2(0.0, 3.0), br, Color(0, 0, 0, 0.4))
	draw_circle(bc, br, Color("2a0f12"))
	draw_arc(bc, br, 0.0, TAU, 32, c_bad.lightened(0.25), maxf(1.5, br * 0.12), true)
	draw_colored_polygon(PackedVector2Array([bc + Vector2(-u * 0.95, -u * 0.55), bc + Vector2(u * 0.95, -u * 0.55), bc + Vector2(0.0, u * 0.8)]), c_bad.lightened(0.3))

func _draw_wallet() -> void:
	for p in D.HAND:
		var r := _pocket_rect(p)
		var c := r.grow(-8.0)
		var door_open := hand_t < 0.02
		var over := door_open and ui_live and r.has_point(mouse) and (wallet[p] >= 0 or sel_slot >= 0) and (dig_mode or not resolving)
		var i := wallet[p]
		if _cell_hidden("wallet", p):
			i = -1
		if i < 0:
			_panel(c, Color(0, 0, 0, 0), 10, Color(1, 1, 1, 0.12), 2)
		var marked := door_open and i >= 0 and ((dig_mode and p in dig_marks) or (burn_mode and p in burn_marks))
		var hovered := over and i >= 0 and not marked
		var jr := c
		if hovered:
			jr = Rect2(c.get_center() + Vector2(0.0, -HOVER_LIFT) - c.size * HOVER_SCALE * 0.5, c.size * HOVER_SCALE)
		var cb := _jewel_box(jr)
		if marked:
			_case_glow(cb, c_gold, 1.0)
		elif door_open and i >= 0 and (dig_mode or burn_mode or consume_mode != ""):
			_case_glow(cb, c_gold, 0.45 + 0.25 * sin(clock * 5.0))
		elif over and i < 0:
			_panel(c.grow(7.0), Color(c_gold, 0.1), 14, Color(c_gold, 0.8), 3)
		if door_open and not dig_offer.is_empty() and p == dig_slot:
			_case_glow(cb, c_gold, 0.6 + 0.3 * sin(clock * 5.0))
		if i >= 0:
			var d := collection[i]
			if hovered:
				_shadow(cb, 12, 16.0)
			_draw_jewel(jr, d)
			if hovered:
				_panel(cb, Color(1, 1, 1, HOVER_WASH), 6)
			if _hand_live():
				_tip_disc(r, d)
			if marked:
				draw_rect(cb, Color(0, 0, 0, 0.55))
				_heavy_center(cb, "DISCARD" if dig_mode else "BURN", T_XL, c_gold)
		if ui_live and _hand_live():
			_register(r, _on_pocket.bind(p))
	if resolving and phase == "show":
		_panel(Rect2(720.0, HAND_PLATE_Y, 1776.0, 280.0), Color(0, 0, 0, 0.45), 14)
		for hp in D.HAND:
			if hand_pulse[hp] > 0.02 and wallet[hp] >= 0 and hand_t < 0.02:
				var hc := _pocket_rect(hp).grow(-8.0)
				var hr := Rect2(hc.position + Vector2(0.0, -16.0 * hand_pulse[hp]), hc.size)
				_case_glow(_jewel_box(hr), c_gold, hand_pulse[hp])
				_draw_jewel(hr, collection[wallet[hp]])
	_draw_hand_door()
	_draw_bottom()

func _nav_bg(r: Rect2) -> void:
	_shadow(r, 8, 12.0)
	_surface(r, 8.0, "metal_dark", Color("2b2e33"), Color("1a1c20"))
	draw_line(r.position + Vector2(8.0, 2.0), Vector2(r.end.x - 8.0, r.position.y + 2.0), Color(1, 1, 1, 0.18), 2.0)
	_panel(r, Color(0, 0, 0, 0), 8, Color(0, 0, 0, 0.6), 2)

func _draw_cash() -> void:
	var lr := _cash_lcd()
	if cash_pulse > 0.0:
		_panel(lr.grow(4.0 + 12.0 * cash_pulse), Color(0.5, 0.88, 0.63, 0.5 * cash_pulse), 10)
	_lcd(lr, "$" + _fmt_int(cash), Color("7fe0a0"), int(_lcd_size(lr, 52) * (1.0 + 0.12 * cash_pulse)), "$88,888")

func _draw_actions() -> void:
	var r := r_actions
	_nav_bg(r)
	var x := r.position.x
	var y := r.position.y
	var black := Color("1a1c20")
	var ink := Color("c9ced6")
	_hw_button(Rect2(x + 436.0, y + 16.0, 337.0, 158.0), "PLAY" if not resolving else "PLAYING", _play, _can_play(), Color("3f9b5a"), T_XL)
	var red := Color("c23a2e")
	if dig_mode:
		var n := dig_marks.size()
		_hw_button(Rect2(x + 24.0, y + 16.0, 260.0, 84.0), "Discard" if n > 0 else "Pick", _confirm_dig, n > 0, red, T_LG)
		_hw_button(Rect2(x + 296.0, y + 16.0, 124.0, 84.0), "Cancel", _cancel, true, black, T_SM)
	else:
		var can := ui_live and phase == "show" and not resolving and dig_offer.is_empty() and digs > 0 and draw_pile.size() + discard.size() > 0
		_hw_button(Rect2(x + 24.0, y + 16.0, 388.0, 84.0), "Discard", _start_dig, can, red, T_LG)
		var lamps := maxi(opt_discards, digs)
		for k in lamps:
			_led(Vector2(x + 380.0 - (lamps - 1 - k) * 28.0, y + 58.0), 8.0, Color("ffb347"), 1.0 if k < digs else 0.0)
	var count := "%d / %d" % [mini(turn_n, D.TURNS), D.TURNS]
	_text_center(Rect2(x + 24.0, y + 112.0, 388.0, 40.0), count, T_LG, ink, true)
	_silk(Vector2(x + 218.0 - _text_w("TURN", 14, true) * 0.5, y + 170.0), "TURN", 14, Color("8d939b"))

func _draw_shop_nav() -> void:
	var enabled := ui_live and install_queue.is_empty() and bench < 0
	_hw_button(Rect2(60.0, 566.0, 360.0, 84.0), "Reroll  $%d" % _reroll_price(), _reroll, enabled and cash >= _reroll_price(), Color("a8861c"), T_MD)
	_hw_button(Rect2(60.0, 670.0, 360.0, 84.0), "View binder (%d)" % collection.size(), _toggle_binder, install_queue.is_empty(), Color("1a1c20"), T_MD)
	_hw_button(Rect2(60.0, 774.0, 360.0, 100.0), "Leave shop", _leave_shop, enabled, Color("3f9b5a"), T_XL)

func _draw_console_sorted() -> void:
	var r := Rect2(60.0, 1302.0, r_side.end.x - 60.0, 108.0)
	_shadow(r, 6, 8.0)
	_brushed(r, 6.0, Color("b4b9bf"), 53)
	draw_line(r.position + Vector2(6.0, 1.0), Vector2(r.end.x - 6.0, r.position.y + 1.0), Color(1, 1, 1, 0.35), 2.0)
	_panel(r, Color(0, 0, 0, 0), 6, Color(0, 0, 0, 0.45), 1)
	for ex in [r.position.x + 18.0, r.end.x - 18.0]:
		for ey in [r.position.y + 22.0, r.end.y - 22.0]:
			_screw(Vector2(ex, ey), 7.0)
	var ink := Color("23262b")
	var cy := r.position.y + 14.0
	var x := r.position.x + 44.0
	_hw_button(Rect2(x, cy + 8.0, 196.0, 72.0), "View binder (%d)" % collection.size(), _toggle_binder, phase == "show" and not dig_mode, Color("1a1c20"), T_SM)
	x += 224.0
	_draw_pile_table(Rect2(x, r.position.y, 560.0, r.size.y))
	x += 586.0
	_console_divider(r, x)
	x += 26.0
	_silk(Vector2(x, cy + 32.0), "SORT", T_SM, ink)
	_silk(Vector2(x, cy + 58.0), "HAND", 13, Color("3d4148"))
	var keys: Array = D.SORT_KEYS
	var x0 := x + 96.0
	var gap := 18.0
	var kw := (r.end.x - 44.0 - x0 - gap * (keys.size() - 1)) / keys.size()
	var live := ui_live and not dig_mode and phase == "show"
	for k in keys.size():
		_stereo_key(Rect2(x0 + k * (kw + gap), cy, kw, 72.0), String(D.SORT_TEXT[keys[k]]), sort_key == String(keys[k]), live, String(keys[k]))

func _draw_console() -> void:
	if D.SHOW_SORT:
		_draw_console_sorted()
		return
	var r := Rect2(879.0, 1170.0, 796.0, 190.0)
	_nav_bg(r)
	var x := r.position.x + 24.0
	_hw_button(Rect2(x, r.position.y + 16.0, 196.0, 158.0), "View binder (%d)" % collection.size(), _toggle_binder, phase == "show" and not dig_mode, Color("14161a"), T_SM)
	_draw_pile_table(Rect2(x + 232.0, r.position.y + 26.0, 516.0, r.size.y - 30.0))

func _stereo_key(r: Rect2, label: String, on: bool, live: bool, key: String) -> void:
	var hover := live and r.has_point(mouse)
	_panel(r.grow(5.0), Color("0d0e10"), 10)
	var down := 4.0 if on else 0.0
	var face := Rect2(r.position + Vector2(0.0, down), r.size - Vector2(0.0, down))
	var top := Color("d3d7dc") if not on else Color("9aa0a8")
	var bot := Color("8d939a") if not on else Color("686e76")
	if hover and not on:
		top = top.lightened(0.1)
		bot = bot.lightened(0.1)
	_grad_panel(face, 7.0, top, bot)
	draw_line(face.position + Vector2(7.0, 2.0), Vector2(face.end.x - 7.0, face.position.y + 2.0), Color(1, 1, 1, 0.7 if not on else 0.25), 2.0)
	_panel(face, Color(0, 0, 0, 0), 7, Color(0, 0, 0, 0.5), 1)
	_led(Vector2(face.position.x + 26.0, face.get_center().y), 7.0, Color("ffb347"), 1.0 if on else 0.0)
	_text_center(Rect2(face.position.x + 40.0, face.position.y, face.size.x - 40.0, face.size.y), label.to_upper(), T_SM, Color("23262b"), true)
	if live:
		_register(r, _set_sort.bind(key))

func _reward_rank(d: Disc) -> int:
	if d.cdr and d.genre < 0:
		return 8
	match String(d.rule.get("effect", "none")):
		"points":
			return 0
		"mult":
			return 1
		"flow_add":
			return 2
		"flow_mult":
			return 3
		"cash":
			return 4
		"copy":
			return 5
	return 6

func _console_divider(r: Rect2, x: float) -> void:
	draw_line(Vector2(x, r.position.y + 12.0), Vector2(x, r.end.y - 12.0), Color(0, 0, 0, 0.35), 2.0)
	draw_line(Vector2(x + 2.0, r.position.y + 12.0), Vector2(x + 2.0, r.end.y - 12.0), Color(1, 1, 1, 0.45), 1.0)

func _toggle_switch(c: Vector2, on: bool) -> void:
	draw_circle(c + Vector2(0.0, 2.0), 17.0, Color(0, 0, 0, 0.35))
	var hexp := PackedVector2Array()
	for i in 6:
		hexp.append(c + Vector2.from_angle(TAU * i / 6.0 + PI / 6.0) * 16.0)
	draw_colored_polygon(hexp, Color("8d939a"))
	draw_polyline(hexp + PackedVector2Array([hexp[0]]), Color(0, 0, 0, 0.45), 1.0, true)
	draw_circle(c, 11.0, Color("c3c8ce"))
	draw_circle(c, 7.0, Color("2a2c31"))
	var tip := c + Vector2(4.0, -20.0 if on else 20.0)
	draw_line(c + Vector2(2.0, 2.0), tip + Vector2(2.0, 2.0), Color(0, 0, 0, 0.3), 9.0, true)
	draw_line(c, tip, Color("b9bec4"), 8.0, true)
	draw_line(c + Vector2(-1.5, 0.0), tip + Vector2(-1.5, 0.0), Color(1, 1, 1, 0.6), 2.0, true)
	draw_circle(tip, 6.5, Color("d9dde2"))
	draw_circle(tip - Vector2(2.0, 2.0), 2.5, Color(1, 1, 1, 0.8))

func _score_color(v: float) -> Color:
	var t := float(_gig_target())
	if v < t * 0.5:
		return Color("ff6b5a")
	if v < t:
		return Color("f2c14e")
	return Color("7fe0a0")

func _tag_ring_val(is_era: bool, v: int) -> Color:
	var key := "era" if is_era else "genre"
	var name := String(D.ERAS[v]) if is_era else String(D.GENRES[v])
	if String(crowd_move.get("kind", "")) == "boo" and not bool(crowd_move.get("ignored", false)) and crowd_move["tag"] == [key, name]:
		return c_bad
	var bo := _boosts(key, v)
	if bo != 0:
		return c_gold if bo > 0 else c_bad
	return Color(0, 0, 0, 0)

func _boosts(key: String, v: int) -> int:
	var best := 0
	for g: Dictionary in rack:
		if g.is_empty() or bool(g.get("broken", false)):
			continue
		if g.has("levels") and ((key == "genre" and g["id"] == "genre_eq") or (key == "era" and g["id"] == "decade_eq")):
			var lv := int(g["levels"][v])
			if lv < 0:
				return -1
			if lv > 0:
				best = 1
	return best

func _draw_side() -> void:
	var r := r_side
	_shadow(r, 12, 10.0)
	_brushed(r, 12.0, Color("aab0b7"), 77)
	for p in [r.position + Vector2(20, 20), Vector2(r.end.x - 20, r.position.y + 20), Vector2(r.position.x + 20, r.end.y - 20), r.end - Vector2(20, 20)]:
		_screw(p, 7.0)
	var x := r.position.x + 36.0
	var w := r.size.x - 72.0
	_silk(Vector2(x, r.position.y + 64.0), "SORT WALLET", T_MD, Color("23262b"))
	var keys: Array = D.SORT_KEYS
	var bw := (w - 16.0) / 2.0
	for k in keys.size():
		var key := String(keys[k])
		var br := Rect2(x + (k % 2) * (bw + 16.0), r.position.y + 90.0 + (k / 2) * 84.0, bw, 64.0)
		var on := sort_key == key
		_hw_button(br, String(D.SORT_TEXT[key]), _set_sort.bind(key), ui_live and not dig_mode, Color("3f9b5a") if on else Color("3d4148"), T_MD)
		_led(Vector2(br.end.x - 18.0, br.position.y + 16.0), 4.0, Color("7fe0a0"), 1.0 if on else 0.0)
	var dy := r.position.y + 90.0 + ((keys.size() + 1) / 2) * 84.0 + 10.0
	draw_line(Vector2(x, dy), Vector2(x + w, dy), Color(0, 0, 0, 0.35), 2.0)
	draw_line(Vector2(x, dy + 2.0), Vector2(x + w, dy + 2.0), Color(1, 1, 1, 0.4), 1.0)
	_silk(Vector2(x, dy + 52.0), "DIG", T_MD, Color("23262b"))
	for k in D.DIGS:
		_led(Vector2(x + w - 10.0 - (D.DIGS - 1 - k) * 30.0, dy + 44.0), 7.0, Color("ffb347"), 1.0 if k < digs else 0.0)
	var left := draw_pile.size()
	var help := "Pick an album to discard." if dig_mode else ("Discard 1 wallet album, then pick 1 of %d from your binder (%d left)." % [D.DIG_OFFERS, left] if D.DIG_PICK else "Discard every album in your wallet and draw a fresh hand (%d left in the binder)." % left)
	_wrap(Vector2(x, dy + 70.0), help, w, T_SM, Color("2b2e33"))
	var by := r.end.y - 116.0
	if dig_mode:
		var n := dig_marks.size()
		_hw_button(Rect2(x, by, w * 0.55, 76.0), "Dig %d" % n if n > 0 else "Dig", _confirm_dig, n > 0, Color("c9a227"), T_LG)
		_hw_button(Rect2(x + w * 0.6, by, w * 0.4, 76.0), "Cancel", _cancel, true, Color("8a8f98"), T_MD)
	else:
		_hw_button(Rect2(x, by, w, 76.0), "Dig through the binder", _start_dig, digs > 0 and ui_live, Color("c9a227"), T_LG)

func _rack_idle() -> bool:
	return consume_mode == "" and not resolving and not playing and dig_offer.is_empty() and not dig_mode and not burn_mode and not peek_open and install_queue.is_empty() and bench < 0 and pack.is_empty() and not binder_open and (phase == "show" or phase == "shop")

func _gear_click(i: int) -> void:
	if not _rack_idle():
		return
	var a := _anchor(i)
	if rack[a].is_empty() or a == gear_sel:
		gear_sel = -1
		return
	gear_sel = a
	_sfx("click")

func _apply_swap(i: int) -> void:
	if consume_mode != "patch_bay":
		return
	var a := _anchor(i)
	if rack[a].is_empty():
		if swap_first < 0:
			return
		if _rack_try(swap_first, i):
			consumables[consume_slot] = ""
			consume_mode = ""
			consume_slot = -1
			_sfx("page_turn")
			_say("Moved the unit.")
		swap_first = -1
		return
	if swap_first < 0:
		swap_first = a
		comp_flash[a] = 1.0
		_sfx("click")
		_say("Now pick the unit to swap it with.")
		return
	if a == swap_first:
		swap_first = -1
		return
	if _rack_try(swap_first, a):
		consumables[consume_slot] = ""
		consume_mode = ""
		consume_slot = -1
		_sfx("page_turn")
		_say("Swapped the two units.")
	swap_first = -1

func _rack_try(fa: int, to_i: int) -> bool:
	var g: Dictionary = rack[fa]
	var ta := _anchor(to_i)
	if g.is_empty() or ta == fa:
		return false
	if _gear_full(g):
		var tb := (to_i / 2) * 2
		if tb == fa:
			return false
		var o1: Dictionary = rack[tb]
		var o2: Dictionary = rack[tb + 1]
		rack[fa] = {}
		rack[fa + 1] = {}
		rack[tb] = g
		rack[tb + 1] = {}
		if not o1.is_empty():
			rack[fa] = o1
		if not o2.is_empty():
			rack[fa + 1] = o2
		comp_flash[tb] = 1.0
	else:
		var occ: Dictionary = rack[ta]
		if not occ.is_empty() and _gear_full(occ):
			var partner := fa + 1 if fa % 2 == 0 else fa - 1
			if not rack[partner].is_empty():
				_say("The %s needs a free slot beside it to swap." % gear_defs[g["id"]]["name"])
				return false
			rack[fa] = {}
			rack[ta] = g
			rack[(fa / 2) * 2] = occ
		else:
			rack[fa] = {}
			rack[ta] = g
			if not occ.is_empty():
				rack[fa] = occ
		comp_flash[ta] = 1.0
	_resolve_clones()
	return true

func _can_sell_now() -> bool:
	return phase == "shop" or (phase == "show" and not resolving and not playing)

func _sell_gear(i: int) -> void:
	if not _can_sell_now() or not install_queue.is_empty() or bench >= 0 or rack[i].is_empty():
		return
	var g: Dictionary = rack[i]
	var id := String(g["id"])
	var got := maxi(1, int(gear_defs[id]["price"]) / 2)
	if id == "piggy":
		got += int(g.get("pot", 0))
	cash += got
	rack[i] = {}
	gear_sel = -1
	_sfx("page_turn")
	_say("Sold the %s for $%d." % [gear_defs[id]["name"], got])

func _can_use(g: Dictionary) -> bool:
	var m := _gear_m(String(g["id"]))
	if m <= 0 or int(g.get("used", 0)) >= m:
		return false
	return ui_live and phase == "show" and not resolving and not playing and dig_offer.is_empty() and not dig_mode and not peek_open and not binder_open and held < 0

func _use_gear(slot: int) -> void:
	var g: Dictionary = rack[slot]
	if g.is_empty() or not _can_use(g):
		return
	match String(g["id"]):
		"deep_library":
			if library_pending or discard_pending or not _hand_live():
				return
			_return_held()
			library_pending = true
			g["used"] = int(g["used"]) + 1
			comp_flash[slot] = 1.0
			_sfx("click")
		"sneak_peek":
			peek_ids.clear()
			for k in mini(int(_gp("sneak_peek", "count")), draw_pile.size()):
				peek_ids.append(draw_pile[draw_pile.size() - 1 - k])
			peek_open = true
			g["used"] = int(g["used"]) + 1
			comp_flash[slot] = 1.0
			_sfx("page_turn")
		"gate":
			if String(crowd_move.get("kind", "")) == "" or bool(crowd_move.get("ignored", false)):
				return
			crowd_move["ignored"] = true
			crowd_move["by"] = "The Noise Gate"
			crowd_move["gated"] = true
			if String(crowd_move["kind"]) == "block":
				blocked_slot = -1
			flow_live = float(_score_ctx()["fl"])
			g["used"] = int(g["used"]) + 1
			comp_flash[slot] = 1.0
			_sfx("page_turn")
			_say("%s %s" % [_move_title(), _move_desc()])

func _on_burn_pick(p: int) -> void:
	if wallet[p] < 0:
		return
	if p in burn_marks:
		burn_marks.erase(p)
		return
	burn_marks.append(p)
	if burn_marks.size() < 2:
		return
	var a: Disc = collection[wallet[burn_marks[0]]]
	var b: Disc = collection[wallet[burn_marks[1]]]
	var mix: Disc = a if a.cdr else (b if b.cdr else null)
	var src: Disc = b if mix == a else a
	if mix == null or src.cdr:
		_say("Pick one album and one Mix.")
		message_t = 60.0
		burn_marks.clear()
		return
	mix.title = src.title
	mix.band = src.band
	mix.cover = src.cover
	mix.genre = src.genre
	mix.era = src.era
	mix.label = src.label
	mix.sound = src.sound
	mix.rule = src.rule.duplicate()
	mix.edition = src.edition
	mix.cdr = false
	mix.mix_cover = ""
	for ci in rack.size():
		if not rack[ci].is_empty() and String(rack[ci]["id"]) == "cd_burner":
			rack[ci]["used"] = int(rack[ci]["used"]) + 1
			comp_flash[ci] = 1.0
	burn_mode = false
	burn_marks.clear()
	_sfx("page_turn")
	message_t = 0.0
	_say("Burned a copy of %s." % src.title)

func _close_peek() -> void:
	peek_open = false
	peek_ids.clear()

func _choice(r: Rect2, label: String, on: bool, cb: Callable) -> void:
	_hw_button(r, label, cb, true, Color("3f9b5a") if on else Color("5a5f67"), T_MD)

func _draw_settings() -> void:
	var r := _modal_panel(1200.0, 1100.0)
	_register(Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600)), func(): pass)
	_heavy_center(Rect2(r.position.x, r.position.y + 26.0, r.size.x, 70.0), "Settings", T_XL, c_ink)
	var x := r.position.x + 60.0
	var w := r.size.x - 120.0
	var y := r.position.y + 150.0
	_text(Vector2(x, y), "ANIMATION SPEED", 16, c_muted, true)
	var n: int = D.ANIM_NAMES.size()
	var bw := (w - 16.0 * (n - 1)) / n
	for i in n:
		_choice(Rect2(x + i * (bw + 16.0), y + 20.0, bw, 76.0), String(D.ANIM_NAMES[i]), anim_idx == i, _set_anim.bind(i))
	_text(Vector2(x, y + 134.0), "How fast the score sequence plays out.", T_SM, c_body, true)
	var y2 := y + 200.0
	_text(Vector2(x, y2), "DISCARDS PER GIG", 16, c_muted, true)
	for i in 3:
		_choice(Rect2(x + i * (bw + 16.0), y2 + 20.0, bw, 76.0), str(i + 1), opt_discards == i + 1, _set_discards.bind(i + 1))
	var y3 := y2 + 150.0
	_text(Vector2(x, y3), "STARTING CASH", 16, c_muted, true)
	var steps := [[-5, "-5"], [-1, "-1"], [1, "+1"], [5, "+5"]]
	_hw_button(Rect2(x, y3 + 20.0, 120.0, 76.0), "-5", _adj_cash.bind(-5), true, Color("5a5f67"), T_MD)
	_hw_button(Rect2(x + 136.0, y3 + 20.0, 120.0, 76.0), "-1", _adj_cash.bind(-1), true, Color("5a5f67"), T_MD)
	_heavy_center(Rect2(x + 272.0, y3 + 20.0, 240.0, 76.0), "$%d" % opt_cash, T_XL, c_ink)
	_hw_button(Rect2(x + 528.0, y3 + 20.0, 120.0, 76.0), "+1", _adj_cash.bind(1), true, Color("5a5f67"), T_MD)
	_hw_button(Rect2(x + 664.0, y3 + 20.0, 120.0, 76.0), "+5", _adj_cash.bind(5), true, Color("5a5f67"), T_MD)
	_text(Vector2(x, y3 + 134.0), "Discards and starting cash apply to your next run.", T_SM, c_body, true)
	var y4 := y3 + 190.0
	_text(Vector2(x, y4), "SOUND EFFECTS", 16, c_muted, true)
	_draw_vol_slider(Rect2(x + 14.0, y4 + 40.0, w - 150.0, 26.0), "sfx")
	var y5 := y4 + 120.0
	_text(Vector2(x, y5), "MUSIC", 16, c_muted, true)
	_draw_vol_slider(Rect2(x + 14.0, y5 + 40.0, w - 150.0, 26.0), "music")
	_hw_button(Rect2(r.get_center().x - 160.0, r.end.y - 110.0, 320.0, 80.0), "Close", _close_settings, true, Color("3f9b5a"), T_LG)

func _draw_peek() -> void:
	var r := _modal_panel(1300.0, 620.0)
	_register(Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600)), func(): pass)
	_heavy_center(Rect2(r.position.x, r.position.y + 30.0, r.size.x, 70.0), "Sneak Peek", T_XL, c_ink)
	_text_center(Rect2(r.position.x, r.position.y + 100.0, r.size.x, 36.0), ("The next %d songs in your binder, in the order you will draw them." % peek_ids.size()) if not peek_ids.is_empty() else "Your binder is empty.", T_MD, c_body, true)
	var n := maxi(1, peek_ids.size())
	var step := (r.size.x - 120.0) / n
	for k in peek_ids.size():
		var d: Disc = collection[peek_ids[k]]
		var c := Vector2(r.position.x + 60.0 + step * (k + 0.5), r.position.y + 270.0)
		var pw := minf(220.0, step - 24.0)
		_draw_jewel(Rect2(c - Vector2(pw, pw) * 0.5, Vector2(pw, pw)), d)
		_tip_disc(Rect2(c - Vector2(pw, pw * 0.886) * 0.5, Vector2(pw, pw * 0.886)), d)
		_text_center(Rect2(c.x - step * 0.5, c.y + 96.0, step, 30.0), "%d" % (k + 1), T_MD, c_muted, true)
	_hw_button(Rect2(r.get_center().x - 160.0, r.end.y - 110.0, 320.0, 80.0), "Close", _close_peek, true, Color("3f9b5a"), T_LG)

func _rack_unit(r: Rect2, title: String, sub: String, seed_n: int, flash: float, sub_w: float = 226.0, tx: float = 44.0) -> void:
	_shadow(r, 6, 6.0)
	_brushed(r, 6.0, Color("b4b9bf"), seed_n)
	for ex in [r.position.x + 18.0, r.end.x - 18.0]:
		for ey in [r.position.y + 24.0, r.end.y - 24.0]:
			_screw(Vector2(ex, ey), 7.0)
	var fs := T_MD
	while fs > 14 and _text_w(title.to_upper(), fs, true) > sub_w + 16.0:
		fs -= 1
	_silk(Vector2(r.position.x + tx, r.position.y + 44.0), title.to_upper(), fs, Color("23262b"))
	_wrap(Vector2(r.position.x + tx, r.position.y + 58.0), sub, sub_w, 17, Color("3d4148"))
	_led(Vector2(r.position.x + tx + 10.0, r.end.y - 34.0), 7.0, Color("ffb347"), flash)
	_silk(Vector2(r.position.x + tx + 28.0, r.end.y - 28.0), "ACTIVE", 12, Color("3d4148"))

func _bay_rect(k: int) -> Rect2:
	var by := 202.0
	if phase == "shop" or phase == "reward":
		by = lerpf(270.0, 90.0, clampf(pack_t / 0.5, 0.0, 1.0)) if not pack.is_empty() else 270.0
	return Rect2(_col_x(k), by, COL_W, GEAR_H)

func _slot_rect(i: int) -> Rect2:
	return _bay_rect(i)

func _unit_rect(i: int) -> Rect2:
	return _bay_rect(i)

func _draw_rack(show_cash: bool = true) -> void:
	if show_cash:
		_draw_cash()
		_draw_consumables()
	var installing := not install_queue.is_empty() and ui_live
	if installing:
		var rr := Rect2(_col_x(0) - 16.0, _bay_rect(0).position.y - 16.0, 6.0 * COL_W + 5.0 * COL_G + 32.0, GEAR_H + 32.0)
		_panel(rr, Color(c_gold, 0.06), 14, Color(c_gold, 0.6 + 0.3 * sin(clock * 5.0)), 4)
		var pend := String(gear_defs[(install_queue[0] as Dictionary)["id"]]["name"]).to_upper()
		_heavy_center(Rect2(rr.position.x, rr.position.y - 46.0, rr.size.x, 36.0), "CLICK A BAY TO PLACE THE %s" % pend, T_SM, c_gold)
	var idle := _rack_idle()
	var bk := _bench_kind()
	for i in rack.size():
		if rack[i].is_empty() and _slot_taken(i):
			continue
		var g: Dictionary = rack[i]
		var br := _unit_rect(i)
		if installing:
			if g.is_empty():
				_draw_empty_bay(br)
			else:
				_draw_gear(br, g, comp_flash[i], i)
			var inst: Dictionary = install_queue[0]
			var tr := _bay_rect(i / 2) if _gear_full(inst) else br
			var good := _install_anchor(inst, i) >= 0
			var hot := tr.has_point(mouse) and good
			if good:
				_panel(tr.grow(6.0), Color(c_gold, 0.12 if hot else 0.0), 10, Color(c_gold, 0.95 if hot else 0.45 + 0.25 * sin(clock * 5.0)), 5 if hot else 3)
			else:
				_panel(tr, Color(0, 0, 0, 0.45), 6)
			if hot:
				var occ: Dictionary = g if not g.is_empty() else (rack[(i / 2) * 2] if _gear_full(inst) else {})
				var label := "Install here" if occ.is_empty() else "Replace %s" % gear_defs[occ["id"]]["name"]
				var lw := _text_w(label, T_MD, true) + 40.0
				var lr := Rect2(tr.get_center().x - lw * 0.5, tr.get_center().y - 28.0, lw, 56.0)
				_panel(lr, Color(0.06, 0.07, 0.09, 0.92), 28)
				_text_center(lr, label, T_MD, c_gold, true)
			if install_price > 0:
				_hold(tr, "inst%d" % i, "Hold to buy", _install.bind(i))
			else:
				_register(tr, _install.bind(i))
			continue
		if idle and bk == "":
			_register(br, _gear_click.bind(i))
		if g.is_empty():
			_draw_empty_bay(br)
		else:
			var gb := br
			if gear_punch[i] > 0.0:
				var gsc := 1.0 + 0.15 * gear_punch[i]
				gb = Rect2(br.get_center() - br.size * gsc * 0.5, br.size * gsc)
				_panel(gb.grow(8.0), Color(_gear_color(String(g["id"])), 0.35 * gear_punch[i]), 14)
			_draw_gear(gb, g, comp_flash[i], i)
		if consume_mode == "patch_bay" and phase in ["show", "shop"] and (not g.is_empty() or swap_first >= 0):
			var sel := swap_first == i
			_panel(br.grow(6.0), Color(c_gold, 0.12 if sel else 0.0), 10, Color(c_gold, 1.0 if sel else 0.5 + 0.3 * sin(clock * 5.0)), 5 if sel else 4)
			if ui_live:
				_register(br, _apply_swap.bind(i))
		elif consume_mode != "" and phase in ["show", "shop"] and String(D.CONSUMABLES[consume_mode]["target"]) == "gear" and not g.is_empty():
			if _gear_can_level(g):
				_panel(br.grow(6.0), Color(0, 0, 0, 0), 10, Color(c_gold, 0.5 + 0.3 * sin(clock * 5.0)), 4)
				if ui_live:
					_register(br, _apply_consumable_gear.bind(i))
			else:
				_panel(br, Color(0, 0, 0, 0.5), 8)
		if gear_sel == i:
			_panel(br.grow(6.0), Color(c_gold, 0.1), 10, c_gold, 5)
		if bk == "tweak" and ui_live and phase == "shop" and not g.is_empty():
			var ok := g.has("levels")
			_panel(br.grow(6.0), Color(0, 0, 0, 0), 10, Color(c_gold, 0.45 + 0.25 * sin(clock * 5.0)) if ok else Color(0, 0, 0, 0), 3)
			if not ok:
				_panel(br, Color(0, 0, 0, 0.45), 6)

func _marker_w(s: String, size: int) -> float:
	return _marker_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _marker_fit(s: String, size: int, maxw: float) -> int:
	var w := _marker_w(s, size)
	return size if w <= maxw else maxi(10, int(floor(size * maxw / w)))

func _marker_l(x: float, y: float, s: String, size: int, col: Color, rot: float = 0.0) -> void:
	_marker(Vector2(x + _marker_w(s, size) * 0.5, y), s, size, col, rot)

func _marker_lines(s: String, size: int, maxw: float) -> Array:
	var lines: Array = []
	var cur := ""
	for word in s.split(" "):
		var t := word if cur == "" else cur + " " + word
		if cur != "" and _marker_w(t, size) > maxw:
			lines.append(cur)
			cur = word
		else:
			cur = t
	if cur != "":
		lines.append(cur)
	return lines

func _tag_names(tags: Array) -> String:
	var out: Array = []
	for t: Array in tags:
		out.append(String(t[1]))
	return ", ".join(out)

func _draw_paper(p: Rect2, tgt: int) -> void:
	_shadow(p, 2, 6.0)
	_panel(p, Color("f4efe4"), 6)
	draw_rect(Rect2(p.get_center().x - 50.0, p.position.y - 12.0, 100.0, 26.0), Color(1, 1, 1, 0.55))
	var ink := Color("15171b")
	var red := Color("c4161c")
	var left := p.position.x + 24.0
	var nm := String(venue.get("name", ""))
	_marker_l(left, p.position.y + 54.0, nm, _marker_fit(nm, 36, 360.0), ink)
	var big := _fmt_int(maxi(0, tgt - score_tot))
	var bsz := _marker_fit(big, 88, 230.0)
	_marker_l(p.end.x - 24.0 - _marker_w(big, bsz), p.position.y + 62.0, big, bsz, red)
	_marker_l(p.end.x - 24.0 - _marker_w("CROWD HP", 20), p.position.y + 100.0, "CROWD HP", 20, red.darkened(0.2))
	_marker_l(left, p.position.y + 104.0, "Turn %d of %d" % [mini(turn_n, D.TURNS), D.TURNS], 26, ink)

func _song_display(r: Rect2, text: String, moving: bool) -> void:
	_panel(r.grow(5.0), Color("0a0b0d"), 9)
	_grad_panel(r, 6.0, Color("dfe7d2"), Color("b9c6aa"))
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(6, 4), r.position + Vector2(r.size.x * 0.45, 4), r.position + Vector2(r.size.x * 0.3, r.size.y * 0.5), r.position + Vector2(6, r.size.y * 0.5)]), Color(1, 1, 1, 0.12))
	var ink := Color("1c2a1e")
	var size := 40
	var tw := _text_w(text, size, true)
	var pad := 22.0
	var yb := r.get_center().y + _vc(font_bold, size)
	if not moving:
		_text(Vector2(r.get_center().x - tw * 0.5, yb), text, size, Color(ink, 0.55), true)
		return
	var period := tw + 220.0
	var off := fmod(float(Time.get_ticks_msec()) * 0.001 * 110.0, period)
	var copies := int(ceil(r.size.x / period)) + 1
	var xs: Array = []
	for i in text.length():
		xs.append(_text_w(text.substr(0, i), size, true))
	for c in range(-copies, 2):
		var base := r.end.x - pad - off + c * period
		for i in text.length():
			var cx: float = base + float(xs[i])
			var cw := _text_w(text.substr(i, 1), size, true)
			var a := clampf((cx - (r.position.x + pad)) / 36.0, 0.0, 1.0) * clampf(((r.end.x - pad) - (cx + cw)) / 36.0, 0.0, 1.0)
			if a > 0.0:
				_text(Vector2(cx, yb), text.substr(i, 1), size, Color(ink, a), true)

func _draw_score_panel() -> void:
	var r := r_score
	_shadow(r, 16, 12.0)
	_surface(r, 16.0, "metal_dark", Color("2b2e33"), Color("1a1c20"))
	draw_line(r.position + Vector2(16.0, 2.0), Vector2(r.end.x - 16.0, r.position.y + 2.0), Color(1, 1, 1, 0.25), 2.0)
	_panel(r, Color(0, 0, 0, 0), 16, Color(0, 0, 0, 0.6), 2)
	for p in [r.position + Vector2(22, 22), Vector2(r.end.x - 22, r.position.y + 22), Vector2(r.position.x + 22, r.end.y - 22), r.end - Vector2(22, 22)]:
		_screw(p, 7.0)
	var x := r.position.x + 40.0
	var w := r.size.x - 80.0
	var y := r.position.y
	var shown := _fin_value() if fin_t >= 0.0 else score_tot
	var pts_v := turn_pts
	if fin_t >= 0.0:
		pts_v = int(round(float(turn_base) * (1.0 - (1.0 if fin_boomed else _fin_u()))))
	var tgt := _gig_target()
	var fc := _flow_heat(flow_roll)
	var pc := Color(D.SOUND_COLOR).lightened(0.25)
	var dim := Color("8d939b")
	_silk(Vector2(x, y + 430.0), "NOW PLAYING", 15, Color(1, 1, 1, 0.9))
	var cur := _playing_disc()
	var song := "READY"
	var moving := false
	if cur != null:
		song = "%s  -  %s" % [cur.title, cur.band]
		moving = true
	elif resolving:
		song = "SET COMPLETE"
	_song_display(Rect2(x, y + 442.0, w, 76.0), song, moving)
	_eq_strip(Rect2(x, y + 532.0, w, 62.0))
	var meter := Rect2(x, y + 260.0, w, 56.0)
	if shown > tgt:
		_panel(meter.grow(5.0 + 3.0 * sin(clock * 7.0)), Color(Color("ffd96a"), 0.25), 10)
	_inset(meter, 6.0, Color("0b0c0e"))
	var frac := clampf(float(shown) / float(tgt), 0.0, 1.0)
	var gfrac := 0.0
	var bars := 28
	var bw := (meter.size.x - 24.0) / bars
	for k in bars:
		var on := float(k) / bars < frac
		var ghost := not on and float(k) / bars < gfrac
		var col := _score_color(float(shown) if shown >= tgt else float(k) / bars * float(tgt))
		var br := Rect2(meter.position.x + 12.0 + k * bw, meter.position.y + 10.0, bw - 4.0, meter.size.y - 20.0)
		_panel(br, col if on else (Color(col, 0.38) if ghost else Color(col, 0.08)), 2)
	var sl := _score_lcd()
	_lcd(sl, _fmt_int(shown), _score_color(float(shown)), _lcd_size(sl, 96), "888,888", "center")
	_silk(Vector2(sl.position.x + 14.0, sl.position.y + 24.0), "SCORE", 13, Color(_score_color(float(shown)), 0.55))
	if SHOW_TOWER_LCDS:
		_draw_cd_player(Rect2(x + w - 280.0, y + 720.0, 280.0, 280.0))
		_hw_button(Rect2(x, y + 1022.0, 260.0, 64.0), "View binder", _toggle_binder, phase == "show" and not dig_mode, Color("14161a"), T_SM)
	else:
		var free_top := y + 594.0
		var free_bot := _cons_rect(0).position.y - 26.0
		var gy := free_top + (free_bot - free_top - (280.0 + 24.0 + 64.0)) * 0.5
		var tcx := r.get_center().x
		_draw_cd_player(Rect2(tcx - 140.0, gy, 280.0, 280.0))
		_hw_button(Rect2(tcx - 130.0, gy + 304.0, 260.0, 64.0), "View binder", _toggle_binder, phase == "show" and not dig_mode, Color("14161a"), T_SM)
	if SHOW_TOWER_LCDS:
		var pl := _pts_lcd()
		var fl := _flow_lcd()
		_silk(Vector2(pl.position.x, pl.position.y - 12.0), "POINTS", 14, dim)
		_silk(Vector2(fl.position.x, fl.position.y - 12.0), "FLOW", 14, dim)
		if pts_pulse > 0.0:
			_panel(pl.grow(4.0 + 12.0 * pts_pulse), Color(pc, 0.5 * pts_pulse), 14)
		if flow_pulse > 0.0:
			_panel(fl.grow(4.0 + 12.0 * flow_pulse), Color(fc, 0.5 * flow_pulse), 14)
		var lsz := _lcd_size(pl, 64)
		if flow_roll >= 4.0:
			_panel(fl.grow(10.0 + 4.0 * sin(clock * 8.0)), Color(fc, 0.22), 16)
		var pshow := pts_v if fin_t >= 0.0 else int(round(pts_roll))
		_lcd(pl, _fmt_int(pshow), pc, int(lsz * (1.0 + 0.1 * pts_pulse)), "888,888")
		_lcd(fl, _fmt_flow(flow_roll), fc, int(lsz * (1.0 + 0.1 * flow_pulse)), "88.88")
	if shown > tgt:
		var ok_txt := "OVERDRIVE +%d%%" % int(round((float(shown) / float(tgt) - 1.0) * 100.0))
		var okr := Rect2(meter.position.x, meter.end.y + 6.0, meter.size.x, 34.0)
		_text_center(okr, ok_txt, T_SM, Color("ffd96a").lerp(Color.WHITE, 0.3 + 0.3 * sin(clock * 6.0)), true)

func _focus_slot() -> int:
	if now_slot >= 0:
		return now_slot
	if sel_slot >= 0:
		return sel_slot
	for k in D.TRAYS:
		if _case_rect(k).grow(8.0).has_point(mouse):
			return k
	if resolving:
		return maxi(0, int(done_slots.back())) if not done_slots.is_empty() else 0
	var e := tray.find(-1)
	return e if e >= 0 else -1

func _info_chip(x: float, y: float, text: String, col: Color) -> float:
	var w := _text_w(text, 12, true) + 16.0
	var cr := Rect2(x, y, w, 30.0)
	_panel(cr, col, 9, Color(D.FLOW_COLOR).lightened(0.3), 2)
	_text_center(cr, text, 12, Color.WHITE, true)
	return w

func _draw_empty_bay(r: Rect2) -> void:
	_panel(r, Color(0, 0, 0, 0.28), 8, Color(1, 1, 1, 0.14), 2)
	_text_center(r, "EMPTY", T_MD, Color("6f747c"), true)

func _header_row(r: Rect2, title: String, desc: String, col: Color, stacked: bool) -> void:
	_panel(r, Color(0.07, 0.08, 0.1, 0.92), 8, Color(col, 0.55), 2)
	_panel(Rect2(r.position.x, r.position.y, 7.0, r.size.y), Color(col, 0.9), 3)
	if stacked:
		_heavy(Vector2(r.position.x + 22.0, r.position.y + 36.0), title, _fit_size(title, T_MD, r.size.x - 44.0, 16), col.lightened(0.35))
		_wrap(Vector2(r.position.x + 22.0, r.position.y + 46.0), desc, r.size.x - 40.0, T_SM, Color("e8ecf2"), true, 2)
	else:
		var tw := _heavy_w(title, T_XS) + 24.0
		var cr := Rect2(r.position.x + 12.0, r.position.y + 6.0, tw, r.size.y - 12.0)
		_panel(cr, Color(col, 0.85), 5)
		_heavy_center(cr, title, T_XS, Color.WHITE)
		var fsz := _fit_size(desc, T_SM, r.end.x - cr.end.x - 28.0, 12)
		_text(Vector2(cr.end.x + 14.0, r.get_center().y + _vc(font_bold, fsz)), desc, fsz, Color("e8ecf2"), true)

func _draw_gig_header() -> void:
	var r := Rect2(720.0, 40.0, 1513.0, 116.0)
	_panel(r, Color("1a1c20"), 10, Color("2a2d33"), 2)
	var head := bool(venue.get("headliner", false))
	var nm := String(venue.get("name", ""))
	_heavy(Vector2(r.position.x + 24.0, r.position.y + 50.0), nm, _fit_size(nm, T_LG, 290.0, 16), Color("f0f2f5"))
	var sub := "GIG %d OF %d  ·  TURN %d OF %d" % [gig_n, D.RUN_GIGS, mini(turn_n, D.TURNS), D.TURNS]
	_text(Vector2(r.position.x + 24.0, r.position.y + 78.0), sub, T_XS, Color("8d939b"), true)
	if phase != "show" or (crowd_move.is_empty() and not head):
		return
	var mx := r.position.x + 350.0
	var mw := r.end.x - 24.0 - mx
	var chip := c_good if bool(crowd_move.get("ignored", false)) else c_bad
	if head and crowd_move.is_empty():
		_header_row(Rect2(mx, r.position.y + 12.0, mw, 92.0), ("BOSS · " + _boss_title()).to_upper(), _boss_text(), c_bad, true)
	elif head:
		_header_row(Rect2(mx, r.position.y + 10.0, mw, 44.0), ("HEADLINER · " + _boss_title()).to_upper(), _boss_text(), c_bad, false)
		_header_row(Rect2(mx, r.position.y + 62.0, mw, 44.0), _move_title().to_upper(), _move_desc(), chip, false)
	else:
		_header_row(Rect2(mx, r.position.y + 12.0, mw, 92.0), _move_title().to_upper(), _move_desc(), chip, true)
	if move_flash > 0.0:
		# New boss ability: the row glows red and pulses three times, fading out.
		var row := Rect2(mx, r.position.y + 62.0, mw, 44.0) if head and not crowd_move.is_empty() else Rect2(mx, r.position.y + 12.0, mw, 92.0)
		var f := move_flash / D.MOVE_FLASH_SECS
		var pulse := 0.5 + 0.5 * cos((1.0 - f) * TAU * 3.0)
		_panel(row.grow(4.0 + 6.0 * pulse), Color(c_bad, 0.0), 10, Color(c_bad, f * (0.45 + 0.55 * pulse)), 3)
		_panel(row.grow(2.0), Color(c_bad, 0.22 * f * pulse), 8)

# Start of a boss gig: a red edge vignette (the usual "danger" cue - edges only, so the board
# stays readable) that pulses, plus an "Incoming Boss" banner. Both ease in, hold, then fade.
func _draw_boss_intro() -> void:
	if boss_intro_t <= 0.0:
		return
	var el := D.BOSS_INTRO_SECS - boss_intro_t
	var a := minf(1.0, el / 0.25) * minf(1.0, boss_intro_t / 0.6)
	if vignette_tex == null:
		var gr := Gradient.new()
		gr.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		gr.colors = PackedColorArray([Color(0.75, 0.05, 0.03, 0.0), Color(0.75, 0.05, 0.03, 0.0), Color(0.75, 0.05, 0.03, 0.8)])
		vignette_tex = GradientTexture2D.new()
		vignette_tex.gradient = gr
		vignette_tex.fill = GradientTexture2D.FILL_RADIAL
		vignette_tex.fill_from = Vector2(0.5, 0.5)
		vignette_tex.fill_to = Vector2(1.0, 0.5) # radius reaches the side edges; corners clamp to full red
		vignette_tex.width = 256
		vignette_tex.height = 256
	var pulse := 0.8 + 0.2 * sin(el * TAU * 1.4)
	# Cover the whole window (including any letterbox margin), not just the UI area.
	var vis := Rect2(-screen_origin / maxf(ui_scale, 0.0001), window_size / maxf(ui_scale, 0.0001))
	draw_texture_rect(vignette_tex, vis, false, Color(1, 1, 1, a * pulse))
	var mid := Vector2(1608.0, UI_H * 0.42)
	var bname := _boss_title()
	var nfs := _fit_size(bname, T_HERO + 20, UI_W * 0.7, 40) if bname != "" else T_HERO
	var nw := _heavy_w(bname, nfs)
	var pop := 1.0 + 0.15 * maxf(0.0, 1.0 - el / 0.3)
	var bw := maxf(nw, 640.0) * pop + 120.0
	var bh := (nfs + 110.0) * pop
	var box := Rect2(mid.x - bw * 0.5, mid.y - bh * 0.5, bw, bh)
	_panel(Rect2(box.position + Vector2(0.0, 10.0), box.size), Color(0, 0, 0, 0.45 * a), 22)
	_panel(box, Color(0.07, 0.03, 0.03, 0.92 * a), 22, Color(c_bad, a), 4)
	_text_center(Rect2(box.position.x, box.position.y + 18.0, box.size.x, 40.0), "INCOMING BOSS:", T_LG, Color(c_bad.lightened(0.25), a), true)
	if bname != "":
		var nr := Rect2(box.position.x, box.position.y + 58.0, box.size.x, nfs * 1.2 * pop)
		_heavy_center(Rect2(nr.position + Vector2(0.0, 4.0), nr.size), bname, int(nfs * pop), Color(0, 0, 0, 0.6 * a))
		_heavy_center(nr, bname, int(nfs * pop), Color(1.0, 0.95, 0.9, a))

func _draw_banner() -> void:
	return

func _gear_color(id: String) -> Color:
	var rl: Dictionary = gear_defs[id].get("rule", {})
	match String(rl.get("effect", "")):
		"points", "mult":
			return Color(D.SOUND_COLOR)
		"flow", "flow_mult":
			return Color(D.FLOW_COLOR)
		"cash":
			return Color(D.HYPE_COLOR)
		"upgrade", "echo", "refire":
			return Color(D.ENERGY_COLOR)
		"block":
			return Color("9fb4c8")
		"consumable":
			return Color("5fd4c3")
	match id:
		"piggy", "royalty_check":
			return Color(D.HYPE_COLOR)
		"tuner", "clone":
			return Color(D.ENERGY_COLOR)
		"gate":
			return Color("9fb4c8")
	return Color("c9ced6")

# Every genre a gear's rule depends on: the genre it applies to (aparam) and any genre
# named by its condition or per-count (rparam). In rule order, no repeats.
func _gear_genres(id: String) -> Array[int]:
	var out: Array[int] = []
	var rl: Dictionary = gear_defs[id].get("rule", {})
	for key in ["aparam", "rparam"]:
		var gi := D.GENRES.find(String(rl.get(key, "")))
		if gi >= 0 and not gi in out:
			out.append(gi)
	return out

# Live value shown on a gear's LCD, or "" for gear whose number can't change.
# Folds in level (+50% per level, as _rule_song does), stored growth and any count that is
# known right now. Counts that depend on the song being played show the per-unit value + " EA".
func _gear_readout(g: Dictionary, slot: int) -> String:
	var id := String(g["id"])
	var def: Dictionary = gear_defs[id]
	if id == "piggy":
		return "+$%d" % int(g.get("pot", 0))
	if id == "royalty_check":
		return "+$%d" % _royalty(g)
	var r: Dictionary = def.get("rule", {})
	var effect := String(r.get("effect", ""))
	if not effect in ["points", "mult", "flow", "flow_mult", "cash", "upgrade"]:
		return ""
	var per := String(r.get("per", "none"))
	if not bool(def.get("levels", false)) and per == "none" and String(r.get("grow", "")) == "":
		return ""
	var m := 1.0 + 0.5 * float(int(g.get("level", 0)))
	var amt := float(r.get("amount", 0.0))
	if effect == "mult":
		return "x" + _ff(1.0 + (amt - 1.0) * m)
	if effect == "flow_mult":
		return "FLOW x" + _ff(1.0 + (amt - 1.0) * m)
	var count := -1
	match per:
		"none":
			count = 1
		"stored":
			count = int(g.get("count", 0))
		"hand_of_genre":
			if phase == "show":
				var hgi := D.GENRES.find(String(r.get("rparam", "")))
				count = 0
				for hw in wallet:
					if hw >= 0 and collection[hw].genre == hgi:
						count += 1
		"unused_discards":
			if phase == "show":
				count = maxi(0, digs)
		"empty_slots":
			if phase == "show":
				var placed := 0
				for ti in tray:
					if ti >= 0:
						placed += 1
				count = maxi(0, D.SETLIST - placed)
		"units_left":
			var gm := _gear_map()
			if slot >= 0 and gm.has(slot):
				count = int(gm[slot]["left"])
	var cap := int(r.get("cap", 0))
	if cap > 0 and count > cap:
		count = cap
	var each := count < 0
	var v := amt * m * (1.0 if each else float(count))
	# Totals round like the scoring code; a per-unit value keeps its fraction (e.g. +$1.5 EA).
	var n := _ff(v) if each else str(int(round(v)))
	var s := ""
	match effect:
		"points":
			s = "+" + n
		"flow":
			s = "+%s FLOW" % _ff(v)
		"cash":
			s = "+$" + n
		"upgrade":
			s = "+%s BASE" % n
	return s + (" EA" if each else "")

# Every decade a gear's rule wants: the decade it applies to (aparam when applies == "decade")
# and the decade it grows on (gparam when grow == "decade").
func _gear_decades(id: String) -> Array[int]:
	var out: Array[int] = []
	var rl: Dictionary = gear_defs[id].get("rule", {})
	var cands: Array = []
	if String(rl.get("applies", "")) == "decade":
		cands.append(String(rl.get("aparam", "")))
	if String(rl.get("grow", "")) == "decade":
		cands.append(String(rl.get("gparam", "")))
	for c in cands:
		var ei := D.ERAS.find(String(c))
		if ei >= 0 and not ei in out:
			out.append(ei)
	return out

func _royalty(g: Dictionary) -> int:
	var id := String(g["id"])
	return mini(cash / maxi(1, int(_gp(id, "per"))), int(_gp(id, "cap")))

func _gear_genre_color(id: String) -> Color:
	var gis := _gear_genres(id)
	if gis.is_empty():
		return Color(0, 0, 0, 0)
	return Color(D.SLEEVE_MAIN[gis[0]]).lightened(0.2)

func _gear_lit(g: Dictionary, slot: int) -> bool:
	if phase != "show" or slot < 0:
		return true
	if _gear_act(String(g["id"])) in ["song", "gig", "discard"]:
		return _tray_on(slot) and not _tray_blocked(slot)
	return true

func _tip_gear(r: Rect2, g: Dictionary) -> void:
	if ui_live and r.has_point(mouse):
		hover_gear = g

func _pedal_knob(c: Vector2, rad: float, ang: float, cap: Color, lit: bool) -> void:
	draw_circle(c + Vector2(0.0, rad * 0.16), rad * 1.05, Color(0, 0, 0, 0.45))
	draw_circle(c, rad, Color("101114") if lit else Color("17181b"))
	var cc := cap if lit else cap.darkened(0.55)
	draw_circle(c, rad * 0.8, cc.darkened(0.25))
	draw_circle(c + Vector2(0.0, -rad * 0.04), rad * 0.72, cc)
	draw_arc(c, rad * 0.72, PI * 1.05, PI * 1.95, 20, Color(1, 1, 1, 0.38 if lit else 0.15), maxf(1.5, rad * 0.12), true)
	var pd := Vector2.from_angle(ang)
	draw_line(c + pd * rad * 0.18, c + pd * rad * 0.68, Color("14161a"), maxf(2.0, rad * 0.16), true)

func _draw_gear(r: Rect2, g: Dictionary, flash: float, slot: int = -1) -> void:
	var def: Dictionary = gear_defs[g["id"]]
	var id := String(g["id"])
	var lit := _gear_lit(g, slot)
	var ecol := _gear_color(id)
	var gcol := _gear_genre_color(id)
	var u := r.size.y / 155.0
	var sell_on := _can_sell_now() and slot >= 0 and slot == gear_sel and install_queue.is_empty() and bench < 0 and ui_live and pack.is_empty()
	_shadow(r, int(10.0 * u), 8.0 * u)
	var body_top := Color("30343a").lerp(ecol, 0.1) if lit else Color("25272b")
	var body_bot := Color("1b1d21").lerp(ecol, 0.06) if lit else Color("17181b")
	_grad_panel(r, 10.0 * u, body_top, body_bot)
	draw_line(Vector2(r.position.x + 10.0 * u, r.position.y + 1.5), Vector2(r.end.x - 10.0 * u, r.position.y + 1.5), Color(1, 1, 1, 0.22), 2.0)
	_panel(r, Color(0, 0, 0, 0), int(10.0 * u), Color(0, 0, 0, 0.7), 2)
	var hv := int(absi(hash(id)))
	var kcap := Color("c3c8ce")
	if gcol.a > 0.0:
		kcap = gcol
	var readout := _gear_readout(g, slot)
	if readout != "":
		# Gear with a changing number shows it on an LCD in place of the knob row.
		var lr := Rect2(r.get_center().x - 80.0 * u, r.position.y + 15.0 * u, 160.0 * u, 30.0 * u)
		var lcol := ecol if lit else ecol.lerp(Color("6a6f77"), 0.6)
		var lfs := int(20.0 * u)
		while lfs > 9 and _text_w(readout, lfs, true) > lr.size.x - 20.0 * u:
			lfs -= 1
		_lcd(lr, readout, lcol, lfs, "", "center")
	else:
		for k in 3:
			var kc := Vector2(r.get_center().x + (k - 1) * 58.0 * u, r.position.y + 30.0 * u)
			_pedal_knob(kc, 15.0 * u, deg_to_rad(135.0 + float((hv >> (k * 4)) % 16) * 18.0), kcap, lit)
	var plate := Rect2(r.position.x + 14.0 * u, r.position.y + 55.0 * u, r.size.x - 28.0 * u, 58.0 * u)
	var pcol := ecol.darkened(0.22) if lit else Color("575c64")
	_brushed(plate, 4.0 * u, pcol, hv % 90)
	for sx in [plate.position.x + 9.0 * u, plate.end.x - 9.0 * u]:
		draw_circle(Vector2(sx, plate.get_center().y), 3.2 * u, Color(0, 0, 0, 0.45))
		draw_circle(Vector2(sx, plate.get_center().y - 0.6 * u), 2.4 * u, Color(1, 1, 1, 0.5))
	# Badges for every genre and decade the unit's rule wants: genre icons in their colour,
	# decade icons in dark ink (the same look as the CD stickers).
	var badges: Array = []
	for gi in _gear_genres(id):
		badges.append(["g%d" % gi, Color(D.SLEEVE_MAIN[gi])])
	for ei in _gear_decades(id):
		badges.append(["e%d" % ei, Color("2b2e33")])
	var badge_r := 15.0 * u
	var text_x := plate.position.x
	if not badges.is_empty():
		var bx := plate.position.x + 20.0 * u + badge_r
		for bd in badges:
			var bc := Vector2(bx, plate.get_center().y)
			var gc: Color = bd[1] if lit else (bd[1] as Color).lerp(Color("6a6f77"), 0.6)
			_aa_circle(bc + Vector2(0.0, 1.5 * u), badge_r, Color(0, 0, 0, 0.35))
			_aa_circle(bc, badge_r, Color.WHITE if lit else Color("c3c8ce"))
			_icon(String(bd[0]), bc, badge_r * 1.15, gc)
			bx += badge_r * 2.0 + 4.0 * u
		text_x = bx - badge_r
	var text_w := plate.end.x - text_x
	var nm := String(def["name"]).to_upper()
	var maxw := text_w - 36.0 * u
	var lines: Array[String] = [nm]
	var words := nm.split(" ")
	var start_fs := int(24.0 * u)
	if words.size() >= 2 and _text_w(nm, start_fs, true) > maxw:
		var l1 := String(words[0])
		var half := nm.length() / 2.0
		for k in range(1, words.size() - 1):
			if absf(float((l1 + " " + words[k]).length()) - half) < absf(float(l1.length()) - half):
				l1 += " " + words[k]
			else:
				break
		lines = [l1, nm.substr(l1.length() + 1)]
		start_fs = int(20.0 * u)
	var fs := start_fs
	for ln in lines:
		while fs > 11 and _text_w(ln, fs, true) > maxw:
			fs -= 1
	var ink := Color("15171a") if pcol.get_luminance() > 0.42 else Color("f4f6f8")
	if not lit:
		ink = Color("9aa0a8")
	var cy := plate.get_center().y
	for k in lines.size():
		_text_center(Rect2(text_x, cy + (k - (lines.size() - 1) * 0.5) * fs * 1.15 - fs * 0.6, text_w, fs * 1.2), lines[k], fs, ink, true)
	if slot >= 0 and phase == "shop":
		_text(Vector2(r.position.x + 12.0 * u, r.position.y + 28.0 * u), str(slot + 1), T_XS, Color("c9ced6", 0.7), true)
	var lvl_i := int(g.get("level", 0))
	if lvl_i > 0:
		var lvt := String(D.LEVEL_NAMES[lvl_i])
		var lw := _text_w(lvt, T_XS, true) + 14.0 * u
		var lr := Rect2(plate.end.x - lw - 4.0 * u, plate.position.y - 10.0 * u, lw, 19.0 * u)
		_panel(lr, c_gold, int(9.0 * u), Color(0, 0, 0, 0.5), 1)
		_text_center(lr, lvt, T_XS, Color("2a2208"), true)
	var led_on := maxf(1.0 if lit and slot >= 0 and phase == "show" else 0.0, flash)
	_led(Vector2(r.end.x - 24.0 * u, r.position.y + 24.0 * u), 6.0 * u, ecol, led_on)
	var pw := 104.0 * u if sell_on else 132.0 * u
	var px := r.position.x + 16.0 * u if sell_on else r.get_center().x - pw * 0.5
	var pad := Rect2(px, r.position.y + 121.0 * u, pw, 24.0 * u)
	var can_use := bool(def.get("active", false)) and slot >= 0 and phase == "show" and _can_use(g)
	_panel(pad.grow(3.0 * u), Color("8b9199") if lit else Color("4a4e55"), int(8.0 * u))
	_grad_panel(pad, 6.0 * u, Color("45484e"), Color("232528"))
	for k in 4:
		var ly := pad.position.y + pad.size.y * (0.22 + k * 0.19)
		draw_line(Vector2(pad.position.x + 8.0 * u, ly), Vector2(pad.end.x - 8.0 * u, ly), Color(0, 0, 0, 0.35), 1.5 * u)
		draw_line(Vector2(pad.position.x + 8.0 * u, ly + 1.5 * u), Vector2(pad.end.x - 8.0 * u, ly + 1.5 * u), Color(1, 1, 1, 0.08), 1.0)
	if can_use:
		var hot := pad.grow(8.0 * u).has_point(mouse)
		_panel(pad.grow(3.0 * u), Color(0, 0, 0, 0), int(8.0 * u), c_gold if hot else Color(ecol, 0.8), 3)
		_register(pad.grow(10.0 * u), _use_gear.bind(slot))
	if flash > 0.0:
		_panel(r, Color(c_gold, 0.35 * flash), 8)
	if phase == "show" and slot >= 0 and _tray_blocked(slot):
		draw_rect(r, Color(0.35, 0.05, 0.05, 0.6))
		var hh := r.size.y
		var sx := r.position.x - hh
		while sx < r.end.x:
			var t0 := maxf(0.0, (r.position.x - sx) / hh)
			var t1 := minf(1.0, (r.end.x - sx) / hh)
			if t0 < t1:
				draw_line(Vector2(sx + t0 * hh, r.end.y - t0 * hh), Vector2(sx + t1 * hh, r.end.y - t1 * hh), Color(1, 0.4, 0.35, 0.28), 8.0)
			sx += 40.0
	if sell_on:
		var worth := maxi(1, int(def["price"]) / 2)
		if id == "piggy":
			worth += int(g.get("pot", 0))
		_hw_button(Rect2(r.end.x - 126.0 * u, r.position.y + 117.0 * u, 110.0 * u, 32.0 * u), "SELL $%d" % worth, _sell_gear.bind(slot), true, Color("4a4f57"), T_XS)
	if bool(g.get("broken", false)):
		_panel(r, Color(0, 0, 0, 0.6), 6)
		_heavy_center(r, "BROKEN", T_XL, c_bad.lightened(0.2))
	if not gear_tip_off:
		_tip_gear(r, g)

func _draw_gear_tip(g: Dictionary) -> void:
	var def: Dictionary = gear_defs[g["id"]]
	var w := 560.0
	var pad := 24.0
	var iw := w - pad * 2.0
	var act := _gear_act(String(g["id"]))
	var acts := {"song": "Works when its tray holds a CD.", "anywhere": "Works anywhere. It needs no tray.", "gig": "Works the first time its tray is played each gig.", "round_end": "Works at the end of each round. It needs no tray.", "button": "Click its footswitch at any time.", "placed": "Works as soon as it is placed in the rig.", "discard": "Works when you discard, if its tray holds a CD."}
	var body := _gear_text(g)
	var st := _gear_status(g, -1)
	var bh := _rich_h(body, iw, T_SM)
	var ah := _rich_h(String(acts.get(act, "")), iw, T_SM)
	var lv_text := "Cannot be leveled up."
	if bool(def.get("levels", false)):
		lv_text = "Level: MK I. A Tune-Up makes it stronger." if int(g.get("level", 0)) == 0 else "Level: %s. Each level adds 50%% to its numbers." % D.LEVEL_NAMES[int(g["level"])]
	var gchips: Array = []
	for gi in _gear_genres(String(g["id"])):
		gchips.append([String(D.GENRES[gi]).to_upper(), Color("5d626a"), "g%d" % gi])
	for ei in _gear_decades(String(g["id"])):
		gchips.append(["", Color("5d626a"), "e%d" % ei])
	var h := pad + 84.0 + (44.0 if not gchips.is_empty() else 0.0) + 52.0 + bh + 10.0 + 52.0 + ah + 10.0 + 52.0 + 30.0 + (46.0 if st != "" else 0.0) + pad - 6.0
	var box := Rect2(mouse + Vector2(28.0, 28.0), Vector2(w, h))
	if box.end.x > UI_W - 12.0:
		box.position.x = mouse.x - w - 20.0
	if box.end.y > UI_H - 12.0:
		box.position.y = maxf(12.0, UI_H - 12.0 - h)
	_tip_frame(box, _gear_rarity(String(g["id"])))
	var x := box.position.x + pad
	var y := box.position.y + pad
	_rich_heavy(Vector2(x, y + 30.0), String(def["name"]), T_LG, Color.WHITE)
	_text_i(Vector2(x, y + 64.0), "Price $%d  ·  sells for $%d" % [int(def["price"]), maxi(1, int(def["price"]) / 2)], T_SM, Color("b8c0cc"))
	_rarity_chip(box.end.x - pad, box.position.y + pad + 8.0, _gear_rarity(String(g["id"])))
	y += 84.0
	if not gchips.is_empty():
		var gx := x
		for c in gchips:
			var icw := 28.0
			var cw := icw + _text_w(String(c[0]), T_XS, true) + (18.0 if String(c[0]) != "" else 12.0)
			var cr := Rect2(gx, y, cw, 32.0)
			_panel(cr, c[1], 12)
			_icon(String(c[2]), Vector2(cr.position.x + 20.0, cr.get_center().y), 22.0, Color.WHITE)
			_text_center(Rect2(cr.position.x + icw, cr.position.y, cw - icw, cr.size.y), String(c[0]), T_XS, Color.WHITE, true)
			gx += cw + 8.0
		y += 44.0
	draw_line(Vector2(x, y), Vector2(x + iw, y), Color(1, 1, 1, 0.12), 2.0)
	_text(Vector2(x, y + 34.0), "EFFECT", T_XS, c_gold, true)
	_rich(Vector2(x, y + 46.0), body, iw, T_SM, Color("e8ecf2"))
	y += 52.0 + bh + 10.0
	draw_line(Vector2(x, y), Vector2(x + iw, y), Color(1, 1, 1, 0.12), 2.0)
	_text(Vector2(x, y + 34.0), "WHEN", T_XS, c_gold, true)
	_rich(Vector2(x, y + 46.0), String(acts.get(act, "")), iw, T_SM, Color("e8ecf2"))
	y += 52.0 + ah + 10.0
	draw_line(Vector2(x, y), Vector2(x + iw, y), Color(1, 1, 1, 0.12), 2.0)
	_text(Vector2(x, y + 34.0), "LEVEL", T_XS, c_gold, true)
	_wrap(Vector2(x, y + 46.0), lv_text, iw, T_SM, Color("e8ecf2"))
	if st != "":
		_text(Vector2(x, y + 52.0 + 30.0 + 30.0), st, T_SM, Color("9af0b8"), true)

func _playing_disc() -> Disc:
	if now_slot >= 0 and tray[now_slot] >= 0:
		return collection[tray[now_slot]]
	return null

func _ctl_faders(ctl: Rect2, levels: Array, flash: float, bay: int = -1, is_era: bool = false) -> void:
	var n := levels.size()
	var cw := ctl.size.x / n
	var cur := _playing_disc()
	for gi in n:
		var cx := ctl.position.x + cw * (gi + 0.5)
		var lv := int(levels[gi])
		var track := Rect2(cx - 4.0, ctl.position.y + 26.0, 8.0, ctl.size.y - 66.0)
		for t in D.EQ_MAX - D.EQ_MIN + 1:
			var ty := track.end.y - track.size.y * t / float(D.EQ_MAX - D.EQ_MIN)
			var zero := t == -D.EQ_MIN
			draw_line(Vector2(cx - (17.0 if zero else 15.0), ty), Vector2(cx - 9.0, ty), Color(0, 0, 0, 0.7 if zero else 0.4), 2.0 if zero else 1.5)
		_inset(track, 4.0, Color("0b0c0e"))
		var v := float(lv - D.EQ_MIN) / float(D.EQ_MAX - D.EQ_MIN)
		var cap := Rect2(cx - 13.0, track.end.y - track.size.y * v - 9.0, 26.0, 18.0)
		var hit := flash > 0.0 and cur != null and (cur.era if is_era else cur.genre) == gi
		var cc := Color("2b2e33")
		if lv > 0:
			cc = Color(D.SOUND_COLOR).darkened(0.25)
		elif lv < 0:
			cc = c_bad.darkened(0.2)
		_fader_cap(cap, cc, flash if hit else 0.0)
		if lv != 0:
			_text_center(cap, "%+d" % lv, 11, Color.WHITE, true)
		var lc := Color(D.SOUND_COLOR).lightened(0.2) if lv > 0 else c_bad.lightened(0.2)
		_led(Vector2(cx, ctl.position.y + 10.0), 4.0, lc, 0.0 if lv == 0 else 1.0)
		_text_center(Rect2(cx - cw, ctl.end.y - 30.0 + (gi % 2) * 16.0, cw * 2.0, 18.0), (D.ERAS if is_era else D.GENRE_SHORT)[gi], 11, Color("23262b") if lv != 0 else Color("6a6f77"), true)
		if bay >= 0 and lv < D.EQ_MAX:
			var col_r := Rect2(cx - cw * 0.5, ctl.position.y, cw, ctl.size.y - 30.0)
			if col_r.has_point(mouse):
				_panel(col_r, Color(c_gold, 0.18), 6, c_gold, 2)
				_tip(col_r, "Raise %s to %+d" % [(D.ERAS if is_era else D.GENRES)[gi], lv + 1])
			_register(col_r, _bench_apply.bind(bay, gi))

func _ctl_xfader(ctl: Rect2, flash: float) -> void:
	var track := Rect2(ctl.position.x + 34.0, ctl.get_center().y + 10.0, ctl.size.x - 68.0, 10.0)
	for t in 11:
		var tx := track.position.x + track.size.x * t / 10.0
		draw_line(Vector2(tx, track.position.y - 18.0), Vector2(tx, track.position.y - (24.0 if t % 5 == 0 else 12.0)), Color(0, 0, 0, 0.45), 1.5)
	_inset(track, 5.0, Color("0b0c0e"))
	_silk(Vector2(track.position.x - 28.0, track.get_center().y + 8.0), "A", T_SM, Color("23262b"))
	_silk(Vector2(track.end.x + 14.0, track.get_center().y + 8.0), "B", T_SM, Color("23262b"))
	var cx := track.position.x + track.size.x * xfade_pos
	_fader_cap(Rect2(cx - 16.0, track.get_center().y - 24.0, 32.0, 48.0), Color("2b2e33"), 0.0)
	_led(Vector2(ctl.end.x - 14.0, ctl.position.y + 16.0), 6.0, Color(D.ENERGY_COLOR).lightened(0.3), flash)
	_silk(Vector2(ctl.end.x - 72.0, ctl.position.y + 22.0), "LINK", 12, Color("3d4148"))

func _ctl_dial(ctl: Rect2, labels: Array, sel: int, flash: float, bay: int = -1) -> void:
	var kc := ctl.get_center() + Vector2(0.0, 10.0)
	var kr := 36.0
	var n := labels.size()
	var a0 := deg_to_rad(150.0)
	var a1 := deg_to_rad(390.0)
	for k in n:
		var d := Vector2.from_angle(lerpf(a0, a1, float(k) / (n - 1)))
		draw_line(kc + d * (kr + 6.0), kc + d * (kr + 16.0), Color("23262b"), 2.0)
		var on := k == sel
		var lr := Rect2(kc + d * (kr + 40.0) - Vector2(40.0, 12.0), Vector2(80.0, 24.0))
		if bay >= 0 and not on:
			if lr.has_point(mouse):
				_panel(lr, Color(c_gold, 0.25), 6, c_gold, 2)
			_register(lr, _bench_apply.bind(bay, k))
		_text_center(lr, String(labels[k]), 13 if on else 11, Color("b03a2e") if on else Color("4c5058"), true)
	var ang := lerpf(a0, a1, float(sel) / (n - 1)) + sin(clock * 40.0) * 0.05 * flash
	_knob(kc, kr, ang, Color("c3c8ce"))

func _ctl_knobs(ctl: Rect2, flash: float) -> void:
	var leds := 8
	for k in leds:
		var lc := Color("7fe0a0") if k < 5 else (Color("f2c14e") if k < 7 else Color("ff6b5a"))
		_led(Vector2(ctl.position.x + 20.0 + k * (ctl.size.x - 40.0) / (leds - 1), ctl.position.y + 14.0), 4.0, lc, 1.0 if flash * leds > k else 0.0)
	for k in 2:
		var kc := Vector2(ctl.position.x + ctl.size.x * (0.27 + k * 0.46), ctl.get_center().y + 8.0)
		_knob(kc, 32.0, deg_to_rad(200.0 + k * 70.0), Color("c3c8ce"))
		_text_center(Rect2(kc.x - 50.0, kc.y + 40.0, 100.0, 22.0), ["THRESH", "RATIO"][k], 11, Color("3d4148"), true)

func _ctl_tube(ctl: Rect2, flash: float) -> void:
	var win := Rect2(ctl.position.x + 10.0, ctl.position.y + 14.0, 96.0, ctl.size.y - 28.0)
	_inset(win, 8.0, Color("120c08"))
	var c := win.get_center() + Vector2(0.0, 18.0)
	var glow := 0.35 + 0.6 * flash
	for k in 5:
		draw_circle(c, 14.0 + k * 9.0, Color(Color("ff9a3c"), 0.1 * glow))
	var glass := Rect2(c.x - 24.0, win.position.y + 14.0, 48.0, win.size.y - 26.0)
	_panel(glass, Color(1, 1, 1, 0.05), 22, Color(1, 1, 1, 0.22), 2)
	for k in 3:
		var fx := c.x - 8.0 + k * 8.0
		draw_line(Vector2(fx, c.y - 26.0), Vector2(fx, c.y + 18.0), Color(Color("ffb35c"), 0.5 + 0.5 * glow), 2.0)
	draw_line(Vector2(glass.position.x + 8.0, glass.position.y + 10.0), Vector2(glass.position.x + 8.0, glass.end.y - 20.0), Color(1, 1, 1, 0.25), 2.0)
	var kc := Vector2(ctl.position.x + ctl.size.x * 0.7, ctl.get_center().y)
	_knob(kc, 34.0, deg_to_rad(250.0 + flash * 30.0), Color("c3c8ce"))
	_text_center(Rect2(kc.x - 50.0, kc.y + 42.0, 100.0, 22.0), "DRIVE", 11, Color("3d4148"), true)

func _draw_floats() -> void:
	for f: Dictionary in floats:
		var a := clampf(float(f["life"]) / 0.4, 0.0, 1.0)
		var t := String(f["text"])
		var fs := T_HERO if f.get("big", false) else T_LG
		var w := _heavy_w(t, fs)
		var p: Vector2 = f["pos"]
		var col: Color = f["col"]
		var h := fs * 1.6
		_panel(Rect2(p + Vector2(-w * 0.5 - 18.0, -h * 0.75), Vector2(w + 36.0, h)), Color(0.06, 0.07, 0.09, 0.88 * a), int(h * 0.5))
		_heavy(p + Vector2(-w * 0.5, 0.0), t, fs, Color(col, a))

func _draw_toast() -> void:
	if message_t <= 0.0:
		return
	var a := clampf(message_t / 0.4, 0.0, 1.0)
	var w := _text_w(message, T_LG, true) + 60.0
	var cx := 1280.0 if phase == "shop" else r_wallet.get_center().x
	var cy := 1374.0 if phase == "shop" else HAND_PLATE_Y - 92.0
	var r := Rect2(cx - w * 0.5, cy, w, 60.0)
	_panel(r, Color(0.08, 0.1, 0.14, 0.92 * a), 30)
	_text_center(r, message, T_LG, Color(1, 1, 1, a), true)

func _draw_held() -> void:
	if held < 0:
		return
	var d := collection[held]
	_draw_jewel(Rect2(mouse + Vector2(0.0, 6.0) - Vector2(96.0, 96.0), Vector2(192.0, 192.0)), d)

func _tip_disc(r: Rect2, d: Disc) -> void:
	if ui_live and r.has_point(mouse):
		hover_disc = d

# ---- Tooltip frames --------------------------------------------------------------------
# Rarity is shown by border colour only (PACK_RARITY colours). Plain UI hints ("") get a faint
# neutral border.
func _rarity_col(rar: String) -> Color:
	if D.PACK_RARITY.has(rar):
		return Color(String(D.PACK_RARITY[rar]["col"]))
	return Color(1, 1, 1)

func _tip_frame(box: Rect2, rar: String, bg: Color = Color("161b24"), radius: int = 18) -> void:
	_panel(Rect2(box.position + Vector2(0, 8), box.size), Color(0, 0, 0, 0.4), radius)
	var border := Color(_rarity_col(rar), 0.9) if D.PACK_RARITY.has(rar) else Color(1, 1, 1, 0.14)
	_panel(box, bg, radius, border, 3 if D.PACK_RARITY.has(rar) else 2)

# Generic hover tooltip (overrides the plain one in dj_engine_ui.gd): rarity frame + icons.
func _draw_tooltip(text: String) -> void:
	var w := 520.0
	var ts := _rich_size(text, w, T_SM, true)
	var box := Rect2(mouse + Vector2(24.0, 24.0), Vector2(ts.x + 36.0, ts.y + 26.0))
	if box.end.x > UI_W - 12.0:
		box.position.x = mouse.x - box.size.x - 16.0
	if box.end.y > UI_H - 12.0:
		box.position.y = mouse.y - box.size.y - 16.0
	_tip_frame(box, hover_tip_rar, c_ink, 14)
	_rich(box.position + Vector2(18.0, 13.0), text, w, T_SM, Color.WHITE, true)

# ---- Text with genre/decade icons ---------------------------------------------------------
# Wraps text like _wrap, but any genre name (Rock, Hip-Hop, ROCK...) or decade (70s) gets its
# icon drawn in front of it, tinted in the genre colour. _rich_size measures the same layout.
func _rich_tag(word: String) -> Dictionary:
	var core := word
	var lead := ""
	var trail := ""
	while core.length() > 0 and core[0] in ["(", "\"", "'"]:
		lead += core[0]
		core = core.substr(1)
	while core.length() > 0 and core[core.length() - 1] in [".", ",", ";", ":", "!", "?", ")", "\"", "'"]:
		trail = core[core.length() - 1] + trail
		core = core.substr(0, core.length() - 1)
	var gi := D.GENRES.find(core)
	if gi < 0:
		gi = D.GENRE_SHORT.find(core)
	if gi < 0:
		for k in D.GENRES.size():
			if String(D.GENRES[k]).to_upper() == core:
				gi = k
	if gi >= 0:
		return {"lead": lead, "core": core, "trail": trail, "icon": "g%d" % gi, "col": Color(D.SLEEVE_MAIN[gi]).lightened(0.45)}
	var ei := D.ERAS.find(core)
	if ei >= 0:
		# Decades show as the icon alone (no "70s" text after it).
		return {"lead": lead, "core": core, "trail": trail, "icon": "e%d" % ei, "icon_only": true}
	return {}

func _rich_layout(text: String, width: float, size: int, bold: bool, pos: Vector2, draw_it: bool, col: Color) -> Vector2:
	var f := _f(bold)
	var lh := f.get_height(size)
	var asc := f.get_ascent(size)
	var sp := _text_w(" ", size, bold)
	var isz := size * 1.2
	var y := 0.0
	var widest := 0.0
	var paras := text.split("\n")
	for pi in paras.size():
		var x := 0.0
		for word: String in paras[pi].split(" "):
			if word == "":
				x += sp
				continue
			var tag := _rich_tag(word)
			var ww := _text_w(word, size, bold) + ((isz + 4.0) if not tag.is_empty() else 0.0)
			if tag.has("icon_only"):
				ww = _text_w(String(tag["lead"]) + String(tag["trail"]), size, bold) + isz
			if x > 0.0 and x + ww > width:
				widest = maxf(widest, x - sp)
				x = 0.0
				y += lh
			if draw_it:
				var base := pos + Vector2(x, y + asc)
				if tag.is_empty():
					_text(base, word, size, col, bold)
				else:
					var tc: Color = tag["col"] if tag.has("col") else col
					var lx := base.x
					if tag["lead"] != "":
						_text(Vector2(lx, base.y), tag["lead"], size, col, bold)
						lx += _text_w(tag["lead"], size, bold)
					_icon(String(tag["icon"]), Vector2(lx + isz * 0.5, base.y - size * 0.36), isz, tc)
					if tag.has("icon_only"):
						lx += isz
					else:
						lx += isz + 4.0
						_text(Vector2(lx, base.y), tag["core"], size, tc, bold)
						lx += _text_w(tag["core"], size, bold)
					if tag["trail"] != "":
						_text(Vector2(lx, base.y), tag["trail"], size, col, bold)
			x += ww + sp
		widest = maxf(widest, x - sp)
		y += lh
	return Vector2(minf(widest, width), y)

func _rich_heavy(pos: Vector2, text: String, size: int, col: Color) -> void:
	var x := pos.x
	var sp := _heavy_w(" ", size)
	var isz := size * 1.1
	for word: String in text.split(" "):
		var tag := _rich_tag(word)
		if tag.is_empty():
			_heavy(Vector2(x, pos.y), word, size, col)
			x += _heavy_w(word, size) + sp
			continue
		var tc: Color = tag["col"] if tag.has("col") else col
		_icon(String(tag["icon"]), Vector2(x + isz * 0.5, pos.y - size * 0.36), isz, tc)
		x += isz + sp

func _rich(pos: Vector2, text: String, width: float, size: int, col: Color, bold: bool = false) -> void:
	_rich_layout(text, width, size, bold, pos, true, col)

func _rich_size(text: String, width: float, size: int, bold: bool = false) -> Vector2:
	return _rich_layout(text, width, size, bold, Vector2.ZERO, false, Color.WHITE)

func _rich_h(text: String, width: float, size: int) -> float:
	return _rich_size(text, width, size).y if text != "" else 0.0

func _draw_disc_tip(d: Disc) -> void:
	var w := 600.0
	var pad := 24.0
	var iw := w - pad * 2.0
	var body := ""
	var head := ""
	if not d.cdr:
		head = _effect_name(d).to_upper()
		body = _cond_text(d, false)
	else:
		head = "MIX"
		body = "When you play it, it picks a random album and becomes that album's genre and decade. The audience, requests and gear treat it like that CD, so it may delight them or turn them against you. It has no effect of its own."
	var fit_head := ""
	var fit_body := ""
	var fit_h := 0.0
	var tr_head := ""
	var tr_body := ""
	if not d.cdr and d.genre >= 0:
		tr_head = _trait_name(d.genre).to_upper()
		tr_body = _trait_body(d.genre)
	var pile_head := ""
	var pile_body := ""
	if phase == "show" and d.genre >= 0:
		var pg := 0
		var pe := 0
		var tip_pool: Array = draw_pile.duplicate()
		if pile_with_hand:
			for wi in wallet:
				if wi >= 0:
					tip_pool.append(wi)
		for pi in tip_pool:
			pg += _has_tag(collection[pi], false, d.genre)
			pe += _has_tag(collection[pi], true, d.era)
		pile_head = "IN YOUR HAND AND THE DRAW PILE" if pile_with_hand else "LEFT IN THE DRAW PILE"
		pile_body = "%d %s  ·  %d %s  (of %d)" % [pg, D.GENRES[d.genre], pe, D.ERAS[d.era], tip_pool.size()]
	var bh := _rich_h(body, iw, T_SM)
	var tbh := _rich_h(tr_body, iw, T_SM)
	var h := pad + 84.0 + 44.0 + (52.0 + bh + 10.0 if body != "" else 0.0) + (52.0 + tbh + 10.0 if tr_body != "" else 0.0) + (fit_h) + (92.0 if pile_head != "" else 0.0) + (84.0 if d.edition != "" else 0.0) + pad - 6.0
	var box := Rect2(mouse + Vector2(28.0, 28.0), Vector2(w, h))
	if box.end.x > UI_W - 12.0:
		box.position.x = mouse.x - w - 20.0
	if box.end.y > UI_H - 12.0:
		box.position.y = maxf(12.0, UI_H - 12.0 - h)
	_tip_frame(box, "" if d.cdr else (String(d.rarity) if D.PACK_RARITY.has(String(d.rarity)) else "common"))
	var x := box.position.x + pad
	var y := box.position.y + pad
	_heavy(Vector2(x, y + 30.0), d.title, T_LG, Color.WHITE)
	_text_i(Vector2(x, y + 64.0), "Picks a random album when played" if d.cdr else "by %s  ·  %s" % [d.band, D.LABELS[d.label]["name"]], T_SM, Color("b8c0cc"))
	if not d.cdr:
		_rarity_chip(box.end.x - pad, box.position.y + pad + 8.0, String(d.rarity) if D.PACK_RARITY.has(String(d.rarity)) else "common")
	y += 84.0
	# A chip is [text, colour] or [text, colour, icon kind]; genre and decade chips lead with their icon.
	var chips := [[D.GENRES[d.genre].to_upper(), Color("5d626a"), "g%d" % d.genre], ["", Color("5d626a"), "e%d" % d.era], ["%d POINTS" % d.sound, Color(D.SOUND_COLOR)], [D.LABELS[d.label]["short"].to_upper(), Color(D.LABELS[d.label]["color"])]] if not (d.genre < 0) else [["CD-R", Color(D.FLOW_COLOR).darkened(0.2)]]
	var cx := x
	for c in chips:
		var chip_icon := String(c[2]) if c.size() > 2 else ""
		var icw := 28.0 if chip_icon != "" else 0.0
		var cw := icw + _text_w(String(c[0]), T_XS, true) + (18.0 if String(c[0]) != "" else 12.0)
		var cr := Rect2(cx, y, cw, 32.0)
		_panel(cr, c[1], 12)
		if chip_icon != "":
			_icon(chip_icon, Vector2(cr.position.x + 9.0 + 11.0, cr.get_center().y), 22.0, Color.WHITE)
		_text_center(Rect2(cr.position.x + icw, cr.position.y, cw - icw, cr.size.y), String(c[0]), T_XS, Color.WHITE, true)
		cx += cw + 8.0
	y += 44.0
	if body != "":
		draw_line(Vector2(x, y), Vector2(x + iw, y), Color(1, 1, 1, 0.12), 2.0)
		_text(Vector2(x, y + 34.0), head, T_XS, c_gold, true)
		_rich(Vector2(x, y + 46.0), body, iw, T_SM, Color("e8ecf2"))
		y += 52.0 + bh + 10.0
	if tr_body != "":
		draw_line(Vector2(x, y), Vector2(x + iw, y), Color(1, 1, 1, 0.12), 2.0)
		var tcol := Color(D.SLEEVE_MAIN[d.genre]).lightened(0.4)
		var tic := T_XS * 1.4
		_icon("g%d" % d.genre, Vector2(x + tic * 0.5, y + 34.0 - T_XS * 0.36), tic, tcol)
		_text(Vector2(x + tic + 8.0, y + 34.0), tr_head, T_XS, tcol, true)
		_rich(Vector2(x, y + 46.0), tr_body, iw, T_SM, Color("e8ecf2"))
		y += 52.0 + tbh + 10.0
	if pile_head != "":
		draw_line(Vector2(x, y), Vector2(x + iw, y), Color(1, 1, 1, 0.12), 2.0)
		_text(Vector2(x, y + 34.0), pile_head, T_XS, c_gold, true)
		_rich(Vector2(x, y + 68.0 - font.get_ascent(T_SM)), pile_body, iw, T_SM, Color("e8ecf2"))
		y += 92.0
	if d.edition != "":
		var ed: Dictionary = D.EDITIONS[d.edition]
		draw_line(Vector2(x, y), Vector2(x + iw, y), Color(1, 1, 1, 0.12), 2.0)
		_text(Vector2(x, y + 34.0), "%s EDITION" % String(ed["name"]).to_upper(), T_XS, Color(ed["color"]).lightened(0.3), true)
		_text(Vector2(x, y + 68.0), String(ed["text"]), T_SM, Color("e8ecf2"))

func _modal_panel(w: float, h: float) -> Rect2:
	draw_rect(Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600)), Color(0.05, 0.06, 0.08, 0.72))
	var r := Rect2(UI_W * 0.5 - w * 0.5, UI_H * 0.5 - h * 0.5, w, h)
	_panel(Rect2(r.position + Vector2(0, 10), r.size), Color(0, 0, 0, 0.4), 24)
	_panel(r, Color("f4efe4"), 24)
	return r

func _draw_result() -> void:
	var r := _modal_panel(900.0, 560.0)
	_heavy_center(Rect2(r.position.x, r.position.y + 40.0, r.size.x, 90.0), "Gig %d cleared!" % gig_n, T_HERO, c_good)
	_text_center(Rect2(r.position.x, r.position.y + 140.0, r.size.x, 40.0), "Crowd score %s of %s" % [_fmt_int(gig_score), _fmt_int(target)], T_LG, c_ink, true)
	var x := r.position.x + 220.0
	var w := r.size.x - 440.0
	var y := r.position.y + 230.0
	_text(Vector2(x, y), "Gig pay", T_MD, c_muted, true)
	_heavy_right(x + w, y, "$%d" % int(reward["pay"]), T_LG, c_ink)
	_text(Vector2(x, y + 48.0), "Crowd bonus", T_MD, c_muted, true)
	_heavy_right(x + w, y + 48.0, "$%d" % int(reward["bonus"]), T_LG, c_ink)
	if int(reward.get("mint", 0)) > 0:
		_text(Vector2(x + w + 30.0, y + 48.0), "+$%d mint" % int(reward["mint"]), T_SM, c_good, true)
	draw_line(Vector2(x, y + 70.0), Vector2(x + w, y + 70.0), Color(c_ink, 0.2), 2.0)
	_text(Vector2(x, y + 110.0), "Cash", T_MD, c_muted, true)
	_heavy_right(x + w, y + 112.0, "$%d" % cash, T_XL, c_good)
	_hw_button(Rect2(r.get_center().x - 220.0, r.end.y - 120.0, 440.0, 84.0), "Visit the record shop", _to_shop, true, Color("3f9b5a"), T_LG)

func _draw_run_end(won: bool) -> void:
	var r := _modal_panel(1000.0, 600.0)
	if won:
		_heavy_center(Rect2(r.position.x, r.position.y + 50.0, r.size.x, 110.0), "YOU WIN!", T_HERO + 24, c_good)
		_text_center(Rect2(r.position.x, r.position.y + 190.0, r.size.x, 44.0), "You beat all %d headliners across %d gigs." % [D.RUN_GIGS / D.BOSS_EVERY, D.RUN_GIGS], T_LG, c_ink, true)
		var units := 0
		for g: Dictionary in rack:
			if not g.is_empty():
				units += 1
		var x := r.position.x + 260.0
		var w := r.size.x - 520.0
		var y := r.position.y + 290.0
		_text(Vector2(x, y), "Deck", T_MD, c_muted, true)
		_heavy_right(x + w, y, "%d CDs" % collection.size(), T_LG, c_ink)
		_text(Vector2(x, y + 56.0), "Rig", T_MD, c_muted, true)
		_heavy_right(x + w, y + 56.0, "%d units" % units, T_LG, c_ink)
		_text(Vector2(x, y + 112.0), "Cash", T_MD, c_muted, true)
		_heavy_right(x + w, y + 112.0, "$%d" % cash, T_LG, c_good)
	else:
		_heavy_center(Rect2(r.position.x, r.position.y + 50.0, r.size.x, 90.0), "The crowd went home", T_HERO, c_bad)
		_text_center(Rect2(r.position.x, r.position.y + 190.0, r.size.x, 44.0), "Your tour ended at gig %d of %d." % [gig_n, D.RUN_GIGS], T_LG, c_ink, true)
	_hw_button(Rect2(r.get_center().x - 160.0, r.end.y - 130.0, 320.0, 86.0), "Main menu", _to_title, true, Color("3f9b5a"), T_LG)

func _to_shop(hint: Dictionary = {}) -> void:
	_make_shop(hint)
	phase = "shop"
	message_t = 0.0

func _leave_shop() -> void:
	install_queue.clear()
	install_price = 0
	install_src = -1
	pack = {}
	bench = -1
	services.clear()
	message_t = 0.0
	binder_open = false
	_back_on_road()

func _album_price(d: Disc) -> int:
	return D.ALBUM_PRICE + (1 if d.sound >= 10 else 0)

func _reroll_price() -> int:
	var a := 3
	var b := 5
	for i in reroll_n:
		var t := a + b
		a = b
		b = t
	return a

func _reroll() -> void:
	var price := _reroll_price()
	if cash < price or not install_queue.is_empty() or not pack.is_empty():
		return
	cash -= price
	reroll_n += 1
	_make_shop(shop_hint, false)
	_sfx("page_turn")
	_say("New stock. The next reroll costs $%d." % _reroll_price())

func _make_shop(hint: Dictionary = {}, fresh: bool = true) -> void:
	if fresh:
		reroll_n = 0
	shop_hint = hint
	shop_items.clear()
	var picks: Array = _random_albums(D.SHOP_ALBUMS, int(hint["genre"]) if not hint.is_empty() else -1, int(hint["era"]) if not hint.is_empty() else -1)
	for a: Dictionary in picks:
		var d := _make_disc(a)
		shop_items.append({"kind": "album", "disc": d, "price": _album_price(d), "sold": false})
	var ap: Dictionary = D.ALBUM_PACKS[rng.randi_range(0, D.ALBUM_PACKS.size() - 1)]
	shop_items.append({"kind": "album_pack", "pack": ap, "price": int(ap["price"]), "sold": false})
	var gear_ids := _random_gear_ids(D.SHOP_GEAR)
	if not hint.is_empty() and not String(hint["gear"]) in gear_ids and not String(hint["gear"]) in _owned_gear():
		if gear_ids.is_empty():
			gear_ids.append(String(hint["gear"]))
		else:
			gear_ids[0] = String(hint["gear"])
	for k in D.SHOP_GEAR:
		if k < gear_ids.size():
			shop_items.append({"kind": "gear", "gear": _make_gear(gear_ids[k]), "price": int(gear_defs[gear_ids[k]]["price"]), "sold": false})
		else:
			shop_items.append({"kind": "gear", "gear": {}, "price": 0, "sold": true})
	var gp: Dictionary = D.GEAR_PACKS[rng.randi_range(0, D.GEAR_PACKS.size() - 1)]
	shop_items.append({"kind": "gear_pack", "pack": gp, "price": int(gp["price"]), "sold": false})
	_make_services()

func _buy(i: int) -> void:
	var it: Dictionary = shop_items[i]
	if bool(it["sold"]) or cash < int(it["price"]):
		return
	match String(it["kind"]):
		"album":
			cash -= int(it["price"])
			it["sold"] = true
			collection.append(it["disc"])
			_say("%s added to your binder." % (it["disc"] as Disc).title)
		"album_pack":
			cash -= int(it["price"])
			it["sold"] = true
			var ap: Dictionary = it["pack"]
			var items: Array = []
			for a in _random_albums(int(ap["show"])):
				items.append(_make_disc(a))
			pack = {"kind": "album", "title": ap["name"], "pick": int(ap["pick"]), "items": items}
			pack_sel.clear()
			_pack_start()
		"gear":
			if not install_queue.is_empty():
				return
			cash -= int(it["price"])
			it["sold"] = true
			install_queue = [it["gear"]]
			install_price = 0
			install_src = -1
			install_refund = i
			install_refund_price = int(it["price"])
			_say("Pick a bay for the %s. Right-click to take it back." % gear_defs[(it["gear"] as Dictionary)["id"]]["name"])
		"gear_pack":
			cash -= int(it["price"])
			it["sold"] = true
			var gp: Dictionary = it["pack"]
			var items: Array = []
			var shelf: Array = shop_items.filter(func(o): return o["kind"] == "gear" and not bool(o["sold"])).map(func(o): return o["gear"]["id"])
			var ids := _random_gear_ids(int(gp["show"]), shelf)
			if ids.size() < int(gp["show"]):
				ids = _random_gear_ids(int(gp["show"]))
			for id in ids:
				items.append(_make_gear(id))
			if items.is_empty():
				cash += int(it["price"])
				it["sold"] = false
				_say("You already own every kind of gear.")
				return
			pack = {"kind": "gear", "title": gp["name"], "pick": mini(int(gp["pick"]), items.size()), "items": items}
			pack_sel.clear()
			_pack_start()

func _toggle_pick(k: int) -> void:
	if k in pack_sel:
		pack_sel.erase(k)
	elif pack_sel.size() < int(pack["pick"]):
		pack_sel.append(k)

func _take_pack() -> void:
	var items: Array = pack["items"]
	if pack["kind"] == "album":
		for k in pack_sel:
			collection.append(items[k])
			_enlist(items[k])
		_say("Added %d album%s to your binder." % [pack_sel.size(), "" if pack_sel.size() == 1 else "s"])
	elif pack["kind"] == "gear":
		install_queue.clear()
		for k in pack_sel:
			install_queue.append(items[k])
		install_price = 0
		install_src = -1
		_say("Pick a bay for each piece of gear. Right-click to leave it in the box.")
	pack = {}
	pack_sel.clear()
	if phase == "reward":
		_back_on_road()

func _bench_kind() -> String:
	if bench < 0 or bench >= services.size():
		return ""
	return String(services[bench]["kind"])

func _buy_consumable(i: int) -> void:
	var sv: Dictionary = services[i]
	if bool(sv["sold"]) or cash < int(sv["price"]):
		return
	if bool(sv.get("pack", false)):
		if not pack.is_empty() or not install_queue.is_empty():
			return
		cash -= int(sv["price"])
		sv["sold"] = true
		pack = {"kind": "tape", "title": "Tape Pack", "pick": 1, "items": _tape_choices(D.TAPE_PACK_SHOW, "")}
		pack_sel.clear()
		_pack_start()
		return
	if consumables.find("") < 0:
		_say("Your consumable slots are full.")
		return
	cash -= int(sv["price"])
	sv["sold"] = true
	_give_consumable(String(sv["id"]))

func _bench_apply(bay: int, idx: int) -> void:
	var sv: Dictionary = services[bench]
	var g: Dictionary = rack[bay]
	if cash < int(sv["price"]) or g.is_empty() or not g.has("levels"):
		return
	g["levels"][idx] = mini(D.EQ_MAX, int(g["levels"][idx]) + 1)
	var nm := String(D.GENRES[idx]) if String(g["id"]) == "genre_eq" else "The " + String(D.ERAS[idx])
	_say("%s is now %+d." % [nm, int(g["levels"][idx])])
	cash -= int(sv["price"])
	sv["sold"] = true
	bench = -1
	comp_flash[bay] = 1.0
	_sfx("page_turn")

func _enhance(i: int) -> void:
	var sv: Dictionary = services[binder_pick]
	var d := collection[i]
	if cash < int(sv["price"]):
		return
	if String(sv["kind"]) == "trade":
		collection.erase(d)
		trade_count += 1
		_say("Traded in %s." % d.title)
	elif String(sv["kind"]) == "upgrade":
		d.sound += D.UPGRADE_POINTS
		_say("%s gains +%d base points." % [d.title, D.UPGRADE_POINTS])
	else:
		if d.edition != "":
			return
		d.edition = String(sv["edition"])
		_say("%s is now %s." % [d.title, D.EDITIONS[d.edition]["name"]])
	cash -= int(sv["price"])
	sv["sold"] = true
	binder_pick = -1
	binder_open = false
	_sfx("page_turn")

func _make_services() -> void:
	services.clear()
	bench = -1
	for id in _tape_choices(D.CONSUMABLE_OFFERS, ""):
		services.append({"id": id, "price": int(D.CONSUMABLES[id]["price"]), "sold": false})
	services.append({"id": "", "pack": true, "price": D.TAPE_PACK_PRICE, "sold": false})

func _install(slot: int) -> void:
	if install_queue.is_empty():
		return
	var t := _install_anchor(install_queue[0], slot)
	if t < 0:
		_say("That unit needs a bay with room for it.")
		return
	if install_price > 0:
		if cash < install_price:
			return
		cash -= install_price
		shop_items[install_src]["sold"] = true
	var g: Dictionary = install_queue.pop_front()
	_put_unit(g, t)
	_resolve_clones()
	comp_flash[t] = 1.0
	install_price = 0
	install_src = -1
	install_refund = -1
	install_stall = -1
	_after_placement()
	_sfx("page_turn")
	_say("Installed the %s." % gear_defs[g["id"]]["name"])

func _draw_shop() -> void:
	draw_rect(Rect2(-800, -800, UI_W + 1600, UI_H + 1600), Color("3a302b"))
	var x := -40.0
	while x < UI_W:
		draw_line(Vector2(x, -800.0), Vector2(x, UI_H + 800.0), Color(0, 0, 0, 0.08), 3.0)
		x += 120.0
	var sign := Rect2(1000.0, 60.0, 560.0, 110.0)
	for sx: float in [sign.position.x + 70.0, sign.end.x - 70.0]:
		draw_line(Vector2(sx, -40.0), Vector2(sx, sign.position.y), Color("5f5e5a"), 4.0)
	_shadow(sign, 12, 8.0)
	_panel(sign, Color("1d1a17"), 12, c_gold, 3)
	_panel(sign.grow(-8.0), Color(c_gold, 0.08), 8)
	_heavy_center(Rect2(sign.position.x, sign.position.y + 6.0, sign.size.x, 62.0), "THE B-SIDE", T_XL + 6, c_gold)
	var sub := "USED CDs  ·  AUDIO GEAR"
	var sub_col := Color(c_gold, 0.75)
	if not install_queue.is_empty():
		sub = "Choose a bay for the %s" % gear_defs[(install_queue[0] as Dictionary)["id"]]["name"]
		sub_col = Color("f4efe4")
	_text_center(Rect2(sign.position.x, sign.position.y + 70.0, sign.size.x, 32.0), sub, T_SM, sub_col, true)
	_draw_shop_label(1455.5, "RECORDS", 560.0)
	_draw_shop_label(1455.5, "GEAR", 910.0)
	_draw_shop_label(793.5, "CONSUMABLES", 560.0)
	_draw_shop_records()
	_draw_shop_gear()
	_draw_services(Rect2(668.0, 600.0, COL_W, 495.0))
	_draw_shop_nav()

func _draw_shop_label(cx: float, text: String, y: float) -> void:
	_heavy_center(Rect2(cx - 300.0, y - 28.0, 600.0, 40.0), text, T_MD, Color(c_gold, 0.85))

func _shop_x(k: int) -> float:
	return 1019.0 + k * 311.0

func _draw_shop_records() -> void:
	for k in 3:
		var it: Dictionary = shop_items[k]
		var cr := Rect2(_shop_x(k), 600.0, COL_W, COL_W * 0.886)
		if bool(it["sold"]):
			_sold_card(cr)
			continue
		var afford := cash >= int(it["price"])
		var hot := ui_live and cr.has_point(mouse)
		var rr := Rect2(cr.position - Vector2(0.0, 10.0 if hot else 0.0) + _shake_off("buy%d" % k), cr.size)
		if it["kind"] == "album":
			var d: Disc = it["disc"]
			_draw_case(rr, d, int(it["price"]))
			_tip_disc(cr, d)
			if ui_live and cr.has_point(mouse):
				_audition(d)
		else:
			_draw_case_pack(rr, it["pack"], int(it["price"]))
			var ap: Dictionary = it["pack"]
			_tip(cr, "%s: open it and pick %d of %d albums for your binder." % [ap["name"], int(ap["pick"]), int(ap["show"])])
		if ui_live and afford:
			_hold(cr, "buy%d" % k, "Hold to buy", _buy.bind(k))
		elif ui_live:
			_register(cr, _deny.bind("buy%d" % k, ""))

func _gear_box(r: Rect2, title: String, sub: String) -> void:
	_shadow(r, 6, 8.0)
	_panel(r, Color("c79b63"), 6, Color("7a5a33"), 2)
	draw_rect(Rect2(r.get_center().x - 34.0, r.position.y, 68.0, 22.0), Color("d9c9a3", 0.8))
	var lab := Rect2(r.position.x + 16.0, r.position.y + 32.0, r.size.x - 32.0, r.size.y - 58.0)
	_panel(lab, Color("f7f3e8"), 3)
	var fs := _fit_size(title.to_upper(), 28, lab.size.x - 16.0, 12)
	_heavy_center(Rect2(lab.position.x, lab.position.y + 8.0, lab.size.x, 44.0), title.to_upper(), fs, Color("22252a"))
	_text_center(Rect2(lab.position.x, lab.position.y + 54.0, lab.size.x, 30.0), sub, T_SM, Color("b03a2e"), true)

func _draw_shop_gear() -> void:
	for k in 3:
		var it: Dictionary = shop_items[3 + k]
		var ur := Rect2(_shop_x(k), 940.0, COL_W, GEAR_H)
		if bool(it["sold"]):
			_sold_card(ur)
			continue
		var afford := cash >= int(it["price"])
		var skey := ("gbuy%d" % k) if k < 2 else "buy5"
		var ush := Rect2(ur.position + _shake_off(skey), ur.size)
		if k < 2:
			_draw_gear(ush, it["gear"], 0.0)
			if install_src == 3 + k:
				_panel(ur.grow(6.0), Color(0, 0, 0, 0), 10, c_gold, 5)
		else:
			var gp: Dictionary = it["pack"]
			_gear_box(Rect2(ush.position - Vector2(0.0, 8.0 if ui_live and install_queue.is_empty() and ur.has_point(mouse) else 0.0), ur.size), String(gp["name"]), "PICK %d OF %d" % [int(gp["pick"]), int(gp["show"])])
			_tip(ur, "%s: open it and keep %d of %d pieces of gear." % [gp["name"], int(gp["pick"]), int(gp["show"])])
		_hang_tag(Vector2(ur.get_center().x, ur.end.y + 36.0), "$%d" % int(it["price"]))
		if ui_live and not afford and install_queue.is_empty():
			_register(ur, _deny.bind(skey, ""))
		if ui_live and afford and install_queue.is_empty():
			if k < 2:
				if ur.has_point(mouse):
					_panel(ur.grow(4.0), Color(0, 0, 0, 0), 10, Color(c_gold, 0.8), 3)
				_hold(ur, "gbuy%d" % k, "Hold to buy", _buy.bind(3 + k))
			else:
				_hold(ur, "buy5", "Hold to buy", _buy.bind(5))

func _crate_wood(r: Rect2, seed_n: int) -> void:
	_surface(r, 4.0, "crate_wood", Color("a07a52"), Color("7d5c3c"), 500.0)
	if _tex("crate_wood") == null:
		var g := RandomNumberGenerator.new()
		g.seed = seed_n
		var y := r.position.y + 4.0
		while y < r.end.y - 4.0:
			var col := Color("5a3f27") if g.randf() < 0.5 else Color("c49a6c")
			var y2 := y + g.randf_range(-2.0, 2.0)
			draw_line(Vector2(r.position.x + 4.0, y), Vector2(r.end.x - 4.0, y2), Color(col, g.randf_range(0.08, 0.2)), g.randf_range(1.0, 2.0))
			y += g.randf_range(4.0, 9.0)
	draw_line(r.position + Vector2(4.0, 1.0), Vector2(r.end.x - 4.0, r.position.y + 1.0), Color(1, 1, 1, 0.25), 2.0)
	_panel(r, Color(0, 0, 0, 0), 4, Color(0, 0, 0, 0.5), 1)

func _draw_case(r: Rect2, d: Disc, price: int = -1) -> void:
	_draw_jewel(r, d, 0.0, price)

func _price_sticker(top_right: Vector2, text: String, k: float) -> void:
	var fs := maxi(12, int(20.0 * k * 0.7))
	var w := _heavy_w(text, fs) + 18.0
	var pr := Rect2(top_right.x - w, top_right.y, w, fs + 14.0)
	_panel(Rect2(pr.position + Vector2(1, 2), pr.size), Color(0, 0, 0, 0.3), 3)
	_panel(pr, Color("ffd23f"), 3)
	draw_line(Vector2(pr.position.x + 4.0, pr.end.y - 4.0), Vector2(pr.end.x - 4.0, pr.end.y - 4.0), Color(0, 0, 0, 0.18), 1.0)
	_heavy_center(pr, text, fs, Color("8a1c12"))

func _draw_case_pack(r: Rect2, ap: Dictionary, price: int) -> void:
	var k := r.size.y / 160.0
	for j in range(2, -1, -1):
		var cr := Rect2(r.position + Vector2(-j * 12.0, -j * 10.0) * k * 0.6 + Vector2(10.0, 10.0), r.size - Vector2(20.0, 20.0))
		_shadow(cr, 6, 4.0)
		_panel(cr, Color("c9d2db"), 6)
		var body := cr.grow(-3.0)
		_panel(body, Color("1b1e23"), 4)
		var ins := Rect2(body.position.x + 20.0, body.position.y + 6.0, body.size.x - 26.0, body.size.y - 12.0)
		_grad_panel(ins, 2.0, Color("2c3e50").lerp(Color("8e44ad"), j * 0.3), Color("1a252f"))
		if j == 0:
			_heavy_center(Rect2(ins.position.x, ins.position.y + ins.size.y * 0.25, ins.size.x, 50.0), String(ap["name"]).to_upper(), T_LG, Color("f4efe4"))
			_text_center(Rect2(ins.position.x, ins.position.y + ins.size.y * 0.25 + 46.0, ins.size.x, 30.0), "PICK %d OF %d" % [int(ap["pick"]), int(ap["show"])], T_XS, Color(1, 1, 1, 0.6), true)
	var wrap := r.grow(-4.0)
	_panel(wrap, Color(1, 1, 1, 0.06), 10, Color(1, 1, 1, 0.3), 2)
	draw_line(wrap.position + Vector2(30, 6), wrap.position + Vector2(8, 60), Color(1, 1, 1, 0.35), 3.0)
	draw_line(Vector2(wrap.end.x - 40.0, wrap.end.y - 8.0), Vector2(wrap.end.x - 8.0, wrap.end.y - 50.0), Color(1, 1, 1, 0.25), 2.0)
	if price >= 0:
		_price_sticker(Vector2(r.end.x - 4.0, r.position.y + 4.0), "$%d" % price, k)

func _shelf(r: Rect2) -> void:
	_shadow(r, 2, 6.0)
	_brushed(r, 2.0, Color("8d939a"), int(r.position.y))
	for bx: float in [r.position.x + 40.0, r.end.x - 60.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(bx, r.end.y), Vector2(bx + 20.0, r.end.y), Vector2(bx + 20.0, r.end.y + 40.0)]), Color("6b7178"))

func _hang_tag(c: Vector2, text: String) -> void:
	draw_line(c + Vector2(0.0, -30.0), c + Vector2(0.0, 6.0), Color("e8e2d0"), 2.0)
	draw_circle(c + Vector2(0.0, -30.0), 5.0, Color("8d939a"))
	var r := Rect2(c.x - 55.0, c.y, 110.0, 70.0)
	_panel(Rect2(r.position + Vector2(2, 4), r.size), Color(0, 0, 0, 0.3), 6)
	_panel(r, Color("f3e3b5"), 6)
	draw_circle(Vector2(r.get_center().x, r.position.y + 10.0), 4.0, Color("6b5a3a"))
	_heavy_center(Rect2(r.position.x, r.position.y + 14.0, r.size.x, r.size.y - 14.0), text, T_LG, Color("8a1c12"))

func _cardboard_box(r: Rect2, title: String, sub: String) -> void:
	_shadow(r, 4, 10.0)
	_surface(r, 4.0, "cardboard", Color("c79b63"), Color("a97e4a"), 400.0)
	if _tex("cardboard") == null:
		var g := RandomNumberGenerator.new()
		g.seed = 11
		var x := r.position.x + 3.0
		while x < r.end.x - 3.0:
			draw_line(Vector2(x, r.position.y + 2.0), Vector2(x, r.end.y - 2.0), Color(0, 0, 0, g.randf_range(0.02, 0.05)), 1.0)
			x += 6.0
	_panel(r, Color(0, 0, 0, 0), 4, Color("7a5a33"), 2)
	draw_line(Vector2(r.position.x, r.position.y + 50.0), Vector2(r.end.x, r.position.y + 50.0), Color("8a6a40"), 2.0)
	draw_rect(Rect2(r.get_center().x - 40.0, r.position.y, 80.0, 50.0), Color("d9c9a3", 0.75))
	draw_rect(Rect2(r.get_center().x - 40.0, r.position.y, 80.0, 50.0), Color(1, 1, 1, 0.12))
	var lab := Rect2(r.position.x + 40.0, r.position.y + 80.0, r.size.x - 80.0, 130.0)
	_panel(lab, Color("f7f3e8"), 2)
	_heavy_center(Rect2(lab.position.x, lab.position.y + 14.0, lab.size.x, 56.0), title.to_upper(), T_XL, Color("22252a"))
	_text_center(Rect2(lab.position.x, lab.position.y + 72.0, lab.size.x, 34.0), sub, T_MD, Color("b03a2e"), true)
	for k in 2:
		var ax := r.end.x - 30.0 - k * 22.0
		draw_line(Vector2(ax, r.end.y - 20.0), Vector2(ax, r.end.y - 50.0), Color(0, 0, 0, 0.45), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(ax - 7.0, r.end.y - 44.0), Vector2(ax + 7.0, r.end.y - 44.0), Vector2(ax, r.end.y - 56.0)]), Color(0, 0, 0, 0.45))

func _spring(u: float, damp: float, freq: float) -> float:
	if u <= 0.0:
		return 0.0
	return 1.0 - exp(-damp * u) * cos(freq * u)

func _pack_in_panel() -> bool:
	return phase == "show"

func _pack_panel() -> Rect2:
	return Rect2(730.0, CHANGER_Y + 10.0, 1756.0, CHANGER_H - 20.0)

func _pack_k() -> float:
	return PACK_PANEL_FX if _pack_in_panel() else 1.0

func _pack_base(is_disc: bool) -> Vector2:
	if _pack_in_panel():
		return Vector2(COL_W, COL_W * 0.886) if is_disc else Vector2(COL_W, GEAR_H)
	return Vector2(370.0, 328.0) if is_disc else Vector2(300.0, 185.0)

func _pack_items_rect() -> Rect2:
	var pnl := _pack_panel()
	return Rect2(pnl.position.x + 16.0, pnl.position.y, pnl.size.x - 32.0 - PACK_SIDE_W, pnl.size.y)

func _pack_item_pos(k: int, n: int, albums: bool) -> Vector2:
	if _pack_in_panel():
		var w := COL_W
		var step := COL_W + COL_G
		if n > 1:
			step = minf(step, (_pack_items_rect().size.x - w) / float(n - 1))
		return Vector2(_pack_cx() + (k - (n - 1) * 0.5) * step, _pack_c().y)
	if albums:
		return Vector2(_pack_cx() + (k - (n - 1) * 0.5) * 410.0, 730.0)
	return Vector2(_pack_cx() + (k - (n - 1) * 0.5) * 360.0, 740.0)

func _gear_rarity(id: String) -> String:
	var pr := int(gear_defs[id]["price"])
	return "rare" if pr >= 7 else ("uncommon" if pr == 6 else "common")

func _rarity_chip(right_x: float, y: float, rar: String) -> void:
	var col := Color(String(D.PACK_RARITY[rar]["col"]))
	var lab := rar.to_upper()
	var cw := _text_w(lab, T_XS, true) + 22.0
	var cr := Rect2(right_x - cw, y, cw, 32.0)
	_panel(cr, Color(col, 0.18), 12, Color(col, 0.8), 2)
	_text_center(cr, lab, T_XS, col.lightened(0.25) if rar == "common" else col.lightened(0.15), true)

func _tape_tip(id: String) -> String:
	var def: Dictionary = D.CONSUMABLES[id]
	return "%s  ·  %s\n%s" % [def["name"], String(def["rarity"]).capitalize(), def["text"]]

func _pack_item_rarity(it) -> String:
	if it is String:
		return String(D.CONSUMABLES[it]["rarity"])
	if it is Disc:
		return String((it as Disc).rarity)
	return _gear_rarity(String(it["id"]))

func _pack_time_item(k: int) -> float:
	return D.PACK_BUILD + D.PACK_BURST_WAIT + k * D.PACK_GAP

func _pack_ready_time() -> float:
	var n := (pack["items"] as Array).size()
	return _pack_time_item(n - 1) + D.PACK_ANIM * 0.8

func _pack_ready() -> bool:
	return not pack.is_empty() and pack_t >= _pack_ready_time()

func _pack_cx() -> float:
	if _pack_in_panel():
		return _pack_items_rect().get_center().x
	return UI_W * 0.5

func _pack_c() -> Vector2:
	if _pack_in_panel():
		return Vector2(_pack_cx(), _pack_panel().get_center().y)
	return Vector2(_pack_cx(), 720.0)

func _pack_start() -> void:
	_sc_sfx("f_whoosh", 0.7, 0.0)
	pack_t = 0.0
	pack_slide = 0.0
	pack_rig_open = false
	pack_burst = false
	pack_skipped = false
	pack_revealed.clear()
	pack_sparks.clear()
	pack_fx.clear()
	for i in 90:
		pack_fx.append({"a0": rng.randf_range(0.0, TAU), "w": rng.randf_range(0.7, 2.2) * (1.0 if rng.randf() < 0.5 else -1.0), "r0": rng.randf_range(160.0, 440.0), "sz": rng.randf_range(2.0, 5.5), "ph": rng.randf_range(0.0, TAU)})

func _pack_spark(p: Vector2, v: Vector2, life: float, col: Color, r: float, drag: float = 1.6) -> void:
	pack_sparks.append({"p": p, "v": v * _pack_k(), "t": 0.0, "life": life, "col": col, "r": r * lerpf(1.0, _pack_k(), 0.5), "drag": drag})

func _pack_burst_fx() -> void:
	fin_shake = maxf(fin_shake, 0.12)
	_sfx("page_turn")
	var cols := [Color("ffd24a"), Color("ffffff"), Color("8fe9ff"), Color("ff9ec4")]
	for i in 60:
		_pack_spark(_pack_c(), Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(200.0, 900.0), rng.randf_range(1.2, 2.2), cols[rng.randi_range(0, cols.size() - 1)], rng.randf_range(2.0, 6.0))

func _pack_reveal_fx(k: int, n: int, albums: bool, rar: String) -> void:
	var rp: Dictionary = D.PACK_RARITY[rar]
	var col := Color(String(rp["col"]))
	var pos := _pack_item_pos(k, n, albums)
	var cnt := 14 if rar == "common" else (28 if rar == "uncommon" else 50)
	for i in cnt:
		_pack_spark(pos, Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(100.0, 280.0 if rar == "common" else (480.0 if rar == "uncommon" else 760.0)), rng.randf_range(0.9, 1.7), col.lerp(Color.WHITE, rng.randf_range(0.0, 0.6)), rng.randf_range(2.0, 4.5 if rar != "rare" else 7.0))
	fin_shake = maxf(fin_shake, 0.06 if rar == "common" else (0.1 if rar == "uncommon" else 0.16))
	_sfx("page_turn")
	if tick_player != null:
		tick_player.pitch_scale = 0.7 if rar == "common" else (0.95 if rar == "uncommon" else 1.2)
		tick_player.play()

func _tick_pack(delta: float) -> void:
	if pack.is_empty():
		return
	var before := pack_t
	pack_t += delta
	pack_slide = move_toward(pack_slide, 1.0 if pack_rig_open else 0.0, delta * 5.0)
	var items: Array = pack["items"]
	var n := items.size()
	var albums: bool = String(pack["kind"]) in ["album", "mixed"]
	if pack_t < D.PACK_BUILD:
		var step := int(pack_t * 7.0)
		if step != int(before * 7.0) and tick_player != null:
			tick_player.pitch_scale = lerpf(0.8, 2.4, pack_t / D.PACK_BUILD)
			tick_player.play()
	if not pack_burst and pack_t >= D.PACK_BUILD:
		pack_burst = true
		if not pack_skipped:
			_pack_burst_fx()
	for k in n:
		if not (k in pack_revealed) and pack_t >= _pack_time_item(k):
			pack_revealed.append(k)
			if not pack_skipped:
				_pack_reveal_fx(k, n, albums, _pack_item_rarity(items[k]))
	for i in range(pack_sparks.size() - 1, -1, -1):
		var f: Dictionary = pack_sparks[i]
		f["t"] = float(f["t"]) + delta
		var v: Vector2 = f["v"]
		v *= exp(-float(f["drag"]) * delta)
		f["v"] = v
		f["p"] = Vector2(f["p"]) + v * delta
		if float(f["t"]) >= float(f["life"]):
			pack_sparks.remove_at(i)

func _pack_glow(c: Vector2, base: float, col: Color, power: float) -> void:
	for k in 9:
		var f := float(k) / 9.0
		draw_circle(c, base * (1.0 + 0.7 * power * (1.0 - f)), Color(col, minf(0.5, 0.06 * power * (k + 1) / 9.0)))

func _base_origin() -> Vector2:
	if fin_shake > 0.0:
		return screen_origin + Vector2(sin(clock * 91.0), cos(clock * 77.0)) * 16.0 * fin_shake * ui_scale
	return screen_origin

func _hold(r: Rect2, key: String, label: String, cb: Callable) -> void:
	if not ui_live:
		return
	hold_targets.append({"rect": r, "key": key, "label": label})
	_register(r, _hold_begin.bind(key, cb, r))

func _hold_begin(key: String, cb: Callable, r: Rect2) -> void:
	hold_key = key
	hold_cb = cb
	hold_rect = r
	hold_t = 0.0

func _tick_hold(delta: float) -> void:
	if hold_key == "":
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not hold_rect.has_point(_ui_mouse()):
		hold_key = ""
		hold_t = 0.0
		return
	hold_t += delta
	if hold_t >= D.HOLD_TIME:
		var cb := hold_cb
		hold_key = ""
		hold_t = 0.0
		cb.call()

func _draw_hold() -> void:
	for tg: Dictionary in hold_targets:
		var r: Rect2 = tg["rect"]
		if hold_key == String(tg["key"]):
			var f := clampf(hold_t / D.HOLD_TIME, 0.0, 1.0)
			draw_rect(Rect2(r.position.x, r.end.y - r.size.y * f, r.size.x, r.size.y * f), Color(c_gold, 0.26))
			draw_rect(Rect2(r.position.x, r.end.y - 10.0, r.size.x * f, 10.0), c_gold)
			_panel(r.grow(4.0), Color(0, 0, 0, 0), 10, c_gold, 4)
		elif hold_key == "" and r.has_point(mouse):
			var lab := String(tg["label"])
			var w := _text_w(lab, T_SM, true) + 36.0
			var pr := Rect2(r.get_center().x - w * 0.5, minf(r.end.y + 8.0, UI_H - 56.0), w, 42.0)
			_panel(pr, Color(0.06, 0.07, 0.09, 0.94), 21, Color(c_gold, 0.6), 2)
			_text_center(pr, lab, T_SM, c_gold, true)

func _pack_take(k: int) -> void:
	if pack.is_empty() or k in pack_sel or not install_queue.is_empty():
		return
	var pit = (pack["items"] as Array)[k]
	if pit is String and consumables.find("") < 0:
		_say("Your consumable slots are full. Use one first.")
		return
	pack_sel.append(k)
	_sfx("page_turn")
	if pit is String:
		_give_consumable(String(pit))
	elif pit is Disc and String(pack["kind"]) == "mixed":
		collection.append(pit)
		_enlist(pit)
		_say("%s added to your binder." % (pit as Disc).title)
	if pit is Dictionary:
		var gu: Dictionary = pit
		install_queue = [gu]
		install_price = 0
		install_src = -1
		install_refund = -1
		install_stall = -1
		_say("Pick a bay for the %s. Right-click to leave it in the box." % gear_defs[gu["id"]]["name"])
		return
	if pack_sel.size() >= int(pack["pick"]):
		_take_pack()

func _after_placement() -> void:
	if pack.is_empty() or not String(pack.get("kind", "")) in ["gear", "mixed"]:
		return
	if install_queue.is_empty() and pack_sel.size() >= int(pack["pick"]):
		pack = {}
		pack_sel.clear()
		if phase == "reward":
			_back_on_road()

func _skip_pack() -> void:
	if not install_queue.is_empty():
		return
	if not pack.is_empty() and not pack_sel.is_empty() and String(pack["kind"]) == "album":
		_take_pack()
		return
	pack = {}
	pack_sel.clear()
	if phase == "reward":
		_back_on_road()

func _draw_pack() -> void:
	var items: Array = pack["items"]
	var pick := int(pack["pick"])
	var albums: bool = String(pack["kind"]) in ["album", "mixed"]
	var album_art: bool = pack["kind"] == "album"
	var n := items.size()
	var t := pack_t
	var ready := _pack_ready()
	var full := Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600))
	var a_bg := clampf(t / 0.5, 0.0, 1.0)
	var inp := _pack_in_panel()
	var pk := _pack_k()
	var pnl := _pack_panel()
	if inp:
		draw_rect(full, Color(0, 0, 0, 0.35 * a_bg))
		_panel(pnl, Color(0.03, 0.03, 0.04, 0.96 * a_bg), 8, Color(c_gold, 0.5 * a_bg), 2)
	else:
		draw_rect(full, Color(0, 0, 0, a_bg))
	_register(full, func(): pass)
	_draw_rack(false)
	var u_b := clampf(t / D.PACK_BUILD, 0.0, 1.0)
	if t < D.PACK_BUILD + 0.1:
		var pulse := 0.5 + 0.5 * sin(t * (3.0 + 5.0 * u_b))
		for k in 8:
			var f := float(k) / 8.0
			draw_circle(_pack_c(), (170.0 + f * 330.0) * pk * (0.85 + 0.3 * pulse * u_b), Color(1.0, 0.86, 0.55, 0.03 * (1.0 - f) * (0.3 + u_b * 0.8)))
		for arm in 3:
			var pts := PackedVector2Array()
			for j in 28:
				var tt := j / 27.0
				var ang := arm * TAU / 3.0 + t * 1.2 * (1.0 + u_b * 0.7) + tt * 3.4
				var rad := lerpf(150.0, 430.0 * (1.0 - 0.45 * u_b), tt) * pk
				pts.append(_pack_c() + Vector2(cos(ang) * rad, sin(ang) * rad * 0.82))
			draw_polyline(pts, Color(1.0, 0.92, 0.7, 0.1 + 0.2 * u_b), 2.0 + 1.5 * u_b, true)
		var cols := [Color("ffd24a"), Color("ffffff"), Color("8fe9ff"), Color("ff9ec4")]
		for i in pack_fx.size():
			var m: Dictionary = pack_fx[i]
			var ang2 := float(m["a0"]) + float(m["w"]) * 0.5 * t * (1.0 + u_b)
			var rad2 := float(m["r0"]) * pk * (1.0 - 0.3 * u_b * u_b)
			var mp := _pack_c() + Vector2(cos(ang2) * rad2, sin(ang2) * rad2 * 0.82)
			var tw := 0.35 + 0.65 * pow(sin(t * 6.0 + float(m["ph"])), 2.0)
			var mc: Color = cols[i % cols.size()]
			draw_circle(mp, float(m["sz"]) * (1.0 + u_b) * 2.4, Color(mc, 0.12 * tw))
			draw_circle(mp, float(m["sz"]) * (1.0 + 0.5 * u_b), Color(mc, 0.85 * tw))
		var amp := 1.0 + 6.0 * u_b * u_b
		var sh := Vector2(sin(t * 63.0), cos(t * 79.0)) * amp
		var ps := lerpf(0.55, 1.0, _spring(t / 0.6, 6.0, 9.0)) * (0.55 if inp else 1.0)
		if album_art:
			var pr := Rect2(_pack_c() + sh - Vector2(255.0, 226.0) * ps, Vector2(510.0, 452.0) * ps)
			_draw_case_pack(pr, {"name": pack["title"], "pick": pick, "show": n}, -1)
		else:
			var gr := Rect2(_pack_c() + sh - Vector2(300.0, 160.0) * ps, Vector2(600.0, 320.0) * ps)
			_cardboard_box(gr, String(pack["title"]), "PICK %d OF %d" % [pick, n])
	var tb := t - D.PACK_BUILD
	if tb > 0.0 and not inp:
		for k in 14:
			var a := k * TAU / 14.0 + tb * 0.4
			var al := clampf(1.0 - tb / 1.0, 0.0, 1.0)
			draw_colored_polygon(PackedVector2Array([_pack_c(), _pack_c() + Vector2.from_angle(a - 0.05) * 1800.0, _pack_c() + Vector2.from_angle(a + 0.05) * 1800.0]), Color(1.0, 0.92, 0.65, 0.08 * al))
		for k in 3:
			var rt := tb - k * 0.1
			if rt > 0.0 and rt < 0.9:
				draw_arc(_pack_c(), rt * 1500.0, 0.0, TAU, 120, Color(1.0, 0.9, 0.55, 0.35 * (1.0 - rt / 0.9)), 8.0 * (1.0 - rt / 0.9) + 2.0, true)
	for k in n:
		var tk0 := _pack_time_item(k)
		if t < tk0:
			continue
		var rar0 := _pack_item_rarity(items[k])
		var rp0: Dictionary = D.PACK_RARITY[rar0]
		var col0 := Color(String(rp0["col"]))
		var pos0 := _pack_item_pos(k, n, albums)
		var u0 := (t - tk0) / D.PACK_ANIM
		var base0 := _pack_base(items[k] is Disc)
		var sc0 := _spring(u0, float(rp0["damp"]), float(rp0["freq"]))
		var beat := 1.0 + float(rp0["pulse"]) * sin(clock * float(rp0["speed"]) + k * 1.7)
		var ramp := clampf(u0 * 2.0, 0.0, 1.0)
		var glow0 := float(rp0["glow"]) * ramp * beat
		if glow0 > 0.0:
			_pack_glow(pos0, maxf(base0.x, base0.y) * 0.5 * (0.85 if inp else 1.0) * maxf(sc0, 0.4) * beat * float(rp0["size"]), col0, glow0)
	for k in n:
		var tk := _pack_time_item(k)
		if t < tk:
			continue
		var it = items[k]
		var rar := _pack_item_rarity(it)
		var rp: Dictionary = D.PACK_RARITY[rar]
		var col := Color(String(rp["col"]))
		var pos := _pack_item_pos(k, n, albums)
		var u := (t - tk) / D.PACK_ANIM
		var sc := _spring(u, float(rp["damp"]), float(rp["freq"]))
		if sc < 0.06:
			continue
		var dbase := _pack_base(it is Disc)
		var base := dbase
		var taken := k in pack_sel
		if u < 0.5:
			var ring := u / 0.5
			draw_arc(pos, maxf(base.x, base.y) * (0.4 + 1.4 * ring), 0.0, TAU, 80, Color(col, 0.3 * (1.0 - ring)), 5.0 * (1.0 - ring) + 1.0, true)
		draw_set_transform(_base_origin() + pos * ui_scale, 0.0, Vector2(ui_scale, ui_scale) * sc)
		if it is Disc:
			_draw_case(Rect2(-Vector2(dbase.x, dbase.x * 0.886) * 0.5, Vector2(dbase.x, dbase.x * 0.886)), it as Disc)
		elif it is String:
			gear_tip_off = true
			_draw_cons_tile(Rect2(-dbase * 0.5, dbase), String(it), false, false)
			gear_tip_off = false
		else:
			gear_tip_off = true
			_draw_gear(Rect2(-dbase * 0.5, dbase), it, 0.0)
			gear_tip_off = false
		draw_set_transform(_base_origin(), 0.0, Vector2(ui_scale, ui_scale))
		var rect := Rect2(pos - base * sc * 0.5, base * sc)
		var tcell := Rect2(pos - base * 0.5, base)
		if sc > 0.7:
			if it is Disc:
				_tip_disc(Rect2(tcell.position, Vector2(base.x, base.x * 0.886)), it as Disc)
			elif it is String:
				_tip(tcell, _tape_tip(String(it)), String(D.CONSUMABLES[String(it)]["rarity"]))
			else:
				_tip_gear(tcell, it)
		if taken:
			draw_rect(rect, Color(0, 0, 0, 0.55))
			_heavy_center(rect, "TAKEN", T_XL, c_gold)
			_panel((_jewel_bounds(rect) if it is Disc else rect).grow(8.0), Color(0, 0, 0, 0), 14, c_gold, 5)
		elif ready:
			var cell := Rect2(pos - base * 0.5, base)
			if it is Disc:
				if cell.has_point(mouse):
					_audition(it as Disc)
			if pack_sel.size() < pick and install_queue.is_empty():
				_hold(cell, "pk%d" % k, "Hold to take", _pack_take.bind(k))
	for f: Dictionary in pack_sparks:
		var fa := clampf(1.0 - float(f["t"]) / float(f["life"]), 0.0, 1.0)
		var fc: Color = f["col"]
		draw_circle(f["p"], float(f["r"]) * 2.4, Color(fc, 0.18 * fa))
		draw_circle(f["p"], float(f["r"]) * fa + 0.5, Color(fc, 0.9 * fa))
	if tb > 0.0 and tb < 0.7:
		var fl := pow(clampf(1.0 - tb / 0.7, 0.0, 1.0), 1.6)
		if inp:
			_panel(pnl, Color(1.0, 0.97, 0.88, fl * 0.35), 8)
		else:
			draw_rect(full, Color(1.0, 0.97, 0.88, fl * 0.35))
	var ta := clampf((t - D.PACK_BUILD - 0.2) / 0.5, 0.0, 1.0)
	var hint := "Place it in a bay above" if not install_queue.is_empty() else "Hold to take  ·  %d of %d taken" % [pack_sel.size(), pick]
	if inp:
		if ready:
			var side := Rect2(pnl.end.x - PACK_SIDE_W - 16.0, pnl.position.y, PACK_SIDE_W, pnl.size.y)
			var cy := side.get_center().y
			if not install_queue.is_empty():
				_text_center(Rect2(side.position.x, cy - 84.0, side.size.x, 30.0), "Place it in", T_XS, Color(1, 1, 1, 0.85), true)
				_text_center(Rect2(side.position.x, cy - 56.0, side.size.x, 30.0), "a bay above", T_XS, Color(1, 1, 1, 0.85), true)
			else:
				_text_center(Rect2(side.position.x, cy - 84.0, side.size.x, 30.0), "Hold to take", T_XS, Color(1, 1, 1, 0.85), true)
				_text_center(Rect2(side.position.x, cy - 56.0, side.size.x, 30.0), "%d of %d taken" % [pack_sel.size(), pick], T_XS, Color(c_gold, 0.9), true)
			_hw_button(Rect2(side.position.x + 10.0, cy - 12.0, side.size.x - 20.0, 64.0), "Skip", _skip_pack, install_queue.is_empty(), Color("6a6f77"), T_MD)
	else:
		if ta > 0.0:
			_heavy_center(Rect2(_pack_cx() - 800.0, 455.0, 1600.0, 80.0), String(pack["title"]).to_upper(), T_XL + 8, Color(c_gold, ta))
		if ready:
			_text_center(Rect2(_pack_cx() - 600.0, 1000.0, 1200.0, 44.0), hint, T_MD, Color(1, 1, 1, 0.85), true)
			_hw_button(Rect2(_pack_cx() - 110.0, 1180.0, 220.0, 92.0), "Skip", _skip_pack, install_queue.is_empty(), Color("6a6f77"), T_LG)

func _toggle_binder() -> void:
	binder_open = not binder_open
	binder_page = 0
	_sfx("page_turn")

func _flip_binder(step: int) -> void:
	var last := maxi(0, (collection.size() - 1) / BINDER_SPREAD)
	var to := clampi(binder_page + step, 0, last)
	if to != binder_page:
		binder_page = to
		_sfx("page_turn")

func _binder_order() -> Array:
	var ids: Array = range(collection.size())
	if sort_key != "":
		ids.sort_custom(func(a, b): return _sort_less(collection[a], collection[b]))
	return ids

func _binder_status(i: int) -> Array:
	if phase != "show":
		return []
	if i in played:
		return ["PLAYED", Color("6a6f77")]
	if i in tray:
		return ["IN CHANGER", Color("3f9b5a")]
	if i in wallet:
		return ["IN HAND", Color("2e6ea6")]
	if i in discard:
		return ["DUG", Color("6a6f77")]
	return []

func _draw_binder_button() -> void:
	var r := Rect2(60.0, 1312.0, 290.0, 84.0)
	if phase == "shop":
		return
	elif phase in ["map", "fork"]:
		r = Rect2(70.0, 1336.0, 340.0, 84.0)
	_hw_button(r, "View binder (%d)" % collection.size(), _toggle_binder, true, C_LEATHER.lightened(0.15), T_MD)

func _draw_binder_overlay() -> void:
	hover_disc = null
	draw_rect(Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600)), Color(0.04, 0.05, 0.07, 0.82))
	_register(Rect2(Vector2(-800, -800), Vector2(UI_W, UI_H) + Vector2(1600, 1600)), func(): pass)
	var b := Rect2((UI_W - 1540.0) * 0.5, 130.0, 1540.0, 960.0)
	_heavy(Vector2(b.position.x, 96.0), "Your Binder", T_XL + 8, Color("f4efe4"))
	var sorted_by := "  ·  sorted by %s" % String(D.SORT_TEXT[sort_key]).to_lower() if sort_key != "" else "  ·  in the order you got them"
	if binder_pick >= 0:
		var bsv: Dictionary = services[binder_pick]
		if String(bsv["kind"]) == "enhance":
			sorted_by = "  ·  pick an album to make %s ($%d)" % [D.EDITIONS[bsv["edition"]]["name"], int(bsv["price"])]
		elif String(bsv["kind"]) == "trade":
			sorted_by = "  ·  pick an album to trade in ($%d)" % int(bsv["price"])
		else:
			sorted_by = "  ·  pick an album to upgrade ($%d)" % int(bsv["price"])
	_text(Vector2(b.position.x + _heavy_w("Your Binder", T_XL + 8) + 24.0, 92.0), "%d albums%s" % [collection.size(), sorted_by], T_MD, Color("b8c0cc"), true)
	_shadow(b, 22, 14.0)
	_surface(b, 22.0, "leather", C_LEATHER.lightened(0.1), C_LEATHER.darkened(0.15), 600.0)
	if _tex("leather") == null:
		_grain(b, 29, 260.0)
	_stitch_rect(b.grow(-12.0), Color("aab3bf", 0.45))
	var spine := Rect2(b.get_center().x - 30.0, b.position.y + 18.0, 60.0, b.size.y - 36.0)
	_grad_panel(spine, 8.0, Color("23262b"), Color("15171a"))
	for k in 3:
		var ry := b.position.y + b.size.y * (0.2 + k * 0.3)
		draw_line(Vector2(spine.position.x - 14.0, ry), Vector2(spine.end.x + 14.0, ry), Color("5f676f"), 9.0)
		draw_line(Vector2(spine.position.x - 14.0, ry), Vector2(spine.end.x + 14.0, ry), Color("c3cad1"), 5.0)
	var order := _binder_order()
	var cell := 204.0
	var gap := 18.0
	for side in 2:
		var page := Rect2(b.position.x + 34.0 if side == 0 else spine.end.x + 18.0, b.position.y + 30.0, spine.position.x - 18.0 - b.position.x - 34.0, b.size.y - 60.0)
		_surface(page, 8.0, "fabric", Color("2a2d33"), Color("1f2227"), 300.0)
		var gx := page.position.x + (page.size.x - (3.0 * cell + 2.0 * gap)) * 0.5
		for k in 9:
			var n := binder_page * BINDER_SPREAD + side * 9 + k
			var r := Rect2(gx + (k % 3) * (cell + gap), page.position.y + 24.0 + (k / 3) * (cell + 44.0), cell, cell)
			var pocket := Rect2(r.position - Vector2(6.0, 6.0), Vector2(r.size.x + 12.0, r.size.y + 14.0))
			_panel(pocket, Color(1, 1, 1, 0.03), 8, Color(1, 1, 1, 0.13), 2)
			_pocket_lip(pocket)
			if n < order.size():
				var i: int = order[n]
				var d := collection[i]
				_draw_jewel(r, d)
				var st := _binder_status(i)
				if not st.is_empty():
					var tw := _text_w(String(st[0]), 13, true) + 18.0
					var tr := Rect2(r.end.x - tw + 4.0, r.position.y - 2.0, tw, 24.0)
					_panel(tr, st[1], 12, Color(1, 1, 1, 0.5), 1)
					_text_center(tr, String(st[0]), 13, Color.WHITE, true)
				if binder_pick >= 0:
					if d.edition != "":
						draw_rect(_jewel_box(r), Color(0, 0, 0, 0.6))
					else:
						if pocket.has_point(mouse):
							_panel(_jewel_box(r).grow(4.0), Color(0, 0, 0, 0), 8, c_gold, 5)
						_register(pocket, _enhance.bind(i))
				if pocket.has_point(mouse):
					hover_disc = d
			_sleeve_gloss(r)
	var pages := maxi(1, (collection.size() + BINDER_SPREAD - 1) / BINDER_SPREAD)
	var ny := b.end.y + 30.0
	_hw_button(Rect2(b.position.x, ny, 220.0, 76.0), "Prev page", _flip_binder.bind(-1), binder_page > 0, Color("3d4148"), T_MD)
	_hw_button(Rect2(b.end.x - 220.0, ny, 220.0, 76.0), "Next page", _flip_binder.bind(1), binder_page < pages - 1, Color("3d4148"), T_MD)
	var first := binder_page * 2 + 1
	_text_center(Rect2(b.position.x, ny, b.size.x, 76.0), "Pages %d–%d of %d   ·   arrow keys flip, Esc closes" % [first, first + 1, pages * 2], T_MD, Color("c9ced6"), true)
	_hw_button(Rect2(b.end.x - 180.0, 40.0, 180.0, 64.0), "Close", _toggle_binder, true, Color("3d4148"), T_MD)

func _edition_marks(c: Vector2, rad: float, e: String) -> void:
	var ed: Dictionary = D.EDITIONS[e]
	var col := Color(ed["color"])
	match e:
		"holo":
			var hues := [Color("ff6ec7"), Color("ffd36e"), Color("6effa0"), Color("6ee7ff"), Color("a78bff"), Color("ff8a6e")]
			for i in hues.size():
				var a0 := clock * 0.4 + i * 0.9
				draw_arc(c, rad * (0.42 + i * 0.095), a0, a0 + 1.6, 24, Color(hues[i], 0.32), rad * 0.08, true)
				draw_arc(c, rad * (0.42 + i * 0.095), a0 + PI, a0 + PI + 1.2, 24, Color(hues[(i + 3) % hues.size()], 0.22), rad * 0.08, true)
		"signed":
			var pts := PackedVector2Array()
			for i in 40:
				var t := i / 39.0
				var x := c.x + rad * (-0.55 + t * 0.95)
				var y := c.y + rad * (0.2 - t * 0.12) + sin(t * TAU * 2.6) * rad * 0.07 + (rad * 0.05 if t < 0.2 else 0.0)
				pts.append(Vector2(x, y))
			draw_polyline(pts, Color(1, 1, 1, 0.55), rad * 0.06, true)
			draw_polyline(pts, Color("15161a"), rad * 0.035, true)
			draw_line(c + Vector2(-rad * 0.5, rad * 0.32), c + Vector2(rad * 0.3, rad * 0.28), Color("15161a"), rad * 0.025, true)
		"limited":
			draw_arc(c, rad - rad * 0.035, 0.0, TAU, 72, Color("e9b949"), rad * 0.06, true)
			draw_arc(c, rad - rad * 0.075, 0.0, TAU, 72, Color(1, 1, 1, 0.5), 1.5, true)
		"remaster":
			draw_arc(c, rad * 0.4, 0.0, TAU, 48, Color(col, 0.85), rad * 0.05, true)
		"mint":
			for p: Vector2 in [Vector2(0.45, -0.3), Vector2(-0.25, 0.55), Vector2(0.62, 0.32)]:
				var sc := c + p * rad
				var s := rad * 0.09
				draw_colored_polygon(PackedVector2Array([sc + Vector2(0, -s), sc + Vector2(s * 0.25, -s * 0.25), sc + Vector2(s, 0), sc + Vector2(s * 0.25, s * 0.25), sc + Vector2(0, s), sc + Vector2(-s * 0.25, s * 0.25), sc + Vector2(-s, 0), sc + Vector2(-s * 0.25, -s * 0.25)]), Color(1, 1, 1, 0.85))
	var fs := maxi(9, int(rad * 0.13))
	var text := String(ed["short"])
	var w := _text_w(text, fs, true) + rad * 0.16
	var h := rad * 0.24
	var tc := c + Vector2(rad * 0.62, -rad * 0.78)
	var pr := Rect2(tc.x - w * 0.5, tc.y - h * 0.5, w, h)
	_panel(Rect2(pr.position + Vector2(0, 2), pr.size), Color(0, 0, 0, 0.4), int(h * 0.5))
	_panel(pr, col, int(h * 0.5), Color(1, 1, 1, 0.75), 1)
	_text_center(pr, text, fs, Color.WHITE, true)

func _draw_services(r: Rect2) -> void:
	for i in services.size():
		var sv: Dictionary = services[i]
		var t := Rect2(r.position.x, r.position.y + i * (GEAR_H + 110.0), COL_W, GEAR_H)
		if bool(sv["sold"]):
			_sold_card(t)
			continue
		var is_pack := bool(sv.get("pack", false))
		var afford := cash >= int(sv["price"]) and (is_pack or consumables.find("") >= 0)
		var hot := ui_live and t.has_point(mouse)
		var tsh := _shake_off("cons%d" % i)
		if is_pack:
			_gear_box(Rect2(t.position - Vector2(0.0, 8.0 if hot else 0.0) + tsh, t.size), "Tape Pack", "PICK 1 OF %d" % D.TAPE_PACK_SHOW)
			_tip(t, "Tape Pack: open it and keep 1 of %d cassettes." % D.TAPE_PACK_SHOW)
		else:
			_draw_cons_tile(Rect2(t.position - Vector2(0.0, 8.0 if hot else 0.0) + tsh, t.size), String(sv["id"]), false, false)
		_hang_tag(Vector2(t.get_center().x, t.end.y + 36.0), "$%d" % int(sv["price"]))
		if ui_live and afford:
			_hold(t, "cons%d" % i, "Hold to buy", _buy_consumable.bind(i))
		elif ui_live:
			_register(t, _deny.bind("cons%d" % i, "" if cash < int(sv["price"]) else "No free cassette slot."))

func _fmt_time(sec: int) -> String:
	return "%d:%02d" % [maxi(0, sec) / 60, maxi(0, sec) % 60]

func _start_show(v: Dictionary) -> void:
	venue = v
	gig_done = false
	wallet.clear()
	for i in D.HAND:
		wallet.append(-1)
	tray.clear()
	readout.clear()
	for i in D.TRAYS:
		tray.append(-1)
		readout.append({})
	draw_pile.clear()
	for i in collection.size():
		draw_pile.append(i)
	_shuffle(draw_pile)
	discard.clear()
	doomed.clear()
	_restore_gear()
	var chal: Dictionary = v.get("challenge", {})
	if String(chal.get("kind", "")) == "gear":
		for g: Dictionary in rack:
			if not g.is_empty() and String(g["id"]) == String(chal.get("gear_id", "")):
				g["broken"] = true
	boss_blocked.clear()
	boss_last_genre = -1
	if String(chal.get("kind", "")) == "engineer":
		var live: Array = []
		for bi in rack.size():
			if not rack[bi].is_empty():
				live.append(bi)
		_shuffle(live)
		var bnames: Array = []
		for bj in mini(_boss_count(), live.size()):
			rack[live[bj]]["broken"] = true
			bnames.append(String(gear_defs[rack[live[bj]]["id"]]["name"]))
		chal["names"] = bnames
	for g: Dictionary in rack:
		if not g.is_empty():
			g["used"] = 0
			g["done"] = false
	turn_n = 1
	bank_in = {}
	crowd_move = {}
	blocked_slot = -1
	move_flash = 0.0
	move_flash_pending = false
	boss_intro_t = 0.0
	if bool(v.get("headliner", false)):
		boss_intro_t = D.BOSS_INTRO_SECS
		_sfx("boss_in")
	done_slots.clear()
	gear_sel = -1
	burn_mode = false
	burn_marks.clear()
	peek_open = false
	consume_mode = ""
	held = -1
	score_tot = 0
	score_live = 0
	turn_pts = 0
	turn_base = 0
	resolving = false
	sel_slot = -1
	set_res = {}
	flow_live = 1.0
	link_log.clear()
	digs = D.BOSS_DIGS if String(chal.get("kind", "")) == "discards" else opt_discards
	tuner_bonus = 0
	_sync_tuner()
	dig_mode = false
	dig_marks.clear()
	booed = false
	show_cash = cash
	_reset_mixes()
	played.clear()
	floats.clear()
	binder_open = false
	binder_pick = -1
	binder_page = 0
	phase = "show"
	stall.clear()
	ch_door = 1.0
	ch_shop = true
	hand_t = 1.0
	hand_hold = true
	hand_after_shop = false
	discard_pending = false
	library_pending = false
	_start_turn()

func _gig_target() -> int:
	var t := float(D.GIG_TARGETS[clampi(gig_n - 1, 0, D.GIG_TARGETS.size() - 1)])
	if venue.get("headliner", false):
		t *= D.HEADLINER_MULT
	if _boss_kind() == "target":
		t *= D.BOSS_TARGET
	return int(round(t))

func _open_slot() -> int:
	return played.size() if resolving and played.size() < tray.size() else -1

func _tag_match(d: Disc, tag: Array) -> bool:
	return _tag_count(d, tag) > 0

func _bay_of(id: String) -> int:
	for k in rack.size():
		if not rack[k].is_empty() and rack[k]["id"] == id and not bool(rack[k].get("broken", false)):
			return k
	return -1

func _has_tag(d: Disc, is_era: bool, v: int) -> int:
	if is_era:
		return 1 if d.era == v else 0
	return 1 if _in_genre(d, v) else 0

func _tag_count(d: Disc, tag: Array) -> int:
	if d.genre < 0:
		return 0
	if tag[0] == "genre":
		return _has_tag(d, false, D.GENRES.find(String(tag[1])))
	return _has_tag(d, true, D.ERAS.find(String(tag[1])))

func _cell_keeps(is_genre: bool, k: int) -> bool:
	return false

func _boss_kind() -> String:
	return String((venue.get("challenge", {}) as Dictionary).get("kind", ""))

func _slot_locked(d: Disc, slot: int) -> bool:
	if _boss_kind() != "slot" or slot < 0:
		return false
	var bc: Dictionary = venue["challenge"]
	return slot == int(bc["slot"]) and not (d.genre == int(bc["genre"]) or d.era == int(bc["era"]))

func _hated_tag(d: Disc) -> String:
	if String(crowd_move.get("kind", "")) != "boo" or bool(crowd_move.get("ignored", false)) or d.genre < 0:
		return ""
	if _tag_count(d, crowd_move["tag"]) > 0:
		return String(crowd_move["tag"][1])
	return ""

func _s_run(st: Dictionary) -> int:
	return int(round(float(int(st["base"]) + int(st["add"])) * float(st["mult"])))

func _s_add(out: Array, st: Dictionary, src: String, text: String, n: int, ci: int = -1) -> void:
	st["add"] = int(st["add"]) + n
	out.append({"src": src, "text": text, "n": n, "ci": ci, "run": _s_run(st)})

func _s_mult(out: Array, st: Dictionary, src: String, text: String, m: float, ci: int = -1) -> void:
	st["mult"] = float(st["mult"]) * m
	out.append({"src": src, "text": text, "n": 1 if m > 1.0 else -1, "ci": ci, "run": _s_run(st), "m": m})

func _cond_count(rule: Dictionary, s: int, ids: Array, prev: Disc, nxt: Disc) -> int:
	var p := String(rule.get("cparam", ""))
	match String(rule.get("condition", "always")):
		"always":
			return 1
		"first":
			return 1 if s == 0 else 0
		"last":
			return 1 if s == ids.size() - 1 else 0
		"next_empty":
			return 1 if s == ids.size() - 1 and ids.size() < D.SETLIST else 0
		"prev_empty":
			return 0
		"per_empty":
			return maxi(0, D.SETLIST - ids.size())
		"odd":
			return 1 if s % 2 == 0 else 0
		"even":
			return 1 if s % 2 == 1 else 0
		"slot1", "slot2", "slot3", "slot4", "slot5", "slot6":
			return 1 if s == int(String(rule.get("condition", "")).substr(4)) - 1 else 0
		"prev_is":
			return 1 if prev != null and _nm_nb(prev, p) else 0
		"next_is":
			return 1 if nxt != null and _nm_nb(nxt, p) else 0
		"per_before":
			var c := 0
			for j in s:
				var dj := _ids_disc(ids, j)
				if dj != null and _name_matches(dj, p):
					c += 1
			return c
		"per_hand":
			var h := 0
			for w in wallet:
				if w >= 0 and _name_matches(collection[w], p):
					h += 1
			return h
	return 0

func _copy_source(ids: Array, s: int) -> Disc:
	var j := s - 1
	while j >= 0:
		var dj := _ids_disc(ids, j)
		if dj == null:
			return null
		var e := String(dj.rule.get("effect", "none"))
		if e == "copy":
			j -= 1
			continue
		return null if e == "none" else dj
	return null

func _fire_rule(rule: Dictionary, src: Disc, s: int, ids: Array, prev: Disc, nxt: Disc, out: Array, st: Dictionary, fx: Dictionary, depth: int) -> bool:
	var eff := String(rule.get("effect", "none"))
	if eff == "none":
		return false
	if eff == "copy":
		var csrc := _copy_source(ids, s)
		if depth == 0 and csrc != null:
			var at := out.size()
			var ok := _fire_rule(csrc.rule, csrc, s, ids, prev, nxt, out, st, fx, 1)
			if ok:
				out.insert(at, {"src": "fx", "text": "Copies %s" % csrc.title, "n": 0, "ci": -1, "run": _s_run(st), "word": "COPY"})
			return ok
		return false
	if not eff in ["points", "mult", "flow_add", "flow_mult", "cash", "consumable"]:
		return false
	var count := _cond_count(rule, s, ids, prev, nxt)
	if count <= 0:
		return false
	var cbs: Array = _card_beats(rule, s, ids) if count > 1 else []
	if cbs.size() != count:
		cbs = []
	if eff == "consumable":
		fx["gen"] = int(fx["gen"]) + 1
		out.append({"src": "fx", "text": "Makes a consumable", "n": 0, "ci": -1, "run": _s_run(st), "word": "+TAPE"})
		return true
	if String(rule.get("target", "self")) == "turn" and eff != "mult":
		var bk: Dictionary = fx["bank"]
		var bper := count if String(rule.get("condition", "")) in ["per_before", "per_hand", "per_empty"] else 1
		var bv := float(rule.get("value", 0.0))
		var bamt := bv * bper
		match eff:
			"points":
				bk["points"] = int(bk["points"]) + int(round(bamt))
			"flow_add":
				bk["flow"] = float(bk["flow"]) + bamt
			"flow_mult":
				bamt = pow(bv, bper)
				bk["fmult"] = float(bk["fmult"]) * bamt
			"cash":
				bk["cash"] = int(bk["cash"]) + int(round(bamt))
		var bword := "+%d NEXT TURN" % int(round(bamt))
		match eff:
			"flow_add":
				bword = "+%s FLOW NEXT TURN" % _ff(bamt)
			"flow_mult":
				bword = "x%s FLOW NEXT TURN" % _ff(bamt)
			"cash":
				bword = "+$%d NEXT TURN" % int(round(bamt))
		out.append({"src": "bank", "text": _rule_line(rule, count, bamt), "n": 0, "ci": -1, "run": _s_run(st), "word": bword})
		return true
	if eff == "cash":
		var per := count if String(rule.get("condition", "")) in ["per_before", "per_hand", "per_empty"] else 1
		var gain := int(round(float(rule.get("value", 0.0)) * per))
		fx["cash"] = int(fx["cash"]) + gain
		out.append({"src": "fx", "text": _rule_line(rule, count, float(gain)), "n": 0, "ci": -1, "run": _s_run(st), "cash": gain})
		_tag_beats(out, cbs)
		return true
	var eb := -1
	var echo := 1.0
	var v := float(rule.get("value", 0.0))
	var tgt := String(rule.get("target", "self"))
	var cmult := count if String(rule.get("condition", "")) in ["per_before", "per_hand", "per_empty"] else 1
	if eff == "flow_add":
		var n := v * cmult * echo
		fx["fl"] = float(fx["fl"]) + n
		out.append({"src": "fx", "text": _rule_line(rule, count, n), "n": 0, "ci": eb, "run": _s_run(st), "flow": float(fx["fl"])})
		_tag_beats(out, cbs)
		return true
	if eff == "flow_mult":
		var m := 1.0 + (v - 1.0) * echo
		m = pow(m, cmult)
		fx["fl"] = float(fx["fl"]) * m
		out.append({"src": "fx", "text": _rule_line(rule, count, m), "n": 0, "ci": eb, "run": _s_run(st), "flow": float(fx["fl"]), "fm": m})
		return true
	var amt := v * cmult if eff == "points" else pow(v, cmult)
	var line := _rule_line(rule, count, amt)
	if tgt == "self":
		if eff == "points":
			_s_add(out, st, "fx", line, int(round(amt)))
			_tag_beats(out, cbs)
		else:
			_s_mult(out, st, "fx", line, amt)
		return true
	var tword := ("+" + _ff(amt)) if eff == "points" else ("x" + _ff(amt))
	out.append({"src": "fx", "text": line, "n": 0, "ci": -1, "run": _s_run(st), "word": tword + (" NEXT SONG" if tgt == "next" else " LATER SONGS")})
	if tgt == "next":
		if s + 1 < ids.size():
			(fx["nextq"] as Array).append({"slot": s + 1, "kind": eff, "value": amt, "title": src.title})
	else:
		var flt := "" if tgt == "later" else String(rule.get("tparam", ""))
		(fx["later"] as Array).append({"from": s, "kind": eff, "value": amt, "filter": flt, "title": src.title})
	return true

func _apply_buff(out: Array, st: Dictionary, q: Dictionary) -> void:
	if String(q["kind"]) == "points":
		_s_add(out, st, "carry", "From %s +%s" % [q["title"], _ff(float(q["value"]))], int(round(float(q["value"]))))
	else:
		_s_mult(out, st, "carry", "From %s x%s" % [q["title"], _ff(float(q["value"]))], float(q["value"]))

func _gear_flow(out: Array, st: Dictionary, fx: Dictionary, text: String, amt: float, ci: int) -> void:
	fx["fl"] = float(fx["fl"]) + amt
	out.append({"src": "fx", "text": text, "n": 0, "ci": ci, "run": _s_run(st), "flow": float(fx["fl"])})

func _gear_cash(out: Array, st: Dictionary, text: String, amt: int, ci: int) -> int:
	out.append({"src": "fx", "text": text, "n": 0, "ci": ci, "run": _s_run(st), "cash": amt})
	return amt

func _rule_applies(r: Dictionary, d: Disc) -> bool:
	match String(r.get("applies", "any")):
		"genre":
			return d.genre >= 0 and _in_genre(d, D.GENRES.find(String(r.get("aparam", ""))))
		"decade":
			return d.era >= 0 and d.era == D.ERAS.find(String(r.get("aparam", "")))
	return true

func _play_size(ids: Array) -> int:
	var n := 0
	for j in ids.size():
		if _ids_disc(ids, j) != null:
			n += 1
	return n

func _rule_requires(r: Dictionary, s: int, ids: Array, prev: Disc, d: Disc) -> bool:
	if d == null and not String(r.get("requires", "none")) in ["none", "full_set", "all_genres_differ", "all_eras_differ", "switch_up", "mirror", "era_ladder", "one_genre", "first_last_genre"]:
		return false
	match String(r.get("requires", "none")):
		"one_genre":
			var og := -1
			var ogn := 0
			for j in ids.size():
				var dg := _ids_disc(ids, j)
				if dg == null:
					continue
				if dg.genre < 0 or (og >= 0 and dg.genre != og):
					return false
				og = dg.genre
				ogn += 1
			return ogn >= maxi(2, int(r.get("rn", 4)))
		"first_last_genre":
			var f0 := _ids_disc(ids, 0)
			var l0 := _ids_disc(ids, ids.size() - 1)
			return ids.size() >= 2 and f0 != null and l0 != null and f0.genre >= 0 and f0.genre == l0.genre
		"between":
			var bg := D.GENRES.find(String(r.get("rparam", "")))
			var ba := _ids_disc(ids, s - 1)
			var bb := _ids_disc(ids, s + 1)
			return ba != null and bb != null and _in_genre(ba, bg) and _in_genre(bb, bg)
		"one_other_same_genre":
			var same := 0
			for j in ids.size():
				var dj4 := _ids_disc(ids, j)
				if j != s and dj4 != null and d.genre >= 0 and dj4.genre == d.genre:
					same += 1
			return same == 1
		"switch_up", "mirror", "era_ladder":
			var seq: Array[Disc] = []
			for j in ids.size():
				var dq := _ids_disc(ids, j)
				if dq != null:
					seq.append(dq)
			var kind := String(r.get("requires", ""))
			if seq.size() < maxi(3, int(r.get("rn", 3))):
				return false
			for j in seq.size():
				if kind == "era_ladder":
					if seq[j].era < 0 or (j > 0 and seq[j].era <= seq[j - 1].era):
						return false
				elif seq[j].genre < 0:
					return false
				elif kind == "switch_up" and j > 0 and seq[j].genre == seq[j - 1].genre:
					return false
				elif kind == "mirror" and seq[j].genre != seq[seq.size() - 1 - j].genre:
					return false
			return true
		"sandwich":
			var a := _ids_disc(ids, s - 1)
			var b := _ids_disc(ids, s + 1)
			return a != null and b != null and a.genre >= 0 and a.genre == b.genre and d.genre != a.genre
		"prev_earlier_era":
			return prev != null and d.era >= 0 and prev.era >= 0 and d.era > prev.era
		"full_set":
			return _play_size(ids) >= D.SETLIST
		"all_genres_differ", "all_eras_differ":
			var by_era := String(r.get("requires", "")) == "all_eras_differ"
			var seen := {}
			var cnt := 0
			for j in ids.size():
				var dj := _ids_disc(ids, j)
				if dj == null:
					continue
				var key := dj.era if by_era else dj.genre
				cnt += 1
				if key < 0 or seen.has(key):
					return false
				seen[key] = true
			return cnt >= maxi(2, int(r.get("rn", 3)))
		"prev_same_era":
			return s > 0 and prev != null and d.era >= 0 and prev.era == d.era
		"prev2_same_genre":
			if s < 2:
				return false
			var p1 := _ids_disc(ids, s - 1)
			var p2 := _ids_disc(ids, s - 2)
			return p1 != null and p2 != null and p1.genre >= 0 and p1.genre == p2.genre
		"last_matches_first":
			if s == 0:
				return false
			var first := _ids_disc(ids, 0)
			if first == null:
				return false
			return (d.genre >= 0 and _in_genre(first, d.genre)) or (d.era >= 0 and first.era == d.era)
		"adjacent":
			var gi := D.GENRES.find(String(r.get("rparam", "")))
			for o in [s - 1, s + 1]:
				var od := _ids_disc(ids, o)
				if od != null and _in_genre(od, gi):
					return true
			return false
		"streak":
			if d.genre < 0:
				return false
			var run := 1
			var k := s - 1
			while k >= 0 and _ids_disc(ids, k) != null and _ids_disc(ids, k).genre == d.genre:
				run += 1
				k -= 1
			return run % maxi(1, int(r.get("rn", 2))) == 0
		"match_back":
			var n := maxi(1, int(r.get("rn", 2)))
			var dn := _ids_disc(ids, s - n)
			return s >= n and dn != null and d.genre >= 0 and _in_genre(dn, d.genre)
	return true

func _rule_count(r: Dictionary, e: Dictionary, d: Disc, s: int, ids: Array, fx: Dictionary = {}) -> int:
	var c := 1
	match String(r.get("per", "none")):
		"units_fired":
			c = 0
			for fk in (fx.get("gf", {}) as Dictionary):
				if int(fk) < int(e["ci"]):
					c += 1
		"earlier_same_genre":
			c = 0
			if d.genre >= 0:
				for j in s:
					var dj2 := _ids_disc(ids, j)
					if dj2 != null and _in_genre(dj2, d.genre):
						c += 1
		"others_in_set":
			var gi := D.GENRES.find(String(r.get("aparam", ""))) if String(r.get("applies", "any")) == "genre" else d.genre
			c = 0
			if gi >= 0:
				for j in ids.size():
					var dj3 := _ids_disc(ids, j)
					if dj3 != null and _in_genre(dj3, gi):
						c += 1
				if _in_genre(d, gi):
					c -= 1
				c = maxi(0, c)
		"units_left":
			c = int(e["left"])
		"unused_discards":
			c = maxi(0, digs)
		"empty_slots":
			c = maxi(0, D.SETLIST - _play_size(ids))
		"base_points":
			c = d.sound
		"stored":
			c = int((e["g"] as Dictionary).get("count", 0))
		"hand_of_genre":
			c = 0
			var hgi := D.GENRES.find(String(r.get("rparam", "")))
			for hw in wallet:
				if hw >= 0 and collection[hw].genre == hgi:
					c += 1
		"earlier_genre", "later_genre":
			c = 0
			var egi := D.GENRES.find(String(r.get("rparam", "")))
			for j in ids.size():
				var de := _ids_disc(ids, j)
				if de != null and de.genre == egi and ((j < s) if String(r.get("per", "")) == "earlier_genre" else (j > s)):
					c += 1
		"genres_in_play":
			var gs := {}
			for j in ids.size():
				var dg := _ids_disc(ids, j)
				if dg != null and dg.genre >= 0:
					gs[dg.genre] = true
			c = gs.size()
		"deck_genre":
			c = 0
			if d.genre >= 0:
				for o: Disc in collection:
					if not o.cdr and o.genre == d.genre:
						c += 1
			c = c / maxi(1, int(r.get("rn", 4)))
		"hand_genres":
			var hc := {}
			for hi in wallet + tray:
				if hi >= 0:
					var hd: Disc = collection[hi]
					if hd.genre >= 0:
						hc[hd.genre] = int(hc.get(hd.genre, 0)) + 1
			c = 0
			for gk in hc:
				if int(hc[gk]) >= maxi(1, int(r.get("rn", 3))):
					c += 1
	var cap := int(r.get("cap", 0))
	if cap > 0:
		c = mini(c, cap)
	return c

func _rule_song(r: Dictionary, e: Dictionary, d: Disc, s: int, ids: Array, prev: Disc, out: Array, st: Dictionary, fx: Dictionary) -> int:
	var when := String(r.get("when", "each"))
	if when in ["gig_start", "gig_end", "turn_end"] or String(r.get("effect", "")) in ["block", "echo"]:
		return 0
	if (when == "first" and s != 0) or (when == "last" and s != ids.size() - 1):
		return 0
	if not _rule_applies(r, d) or not _rule_requires(r, s, ids, prev, d):
		return 0
	if String(r.get("requires", "none")) == "left_fired" and (int(e["lc"]) < 0 or not (fx["gf"] as Dictionary).has(int(e["lc"]))):
		return 0
	var count := _rule_count(r, e, d, s, ids, fx)
	if count <= 0:
		return 0
	var bs: Array = _gear_beats(r, e, d, s, ids, fx) if count > 1 and String(r.get("effect", "points")) in ["points", "flow", "cash"] else []
	if bs.size() != count:
		bs = []
	var m: float = float(e["m"]) * (1.0 + 0.5 * float(int((e["g"] as Dictionary).get("level", 0))))
	var ci: int = e["ci"]
	var amt := float(r.get("amount", 0.0))
	var label := String(r.get("label", ""))
	match String(r.get("effect", "points")):
		"points":
			var v := int(round(amt * count * m))
			_s_add(out, st, "rack", "%s +%d" % [label, v], v, ci)
			_tag_beats(out, bs)
		"mult":
			var lm := 1.0 + (amt - 1.0) * m
			_s_mult(out, st, "rack", "%s x%s" % [label, _ff(lm)], lm, ci)
		"flow":
			var f := amt * count * m
			_gear_flow(out, st, fx, "%s +%s flow" % [label, _ff(f)], f, ci)
			_tag_beats(out, bs)
		"cash":
			var c := int(round(amt * count * m))
			var got := _gear_cash(out, st, "%s +$%d" % [label, c], c, ci)
			_tag_beats(out, bs)
			return got
		"flow_mult":
			var lm2 := 1.0 + (amt - 1.0) * m
			fx["fl"] = float(fx["fl"]) * lm2
			out.append({"src": "rack", "text": "%s flow x%s" % [label, _ff(lm2)], "n": 0, "ci": ci, "run": _s_run(st), "flow": float(fx["fl"]), "fm": lm2})
		"consumable":
			fx["gen"] = int(fx["gen"]) + int(round(amt * count * m))
			out.append({"src": "rack", "text": "%s: consumable" % label, "n": 0, "ci": ci, "run": _s_run(st), "word": "+TAPE"})
		"upgrade":
			var up := int(round(amt * count * m))
			fx["upg"] = int(fx["upg"]) + up
			out.append({"src": "rack", "text": "%s +%d base points" % [label, up], "n": 0, "ci": ci, "run": _s_run(st), "word": "+%d BASE" % up})
	return 0

func _tray_of(fx: Dictionary, s: int) -> int:
	var sl: Array = fx.get("slots", [])
	return int(sl[s]) if s < sl.size() else s

func _echo_count(gm: Dictionary, d: Disc, s: int, ids: Array, prev: Disc, out: Array, st: Dictionary, fx: Dictionary) -> int:
	var n := 0
	for key in gm:
		var e: Dictionary = gm[key]
		var rule: Dictionary = gear_defs[e["id"]].get("rule", {})
		if String(rule.get("effect", "")) != "echo" or _gear_act(e["id"]) != "song" or _tray_of(fx, s) != int(e["ci"]):
			continue
		var rw := String(rule.get("when", "each"))
		if (rw == "first" and s != 0) or (rw == "last" and s != ids.size() - 1):
			continue
		if not _rule_applies(rule, d) or not _rule_requires(rule, s, ids, prev, d):
			continue
		var id: String = e["id"]
		(fx["gf"] as Dictionary)[int(e["ci"])] = true
		n += int(e["m"])
		out.append({"src": "rack", "text": "%s: plays again" % String(rule.get("label", "Echo")), "n": 0, "ci": int(e["ci"]), "run": _s_run(st), "word": "REPLAY"})
	return n

func _rule_gig(when: String, effect: String) -> int:
	var gm := _gear_map()
	var total := 0.0
	for key in gm:
		var e: Dictionary = gm[key]
		var r: Dictionary = gear_defs[e["id"]].get("rule", {})
		if String(r.get("when", "")) != when or String(r.get("effect", "")) != effect:
			continue
		total += float(r.get("amount", 0.0)) * int(e["m"])
	return int(round(total))

func _gear_song(gm: Dictionary, d: Disc, s: int, ids: Array, prev: Disc, hand_g: int, out: Array, st: Dictionary, fx: Dictionary) -> int:
	var cash_gain := 0
	var last := ids.size() - 1
	var here := _tray_of(fx, s)
	for key in gm:
		var e: Dictionary = gm[key]
		var g: Dictionary = e["g"]
		var rule: Dictionary = gear_defs[e["id"]].get("rule", {})
		if rule.is_empty():
			continue
		match _gear_act(e["id"]):
			"song":
				if here != int(e["ci"]):
					continue
			"anywhere":
				if s != last:
					continue
			"gig":
				if here != int(e["ci"]) or bool(g.get("done", false)):
					continue
			_:
				continue
		var n0 := out.size()
		if String(rule.get("effect", "")) == "refire":
			cash_gain += _refire(gm, e, d, s, ids, prev, out, st, fx)
		else:
			cash_gain += _rule_song(rule, e, d, s, ids, prev, out, st, fx)
		if out.size() > n0:
			(fx["gf"] as Dictionary)[int(e["ci"])] = true
	return cash_gain

func _refire(gm: Dictionary, e: Dictionary, d: Disc, s: int, ids: Array, prev: Disc, out: Array, st: Dictionary, fx: Dictionary) -> int:
	var lc := int(e["lc"])
	if lc < 0 or not (fx["gf"] as Dictionary).has(lc) or not gm.has(lc):
		return 0
	var le: Dictionary = gm[lc]
	var lr: Dictionary = gear_defs[le["id"]].get("rule", {})
	if not String(lr.get("effect", "")) in ["points", "mult", "flow", "flow_mult", "cash"]:
		return 0
	var at := out.size()
	var got := _rule_song(lr, le, d, s, ids, prev, out, st, fx)
	if out.size() > at:
		out.insert(at, {"src": "rack", "text": "%s fires %s again" % [String(gear_defs[e["id"]].get("rule", {}).get("label", "Chain")), String(lr.get("label", ""))], "n": 0, "ci": int(e["ci"]), "run": _s_run(st)})
	return got

func _ids_disc(ids: Array, j: int) -> Disc:
	if j < 0 or j >= ids.size() or int(ids[j]) < 0:
		return null
	return collection[int(ids[j])]

func _score_ctx() -> Dictionary:
	var gm := _gear_map()
	var stored := _stored_flow(gm)
	var fl := (1.0 + float(bank_in.get("flow", 0.0)) + stored) * float(bank_in.get("fmult", 1.0))
	if String(crowd_move.get("kind", "")) == "static" and not bool(crowd_move.get("ignored", false)):
		fl = 1.0 + (fl - 1.0) * D.STATIC_KEEP
	return {"fx": {"fl": 1.0, "cash": 0, "nextq": [], "later": [], "upg": 0, "gen": 0, "gf": {}, "bank": {"points": 0, "flow": 0.0, "fmult": 1.0, "cash": 0}}, "req_done": false, "pop_done": false, "gm": gm, "hand_g": 0, "req": _demand_bonus(), "fl": fl, "stored": stored, "total": 0, "carry": int(bank_in.get("points", 0))}

# Name for a CD's own effect, shown as its tooltip heading: "<when> <what>", e.g. "Closing Tips".
# The "when" word is left out for effects that always apply ("Groove").
const EFFECT_WORD := {"points": "Boost", "mult": "Amp", "flow_add": "Groove", "flow_mult": "Surge", "cash": "Tips", "copy": "Sample", "consumable": "Bootleg"}
const COND_WORD := {"first": "Opening", "last": "Closing", "odd": "Offbeat", "even": "Backbeat", "slot1": "Track 1", "slot2": "Track 2", "slot3": "Track 3", "slot4": "Track 4", "prev_is": "Callback", "next_is": "Lead-In", "per_before": "Building", "per_hand": "Backstage", "per_empty": "Echoing", "next_empty": "Fade-Out", "prev_empty": "Cold-Open"}

func _effect_name(d: Disc) -> String:
	var r: Dictionary = d.rule
	var what := String(EFFECT_WORD.get(String(r.get("effect", "none")), "Effect"))
	var when := String(COND_WORD.get(String(r.get("condition", "always")), ""))
	return what if when == "" else "%s %s" % [when, what]

func _trait_name(genre: int) -> String:
	match String(D.GENRES[genre]):
		"Rock":
			return "Streak"
		"Hip-Hop":
			return "Build"
		"Pop":
			return "Crossover"
		"Jazz":
			return "Ascent"
	return ""

func _trait_label(genre: int) -> String:
	var n := _trait_name(genre)
	return "" if n == "" else ("%s %s" % [D.GENRES[genre], n]).to_upper()

func _trait_body(genre: int) -> String:
	match String(D.GENRES[genre]):
		"Rock":
			return "+%s flow if the CD before it is Rock." % _ff(D.TRAIT_ROCK_FLOW)
		"Hip-Hop":
			return "+%d point for each CD played before it." % D.TRAIT_HIPHOP_POINTS
		"Pop":
			return "+$%d the first time each turn it follows a different genre." % D.TRAIT_POP_CASH
		"Jazz":
			return "Banks +%d points for next turn if the CD before it is from an earlier decade." % D.TRAIT_JAZZ_BANK
	return ""

func _trait_text(genre: int) -> String:
	return "%s: %s" % [D.GENRES[genre], _trait_body(genre)]

func _nt(t: String) -> Dictionary:
	return {"t": t}

func _ni(kind: String, col: Color) -> Dictionary:
	return {"i": kind, "c": col}

func _note_genre(p: String) -> Dictionary:
	var gi := D.GENRES.find(p)
	if gi >= 0:
		return _ni("g%d" % gi, Color(D.SLEEVE_MAIN[gi]))
	var ei := D.ERAS.find(p)
	if ei >= 0:
		return _ni("e%d" % ei, Color("3b362c"))
	return _nt(p)

func _note_tokens(d: Disc) -> Array:
	if d.cdr and d.genre < 0:
		return [_nt("Becomes a random album")]
	var r: Dictionary = d.rule
	var eff := String(r.get("effect", "none"))
	if eff == "none":
		return []
	if eff == "copy":
		return [_nt("Copies the song before it")]
	var v := _ff(float(r.get("value", 0.0)))
	var p := String(r.get("cparam", ""))
	var tp := String(r.get("tparam", ""))
	var green := Color(D.SOUND_COLOR).darkened(0.1)
	var purple := Color(D.ENERGY_COLOR)
	var out: Array = []
	match String(r.get("condition", "always")):
		"first":
			out.append(_nt("Played first, "))
		"last":
			out.append(_nt("Played last, "))
		"next_empty":
			out.append(_nt("Next slot empty, "))
		"prev_empty":
			out.append(_nt("Previous slot empty, "))
		"per_empty":
			out.append(_nt("Per empty slot, "))
		"odd":
			out.append(_nt("Odd slot, "))
		"even":
			out.append(_nt("Even slot, "))
		"slot1", "slot2", "slot3", "slot4", "slot5", "slot6":
			out.append(_nt("Slot %s, " % String(r.get("condition", "")).substr(4)))
		"prev_is":
			out.append(_nt("After "))
			out.append(_note_genre(p))
			out.append(_nt(", "))
		"next_is":
			out.append(_nt("Before "))
			out.append(_note_genre(p))
			out.append(_nt(", "))
		"per_before":
			out.append(_nt("Per "))
			out.append(_note_genre(p))
			out.append(_nt(" before it, "))
		"per_hand":
			out.append(_nt("Per "))
			out.append(_note_genre(p))
			out.append(_nt(" in hand, "))
	var scoring := eff in ["points", "mult"]
	match String(r.get("target", "self")):
		"next":
			out.append(_nt("Next song gets " if scoring else "Next song: "))
		"later":
			out.append(_nt("Later songs get " if scoring else "Later songs: "))
		"later_genre", "later_decade":
			out.append(_nt("Later "))
			out.append(_note_genre(tp))
			out.append(_nt(" songs get " if scoring else " songs: "))
		"turn":
			out.append(_nt("Next turn: "))
	match eff:
		"points":
			out.append(_nt("+%s " % v))
			out.append(_ni("note", green))
		"mult":
			out.append(_nt("x%s " % v))
			out.append(_ni("note", green))
		"flow_add":
			out.append(_nt("+%s " % v))
			out.append(_ni("wave", purple))
		"flow_mult":
			out.append(_nt("x%s " % v))
			out.append(_ni("wave", purple))
		"cash":
			out.append(_nt("+$%s" % v))
		"consumable":
			out.append(_nt("Makes a cassette"))
	if not out.is_empty() and out[0].has("t"):
		var f0 := String(out[0]["t"])
		out[0] = _nt(f0.left(1).to_upper() + f0.substr(1))
	return out

func _draw_note(cr: Rect2, k: float, toks: Array, dim: float) -> void:
	var phi := 1.618034
	var pw := cr.size.x * 0.88
	var ph := pw / (phi * phi * phi)
	var over := ph * 0.236068
	var r := Rect2(cr.get_center().x - pw * 0.5, cr.end.y + over - ph, pw, ph)
	var rad := int(round(3.0 * k))
	_panel(Rect2(r.position + Vector2(0.0, 5.0 * k), r.size), Color(0, 0, 0, 0.10), rad + 2)
	_panel(Rect2(r.position + Vector2(0.0, 2.5 * k), r.size), Color(0, 0, 0, 0.14), rad + 1)
	_panel(Rect2(r.position + Vector2(0.0, 1.0 * k), r.size), Color(0, 0, 0, 0.18), rad)
	_panel(r, Color("f6efdb").darkened(dim * 0.7), rad)
	var padx := ph * 0.3
	var avail := pw - padx * 2.0
	var fs := int(ph * 0.4)
	var total := 0.0
	while true:
		total = 0.0
		for tk: Dictionary in toks:
			total += _text_w(String(tk["t"]), fs, true) if tk.has("t") else fs * 1.15
		if total <= avail or fs <= 8:
			break
		fs -= 1
	var f := _f(true)
	var x := r.get_center().x - total * 0.5
	var cy := r.get_center().y
	var ink := Color("3b362c").lightened(dim * 0.2)
	for tk: Dictionary in toks:
		if tk.has("t"):
			var ts := String(tk["t"])
			_text(Vector2(x, cy + _vc(f, fs)), ts, fs, ink, true)
			x += _text_w(ts, fs, true)
		else:
			var ic := fs * 1.15
			_icon(String(tk["i"]), Vector2(x + ic * 0.5, cy), ic * 0.9, Color(tk["c"]).darkened(dim * 0.5))
			x += ic
func _genre_trait(d: Disc, s: int, prev: Disc, out: Array, st: Dictionary, fx: Dictionary, ctx: Dictionary) -> int:
	match String(D.GENRES[d.genre]):
		"Rock":
			if prev != null and prev.genre == d.genre:
				var f: float = D.TRAIT_ROCK_FLOW
				fx["tf"] = true
				fx["fl"] = float(fx["fl"]) + f
				out.append({"src": "fx", "text": "Rock streak +%s flow" % _ff(f), "n": 0, "ci": -1, "run": _s_run(st), "flow": float(fx["fl"])})
		"Hip-Hop":
			if s > 0:
				fx["tf"] = true
				var n: int = s * D.TRAIT_HIPHOP_POINTS
				_s_add(out, st, "fx", "Hip-Hop: %d before it +%d" % [s, n], n)
		"Pop":
			if prev != null and prev.genre >= 0 and prev.genre != d.genre and not bool(ctx["pop_done"]):
				ctx["pop_done"] = true
				fx["tf"] = true
				var c: int = D.TRAIT_POP_CASH
				out.append({"src": "fx", "text": "Pop crossover +$%d" % c, "n": 0, "ci": -1, "run": _s_run(st), "cash": c})
				return c
		"Jazz":
			if prev != null and prev.era >= 0 and d.era >= 0 and d.era > prev.era:
				fx["tf"] = true
				var b: int = D.TRAIT_JAZZ_BANK
				var bk: Dictionary = fx["bank"]
				bk["points"] = int(bk["points"]) + b
				out.append({"src": "bank", "text": "Jazz: +%d points next turn" % b, "n": 0, "ci": -1, "run": _s_run(st), "word": "+%d NEXT TURN" % b})
	return 0

func _score_slot(s: int, ids: Array, ctx: Dictionary) -> Dictionary:
	var gm: Dictionary = ctx["gm"]
	var fx: Dictionary = ctx["fx"]
	var fl: float = ctx["fl"]
	var hand_g: int = ctx["hand_g"]
	var req: int = ctx["req"]
	var d: Disc = collection[int(ids[s])]
	var prev: Disc = _ids_disc(ids, s - 1)
	var nxt: Disc = _ids_disc(ids, s + 1)
	var st := {"base": d.sound, "add": 0, "mult": 1.0}
	var out: Array = [{"src": "base", "text": "Points %d" % d.sound, "n": d.sound, "ci": -1, "run": d.sound}]
	var fired := false
	var cash_gain := 0
	var fl_start := fl
	fx["fl"] = fl
	fx["cash"] = 0
	fx["upg"] = 0
	fx["gen"] = 0
	fx["tf"] = false
	for q: Dictionary in fx["nextq"]:
		if int(q["slot"]) == s:
			_apply_buff(out, st, q)
			fired = true
	for q: Dictionary in fx["later"]:
		if int(q["from"]) < s and (String(q["filter"]) == "" or _name_matches(d, String(q["filter"]))):
			_apply_buff(out, st, q)
			fired = true
	var reps := 1
	if not d.cdr:
		reps = 1 + _echo_count(gm, d, s, ids, prev, out, st, fx)
		for rp in reps:
			if rp > 0:
				_s_add(out, st, "rack", "Plays again: points +%d" % d.sound, d.sound)
			var ef0 := out.size()
			if _fire_rule(d.rule, d, s, ids, prev, nxt, out, st, fx, 0):
				fired = true
				_tag_effect(out, ef0, _effect_name(d))
		cash_gain += int(fx["cash"])
	if not d.cdr and d.genre >= 0:
		for rp in reps:
			var tr0 := out.size()
			cash_gain += _genre_trait(d, s, prev, out, st, fx, ctx)
			_tag_effect(out, tr0, "%s %s" % [D.GENRES[d.genre], _trait_name(d.genre)])
		if bool(fx["tf"]):
			fired = true
	for rp in reps:
		match d.edition:
			"holo", "signed", "limited":
				var en := int(D.EDITIONS[d.edition]["n"])
				_s_add(out, st, "disc", "%s +%d" % [D.EDITIONS[d.edition]["name"], en], en)
			"mint":
				cash_gain += int(D.EDITIONS["mint"]["n"])
	cash_gain += _gear_song(gm, d, s, ids, prev, hand_g, out, st, fx)
	var ht := _hated_tag(d)
	if ht != "":
		if _boss_kind() == "hates":
			_s_mult(out, st, "taste", "Boo: no points", 0.0)
		else:
			_s_mult(out, st, "taste", "Booed %s x%s" % [ht, str(D.HATE_MULT)], D.HATE_MULT)
	if not bool(ctx["req_done"]) and String(crowd_move.get("kind", "")) == "demand" and _tag_match(d, crowd_move["tag"]):
		ctx["req_done"] = true
		if req > 0:
			_s_add(out, st, "call", "Demand met +%d" % req, req)
	var bc: Dictionary = venue.get("challenge", {})
	var bdc := 0
	if _boss_kind() == "genre":
		bdc = _has_tag(d, false, int(bc.get("genre", -2)))
	elif _boss_kind() == "era":
		bdc = _has_tag(d, true, int(bc.get("era", -2)))
	elif _boss_kind() == "purist" and d.genre >= 0 and d.genre != int(bc.get("genre", -2)):
		bdc = 1
	elif _boss_kind() == "critic" and d.genre >= 0 and d.genre == boss_last_genre:
		bdc = 1
	if bdc > 0:
		if _boss_kind() == "purist":
			_s_mult(out, st, "boss", "Purist x%s" % _ff(_boss_mult()), _boss_mult())
		else:
			_s_mult(out, st, "boss", "Boss debuff x%s" % _ff(_boss_mult()), _boss_mult())
	if _slot_locked(d, s):
		_s_mult(out, st, "boss", "Slot locked: no points", 0.0)
	var song := _s_run(st)
	var fl_mul := float(fx["fl"])
	if absf(fl_mul - fl_start) > 0.001:
		fired = true
	ctx["fl"] = fl_mul
	ctx["total"] = int(ctx["total"]) + song
	return {"score": song, "song": song, "steps": out, "fired": fired, "cash": cash_gain, "upgrade": int(fx["upg"]), "gen": int(fx["gen"]), "flow_start": fl_start, "flow_mul": fl_mul}

func _score_set(ids: Array, tray_slots: Array = []) -> Dictionary:
	var ctx := _score_ctx()
	var slots: Array = []
	var tsl: Array = tray_slots
	if tsl.is_empty():
		for s in ids.size():
			tsl.append(s)
	(ctx["fx"] as Dictionary)["slots"] = tsl
	for s in ids.size():
		slots.append(_score_slot(s, ids, ctx))
	var pts := int(ctx["total"]) + int(ctx["carry"])
	var fl := float(ctx["fl"])
	var tcash := 0
	return {"turn_cash": tcash, "slots": slots, "total": int(round(float(pts) * fl)), "pts": pts, "carry": int(ctx["carry"]), "finale_flow": fl, "stored": float(ctx["stored"]), "bank": (ctx["fx"] as Dictionary)["bank"]}

func _play() -> void:
	if not _can_play():
		return
	var sl := _setlist()
	play_ids = sl[0]
	play_slots = sl[1]
	for t in play_ids:
		var m: Disc = collection[t]
		if m.cdr and m.genre < 0:
			_resolve_mix(m)
	set_res = _score_set(play_ids, play_slots)
	resolving = true
	sel_slot = -1
	played.clear()
	turn_base = int(set_res["carry"])
	turn_pts = turn_base
	link_log.clear()
	done_slots.clear()
	turn_dmg = 0
	move_met = false
	skip_on = false
	combo_n = 0
	_plan_pacing()
	if String(crowd_move.get("kind", "")) == "static" and not bool(crowd_move.get("ignored", false)):
		_sc_sfx("scratch", 0.8, 0.0)
	_start_slot(_next_filled(-1))

func _slot_events(s: int) -> int:
	var r: Dictionary = (set_res["slots"] as Array)[play_slots.find(s)]
	return _expand_beats(r["steps"] as Array, float(r["flow_start"])).size() + (1 if collection[tray[s]].cdr else 0)

func _plan_pacing() -> void:
	chain_i = 0
	chain_n = 0
	for s in play_slots:
		chain_n += _slot_events(int(s))
	turn_pace = 1.0
	var mags: Array = []
	for ms in play_slots:
		var rr: Dictionary = (set_res["slots"] as Array)[play_slots.find(ms)]
		var pr := 0
		var pf := float(rr["flow_start"])
		for st0 in (rr["steps"] as Array):
			var sd: Dictionary = st0
			var dl := int(sd["run"]) - pr
			pr = int(sd["run"])
			if dl != 0:
				mags.append(_mag_pts(float(dl)))
			if sd.has("flow"):
				var df := absf(float(sd["flow"]) - pf)
				pf = float(sd["flow"])
				if df > 0.0001:
					mags.append(clampf(df / 1.5, 0.1, 1.3))
	mags.sort()
	mags.reverse()
	top_mag = float(mags[mini(1, mags.size() - 1)]) if not mags.is_empty() else 99.0
	var est := 0.0
	var k := 0
	for s in play_slots:
		var n := _slot_events(int(s))
		var dur := D.SONG_START
		for j in n:
			dur += _chain_step_raw(k)
			k += 1
		dur = maxf(dur + D.SONG_TAIL, _hook_len(n, int(s) == int(play_slots.back())))
		est += dur
	var cap := D.TURN_MAX_SECS * _anim() / float(D.ANIM_SCALE[1])
	var fin := (D.FIN_WIND + D.FIN_STREAM + D.FIN_HOLD) * _anim()
	var songs := est * _anim()
	if songs + fin > cap:
		turn_pace = clampf((cap - fin) / songs, 0.35, 1.0)

func _chain_step_raw(i: int) -> float:
	var u := clampf(float(i) / float(maxi(1, chain_n - 1)), 0.0, 1.0)
	return lerpf(D.CHAIN_STEP_FIRST, D.CHAIN_STEP_LAST, u)

func _chain_step() -> float:
	return _chain_step_raw(chain_i) * _anim() * turn_pace

func _hook_len(events: int, last: bool) -> float:
	return clampf(D.HOOK_BASE + D.HOOK_PER_EVENT * events, D.HOOK_BASE, D.HOOK_MAX) + (D.HOOK_LAST_BONUS if last else 0.0)

func _skip_scoring() -> void:
	if not resolving or skip_on:
		return
	skip_on = true
	_sc_sfx("whoosh", 0.4, 0.0)

func _next_filled(after: int) -> int:
	for k in range(after + 1, D.TRAYS):
		if tray[k] >= 0:
			return k
	return -1

func _start_slot(s: int) -> void:
	var d := collection[tray[s]]
	result = (set_res["slots"] as Array)[play_slots.find(s)]
	flow_live = float(result["flow_start"])
	steps = _expand_beats(result["steps"] as Array, float(result["flow_start"]))
	if d.cdr:
		steps.push_front({"src": "mix", "text": "Mix: %s, %s" % [D.GENRES[d.genre], D.ERAS[d.era]], "n": 0, "ci": -1, "word": "MIX %s %s" % [D.GENRES[d.genre], D.ERAS[d.era]]})
	song_slot = s
	now_slot = s
	slot_flash[s] = 1.0
	tray_punch[s] = 1.0
	readout[s] = {"text": "0", "pts": 0, "fl": 0.0}
	step_i = 0
	song_cash = 0
	step_t = D.SONG_START * _anim() * turn_pace
	slot_elapsed = 0.0
	slot_last = s == int(play_slots.back())
	slot_hook = _hook_len(steps.size(), slot_last) * _anim() * turn_pace
	eq_prev_run = 0
	rec_pop = 1.0
	playing = true
	song_muffled = _hated_tag(d) != ""
	if not done_slots.is_empty():
		_sc_sfx("scratch" if rng.randf() < 0.5 else "whoosh", 0.5, 0.0)
	else:
		_sfx("click")
	_music_start(d)
	music_t = 999.0

func _play_step(st: Dictionary) -> void:
	ev_pts = 0
	ev_flow = 0.0
	var n := int(st["n"])
	var ro: Dictionary = readout[song_slot]
	var src := String(st["src"])
	if st.has("cash"):
		song_cash += int(st["cash"])
		_cash_fx(int(st["cash"]), song_slot)
		var cpos := _bay_rect(int(st["ci"])).get_center() if int(st["ci"]) >= 0 else _case_rect(song_slot).get_center()
		_spawn_pop(cpos, "+$%d" % int(st["cash"]), Color("ffd96a"), 0.4, "")
	if st.has("flow"):
		var dfl := float(st["flow"]) - flow_live
		ev_flow = dfl
		flow_live = float(st["flow"])
		flow_pulse = 1.0
		ro["fl"] = float(ro.get("fl", 0.0)) + dfl
		slot_flash[song_slot] = 0.8
		rec_pop = 0.7
		_kick_eq(0.4, true)
		_tick()
	if st.has("run"):
		var rv := int(st["run"])
		if rv != eq_prev_run:
			pts_pulse = 1.0
			slot_flash[song_slot] = 0.8
			rec_pop = 0.7
			if not st.has("flow"):
				_tick()
		var dl := absi(rv - eq_prev_run)
		ev_pts = rv - eq_prev_run
		eq_prev_run = rv
		turn_pts = turn_base + rv
		ro["net"] = rv
		_kick_eq(clampf(float(dl) / maxf(8.0, float(_gig_target()) * 0.12), 0.2, 1.0), src in ["fx", "carry"])
		ro["text"] = _fmt_int(rv)
	if int(st["ci"]) >= 0:
		comp_flash[int(st["ci"])] = 1.0
	_event_juice(st, n, src)

func _finish_song() -> void:
	playing = false
	song_muffled = false
	if not slot_last:
		_music_stop()
	var s := song_slot
	var i := tray[s]
	var d := collection[i]
	var got := int(result["score"])
	turn_base += got
	turn_pts = turn_base
	played.append(i)
	if String(crowd_move.get("kind", "")) == "demand" and _tag_match(d, crowd_move["tag"]):
		move_met = true
	for ci in rack.size():
		var ru: Dictionary = rack[ci]
		if ru.is_empty() or bool(ru.get("broken", false)):
			continue
		if _gear_act(String(ru["id"])) == "gig" and ci == s:
			ru["done"] = true
	if _boss_kind() == "destroy" and rng.randf() < D.BOSS_DESTROY:
		doomed.append(d)
		_say("%s is scratched beyond repair." % d.title)
	var extra := int(result["cash"]) - song_cash
	if extra > 0:
		_cash_fx(extra, s)
		_spawn_pop(_case_rect(s).get_center(), "+$%d" % extra, Color("ffd96a"), 0.4, "")
	for gk in int(result.get("gen", 0)):
		if not _give_consumable():
			_say("Tape slots are full.")
	var upg := int(result.get("upgrade", 0))
	if upg > 0:
		d.sound += upg
		_spawn_pop(_case_rect(s).get_center(), "+%d BASE" % upg, c_gold, 0.4, "")
	readout[s] = {"text": "+%s" % _fmt_int(got), "net": got, "fl": float(result["flow_mul"]) - float(result["flow_start"])}
	now_slot = -1
	song_slot = -1
	done_slots.append(s)
	var nx := _next_filled(s)
	if nx >= 0:
		_start_slot(nx)
	else:
		_start_finale()

func _grow_gear() -> void:
	for ci in rack.size():
		var ru: Dictionary = rack[ci]
		if ru.is_empty() or bool(ru.get("broken", false)) or not ru.has("count") or not (ci in play_slots):
			continue
		var rl: Dictionary = gear_defs[ru["id"]].get("rule", {})
		var amt := int(rl.get("gamt", 1))
		match String(rl.get("grow", "")):
			"play":
				ru["count"] = int(ru["count"]) + amt
			"decade":
				var ei := D.ERAS.find(String(rl.get("gparam", "")))
				for i in play_ids:
					if collection[i].era == ei:
						ru["count"] = int(ru["count"]) + amt
			"genre":
				var gi := D.GENRES.find(String(rl.get("gparam", "")))
				for i in play_ids:
					if collection[i].genre == gi:
						ru["count"] = int(ru["count"]) + amt

func _start_finale() -> void:
	_grow_gear()
	finale_flow = float(set_res["finale_flow"])
	var gain := int(round(float(turn_base) * finale_flow))
	turn_dmg = gain
	fin_from = score_tot
	fin_to = score_tot + gain
	fin_boomed = false
	fin_riser = false
	fin_accum = 0.0
	fin_tick_t = 0.0
	fin_t = 0.0
	resolving = true

func _move_tag(from_hand: bool) -> Array:
	var pool: Array = []
	for i in (wallet if from_hand else wallet + draw_pile):
		if i >= 0 and collection[i].genre >= 0:
			pool.append(collection[i])
	if pool.is_empty():
		return ["genre", D.GENRES[rng.randi_range(0, D.GENRES.size() - 1)]]
	var d: Disc = pool[rng.randi_range(0, pool.size() - 1)]
	return ["genre", D.GENRES[d.genre]] if rng.randf() < 0.6 else ["era", D.ERAS[d.era]]

func _roll_move() -> void:
	blocked_slot = -1
	if not D.CROWD_MOVES or not bool(venue.get("headliner", false)):
		crowd_move = {}
		return
	var total := 0
	for k in D.MOVE_WEIGHTS:
		total += int(D.MOVE_WEIGHTS[k])
	var r := rng.randi_range(0, total - 1)
	var kind := "cool"
	for k in D.MOVE_WEIGHTS:
		r -= int(D.MOVE_WEIGHTS[k])
		if r < 0:
			kind = String(k)
			break
	var tgt := _gig_target()
	crowd_move = {"kind": kind}
	match kind:
		"cool":
			crowd_move["need"] = int(round(tgt * D.COOL_NEED))
			crowd_move["heal"] = int(round(tgt * D.COOL_HEAL))
		"boo":
			crowd_move["tag"] = _move_tag(true)
		"demand":
			crowd_move["tag"] = _move_tag(false)
			crowd_move["heal"] = int(round(tgt * D.DEMAND_HEAL))
		"block":
			blocked_slot = rng.randi_range(0, D.TRAYS - 1)
			crowd_move["slot"] = blocked_slot
	_refresh_move()
	_flag_move_change()

# Highlight the boss ability row and play the alert. While the boss intro is still on screen,
# wait for it to clear so the two don't land on top of each other.
func _flag_move_change() -> void:
	if boss_intro_t > 0.0:
		move_flash_pending = true
		return
	move_flash = D.MOVE_FLASH_SECS
	_sfx("boss_move")

func _move_title() -> String:
	match String(crowd_move.get("kind", "")):
		"cool":
			return "The crowd cools off"
		"boo":
			return "Boo %s" % String(crowd_move["tag"][1])
		"demand":
			return "Wants %s" % String(crowd_move["tag"][1])
		"static":
			return "Static on the line"
		"block":
			return "A heckler takes tray %d" % (int(crowd_move["slot"]) + 1)
	return ""

func _move_desc() -> String:
	if bool(crowd_move.get("ignored", false)):
		return "%s cancels it." % String(crowd_move.get("by", "Your gear"))
	match String(crowd_move.get("kind", "")):
		"cool":
			return "Deal %s points this turn or the crowd wins back %s." % [_fmt_int(int(crowd_move["need"])), _fmt_int(int(crowd_move["heal"]))]
		"boo":
			return "%s songs score half this turn." % String(crowd_move["tag"][1])
		"demand":
			return "Play a %s song or the crowd wins back %s." % [String(crowd_move["tag"][1]), _fmt_int(int(crowd_move["heal"]))]
		"static":
			return "Your flow is cut in half before this turn plays."
		"block":
			return "You cannot use that tray, and its gear is off, this turn."
	return ""

func _start_turn() -> void:
	for k in D.TRAYS:
		tray[k] = -1
		readout[k] = {}
	done_slots.clear()
	sel_slot = -1
	turn_dmg = 0
	move_met = false
	_refill()
	_apply_sort()
	_roll_move()
	_roll_boss_blocks()
	if bool(venue.get("headliner", false)) and crowd_move.is_empty() and (turn_n == 1 or _boss_kind() in ["heckler", "critic"]):
		_flag_move_change()
	flow_live = float(_score_ctx()["fl"])
	turn_base = int(bank_in.get("points", 0))
	turn_pts = turn_base
	var carried := ""
	if turn_n > 1 and D.TURN_ALLOWANCE > 0:
		_cash_fx(D.TURN_ALLOWANCE, -1)
	var bc := int(bank_in.get("cash", 0))
	if bc > 0:
		_cash_fx(bc, -1)
	if not bank_in.is_empty():
		var parts: Array[String] = []
		if turn_base > 0:
			parts.append("+%s points" % _fmt_int(turn_base))
		if float(bank_in.get("flow", 0.0)) > 0.0:
			parts.append("+%s flow" % _ff(float(bank_in["flow"])))
		if float(bank_in.get("fmult", 1.0)) > 1.0:
			parts.append("flow x%s" % _ff(float(bank_in["fmult"])))
		if bc > 0:
			parts.append("+$%d" % bc)
		if not parts.is_empty():
			carried = " Carried over: %s." % ", ".join(parts)
	if carried != "":
		_say("Turn %d of %d.%s" % [turn_n, D.TURNS, carried])
	else:
		message_t = 0.0
	shop_open = true
	stall.clear()
	_stall_refresh()

func _end_turn() -> void:
	resolving = false
	skip_on = false
	song_drop = false
	pops.clear()
	if _boss_kind() == "critic" and not play_ids.is_empty():
		var cnt := {}
		for pi in play_ids:
			var gg: int = collection[pi].genre
			cnt[gg] = int(cnt.get(gg, 0)) + 1
		var best := -1
		var bn := 0
		for gk in cnt:
			if int(cnt[gk]) > bn:
				bn = int(cnt[gk])
				best = int(gk)
		boss_last_genre = best
	var tc := int(set_res.get("turn_cash", 0))
	if tc > 0:
		_cash_fx(tc, -1)
	var heal := 0
	var kind := String(crowd_move.get("kind", ""))
	var ign := bool(crowd_move.get("ignored", false))
	if kind == "cool" and not ign and turn_dmg < int(crowd_move["need"]):
		heal = int(crowd_move["heal"])
	elif kind == "demand" and not ign and not move_met:
		heal = int(crowd_move["heal"])
	if heal > 0:
		score_tot = maxi(0, score_tot - heal)
		score_live = score_tot
	bank_in = (set_res.get("bank", {}) as Dictionary).duplicate()
	for k in D.TRAYS:
		if tray[k] >= 0:
			discard.append(tray[k])
			tray[k] = -1
	now_slot = -1
	if score_tot >= _gig_target() or turn_n >= D.TURNS:
		gig_done = true
		_end_show()
		return
	turn_n += 1
	_start_turn()
	if heal > 0:
		_say("The crowd won back %s points. Turn %d: %s." % [_fmt_int(heal), turn_n, _move_title()])

func _restore_gear() -> void:
	for g: Dictionary in rack:
		if not g.is_empty():
			g["broken"] = false

func _sync_tuner() -> void:
	var nb := _rule_gig("gig_start", "discards")
	digs += nb - tuner_bonus
	tuner_bonus = nb

func _burn_doomed() -> void:
	for d: Disc in doomed:
		collection.erase(d)
	doomed.clear()

func _end_show() -> void:
	shop_open = false
	_restore_gear()
	_return_held()
	playing = false
	_music_stop()
	dig_mode = false
	dig_marks.clear()
	booed = score_tot < _gig_target()
	var ratio := float(score_tot) / float(_gig_target())
	var gear_pay := _rule_gig("gig_end", "cash")
	for pg: Dictionary in rack:
		if not pg.is_empty() and String(pg["id"]) == "piggy":
			pg["pot"] = int(pg["pot"]) + int(_gp("piggy", "cash"))
	var turns_left := (maxi(0, D.TURNS - turn_n) * D.PAY_TURN) if not booed else 0
	var unused := (maxi(0, digs) * D.PAY_DISCARD) if not booed else 0
	for rg: Dictionary in rack:
		if not rg.is_empty() and String(rg["id"]) == "royalty_check":
			gear_pay += _royalty(rg)
	reward = {"turns": turns_left, "discards": unused, "mint": cash - show_cash, "gear": gear_pay}
	cash += turns_left + unused + gear_pay
	phase = "end"

func _draw_show_end() -> void:
	var r := _modal_panel(900.0, 680.0)
	var final := _is_final()
	var ratio := float(score_tot) / float(_gig_target())
	var title := "Booed off stage" if booed else ("Encore!" if ratio >= D.TIER_GREAT else ("Big applause" if ratio >= D.TIER_GOOD else "Target cleared"))
	if final and not booed:
		title = "Final boss beaten!"
	_heavy_center(Rect2(r.position.x, r.position.y + 40.0, r.size.x, 90.0), title, T_HERO, c_good if not booed else c_bad)
	_text_center(Rect2(r.position.x, r.position.y + 140.0, r.size.x, 40.0), "%s: %s of %s points" % [venue["name"], _fmt_int(score_tot), _fmt_int(_gig_target())], T_LG, c_ink, true)
	var sub := "The tour ends here." if booed else ("You won over all %d crowds." % gig_n if final else ("You beat the boss." if bool(venue.get("headliner", false)) else "turn %d of %d · final score %s" % [turn_n, D.TURNS, _fmt_int(score_tot)]))
	_text_center(Rect2(r.position.x, r.position.y + 186.0, r.size.x, 40.0), sub, T_MD, c_body)
	var x := r.position.x + 220.0
	var w := r.size.x - 440.0
	var y := r.position.y + 262.0
	var rows := [["Turns left", int(reward["turns"])], ["Unused discards", int(reward["discards"])], ["Gear", int(reward.get("gear", 0))]]
	for k in rows.size():
		_text(Vector2(x, y + k * 44.0), String(rows[k][0]), T_MD, c_muted, true)
		_heavy_right(x + w, y + k * 44.0, "$%d" % int(rows[k][1]), T_LG, c_ink)
	if int(reward["mint"]) > 0:
		_text(Vector2(x + w + 30.0, y), "+$%d mint" % int(reward["mint"]), T_SM, c_good, true)
	draw_line(Vector2(x, y + 150.0), Vector2(x + w, y + 150.0), Color(c_ink, 0.2), 2.0)
	_text(Vector2(x, y + 206.0), "Cash", T_MD, c_muted, true)
	_heavy_right(x + w, y + 208.0, "$%d" % cash, T_XL, c_good)
	if not doomed.is_empty():
		var names: Array = []
		for dd: Disc in doomed:
			names.append(dd.title)
		_text_center(Rect2(r.position.x, r.position.y + 500.0, r.size.x, 30.0), "Destroyed: " + ", ".join(names), T_SM, c_bad, true)
	if booed:
		_hw_button(Rect2(r.get_center().x - 200.0, r.end.y - 130.0, 400.0, 86.0), "Main menu", _to_title, true, Color("3f9b5a"), T_LG)
	elif final:
		_hw_button(Rect2(r.get_center().x - 220.0, r.end.y - 130.0, 440.0, 86.0), "Continue", _to_win, true, Color("3f9b5a"), T_LG)
	else:
		_hw_button(Rect2(r.get_center().x - 220.0, r.end.y - 130.0, 440.0, 86.0), "Continue", _to_map, true, Color("3f9b5a"), T_LG)

func _to_win() -> void:
	_burn_doomed()
	phase = "won"

func _to_map() -> void:
	_burn_doomed()
	_reset_mixes()
	binder_open = false
	message_t = 0.0
	_back_on_road()

func _tag_chips(x: float, y: float, label: String, tags: Array, col: Color) -> void:
	_text(Vector2(x, y + 22.0), label, T_XS, col, true)
	var cx := x + 76.0
	for tag: Array in tags:
		var t := String(tag[1]).to_upper()
		var w := _text_w(t, T_XS, true) + 20.0
		var cr := Rect2(cx, y, w, 32.0)
		var bg := Color(D.GENRE_COLORS[D.GENRES.find(String(tag[1]))]) if tag[0] == "genre" else Color("5d626a")
		_panel(cr, bg, 12, col, 3)
		_text_center(cr, t, T_XS, Color.WHITE, true)
		cx += w + 8.0

func _make_road() -> void:
	forks_done = 0
	fork_gigs = 0
	fork_roads.clear()
	road_stops.clear()
	var vs: Array = range(D.VENUES.size())
	_shuffle(vs)
	boss_order = range(D.BOSSES.size())
	_shuffle(boss_order)
	for k in D.RUN_GIGS:
		var vn: Dictionary = (D.VENUES[vs[k % vs.size()]] as Dictionary).duplicate(true)
		if (k + 1) % D.BOSS_EVERY == 0:
			vn = _make_boss_venue(k / D.BOSS_EVERY)
		road_stops.append({"kind": "venue", "venue": vn, "stamp": [], "hint": {}, "town": ""})
		if k < D.RUN_GIGS - 1:
			if (k + 1) % D.BOSS_EVERY == 0:
				road_stops.append({"kind": "reward", "mode": "boss", "stamp": [], "hint": {}, "town": ""})
			else:
				road_stops.append({"kind": "reward", "mode": "album", "stamp": [], "hint": {}, "town": ""})
				road_stops.append({"kind": "reward", "mode": "tape", "stamp": [], "hint": {}, "town": ""})

func _make_headliner() -> Dictionary:
	var likes: Array = []
	var g := rng.randi_range(0, D.GENRES.size() - 1)
	likes.append(["genre", D.GENRES[g]])
	likes.append(["era", D.ERAS[rng.randi_range(0, D.ERAS.size() - 1)]])
	var hate_g := (g + rng.randi_range(1, D.GENRES.size() - 1)) % D.GENRES.size()
	return {"name": D.HEADLINER_NAMES[rng.randi_range(0, D.HEADLINER_NAMES.size() - 1)], "likes": likes, "dislikes": [["genre", D.GENRES[hate_g]]], "headliner": true}

func _random_stamp() -> Array:
	var a: Dictionary = albums[rng.randi_range(0, albums.size() - 1)]
	return [int(a["genre"]), -1] if rng.randf() < 0.5 else [-1, int(a["era"])]

func _shop_hint() -> Dictionary:
	var a: Dictionary = albums[rng.randi_range(0, albums.size() - 1)]
	var ids: Array = _gear_pool()
	return {"show": "album" if rng.randf() < 0.5 else "gear", "genre": int(a["genre"]), "era": int(a["era"]), "gear": String(ids[rng.randi_range(0, ids.size() - 1)])}

func _gig_hint(v: Dictionary) -> Dictionary:
	return {"like": rng.randi_range(0, maxi(0, (v["likes"] as Array).size() - 1)), "hate": rng.randi_range(0, maxi(0, (v["dislikes"] as Array).size() - 1))}

func _tour_gigs() -> int:
	return D.LANE_GIGS * D.TOURS if D.USE_FORK else D.RUN_GIGS

func _forks_total() -> int:
	return D.TOURS

func _is_final() -> bool:
	if not D.USE_FORK:
		return gig_n >= D.RUN_GIGS
	return bool(venue.get("headliner", false)) and gig_n >= _tour_gigs()

func _make_forks() -> void:
	forks_done = 0
	fork_gigs = 0
	fork_roads.clear()
	road_stops.clear()
	fork_towns.clear()

func _fork_town() -> String:
	if fork_towns.is_empty():
		fork_towns.assign(D.TOWNS)
		_shuffle(fork_towns)
	return String(fork_towns.pop_back())

func _roll_combo() -> Array:
	var total := 0
	for c: Dictionary in D.ROAD_COMBOS:
		total += int(c["weight"])
	var r := rng.randi_range(0, total - 1)
	for c: Dictionary in D.ROAD_COMBOS:
		r -= int(c["weight"])
		if r < 0:
			return c["stops"]
	return D.ROAD_COMBOS[0]["stops"]

func _extra_stops() -> Array:
	var out: Array = []
	if not D.PICKUPS_ENABLED:
		return out
	for kind: String in _roll_combo():
		if kind != "shop":
			out.append({"kind": kind, "stamp": _random_stamp(), "hint": {}, "town": ""})
	return out

func _make_lane(venues: Array, boss: String) -> Dictionary:
	var stops: Array = []
	for v: Dictionary in venues:
		stops.append_array(_extra_stops())
		stops.append({"kind": "venue", "venue": v, "stamp": [], "hint": _gig_hint(v), "town": _fork_town()})
		stops.append({"kind": "shop", "stamp": [], "hint": {}, "town": ""})
	stops.append_array(_extra_stops())
	var town := _fork_town()
	stops.append({"kind": "boss", "boss": boss, "stamp": [], "hint": {}, "town": town})
	stops.append({"kind": "shop", "stamp": [], "hint": {}, "town": ""})
	return {"town": town, "boss": boss, "stops": stops}

func _roll_fork() -> void:
	forks_done += 1
	var kinds: Array = D.BOSS_KINDS.duplicate()
	_shuffle(kinds)
	var vs: Array = range(D.VENUES.size())
	_shuffle(vs)
	var per := D.LANE_GIGS - 1
	fork_roads.clear()
	for k in 2:
		var venues: Array = []
		for j in per:
			venues.append((D.VENUES[vs[k * per + j]] as Dictionary).duplicate(true))
		fork_roads.append(_make_lane(venues, String(kinds[k])))

func _advance_road() -> void:
	binder_open = false
	if not road_stops.is_empty():
		var nd: Dictionary = road_stops.pop_front()
		if String(nd["kind"]) == "venue":
			fork_gigs += 1
			gig_n = fork_gigs
		_enter_stop(nd)
	elif D.USE_FORK:
		_roll_fork()
		phase = "fork"
	else:
		_to_title()

func _pick_road(k: int) -> void:
	road_stops = (fork_roads[k]["stops"] as Array).duplicate()
	fork_roads.clear()
	_advance_road()

func _link_cols(a: Array, b: Array) -> void:
	var fed := {}
	for i in a:
		var order: Array = b.duplicate()
		order.sort_custom(func(p, q): return absf(float(tour[p]["y"]) - float(tour[i]["y"])) < absf(float(tour[q]["y"]) - float(tour[i]["y"])))
		tour[i]["next"].append(order[0])
		fed[order[0]] = true
		if order.size() > 1 and rng.randf() < D.SECOND_ROAD:
			tour[i]["next"].append(order[1])
			fed[order[1]] = true
	for j in b:
		if fed.has(j):
			continue
		var best: int = a[0]
		for i in a:
			if absf(float(tour[i]["y"]) - float(tour[j]["y"])) < absf(float(tour[best]["y"]) - float(tour[j]["y"])):
				best = i
		tour[best]["next"].append(j)

func _reachable() -> Array:
	return tour[tour_at]["next"]

func _travel(id: int) -> void:
	if not id in _reachable():
		return
	tour_at = id
	tour_path.append(id)
	var nd: Dictionary = tour[id]
	if String(nd["kind"]) in ["venue", "headliner"]:
		gig_n = tour_path.filter(func(i): return tour[i]["kind"] in ["venue", "headliner"]).size()
	_enter_stop(nd)

func _enter_stop(nd: Dictionary) -> void:
	_sfx("page_turn")
	match String(nd["kind"]):
		"shop":
			_to_shop(nd.get("hint", {}))
		"pickup", "cash":
			_start_pickup(String(nd["kind"]), nd.get("stamp", []))
		"boss":
			_enter_boss(String(nd["boss"]))
		"reward":
			_start_reward(String(nd.get("mode", "album")))
		_:
			_start_show(nd["venue"])

func _start_reward(mode: String = "album") -> void:
	phase = "reward"
	var items: Array = []
	if mode == "tape":
		pack = {"kind": "tape", "title": "Choose a cassette", "pick": 1, "items": _tape_choices(3, "")}
	elif mode == "boss":
		var eds: Array = ["holo", "signed", "limited"]
		var cd := _make_disc(_pick_card(-1, -1, "rare", []))
		cd.edition = String(eds[rng.randi_range(0, eds.size() - 1)])
		items.append(cd)
		var ids: Array = _random_gear_ids(10).filter(func(id): return _can_fit(String(id)))
		if ids.is_empty():
			var cd2 := _make_disc(_pick_card(-1, -1, "rare", [cd.title]))
			cd2.edition = String(eds[rng.randi_range(0, eds.size() - 1)])
			items.append(cd2)
		else:
			var ids2 := ids.filter(func(id): return int(gear_defs[id]["price"]) >= 7)
			var gid := String((ids2 if not ids2.is_empty() else ids)[0])
			var gu := _make_gear(gid)
			if bool(gear_defs[gid].get("levels", false)):
				gu["level"] = 1
			items.append(gu)
		items.append(_tape_choices(1, "rare")[0])
		pack = {"kind": "mixed", "title": "Headliner reward", "pick": 1, "items": items}
	else:
		for a: Dictionary in _random_albums(3):
			items.append(_make_disc(a))
		pack = {"kind": "album", "title": "Choose an album", "pick": 1, "items": items}
	pack_sel.clear()
	_pack_start()

func _back_on_road() -> void:
	_advance_road()

func _start_pickup(kind: String, stamp: Array = []) -> void:
	pickup = {"kind": kind, "hits": 0, "need": D.REVEAL_CLICKS if kind == "pickup" else 1}
	if kind == "cash":
		pickup["cash"] = rng.randi_range(D.CASH_REWARD[0], D.CASH_REWARD[1])
	else:
		pickup["options"] = _pickup_options(stamp)
	pickup_shake = 0.0
	message_t = 0.0
	phase = "pickup"
	_sc_sfx("f_whoosh", 0.7, 0.0)

func _pickup_options(stamp: Array) -> Array:
	var chosen: Array = _random_albums(D.PICKUP_CHOICES, int(stamp[0]) if stamp.size() == 2 else -1, int(stamp[1]) if stamp.size() == 2 else -1)
	var opts: Array = []
	for a: Dictionary in chosen:
		opts.append({"disc": _make_disc(a)})
	var ids := _random_gear_ids(8).filter(func(id): return _can_fit(String(id)))
	if not ids.is_empty() and opts.size() > 1 and (pickups_since_gear >= D.PICKUP_GEAR_PITY or rng.randf() < D.PICKUP_GEAR_CHANCE):
		opts[rng.randi_range(1, opts.size() - 1)] = {"gear": _make_gear(String(ids[0]))}
		pickups_since_gear = 0
	else:
		pickups_since_gear += 1
	_shuffle(opts)
	return opts

func _hit_pickup() -> void:
	if int(pickup["hits"]) >= int(pickup["need"]):
		return
	pickup["hits"] = int(pickup["hits"]) + 1
	pickup_shake = 0.35
	_sfx("click")
	if int(pickup["hits"]) >= int(pickup["need"]):
		_sfx("page_turn")
		if pickup["kind"] == "cash":
			cash += int(pickup["cash"])

func _take_option(k: int) -> void:
	var o: Dictionary = (pickup["options"] as Array)[k]
	if o.has("disc"):
		var d: Disc = o["disc"]
		collection.append(d)
		_say("Added %s to your binder." % d.title)
	else:
		if _place_free(o["gear"]):
			_say("Installed the %s." % gear_defs[o["gear"]["id"]]["name"])
	pickup = {}
	_back_on_road()

func _leave_pickup() -> void:
	pickup = {}
	message_t = 0.0
	_back_on_road()

func _map_rect() -> Rect2:
	return Rect2(70.0, 50.0, 2420.0, 1270.0)

func _map_pos(nd: Dictionary) -> Vector2:
	var P := _map_rect()
	var x := P.position.x + 150.0 + int(nd["col"]) * (P.size.x - 300.0) / maxf(1.0, tour_cols - 1)
	var y := P.position.y + 170.0 + float(nd["y"]) * (P.size.y - 400.0)
	return Vector2(x, y)

func _draw_map() -> void:
	_surface(Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0), 0.0, "wood", Color("6b4a32"), Color("4a3222"), 700.0)
	var P := _map_rect()
	_draw_map_paper(P)
	var reach := _reachable()
	for nd: Dictionary in tour:
		for j in nd["next"]:
			var done := int(nd["id"]) in tour_path and int(j) in tour_path and tour_path.find(int(j)) == tour_path.find(int(nd["id"])) + 1
			_draw_road(_map_pos(nd), _map_pos(tour[j]), done, int(nd["road"]) + int(j))
	var hover_id := -1
	for nd: Dictionary in tour:
		var id := int(nd["id"])
		var c := _map_pos(nd)
		var can := ui_live and id in reach
		var hit := Rect2(c.x - 100.0, c.y - 62.0, 200.0, 128.0)
		var over := ui_live and hit.has_point(mouse)
		if over and String(nd["kind"]) in ["venue", "headliner"]:
			hover_id = id
		_draw_stop(nd, c, id in tour_path, id == tour_at, can, can and over)
		if can:
			_register(hit, _travel.bind(id))
	_draw_map_legend(P)
	var note := Rect2(430.0, 1336.0, 520.0, 84.0)
	_shadow(note, 2, 4.0)
	_panel(note, Color("fff3a8"), 2)
	var shows := tour_path.filter(func(i): return tour[i]["kind"] in ["venue", "headliner"]).size()
	_heavy(Vector2(note.position.x + 20.0, note.position.y + 52.0), "$%d" % cash, T_XL, c_ink)
	_text(Vector2(note.position.x + 130.0, note.position.y + 36.0), "Gigs played: %d of %d" % [shows, D.TOUR_GIGS + 1], T_SM, c_body, true)
	_text(Vector2(note.position.x + 130.0, note.position.y + 66.0), "Pick the next stop on the road.", T_SM, c_body, true)
	if hover_id >= 0:
		_stop_card(tour[hover_id], _map_pos(tour[hover_id]), hover_id == tour_at)

func _boss_generic(kind: String) -> Dictionary:
	match kind:
		"genre":
			return {"name": "Genre debuffed", "text": "songs of your most common genre score half"}
		"era":
			return {"name": "Decade debuffed", "text": "songs of your most common decade score half"}
		"slot":
			return {"name": "Crowd request", "text": "one slot only takes a chosen genre or decade"}
		"hates":
			return {"name": "Angry crowd", "text": "an extra hate, and hated songs score nothing"}
		"target":
			return {"name": "High expectations", "text": "the target is %d%% higher" % int(round((D.BOSS_TARGET - 1.0) * 100.0))}
		"gear":
			return {"name": "Broken equipment", "text": "one piece of your gear is out"}
		"destroy":
			return {"name": "Rough crowd", "text": "played songs may be destroyed"}
	return {"name": "No time to dig", "text": "no discards"}

func _boss_info(c: Dictionary) -> Dictionary:
	var gen := _boss_generic(String(c["kind"]))
	match String(c["kind"]):
		"genre":
			var g := String(D.GENRES[int(c["genre"])])
			return {"name": gen["name"], "text": "%s songs score half all night." % g, "short": "%s songs score half" % g}
		"era":
			var e := String(D.ERAS[int(c["era"])])
			return {"name": gen["name"], "text": "%s songs score half all night." % e, "short": "%s songs score half" % e}
		"slot":
			var g2 := String(D.GENRES[int(c["genre"])])
			var e2 := String(D.ERAS[int(c["era"])])
			return {"name": gen["name"], "text": "Slot %d only takes %s or %s songs. Anything else scores nothing." % [int(c["slot"]) + 1, g2, e2], "short": "Slot %d needs %s or %s" % [int(c["slot"]) + 1, g2, e2]}
		"hates":
			return {"name": gen["name"], "text": "They hate %s as well, and hated songs score nothing." % String(c["hate"]), "short": "Hates score nothing"}
		"target":
			return {"name": gen["name"], "text": "The target is %d%% higher." % int(round((D.BOSS_TARGET - 1.0) * 100.0)), "short": "Target +%d%%" % int(round((D.BOSS_TARGET - 1.0) * 100.0))}
		"gear":
			var gn := String(c["name"])
			return {"name": gen["name"], "text": "Your %s is broken for the night." % gn, "short": "%s is broken" % gn}
		"destroy":
			return {"name": gen["name"], "text": "Each song you play has a %d%% chance to be destroyed for good." % int(round(D.BOSS_DESTROY * 100.0)), "short": "Songs may be destroyed"}
	return {"name": gen["name"], "text": "You get no discards tonight.", "short": "No discards"}

func _ranked(is_genre: bool) -> Array:
	var counts := {}
	for d: Disc in collection:
		if d.cdr:
			continue
		var k := d.genre if is_genre else d.era
		counts[k] = int(counts.get(k, 0)) + 1
	var ids: Array = counts.keys()
	_shuffle(ids)
	ids.sort_custom(func(a, b): return int(counts[a]) > int(counts[b]))
	return ids

func _make_boss(kind: String) -> Dictionary:
	var head := _make_headliner()
	var ch := {"kind": kind}
	match kind:
		"genre":
			ch["genre"] = int(_ranked(true)[0])
		"era":
			ch["era"] = int(_ranked(false)[0])
		"slot":
			var real: Array = collection.filter(func(o): return not o.cdr)
			var o: Disc = real[rng.randi_range(0, real.size() - 1)]
			ch["slot"] = rng.randi_range(1, D.SETLIST - 2)
			ch["genre"] = o.genre
			ch["era"] = o.era
		"hates":
			var liked: Array = (head["likes"] as Array).map(func(t): return t[1])
			var pick := -1
			for g in _ranked(true):
				if not String(D.GENRES[int(g)]) in liked and not (head["dislikes"] as Array).any(func(t): return t[1] == D.GENRES[int(g)]):
					pick = int(g)
					break
			if pick < 0:
				ch["kind"] = "target"
			else:
				ch["hate"] = D.GENRES[pick]
				(head["dislikes"] as Array).append(["genre", D.GENRES[pick]])
		"gear":
			var bays: Array = []
			for k in rack.size():
				if not rack[k].is_empty():
					bays.append(k)
			if bays.is_empty():
				ch["kind"] = "target"
			else:
				var bk := int(bays[rng.randi_range(0, bays.size() - 1)])
				ch["gear_id"] = String(rack[bk]["id"])
				ch["name"] = String(gear_defs[rack[bk]["id"]]["name"])
	head["challenge"] = ch
	return head

func _enter_boss(kind: String) -> void:
	fork_gigs += 1
	gig_n = fork_gigs
	boss_venue = _make_boss(kind)
	_sfx("page_turn")
	phase = "boss"

func _begin_boss() -> void:
	_start_show(boss_venue)

func _draw_boss() -> void:
	var full := Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0)
	_grad_panel(full, 0.0, Color("2a1220"), Color("7a2a2a"))
	var r := _modal_panel(1200.0, 820.0)
	var ch: Dictionary = boss_venue["challenge"]
	var info := _boss_info(ch)
	_text_center(Rect2(r.position.x, r.position.y + 30.0, r.size.x, 40.0), "HEADLINER  ·  GIG %d OF %d" % [gig_n, _tour_gigs()], T_MD, c_bad, true)
	_heavy_center(Rect2(r.position.x, r.position.y + 80.0, r.size.x, 100.0), String(boss_venue["name"]), T_XL + 16, c_ink)
	_heavy_center(Rect2(r.position.x, r.position.y + 215.0, r.size.x, 60.0), String(info["name"]), T_LG, c_bad)
	_wrap(Vector2(r.position.x + 150.0, r.position.y + 300.0), String(info["text"]), r.size.x - 300.0, T_MD, c_body, true)
	var x := r.position.x + 150.0
	_tag_chips(x, r.position.y + 470.0, "LIKES", boss_venue["likes"], c_good)
	_tag_chips(x, r.position.y + 530.0, "HATES", boss_venue["dislikes"], c_bad)
	_text(Vector2(x, r.position.y + 620.0), "+%d points for a liked song   ·   a hated song scores half" % D.LIKE, 16, c_body, true)
	_hw_button(Rect2(r.get_center().x - 220.0, r.end.y - 120.0, 440.0, 86.0), "Take the stage", _begin_boss, true, Color("3f9b5a"), T_LG)

func _to_title() -> void:
	Engine.time_scale = 1.0
	slowmo_end_ms = 0
	binder_open = false
	pack = {}
	message_t = 0.0
	_menu_song()
	phase = "title"

func _show_title() -> void:
	phase = "title"

func _menu_bg(art: bool = true) -> void:
	var full := Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0)
	if not art:
		draw_rect(full, Color.BLACK)
		return
	draw_rect(full, Color("0e1018"))
	var tex := _cover_tex(String(menu_album.get("cover", "")))
	if tex != null:
		var ts := tex.get_size()
		var sc := maxf(UI_W / ts.x, UI_H / ts.y)
		var sz := ts * sc
		draw_texture_rect(tex, Rect2((Vector2(UI_W, UI_H) - sz) * 0.5, sz), false)
	draw_rect(full, Color(0.04, 0.05, 0.09, 0.6))
	_grad_panel(full, 0.0, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.55))

func _to_kits() -> void:
	pending_kit = 0
	if _decks().size() == 1:
		_new_run(0, _decks()[0])
		return
	phase = "decks"

func _pick_kit(i: int) -> void:
	pending_kit = i
	phase = "decks"

func _pick_deck(i: int) -> void:
	_new_run(pending_kit, _decks()[i])

func _draw_decks() -> void:
	_menu_bg(false)
	_heavy_center(Rect2(0.0, 40.0, UI_W, 110.0), "Choose your deck", T_XL + 16, Color("f4efe4"))
	var ds := _decks()
	var w := 300.0
	var h := 400.0
	var gap := 24.0
	var per := 6
	for di in ds.size():
		var dk: Dictionary = ds[di]
		var row := di / per
		var n := mini(per, ds.size() - row * per)
		var x0 := (UI_W - (n * w + (n - 1) * gap)) * 0.5
		var r := Rect2(x0 + (di % per) * (w + gap), 270.0 + row * (h + 60.0), w, h)
		var hot := ui_live and r.has_point(mouse)
		if hot:
			_panel(r.grow(8.0), Color("f2c14e"), 22)
		_shadow(r, 18, 10.0)
		_panel(r, Color("f4efe4"), 18)
		var lead := _deck_lead(dk)
		var tex: Texture2D = _cover_tex(String(lead["cover"])) if not lead.is_empty() else null
		_cd_art(Vector2(r.get_center().x, r.position.y + 118.0), 84.0, tex, clock * 0.6 if hot else 0.0)
		_heavy_center(Rect2(r.position.x, r.position.y + 224.0, w, 44.0), String(dk["name"]), T_LG, c_ink)
		_text_center(Rect2(r.position.x, r.position.y + 268.0, w, 24.0), ("%d CDs  ·  %d MIX" % [_deck_size(dk), int(dk["mixes"])]) if int(dk.get("mixes", 0)) > 0 else ("%d CDs" % _deck_size(dk)), 13, c_muted, true)
		_wrap(Vector2(r.position.x + 22.0, r.position.y + 322.0), String(dk.get("idea", "")), w - 44.0, 15, c_body, true)
		if ui_live:
			_register(r, _pick_deck.bind(di))
	_hw_button(Rect2(70.0, 1336.0, 260.0, 84.0), "Back", _to_title, true, Color("6a6f77"), T_MD)

func _draw_title() -> void:
	_menu_bg(false)
	var c := Vector2(UI_W * 0.5, 470.0)
	var ctex := _cover_tex(String(menu_album.get("cover", "")))
	_draw_cd_player(Rect2(c - Vector2(280.0, 280.0), Vector2(560.0, 560.0)), ctex if ctex != null else null, clock * 0.8, true)
	_heavy_center(Rect2(0.0, 820.0, UI_W, 150.0), "DJ Engine", T_HERO + 40, Color("f4efe4"))
	_text_center(Rect2(0.0, 985.0, UI_W, 50.0), "A DJ roguelike. Lay out a set, chain your effects, win the crowd.", T_MD, Color(1, 1, 1, 0.85), true)
	_hw_button(Rect2(UI_W * 0.5 - 220.0, 1090.0, 440.0, 100.0), "Play", _to_kits, true, Color("3f9b5a"), T_XL)
	_hw_button(Rect2(UI_W * 0.5 - 180.0, 1220.0, 360.0, 80.0), "Settings", _open_settings, true, Color("6a6f77"), T_MD)

func _draw_vol_slider(track: Rect2, key: String) -> void:
	vol_tracks[key] = track
	var val := music_vol if key == "music" else sfx_vol
	var v := float(val) / 100.0
	_panel(track.grow(3.0), Color(0, 0, 0, 0.18), 16)
	_panel(Rect2(track.position, Vector2(maxf(track.size.y, track.size.x * v), track.size.y)), Color("3f9b5a"), 14)
	var kx := track.position.x + track.size.x * v
	var hot := ui_live and track.grow(16.0).has_point(mouse)
	var kr := 24.0 if (hot or vol_drag == key) else 21.0
	var kc := Vector2(kx, track.get_center().y)
	_aa_circle(kc + Vector2(0.0, 3.0), kr, Color(0, 0, 0, 0.3))
	_aa_circle(kc, kr, Color.WHITE)
	draw_arc(kc, kr - 1.0, 0.0, TAU, 48, Color(0, 0, 0, 0.35), 2.0, true)
	_heavy(Vector2(track.end.x + 34.0, track.get_center().y + 14.0), str(val), T_LG, c_ink)
	_register(track.grow(16.0), _vol_press.bind(key))

func _vol_press(key: String) -> void:
	vol_drag = key
	_vol_set_from_mouse()

func _vol_set_from_mouse() -> void:
	var track: Rect2 = vol_tracks.get(vol_drag, Rect2())
	if track.size.x <= 0.0:
		return
	var val := clampi(int(round((_ui_mouse().x - track.position.x) / track.size.x * 100.0)), 0, 100)
	if vol_drag == "music":
		music_vol = val
	else:
		sfx_vol = val

func _music_gain() -> float:
	var v := float(music_vol) / 100.0
	return v * v

func _sfx_gain() -> float:
	var v := float(sfx_vol) / 100.0
	return v * v

func _kit_gear(kit: Dictionary) -> Dictionary:
	return {"id": String(kit["gear"]), "used": 0, "broken": false}

func _draw_kits() -> void:
	_menu_bg(false)
	_heavy_center(Rect2(0.0, 40.0, UI_W, 110.0), "Choose your kit", T_XL + 16, Color("f4efe4"))
	var n: int = D.KITS.size()
	var w := 560.0
	var gap := 40.0
	var x0 := (UI_W - (n * w + (n - 1) * gap)) * 0.5
	for i in n:
		var kit: Dictionary = D.KITS[i]
		var r := Rect2(x0 + i * (w + gap), 170.0, w, 1130.0)
		var hot := ui_live and r.has_point(mouse)
		if hot:
			_panel(r.grow(10.0), Color("f2c14e"), 24)
		_shadow(r, 20, 12.0)
		_panel(r, Color("f4efe4"), 20)
		var x := r.position.x + 30.0
		var iw := r.size.x - 60.0
		_heavy(Vector2(x, r.position.y + 70.0), String(kit["name"]), T_XL, c_ink)
		_wrap(Vector2(x, r.position.y + 112.0), String(kit["idea"]), iw, T_SM, c_body, true)
		_text(Vector2(x, r.position.y + 290.0), "STARTING GEAR", 14, c_muted, true)
		_draw_gear(Rect2(x, r.position.y + 304.0, iw, 200.0), _kit_gear(kit), 0.5)
		_text(Vector2(x, r.position.y + 550.0), "THE DECK", 14, c_muted, true)
		_wrap(Vector2(x, r.position.y + 580.0), "Next you pick a deck: one for every genre and decade.", iw, T_SM, c_body, true)
		_wrap(Vector2(x, r.position.y + 680.0), "Every CD has one effect that reacts to the songs around it. Lay out the whole set, then press PLAY.", iw, 15, c_body, true)
		_hw_button(Rect2(r.get_center().x - 190.0, r.end.y - 110.0, 380.0, 80.0), "Pick this kit", _pick_kit.bind(i), true, Color("3f9b5a"), T_MD)
		if ui_live:
			_register(r, _pick_kit.bind(i))
	_hw_button(Rect2(70.0, 1336.0, 260.0, 84.0), "Back", _show_title, true, Color("6a6f77"), T_MD)

func _road_curve(a: Vector2, c: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		pts.append(a.lerp(c, t).lerp(c.lerp(b, t), t))
	return pts

func _draw_fork() -> void:
	var full := Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0)
	_grad_panel(full, 0.0, Color("16213d"), Color("e08a4f"))
	var g := RandomNumberGenerator.new()
	g.seed = 7
	for k in 70:
		draw_circle(Vector2(g.randf_range(0.0, UI_W), g.randf_range(0.0, 700.0)), g.randf_range(1.2, 2.6), Color(1, 1, 1, g.randf_range(0.3, 0.9)))
	draw_circle(Vector2(UI_W * 0.5, 1000.0), 260.0, Color("f6c26b", 0.85))
	draw_rect(Rect2(-800.0, 990.0, UI_W + 1600.0, 900.0), Color("1e2c24"))
	var sites := [Rect2(150.0, 190.0, 1000.0, 790.0), Rect2(1410.0, 190.0, 1000.0, 790.0)]
	var base := Vector2(UI_W * 0.5, 1500.0)
	var hover_k := -1
	for k in sites.size():
		if ui_live and (sites[k] as Rect2).has_point(mouse):
			hover_k = k
	for k in sites.size():
		var s: Rect2 = sites[k]
		var pts := _road_curve(base, Vector2(UI_W * 0.5, 1110.0), Vector2(s.get_center().x, s.end.y + 10.0))
		if k == hover_k:
			draw_polyline(pts, Color("f2c14e"), 224.0, true)
		draw_polyline(pts, Color("d8d2c0"), 206.0, true)
		draw_polyline(pts, Color("2c2f35"), 188.0, true)
		for i in range(0, pts.size() - 1, 2):
			draw_line(pts[i], pts[i + 1], Color("f2c14e"), 8.0, true)
	_heavy_center(Rect2(0.0, 40.0, UI_W, 110.0), "Choose your lane", T_XL + 16, Color("f4efe4"))
	_text_center(Rect2(0.0, 134.0, UI_W, 40.0), "Tour %d of %d  ·  %d gigs, a record shop after each" % [forks_done, _forks_total(), D.LANE_GIGS], T_SM, c_gold, true)
	var tip_nd := {}
	var tip_c := Vector2.ZERO
	for k in sites.size():
		var s: Rect2 = sites[k]
		var road: Dictionary = fork_roads[k]
		if k == hover_k:
			_panel(s.grow(12.0), Color("f2c14e"), 26)
		_shadow(s, 20, 14.0)
		_panel(s, Color("1d5c3a"), 20, Color("f4efe4"), 8)
		_panel(s.grow(-18.0), Color(0, 0, 0, 0), 14, Color("f4efe4", 0.45), 3)
		var band := Rect2(s.position.x + 36.0, s.position.y + 36.0, s.size.x - 72.0, 128.0)
		_panel(band, Color("5d626a"), 12, Color(1, 1, 1, 0.6), 3)
		_heavy(Vector2(band.position.x + 28.0, band.position.y + 70.0), "LANE %s" % ["A", "B"][k], T_XL, Color.WHITE)
		_text(Vector2(band.position.x + 30.0, band.position.y + 106.0), "toward " + String(road["town"]), T_SM, Color(1, 1, 1, 0.85), true)
		var shown: Array = (road["stops"] as Array).filter(func(n): return String(n["kind"]) in ["venue", "boss"])
		for i in shown.size():
			var nd: Dictionary = shown[i]
			var kind := String(nd["kind"])
			var row := Rect2(s.position.x + 36.0, s.position.y + 190.0 + i * 190.0, s.size.x - 72.0, 172.0)
			_panel(row, Color(0, 0, 0, 0.25), 12)
			_map_icon("headliner" if kind == "boss" else kind, Vector2(row.position.x + 80.0, row.position.y + 86.0), false, [])
			_text_right(row.end.x - 20.0, row.position.y + 34.0, "HEADLINER" if kind == "boss" else "GIG %d" % (fork_gigs + i + 1), 14, Color(1, 1, 1, 0.6), true)
			var tx := row.position.x + 170.0
			if kind == "boss":
				var bgen := _boss_generic(String(nd["boss"]))
				_heavy(Vector2(tx, row.position.y + 70.0), "Headliner", T_MD, Color.WHITE)
				_text(Vector2(tx, row.position.y + 108.0), String(bgen["name"]), T_SM, Color("f2c14e"), true)
				_wrap(Vector2(tx, row.position.y + 138.0), String(bgen["text"]), row.end.x - tx - 20.0, 15, Color(1, 1, 1, 0.8), true)
				continue
			var v: Dictionary = nd["venue"]
			var vn := String(v["name"])
			_heavy(Vector2(tx, row.position.y + 70.0), vn, T_SM if _heavy_w(vn, T_MD) > 600.0 else T_MD, Color.WHITE)
			var gh: Dictionary = nd["hint"]
			var like_t: Array = (v["likes"] as Array)[int(gh["like"])]
			var hate_t: Array = (v["dislikes"] as Array)[int(gh["hate"])]
			var cx := tx
			_text(Vector2(cx, row.position.y + 116.0), "LIKES", 13, Color("9be3a8"), true)
			cx += _text_w("LIKES", 13, true) + 10.0
			cx += _tip_chip(cx, row.position.y + 94.0, like_t, Color("9be3a8")) + 26.0
			_text(Vector2(cx, row.position.y + 116.0), "HATES", 13, Color("ffb0a6"), true)
			cx += _text_w("HATES", 13, true) + 10.0
			_tip_chip(cx, row.position.y + 94.0, hate_t, Color("ffb0a6"))
			if ui_live and row.has_point(mouse):
				tip_nd = nd
				tip_c = Vector2(row.get_center().x, row.end.y - 14.0)
		var post := Rect2(s.get_center().x - 14.0, s.end.y, 28.0, 40.0)
		draw_rect(post, Color("8a9099"))
		if ui_live:
			_register(s, _pick_road.bind(k))
	var note := Rect2(430.0, 1336.0, 520.0, 84.0)
	_shadow(note, 2, 4.0)
	_panel(note, Color("fff3a8"), 2)
	_heavy(Vector2(note.position.x + 20.0, note.position.y + 52.0), "$%d" % cash, T_XL, c_ink)
	_text(Vector2(note.position.x + 130.0, note.position.y + 36.0), "Tour %d of %d" % [forks_done, _forks_total()], T_SM, c_body, true)
	_text(Vector2(note.position.x + 130.0, note.position.y + 66.0), "Pick a lane. Gig 3 is the headliner.", T_SM, c_body, true)
	if not tip_nd.is_empty():
		_stop_card(tip_nd, tip_c, false)

func _draw_map_paper(P: Rect2) -> void:
	_shadow(P, 4, 14.0)
	_panel(P, Color("ece4cf"), 4)
	var g := RandomNumberGenerator.new()
	g.seed = map_seed
	for k in 5:
		var cx := g.randf_range(P.position.x + 200.0, P.end.x - 200.0)
		var cy := g.randf_range(P.position.y + 150.0, P.end.y - 150.0)
		var pts := PackedVector2Array()
		var rad := g.randf_range(150.0, 320.0)
		for i in 18:
			pts.append((Vector2(cx, cy) + Vector2.from_angle(TAU * i / 18.0) * rad * g.randf_range(0.7, 1.15)).clamp(P.position + Vector2(4, 4), P.end - Vector2(4, 4)))
		draw_colored_polygon(pts, Color("d8e3c0", 0.55))
	var lake := PackedVector2Array()
	var lc := Vector2(g.randf_range(P.position.x + 500.0, P.end.x - 500.0), g.randf_range(P.position.y + 250.0, P.end.y - 250.0))
	for i in 22:
		lake.append((lc + Vector2.from_angle(TAU * i / 22.0) * Vector2(170.0, 90.0) * g.randf_range(0.75, 1.1)).clamp(P.position + Vector2(4, 4), P.end - Vector2(4, 4)))
	draw_colored_polygon(lake, Color("b9d3e0"))
	draw_polyline(lake + PackedVector2Array([lake[0]]), Color("7fa6bd"), 2.0, true)
	var river := PackedVector2Array()
	var ry := g.randf_range(P.position.y + 200.0, P.end.y - 200.0)
	var x := P.position.x
	while x <= P.end.x:
		river.append(Vector2(x, ry + sin(x * 0.006 + map_seed % 7) * 60.0 + sin(x * 0.017) * 18.0))
		x += 20.0
	draw_polyline(river, Color("8fb6cc"), 7.0, true)
	var gx := P.position.x + 120.0
	while gx < P.end.x:
		draw_line(Vector2(gx, P.position.y), Vector2(gx, P.end.y), Color(0, 0, 0, 0.035), 1.0)
		gx += 240.0
	var gy := P.position.y + 120.0
	while gy < P.end.y:
		draw_line(Vector2(P.position.x, gy), Vector2(P.end.x, gy), Color(0, 0, 0, 0.035), 1.0)
		gy += 240.0
	for k in 2:
		var bx := P.position.x + P.size.x * (0.3 + k * 0.38) + g.randf_range(-60.0, 60.0)
		var yy := P.position.y
		while yy < P.end.y:
			var y2 := minf(yy + 14.0, P.end.y)
			draw_line(Vector2(bx + sin(yy * 0.01) * 30.0, yy), Vector2(bx + sin(y2 * 0.01) * 30.0, y2), Color("b07aa1", 0.45), 2.0)
			yy += 26.0
	for k in 2:
		var fx := P.position.x + P.size.x * (k + 1) / 3.0
		draw_line(Vector2(fx, P.position.y), Vector2(fx, P.end.y), Color(0, 0, 0, 0.09), 4.0)
		draw_line(Vector2(fx + 3.0, P.position.y), Vector2(fx + 3.0, P.end.y), Color(1, 1, 1, 0.3), 2.0)
	var fy := P.get_center().y
	draw_line(Vector2(P.position.x, fy), Vector2(P.end.x, fy), Color(0, 0, 0, 0.08), 4.0)
	draw_line(Vector2(P.position.x, fy + 3.0), Vector2(P.end.x, fy + 3.0), Color(1, 1, 1, 0.3), 2.0)
	var ring := Vector2(P.end.x - 330.0, P.end.y - 170.0)
	draw_arc(ring, 70.0, 0.4, TAU - 0.6, 48, Color("7a5230", 0.22), 9.0, true)
	draw_arc(ring + Vector2(4, 3), 62.0, 1.0, TAU - 1.6, 48, Color("7a5230", 0.12), 4.0, true)
	for corner in [P.position + Vector2(40.0, -12.0), Vector2(P.end.x - 160.0, P.position.y - 12.0)]:
		draw_rect(Rect2(corner, Vector2(120.0, 34.0)), Color(1, 1, 0.9, 0.55))
		draw_rect(Rect2(corner, Vector2(120.0, 34.0)), Color(0, 0, 0, 0.06), false, 1.0)

func _draw_road(a: Vector2, b: Vector2, done: bool, num: int) -> void:
	var mid := (a + b) * 0.5 + Vector2(0.0, (b.x - a.x) * 0.06 * (1.0 if num % 2 == 0 else -1.0))
	var pts := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	draw_polyline(pts, Color("8a7a58", 0.55), 13.0, true)
	draw_polyline(pts, Color("f2c14e") if num % 3 != 0 else Color("fbfaf5"), 8.0, true)
	if done:
		draw_polyline(pts, Color("d7263d", 0.55), 20.0, true)
	var sc := pts[8] + Vector2(0.0, -22.0)
	var shield := PackedVector2Array([sc + Vector2(-18, -14), sc + Vector2(18, -14), sc + Vector2(18, 4), sc + Vector2(0, 16), sc + Vector2(-18, 4)])
	draw_colored_polygon(shield, Color("1f4e8c"))
	draw_polyline(shield + PackedVector2Array([shield[0]]), Color.WHITE, 2.0, true)
	draw_rect(Rect2(sc + Vector2(-18, -14), Vector2(36, 7)), Color("c0392b"))
	_text_center(Rect2(sc.x - 18.0, sc.y - 7.0, 36.0, 20.0), str(num % 99 + 1), 12, Color.WHITE, true)

func _draw_stop(nd: Dictionary, c: Vector2, visited: bool, here: bool, can: bool, hot: bool) -> void:
	var kind := String(nd["kind"])
	if can:
		draw_arc(c, 30.0 + 4.0 * sin(clock * 4.0), 0.0, TAU, 40, Color("d7263d", 0.8 if hot else 0.5), 4.0, true)
	draw_circle(c, 11.0, Color.WHITE)
	draw_arc(c, 11.0, 0.0, TAU, 24, Color("2b2e33"), 3.0, true)
	var ic := c + Vector2(0.0, -32.0)
	draw_line(c, ic, Color("5d626a"), 3.0)
	_map_icon(kind, ic, here, nd.get("stamp", []))
	_stop_label(nd, c, 1.0 if (can or here or kind == "start") else (0.55 if visited else 0.8), hot)

func _marker_font() -> Font:
	if font_marker == null:
		var path := "res://assets/fonts/PermanentMarker-Regular.ttf"
		if ResourceLoader.exists(path):
			font_marker = load(path)
		else:
			var ff := FontFile.new()
			font_marker = ff if ff.load_dynamic_font(path) == OK else font_heavy
	return font_marker

func _marker(center: Vector2, s: String, size: int, col: Color, rot: float, under: int = 0) -> void:
	var f := _marker_font()
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_set_transform(screen_origin + center * ui_scale, rot, Vector2(ui_scale, ui_scale))
	var p := Vector2(-w * 0.5, size * 0.35)
	draw_string(f, p + Vector2(1.2, 1.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col, col.a * 0.55))
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	for k in under:
		var y := size * 0.55 + k * 7.0
		draw_line(Vector2(-w * 0.5, y), Vector2(w * 0.5, y + 1.5), col, 3.0, true)
	draw_set_transform(screen_origin, 0.0, Vector2(ui_scale, ui_scale))

func _stop_label(nd: Dictionary, c: Vector2, a: float, hot: bool) -> void:
	var kind := String(nd["kind"])
	var ink := Color(0.07, 0.07, 0.09, a)
	var tilt := (int(nd["id"]) * 37 % 7 - 3) * 0.012
	var name := ""
	var sub := ""
	var sub_col := Color("d7263d")
	match kind:
		"start":
			name = String(nd["town"])
			sub = "home"
		"shop":
			name = "Record shop"
			var sh: Dictionary = nd.get("hint", {})
			if not sh.is_empty():
				var gid := String(sh["gear"])
				if String(sh["show"]) == "gear" and not gid in _owned_gear():
					sub = "Has %s" % String(gear_defs[gid]["name"])
					sub_col = Color("2e6ea6")
				else:
					sub = "Has %s %s" % [D.GENRES[int(sh["genre"])], D.ERAS[int(sh["era"])]]
					sub_col = Color(D.GENRE_COLORS[int(sh["genre"])]).darkened(0.1)
		"pickup":
			name = "Pickup"
			var st: Array = nd.get("stamp", [])
			if st.size() == 2 and int(st[0]) >= 0:
				sub = String(D.GENRES[int(st[0])])
				sub_col = Color(D.GENRE_COLORS[int(st[0])]).darkened(0.1)
		"cash":
			name = "Tip jar"
		_:
			name = String((nd["venue"] as Dictionary)["name"])
			sub = String(nd["town"])
	var fs := 28
	var w := _marker_font().get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if w > 200.0:
		fs = maxi(16, int(fs * 200.0 / w))
	_marker(Vector2(c.x, c.y + 50.0), name, fs, ink, tilt, 2 if kind == "headliner" else (1 if hot else 0))
	if sub != "":
		var sfs := 18
		var sw := _marker_font().get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
		if sw > 200.0:
			sfs = maxi(12, int(sfs * 200.0 / sw))
		_marker(Vector2(c.x, c.y + 80.0), sub, sfs, Color(sub_col, a), tilt * 0.5)
	if kind in ["venue", "headliner"]:
		var v: Dictionary = nd["venue"]
		var gh: Dictionary = nd.get("hint", {})
		var likes: Array = v["likes"]
		var hates: Array = v["dislikes"]
		if not likes.is_empty():
			_marker(Vector2(c.x, c.y + 106.0), "+ " + String((likes[int(gh.get("like", 0))] as Array)[1]), 17, Color(c_good.darkened(0.2), a), tilt * 0.4)
		if not hates.is_empty():
			_marker(Vector2(c.x, c.y + 130.0), "- " + String((hates[int(gh.get("hate", 0))] as Array)[1]), 17, Color(c_bad.darkened(0.1), a), tilt * 0.4)

func _stop_card(nd: Dictionary, c: Vector2, here: bool) -> void:
	var v: Dictionary = nd["venue"]
	var head := String(nd["kind"]) == "headliner"
	var P := _map_rect()
	var tag := Rect2(c.x - 170.0, c.y + 24.0, 340.0, 196.0)
	tag.position.x = clampf(tag.position.x, P.position.x + 12.0, P.end.x - tag.size.x - 12.0)
	if tag.end.y > P.end.y - 12.0:
		tag.position.y = c.y - 60.0 - tag.size.y
	_shadow(tag, 2, 6.0)
	_panel(tag, Color(1, 1, 0.97), 3, Color("d7263d"), 3)
	var x := tag.position.x + 14.0
	_text(Vector2(x, tag.position.y + 26.0), ("HEADLINER · " if head else "GIG · ") + String(nd["town"]).to_upper(), 14, Color("b8860b") if head else Color("d7263d"), true)
	_heavy(Vector2(x, tag.position.y + 58.0), String(v["name"]), T_SM if _heavy_w(String(v["name"]), T_MD) > 300.0 else T_MD, c_ink)
	var y := tag.position.y + 92.0
	for row: Array in [["LIKES", v["likes"], c_good, "+%d points each" % D.LIKE], ["HATES", v["dislikes"], c_bad, "scores half"]]:
		_text(Vector2(x, y), "%s  ·  %s" % [row[0], row[3]], 13, row[2], true)
		var cx := x
		for t: Array in row[1]:
			cx += _tip_chip(cx, y + 8.0, t, row[2]) + 6.0
		y += 52.0
	if here:
		_text_right(tag.end.x - 12.0, tag.position.y + 22.0, "HERE", 13, Color("b8860b"), true)

func _map_icon(kind: String, ic: Vector2, here: bool = false, stamp: Array = []) -> void:
	match kind:
		"shop":
			draw_circle(ic + Vector2(2, 3), 20.0, Color(0, 0, 0, 0.3))
			draw_circle(ic, 20.0, Color("15171a"))
			for k in 3:
				draw_arc(ic, 8.0 + k * 3.5, 0.0, TAU, 24, Color(1, 1, 1, 0.12), 1.0, true)
			draw_circle(ic, 6.0, Color("e2725b"))
			draw_circle(ic, 1.8, Color("15171a"))
		"start":
			var hb := Rect2(ic - Vector2(22.0, 8.0), Vector2(44.0, 26.0))
			_panel(Rect2(hb.position + Vector2(2, 3), hb.size), Color(0, 0, 0, 0.3), 2)
			_panel(hb, Color("d9cfb6"), 2, Color("7a7260"), 2)
			draw_colored_polygon(PackedVector2Array([ic + Vector2(-27.0, -7.0), ic + Vector2(0.0, -28.0), ic + Vector2(27.0, -7.0)]), Color("b03a2e"))
			draw_rect(Rect2(ic.x - 6.0, ic.y + 2.0, 12.0, 16.0), Color("6b4a32"))
			draw_circle(ic + Vector2(3.0, 11.0), 1.4, Color("e9b949"))
			draw_rect(Rect2(hb.position.x + 4.0, hb.end.y - 9.0, 11.0, 6.0), Color("2b2e33"))
			draw_rect(Rect2(hb.end.x - 15.0, hb.end.y - 9.0, 11.0, 6.0), Color("2b2e33"))
		"pickup":
			if stamp.size() == 2:
				var sb := Rect2(ic - Vector2(26.0, 20.0), Vector2(52.0, 40.0))
				_panel(Rect2(sb.position + Vector2(2, 3), sb.size), Color(0, 0, 0, 0.3), 3)
				_panel(sb, Color("b98a55"), 3, Color("7a5a33"), 2)
				draw_rect(Rect2(sb.position.x + 20.0, sb.position.y, 12.0, 9.0), Color("e6d3a3"))
				var lab := Rect2(sb.position.x + 5.0, sb.position.y + 13.0, 42.0, 22.0)
				if int(stamp[0]) >= 0:
					_panel(lab, Color(D.GENRE_COLORS[int(stamp[0])]), 3, Color(1, 1, 1, 0.5), 1)
					_heavy_center(lab, String(D.GENRE_SHORT[int(stamp[0])]), 13, Color.WHITE)
				else:
					_panel(lab, Color("5d626a"), 3, Color(1, 1, 1, 0.5), 1)
					_heavy_center(lab, String(D.ERAS[int(stamp[1])]), 17, Color.WHITE)
			else:
				var br := Rect2(ic - Vector2(20, 16), Vector2(40, 32))
				_panel(Rect2(br.position + Vector2(2, 3), br.size), Color(0, 0, 0, 0.3), 3)
				_panel(br, Color("b98a55"), 3, Color("7a5a33"), 2)
				draw_rect(Rect2(br.position.x + 16.0, br.position.y, 8.0, br.size.y), Color("e6d3a3"))
				_heavy_center(br, "?", 20, Color("4a3222"))
		"cash":
			draw_circle(ic + Vector2(2, 3), 19.0, Color(0, 0, 0, 0.3))
			draw_circle(ic, 19.0, Color("3f9b5a"))
			draw_arc(ic, 15.0, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0, true)
			_heavy_center(Rect2(ic - Vector2(19, 19), Vector2(38, 38)), "$", 22, Color.WHITE)
		"headliner":
			var star := PackedVector2Array()
			for i in 10:
				star.append(ic + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * (26.0 if i % 2 == 0 else 11.0))
			draw_colored_polygon(star, Color("e9b949"))
			draw_polyline(star + PackedVector2Array([star[0]]), Color("8a6a10"), 2.0, true)
		_:
			draw_circle(ic + Vector2(2, 3), 14.0, Color(0, 0, 0, 0.3))
			var col := Color("e9b949") if here else (Color("d7263d") if kind == "venue" else Color("2e6ea6"))
			draw_circle(ic, 14.0, col)
			draw_circle(ic - Vector2(4, 4), 5.0, Color(1, 1, 1, 0.55))

func _tip_chip(x: float, y: float, tag: Array, ring: Color) -> float:
	var is_genre: bool = tag[0] == "genre"
	var t := String(tag[1]).to_upper() if is_genre else String(tag[1])
	# Genre and decade chips lead with their icon, like the CD tooltip chips.
	var gi := D.GENRES.find(String(tag[1])) if is_genre else -1
	var ei := -1 if is_genre else D.ERAS.find(String(tag[1]))
	var kind := ("g%d" % gi) if gi >= 0 else (("e%d" % ei) if ei >= 0 else "")
	var icw := 24.0 if kind != "" else 0.0
	var w := icw + _text_w(t, 14, true) + 18.0
	var r := Rect2(x, y, w, 28.0)
	var bg := Color(D.GENRE_COLORS[gi]) if gi >= 0 else Color("5d626a")
	_panel(r, bg, 10, ring, 2)
	if kind != "":
		_icon(kind, Vector2(r.position.x + 9.0 + 10.0, r.get_center().y), 20.0, Color.WHITE)
	_text_center(Rect2(r.position.x + icw, r.position.y, w - icw, r.size.y), t, 14, Color.WHITE, true)
	return w

func _draw_map_legend(P: Rect2) -> void:
	var r := Rect2(P.position.x + 30.0, P.position.y + 30.0, 700.0, 116.0)
	_panel(r, Color("f7f1e1"), 3, Color(c_ink, 0.5), 2)
	_panel(r.grow(-6.0), Color(0, 0, 0, 0), 2, Color(c_ink, 0.25), 1)
	_heavy(Vector2(r.position.x + 20.0, r.position.y + 46.0), "Tour Map", T_LG, c_ink)
	var items := [["venue", "Gig"], ["pickup", "Pickup"], ["cash", "Cash"], ["shop", "Record shop"], ["headliner", "Headliner"]]
	var lx := r.position.x + 30.0
	var ly := r.position.y + 84.0
	for it: Array in items:
		_map_icon(String(it[0]), Vector2(lx + 10.0, ly))
		_text(Vector2(lx + 38.0, ly + 6.0), String(it[1]), 16, c_body, true)
		lx += 38.0 + _text_w(String(it[1]), 16, true) + 34.0
	var cc := Vector2(P.end.x - 90.0, P.position.y + 90.0)
	draw_circle(cc, 46.0, Color("f7f1e1"))
	draw_arc(cc, 46.0, 0.0, TAU, 40, Color(c_ink, 0.5), 2.0, true)
	draw_colored_polygon(PackedVector2Array([cc + Vector2(0, -40), cc + Vector2(8, 0), cc + Vector2(-8, 0)]), Color("d7263d"))
	draw_colored_polygon(PackedVector2Array([cc + Vector2(0, 40), cc + Vector2(8, 0), cc + Vector2(-8, 0)]), Color(c_ink, 0.6))
	_text_center(Rect2(cc.x - 20.0, cc.y - 70.0, 40.0, 20.0), "N", 15, c_ink, true)

func _draw_pickup() -> void:
	draw_rect(Rect2(-800.0, -800.0, UI_W + 1600.0, UI_H + 1600.0), Color("050506"))
	var cx := UI_W * 0.5
	var floor_y := 1080.0
	var top := PackedVector2Array([Vector2(cx - 70.0, -40.0), Vector2(cx + 70.0, -40.0), Vector2(cx + 480.0, floor_y), Vector2(cx - 480.0, floor_y)])
	draw_polygon(top, PackedColorArray([Color(1, 0.96, 0.85, 0.22), Color(1, 0.96, 0.85, 0.22), Color(1, 0.96, 0.85, 0.05), Color(1, 0.96, 0.85, 0.05)]))
	for k in 6:
		var rx := 520.0 - k * 70.0
		var ry := 90.0 - k * 12.0
		var pool := PackedVector2Array()
		for i in 48:
			pool.append(Vector2(cx, floor_y) + Vector2(cos(TAU * i / 48.0) * rx, sin(TAU * i / 48.0) * ry))
		draw_colored_polygon(pool, Color(1, 0.95, 0.8, 0.05 + k * 0.03))
	var hits := int(pickup.get("hits", 0))
	var need := int(pickup.get("need", 1))
	var open := hits >= need
	var kind := String(pickup.get("kind", "pickup"))
	var shake := Vector2(sin(clock * 70.0), cos(clock * 53.0)) * 10.0 * pickup_shake / 0.35
	var title := "TIP JAR" if kind == "cash" else "PICKUP"
	_text_center(Rect2(0.0, 90.0, UI_W, 60.0), title, T_LG, Color(1, 0.95, 0.8, 0.8), true)
	if not open:
		var obj := Rect2(cx - 200.0, floor_y - 300.0, 400.0, 300.0)
		if kind == "cash":
			_draw_tip_jar(Vector2(cx, floor_y) + shake, false)
		else:
			_draw_package(Vector2(cx, floor_y) + shake, hits)
		var hot := obj.has_point(mouse)
		if hot:
			draw_arc(Vector2(cx, floor_y - 150.0), 230.0, 0.0, TAU, 64, Color(1, 0.95, 0.8, 0.15), 3.0, true)
		_register(obj.grow(40.0), _hit_pickup)
		var hint := "Click the jar" if kind == "cash" else "Click to open"
		_text_center(Rect2(0.0, floor_y + 90.0, UI_W, 40.0), hint, T_MD, Color(1, 1, 1, 0.75), true)
		if need > 1:
			for k in need:
				var dc := Vector2(cx - (need - 1) * 22.0 + k * 44.0, floor_y + 160.0)
				draw_circle(dc, 10.0, Color(1, 0.85, 0.4) if k < hits else Color(1, 1, 1, 0.15))
		return
	for k in 14:
		var a := TAU * k / 14.0 + clock * 0.2
		draw_line(Vector2(cx, floor_y - 260.0), Vector2(cx, floor_y - 260.0) + Vector2.from_angle(a) * 420.0, Color(1, 0.9, 0.6, 0.06), 30.0)
	var by := floor_y + 140.0
	if kind == "cash":
		_draw_tip_jar(Vector2(cx, floor_y), true)
		_heavy_center(Rect2(0.0, floor_y - 560.0, UI_W, 120.0), "+$%d" % int(pickup["cash"]), T_HERO + 20, Color("7fe0a0"))
		_hw_button(Rect2(cx - 220.0, by, 440.0, 90.0), "Back on the road", _leave_pickup, true, Color("3f9b5a"), T_LG)
		return
	_draw_pickup_options(floor_y, by)

func _draw_card_detail(dc: Vector2, d: Disc, rad: float) -> void:
	_draw_jewel(Rect2(dc - Vector2(rad, rad), Vector2(rad, rad) * 2.0), d)
	_heavy_center(Rect2(dc.x - 270.0, dc.y + rad + 72.0, 540.0, 50.0), d.title, T_LG, Color.WHITE)
	var y := dc.y + rad + 130.0
	if d.edition != "":
		var ed: Dictionary = D.EDITIONS[d.edition]
		_text_center(Rect2(dc.x - 270.0, y, 540.0, 30.0), "%s EDITION" % String(ed["name"]).to_upper(), T_SM, Color(ed["color"]).lightened(0.3), true)
		_wrap(Vector2(dc.x - 240.0, y + 40.0), String(ed["text"]), 480.0, T_SM, Color("e8ecf2"))

func _draw_pickup_options(floor_y: float, by: float) -> void:
	var cx := UI_W * 0.5
	_heavy_center(Rect2(0.0, 170.0, UI_W, 70.0), "Take one", T_XL, Color.WHITE)
	var opts: Array = pickup["options"]
	for k in opts.size():
		var o: Dictionary = opts[k]
		var dc := Vector2(cx + (k - (opts.size() - 1) * 0.5) * 560.0, 540.0)
		if o.has("disc"):
			_draw_card_detail(dc, o["disc"], 160.0)
			_hw_button(Rect2(dc.x - 160.0, 1000.0, 320.0, 80.0), "Take this CD", _take_option.bind(k), true, Color("3f9b5a"), T_MD)
		else:
			var g: Dictionary = o["gear"]
			_text_center(Rect2(dc.x - 250.0, 360.0, 500.0, 40.0), "GEAR", T_MD, c_gold, true)
			_draw_gear(Rect2(dc.x - 250.0, 420.0, 500.0, 214.0), g, 0.6 + 0.4 * sin(clock * 3.0))
			_hw_button(Rect2(dc.x - 160.0, 1000.0, 320.0, 80.0), "Install this", _take_option.bind(k), true, Color("3f9b5a"), T_MD)
	_hw_button(Rect2(cx - 150.0, by, 300.0, 70.0), "Leave them", _leave_pickup, true, Color("6a6f77"), T_MD)

func _draw_package(base: Vector2, hits: int) -> void:
	var w := 360.0
	var h := 250.0
	var body := Rect2(base.x - w * 0.5, base.y - h, w, h)
	draw_rect(Rect2(body.position + Vector2(10, 14), body.size), Color(0, 0, 0, 0.5))
	_surface(body, 4.0, "cardboard", Color("c79b63"), Color("a97e4a"), 400.0)
	_panel(body, Color(0, 0, 0, 0), 4, Color("7a5a33"), 2)
	var lift := hits * 14.0
	var lid := Rect2(body.position.x - 14.0, body.position.y - 46.0 - lift, w + 28.0, 50.0)
	draw_set_transform(lid.get_center(), deg_to_rad(-hits * 3.0), Vector2.ONE)
	var lr := Rect2(-lid.size * 0.5, lid.size)
	_surface(lr, 4.0, "cardboard", Color("d1a874"), Color("b38a55"), 400.0)
	_panel(lr, Color(0, 0, 0, 0), 4, Color("7a5a33"), 2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var tx := base.x - 22.0
	var gap := hits * 10.0
	draw_rect(Rect2(tx, body.position.y, 44.0, h * 0.5 - gap), Color("e6d3a3", 0.95))
	draw_rect(Rect2(tx, body.position.y + h * 0.5 + gap, 44.0, h * 0.5 - gap), Color("e6d3a3", 0.95))
	if hits > 0:
		for k in 5:
			var yy := body.position.y + h * 0.5 - gap + (k % 2) * 6.0
			draw_line(Vector2(tx + k * 11.0, yy), Vector2(tx + k * 11.0 + 6.0, yy + 6.0), Color("8a6a40"), 2.0)
	_heavy_center(Rect2(body.position.x + 40.0, body.position.y + 70.0, 100.0, 110.0), "?", T_HERO, Color("4a3222", 0.7))
	_text_center(Rect2(body.end.x - 150.0, body.end.y - 70.0, 130.0, 30.0), "FRAGILE", 15, Color("b03a2e"), true)

func _draw_tip_jar(base: Vector2, empty: bool) -> void:
	var w := 230.0
	var h := 280.0
	var jar := Rect2(base.x - w * 0.5, base.y - h, w, h)
	draw_rect(Rect2(jar.position + Vector2(10, 14), jar.size), Color(0, 0, 0, 0.4))
	if not empty:
		for k in 7:
			var br := Rect2(jar.position.x + 20.0 + (k % 3) * 60.0, jar.end.y - 60.0 - (k / 3) * 46.0, 70.0, 36.0)
			_panel(br, Color("7fb98a").darkened(k * 0.04), 3, Color("3f6e48"), 1)
			_text_center(br, "$", 18, Color("2f5a38"), true)
	_panel(jar, Color(0.75, 0.88, 0.95, 0.18), 30, Color(0.85, 0.95, 1.0, 0.6), 3)
	draw_line(jar.position + Vector2(26, 30), Vector2(jar.position.x + 26.0, jar.end.y - 30.0), Color(1, 1, 1, 0.35), 6.0)
	var rim := Rect2(jar.position.x - 10.0, jar.position.y - 26.0, w + 20.0, 34.0)
	_panel(rim, Color("9aa0a6"), 8, Color("5d626a"), 2)
	var lab := Rect2(jar.position.x + 30.0, jar.position.y + 80.0, w - 60.0, 60.0)
	_panel(lab, Color("fbfaf5"), 3)
	_heavy_center(lab, "TIPS", T_LG, Color("b03a2e"))
