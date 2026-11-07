# Dice Engine Game — Prototype Spec

Oct 26, 2026 · @Mike

## Overview

A single-player digital card-and-dice engine builder. The player buys cards with five resources, places them on a board, and activates them each round by assigning rolled dice that match each card's dice pattern. Every round has a victory point (VP) target the player must reach while a visible forecast of environmental debuffs disrupts their engine.

This spec is written for an implementer (human or LLM) building a playable prototype. Rules marked **Decided** are fixed design choices. Rules marked **Default** are placeholder values chosen to make the prototype playable; expose them as tunable constants.

**Theme:** not final. Dice are plain numbers (d6). Cards are "plants" and resources use plant names as placeholders only; keep all names data-driven so the theme can be swapped later.

**Target platform:** desktop (Steam), Godot 4 with GDScript. Code style: private functions take an underscore prefix (`_on_card_clicked`); variables do not (`market_cards`, not `_market_cards`).

### Design pillars

1. **Every die is a choice.** Dice are a spendable resource; each one either grows the engine or protects it from the forecast.
2. **Plan, don't gamble.** Threats and the market are visible in advance. Randomness lives in which numbers you roll, never in whether a hidden event ruins you.
3. **The engine must keep growing.** Round targets rise faster than passive income, so synergy and good building are required to survive.
4. **Pressure scales with success.** Debuffs target the strongest parts of a board so a lead never makes the game trivial.

## Round structure

A run is a fixed sequence of rounds (Default: 12). Each round follows these phases in order.

1. **Forecast resolves.** Today's event (the front slot of the forecast) takes effect. Its debuffs apply for this round unless the event says otherwise. Any conditional debuffs from earlier rounds whose conditions failed also apply now.
2. **Roll.** Roll the dice pool (Default: 4 dice; always clamped to 3–5 after modifiers).
3. **Action phase.** The player takes these actions in any order, as many times as they can afford:
   - Assign a die to a board card whose pattern it matches, activating that card immediately.
   - Spend Pollen to adjust a die (see Dice).
   - Buy a card from the market and place it on the board.
   - Refresh the market by spending Seeds.
   - Exchange resources at 3:1.
4. **End action phase.** The player clicks End Round. Unused dice are discarded (Default: no carryover).
5. **Scoring.** Round VP = the sum of printed values of all non-dormant board cards + all VP earned from activations this round.
6. **Target check.** Compare round VP to this round's target (see Scoring). On a miss, apply the miss consequence.
7. **Condition check.** Evaluate any conditional debuffs from this round's event (for example, "was a Water card activated?"). Failures queue their penalty for the next round.
8. **Cleanup.** Clamp each resource to the storage cap. Clear round-only debuffs.
9. **Forecast advances.** Shift the forecast forward one slot and reveal a new event at the back.

**Decided:** VP targets are per round, and VP does not bank between rounds.

## Dice and activation

**Decided:** dice are a spendable resource, not weather or a random event. The pool size is 3–5.

- **Pool:** standard d6. Default base size 4. Card abilities can raise it ("+1 die next round") and debuffs can lower it, but the final pool is always clamped to 3–5.
- **Activation:** assigning a die to a board card whose pattern it satisfies activates that card's ability immediately. The die is consumed.
- **One activation per card per round** (Default). Some abilities may grant a second activation.
- **Multi-die patterns:** a card may require 2 dice (for example, a pair or a sum). The player assigns both dice; the card activates once both are placed.
- **Pollen adjustment:** spend 1 Pollen to change one unassigned die by +1 or −1 (no wraparound: 1 cannot go to 0, 6 cannot go to 7). Default: spend 2 Pollen to reroll one unassigned die.

### Pattern vocabulary

Implement patterns as data so new ones can be added without code changes.

| Pattern | Dice | Rule |
| --- | --- | --- |
| Odd | 1 | Die is 1, 3, or 5 |
| Even | 1 | Die is 2, 4, or 6 |
| Low | 1 | Die is 1–3 |
| High | 1 | Die is 4–6 |
| Exact N | 1 | Die equals N |
| At least N | 1 | Die is N or higher |
| At most N | 1 | Die is N or lower |
| Any | 1 | Any die |
| Pair | 2 | Both dice equal |
| Sum N+ | 2 | Two dice total N or more |
| Sum exactly N | 2 | Two dice total exactly N |
| Run | 2 | Two consecutive values (e.g., 3 and 4) |

