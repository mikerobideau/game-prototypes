extends RefCounted

const CATALOG := "res://prototypes/loop_deck/art/covers/catalog.json"
const MUSIC_DIR := "res://prototypes/loop_deck/music"
const MUSIC_SECONDS := 4.0
const MUSIC_FADE := 0.8
const MENU_FADE := 1.5
const BG_DIR := "res://prototypes/loop_deck/background_music"
const BG_DB := -8.0
const BG_FADE_IN := 1.0
const BG_FADE_OUT := 0.4
const PACK_BUILD := 0.7
const PACK_BURST_WAIT := 0.1
const PACK_GAP := 0.5
const PACK_ANIM := 0.9
const HOLD_TIME := 0.6
const THUMB_DIR := "res://prototypes/loop_deck/art/thumbs/"
const THUMB_MAX := 768
const PACK_RARITY := {
	"common": {"glow": 0.12, "col": "ffffff", "damp": 5.0, "freq": 11.0, "pulse": 0.0, "speed": 0.0, "size": 0.9},
	"uncommon": {"glow": 0.32, "col": "6fc8ee", "damp": 4.0, "freq": 12.0, "pulse": 0.08, "speed": 2.0, "size": 1.0},
	"rare": {"glow": 0.5, "col": "c38bff", "damp": 3.0, "freq": 13.0, "pulse": 0.1, "speed": 2.0, "size": 1.3},
	"legendary": {"glow": 0.7, "col": "ff9a3c", "damp": 2.5, "freq": 14.0, "pulse": 0.14, "speed": 2.5, "size": 1.6},
}
const AUDITION_DB := -4.0
const TEXTURES := "res://prototypes/loop_deck/art/textures/"
# Icons: icon/genre/<genre name in lower case>.png (e.g. icon/genre/hip-hop.png) and
# icon/decade/<decade>.png (e.g. icon/decade/90s.png). Dark shapes on a transparent or white
# background; the game recolours them. Replace a file with the same name to change an icon.
const ICON_DIR := "res://prototypes/loop_deck/icon/"
const GENRES: Array[String] = ["Percussion", "Rhythm", "Chord", "Lead"]
const GENRE_SHORT: Array[String] = ["PERC", "RHYTHM", "CHORD", "LEAD"]
const GENRE_COLORS: Array[String] = ["5d626a", "5d626a", "5d626a", "5d626a"]
const COND_WEIGHTS := {"plain": 6, "odd": 2, "even": 2, "opener": 3, "closer": 3, "after_genre": 7, "after_decade": 6, "hype": 10, "boost": 8, "fans": 8, "anthem": 8, "mirror": 5}
const RARITY_WEIGHTS := {"common": 20, "uncommon": 55, "rare": 25}
const GEAR_PATH := "res://prototypes/loop_deck/data/gear.json"
const CARDS_PATH := "res://prototypes/loop_deck/data/cards.json"
const DECKS_PATH := "res://prototypes/loop_deck/data/decks.json"
const DECKS_SHOWN := 14
const PREFS_PATH := "user://loop_deck.cfg"
const END_TARGET_SCALE := 1.0
const FIN_WIND := 0.25
const FIN_STREAM := 0.7
const FIN_HOLD := 1.0
const SONG_START := 0.2
const STEP_FIRST := 0.26
const STEP_RAMP := 0.02
const STEP_MIN := 0.11
const SONG_TAIL := 0.45
const ANIM_NAMES: Array[String] = ["Fast", "Normal", "Relaxed", "Slow"]
const ANIM_SCALE: Array[float] = [1.0, 1.35, 1.8, 2.4]
const SFX_DIR := "res://prototypes/loop_deck/sound_effect/"
const SFX_FILE_DB := {"f_whoosh": -6.0, "f_money_collect": -8.0, "f_click_switch": -6.0, "f_metal_door_open": -10.0, "f_magic_spell": -6.0}
const SFX_LEVEL_NAMES: Array[String] = ["Off", "Low", "Medium", "High"]
const SFX_LEVEL_DB: Array[float] = [-80.0, -10.0, -4.0, 0.0]
const HOOK_BASE := 1.2
const HOOK_PER_EVENT := 0.25
const HOOK_MAX := 3.0
const HOOK_LAST_BONUS := 0.8
const HOOK_FADE_IN := 0.12
const CHAIN_STEP_FIRST := 0.35
const CHAIN_STEP_LAST := 0.12
const TURN_MAX_SECS := 10.0
const POP_TIME := 0.3
const STREAK_TIME := 0.15
const POP_DELAY := 0.033
const BEAT_STEP := 0.12
const BEAT_STEP_FAST := 0.07
const BEAT_MAX := 8
const HITSTOP := 0.045
const SLAM_RISER := 0.6
const SLAM_DROP := 0.15
const SLAM_SLOWMO := 0.3
const SLAM_SLOWMO_SECS := 0.25
const SKIP_SPEED := 4.0
const TAPE_FLY := 0.38
const TAPE_POOF := 0.28
const TAPE_ABSORB := 0.55
const COND_POINTS := {"plain": 12, "odd": 6, "even": 6, "opener": 8, "closer": 8, "after_genre": 7, "after_decade": 7, "hype": 4, "boost": 4, "fans": 4, "anthem": 4, "mirror": 4}
const SET_BONUS := 10
const SIDE_BONUS := 8
const OPENER_MULT := 2.0
const CLOSER_MULT := 3.0
const AFTER_MULT := 2.0
const ABOVE_MULT := 3.0
const AMP_ADD := 1.5
const SURGE_MULT := 2.5
const FANS_FLOW := 1.0
const ECHO_FLOW := 1.5
const ANTHEM_ADD := 8
const HATE_MULT := 0.5
const ERAS: Array[String] = [""]
const LABELS := [
	{"name": "Rust Belt Records", "short": "Rust Belt", "color": "b4532a"},
	{"name": "Lighthouse Sound", "short": "Lighthouse", "color": "1f4e79"},
	{"name": "Comet Tapes", "short": "Comet", "color": "d9821c"},
	{"name": "Night Owl", "short": "Night Owl", "color": "2f6b4f"},
]

