extends RefCounted
## Builds pitched loops from MIDI pattern templates and one-sample-per-note instruments.
##
## A template (patterns/<type>_<words>.mid) fixes the rhythm and the melodic shape. Each note
## becomes a step of A minor pentatonic relative to A. A run's seed then picks, per card, an
## instrument, a starting step (which notes) and an octave, and the loop is mixed from the
## instrument's note samples (instruments/<dir>/<note>.wav) into one looping AudioStreamWAV.

const D := preload("res://prototypes/loop_deck/loop_deck_data.gd")
const PENTA: Array[int] = [0, 3, 5, 7, 10]
# Semitones above the key's root for each pentatonic step. Patterns are written in minor;
# a major key raises the minor 3rd to a major 3rd and turns the minor 7th into the 6th, so
# triads and arpeggios (A C E) become major (C E G in C major) and every melody keeps its shape.
const DEG_MINOR: Array[int] = [0, 3, 5, 7, 10]
const DEG_MAJOR: Array[int] = [0, 4, 5, 7, 9]
# Played-as-written patterns keep every note (A natural minor and anything chromatic). In a
# major key the minor 3rd, 6th and 7th above A are raised (C, F, G become C#, F#, G# in A major).
const SCALE_MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 10]
const SCALE_MAJOR: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const MAJOR_RAISE := {3: 4, 8: 9, 10: 11}
const A3 := 57
const NOTE_SEMI := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const SMALL_WORDS: Array[String] = ["and", "of", "the", "a", "on", "in"]

var templates: Array = []
var key_root := 0
var key_major := false
var specs := {}
var streams := {}
var _notes_by_dir := {}
var _pcm := {}
var _lock := Mutex.new()
var _thread: Thread
var _stop := false


## Loads every MIDI file in `dir`. Each track with notes becomes one template, titled with the
## track's name (or the file name). The loop type comes from a file-name prefix (rhythm_, bass_,
## chord_, lead_) or, without one, is guessed from the notes. `as_written` keeps the pattern on
## the notes it was written on (only the key changes); `variants` is how many cards (each with a
## different instrument) a template makes, 0 for D.GEN_VARIANTS.
func load_templates(dir: String = D.PATTERN_DIR, as_written: bool = false, variants: int = 0) -> void:
	templates.clear()
	if not DirAccess.dir_exists_absolute(dir):
		push_warning("No pattern folder at %s" % dir)
		return
	var files := Array(DirAccess.get_files_at(dir))
	files.sort()
	for f: String in files:
		f = f.trim_suffix(".import").trim_suffix(".remap")
		if not f.get_extension().to_lower() in ["mid", "midi"]:
			continue
		var base := f.get_basename().to_lower()
		var words := Array(base.split("_", false))
		var prefix := String(D.PATTERN_TYPES.get(words[0] if words.size() > 1 else "", ""))
		var tracks := parse_midi(FileAccess.get_file_as_bytes(dir.path_join(f)))
		if tracks.is_empty():
			push_warning("Pattern %s has no notes" % f)
		var used := {}
		for ti in tracks.size():
			var tr: Dictionary = tracks[ti]
			var notes: Array = tr["notes"]
			# A track name may start with the type: "Lead Falling", "Rhythm - Prowl".
			var title := String(tr["name"]).strip_edges()
			var genre := prefix
			var m := _TYPE_PREFIX.search(title)
			if m != null:
				genre = String(D.PATTERN_TYPES[m.get_string(1).to_lower()])
				title = m.get_string(2).strip_edges()
			if genre == "":
				genre = _guess_type(notes)
			if title == "":
				title = _title(words.slice(1) if prefix != "" else words)
			var id := base
			if tracks.size() > 1:
				id = "%s_%s" % [base, title.to_lower().validate_node_name().replace(" ", "_")]
			while used.has(id):
				id += "_%d" % (ti + 1)
			used[id] = true
			id = id.replace("#", "")
			var tags: Array = Array(title.to_lower().split(" ", false))
			templates.append({"id": id, "title": title, "genre": genre, "tags": tags, "notes": notes, "as_written": as_written, "variants": variants, "file": f})


## Lead unless the track is low (bass) or plays several notes at once (chords).
static var _TYPE_PREFIX := _type_prefix()


static func _type_prefix() -> RegEx:
	var r := RegEx.new()
	r.compile("(?i)^(%s)(?:[ :_-]+(.*))?$" % "|".join(D.PATTERN_TYPES.keys()))
	return r


func _guess_type(notes: Array) -> String:
	var lo := 127
	var starts := {}
	var stacked := 0
	for n: Dictionary in notes:
		lo = mini(lo, int(n["pitch"]))
		var k := snappedf(float(n["beat"]), 0.01)
		if starts.has(k):
			stacked += 1
		starts[k] = true
	if stacked * 2 >= notes.size():
		return "Chord"
	if lo < 48:
		return "Rhythm"
	return "Lead"


