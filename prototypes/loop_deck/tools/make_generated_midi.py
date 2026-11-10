# Writes 100 synthwave card patterns to generated_midi/ (one MIDI file per card) and a card
# sheet, generated_midi/cards.csv, with each card's title, type, rarity, points and placement
# ability. Open the sheet in a spreadsheet to tune abilities; the game reads it next to the MIDI.
#
# Every pattern is 2 bars at 100 BPM. Pitched patterns are written in C major over a C chord
# (the game moves each bar to I, V, vi or IV and then to the deck's key); drums are on MIDI
# channel 10. Patterns are built from small hand-written pieces so they stay musical:
#   Percussion (24): kick x snare x hat grooves with bar-2 fills, plus hand percussion
#   Rhythm (24):     bass rhythms x note shapes (root, octave pump, fifths, walks)
#   Chord (22):      arpeggio shapes x rhythms, and chord stabs x rhythms
#   Lead (30):       a 1-bar call followed by a 1-bar answer
#
#   python tools/make_generated_midi.py
import csv, glob, os, random, struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DST = os.path.join(ROOT, 'generated_midi')
TPQ = 480
STEPS = 16  # 16th notes per bar
R = random.Random(2026)

GM = {'kick': 36, 'rim': 37, 'snare': 38, 'clap': 39, 'hat': 42, 'tom_low': 45,
      'open': 46, 'tom_mid': 47, 'crash': 49, 'tom_high': 50}
NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def midi(name):
    return 12 * (int(name[1:]) + 1) + NOTE[name[0]]


def hits(rhythm):
    """'x--.x...' -> [(step, length_in_steps)] for each x, holding through '-'."""
    r = rhythm.replace(' ', '')
    out = []
    for i, c in enumerate(r):
        if c == 'x':
            j = i + 1
            while j < len(r) and r[j] == '-':
                j += 1
            out.append((i, j - i))
    return out


def notes_for(bar, rhythm, pitches, vel_on=100, vel_off=84):
    """Pitched notes for one bar: pitches cycle if there are fewer than hits."""
    out = []
    for k, (st, ln) in enumerate(hits(rhythm)):
        p = pitches[k % len(pitches)]
        for name in p.split('+'):
            out.append((bar * STEPS + st, ln, midi(name), vel_on if st % 4 == 0 else vel_off))
    return out


def drum_bar(bar, rows):
    out = []
    for piece, rhythm in rows.items():
        for st, _ in hits(rhythm):
            vel = 112 if st % 4 == 0 else (92 if st % 2 == 0 else 72)
            out.append((bar * STEPS + st, 1, GM[piece], vel))
    return out


# --- Percussion ----------------------------------------------------------------------------
KICKS = {
    'four': 'x... x... x... x...', 'rock': 'x... .... x.x. ....', 'half': 'x... .... .... ..x.',
    'push': 'x... ..x. x... ....', 'electro': 'x..x ..x. .x.. x...', 'gallop': 'x.xx .... x.xx ....',
}
SNARES = {
    'back': '.... x... .... x...', 'half': '.... .... x... ....', 'ghost': '.... x..x .... x...',
    'clap': '.... x... .... x...',
}
HATS = {
    'eighths': {'hat': 'x.x. x.x. x.x. x.x.'}, 'sixteenths': {'hat': 'xxxx xxxx xxxx xxxx'},
    'offbeat': {'hat': 'x... x... x... x...', 'open': '..x. ..x. ..x. ..x.'},
    'lift': {'hat': 'x.x. x.x. x.x. x...', 'open': '.... .... .... ..x.'},
}
FILLS = {
    'none': {},
    'toms': {'tom_high': '.... .... .... xx..', 'tom_mid': '.... .... .... ..x.', 'tom_low': '.... .... .... ...x'},
    'roll': {'snare': '.... .... .... x.xx'},
    'crash': {},
}
PERC = [
    {'hat': 'xxxx xxxx xxxx xxxx', 'clap': '.... x... .... x...'},
    {'open': '..x. ..x. ..x. ..x.', 'rim': 'x... .... x... ....'},
    {'rim': '..x. .x.. x..x .x..'},
    {'clap': 'x..x ..x. .... x...', 'hat': 'x.x. x.x. x.x. x.x.'},
    {'hat': 'x.xx x.xx x.xx x.xx'},
    {'clap': '.... x... .... x...', 'rim': '...x ...x ...x ...x'},
]


