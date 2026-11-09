# Loop Deck

DJ Engine's game, played with loops instead of CDs. Each card is a 2-bar loop at 100 BPM in A minor pentatonic. Cards still activate and score one at a time, but every loop keeps playing once it comes in, so a set builds into a full mix.

Run it from `loop_deck.tscn`. The code was copied from DJ Engine (`loop_deck.gd`, `loop_deck_ui.gd`, `loop_deck_data.gd`, `edition.gdshader`) and the two games now evolve separately.

## Run

- The title screen has only **Play**. Play starts a run with the first deck in `data/decks.json` (the Starter Crate).
- Gigs run back to back: Basement Jam, Open Deck Night and so on (`VENUE_NAMES`), with the same rising targets as DJ Engine. There are `RUN_GIGS` (8) gigs. There is no tour map, road stops, venue likes or dislikes, crowd moves or headliner bosses.
- Each gig is DJ Engine's gig: 4 turns, a stall at the start of each turn (loops, Stomp Boxes, cassettes, packs), a hand of 6, up to 4 loops per set, discards, editions, points x flow, and the slam.
- When a gig ends, Continue goes straight to the next gig. Losing returns to the title.

## Loops

- `loops/` holds the 43 loop files from Loop Mixer whose notes all sit inside A minor pentatonic (A C D E G). Files using B or F (the D and E pentatonic groups, and the Bdim, Dm, F and most Em/G chord loops) were left out. The `.import` files set each WAV to loop forward.
- **Loop types** replace genres (`GENRES`), each with a colour (`SLEEVE_*`) and an icon in `icon/type/`, drawn by `tools/make_type_icons.gd`:
  - **Percussion** (red, drum): drums and perc loops (7).
  - **Rhythm** (green, square pulse): every bass line, plus the pentatonic pad and plucked arp (9).
  - **Chord** (purple, stacked notes): the Am and C pads and the Am and C chord stabs and plucks (8).
  - **Lead** (amber, eighth note): every lead (19).
- There are no decades. Cards have no decade sticker, chip or rule.
- Cards are in `data/cards.json`, made by a generator script from the Loop Mixer manifest. Each card has a title, an instrument (shown in the tooltip as "Keys · A minor pentatonic"), base points, a rarity and one DJ Engine-style ability, with genre conditions now naming loop types (e.g. "After Percussion, x2"). Covers are blank CDs.
- The starter deck is 20 cards: 5 percussion, 5 rhythm, 4 chord and 6 lead.

## Instruments

Every card has a second attribute, its **instrument** (`Disc.instrument`, `INSTRUMENTS` in the data file with a short spine label). One instrument can have patterns in more than one loop type. All instruments come from the existing loops, grouped by the sound in each loop's description; no new loops were made.

| Instrument | Percussion | Rhythm | Chord | Lead |
|---|---|---|---|---|
| Drum Kit | 4 | | | |
| Hand Percussion | 3 | | | |
| Sine Synth | | 3 | | 4 |
| Saw Synth | | 5 | | 2 |
| Pluck | | 1 | 2 | |
| Synth Pad | | | 2 | |
| Electric Piano | | | 2 | |
| Organ | | | 2 | |
| Square Synth | | | | 5 |
| Flute | | | | 4 |
| FM Bell | | | | 4 |