## Reads a standard MIDI file (format 0 or 1) into its tracks: {name, notes}, where each note
## is beat, len (beats), pitch and vel. Tracks without notes and drum notes (MIDI channel 10)
## are left out. Only note on/off is used; tempo and time signature are ignored.
func parse_midi(b: PackedByteArray) -> Array:
	var out: Array = []
	if b.size() < 14 or b.slice(0, 4).get_string_from_ascii() != "MThd":
		return out
	var tracks := _u16(b, 10)
	var div := _u16(b, 12)
	if div == 0 or div & 0x8000:
		return out
	var p := 8 + _u32(b, 4)
	for _t in tracks:
		if p + 8 > b.size() or b.slice(p, p + 4).get_string_from_ascii() != "MTrk":
			break
		var end := mini(p + 8 + _u32(b, p + 4), b.size())
		var q := p + 8
		var tick := 0
		var run := 0
		var open := {}
		var notes: Array = []
		var name := ""
		while q < end:
			var dv := _varlen(b, q)
			tick += dv[0]
			q = dv[1]
			if q >= end:
				break
			var c := b[q]
			if c == 0xFF:
				var ml := _varlen(b, q + 2)
				if b[q + 1] == 0x03 and name == "":
					name = b.slice(ml[1], ml[1] + ml[0]).get_string_from_utf8()
				q = ml[1] + ml[0]
				continue
			if c == 0xF0 or c == 0xF7:
				var sl := _varlen(b, q + 1)
				q = sl[1] + sl[0]
				continue
			if c & 0x80:
				run = c
				q += 1
			var hi := run & 0xF0
			if hi == 0xC0 or hi == 0xD0:
				q += 1
				continue
			if q + 1 >= end:
				break
			var key := (run & 0x0F) * 128 + b[q]
			var vel := b[q + 1]
			q += 2
			if (run & 0x0F) == 9:
				continue
			if hi == 0x90 or hi == 0x80:
				if open.has(key):
					var o: Array = open[key]
					notes.append({"beat": float(o[0]) / div, "len": float(tick - int(o[0])) / div, "pitch": key % 128, "vel": int(o[1])})
					open.erase(key)
				if hi == 0x90 and vel > 0:
					open[key] = [tick, vel]
		for key in open:
			var o: Array = open[key]
			notes.append({"beat": float(o[0]) / div, "len": maxf(0.25, float(tick - int(o[0])) / div), "pitch": int(key) % 128, "vel": int(o[1])})
		p = end
		notes = notes.filter(func(n): return float(n["len"]) > 0.0)
		if notes.is_empty():
			continue
		notes.sort_custom(func(a, c): return float(a["beat"]) < float(c["beat"]))
		out.append({"name": name, "notes": notes})
	return out


## Makes D.GEN_VARIANTS cards per template. `pool` maps a type name to album dictionaries
## whose points, rarity and ability the generated cards borrow.
## `root` is the key's root in semitones above A (-6 to 5); `major` picks major or minor.
func make_albums(seed_n: int, pool: Dictionary, root: int = 0, major: bool = false) -> Array:
	finish()
	key_root = root
	key_major = major
	specs.clear()
	streams.clear()
	var rg := RandomNumberGenerator.new()
	rg.seed = seed_n
	var out: Array = []
	for t: Dictionary in templates:
		var genre := String(t["genre"])
		var voices := voices_for(genre)
		if voices.is_empty():
			continue
		_shuffle(voices, rg)
		var borrow: Array = pool.get(genre, [])
		var count := int(t.get("variants", 0))
		count = mini(count, voices.size()) if count > 0 else D.GEN_VARIANTS
		for v in count:
			var id := "%s#%d" % [t["id"], v]
			var voice := String(voices[v % voices.size()])
			specs[id] = {"voice": voice, "genre": genre, "notes": _arrange(t, voice, rg)}
			var src: Dictionary = borrow[rg.randi_range(0, borrow.size() - 1)] if not borrow.is_empty() else {}
			var rule: Dictionary = src.get("rule", {"condition": "always", "cparam": "", "effect": "none", "value": 0.0, "target": "self", "tparam": ""})
			out.append({"id": id, "title": t["title"], "orig": t["title"], "band": voice, "cover": "", "song": "gen://" + id, "genre": maxi(0, D.GENRES.find(genre)), "era": 0, "label": (absi(id.hash()) / 7) % D.LABELS.size(), "points": int(src.get("points", 4)), "rule": rule.duplicate(true), "rarity": String(src.get("rarity", "common")), "starter": false, "hook": -1.0, "instrument": voice, "tags": t["tags"]})
	return out