def percussion():
    out = []
    combos = [(k, s, h) for k in KICKS for s in SNARES for h in HATS
              if not (k == 'half') ^ (s == 'half')]
    R.shuffle(combos)
    for i, (k, s, h) in enumerate(combos[:18]):
        fill = list(FILLS)[i % 4]
        rows = {'kick': KICKS[k], 'clap' if s == 'clap' else 'snare': SNARES[s]}
        rows.update(HATS[h])
        bar2 = dict(rows)
        if fill in ('toms', 'roll'):
            bar2 = {p: r[:14] + '....' for p, r in rows.items() if p != 'kick'}  # clear last beat
            bar2['kick'] = rows['kick']
            for p, r in FILLS[fill].items():
                base = bar2.get(p, '.... .... .... ....').replace(' ', '')
                add = r.replace(' ', '')
                bar2[p] = ''.join('x' if (a == 'x' or b == 'x') else '.' for a, b in zip(base, add))
        notes = drum_bar(0, rows) + drum_bar(1, bar2)
        if fill == 'crash':
            notes.append((0, 1, GM['crash'], 110))
        out.append(('Drums', notes, 9))
    for rows in PERC:
        out.append(('Perc', drum_bar(0, rows) + drum_bar(1, rows), 9))
    return out


# --- Rhythm (bass) -------------------------------------------------------------------------
BASS_RHYTHMS = {
    'eighths': 'x.x. x.x. x.x. x.x.', 'legato': 'x-x- x-x- x-x- x-x-', 'sixteenths': 'xxxx xxxx xxxx xxxx',
    'gallop': 'x.xx x.xx x.xx x.xx', 'offbeat': '..x- ..x- ..x- ..x-', 'sync': 'x--x --x- x--x --x-',
    'quarters': 'x--. x--. x--. x--.', 'drive': 'x.xx x.x. x.xx x.x.',
}
BASS_SHAPES = {
    'root': ['C2'], 'pump': ['C2', 'C3'], 'fifths': ['C2', 'C2', 'G2', 'C2'],
    'octfifth': ['C2', 'C3', 'G2', 'C3'], 'walk': ['C2', 'E2', 'G2', 'A2'], 'climb': ['C2', 'C2', 'D2', 'E2'],
}


def rhythm():
    out = []
    combos = [(r, s) for r in BASS_RHYTHMS for s in BASS_SHAPES
              if not (r in ('offbeat', 'quarters') and s == 'root')]
    R.shuffle(combos)
    for r, s in combos[:24]:
        notes = notes_for(0, BASS_RHYTHMS[r], BASS_SHAPES[s]) + notes_for(1, BASS_RHYTHMS[r], BASS_SHAPES[s])
        out.append(('Rhythm', notes, 0))
    return out


# --- Chord (arps and stabs) ----------------------------------------------------------------
ARPS = {
    'up': ['C4', 'E4', 'G4', 'C5'], 'down': ['C5', 'G4', 'E4', 'C4'], 'updown': ['C4', 'E4', 'G4', 'C5', 'G4', 'E4'],
    'broken': ['C4', 'G4', 'E4', 'G4'], 'wide': ['C3', 'G3', 'C4', 'E4'], 'high': ['G4', 'C5', 'E5', 'C5'],
}
ARP_RHYTHMS = {'sixteenths': 'xxxx xxxx xxxx xxxx', 'eighths': 'x.x. x.x. x.x. x.x.', 'gated': 'xx.x xx.x xx.x xx.x'}
VOICINGS = [['C4+E4+G4'], ['E4+G4+C5'], ['G3+C4+E4']]
STAB_RHYTHMS = {
    'offbeat': '..x. ..x. ..x. ..x.', '332': 'x--x --x- .... ....', 'push': '..x. ..x. x... ....',
    'quarters': 'x... x... x... x...', 'chop': 'x.x. x.x. x.x. x.x.', 'longshort': 'x--- --x- x--- ....',
    'sync': 'x..x ..x. ..x. x...',
}


def chord():
    out = []
    arps = [(a, r) for a in ARPS for r in ARP_RHYTHMS]
    R.shuffle(arps)
    for a, r in arps[:12]:
        out.append(('Chord', notes_for(0, ARP_RHYTHMS[r], ARPS[a], 96, 82) + notes_for(1, ARP_RHYTHMS[r], ARPS[a], 96, 82), 0))
    stabs = [(v, r) for v in range(len(VOICINGS)) for r in STAB_RHYTHMS]
    R.shuffle(stabs)
    for v, r in stabs[:10]:
        out.append(('Chord', notes_for(0, STAB_RHYTHMS[r], VOICINGS[v], 92, 88) + notes_for(1, STAB_RHYTHMS[r], VOICINGS[v], 92, 88), 0))
    return out