const SOUND_COLOR := "3fae5a"
const ENERGY_COLOR := "8a63d2"
const HYPE_COLOR := "e9b949"
const FLOW_COLOR := "4ab3d9"
const SLEEVE_MAIN: Array[String] = ["B23A3A", "1E8A6E", "5E48B5", "C27C0E"]
const SLEEVE_DARK: Array[String] = ["7A2222", "125C49", "3D2E80", "804F06"]
const SLEEVE_LIGHT: Array[String] = ["FBE9E7", "E3F4EE", "EEEBFB", "FCF0DA"]

const COLLECTION := 20
const HAND := 6
const SETLIST := 4
const TRAYS := 6
const SHOW_SORT := false
const TURNS := 4
const TURN_BONUS := 1
const COOL_NEED := 0.2
const COOL_HEAL := 0.12
const DEMAND_HEAL := 0.12
const STATIC_KEEP := 0.5
const MOVE_WEIGHTS := {"cool": 3, "boo": 3, "demand": 3, "static": 2, "block": 2}
const RUN_GIGS := 8
const BOSS_EVERY := 3
const CROWD_MOVES := false
const BOSS_TIERS := 5
const PURIST_TIERS: Array[float] = [0.8, 0.7, 0.6, 0.5, 0.4]
const CRITIC_TIERS: Array[float] = [0.6, 0.5, 0.4, 0.3, 0.2]
const TURN_ALLOWANCE := 3
const BOSS_INTRO_SECS := 2.6 # red vignette + "Incoming Boss" banner at the start of a boss gig
const MOVE_FLASH_SECS := 1.6 # highlight on the boss ability row when it changes
const DIGS := 2
const DIG_MAX := 1
const DIG_OFFERS := 3
const DIG_PICK := false