func voices_for(genre: String) -> Array:
	var out: Array = []
	for name in D.VOICES:
		var v: Dictionary = D.VOICES[name]
		if genre in v["roles"] and not _notes(String(v["dir"])).is_empty():
			out.append(name)
	return out


## The loop for a generated card, mixed on first use (about 0.1 s) and then kept.
func stream(id: String) -> AudioStreamWAV:
	_lock.lock()
	if not streams.has(id) and specs.has(id):
		streams[id] = _render(specs[id])
	var s: AudioStreamWAV = streams.get(id)
	_lock.unlock()
	return s


## Mixes these cards' loops on a background thread, in order, so they are ready to play.
func warm(ids: Array) -> void:
	finish()
	_stop = false
	_thread = Thread.new()
	_thread.start(func():
		for id in ids:
			if _stop:
				break
			stream(String(id)))


## Stops background mixing. Call before quitting.
func finish() -> void:
	if _thread != null:
		_stop = true
		_thread.wait_to_finish()
		_thread = null


func _arrange(t: Dictionary, voice: String, rg: RandomNumberGenerator) -> Array:
	var genre := String(t["genre"])
	var offs: Array = D.GEN_OFFSETS["major" if key_major else "minor"][genre]
	var written := bool(t.get("as_written", false))
	var shift := 0 if written else int(offs[rg.randi_range(0, offs.size() - 1)])
	var deg: Array[int] = DEG_MAJOR if key_major else DEG_MINOR
	var pitches: Array = []
	for n: Dictionary in t["notes"]:
		pitches.append(_written_pitch(int(n["pitch"])) if written else _key_pitch(_step(int(n["pitch"])) + shift, deg))
	var have := _notes(String(D.VOICES[voice]["dir"]))
	var rr: Array = D.GEN_RANGES[genre]
	var lo := maxi(int(rr[0]), int(have.keys().min()))
	var hi := mini(int(rr[1]), int(have.keys().max()))
	var pmin := int(pitches.min())
	var pmax := int(pitches.max())
	var fits: Array = []
	var best := 0
	var best_over := 1 << 30
	for o in range(-5, 6):
		var plo := pmin + o * 12
		var phi := pmax + o * 12
		var over := maxi(0, lo - plo) + maxi(0, phi - hi)
		if over == 0:
			fits.append(o)
		elif over < best_over:
			best_over = over
			best = o
	var oct := int(fits[rg.randi_range(0, fits.size() - 1)]) if not fits.is_empty() else best
	if written and not fits.is_empty():
		for o in fits:
			if absi(int(o)) < absi(oct):
				oct = int(o)
	var out: Array = []
	for i in pitches.size():
		var n: Dictionary = t["notes"][i]
		var p := int(pitches[i]) + oct * 12
		while p < lo:
			p += 12
		while p > hi:
			p -= 12
		out.append({"beat": n["beat"], "len": n["len"], "pitch": p, "vel": float(n["vel"]) * rg.randf_range(0.92, 1.05)})
	return out


func _render(spec: Dictionary) -> AudioStreamWAV:
	var rate := D.GEN_RATE
	var beat_f := 60.0 / D.BPM * rate
	var frames := int(round(beat_f * D.BEATS_PER_BAR * D.LOOP_BARS))
	var buf := PackedFloat32Array()
	buf.resize(frames)
	buf.fill(0.0)
	var vd: Dictionary = D.VOICES[spec["voice"]]
	var dir := String(vd["dir"])
	var rel := maxi(1, int(float(vd["release"]) * rate))
	for n: Dictionary in spec["notes"]:
		var smp := _sample(dir, int(n["pitch"]))
		if smp.is_empty():
			continue
		var data: PackedFloat32Array = smp["data"]
		var ratio: float = float(smp["ratio"]) * float(smp["rate"]) / rate
		var start := int(round(float(n["beat"]) * beat_f)) % frames
		var hold := int(float(n["len"]) * beat_f)
		var g := float(n["vel"]) / 110.0
		var count := mini(hold + rel, int(float(data.size() - 2) / ratio))
		var j := start
		for i in count:
			var e := g if i < hold else g * (1.0 - float(i - hold) / rel)
			var x: float
			if ratio == 1.0:
				x = data[i]
			else:
				var pos := i * ratio
				var k := int(pos)
				x = lerpf(data[k], data[k + 1], pos - k)
			buf[j] += x * e
			j += 1
			if j >= frames:
				j = 0
	var sum := 0.0
	var peak := 0.0
	for x in buf:
		sum += x * x
		peak = maxf(peak, absf(x))
	var rms := sqrt(sum / frames)
	var gain := float(D.GEN_RMS.get(spec["genre"], 0.08)) / rms if rms > 0.0 else 1.0
	if peak * gain > 0.97:
		gain = 0.97 / peak
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		bytes.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = frames
	return w


