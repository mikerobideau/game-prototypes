# Writes the demo pattern templates in patterns/ as MIDI files.
#
# Every pattern is a 2-bar loop at 100 BPM, written in A minor pentatonic (A C D E G).
# The game reads the MIDI, turns each note into a scale step relative to A, and lets the
# run's seed pick the instrument, the starting note and the octave. You can replace or add
# .mid files from any DAW; name them <type>_<words>.mid where <type> is rhythm, chord or lead.
#
# Notation used below (only for these demo files):
#   steps per beat: 4 = 16th notes, 3 = triplet 8ths, 1 = quarter notes
#   rhythm: x = a note starts, - = the note holds, . = rest (spaces and | are ignored)
#   pitches: one entry per x, chords joined with +
import os, struct

DST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'patterns')
TPQ = 480
BEATS = 8

PATTERNS = [
    ('rhythm_root_fifth_bass', 4,
     'x-.x -.x. x-.x -.x. | x-.x -.x. x-.x .xx.',
     'A2 A2 E2 A2 A2 E2 | A2 A2 E2 A2 A2 C3 D3'),
    ('rhythm_octave_pump', 4,
     'x.x. x.x. x.x. x.x. | x.x. x.x. x.x. x.x.',
     'A1 A2 A1 A2 A1 A2 A1 A2 | C2 C3 C2 C3 D2 D3 E2 E3'),
    ('rhythm_walking_bass', 4,
     'x--. x--. x--. x--. | x--. x--. x--. x--.',
     'A2 C3 D3 E3 | G3 E3 D3 C3'),
    ('rhythm_tresillo_bass', 4,
     'x--x --x- ---x -x-- | x--x --x- ---x -x-x',
     'A2 A2 E3 D3 C3 | A2 A2 E3 G3 E3 D3'),
    ('chord_whole_note_chords', 1,
     'x--- | x---',
     'A3+C4+E4 | G3+C4+E4'),
    ('chord_offbeat_stabs', 4,
     '..x. ..x. ..x. ..x. | ..x. ..x. ..x. ..x.',
     'A3+C4+E4 A3+C4+E4 A3+C4+E4 A3+C4+E4 | G3+C4+E4 G3+C4+E4 A3+D4+E4 A3+D4+E4'),
    ('chord_tresillo_hits', 4,
     'x--x --x- ---- x-x. | x--x --x- ---- x---',
     'A3+C4+E4 A3+C4+E4 A3+C4+E4 G3+C4+E4 G3+C4+E4 | A3+C4+E4 A3+C4+E4 A3+C4+E4 A3+D4+E4'),
    ('lead_triplet_descent', 3,
     'xxx xxx x-- ... | xxx xxx xxx x--',
     'E5 C5 A4 E5 C5 A4 G4 | G5 E5 D5 E5 C5 A4 C5 A4 G4 A4'),
    ('lead_call_and_response', 4,
     'x.x. x--- ..x. x--- | x.x. x--- ..x. x.x.',
     'A4 C5 D5 C5 A4 | A4 C5 E5 D5 C5 A4'),
    ('lead_hook', 4,
     'x-.x -.x- x-x- .... | x-.x -.x- x--- x-..',
     'E4 G4 A4 G4 E4 | E4 G4 A4 C5 A4'),
    ('lead_turnaround_run', 4,
     '.... .... .... .... | .... .... x-x- xxxx',
     'E4 G4 A4 C5 D5 E5'),
]

NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def midi(name):
    return 12 * (int(name[1:]) + 1) + NOTE[name[0]]


def parse(spb, rhythm, pitches):
    steps = rhythm.replace(' ', '').replace('|', '')
    assert len(steps) == BEATS * spb, (rhythm, len(steps))
    chords = pitches.replace('|', ' ').split()
    notes, k, i = [], 0, 0
    while i < len(steps):
        if steps[i] == 'x':
            j = i + 1
            while j < len(steps) and steps[j] == '-':
                j += 1
            vel = 100 if i % spb == 0 else 84
            for p in chords[k].split('+'):
                notes.append((i * TPQ // spb, (j - i) * TPQ // spb, midi(p), vel if '+' not in chords[k] else 88))
            k += 1
            i = j
        else:
            i += 1
    assert k == len(chords), (rhythm, k, len(chords))
    return notes


def varlen(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, (n & 0x7F) | 0x80)
        n >>= 7
    return bytes(out)


def write(path, name, notes):
    ev = [(0, 0, b'\xFF\x03' + varlen(len(name)) + name.encode()),
          (0, 0, b'\xFF\x51\x03' + (600000).to_bytes(3, 'big')),
          (0, 0, b'\xFF\x58\x04\x04\x02\x18\x08')]
    for st, ln, p, v in notes:
        ev.append((st + ln, 1, bytes([0x80, p, 0])))
        ev.append((st, 2, bytes([0x90, p, v])))
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
for name, spb, rhythm, pitches in PATTERNS:
    write(os.path.join(DST, name + '.mid'), name, parse(spb, rhythm, pitches))
print(len(PATTERNS), 'patterns written to', DST)
