extends RefCounted
## Album catalog: 7 genres x 9 albums (3 bands x 3 albums) = 63 albums.
## Genres are neutral link keys. Every album carries exactly one sticker, and
## 18 albums pay cash instead of points (3 per sticker, except Crossover).
## "band" values are placeholders ("Punk A", "Punk B", "Punk C"): replace them
## with your real band names. Album titles are the new, sticker-hinting names.
## Decades are data only, so any album can move to another decade freely.
## Points are placeholders: base by sticker, -1 for cash albums, +1 on some.

const GENRES := ["Alternative", "Punk", "Classic Rock", "Metal", "Indie", "Psychedelic", "Blues"]
const DECADES := ["60s", "70s", "80s", "90s", "00s", "10s"]

## family: slot | link | flow | pattern | set
## slot: the changer slot (1-5) a slot sticker pays in; 0 = any slot.
## Each sticker has a points rule and a cash rule (Crossover has no cash rule).
const STICKERS := {
	"opener": {"name": "Opener", "family": "slot", "slot": 1, "points": 4, "cash": 2,
		"points_text": "+4 points in slot 1.", "cash_text": "+$2 in slot 1."},
	"closer": {"name": "Closer", "family": "slot", "slot": 5, "points": 4, "cash": 2,
		"points_text": "+4 points in slot 5.", "cash_text": "+$2 in slot 5."},
	"crossover": {"name": "Crossover", "family": "link", "slot": 0, "points": 0, "cash": 0,
		"points_text": "Always keeps the flow.", "cash_text": ""},
	"chart_topper": {"name": "Chart Topper", "family": "flow", "slot": 0, "points": 2, "cash": 1,
		"points_text": "+2 points for each level of flow.", "cash_text": "+$1 for each level of flow above x1."},
	"reprise": {"name": "Reprise", "family": "pattern", "slot": 0, "points": 4, "cash": 2,
		"points_text": "+4 points if it shares a genre or decade with the song two back.",
		"cash_text": "+$2 if it shares a genre or decade with the song two back."},
	"discography": {"name": "Discography", "family": "set", "slot": 0, "points": 2, "cash": 1,
		"points_text": "+2 points for each earlier song of its genre tonight.",
		"cash_text": "+$1 for each earlier song of its genre tonight."},
	"throwback": {"name": "Throwback", "family": "set", "slot": 0, "points": 3, "cash": 2,
		"points_text": "+3 points if its decade played earlier, but not right before.",
		"cash_text": "+$2 if its decade played earlier, but not right before."},
}

