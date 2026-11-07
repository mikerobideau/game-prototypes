# Holdings data

All game content is Godot resources (`.tres`), one file per item, edited in the Inspector. The game loads every `.tres` in these folders at startup; there's no list to keep in sync.

| Folder | Type | One file per |
|---|---|---|
| `cards/` | `HoldingsCard` | business |
| `events/` | `HoldingsEvent` | market event |
| `offers/` | `HoldingsOffer` | Investor Meeting offer |
| `editions/` | `HoldingsEdition` | card edition |

The resource scripts live in `../types/`.

## Editing
- **Tweak something:** open the `.tres` in the FileSystem dock and change fields in the Inspector. Drop-downs list every valid option.
- **Add a card:** duplicate a similar card (right-click → Duplicate), set a new `id` (lower_snake_case; it's also the art file name in `art/` and `art_silhouette/`), and edit.
- **Remove a card:** delete its file, or move it out of the folder.
- Restart the game to see changes.

## HoldingsCard
- **id, name, sector, value, rarity**: value = Brand earned when placed and each time it operates. Rarity sets deck copies (common 3, uncommon 2, rare 1).
- **Dice**: `pattern` (`none` = needs no die), `pattern_param` (used by exact / at least / at most / sum patterns), `chain_left`, `copy_left`.
- **Text**: `text` (tooltip), `short_text` (card face), `tags` (e.g. `startup`).
- **Abilities**: a list of `HoldingsAbility`. Each has:
  - **when**: `operate`, `quarter_end`, `after_quarter`, `neighbor_operate`, `sell`, `buy`, `bad_event`.
  - **kind**: what happens. Fill in only the fields that kind uses:

| Kind | Fields |
|---|---|
| gain / pay | resource amounts (cash, labor…) |
| convert | resource amounts to pay + brand_for_convert |
| gain_per | resource, per, sector, amount, divide_by, max_count |
| vp | amount |
| vp_per | per, sector or resource, amount, divide_by, max_count |
| vp_if | condition, condition_sector, condition_amount, amount, else_amount |
| grow | amount, only_if_operated |
| grow_adjacent | tag, amount |
| upgrade_adjacent / extra_die | amount |
| mature | quarters, min_value, speed_per, sector |
| retrigger_adjacent / gain_random_card | sector (optional filter) |
| distress_self | on_die |
| gain_ctx | resource, context_key |
| peek_swap | count |
| forecast_* | forecast_slot |
| absorb, restore_dormant, refresh_market, refresh_type, replace_market | none |

  `only_if_neighbor_sector` restricts a `neighbor_operate` ability to neighbours of that sector.
- **Passive rules**: prevent_distress (+ Brand when it does), repeat_same_die, adjacent_any_die, adjacent_value (sector + amount), adjacent_die_plus (sector + amount).
- **Fallback art**: settings for the drawn building used only when a card has no SVG.

## HoldingsEvent
`tier` (`mild` / `moderate` / `severe`), `category` (shown before an event is revealed), `text`, and `effects` (list of `HoldingsEventEffect`). Optional **weakened version** (`weak_text` + `weak_effects`; an event with weak effects can be weakened by PR Firm) and **goal** (`goal` + sector/amount, with a `penalty` list applied next quarter if missed).

`HoldingsEventEffect` kinds: dice_minus (amount), dice_minus_per_cards (per_businesses), odd_minus, cap_highest (cap), cost_plus (resource, amount), refresh_plus (amount), market_frozen, refresh_frozen, lose_half (resource), halve_output / halve_value / dormant (target), intel_locked, exchange_rate (rate).

## HoldingsOffer / HoldingsEdition
Offers: `name`, `text`, `icon`, and `edition` for edition offers. Editions: `name`, `text`, `color`. Their effects are wired in game code by `id`, so a brand-new offer or edition id needs code; renaming, rewording and recolouring are safe.

## HoldingsTutorialStep (`tutorial/`)
One file per lesson, played in file-name order (`01_welcome`, `02_news`, ...). Fields:
- `title` and `body`: the lesson text. A line break starts a new paragraph. Resource names and "Brand" show as icons, as on cards.
- **Live values** so text never goes stale: `{card:id}` (card name), `{cost:id}` (current price), `{value:id}`, `{years}`, `{quarters}`, `{target}`, `{strikes}`, `{dice}`, `{cap}`, `{rate}`, `{reroll}`, `{scout}`.
- `targets`: what to spotlight; the player can only click these until the lesson moves on. `market:0`-`3`, `board:0`-`8`, `die:0`-`3`, `res:cash`/`labor`/`equipment`/`intel`/`advertising`, `buy`, `scout`, `deck`, `end`, `exchange`, `reroll`, `assets`, `market_panel`, `portfolio`, `calendar`, `clipping`, `scorepad`, `help`. Use `modal` while a popup is open, `*` to free everything, or leave empty for a centred message.
- `wait`: `next` shows a Next button; anything else waits for the player to do that action (`intro_closed`, `market_pick`, `buy`, `placed`, `operated`, `resource`, `scout`, `end_quarter`, `next_quarter`, `meeting`).

The scripted opening (sheet, seed, first headline, the four Market cards and the dice) is in `TUTORIAL_*` in `holdings_data.gd`. Bad card ids or targets are reported as warnings when the game starts.