Debuffs can modify patterns (for example, "High now means 5–6 for this card"), so pattern checks should read from the card's current effective pattern, not its base pattern.

## Cards

Each card has a printed value, a type, a cost, a dice pattern, and an ability.

### Value (Decided)

- Every card has a value from 1 to 7.
- A card on the board pays its value in VP **every round** at scoring, including the round it was placed, unless it is dormant.
- Value and ability strength trade off (Default design rule): high-value cards (5–7) have weak or no abilities; low-value cards (1–3) have strong abilities and synergies. Mid-value cards (4) are balanced.

### Types

- Five types, one per resource: Water, Sunlight, Nutrient, Seed, Pollen. A card's type sets its main cost resource and usually the resource its ability produces.
- Conditional debuffs and synergy abilities reference types ("if no Water card is activated…", "+1 VP per Nutrient card on your board").

### Abilities (Decided list of effect kinds)

Abilities fire when the card is activated. Build them from composable effect primitives:

- Gain resource(s).
- Gain VP (flat).
- Gain VP per condition (per card of a type on the board, per die of a pattern used this round, per card in the market, per empty slot, per activation this round, etc.).
- Refresh the market (full or targeted; see Market).
- Gain a random card (from the market deck, placed on the board if a slot is free, else lost).
- +1 die next round.
- Adjust a die (as Pollen does).
- Forecast manipulation: reveal a further slot, delay the front event one round, weaken an event, cancel an event.
- Restore a dormant card.

### Board

- Default: 8 board slots. A full board forces a replacement: to place a new card, the player must first discard one board card (no refund).
- Cards bought from the market go directly to the board (Default; there is no hand).
- **Dormant** cards: do not pay their value and cannot be activated. A dormant card can be restored by an ability, or by assigning any die to it (that activation only restores the card; it does not trigger the ability).

### Starting board (Default)

Two starter cards (see Starter content): one producing Water and Seeds, one producing VP. Starting resources: 2 Water, 1 Sunlight, 1 Nutrient, 2 Seeds, 1 Pollen.

## Resources and economy

**Decided:** five resources. Cards are bought with combinations of them, and some card abilities produce them. Each has a distinct job (names are placeholders).

| Resource | Role | Spent on |
| --- | --- | --- |
| Water | Common, baseline economy | Part of almost every card cost |
| Sunlight | Scarce value resource | Required for high-value (5–7) cards |
| Nutrients | Synergy resource | Main cost of combo / ability cards |
| Seeds | Card-flow resource | Card costs; refreshing the market |
| Pollen | Rare dice resource | Card costs; adjusting or rerolling dice |

### Cost rule (Decided: costs follow a learnable formula)

Players must be able to predict what a card will cost before it appears, so they can plan which resources to gather. Generate or validate every card's cost with this rule (Default numbers):

1. Total cost = card value + 1.
2. The card's type resource pays half the total, rounded up.
3. If the card's value is 5 or higher and its type is not Sunlight, 1 unit of the remainder must be Sunlight.
4. The rest is paid in Water. (Water-type cards: the remainder is paid in Seeds instead.)

Examples: a value-3 Nutrient card costs 2 Nutrients + 2 Water. A value-6 Seed card costs 4 Seeds + 1 Sunlight + 2 Water. Show the cost rule in the UI (a help panel) so it can be learned.

### Exchange (Decided)

At any time during the action phase, trade 3 of any one resource for 1 of any other. Intentionally a bad rate: a safety valve, not a strategy.

### Storage cap (Default)

Maximum 5 of each resource, enforced at cleanup. Resources above the cap are lost. During the action phase the player may temporarily exceed the cap.

### Income

There is no automatic per-round income (Default). All resources come from card activations and starting stock, so the starting board must produce Water and Seeds reliably.

## Market

**Decided:** market cards persist from round to round. The market never refreshes on its own; Seeds must be spent to refresh it, and some card abilities also refresh it.

- **Size:** 5 face-up cards (Default), dealt from a shuffled market deck containing the full card pool (starter cards excluded).
- **Buying:** pay the card's cost; the card goes to the board. The empty market slot refills immediately from the deck.
- **Seed refresh:** spend 2 Seeds (Default, flat cost) to discard all 5 market cards and deal 5 new ones. Discarded cards go to a discard pile.
- **Card-ability refreshes** are more targeted than the Seed refresh, so they are not just a cheaper copy of it. Examples: replace one chosen market card; refresh only cards of one type; look at the top 3 deck cards and swap one into the market.
- **Deck exhaustion:** when the deck is empty, shuffle the discard pile to form a new deck.
- **Debuff hooks:** events may raise the refresh cost, freeze the market (no buying or refreshing this round), discard a market card, or raise costs of one resource type.