- **On the case:** the instrument's short name (SAW, SINE, PLUCK…) runs down the jewel case spine in stacked letters, between the title strip and the ability note.
- **In the tooltip:** the byline reads "Saw Synth · A minor pentatonic", with an instrument chip between the type chip and the points chip.
- **Card abilities** can name an instrument wherever they could name a type (after, before, for each earlier, for each in hand). The note shows the short name, e.g. "After Saw, x2". Examples: Am Saw Lead (x2 after a Saw Synth loop), C Saw Lead (+4 for each earlier Saw Synth loop), Am Vibrato (+1 flow after a Sine Synth loop), Plucked Arp (+1 flow if the next loop is a Pluck), C Pluck (+5 for each Pluck in hand).
- **Stomp Boxes** that use instruments: **Unison** (+1.5 flow if two loops share an instrument), **Ensemble** (+15 points if this loop shares its instrument with another loop) and **Orchestra** (+2 flow if 4 loops all use different instruments). Rule conditions: `instrument_pair`, `instrument_shared`, `instruments_differ`.
- **Gaps:** Keys, Organ and Pad only have Chord loops, and Square, Flute and FM Bell only have Lead loops. Filling those (for example an organ lead or a square chord stab) needs new loops from the Loop Mixer tool.
- `tools/make_loop_data.py` rebuilds `data/cards.json`, `decks.json` and `gear.json` from the Loop Mixer manifest. It picks the instrument from each loop's description and copies any missing loop files.

## Type traits

Each type earns flow, like DJ Engine's genre traits (`_genre_trait`, values `TRAIT_*_FLOW`):

- **Percussion · Groove:** +0.5 flow if it's the first loop in the set.
- **Rhythm · Lock In:** +0.5 flow if a Percussion loop is already playing.
- **Chord · Harmony:** +0.5 flow if a Rhythm loop is already playing.
- **Lead · Top Line:** +0.25 flow for each other loop type already playing.

## Playback

- Each tray has its own looping player on the Songs bus (`loop_players`). The first loop of a set starts the clock (`loop_t0`). Every later loop starts at the clock's position in the 2-bar cycle, so all loops stay phase-locked.
- One bar per card: a card's loop enters on a bar line and its scoring beats fit inside that bar (`loop_step_cap`). The next card comes in on the next bar line, about 2.4 s later.
- Loops come in at full volume with no fade and no transition sound (no whoosh, click or scratch). The Songs bus is left clean: no heat filter, reverb, ducking or pre-slam drop.
- After the last card, the mix keeps playing through the scoring and the slam, plays one more 2-bar pass and then fades out (`_loops_release`, `LOOP_FADE_OUT`). Pressing Play again stops any tail.
- Hovering a loop card previews it on its own, as DJ Engine previews songs.

## Stomp Boxes

`data/gear.json` has 13 units (the three instrument units are listed under Instruments), built on DJ Engine's rule system. New rule conditions: `types_all` (all types in `rparam`, joined with `+`, are played), `type_exactly` (exactly `rn` loops of type `rparam`), `all_types` (all four types). New count: `per: loops_before` (loops already playing).

- **Clean Boost:** +10 points to the loop in this tray.
- **Backbeat:** +15 points if this tray is Percussion.
- **Low End:** +1 flow if this tray is Rhythm.
- **Harmonizer:** x1.5 points if this tray is Chord.
- **Spotlight:** x2 points if this tray is Lead and it's the only Lead loop.
- **Duet:** +1.5 flow if Rhythm and Lead loops both play.
- **Full Band:** +2 flow if all four loop types play.
- **Click Track:** +$2 if exactly one Percussion loop plays.
- **Stack:** +4 points for each loop already playing.
- **Tape Deck:** makes a cassette the first time its tray plays each gig.

## Cassettes

The same as DJ Engine, minus the decade tapes (Fast Forward, Rewind), Remix (changing a loop's type would not change its sound) and Quiet Down (no crowd moves).

## Look

The gig screen, jewel cases, tooltips and hi-fi hardware are DJ Engine's. Changes: type colours and a single type sticker on each case; tooltips show the type chip, points and instrument; the model plate reads "LOOP DECK / LD-1 · LOOP STATION"; the doors read "LOOP CHANGER · 6 TRAY" and "LOOP STORAGE"; player-facing text says loops instead of CDs, songs or albums, and "crate" instead of "binder".

## Not yet trimmed

The tutorial and collection screens were removed. DJ Engine's map, road stops, pickups, road shop, bosses, kit and deck pickers and settings screen are still in the code but can't be reached.