const ALBUMS := [
	# Alternative
	{"band": "Alternative A", "album": "Curtain Up", "genre": "Alternative", "decade": "60s", "points": 4, "sticker": "opener", "payout": "points"},
	{"band": "Alternative A", "album": "Royalty Check", "genre": "Alternative", "decade": "70s", "points": 3, "sticker": "reprise", "payout": "cash"},
	{"band": "Alternative A", "album": "Memory Lane", "genre": "Alternative", "decade": "90s", "points": 4, "sticker": "throwback", "payout": "points"},
	{"band": "Alternative B", "album": "Open Door", "genre": "Alternative", "decade": "60s", "points": 2, "sticker": "crossover", "payout": "points"},
	{"band": "Alternative B", "album": "Cover Charge", "genre": "Alternative", "decade": "80s", "points": 3, "sticker": "opener", "payout": "cash"},
	{"band": "Alternative B", "album": "Last Dance", "genre": "Alternative", "decade": "00s", "points": 4, "sticker": "closer", "payout": "points"},
	{"band": "Alternative C", "album": "Rolling Thunder", "genre": "Alternative", "decade": "70s", "points": 4, "sticker": "chart_topper", "payout": "points"},
	{"band": "Alternative C", "album": "Walk-Off", "genre": "Alternative", "decade": "80s", "points": 4, "sticker": "closer", "payout": "points"},
	{"band": "Alternative C", "album": "Boxed Set Profits", "genre": "Alternative", "decade": "10s", "points": 3, "sticker": "discography", "payout": "cash"},
	# Punk
	{"band": "Punk A", "album": "Final Bow", "genre": "Punk", "decade": "60s", "points": 5, "sticker": "closer", "payout": "points"},
	{"band": "Punk A", "album": "Full Discography", "genre": "Punk", "decade": "90s", "points": 4, "sticker": "discography", "payout": "points"},
	{"band": "Punk A", "album": "Gold Record", "genre": "Punk", "decade": "00s", "points": 3, "sticker": "chart_topper", "payout": "cash"},
	{"band": "Punk B", "album": "Remember When", "genre": "Punk", "decade": "70s", "points": 3, "sticker": "throwback", "payout": "points"},
	{"band": "Punk B", "album": "Closing Time", "genre": "Punk", "decade": "90s", "points": 4, "sticker": "closer", "payout": "points"},
	{"band": "Punk B", "album": "Blend In", "genre": "Punk", "decade": "10s", "points": 3, "sticker": "crossover", "payout": "points"},
	{"band": "Punk C", "album": "Track One", "genre": "Punk", "decade": "80s", "points": 4, "sticker": "opener", "payout": "points"},
	{"band": "Punk C", "album": "Bridge the Gap", "genre": "Punk", "decade": "00s", "points": 2, "sticker": "crossover", "payout": "points"},
	{"band": "Punk C", "album": "Repeat Business", "genre": "Punk", "decade": "10s", "points": 2, "sticker": "reprise", "payout": "cash"},
	# Classic Rock
	{"band": "Classic Rock A", "album": "Full Swing", "genre": "Classic Rock", "decade": "60s", "points": 3, "sticker": "chart_topper", "payout": "points"},
	{"band": "Classic Rock A", "album": "Last Call", "genre": "Classic Rock", "decade": "70s", "points": 4, "sticker": "closer", "payout": "points"},
	{"band": "Classic Rock A", "album": "Publishing Rights", "genre": "Classic Rock", "decade": "90s", "points": 2, "sticker": "discography", "payout": "cash"},
	{"band": "Classic Rock B", "album": "Plays Nice", "genre": "Classic Rock", "decade": "60s", "points": 3, "sticker": "crossover", "payout": "points"},
	{"band": "Classic Rock B", "album": "Residuals", "genre": "Classic Rock", "decade": "80s", "points": 3, "sticker": "reprise", "payout": "cash"},
	{"band": "Classic Rock B", "album": "Doors at Eight", "genre": "Classic Rock", "decade": "00s", "points": 5, "sticker": "opener", "payout": "points"},
	{"band": "Classic Rock C", "album": "Common Ground", "genre": "Classic Rock", "decade": "70s", "points": 3, "sticker": "crossover", "payout": "points"},
	{"band": "Classic Rock C", "album": "Back in the Day", "genre": "Classic Rock", "decade": "80s", "points": 3, "sticker": "throwback", "payout": "points"},
	{"band": "Classic Rock C", "album": "Gaining Speed", "genre": "Classic Rock", "decade": "10s", "points": 4, "sticker": "chart_topper", "payout": "points"},
	# Metal
	{"band": "Metal A", "album": "The Whole Catalog", "genre": "Metal", "decade": "60s", "points": 3, "sticker": "discography", "payout": "points"},
	{"band": "Metal A", "album": "Reissue Royalties", "genre": "Metal", "decade": "90s", "points": 3, "sticker": "throwback", "payout": "cash"},
	{"band": "Metal A", "album": "Two Songs Ago", "genre": "Metal", "decade": "00s", "points": 3, "sticker": "reprise", "payout": "points"},
	{"band": "Metal B", "album": "Building Heat", "genre": "Metal", "decade": "70s", "points": 4, "sticker": "chart_topper", "payout": "points"},
	{"band": "Metal B", "album": "Rewind", "genre": "Metal", "decade": "90s", "points": 3, "sticker": "reprise", "payout": "points"},
	{"band": "Metal B", "album": "Curtain Call", "genre": "Metal", "decade": "10s", "points": 4, "sticker": "closer", "payout": "points"},
	{"band": "Metal C", "album": "Any Port in a Storm", "genre": "Metal", "decade": "80s", "points": 3, "sticker": "crossover", "payout": "points"},
	{"band": "Metal C", "album": "First Chord", "genre": "Metal", "decade": "00s", "points": 5, "sticker": "opener", "payout": "points"},
	{"band": "Metal C", "album": "Chart Royalties", "genre": "Metal", "decade": "10s", "points": 2, "sticker": "chart_topper", "payout": "cash"},
	# Indie
	{"band": "Indie A", "album": "Early Bird", "genre": "Indie", "decade": "60s", "points": 4, "sticker": "opener", "payout": "cash"},
	{"band": "Indie A", "album": "Stack the Riffs", "genre": "Indie", "decade": "70s", "points": 4, "sticker": "discography", "payout": "points"},
	{"band": "Indie A", "album": "Echo Chamber", "genre": "Indie", "decade": "90s", "points": 4, "sticker": "reprise", "payout": "points"},
	{"band": "Indie B", "album": "Collector's Price", "genre": "Indie", "decade": "60s", "points": 3, "sticker": "throwback", "payout": "cash"},
	{"band": "Indie B", "album": "Skip Back", "genre": "Indie", "decade": "80s", "points": 3, "sticker": "reprise", "payout": "points"},
	{"band": "Indie B", "album": "Deep Catalog", "genre": "Indie", "decade": "00s", "points": 3, "sticker": "discography", "payout": "points"},
	{"band": "Indie C", "album": "Last Payment", "genre": "Indie", "decade": "70s", "points": 3, "sticker": "closer", "payout": "cash"},
	{"band": "Indie C", "album": "Riding High", "genre": "Indie", "decade": "80s", "points": 4, "sticker": "chart_topper", "payout": "points"},
	{"band": "Indie C", "album": "Fits Right In", "genre": "Indie", "decade": "10s", "points": 2, "sticker": "crossover", "payout": "points"},
	# Psychedelic
	{"band": "Psychedelic A", "album": "Second Verse", "genre": "Psychedelic", "decade": "60s", "points": 4, "sticker": "reprise", "payout": "points"},
	{"band": "Psychedelic A", "album": "Meet in the Middle", "genre": "Psychedelic", "decade": "90s", "points": 2, "sticker": "crossover", "payout": "points"},
	{"band": "Psychedelic A", "album": "Closing Bonus", "genre": "Psychedelic", "decade": "00s", "points": 3, "sticker": "closer", "payout": "cash"},
	{"band": "Psychedelic B", "album": "Catalog Sale", "genre": "Psychedelic", "decade": "70s", "points": 2, "sticker": "discography", "payout": "cash"},
	{"band": "Psychedelic B", "album": "Hype Meter", "genre": "Psychedelic", "decade": "90s", "points": 4, "sticker": "chart_topper", "payout": "points"},
	{"band": "Psychedelic B", "album": "Old School", "genre": "Psychedelic", "decade": "10s", "points": 4, "sticker": "throwback", "payout": "points"},
	{"band": "Psychedelic C", "album": "Greatest Hits", "genre": "Psychedelic", "decade": "80s", "points": 4, "sticker": "discography", "payout": "points"},
	{"band": "Psychedelic C", "album": "Vintage Value", "genre": "Psychedelic", "decade": "00s", "points": 3, "sticker": "throwback", "payout": "cash"},
	{"band": "Psychedelic C", "album": "Lights Down", "genre": "Psychedelic", "decade": "10s", "points": 5, "sticker": "opener", "payout": "points"},
	# Blues
	{"band": "Blues A", "album": "Way Back When", "genre": "Blues", "decade": "60s", "points": 4, "sticker": "throwback", "payout": "points"},
	{"band": "Blues A", "album": "Mix and Match", "genre": "Blues", "decade": "70s", "points": 3, "sticker": "crossover", "payout": "points"},
	{"band": "Blues A", "album": "Advance Tickets", "genre": "Blues", "decade": "90s", "points": 4, "sticker": "opener", "payout": "cash"},
	{"band": "Blues B", "album": "Platinum Hit", "genre": "Blues", "decade": "60s", "points": 2, "sticker": "chart_topper", "payout": "cash"},
	{"band": "Blues B", "album": "More of the Same", "genre": "Blues", "decade": "80s", "points": 3, "sticker": "discography", "payout": "points"},
	{"band": "Blues B", "album": "Flashback", "genre": "Blues", "decade": "00s", "points": 3, "sticker": "throwback", "payout": "points"},
	{"band": "Blues C", "album": "Opening Night", "genre": "Blues", "decade": "70s", "points": 4, "sticker": "opener", "payout": "points"},
	{"band": "Blues C", "album": "Final Tab", "genre": "Blues", "decade": "80s", "points": 3, "sticker": "closer", "payout": "cash"},
	{"band": "Blues C", "album": "Take Two", "genre": "Blues", "decade": "10s", "points": 4, "sticker": "reprise", "payout": "points"},
]


static func albums_at(genre: String, decade: String) -> Array:
	var found := []
	for album in ALBUMS:
		if album.genre == genre and album.decade == decade:
			found.append(album)
	return found


static func albums_of_genre(genre: String) -> Array:
	var found := []
	for album in ALBUMS:
		if album.genre == genre:
			found.append(album)
	return found


static func albums_with_sticker(sticker_id: String) -> Array:
	var found := []
	for album in ALBUMS:
		if album.sticker == sticker_id:
			found.append(album)
	return found
