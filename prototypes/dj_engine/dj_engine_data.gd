extends RefCounted

const CATALOG := "res://prototypes/dj_engine/art/covers/catalog.json"
const MUSIC_DIR := "res://prototypes/dj_engine/music"
const MUSIC_SECONDS := 4.0
const MUSIC_FADE := 0.8
const MENU_FADE := 1.5
const BG_DIR := "res://prototypes/dj_engine/background_music"
const BG_DB := -8.0
const BG_FADE_IN := 1.0
const BG_FADE_OUT := 0.4
const PACK_BUILD := 0.7
const PACK_BURST_WAIT := 0.1
const PACK_GAP := 0.5
const PACK_ANIM := 0.9
const HOLD_TIME := 0.6
const THUMB_DIR := "res://prototypes/dj_engine/art/thumbs/"
const THUMB_MAX := 768
const PACK_RARITY := {
	"common": {"glow": 0.12, "col": "ffffff", "damp": 5.0, "freq": 11.0, "pulse": 0.0, "speed": 0.0, "size": 0.9},
	"uncommon": {"glow": 0.32, "col": "6fc8ee", "damp": 4.0, "freq": 12.0, "pulse": 0.08, "speed": 2.0, "size": 1.0},
	"rare": {"glow": 0.5, "col": "c38bff", "damp": 3.0, "freq": 13.0, "pulse": 0.1, "speed": 2.0, "size": 1.3},
}
const AUDITION_DB := -4.0
const TEXTURES := "res://prototypes/dj_engine/art/textures/"
# Icons: icon/genre/<genre name in lower case>.png (e.g. icon/genre/hip-hop.png) and
# icon/decade/<decade>.png (e.g. icon/decade/90s.png). Dark shapes on a transparent or white
# background; the game recolours them. Replace a file with the same name to change an icon.
const ICON_DIR := "res://prototypes/dj_engine/icon/"
const GENRES: Array[String] = ["Pop", "Rock", "Hip-Hop", "Jazz"]
const GENRE_SHORT: Array[String] = ["POP", "ROCK", "HIPHOP", "JAZZ"]
const GENRE_COLORS: Array[String] = ["5d626a", "5d626a", "5d626a", "5d626a"]
const COND_WEIGHTS := {"plain": 6, "odd": 2, "even": 2, "opener": 3, "closer": 3, "after_genre": 7, "after_decade": 6, "hype": 10, "boost": 8, "fans": 8, "anthem": 8, "mirror": 5}
const RARITY_WEIGHTS := {"common": 20, "uncommon": 55, "rare": 25}
const GEAR_PATH := "res://prototypes/dj_engine/data/gear.json"
const CARDS_PATH := "res://prototypes/dj_engine/data/cards.json"
const DECKS_PATH := "res://prototypes/dj_engine/data/decks.json"
const DECKS_SHOWN := 12
const PREFS_PATH := "user://dj_engine.cfg"
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
const HITSTOP := 0.045
const SLAM_RISER := 0.6
const SLAM_DROP := 0.15
const SLAM_SLOWMO := 0.3
const SLAM_SLOWMO_SECS := 0.25
const SKIP_SPEED := 4.0
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
const ERAS: Array[String] = ["60s", "70s", "80s", "90s", "00s", "10s"]
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
const SLEEVE_MAIN: Array[String] = ["993556", "185FA5", "534AB7", "3B6D11"]
const SLEEVE_DARK: Array[String] = ["72243E", "0C447C", "3C3489", "27500A"]
const SLEEVE_LIGHT: Array[String] = ["FBEAF0", "E6F1FB", "EEEDFE", "EAF3DE"]

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
const RUN_GIGS := 15
const BOSS_EVERY := 3
const BOSS_INTRO_SECS := 2.6 # red vignette + "Incoming Boss" banner at the start of a boss gig
const MOVE_FLASH_SECS := 1.6 # highlight on the boss ability row when it changes
const DIGS := 2
const DIG_MAX := 1
const DIG_OFFERS := 3
const DIG_PICK := false
const CATALOG_DATA := preload("res://prototypes/dj_engine/album_catalog.gd")

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
	{"name": "Chain Gang", "idea": "Buff the next song and build long chains.", "gear": "sax", "lean": ["genre", "Jazz"]},
	{"name": "Showstopper", "idea": "Open big and close bigger.", "gear": "fog", "lean": ["genre", "Rock"]},
	{"name": "Genre Streak", "idea": "Stack one genre and watch it snowball.", "gear": "reverb", "lean": ["genre", "Pop"]},
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
const TRAIT_ROCK_FLOW := 0.25
const TRAIT_HIPHOP_POINTS := 1
const TRAIT_POP_CASH := 1
const TRAIT_JAZZ_BANK := 3
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
const EDITIONS := {
	"holo": {"name": "Holographic", "short": "HOLO", "text": "+3 points on a hit.", "n": 3, "price": 6, "color": "a678f0"},
	"signed": {"name": "Signed", "short": "SIGNED", "text": "+5 points on a hit.", "n": 5, "price": 5, "color": "c9a227"},
	"limited": {"name": "Limited Edition", "short": "LTD", "text": "+8 points on a hit.", "n": 8, "price": 8, "color": "d4508f"},
	"mint": {"name": "Mint Condition", "short": "MINT", "text": "+$1 each time it's played.", "n": 1, "price": 4, "color": "3fae5a"},
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
	"fast_forward": {"name": "Fast Forward", "text": "Move one CD a decade later, for good.", "target": "cd", "price": 3, "rarity": "common", "col": "2f9d8c"},
	"rewind": {"name": "Rewind", "text": "Move one CD a decade earlier, for good.", "target": "cd", "price": 3, "rarity": "common", "col": "2f9d8c"},
	"remix": {"name": "Remix", "text": "Change one CD to a random other genre, for good.", "target": "cd", "price": 3, "rarity": "common", "col": "2f9d8c"},
	"polish": {"name": "Polish", "text": "One CD gains +2 base points, for good.", "target": "cd", "price": 5, "rarity": "uncommon", "col": "2f9d8c"},
	"dub": {"name": "Dub", "text": "Add a copy of one CD to your deck.", "target": "cd", "price": 5, "rarity": "uncommon", "col": "2f9d8c"},
	"press": {"name": "Press", "text": "Give one CD a random edition: holographic, signed, limited or mint.", "target": "cd", "price": 4, "rarity": "uncommon", "col": "2f9d8c"},
	"trade_in": {"name": "Trade In", "text": "Remove one CD from your deck for good.", "target": "cd", "price": 2, "rarity": "common", "col": "2f9d8c"},
	"tune_up": {"name": "Tune-Up", "text": "Level up one gear unit that supports it, to MK II and then MK III.", "target": "gear", "price": 6, "rarity": "rare", "col": "6b4fb8"},
	"amp_up": {"name": "Amp Up", "text": "+1 flow for the rest of this turn.", "target": "", "price": 2, "rarity": "common", "col": "d9a62e"},
	"quiet_down": {"name": "Quiet Down", "text": "Cancel this turn's crowd move.", "target": "", "price": 3, "rarity": "uncommon", "col": "d9a62e"},
	"master_tape": {"name": "Master Tape", "text": "One CD gains +4 base points and a random edition, if it has none.", "target": "cd", "price": 7, "col": "2f9d8c", "rarity": "rare"},
	"overdrive": {"name": "Overdrive", "text": "Multiply your flow by 1.5 for the rest of this turn.", "target": "", "price": 6, "col": "d9a62e", "rarity": "rare"},
}
const TAPE_WEIGHTS := {"common": 60.0, "uncommon": 30.0, "rare": 10.0}
const TAPE_PACK_PRICE := 6
const TAPE_PACK_SHOW := 3
const BROWSER_SHOW := 6