const FLOW_MAX := 6
const GIG_TARGETS: Array[int] = [100, 130, 110, 200, 260, 265, 350, 455, 595, 780, 1020, 1330, 1730, 2250, 2925]
const HEADLINER_MULT := 1.25
const PURIST_MULT := 0.65
const BOSSES := [
	{"venue": "The Grand Ballroom", "title": "Heckler King", "kind": "heckler"},
	{"venue": "Riverside Amphitheater", "title": "The Purist", "kind": "purist"},
	{"venue": "The Palladium", "title": "The Critic", "kind": "critic"},
	{"venue": "The Velvet Room", "title": "Sound Engineer", "kind": "engineer"},
	{"venue": "Starlight Arena", "title": "Label Exec", "kind": "exec"},
]
const BOSS_TARGET := 1.3
const TIER_GOOD := 1.5
const TIER_GREAT := 2.0
const EQ_UNIT := 3
const KITS := [
	{"name": "Chain Gang", "idea": "Buff the next loop and build long chains.", "gear": "sax", "lean": ["genre", "Jazz"]},
	{"name": "Showstopper", "idea": "Open big and close bigger.", "gear": "fog", "lean": ["genre", "Rock"]},
	{"name": "Type Streak", "idea": "Stack one type and watch it snowball.", "gear": "reverb", "lean": ["genre", "Pop"]},
	{"name": "Crowd Pleaser", "idea": "Steady points from variety and a full set.", "gear": "tube", "lean": ["era", "90s"]},
]
const CDR_POINTS := 3
const LIKE := 5
const REQUEST := 10
const CALL_CHANCE := 0.55
const REQUEST_SONGS := 2


const VENUES := [
	{"name": "Basement Show", "likes": [["genre", "Rock"], ["era", "90s"]], "dislikes": [["genre", "Jazz"]]},
	{"name": "Wedding Reception", "likes": [["genre", "Pop"], ["era", "80s"]], "dislikes": [["genre", "Hip-Hop"]]},
	{"name": "Coffeehouse", "likes": [["genre", "Jazz"], ["genre", "Pop"]], "dislikes": [["genre", "Rock"]]},
	{"name": "Block Party", "likes": [["genre", "Hip-Hop"], ["genre", "Pop"]], "dislikes": [["genre", "Jazz"]]},
	{"name": "Festival Tent", "likes": [["genre", "Rock"], ["era", "10s"]], "dislikes": [["era", "60s"]]},
	{"name": "Record Store Day", "likes": [["genre", "Hip-Hop"], ["era", "70s"]], "dislikes": [["era", "10s"]]},
]

const USE_FORK := false
const TOURS := 2
const LANE_GIGS := 3
const PICKUPS_ENABLED := false
const BOSS_DEBUFF_MULT := 0.5
const BOSS_DESTROY := 0.2
const BOSS_DIGS := 0
const BOSS_KINDS: Array[String] = ["genre", "era", "slot", "hates", "target", "gear", "destroy", "discards"]
const ROAD_COMBOS := [
	{"stops": ["pickup", "pickup"], "weight": 25},
	{"stops": ["pickup", "shop"], "weight": 40},
	{"stops": ["cash", "pickup"], "weight": 20},
	{"stops": ["shop", "pickup"], "weight": 15},
]
const TOUR_GIGS := 3
const GIG_CHOICES := [1, 2]
const REWARDS_BETWEEN := 2
const REWARD_ROWS := [2, 3]
const CASH_CHANCE := 0.5
const SECOND_ROAD := 0.35
const REVEAL_CLICKS := 3
const CASH_REWARD := [4, 8]
const PICKUP_GEAR_CHANCE := 0.3
const PICKUP_GEAR_PITY := 2
const PICKUP_CHOICES := 3
const HEADLINER_NAMES: Array[String] = ["The Grand Ballroom", "Riverside Amphitheater", "The Palladium", "Starlight Arena"]
const TOWNS: Array[String] = ["Rustfield", "Lake Halcyon", "Cedar Bluff", "Port Amber", "Millbrook", "Granite Falls", "Fairhaven", "Copper Ridge", "Elk Hollow", "New Bristol", "Saltmarsh", "Pinecrest", "Wolf Creek", "Hadley", "Ironton", "Sparrow Bay", "Kettle Rock", "Brightwater", "Old Mesa", "Juniper", "Harlow", "Dunmore", "Silver Lake", "Bramblewood", "Northgate", "Canyon City", "Larkspur", "Tinley", "Marigold", "Stonebridge"]