Not in scope (Decided against): a market preview of upcoming cards, a sliding/expiring conveyor, and reserving cards.

## Forecast and events

**Decided:** environmental pressure comes from events that fully or partially debuff game elements. Events are shown in advance as a forecast several days ahead so the player can plan.

**Decided against:** events that simply demand specific dice ("two dice must be a six"). Those are pure luck. Every event must be something the player can prepare for or play around.

### Forecast

- The forecast shows the next 3 rounds (Default). Slot 1 is today's event; slots 2–3 are upcoming.
- Default visibility: slots 1 and 2 show full details; slot 3 shows only the event's category (Card, Dice, Economy, Market, Conditional). This keeps planning possible with some uncertainty.
- Abilities can reveal slot 3 fully, delay the front event by one round, weaken an event (partial instead of full), or cancel it.
- Event intensity escalates over the run: the event deck is split into tiers (Mild, Moderate, Severe) and the forecast draws from higher tiers in later rounds. Default: rounds 1–4 Mild, 5–8 Mild/Moderate, 9–12 Moderate/Severe.

### Debuff categories

- **Card:** disable a card for the round, make a card dormant, raise its activation requirement, halve its ability output, halve its printed value this round.
- **Dice:** cap a die at 4, lock a die (no Pollen adjustment), −1 to all odd dice, lose a die this round.
- **Economy:** a resource costs +1 in purchases, lose some of a resource, exchange rate worsens to 4:1.
- **Market:** refresh costs +1 Seed, market frozen, discard the cheapest or most expensive market card.
- **Conditional (future):** a requirement the player must meet this round, or a penalty applies next round. Example: "If no Water card is activated, −1 die next round." These act as objectives with teeth.

### Full vs partial

Most events are partial (the engine runs at reduced strength). Full shutdowns ("this card is disabled") are less frequent spikes, mainly in the Severe tier.

### Scaling with the player's board

To keep a strong lead from making the game trivial, many events target the board's strongest parts: "disable your highest-value card," "your most-activated type needs +1 on its dice pattern," "−1 die per 5 cards on your board." Targeting should be deterministic and shown in the forecast (highlight the affected card) so the player can plan.

## Scoring, targets, win and loss

**Decided:** each round has its own VP target, creating an immediate challenge every round. VP does not carry over between rounds, so an early lead cannot be banked.

### Round VP

Round VP = (sum of printed values of non-dormant board cards) + (VP from activations this round).

VP grows naturally over a run because (1) more cards on the board raise the passive sum and (2) synergies between cards make activations stronger. Targets must grow faster than passive income alone, so a run cannot be survived without a working engine. Design goal: by mid-run, activations supply about half of each round's VP.

### Target curve (Default, tune from playtests)

Roughly quadratic growth. Store as a data array, not a formula, so it can be hand-tuned.

| Round | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Target VP | 4 | 6 | 9 | 12 | 16 | 20 | 25 | 31 | 38 | 46 | 55 | 65 |

Show the current target and the next round's target in the HUD at all times, with a live counter of round VP during the action phase (passive value + activation VP so far).

### Missing a target

Not yet decided (see Open questions). Prototype default: a strike system. Each missed target is a strike; 3 strikes end the run. Make the consequence a swappable rule so the alternative (shortfall carried as debt added to the next target) can be tested.

### Win and score

- **Win:** complete the final round (Default: 12) without being eliminated.
- **Score:** the sum of surplus VP over each round's target (rounds missed add 0). Used for a results screen and personal best, not for winning.

## Starter content: cards

A first pool of 22 cards for paper-testing and the prototype. All costs follow the cost rule. Names are placeholders. Abilities that count "this round" count activations so far, including the current one.

### Starting board (not in the market deck)

| Name | Type | Value | Pattern | Ability |
| --- | --- | --- | --- | --- |
| Spring | Water | 1 | Any | Gain 1 Water and 1 Seed |
| Sprout | Nutrient | 2 | Even | Gain 1 Nutrient; +1 VP |

### Market deck

Default copies: 2 of each card with value 1–3, 1 of each card with value 4+ (33 cards total).