# --- Lead (call and answer) ----------------------------------------------------------------
CALLS = [
    ('x.x. x--- x.x. x---', 'E5 D5 C5 E5 D5 C5'), ('x--- x-x- x--- ----', 'G5 E5 D5 C5'),
    ('x.xx .x.. x-x- x---', 'C5 D5 E5 G5 A5 G5 E5'), ('..x. x.x. x--- ----', 'G4 C5 D5 E5'),
    ('x--x --x- x-x- x---', 'E5 E5 E5 D5 C5 D5'), ('x--- ---- x--- x---', 'G5 E5 C5'),
    ('xxx. xxx. x--- ....', 'C5 D5 E5 D5 E5 G5 E5'), ('x.x. x.x. x.x. x.x.', 'C5 E5 G5 E5 C5 E5 G5 A5'),
    ('.x.x .x.x .x.x .x.x', 'G5 E5 G5 E5 A5 G5 E5 C5'), ('x-x- x-x- x--- ----', 'C6 B5 A5 G5 E5'),
]
ANSWERS = [
    ('x--- x--- x--- ----', 'D5 E5 C5'), ('x.x. x--- .... ....', 'E5 D5 C5'), ('.... .... x.x. x---', 'G5 E5 C5'),
    ('x--x --x- x--- ----', 'A5 G5 E5 D5'), ('x--- ---- x.x. xxxx', 'C5 C5 D5 E5 G5 A5 C6'),
    ('x--- ---- ---- ----', 'C5'), ('xxx. x.x. x--- ....', 'E5 D5 C5 D5 E5 C5'),
    ('x.x. x.x. x.x. x.x.', 'G5 E5 C5 E5 G5 E5 C5 E5'), ('.... .... .... ....', ''),
]


def lead():
    out = []
    pairs = [(c, a) for c in range(len(CALLS)) for a in range(len(ANSWERS))]
    R.shuffle(pairs)
    for c, a in pairs[:30]:
        call, ans = CALLS[c], ANSWERS[a]
        notes = notes_for(0, call[0], call[1].split())
        if ans[1]:
            notes += notes_for(1, ans[0], ans[1].split())
        out.append(('Lead', notes, 0))
    return out


# --- Names ---------------------------------------------------------------------------------
ADJ = ['Neon', 'Midnight', 'Chrome', 'Laser', 'Electric', 'Vapor', 'Turbo', 'Sunset', 'Crystal', 'Digital',
       'Retro', 'Cyber', 'Velvet', 'Starlight', 'Magenta', 'Pastel', 'Analog', 'Hyper', 'Ultra', 'Night',
       'Polar', 'Solar', 'Lunar', 'Ruby', 'Cobalt']
NOUN = ['Drive', 'Skyline', 'Highway', 'Pulse', 'Horizon', 'Arcade', 'Run', 'Dream', 'City', 'Coast',
        'Heart', 'Signal', 'Grid', 'Mirage', 'Cruise', 'Echo', 'Rush', 'Glow', 'Wave', 'Boulevard',
        'Circuit', 'Palm', 'Tide', 'Motel', 'Rider']

