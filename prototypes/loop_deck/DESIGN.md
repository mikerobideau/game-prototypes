# Loop Deck

A synthwave looper built on DJ Engine's game. Each card is a synth loop (drums, bass, chords or lead) at 100 BPM. Cards still activate and score one at a time, but every loop keeps playing once it comes in, and a synth pad plays the chords underneath. Every CD tray carries a random chord from the deck's key each turn, and a card plays its tray's chord as it comes in, so the order of the trays you fill makes the set's chord progression.

Run it from `loop_deck.tscn`. The code was copied from DJ Engine (`loop_deck.gd`, `loop_deck_ui.gd`, `loop_deck_data.gd`, `edition.gdshader`) and the two games now evolve separately.

## Run

- The title screen has only **Play**. Play opens **Choose Deck**: 14 decks, one per key, majors (A–G) in the top row and minors (A–G, blue cards) below. Each card shows the key's scale and the six chords its trays can get (e.g. C Dm Em F G Am).
- Each deck is built when the run starts (`_gen_deck_cards`): every card made from your MIDI in `midi/` (when that folder is in `CARD_DIRS`), then random cards from the pool, each of the loop type the deck has fewest of, up to `COLLECTION` (20). The key sets the notes of every loop and the pad for the whole run; the tooltip byline names it ("Saw Lead · C major"). Built in `_load_decks` when `KEY_DECKS` is on.
- Gigs run back to back: Basement Jam, Open Deck Night and so on (`VENUE_NAMES`), with the same rising targets as DJ Engine. There are `RUN_GIGS` (8) gigs. There is no tour map, road stops, venue likes or dislikes, crowd moves or headliner bosses.
- Each gig is DJ Engine's gig: 4 turns, a stall at the start of each turn (loops, Stomp Boxes, cassettes, packs), a hand of 6, up to 4 loops per set, discards, editions, points x flow, and the slam.
- When a gig ends, Continue goes straight to the next gig. Losing returns to the title.

## Loops

- Every card is a **generated loop**: a MIDI pattern played on one instrument (see Synthwave loops). The old Loop Mixer WAVs in `loops/` and the cards in `cards.json` are no longer dealt while `GEN_LOOPS` is on; `cards.json` now only lends points, rarity and abilities to generated cards.
- **Loop types** replace genres (`GENRES`), each with a colour (`SLEEVE_*`) and an icon in `icon/type/`, drawn by `tools/make_type_icons.gd`: **Percussion** (red, drum: drum kits), **Rhythm** (green, square pulse: bass), **Chord** (purple, stacked notes: arps and stabs) and **Lead** (amber, eighth note).
- There are no decades. Cards have no decade sticker, chip or rule.
- Each card has a title, an instrument, base points, a rarity and one DJ Engine-style ability, with genre conditions naming loop types (e.g. "After Percussion, x2"). Covers are blank CDs.

## The 100-card set

- The cards come from the folders in `CARD_DIRS`: now only `generated_midi/`, which holds **100 MIDI files, one card each**, made by `tools/make_generated_midi.py`: 24 Percussion, 24 Rhythm, 22 Chord and 30 Lead. Add `[PATTERN_DIR, "demo"]` or `[MIDI_DIR, "midi"]` to bring back the demo patterns or your own MIDI.
- The patterns are built from small hand-written pieces so they stay musical: drum grooves (6 kicks x 4 snares x 4 hat patterns, with tom, snare-roll or crash fills in bar 2) plus 6 hand-percussion grooves; bass rhythms x note shapes (root, octave pump, fifths, walks); arpeggio shapes x rhythms and chord stabs x rhythms; and leads made of a 1-bar call and a 1-bar answer (10 calls x 9 answers). Titles are synthwave word pairs ("Neon Skyline").
- **The card sheet** `generated_midi/cards.csv` has one row per MIDI file: `file, title, type, rarity, points, condition, cond_param, effect, value, target, target_param`. Open it in a spreadsheet to change any card; a file with a row makes exactly one card with that ability (`CARD_SHEET`), and its instrument is still picked by the run's seed. The sheet's `.import` file says "keep" so Godot does not read it as a translation table.
- **Every card has a placement ability:** where it sits in the set decides whether it fires. Conditions: a set slot (1-4, the play order), first, last, odd or even slot, after or before a loop type or instrument, and for each earlier loop of a type. Each type has its own list (e.g. Percussion: first x2, slot 1 x2, before Rhythm +1 flow; Lead: slot 4 x3, last x2.5, after Chord x2). Rarity: about half common, a third uncommon, a sixth rare; rarer cards have fewer base points (5 / 4 / 3) and stronger abilities (+2 points, +0.5 mult or +0.5 flow per tier). Chords do not affect scoring yet.
- **Measured** (`_score_set` over 150 random hands of 6 from a C major deck, every way to choose and order 4 cards): the best arrangement averages about 150, a random one about 50 and the worst about 16, so placement roughly triples a set. With the six new Stomp Boxes in the rack the best arrangement averages about 400 (4x random). Perfect play with the starting deck alone would clear all 8 gigs, so targets or values need tuning.

