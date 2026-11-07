# Gear

Every unit is a Half bay and sits above its own tray (bay 1 over tray 1, and so on). A unit that scores songs only fires for the CD in its tray, so you have to play a CD there. Anywhere units, round-end units and buttons need no tray. The rack is edited in the gear workshop; this table is generated from `data/gear.json`.

| Unit | Price | Activates | Text |
|---|---|---|---|
| Crunch Box | $6 | Per song | +{amount} points if this tray is {aparam}. |
| Stack Fuzz | $7 | Per song | x{amount} points if this tray is {aparam}. |
| Sub Boost | $6 | Per song | +{amount} flow if this tray is {aparam}. |
| Bass Drop | $7 | Per song | Flow x{amount} if this tray is {aparam}. |
| Radio Compressor | $5 | Per song | +${amount} if this tray is {aparam}. |
| Platinum Boost | $6 | Per song | Pays ${amount} per base point of the song if this tray is {aparam}. |
| Rainy Day Sustain | $5 | Round end | Sell value rises by ${cash} at the end of each round. |
| Clone Box | $8 | On placement | When placed, turns into the gear to its right. |
| Double Tap | $7 | Per song | The CD in this tray triggers its card effect twice. |
| CD Burner | $7 | Per song | The CD in this tray gains +{amount} base points, permanently. |
| Smoke Chorus | $6 | Per song | +{amount} flow for each {rparam} CD in your hand. |
| Duo Tone | $7 | Per song | x{amount} points if this tray is {aparam} and exactly one other song is too. |
| Prism Phaser | $6 | Anywhere | +{amount} flow if {rn}+ songs are all different genres. |
| Metronome | $7 | Anywhere | +{amount} points if {rn} songs each rise a decade. |
| Mono Drive | $7 | Anywhere | +{amount} points if {rn} songs share a genre. |
| Sidechain | $6 | Per song | x{amount} points if this song sits between two {rparam} songs. |
| Feedback Loop | $6 | Per song | +{amount} points for each earlier {rparam} song. |
| Pre-Delay | $6 | Per song | +${amount} for each later {rparam} song. |
| Loop Station | $7 | Per song | x{amount} points if the first and last songs share a genre. |
| Delay Pedal | $7 | Per song | x{amount} points if this song shares its genre with the song {rn} back. |
| Ping-Pong Delay | $6 | Per song | +{amount} flow if {rn}+ songs are played and no neighbors share a genre. |
| Reverb | $5 | Per song | +{amount} flow for each CD under four you play. |
| Clean Boost | $5 | Per song | +{amount} points to the CD in this tray. |
| Gain Knob | $6 | Per song | x{amount} points to the CD in this tray. |
| Swell | $5 | Per song | +{amount} points for each time this tray has been played. |
| Tremolo 60s | $6 | Per song | +{amount} points for each {gparam} song played while this tray is played. |
| Tuner | $5 | On discard | When you discard, that CD gains +1 base points. |
| Tip Jar | $4 | Once per gig | +${amount} per unused discard the first time this tray is played each gig. |
| Wah Pedal | $6 | Per song | +{amount} flow for each unit to its left. |
| Noise Gate | $6 | Button | Once per gig: cancel this turn's crowd move. |
| Fog Machine | $5 | Per song | Hecklers can't block a tray while this tray is played. |
| Deep Library | $6 | Button | Once per gig: redraw your whole hand. |
| Sneak Peek | $4 | Button | Once per gig: look at the next {count} songs in your binder. |
| Disco Filter | $6 | Per song | +{amount} flow if this tray is {aparam}. |
| Gated Reverb | $6 | Per song | +{amount} points if this tray is {aparam}. |
| Cassette Saturator | $5 | Per song | +${amount} if this tray is {aparam}. |
| Y2K Delay | $7 | Per song | The {aparam} CD in this tray triggers its card effect twice. |
| Auto-Tune | $7 | Per song | x{amount} points if this tray is {aparam}. |
| Tape Deck | $6 | Once per gig | Makes a consumable the first time its tray is played each gig. |
| Spare Reel | $7 | Anywhere | Makes a consumable if {rn}+ songs are all different genres. |

## Open items

- Sneak Peek only looks at the next 3 CDs. Taking one into your hand needs a pick screen.
- Swell and Tremolo 60s grow for the whole run. Tune or reset per gig if they snowball.
- All numbers are first guesses, and gig targets need a pass now that starter decks are plain CDs.
- The workshop balance check measures one unit in four trays, so anywhere and shape units read as weak.

## Chain units

Relay, Cascade, Tap Splitter and Daisy Chain react to the unit on their left. See DESIGN.md. In the gear workshop the new condition is "The unit on its left fired", the new per is "units_fired", and the new effect is "Fire the unit on its left again for this CD".