# --- Placement abilities -------------------------------------------------------------------
# (condition, condition param, effect, common value, target). Slots 1-4 are the I, V, vi and IV
# chords. Rarer cards get bigger values (see STEP) and fewer base points.
ABILITIES = {
    'Percussion': [('first', '', 'mult', 2, 'self'), ('slot1', '', 'mult', 2, 'self'), ('odd', '', 'points', 6, 'self'),
                   ('next_is', 'Rhythm', 'flow_add', 1, 'set'), ('first', '', 'points', 6, 'next'),
                   ('prev_is', 'Percussion', 'points', 8, 'self'), ('next_is', 'Lead', 'flow_add', 1, 'set')],
    'Rhythm': [('slot2', '', 'mult', 2, 'self'), ('prev_is', 'Percussion', 'mult', 2, 'self'), ('even', '', 'points', 6, 'self'),
               ('next_is', 'Chord', 'flow_add', 1, 'set'), ('per_before', 'Percussion', 'points', 4, 'self'),
               ('next_is', 'Lead', 'points', 6, 'next'), ('prev_is', 'Gated Kit', 'mult', 2, 'self')],
    'Chord': [('slot3', '', 'mult', 2.5, 'self'), ('prev_is', 'Rhythm', 'mult', 2, 'self'), ('next_is', 'Lead', 'flow_add', 1, 'set'),
              ('odd', '', 'points', 6, 'self'), ('per_before', 'Rhythm', 'points', 5, 'self'), ('even', '', 'flow_add', 0.5, 'set'),
              ('next_is', 'Saw Lead', 'flow_add', 1, 'set')],
    'Lead': [('slot4', '', 'mult', 3, 'self'), ('last', '', 'mult', 2.5, 'self'), ('prev_is', 'Chord', 'mult', 2, 'self'),
             ('per_before', 'Rhythm', 'points', 4, 'self'), ('prev_is', 'Rhythm', 'flow_add', 1, 'set'), ('even', '', 'points', 8, 'self'),
             ('last', '', 'cash', 2, 'self'), ('prev_is', 'Synth Pluck', 'mult', 2, 'self')],
}
STEP = {'points': 2, 'mult': 0.5, 'flow_add': 0.5, 'cash': 1}
RARITIES = ['common'] * 10 + ['uncommon'] * 7 + ['rare'] * 3
BASE = {'common': 5, 'uncommon': 4, 'rare': 3}


def ability(card_type, i):
    cond, cp, eff, val, tgt = ABILITIES[card_type][i % len(ABILITIES[card_type])]
    rarity = RARITIES[R.randrange(len(RARITIES))]
    tier = {'common': 0, 'uncommon': 1, 'rare': 2}[rarity]
    value = val + STEP[eff] * tier
    return rarity, BASE[rarity] + R.randrange(2), cond, cp, eff, value, tgt


# --- Writing -------------------------------------------------------------------------------
def varlen(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def write(path, title, notes, channel):
    t = TPQ // 4
    ev = [(0, 0, b'\xFF\x03' + varlen(len(title)) + title.encode()),
          (0, 0, b'\xFF\x51\x03' + (600000).to_bytes(3, 'big'))]
    for st, ln, p, v in notes:
        ev.append(((st + ln) * t, 1, bytes([0x80 | channel, p, 0])))
        ev.append((st * t, 2, bytes([0x90 | channel, p, v])))
    ev.append((2 * STEPS * t, 3, b'\xFF\x2F\x00'))
    ev.sort(key=lambda e: (e[0], e[1]))
    data, last = b'', 0
    for tick, _, msg in ev:
        data += varlen(tick - last) + msg
        last = tick
    with open(path, 'wb') as f:
        f.write(b'MThd' + struct.pack('>IHHH', 6, 0, 1, TPQ) + b'MTrk' + struct.pack('>I', len(data)) + data)


def main():
    os.makedirs(DST, exist_ok=True)
    for old in glob.glob(os.path.join(DST, '*.mid')):
        os.remove(old)
    patterns = percussion() + rhythm() + chord() + lead()
    names = [f'{a} {n}' for a in ADJ for n in NOUN]
    R.shuffle(names)
    rows = []
    counters = {}
    for k, (kind, notes, channel) in enumerate(patterns):
        card_type = {'Drums': 'Percussion', 'Perc': 'Percussion'}.get(kind, kind)
        n = counters.get(card_type, 0)
        counters[card_type] = n + 1
        title = names[k]
        prefix = {'Percussion': 'drums', 'Rhythm': 'rhythm', 'Chord': 'chord', 'Lead': 'lead'}[card_type]
        file = f'{prefix}_{n + 1:02d}_{title.lower().replace(" ", "_")}'
        write(os.path.join(DST, file + '.mid'), f'{kind} {title}', notes, channel)
        rarity, points, cond, cp, eff, value, tgt = ability(card_type, n)
        rows.append([file, title, card_type, rarity, points, cond, cp, eff, value, tgt, ''])
    with open(os.path.join(DST, 'cards.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['file', 'title', 'type', 'rarity', 'points', 'condition', 'cond_param', 'effect', 'value', 'target', 'target_param'])
        w.writerows(rows)
    # Keep Godot from importing the sheet as a translation table.
    with open(os.path.join(DST, 'cards.csv.import'), 'w') as f:
        f.write('[remap]

importer="keep"
')
    print(len(patterns), 'patterns and cards.csv written to', DST, counters)


main()
