# Writes the demo synthwave patterns in patterns/ as MIDI files.
#
# Pitched patterns are written in C major over a C chord (the I chord). The game plays bar 1 of
# a set over I, bar 2 over V, bar 3 over vi and bar 4 over IV by moving each bar's notes along
# the C major scale, then moves everything to the deck's key. Drum patterns are on MIDI channel
# 10 with General MIDI drum notes. Each file has one track named "<Type> <Title>".
#
# Notation used below (only for these demo files):
#   steps per beat: 4 = 16th notes; every pattern is 2 bars
#   rhythm: x = a note starts, - = the note holds, . = rest (spaces and | are ignored)
#   pitches: one entry per x, chords joined with +
import glob, os, struct

DST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'patterns')
TPQ = 480
BEATS = 8
GM = {'kick': 36, 'rim': 37, 'snare': 38, 'clap': 39, 'hat_closed': 42, 'tom_low': 45,
      'hat_open': 46, 'tom_mid': 47, 'crash': 49, 'tom_high': 50}

PITCHED = [
    ('rhythm_octave_pump', 4,
     'x.x. x.x. x.x. x.x. | x.x. x.x. x.x. x.x.',
     'C2 C3 C2 C3 C2 C3 C2 C3 | C2 C3 C2 C3 C2 C3 C2 C3'),
    ('rhythm_root_drive', 4,
     'x.x. x.x. x.x. x.x. | x.x. x.x. x.x. x.x.',
     'C2 C2 C2 C2 C2 C2 C2 C2 | C2 C2 C2 C2 C2 C2 E2 G2'),
    ('rhythm_gallop', 4,
     'x.xx x.xx x.xx x.xx | x.xx x.xx x.xx x.xx',
     'C2 C2 C2 C2 C2 C2 C2 C2 C2 C2 C2 C2 | C2 C2 C2 C2 C2 C2 C2 C2 C2 C2 C2 C2'),
    ('rhythm_offbeat_pop', 4,
     '..x- ..x- ..x- ..x- | ..x- ..x- ..x- ..x-',
     'C2 C2 C3 C2 | C2 C2 C3 C2'),
    ('chord_arp_up', 4,
     'xxxx xxxx xxxx xxxx | xxxx xxxx xxxx xxxx',
     'C4 E4 G4 C5 C4 E4 G4 C5 C4 E4 G4 C5 C4 E4 G4 C5 | C4 E4 G4 C5 C4 E4 G4 C5 C4 E4 G4 C5 C4 E4 G4 C5'),
    ('chord_offbeat_stabs', 4,
     '..x. ..x. ..x. ..x. | ..x. ..x. ..x. ..x.',
     'C4+E4+G4 C4+E4+G4 C4+E4+G4 C4+E4+G4 | C4+E4+G4 C4+E4+G4 C4+E4+G4 C4+E4+G4'),
    ('lead_soaring_hook', 4,
     'x--- --x- x--- ---- | x--- x--- x--- ----',
     'E5 D5 C5 | E5 G5 E5'),
    ('lead_call_and_answer', 4,
     'x.x. x--- .... .... | .... .... x.x. x---',
     'C5 D5 E5 | G5 E5 C5'),
    ('lead_sparkle', 4,
     '..x. ..x. ..x. ..x. | ..x. ..x. ..x. ..x.',
     'G5 E5 C6 E5 | G5 E5 G5 C6'),
    ('lead_turnaround_run', 4,
     '.... .... .... .... | .... .... x.x. xxxx',
     'C5 D5 E5 G5 A5 C6'),
]

