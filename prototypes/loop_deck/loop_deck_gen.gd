extends RefCounted
## Builds the synthwave loops from MIDI patterns and one-sample-per-note instruments.
##
## A template is one MIDI track. Pitched tracks are written in C major over a C chord; drum
## tracks use MIDI channel 10. A loop is mixed for a chord sequence (a set's trays' chords in
## play order, one bar each): every bar's notes are moved along the C major scale to that bar's
## chord, then the whole loop is moved to the deck's key. Notes are mixed from the instrument's samples (instruments/<dir>/<note>.wav, or
## <drum>.wav for kits) into one looping AudioStreamWAV. The always-on pad is built the same way.

const D := preload("res://prototypes/loop_deck/loop_deck_data.gd")
const SCALE: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const C4 := 60
const NOTE_SEMI := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const SMALL_WORDS: Array[String] = ["and", "of", "the", "a", "on", "in"]

var templates: Array = []
## The key's major scale root (the relative major for a minor key), in semitones from C (-6..5).
var key_root := 0
## Scale degree of the key's home chord in that major scale: 0 for a major key, 5 for minor.
var tonic := 0
## Chord degrees of the set being played, in play order; empty outside a set.
var set_prog: Array = []
var specs := {}
var _cache := {}
var _notes_by_dir := {}
var _pcm := {}
var _lock := Mutex.new()
var _sample_lock := Mutex.new()
var _queue: Array = []
var _sem := Semaphore.new()
var _thread: Thread
var _stop := false


## Loads the MIDI files in each folder of D.CARD_DIRS. Each track with notes becomes one
## template, titled with the track's name (or its row in the folder's card sheet). The loop type comes from the start
## of the track name ("Lead Falling", "Rhythm - Prowl", "Drums Motorik"), else from a file-name
## prefix (lead_riff.mid), else drums if the track is on channel 10, else a guess from the notes.
func load_templates() -> void:
	templates.clear()
	var used := {}
	for entry: Array in D.CARD_DIRS:
		_load_dir(String(entry[0]), String(entry[1]), used)