| Name | Type | Value | Cost | Pattern | Ability |
| --- | --- | --- | --- | --- | --- |
| Rain Barrel | Water | 1 | 1 Water, 1 Seed | Any | Gain 2 Water |
| Fern | Water | 2 | 2 Water, 1 Seed | Odd | Gain 1 Water and 1 Seed |
| Reed Bed | Water | 3 | 2 Water, 2 Seeds | Low | Gain 1 Water; +1 die next round |
| Water Lily | Water | 4 | 3 Water, 2 Seeds | Even | +1 VP per Water card on board |
| Willow | Water | 6 | 4 Water, 1 Sunlight, 2 Seeds | Sum 8+ | +2 VP |
| Marigold | Sunlight | 2 | 2 Sunlight, 1 Water | Exact 6 | Gain 1 Sunlight; +2 VP |
| Heliotrope | Sunlight | 3 | 2 Sunlight, 2 Water | At least 5 | Weaken the event in forecast slot 2 (full becomes partial) |
| Sunflower | Sunlight | 5 | 3 Sunlight, 3 Water | High | +1 VP |
| Oak | Sunlight | 7 | 4 Sunlight, 4 Water | None | No ability (cannot be activated) |
| Clover | Nutrient | 1 | 1 Nutrient, 1 Water | Even | Gain 1 Nutrient; +1 VP per Nutrient card on board |
| Bean Vine | Nutrient | 2 | 2 Nutrients, 1 Water | Run | +1 VP per card activated this round |
| Comfrey | Nutrient | 3 | 2 Nutrients, 2 Water | Pair | Restore one dormant card; +2 VP |
| Mycelium | Nutrient | 4 | 3 Nutrients, 2 Water | Any | +1 VP per distinct type activated this round |
| Dandelion | Seed | 1 | 1 Seed, 1 Water | Odd | Gain 1 Seed; replace one chosen market card |
| Milkweed | Seed | 2 | 2 Seeds, 1 Water | Low | Look at top 3 market deck cards; swap one into the market |
| Poppy | Seed | 3 | 2 Seeds, 2 Water | At most 2 | Gain a random card from the market deck |
| Maple | Seed | 5 | 3 Seeds, 1 Sunlight, 2 Water | Sum exactly 7 | Refresh all market cards of one chosen type; +1 VP |
| Lavender | Pollen | 1 | 1 Pollen, 1 Water | Exact 1 | Gain 1 Pollen; +1 die next round |
| Bee Balm | Pollen | 2 | 2 Pollen, 1 Water | Pair | Gain 2 Pollen |
| Foxglove | Pollen | 4 | 3 Pollen, 2 Water | Even | Delay the event in forecast slot 2 by one round |

The pool is deliberately small. Expand it once the economy works, adding more type synergies and forecast-interaction cards.

## Starter content: events

Thirteen events across three tiers. Unless stated, effects last for the round the event resolves in. Conditional events check their condition at the end of that round and apply their penalty next round. Names are placeholders.

| Name | Tier | Category | Full / partial | Effect |
| --- | --- | --- | --- | --- |
| Light Frost | Mild | Dice | Partial | −1 to all odd dice (a 1 stays 1) |
| Thirsty Soil | Mild | Economy | Partial | Cards cost +1 Water |
| Overgrowth | Mild | Market | Partial | Market refresh costs +1 Seed |
| Dry Spell | Mild | Conditional | Partial | If no Water card is activated, −1 die next round |
| Aphids | Moderate | Card | Partial | Your highest-value card with an ability gives half its output (round down) |
| Clouded Sky | Moderate | Dice | Partial | Your highest rolled die is capped at 4 |
| Blight | Moderate | Economy | Partial | Lose half your Nutrients (round down) |
| Stagnant Market | Moderate | Market | Full | Market frozen: no buying or refreshing |
| Root Rot | Moderate | Conditional | Partial | If fewer than 3 cards are activated, your lowest-value card becomes dormant |
| Failed Pollination | Moderate | Conditional | Partial | If no Pollen card is activated, Pollen cannot be spent next round |
| Hard Frost | Severe | Card | Full | Your highest-value card becomes dormant |
| Drought | Severe | Dice | Full | −1 die |
| Locusts | Severe | Dice | Partial | −1 die per 5 cards on your board (round down) |

The forecast highlights which card a targeted event will hit (based on the board when it reaches slot 1), and shows conditional events' requirements clearly so the player can plan around them. Penalties reducing dice still respect the 3-die minimum.