const GIGS := 8
const TARGETS: Array[int] = [90, 120, 160, 210, 270, 350, 450, 580]
const START_CASH := 15
const PAY_TURN := 2
const PAY_DISCARD := 2
const INTEREST_PER := 5
const INTEREST_CAP := 0
const USE_KITS := false
const TRAIT_PERC_FLOW := 0.5
const TRAIT_RHYTHM_FLOW := 0.5
const TRAIT_CHORD_FLOW := 0.5
const TRAIT_LEAD_FLOW := 0.25
const BPM := 100.0
const BEATS_PER_BAR := 4
const LOOP_BARS := 2
const LOOP_FADE_OUT := 0.6
const LOOP_DB := -6.0
const KEY_NAME := "A minor pentatonic"
# Key decks: Choose Deck offers one deck per major key. Every deck plays the I-V-vi-IV
# progression in its key; generated loops and the pad are moved to the chosen key.
const KEY_DECKS := true
const KEY_ROOTS: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]
const KEY_MODES: Array[String] = ["major", "minor"]
const KEY_SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
# A minor key uses the notes of its relative major (A minor: C major). Names are spelled with
# flats when that major key has flats (F, Bb, Eb, Ab, Db), so D minor shows Bb and C minor Eb.
const FLAT_PARENTS: Array[int] = [5, 10, 3, 8, 1]
# Spine labels for every instrument a card can have.
const INSTRUMENTS := {
	"Gated Kit": "GATED",
	"Analog Kit": "ANALOG",
	"Saw Bass": "SAW BASS",
	"Pulse Bass": "PULSE BASS",
	"Sub Bass": "SUB BASS",
	"Saw Lead": "SAW LEAD",
	"Square Lead": "SQUARE",
	"PWM Lead": "PWM",
	"Synth Pluck": "PLUCK",
	"Brass": "BRASS",
}