## Card sheet rows by MIDI file name (lower case, no extension).
func _read_sheet(path: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var head := f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < head.size():
			continue
		var r := {}
		for i in head.size():
			r[head[i]] = row[i]
		out[String(r.get("file", "")).to_lower().trim_suffix(".mid")] = r
	return out


func _load_dir(dir: String, source: String, used: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	var sheet := _read_sheet(dir.path_join(D.CARD_SHEET))
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
		for ti in tracks.size():
			var tr: Dictionary = tracks[ti]
			var notes: Array = tr["notes"]
			var title := String(tr["name"]).strip_edges()
			var genre := prefix
			var m := _TYPE_PREFIX.search(title)
			if m != null:
				genre = String(D.PATTERN_TYPES[m.get_string(1).to_lower()])
				title = m.get_string(2).strip_edges()
			if genre == "":
				genre = "Percussion" if bool(tr["drums"]) else _guess_type(notes)
			if title == "":
				title = _title(words.slice(1) if prefix != "" else words)
			var id := base
			if tracks.size() > 1:
				id = "%s_%s" % [base, title.to_lower().validate_node_name().replace(" ", "_")]
			while used.has(id):
				id += "_%d" % (ti + 1)
			used[id] = true
			id = id.replace("#", "")
			var last := 0.0
			for n: Dictionary in notes:
				last = maxf(last, float(n["beat"]))
			var bars := 1 if last < D.BEATS_PER_BAR else (2 if last < 2 * D.BEATS_PER_BAR else D.PATTERN_MAX_BARS)
			var card: Dictionary = sheet.get(base, {}) if tracks.size() == 1 else {}
			if not card.is_empty():
				title = String(card.get("title", title))
				if D.GENRES.has(String(card.get("type", ""))):
					genre = String(card["type"])
			var tags: Array = Array(title.to_lower().split(" ", false))
			templates.append({"id": id, "title": title, "genre": genre, "tags": tags, "notes": notes, "bars": bars, "file": f, "source": source, "card": card})


static var _TYPE_PREFIX := _type_prefix()


static func _type_prefix() -> RegEx:
	var r := RegEx.new()
	r.compile("(?i)^(%s)(?:[ :_-]+(.*))?$" % "|".join(D.PATTERN_TYPES.keys()))
	return r


## Lead unless the track is low (bass) or plays several notes at once (chords).
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


## Reads a standard MIDI file (format 0 or 1) into its tracks: {name, notes, drums}, where each
## note is beat, len (beats), pitch and vel, and drums is true when most notes are on channel 10.
## Tracks without notes are left out. Only note on/off is used; tempo is ignored.
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
		var drum_hits := 0
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
			if hi == 0x90 or hi == 0x80:
				if open.has(key):
					var o: Array = open[key]
					notes.append({"beat": float(o[0]) / div, "len": float(tick - int(o[0])) / div, "pitch": key % 128, "vel": int(o[1])})
					open.erase(key)
				if hi == 0x90 and vel > 0:
					open[key] = [tick, vel]
					if (run & 0x0F) == 9:
						drum_hits += 1
		for key in open:
			var o: Array = open[key]
			notes.append({"beat": float(o[0]) / div, "len": maxf(0.25, float(tick - int(o[0])) / div), "pitch": int(key) % 128, "vel": int(o[1])})
		p = end
		notes = notes.filter(func(n): return float(n["len"]) > 0.0)
		if notes.is_empty():
			continue
		notes.sort_custom(func(a, c): return float(a["beat"]) < float(c["beat"]))
		out.append({"name": name, "notes": notes, "drums": drum_hits * 2 > notes.size()})
	return out


## Makes the run's cards: D.GEN_VARIANTS per demo pattern and D.MIDI_CARDS per track of yours,
## each on a different instrument. `pool` maps a type name to album dictionaries whose points,
## rarity and ability the cards borrow. `root` is the key's major scale root in semitones from C
## (-6 to 5) and `home` the scale degree of its home chord (0 major, 5 minor).
func make_albums(seed_n: int, pool: Dictionary, root: int = 0, home: int = 0) -> Array:
	finish()
	key_root = root
	tonic = home
	set_prog = []
	specs.clear()
	_cache.clear()
	var rg := RandomNumberGenerator.new()
	rg.seed = seed_n
	var out: Array = []
	var names: Array = D.VOICES.keys()
	for t: Dictionary in templates:
		var genre := String(t["genre"])
		var voices := voices_for(genre)
		if voices.is_empty():
			continue
		_shuffle(voices, rg)
		var borrow: Array = pool.get(genre, [])
		var card: Dictionary = t.get("card", {})
		var count := mini(D.MIDI_CARDS if t["source"] == "midi" else D.GEN_VARIANTS, voices.size())
		if not card.is_empty():
			count = 1
		for v in count:
			var id := "%s#%d" % [t["id"], v]
			var voice := String(voices[v])
			specs[id] = {"t": t, "voice": voice, "genre": genre, "seed": rg.randi()}
			var src: Dictionary = borrow[rg.randi_range(0, borrow.size() - 1)] if not borrow.is_empty() else {}
			var rule: Dictionary = (src.get("rule", {"condition": "always", "cparam": "", "effect": "none", "value": 0.0, "target": "self", "tparam": ""}) as Dictionary).duplicate(true)
			if not card.is_empty():
				# The card sheet sets this card's ability, points and rarity.
				rule = {"condition": String(card.get("condition", "always")), "cparam": String(card.get("cond_param", "")), "effect": String(card.get("effect", "none")), "value": float(card.get("value", "0")), "target": String(card.get("target", "self")) if String(card.get("target", "")) != "" else "self", "tparam": String(card.get("target_param", ""))}
				src = {"points": int(card.get("points", "4")), "rarity": String(card.get("rarity", "common"))}
			# Borrowed abilities may name an old instrument: swap in one of these.
			for k in ["cparam", "tparam"]:
				var pv := String(rule.get(k, ""))
				if pv != "" and not pv in D.GENRES and not pv in names:
					rule[k] = names[rg.randi_range(0, names.size() - 1)]
			out.append({"id": id, "title": t["title"], "orig": t["title"], "band": voice, "cover": "", "song": "gen://" + id, "genre": maxi(0, D.GENRES.find(genre)), "era": 0, "label": (absi(id.hash()) / 7) % D.LABELS.size(), "points": int(src.get("points", 4)), "rule": rule, "rarity": String(src.get("rarity", "common")), "starter": false, "hook": -1.0, "instrument": voice, "tags": t["tags"], "source": t["source"]})
	return out


func voices_for(genre: String) -> Array:
	var out: Array = []
	for name in D.VOICES:
		var v: Dictionary = D.VOICES[name]
		if not genre in v["roles"]:
			continue
		var dir := String(v["dir"])
		var ok := ResourceLoader.exists(D.VOICE_DIR.path_join(dir).path_join("kick.wav")) if v.get("drums", false) else not _notes(dir).is_empty()
		if ok:
			out.append(name)
	return out


## The loop for a card over a chord sequence (empty: the home chord, used for previews). Mixed
## on first use (about 0.1 s per bar) and kept.
func stream(id: String, prog: Array = []) -> AudioStreamWAV:
	if not specs.has(id):
		return null
	if prog.is_empty():
		prog = [tonic]
	var key := "%s|%s" % [id, _pk(prog)]
	_lock.lock()
	var s: AudioStreamWAV = _cache.get(key)
	_lock.unlock()
	if s != null:
		return s
	var sp: Dictionary = specs[id]
	var vd: Dictionary = D.VOICES[sp["voice"]]
	var ar := _arrange(sp, prog)
	s = _render(ar["notes"], String(vd["dir"]), float(vd["release"]), bool(vd.get("drums", false)), float(D.GEN_RMS.get(sp["genre"], 0.08)), int(ar["bars"]))
	_lock.lock()
	_cache[key] = s
	_lock.unlock()
	return s


## The pad over a chord sequence: each chord for one bar.
func pad_stream(prog: Array = []) -> AudioStreamWAV:
	if prog.is_empty():
		prog = [tonic]
	var key := "pad|%s" % _pk(prog)
	_lock.lock()
	var s: AudioStreamWAV = _cache.get(key)
	_lock.unlock()
	if s != null:
		return s
	var notes: Array = []
	for b in prog.size():
		for p in D.PAD_NOTES:
			notes.append({"beat": float(b * D.BEATS_PER_BAR), "len": float(D.BEATS_PER_BAR), "pitch": _chord_pitch(int(p), _steps(int(prog[b]))) + key_root, "vel": 90.0})
	s = _render(notes, D.PAD_DIR, D.PAD_RELEASE, false, D.PAD_RMS, prog.size())
	_lock.lock()
	_cache[key] = s
	_lock.unlock()
	return s


## Mixes these cards' preview loops (home chord) in the background.
func warm(ids: Array) -> void:
	var items: Array = []
	for id in ids:
		items.append([String(id), []])
	_request(items, false)


## Mixes the pad and these cards' loops for a set's chord sequence, ahead of everything else
## waiting, and drops mixes made for other sequences.
func prepare_set(ids: Array, prog: Array) -> void:
	var keep := _pk(prog)
	_lock.lock()
	for key in _cache.keys():
		var kp := String(key).get_slice("|", 1)
		if kp != keep and kp != str(tonic):
			_cache.erase(key)
	_lock.unlock()
	var items: Array = [["pad", prog]]
	for id in ids:
		items.append([String(id), prog])
	_request(items, true)


func _request(items: Array, first: bool) -> void:
	_lock.lock()
	var rest: Array = _queue.filter(func(q): return (q[1] as Array).is_empty())
	_queue = items + rest if first else _queue + items
	_lock.unlock()
	if _thread == null:
		_stop = false
		_thread = Thread.new()
		_thread.start(_work)
	_sem.post()


func _work() -> void:
	while true:
		_lock.lock()
		var item = _queue.pop_front() if not _queue.is_empty() else null
		_lock.unlock()
		if _stop:
			return
		if item == null:
			_sem.wait()
			continue
		if String(item[0]) == "pad":
			pad_stream(item[1])
		else:
			stream(String(item[0]), item[1])


## True while the background worker still has mixes waiting.
func busy() -> bool:
	_lock.lock()
	var b := not _queue.is_empty()
	_lock.unlock()
	return b


## Stops background mixing. Call before quitting.
func finish() -> void:
	if _thread != null:
		_stop = true
		_lock.lock()
		_queue.clear()
		_lock.unlock()
		_sem.post()
		_thread.wait_to_finish()
		_thread = null


## Scale steps from the written C chord to a chord degree: up to 2 steps up (ii, iii), else down
## (IV is -4, V -3, vi -2), so bass lines stay close to where they were written.
func _steps(degree: int) -> int:
	var d := posmod(degree, 7)
	return d if d <= 2 else d - 7


## Lays the template out over a chord sequence. The loop is long enough for both the pattern and
## the sequence to repeat whole (a 2-bar pattern over 3 chords is 6 bars); each pitched bar is
## moved to its chord and the deck's key, then the whole loop by octaves to fit the type's range
## and the instrument.
func _arrange(sp: Dictionary, prog: Array) -> Dictionary:
	var t: Dictionary = sp["t"]
	var voice := String(sp["voice"])
	var bpb := D.BEATS_PER_BAR
	var pb := int(t["bars"])
	var n := prog.size()
	var bars := pb * n / _gcd(pb, n)
	var drums := bool(D.VOICES[voice].get("drums", false))
	var rg := RandomNumberGenerator.new()
	rg.seed = int(sp["seed"])
	var out: Array = []
	for b in bars:
		var src_bar := b % pb
		var steps := _steps(int(prog[b % n]))
		for nt: Dictionary in t["notes"]:
			var beat := float(nt["beat"])
			if floori(beat / bpb) != src_bar:
				continue
			var p := int(nt["pitch"])
			if not drums:
				p = _chord_pitch(p, steps) + key_root
			out.append({"beat": b * bpb + beat - src_bar * bpb, "len": nt["len"], "pitch": p, "vel": float(nt["vel"]) * rg.randf_range(0.93, 1.04)})
	if drums or out.is_empty():
		return {"notes": out, "bars": bars}
	var have := _notes(String(D.VOICES[voice]["dir"]))
	var rr: Array = D.GEN_RANGES[t["genre"]]
	var lo := maxi(int(rr[0]), int(have.keys().min()))
	var hi := mini(int(rr[1]), int(have.keys().max()))
	var pmin := 127
	var pmax := 0
	for nt: Dictionary in out:
		pmin = mini(pmin, int(nt["pitch"]))
		pmax = maxi(pmax, int(nt["pitch"]))
	# The octave closest to the written one that fits; else the one that overflows least.
	var oct := 0
	var best := 1 << 30
	for o in [0, 1, -1, 2, -2, 3, -3]:
		var over: int = maxi(0, lo - (pmin + o * 12)) + maxi(0, (pmax + o * 12) - hi)
		if over < best:
			best = over
			oct = o
	for nt: Dictionary in out:
		var p := int(nt["pitch"]) + oct * 12
		while p < lo:
			p += 12
		while p > hi:
			p -= 12
		nt["pitch"] = p
	return {"notes": out, "bars": bars}


## A chord sequence as a cache key, e.g. "0,4,5".
func _pk(prog: Array) -> String:
	var parts := PackedStringArray()
	for d in prog:
		parts.append(str(int(d)))
	return ",".join(parts)


func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return maxi(1, a)


## A note written over C, moved `steps` along the C major scale (notes outside the scale keep
## their sharp). C4 E4 G4 moved -3 steps is G3 B3 D4.
func _chord_pitch(pitch: int, steps: int) -> int:
	var rel := pitch - C4
	var sm := posmod(rel, 12)
	var acc := 0
	var d := SCALE.find(sm)
	if d < 0:
		d = SCALE.find(sm - 1)
		acc = 1
	var nd := d + steps
	return C4 + (floori(rel / 12.0) + floori(nd / 7.0)) * 12 + SCALE[posmod(nd, 7)] + acc


func _render(notes: Array, dir: String, release: float, drums: bool, rms_target: float, bars: int) -> AudioStreamWAV:
	var rate := D.GEN_RATE
	var beat_f := 60.0 / D.BPM * rate
	var frames := int(round(beat_f * D.BEATS_PER_BAR * bars))
	var buf := PackedFloat32Array()
	buf.resize(frames)
	buf.fill(0.0)
	var rel := maxi(1, int(release * rate))
	for n: Dictionary in notes:
		var smp := _drum_sample(dir, int(n["pitch"])) if drums else _sample(dir, int(n["pitch"]))
		if smp.is_empty():
			continue
		var data: PackedFloat32Array = smp["data"]
		var ratio: float = float(smp["ratio"]) * float(smp["rate"]) / rate
		var start := int(round(float(n["beat"]) * beat_f)) % frames
		var g := float(n["vel"]) / 110.0
		var avail := int(float(data.size() - 2) / ratio)
		var hold := avail if drums else int(float(n["len"]) * beat_f)
		var count := mini(hold + (0 if drums else rel), avail)
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
	var gain := rms_target / rms if rms > 0.0 else 1.0
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
	var pcm := _load_pcm(String(have[near]))
	if pcm.is_empty():
		return {}
	return {"data": pcm["data"], "rate": pcm["rate"], "ratio": pow(2.0, float(pitch - near) / 12.0)}


## The kit sample for a General MIDI drum note (D.DRUM_FILES), played at its own pitch.
func _drum_sample(dir: String, pitch: int) -> Dictionary:
	if not D.DRUM_FILES.has(pitch):
		return {}
	var path := D.VOICE_DIR.path_join(dir).path_join(String(D.DRUM_FILES[pitch]) + ".wav")
	if not ResourceLoader.exists(path):
		return {}
	var pcm := _load_pcm(path)
	if pcm.is_empty():
		return {}
	return {"data": pcm["data"], "rate": pcm["rate"], "ratio": 1.0}


func _load_pcm(path: String) -> Dictionary:
	_sample_lock.lock()
	if not _pcm.has(path):
		_pcm[path] = _read_pcm(path)
	var pcm: Dictionary = _pcm[path]
	_sample_lock.unlock()
	return pcm


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


## MIDI note -> sample path for one instrument folder, from file names like A3.wav, Eb4.wav, C#4.wav.
func _notes(dir: String) -> Dictionary:
	_sample_lock.lock()
	var known: Dictionary = _notes_by_dir.get(dir, {})
	var has := _notes_by_dir.has(dir)
	_sample_lock.unlock()
	if has:
		return known
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
	_sample_lock.lock()
	_notes_by_dir[dir] = out
	_sample_lock.unlock()
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