DRUMS = [
    ('drums_outrun_four', {
        'kick':       'x... x... x... x... | x... x... x... x...',
        'snare':      '.... x... .... x... | .... x... .... x...',
        'hat_closed': 'x... x... x... x... | x... x... x... x...',
        'hat_open':   '..x. ..x. ..x. ..x. | ..x. ..x. ..x. ..x.',
    }),
    ('drums_gated_halftime', {
        'kick':       'x... .... ..x. .... | x... ...x ..x. ....',
        'snare':      '.... .... x... .... | .... .... x... ....',
        'hat_closed': 'x.x. x.x. x.x. x.x. | x.x. x.x. x.x. x.x.',
    }),
    ('drums_motorik', {
        'kick':       'x... .... x... .... | x... .... x.x. ....',
        'snare':      '.... x... .... x... | .... x... .... x...',
        'hat_closed': 'xxxx xxxx xxxx xxxx | xxxx xxxx xxxx xxxx',
    }),
    ('drums_tom_fill', {
        'crash':      'x... .... .... .... | .... .... .... ....',
        'kick':       'x... x... x... x... | x... x... .... ....',
        'snare':      '.... x... .... x... | .... x... .... ....',
        'hat_closed': 'x.x. x.x. x.x. x.x. | x.x. x.x. .... ....',
        'tom_high':   '.... .... .... .... | .... .... xx.. ....',
        'tom_mid':    '.... .... .... .... | .... .... ..xx ....',
        'tom_low':    '.... .... .... .... | .... .... .... xxxx',
    }),
    ('perc_clap_shaker', {
        'clap':       '.... x... .... x... | .... x... .... x...',
        'hat_closed': 'xxxx xxxx xxxx xxxx | xxxx xxxx xxxx xxxx',
    }),
]

NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def midi(name):
    return 12 * (int(name[1:]) + 1) + NOTE[name[0]]


def steps_of(rhythm, spb):
    steps = rhythm.replace(' ', '').replace('|', '')
    assert len(steps) == BEATS * spb, (rhythm, len(steps))
    return steps


def parse(spb, rhythm, pitches):
    steps = steps_of(rhythm, spb)
    chords = pitches.replace('|', ' ').split()
    notes, k, i = [], 0, 0
    while i < len(steps):
        if steps[i] == 'x':
            j = i + 1
            while j < len(steps) and steps[j] == '-':
                j += 1
            vel = 100 if i % spb == 0 else 84
            for p in chords[k].split('+'):
                notes.append((i * TPQ // spb, (j - i) * TPQ // spb, midi(p), vel))
            k += 1
            i = j
        else:
            i += 1
    assert k == len(chords), (rhythm, k, len(chords))
    return notes


def parse_drums(rows):
    notes = []
    for piece, rhythm in rows.items():
        for i, c in enumerate(steps_of(rhythm, 4)):
            if c == 'x':
                vel = 110 if i % 4 == 0 else (90 if i % 2 == 0 else 70)
                notes.append((i * TPQ // 4, TPQ // 4, GM[piece], vel))
    return notes


def varlen(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def write(path, name, notes, channel):
    title = ' '.join(w.capitalize() for w in name.split('_'))
    ev = [(0, 0, b'\xFF\x03' + varlen(len(title)) + title.encode()),
          (0, 0, b'\xFF\x51\x03' + (600000).to_bytes(3, 'big')),
          (0, 0, b'\xFF\x58\x04\x04\x02\x18\x08')]
    for st, ln, p, v in notes:
        ev.append((st + ln, 1, bytes([0x80 | channel, p, 0])))
        ev.append((st, 2, bytes([0x90 | channel, p, v])))
    ev.append((BEATS * TPQ, 3, b'\xFF\x2F\x00'))
    ev.sort(key=lambda e: (e[0], e[1]))
    data, t = b'', 0
    for tick, _, msg in ev:
        data += varlen(tick - t) + msg
        t = tick
    with open(path, 'wb') as f:
        f.write(b'MThd' + struct.pack('>IHHH', 6, 0, 1, TPQ))
        f.write(b'MTrk' + struct.pack('>I', len(data)) + data)


os.makedirs(DST, exist_ok=True)
for old in glob.glob(os.path.join(DST, '*.mid')):
    os.remove(old)
for name, spb, rhythm, pitches in PITCHED:
    write(os.path.join(DST, name + '.mid'), name, parse(spb, rhythm, pitches), 0)
for name, rows in DRUMS:
    write(os.path.join(DST, name + '.mid'), name, parse_drums(rows), 9)
print(len(PITCHED) + len(DRUMS), 'patterns written to', DST)