# --- Synthwave loops (loop_deck_gen.gd) ---
# Every card is built each run from a MIDI pattern: the demo patterns in PATTERN_DIR and your own
# files in MIDI_DIR. Pitched patterns are written in C major over a C chord; drum patterns use
# MIDI channel 10. Each CD tray gets a random chord from the deck's key every turn, after the
# shop closes; a set's progression is the chords of the trays it plays, in order, one bar per
# card. Each bar of a loop is moved along the scale to its chord, then to the deck's key.
const GEN_LOOPS := true
const PATTERN_DIR := "res://prototypes/loop_deck/patterns"
const MIDI_DIR := "res://prototypes/loop_deck/midi"
const GENERATED_DIR := "res://prototypes/loop_deck/generated_midi"
# Folders the cards come from: [folder, source]. "generated" is the 100-card set made by
# tools/make_generated_midi.py. Add [PATTERN_DIR, "demo"] or [MIDI_DIR, "midi"] for the demo
# patterns or your own MIDI (every card of yours goes in each starting deck).
const CARD_DIRS := [[GENERATED_DIR, "generated"]]
# A folder's card sheet (one row per MIDI file: title, type, rarity, points, ability). A file with
# a row makes exactly one card with that ability; a file without one makes GEN_VARIANTS cards
# that borrow abilities from cards.json.
const CARD_SHEET := "cards.csv"
const VOICE_DIR := "res://prototypes/loop_deck/instruments"
const PATTERN_TYPES := {"rhythm": "Rhythm", "bass": "Rhythm", "chord": "Chord", "lead": "Lead", "drums": "Percussion", "drum": "Percussion", "perc": "Percussion", "percussion": "Percussion"}
# Longest pattern, in bars (shorter ones repeat).
const PATTERN_MAX_BARS := 4
# Chords a tray can get, as the scale degree of the chord's root in the key's major scale (the
# relative major for a minor key: A minor's i is degree 5, A, of C major). Diminished chords are
# left out. Numerals are shown with the chord's name on each tray, e.g. "V - G".
const CHORDS_MAJOR: Array[int] = [0, 1, 2, 3, 4, 5]
const CHORDS_MINOR: Array[int] = [5, 0, 1, 2, 3, 4]
const NUMERALS_MAJOR: Array[String] = ["I", "ii", "iii", "IV", "V", "vi", "vii°"]
const NUMERALS_MINOR: Array[String] = ["i", "ii°", "III", "iv", "v", "VI", "VII"]
# Cards per pattern, each on a different instrument: demo patterns and your own MIDI tracks.
const GEN_VARIANTS := 2
const MIDI_CARDS := 4
const GEN_RATE := 32000
# Instrument name: sample folder, loop types it may play, release (seconds) after a note ends.
# Kits play each drum sample to its end (DRUM_FILES maps MIDI drum notes to sample names).
const VOICES := {
	"Gated Kit": {"dir": "kit_gated", "roles": ["Percussion"], "release": 0.0, "drums": true},
	"Analog Kit": {"dir": "kit_analog", "roles": ["Percussion"], "release": 0.0, "drums": true},
	"Saw Bass": {"dir": "saw_bass", "roles": ["Rhythm"], "release": 0.04},
	"Pulse Bass": {"dir": "pulse_bass", "roles": ["Rhythm"], "release": 0.04},
	"Sub Bass": {"dir": "sub_bass", "roles": ["Rhythm"], "release": 0.05},
	"Saw Lead": {"dir": "saw_lead", "roles": ["Lead"], "release": 0.08},
	"Square Lead": {"dir": "square_lead", "roles": ["Lead"], "release": 0.06},
	"PWM Lead": {"dir": "pwm_lead", "roles": ["Lead"], "release": 0.08},
	"Synth Pluck": {"dir": "synth_pluck", "roles": ["Lead", "Chord"], "release": 0.1},
	"Brass": {"dir": "brass", "roles": ["Chord"], "release": 0.1},
}
const DRUM_FILES := {35: "kick", 36: "kick", 37: "rim", 38: "snare", 40: "snare", 39: "clap", 42: "hat_closed", 44: "hat_closed", 46: "hat_open", 51: "hat_open", 41: "tom_low", 43: "tom_low", 45: "tom_low", 47: "tom_mid", 48: "tom_mid", 50: "tom_high", 49: "crash", 57: "crash"}
# MIDI note range each loop type is played in (E1-G3 bass, C3-G5 chords, C4-G6 leads).
const GEN_RANGES := {"Rhythm": [28, 55], "Chord": [48, 79], "Lead": [60, 91]}
# Loudness (RMS) each loop is mixed to.
const GEN_RMS := {"Percussion": 0.09, "Rhythm": 0.11, "Chord": 0.07, "Lead": 0.075}
# The pad that always plays during a set: the set's chords, one bar each, as a low root plus the
# triad around middle C (C3 + C4 E4 G4 moved to each chord), in the deck's key.
const PAD_DIR := "poly_pad"
const PAD_RELEASE := 0.5
const PAD_RMS := 0.06
const PAD_NOTES: Array[int] = [48, 60, 64, 67]
const VENUE_NAMES: Array[String] = ["Basement Jam", "Open Deck Night", "Warehouse Loop", "Rooftop Session", "Club Nocturne", "Festival Tent", "Arena Soundcheck", "Main Stage"]
const REWARD_BASE := 5
const PAY_BOOED := 2
const PAY_BASE := 5
const PAY_APPLAUSE := 8
const PAY_ENCORE := 11
const BONUS_STEP := 0.25
const BONUS_MAX := 3
const RACK_SLOTS := 6
const START_RACK: Array[String] = []

const SHOP_ALBUMS := 2
const SHOP_GEAR := 2
const ALBUM_PRICE := 3
const ALBUM_PACKS := [
	{"name": "Sampler", "price": 4, "show": 3, "pick": 1},
	{"name": "Box Set", "price": 7, "show": 4, "pick": 2},
]
const GEAR_PACKS := [
	{"name": "Grab Box", "price": 6, "show": 3, "pick": 1},
	{"name": "Studio Bundle", "price": 11, "show": 3, "pick": 2},
]

const SORT_KEYS: Array[String] = ["genre", "era", "sound", "ability"]
const SORT_TEXT := {"genre": "Genre", "era": "Decade", "sound": "Points", "ability": "Ability"}

const EQ_MIN := -1
const EQ_MAX := 3
const EQ_START: Array[int] = [2, 1, 0, -1]
const EQ_ERA_START: Array[int] = [2, 1, 1, 0, -1, -1]
const LEVEL_NAMES: Array[String] = ["", "MK II", "MK III"]