## Synthwave loops

Code: `loop_deck_gen.gd`; settings: the `GEN_*`, `CHORDS_*`, `NUMERALS_*`, `PAD_*`, `VOICES` and `DRUM_FILES` constants in `loop_deck_data.gd`.

- **Tray chords.** When the shop closes each turn (`_close_stall` → `_roll_tray_chords`), every CD tray gets a random chord from the key: I ii iii IV V vi in a major key, i III iv v VI VII in a minor key (`CHORDS_MAJOR`, `CHORDS_MINOR`; diminished chords are left out; repeats are allowed). The chord shows above the tray's number as numeral and name, e.g. "V - G" (gold when the tray holds a card). Until the shop closes the trays show no chord. Chords are flavour only for now.
- **A set's progression** is the chords of the trays it plays, in play order, one bar each (`_set_prog`): trays 1, 3, 4 and 6 holding i, iv, III and iv in A minor play Am | Dm | C | Dm. Cards enter one bar apart, so each card comes in on its own tray's chord; after the last card the progression keeps repeating through the scoring and the tail.
- **The pad** always plays during a set: the set's chords, one bar each (`PAD_NOTES`: a low root plus the triad around middle C, moved to each chord and the key), on the Poly Pad voice. It is one more loop player (`pad_slot`), started by the set's first card (`_pad_start`) and faded and stopped with the other loops.
- **Patterns** are MIDI tracks: the demo patterns in `patterns/` (written by `tools/make_patterns.py`), the 100-card set in `generated_midi/` and your files in `midi/`. Pitched tracks are written in **C major over a C chord**; drum tracks use MIDI channel 10 with General MIDI drum notes. Only notes are read; tempo is ignored. A pattern is 1, 2 or 4 bars (from its last note).
- **Following the chords.** A loop is mixed for one chord sequence and is long enough for both its pattern and the sequence to repeat whole (a 2-bar pattern over 4 chords is 4 bars, over 3 chords 6 bars). Each bar of a pitched pattern is moved along the major scale to its chord (`_steps`: ii and iii up 1 and 2 steps, IV V vi vii down 4, 3, 2 and 1, so a bass on C goes to F, G or A below it), then the whole loop moves to the key's major scale (the relative major for a minor key: A minor plays in C major with i = vi; within 6 semitones of C) and by octaves to fit its type's range (`GEN_RANGES`) and the instrument, keeping the written octave when it fits. Notes outside the scale keep their sharp. Drums are not moved.
- **Track names and types.** A track name can start with its type: "Lead Falling", "Rhythm - Prowl", "Drums Motorik" (prefixes in `PATTERN_TYPES`: rhythm, bass, chord, lead, drums, drum, perc, percussion). Without one, the file-name prefix is used (`lead_riff.mid`), then channel 10 means Percussion, then the type is guessed (low notes: Rhythm, stacked notes: Chord, otherwise Lead). Card ids are `<file>` or `<file>_<track title>`, then `#<n>`.
- **Cards per pattern:** `GEN_VARIANTS` (2) per demo pattern and `MIDI_CARDS` (4) per track of yours, each on a different instrument allowed for its type (fewer if the type has fewer instruments). Points, rarity and ability are borrowed from a random `cards.json` card of the same type; an ability that names an old instrument gets a current one instead.
- **Demo patterns** (15): Drums Outrun Four, Gated Halftime, Motorik, Tom Fill; Perc Clap Shaker; Rhythm Octave Pump, Root Drive, Gallop, Offbeat Pop; Chord Arp Up, Offbeat Stabs; Lead Soaring Hook, Call and Answer, Sparkle, Turnaround Run.
- **Mixing:** each loop is mixed into one looping `AudioStreamWAV` (32 kHz mono, a bar is 2.4 s) with note tails wrapping round to the start, normalised per type (`GEN_RMS`, `PAD_RMS`), and kept per card and chord sequence. Kit samples play to their end; pitched notes stop at their length with the voice's release. Generated cards use the song path `gen://<card id>`: a set plays them over its chords (`gen.set_prog`), while hover previews play them over the key's home chord.
- **Mixing ahead.** A background worker mixes queued loops (`warm`, `prepare_set`). At the start of a run it mixes every card's preview. Whenever the trays change during a turn (`_prepare_trays`, checked each frame), the pad and the loops for the trays as they stand jump to the front of the queue, so they are usually ready before Play (about 1.8 s for a set of four); mixes for other sequences are dropped. A loop needed before it is ready is mixed on the spot.
- **Timing:** a loop takes about 0.2–0.3 s to mix. At the start of a run a background thread mixes the pad, then the deck's loops, then every other card. A loop needed before then is mixed on the spot.
- **Export:** add `*.mid` to the export preset's non-resource include filter so `patterns/` and `midi/` ship.

