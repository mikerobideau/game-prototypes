# Loop Deck

DJ Engine's game, played with loops instead of CDs. Each card is a 2-bar loop at 100 BPM in A minor pentatonic. Cards still activate and score one at a time, but every loop keeps playing once it comes in, so a set builds into a full mix.

Run it from `loop_deck.tscn`. The code was copied from DJ Engine (`loop_deck.gd`, `loop_deck_ui.gd`, `loop_deck_data.gd`, `edition.gdshader`) and the two games now evolve separately.

## Run

- The title screen has only **Play**. Play opens **Choose Deck**: 14 decks, one per key, majors (A–G) in the top row and minors (A–G, blue cards) below. Each card shows the five notes the key's loops use, e.g. C E F G A for C major.
- Every key deck holds the cards of the first deck in `data/decks.json` (the Starter Crate). The key sets which notes the generated loops play for the whole run, and the tooltip byline names it ("Organ · C major"). Built in `_load_decks` when `KEY_DECKS` is on; roots, spelling and flat keys are `KEY_ROOTS`, `KEY_SEMIS` and `FLAT_KEYS`.
- Gigs run back to back: Basement Jam, Open Deck Night and so on (`VENUE_NAMES`), with the same rising targets as DJ Engine. There are `RUN_GIGS` (8) gigs. There is no tour map, road stops, venue likes or dislikes, crowd moves or headliner bosses.
- Each gig is DJ Engine's gig: 4 turns, a stall at the start of each turn (loops, Stomp Boxes, cassettes, packs), a hand of 6, up to 4 loops per set, discards, editions, points x flow, and the slam.
- When a gig ends, Continue goes straight to the next gig. Losing returns to the title.

## Loops