const EDITION_CHANCE := 0.08
const EDITION_SHADER := "res://prototypes/loop_deck/edition.gdshader"
const SIGNATURE_FONT := "res://prototypes/loop_deck/font/Style_Script/StyleScript-Regular.ttf"
const EDITIONS := {
	"holo": {"name": "Holographic", "short": "HOLO", "text": "Plays twice: its points and its effect fire a second time.", "n": 1, "price": 6, "color": "a678f0"},
	"signed": {"name": "Signed", "short": "SIGNED", "text": "+$5 when played.", "n": 5, "price": 5, "color": "c9a227"},
	"limited": {"name": "Limited Edition", "short": "LTD", "text": "+50 points when played.", "n": 50, "price": 8, "color": "d4508f"},
	"mint": {"name": "Mint Condition", "short": "MINT", "text": "+5 flow when played.", "n": 5, "price": 4, "color": "3fae5a"},
}

const SERVICES_MAX := 2
const SERVICE_CHANCE := {"enhance": 0.45, "tweak": 0.5, "upgrade": 0.45}
const TWEAK_PRICE := 3
const UPGRADE_PRICE := 6
const UPGRADE_POINTS := 2
const TRADE_PRICE := 2
const CONSUMABLE_SLOTS := 2
const CONSUMABLE_OFFERS := 2
const CONSUMABLES := {
	"polish": {"name": "Polish", "text": "One loop gains +2 base points, for good.", "target": "cd", "price": 5, "rarity": "uncommon", "col": "2f9d8c"},
	"dub": {"name": "Dub", "text": "Add a copy of one loop to your deck.", "target": "cd", "price": 5, "rarity": "uncommon", "col": "2f9d8c"},
	"press": {"name": "Press", "text": "Give one loop a random edition: holographic, signed, limited or mint.", "target": "cd", "price": 4, "rarity": "uncommon", "col": "2f9d8c"},
	"trade_in": {"name": "Trade In", "text": "Remove one loop from your deck for good.", "target": "cd", "price": 2, "rarity": "common", "col": "2f9d8c"},
	"tune_up": {"name": "Tune-Up", "text": "Level up one Stomp Box that supports it, to MK II and then MK III.", "target": "gear", "price": 6, "rarity": "rare", "col": "6b4fb8"},
	"amp_up": {"name": "Amp Up", "text": "+1 flow for the rest of this turn.", "target": "", "price": 2, "rarity": "common", "col": "d9a62e"},
	"master_tape": {"name": "Master Tape", "text": "One loop gains +4 base points and a random edition, if it has none.", "target": "cd", "price": 7, "col": "2f9d8c", "rarity": "rare"},
	"overdrive": {"name": "Overdrive", "text": "Multiply your flow by 1.5 for the rest of this turn.", "target": "", "price": 6, "col": "d9a62e", "rarity": "rare"},
	"patch_bay": {"name": "Patch Bay", "text": "Swap two Stomp Boxes in your rig, or move one into an empty bay.", "target": "gear", "price": 3, "rarity": "uncommon", "col": "6b4fb8"},
	"hype_reel": {"name": "Hype Reel", "text": "+3 flow for the rest of this turn.", "target": "", "price": 6, "rarity": "rare", "col": "d9a62e"},
	"bootleg": {"name": "Bootleg", "text": "Add two copies of one loop to your deck.", "target": "cd", "price": 7, "rarity": "rare", "col": "2f9d8c"},
	"platinum_master": {"name": "Platinum Master", "text": "One loop gains +8 base points and a random edition, if it has none.", "target": "cd", "price": 10, "rarity": "legendary", "col": "c9772a"},
	"wall_of_sound": {"name": "Wall of Sound", "text": "Multiply your flow by 2.5 for the rest of this turn.", "target": "", "price": 10, "rarity": "legendary", "col": "c9772a"},
	"golden_ticket": {"name": "Golden Ticket", "text": "Gain $15.", "target": "", "price": 8, "rarity": "legendary", "col": "c9772a"},
}
const TAPE_WEIGHTS := {"common": 60.0, "uncommon": 30.0, "rare": 10.0, "legendary": 3.0}
const TAPE_PACK_PRICE := 6
const TAPE_PACK_SHOW := 3
const BROWSER_SHOW := 6