## The nearest note sample for `pitch`, with the playback ratio that tunes it to `pitch`.
func _sample(dir: String, pitch: int) -> Dictionary:
	var have := _notes(dir)
	if have.is_empty():
		return {}
	var near := pitch
	if not have.has(pitch):
		var bd := 999
		for k in have:
			if absi(int(k) - pitch) < bd:
				bd = absi(int(k) - pitch)
				near = int(k)
	var path := String(have[near])
	if not _pcm.has(path):
		_pcm[path] = _read_pcm(path)
	var pcm: Dictionary = _pcm[path]
	if pcm.is_empty():
		return {}
	return {"data": pcm["data"], "rate": pcm["rate"], "ratio": pow(2.0, float(pitch - near) / 12.0)}


func _read_pcm(path: String) -> Dictionary:
	var w := load(path) as AudioStreamWAV
	if w == null or w.format != AudioStreamWAV.FORMAT_16_BITS:
		push_warning("%s must be an uncompressed 16-bit WAV (Import > Compress: Disabled)" % path)
		return {}
	var bytes := w.data
	var ch := 2 if w.stereo else 1
	var n := bytes.size() / (2 * ch)
	var out := PackedFloat32Array()
	out.resize(n)
	if ch == 1:
		for i in n:
			out[i] = bytes.decode_s16(i * 2) / 32768.0
	else:
		for i in n:
			out[i] = (bytes.decode_s16(i * 4) + bytes.decode_s16(i * 4 + 2)) / 65536.0
	return {"data": out, "rate": float(w.mix_rate)}


## MIDI note -> sample path for one instrument folder, from file names like A3.wav or C#4.wav.
func _notes(dir: String) -> Dictionary:
	if _notes_by_dir.has(dir):
		return _notes_by_dir[dir]
	var out := {}
	var path := D.VOICE_DIR.path_join(dir)
	if DirAccess.dir_exists_absolute(path):
		for f: String in DirAccess.get_files_at(path):
			f = f.trim_suffix(".import").trim_suffix(".remap")
			if f.get_extension().to_lower() != "wav":
				continue
			var m := _note_number(f.get_basename())
			if m >= 0:
				out[m] = path.path_join(f)
	_notes_by_dir[dir] = out
	return out


func _note_number(s: String) -> int:
	if s.length() < 2 or not NOTE_SEMI.has(s[0].to_upper()):
		return -1
	var semi := int(NOTE_SEMI[s[0].to_upper()])
	var rest := s.substr(1)
	if rest.begins_with("#"):
		semi += 1
		rest = rest.substr(1)
	elif rest.begins_with("b"):
		semi -= 1
		rest = rest.substr(1)
	if not rest.is_valid_int():
		return -1
	return 12 * (int(rest) + 1) + semi


## Pentatonic step relative to A3 (A3 = 0, C4 = 1 … A4 = 5). Notes outside the scale snap
## to the nearest scale note.
func _step(pitch: int) -> int:
	var rel := pitch - A3
	var o := floori(rel / 12.0)
	var s := posmod(rel, 12)
	var best := 0
	for i in range(1, 6):
		var semi := 12 if i == 5 else PENTA[i]
		if absi(semi - s) < absi((12 if best == 5 else PENTA[best]) - s):
			best = i
	return o * 5 + best


## A note written in A minor, moved to the current key (and to major when the key is major).
func _written_pitch(pitch: int) -> int:
	var rel := pitch - A3
	var d := posmod(rel, 12)
	if key_major:
		d = int(MAJOR_RAISE.get(d, d))
	return A3 + key_root + floori(rel / 12.0) * 12 + d


## MIDI note for a pentatonic step in the current key.
func _key_pitch(step: int, deg: Array[int]) -> int:
	return A3 + key_root + floori(step / 5.0) * 12 + deg[posmod(step, 5)]


func _title(words: Array) -> String:
	var out: Array = []
	for i in words.size():
		var w := String(words[i])
		out.append(w if i > 0 and w in SMALL_WORDS else w.capitalize())
	return " ".join(out)


func _shuffle(a: Array, rg: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rg.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _u16(b: PackedByteArray, i: int) -> int:
	return (b[i] << 8) | b[i + 1]


func _u32(b: PackedByteArray, i: int) -> int:
	return (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3]


func _varlen(b: PackedByteArray, i: int) -> Array:
	var v := 0
	while i < b.size():
		var c := b[i]
		i += 1
		v = (v << 7) | (c & 0x7F)
		if (c & 0x80) == 0:
			break
	return [v, i]