## Instruments

Every card has a second attribute, its **instrument** (`Disc.instrument`, `INSTRUMENTS` in the data file with a short spine label). The instruments are sample folders in `instruments/`, made by `tools/make_instruments.py`; `VOICES` sets which loop types each may play.

| Instrument | Folder | Percussion | Rhythm | Chord | Lead |
|---|---|---|---|---|---|
| Gated Kit | `kit_gated` | ✓ | | | |
| Analog Kit | `kit_analog` | ✓ | | | |
| Saw Bass | `saw_bass` | | ✓ | | |
| Pulse Bass | `pulse_bass` | | ✓ | | |
| Sub Bass | `sub_bass` | | ✓ | | |
| Synth Pluck | `synth_pluck` | | | ✓ | ✓ |
| Brass | `brass` | | | ✓ | |
| Saw Lead | `saw_lead` | | | | ✓ |
| Square Lead | `square_lead` | | | | ✓ |
| PWM Lead | `pwm_lead` | | | | ✓ |

The pad's voice is `poly_pad` (no cards).

- **Pitched folders** hold one WAV every 3 semitones (C, Eb, Gb and A in each octave, e.g. `Eb3.wav`); a note in between plays the nearest sample re-pitched by at most 1.5 semitones. **Kit folders** hold one WAV per drum (`kick`, `snare`, `clap`, `rim`, `hat_closed`, `hat_open`, `tom_low`, `tom_mid`, `tom_high`, `crash`), mapped from General MIDI drum notes by `DRUM_FILES`. The gated kit's snare, clap and toms have a gated-reverb tail.
- Any file can be replaced by a recording with the same name. The WAVs must import uncompressed (Compress: Disabled, the default here).
- **On the case:** the instrument's short name runs down the jewel case spine in stacked letters, between the title strip and the ability note.
- **In the tooltip:** the byline reads "Saw Lead · C major", with an instrument chip between the type chip and the points chip.
- **Card abilities** can name an instrument wherever they could name a type (after, before, for each earlier, for each in hand). The note shows the short name, e.g. "After Saw Lead, x2".
- **Stomp Boxes** that use instruments: **Unison** (+1.5 flow if two loops share an instrument), **Ensemble** (+15 points if this loop shares its instrument with another loop) and **Orchestra** (+2 flow if 4 loops all use different instruments). Rule conditions: `instrument_pair`, `instrument_shared`, `instruments_differ`.
- `tools/make_loop_data.py` rebuilds `data/cards.json`, `decks.json` and `gear.json` from the Loop Mixer manifest.

## Type traits

Each type earns flow, like DJ Engine's genre traits (`_genre_trait`, values `TRAIT_*_FLOW`):

- **Percussion · Groove:** +0.5 flow if it's the first loop in the set.
- **Rhythm · Lock In:** +0.5 flow if a Percussion loop is already playing.
- **Chord · Harmony:** +0.5 flow if a Rhythm loop is already playing.
- **Lead · Top Line:** +0.25 flow for each other loop type already playing.

## Playback

- Each tray has its own looping player on the Songs bus (`loop_players`), plus one for the pad. The first loop of a set starts the clock (`loop_t0`) and the pad. Every later loop starts at the clock's position in its own length (4 bars for generated loops), so all loops and the pad stay on the same bars and chords.
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
- **Synthwave units (placement):** **Gated Reverb** (x2 if this tray is Percussion and plays first), **Sidechain** (+1 flow if this tray is Rhythm and sits next to a Percussion loop), **Arpeggiator** (+6 points for each loop already playing if this tray is Chord), **Chorus** (+12 points if the loop in this tray sits next to a Chord loop), **Turnaround** (x2 to the last loop of a full set; works anywhere) and **Bridge** (x1.5 if the loop in this tray sits between two loops of one other type).

## Cassettes

The same as DJ Engine, minus the decade tapes (Fast Forward, Rewind), Remix (changing a loop's type would not change its sound) and Quiet Down (no crowd moves).

## Look

The gig screen, jewel cases, tooltips and hi-fi hardware are DJ Engine's. Changes: type colours and a single type sticker on each case; tooltips show the type chip, points and instrument; the model plate reads "LOOP DECK / LD-1 · LOOP STATION"; the doors read "LOOP CHANGER · 6 TRAY" and "LOOP STORAGE"; player-facing text says loops instead of CDs, songs or albums, and "crate" instead of "binder".

## Not yet trimmed

The tutorial and collection screens were removed. DJ Engine's map, road stops, pickups, road shop, bosses, kit and deck pickers and settings screen are still in the code but can't be reached.