## Data model and implementation notes

Keep all content (cards, events, patterns, targets, constants) as data so balance can change without code changes. In Godot 4, use custom `Resource` classes saved as `.tres` files, or JSON loaded at startup.

### Core data types

```gdscript
class_name CardData extends Resource
@export var id: StringName
@export var display_name: String
@export var card_type: StringName        # water, sunlight, nutrient, seed, pollen
@export var value: int                    # 1-7, paid every round
@export var cost: Dictionary              # {"water": 2, "seed": 1}
@export var pattern: PatternData          # null = cannot be activated
@export var effects: Array[EffectData]    # executed in order on activation
@export var copies_in_deck: int = 1

class_name PatternData extends Resource
@export var kind: StringName              # odd, even, low, high, exact, at_least, at_most, any, pair, sum_at_least, sum_exactly, run
@export var dice_count: int = 1
@export var param: int = 0                # N for exact / at_least / sum etc.

class_name EffectData extends Resource
@export var kind: StringName              # gain_resource, gain_vp, vp_per, refresh_market, replace_market_card, peek_swap_market, gain_random_card, extra_die_next_round, adjust_die, forecast_reveal, forecast_delay, forecast_weaken, forecast_cancel, restore_dormant
@export var params: Dictionary            # e.g. {"resource": "water", "amount": 2} or {"per": "board_type", "type": "nutrient", "amount": 1}

class_name EventData extends Resource
@export var id: StringName
@export var display_name: String
@export var tier: StringName              # mild, moderate, severe
@export var category: StringName          # card, dice, economy, market, conditional
@export var is_full: bool
@export var modifiers: Array[Dictionary]  # applied while the event is active
@export var condition: Dictionary         # conditional events only
@export var penalty: Array[Dictionary]    # applied next round if condition fails
```

### Runtime state

A single `RunState` object owns: round number, strikes, resources, dice pool (values + assigned flags), board slots (card instance + dormant flag + activated-this-round flag), market slots, market deck, discard pile, forecast slots, queued next-round penalties, and per-round counters (VP so far, activations so far, types activated). Card instances wrap `CardData` so debuffs can modify an instance's effective pattern, output, or value without touching the shared data.

### Architecture suggestions

- A modifier stack: events push modifiers ("pattern for card X shifted", "die cap 4", "cost +1 water") and every rules query (`can_activate`, `get_cost`, `get_effective_value`) reads through it. This keeps events data-driven.
- A signal bus for UI: `die_assigned`, `card_activated`, `resources_changed`, `round_vp_changed`, `market_changed`, `forecast_changed`.
- Seeded RNG per run for reproducible playtests and bug reports.
- A debug panel: set dice values, add resources, force an event into a forecast slot, skip to a round.

### Minimum UI

Forecast strip (3 slots) at top; market row (5 cards) with refresh button; resource counters with exchange button; board (8 slots); dice tray; HUD with round, target, live round VP, next target, and strikes; End Round button; cost-rule help panel; results screen.

## Open questions and tuning knobs

### Open design questions

- [ ] Consequence of missing a round target: strikes (prototype default), shortfall carried as debt, or immediate loss?
- [ ] Final theme, and final names for resources, cards, and events.
- [ ] Run length: is 12 rounds right, and is there a distinct final challenge round?
- [ ] Should unused dice ever carry over (for example, via a card ability)?
- [ ] Is there anything between rounds (a draft, upgrade, or reward choice), or is the market the only growth source?

### Tuning knobs (expose as constants)

| Knob | Default |
| --- | --- |
| Rounds per run | 12 |
| Base dice pool / min / max | 4 / 3 / 5 |
| Board slots | 8 |
| Market size | 5 |
| Seed refresh cost | 2 Seeds |
| Exchange rate | 3:1 |
| Resource storage cap | 5 each |
| Pollen: adjust ±1 / reroll | 1 / 2 Pollen |
| Forecast length / fully visible slots | 3 / 2 |
| Strikes before loss | 3 |
| Cost rule total | value + 1 |
| Round targets | See target curve table |

### What to watch in playtests

- Share of round VP from passive value vs activations (goal: about half from activations by mid-run).
- Rounds where the market is stuck (nothing affordable, no Seeds).
- Whether forecast events change decisions, or just reduce score.
- Rounds where targets become trivial; if so, strengthen board-scaling events before raising targets.