- **Percussion** cards play the drum and perc WAVs in `loops/` (from Loop Mixer). The `.import` files set each WAV to loop forward.
- **Rhythm, Chord and Lead** cards are **generated loops** (see below): each run builds them from MIDI pattern templates played on per-note instrument samples. The pitched Loop Mixer WAVs are still in `loops/` and `cards.json` but are not dealt while `GEN_LOOPS` is on.
- **Loop types** replace genres (`GENRES`), each with a colour (`SLEEVE_*`) and an icon in `icon/type/`, drawn by `tools/make_type_icons.gd`: **Percussion** (red, drum), **Rhythm** (green, square pulse: bass lines), **Chord** (purple, stacked notes) and **Lead** (amber, eighth note).
- There are no decades. Cards have no decade sticker, chip or rule.
- Each card has a title, an instrument (shown in the tooltip with the run's key, e.g. "Organ · C major"), base points, a rarity and one DJ Engine-style ability, with genre conditions naming loop types (e.g. "After Percussion, x2"). Covers are blank CDs.
- The starter deck is 20 cards: 5 percussion, 5 rhythm, 4 chord and 6 lead. Its pitched cards are listed by template variant (`lead_hook#0`), so the deck is the same riffs every run but they sound different.

## Generated loops

A pitched card is **pattern × instrument × notes**. The pattern (rhythm and melodic shape) is hand-made and fixed; the run's seed picks how it sounds. Code: `loop_deck_gen.gd`; settings: the `GEN_*`, `PATTERN_*` and `VOICES` constants in `loop_deck_data.gd`.

- **Patterns** are MIDI files in `patterns/`, one 2-bar loop each, written in A minor pentatonic. The file name sets the type and title: `lead_triplet_descent.mid` is a Lead called "Triplet Descent" (prefixes `rhythm_`/`bass_`, `chord_`, `lead_`). Only notes are read (start, length, pitch, velocity); tempo and time signature in the file are ignored. Notes outside the scale snap to the nearest scale note.
- The 11 demo patterns are written by `tools/make_patterns.py` from one-line rhythm/pitch strings. Replace or add `.mid` files from any DAW; no other data is needed.
  - Rhythm: Root Fifth Bass, Octave Pump, Walking Bass, Tresillo Bass.
  - Chord: Whole Note Chords, Offbeat Stabs, Tresillo Hits.
  - Lead: Triplet Descent, Call and Response, Hook, Turnaround Run.
- **Instruments** are folders in `instruments/` with one WAV per note, named by pitch (`A3.wav`, `C4.wav`). The demo set is 9 synth voices, made by `tools/make_instruments.py` (pentatonic notes only). Any file can be replaced by a recording with the same name; a missing note is played from the nearest sample, re-pitched. The WAVs must import uncompressed (Compress: Disabled, the default here).
- **Each run** (`_roll_albums` in `_new_run`) makes `GEN_VARIANTS` (3) cards per pattern, each with a different instrument allowed for its type (`VOICES` roles). For each card the seed also picks:
  - **Which notes:** the pattern moves up by 0–4 scale steps (`GEN_OFFSETS`). Bass and chords only start on A, C or E so the mix keeps an A minor centre; leads can start anywhere.
  - **Which octave:** any octave that fits both the type's range (`GEN_RANGES`) and the instrument's samples.
  - Slight velocity changes. The rhythm and shape never change.
- **Key:** after that, every note moves to the deck's key (`make_albums` root and mode; the root is kept within 6 semitones of A so loops stay near their written range). Patterns are written in minor:
  - **Minor keys** are a straight transposition.
  - **Major keys** raise the minor 3rd to a major 3rd and turn the minor 7th into the 6th (`DEG_MAJOR`): A C D E G becomes C E F G A in C major. Triads and arpeggios stay triads (the A–C–E arpeggio plays C–E–G) and every melody keeps its up/down shape.
  - **Starting notes per mode** (`GEN_OFFSETS`): in minor, bass and chords start on the root, 3rd or 5th; in major, chords start on the root and bass on the root or 5th. Leads can start on any scale note in both.
  - The instrument samples are A minor pentatonic notes only. Other notes play the nearest sample re-pitched by at most 1.5 semitones.
  - **Points, rarity and ability** are borrowed from a random pitched card of the same type in `cards.json`.
- **Mixing:** each loop is mixed into one looping `AudioStreamWAV` (32 kHz mono), with note tails wrapping round to the start so it repeats without a gap, and normalised to the old loops' loudness (`GEN_RMS`). From there it plays exactly like a WAV loop. Generated cards use the song path `gen://<card id>`, which `_music_stream` hands to the generator.
- **Timing:** a loop takes about 0.1 s to mix. At the start of a run a background thread mixes the collection's loops first, then every other card (about 4 s for all 33). A loop needed before then is mixed on the spot.
- **Your MIDI files** go in `midi/`, written in A minor. Every track with notes becomes a template; drum tracks (MIDI channel 10) and empty tracks are skipped. A track name can start with its type: "Lead Falling" and "Rhythm - Prowl" make a Lead called "Falling" and a Rhythm called "Prowl" (prefixes rhythm, bass, chord, lead; then a space, -, _ or :). Without one, the file-name prefix is used, or the type is guessed (low notes: Rhythm, stacked notes: Chord, otherwise Lead). Card ids are `<file>_<track title>#<n>`.
- **MIDI test** (`MIDI_TEST`, on): the only pitched cards are the tracks in `midi/`, `MIDI_TEST_CARDS` (4) per track, each on a different instrument (fewer if the type has fewer instruments: Rhythm has 3). They play **as written**: every note is kept, including B, F and chromatic notes (no pentatonic snapping or step shift), at the written octave or the nearest one that fits the instrument. Only the key and instrument change; in a major key the minor 3rd, 6th and 7th are raised (`MAJOR_RAISE`), so "Falling" (A E D C B) plays C G F E D in C major. Every key deck is the starter's 5 percussion cards plus those cards, and the deck cards list the key's full 7-note scale. Turn it off to go back to the demo patterns.
- **Export:** add `*.mid` to the export preset's non-resource include filter so `patterns/` ships.

## Instruments

Every card has a second attribute, its **instrument** (`Disc.instrument`, `INSTRUMENTS` in the data file with a short spine label). One instrument can have patterns in more than one loop type. Percussion instruments come from the loop WAVs. Pitched instruments are the sample folders in `VOICES`; which loop types each may play is set there.

| Instrument | Percussion | Rhythm | Chord | Lead |
|---|---|---|---|---|
| Drum Kit | ✓ | | | |
| Hand Percussion | ✓ | | | |
| Sine Synth | | ✓ | | ✓ |
| Saw Synth | | ✓ | | ✓ |
| Pluck | | ✓ | ✓ | ✓ |
| Synth Pad | | | ✓ | |
| Electric Piano | | | ✓ | ✓ |
| Organ | | | ✓ | ✓ |
| Square Synth | | | | ✓ |
| Flute | | | | ✓ |
| FM Bell | | | ✓ | ✓ |

- **On the case:** the instrument's short name (SAW, SINE, PLUCK…) runs down the jewel case spine in stacked letters, between the title strip and the ability note.
- **In the tooltip:** the byline reads "Saw Synth · A minor pentatonic", with an instrument chip between the type chip and the points chip.
- **Card abilities** can name an instrument wherever they could name a type (after, before, for each earlier, for each in hand). The note shows the short name, e.g. "After Saw, x2". Generated cards borrow these abilities from `cards.json`, e.g. x2 after a Saw Synth loop, +1 flow if the next loop is a Pluck, +5 for each Pluck in hand.
- **Stomp Boxes** that use instruments: **Unison** (+1.5 flow if two loops share an instrument), **Ensemble** (+15 points if this loop shares its instrument with another loop) and **Orchestra** (+2 flow if 4 loops all use different instruments). Rule conditions: `instrument_pair`, `instrument_shared`, `instruments_differ`.
- `tools/make_loop_data.py` rebuilds `data/cards.json`, `decks.json` and `gear.json` from the Loop Mixer manifest. It picks the instrument from each loop's description and copies any missing loop files. Its starter list names generated cards by template variant.

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
