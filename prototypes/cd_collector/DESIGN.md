# CD Collector

A solo tableau-building game about filling a nine-pocket CD binder. Draft CDs from a community row, slot them into your binder so neighbours fit together, and play them to trigger their effects. After 15 turns, your total **victory points (VP)** decides how you did.

It draws on two earlier prototypes: from **Holdings**, a 3×3 board where position and adjacency drive abilities, and from **Disc Engine**, CDs with genres and decades that link to each other. Nothing comes over from venues, rack gear, events, dice or crowd meters.

**Feel:** a modern tabletop game. Everything on screen is a physical component (cards, a binder page, tokens, a turn track, a paper log, a sticky note) and every rule could be run by hand at a table.

**Prototype:** run `cd_collector.tscn` (F6). Data (genres, decades, hook templates, objectives, tuning) is in `cd_collector_data.gd`. Rules are in `cd_collector.gd`: turn flow in `_start_turn` / `_end_turn` / `_finish`, actions in `_buy` / `_place` / `_play`, hooks in `_count` / `_amount` / `_fire`, objectives in `_objective_score`. Drawing helpers are shared with Nine Pocket (`nine_pocket_ui.gd`). `tools/sim.gd` runs a greedy bot headless:

```bash
godot --headless --path . -s res://prototypes/cd_collector/tools/sim.gd
```

## Systems
1. **CDs**: cards you draft, hold in your hand, place in the binder and play.
2. **Resources**: **Plays** and **Cash**, kept to two on purpose.
3. **Objective cards**: one scoring goal chosen at setup.

## Components
- **Binder page**: a 3×3 grid of pockets (the player board).
- **CD deck** and a **community row** of 3 face-up CDs.
- **Hand**: up to 6 CDs.
- **Play tokens**, **Cash coins**, and a **turn track** numbered 1–15.
- **Victory point pad**.
- **Objective deck**.

## CD card
- **Band / album** (flavour).
- **Genre** (5: Classic Rock, Indie, Metal, Punk, Psychedelic) and **Decade** (4: 70s, 80s, 90s, 00s), the two linking tags.
- **Cost** in Cash (0–4), shown on a gold coin while the CD is in the row. It is the sum of what its two hooks are worth.
- **on_played** hook: every CD has one. Fires each time the CD is played.
- **on_placed** hook: about 60% of CDs have one. Fires once, when the CD goes into a pocket.

A CD has no base VP: all VP comes from hooks. The deck is 60 CDs, 3 of each genre and decade combination.

## Setup
1. Shuffle the deck and deal 3 CDs face up as the community row.
2. Look at 3 objective cards and keep 1.
3. Start with 3 Cash and an empty binder on turn 1.

## A turn
At the start of each turn you gain **+1 Cash** and your **2 Plays**. Then do any of these, any number of times, in any order:

- **Buy:** pay a CD's Cash cost to take it from the row into your hand. Refill that slot from the deck.
- **Refresh row:** pay $1 to discard the whole row and deal 3 new CDs.
- **Place:** move a CD from your hand into a pocket. It must share a **genre or decade** with at least one orthogonally adjacent CD. The first CD can go anywhere. Then resolve its **on_placed** hook.
- **Replace:** place a CD onto a filled pocket under the same rule. The CD underneath is discarded. VP already earned from it stays earned.
- **Play:** spend 1 Play to play a CD in your binder and resolve its **on_played** hook. Each CD can be played **once per turn**.

End the turn when you choose. Unspent Plays are lost, Cash carries over. At end of turn, the **leftmost CD in the row is discarded**, the others slide left, and a new CD joins on the right. After turn 15, score your objective and total your VP.

## Plays
Plays and time are the same thing: how many CDs you can play this turn. You get 2 each turn and hooks can grant more. **No infinite plays:** each CD plays at most once per turn, so no turn can have more than 9 plays however many Plays you gain. The Play token on a played CD marks it as used.

## Hooks
`on_placed` and `on_played` hooks give **VP**, **Cash**, **Plays**, or **draw CDs** into your hand. A hook can be conditional, and either scales (per matching CD) or needs a threshold (if at least N):

| Condition | Example |
|---|---|
| Always | +1 VP |
| Adjacent | +1 VP per adjacent Punk |
| Row / column | +2 VP per other 80s in this column |
| Corner / center / edge | +3 VP if in a corner |
| Count in binder | +1 VP per other Metal in your binder |
| Count in hand | +1 VP per CD in your hand |
| Threshold | +1 Play if next to 2+ Metal |

Genre and decade conditions use the CD's own genre or decade. Drawn CDs go to your hand from the top of the deck. If your hand is full, they're discarded. When the deck runs out, the discard pile is reshuffled.

## Objectives
Scored once, at the end. Ten cards: Genre Lines, Decade Lines, Four Corners, Full Page, Well Rounded, Specialist, The Hub, Stash, Diagonals, Decade Sweep. The in-game card shows what it's worth right now.

## Balance
300 games with a greedy bot (places wherever legal, plays everything, buys the most expensive CD it can afford, never replaces, ignores its objective): mean about 26 VP, median 26, quartiles 13 and 36, max 75. A human who plans placement, replaces weak CDs and aims at the objective should do much better. Rank thresholds (25 / 45 / 65) are guesses. Tuning knobs: `TURNS`, `PLAYS_PER_TURN`, `START_CASH`, `INCOME`, `HAND_MAX`, `REFRESH_COST`, `PLACED_CHANCE`, and the hook templates in `PLACED` and `PLAYED`.

## Open questions
- Is 2 Plays per turn right, or should Plays grow over the game?
- The hook templates are a first pass; many are weak or situational. Costs are a simple sum and aren't tuned.
- Should a replaced CD be able to go back to your hand?
- Should leftover Cash be worth VP at the end?
- Multiplayer later: a shared row and turn order would make this 2–4 players without changing the rules above.
