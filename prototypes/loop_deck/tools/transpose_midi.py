"""
Moves a MIDI file onto the game's chord progression and into a key, the same way
loop_deck_gen.gd does, and writes the result as a new MIDI file you can open in a DAW.

    python tools/transpose_midi.py midi/test.mid G

writes midi_preview/test_G_major.mid and prints every bar's notes.

How it works, for each pitched track:

  1. The track is written in C major over a C chord (a 1-, 2- or 4-bar pattern).
  2. It is laid out over 4 bars, one chord per bar: I, V, vi, IV.
     A 2-bar pattern plays its bars 1, 2, 1, 2.
  3. FOLLOW THE CHORD: every note in a bar moves the same number of steps along the
     C major scale (not semitones). C E G moved -3 steps is G B D (the V chord),
     -2 steps is A C E (vi), -4 steps is F A C (IV).
  4. MOVE TO THE KEY: every note moves by the same number of semitones, from C to the key's
     root (G major: -5 semitones, so C becomes G).

Drum tracks (MIDI channel 10) are laid out over the 4 bars but never moved.
The game also moves a whole loop by octaves to suit each instrument; this script does not.
"""
import os
import struct
import sys

# ---------------------------------------------------------------------------
# The music: these four functions are the whole idea.
# ---------------------------------------------------------------------------

C_MAJOR = [0, 2, 4, 5, 7, 9, 11]          # semitones above C: C D E F G A B
BEATS_PER_BAR = 4

# The progression, one chord per bar: its name and how many scale steps to move from C.
PROGRESSION = [
    ("I", 0),     # C chord: stay put
    ("V", -3),    # G chord: C goes down 3 scale steps to G
    ("vi", -2),   # A minor: C goes down 2 steps to A
    ("IV", -4),   # F chord: C goes down 4 steps to F
]

# Semitones from C to each key's root, kept close to C (within 6) so notes don't jump far.
KEY_OFFSET = {"C": 0, "D": 2, "E": 4, "F": 5, "G": -5, "A": -3, "B": -1}


def move_along_scale(note, steps):
    """Move a MIDI note `steps` notes up (or down, if negative) the C major scale.

    Example: E4 (64) moved -3 steps: E is scale note 2 (C=0 D=1 E=2), 2 - 3 = -1,
    which is B in the octave below, so the result is B3 (59).
    A note outside the scale (a sharp) moves with the scale note below it and keeps its sharp.
    """
    octave, semitone = divmod(note, 12)          # C4 = 60 -> octave 5, semitone 0
    sharp = 0
    if semitone not in C_MAJOR:                   # e.g. C# (1): treat it as C plus a sharp
        semitone -= 1
        sharp = 1
    degree = C_MAJOR.index(semitone) + steps      # which scale note we land on
    octave += degree // 7                         # wrap into the octave above or below
    degree %= 7
    return octave * 12 + C_MAJOR[degree] + sharp


def move_to_key(note, key):
    """Move a MIDI note from C major to the key: the same shift in semitones for every note."""
    return note + KEY_OFFSET[key]


def follow_progression(notes, is_drums):
    """Lay a pattern out over the 4-bar progression.

    `notes` is a list of (start_beat, length_beats, pitch, velocity).
    Returns the 4-bar version, every pitched note moved to its bar's chord.
    """
    last_start = max(start for start, _, _, _ in notes)
    pattern_bars = 1 if last_start < 4 else (2 if last_start < 8 else 4)
    out = []
    for bar, (chord, steps) in enumerate(PROGRESSION):
        source_bar = bar % pattern_bars           # which bar of the pattern plays here
        for start, length, pitch, vel in notes:
            if int(start // BEATS_PER_BAR) != source_bar:
                continue
            new_start = bar * BEATS_PER_BAR + (start - source_bar * BEATS_PER_BAR)
            new_pitch = pitch if is_drums else move_along_scale(pitch, steps)
            out.append((new_start, length, new_pitch, vel))
    return out


def note_name(note):
    return ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][note % 12] + str(note // 12 - 1)


# ---------------------------------------------------------------------------
# Reading and writing MIDI files (plumbing: only note on/off and track names).
# ---------------------------------------------------------------------------

def read_varlen(data, i):
    value = 0
    while True:
        byte = data[i]
        i += 1
        value = (value << 7) | (byte & 0x7F)
        if byte < 0x80:
            return value, i


def write_varlen(value):
    out = [value & 0x7F]
    value >>= 7
    while value:
        out.insert(0, (value & 0x7F) | 0x80)
        value >>= 7
    return bytes(out)


def read_midi(path):
    """Returns (ticks_per_beat, tracks); each track is {name, channel, notes}."""
    data = open(path, "rb").read()
    track_count, ticks_per_beat = struct.unpack(">xxHH", data[8:14])
    pos = 8 + struct.unpack(">I", data[4:8])[0]
    tracks = []
    for _ in range(track_count):
        end = pos + 8 + struct.unpack(">I", data[pos + 4:pos + 8])[0]
        i, tick, status = pos + 8, 0, 0
        name, channel, held, notes = "", 0, {}, []
        while i < end:
            delta, i = read_varlen(data, i)
            tick += delta
            if data[i] == 0xFF:                               # meta event (track name, tempo...)
                kind = data[i + 1]
                length, j = read_varlen(data, i + 2)
                if kind == 0x03 and not name:
                    name = data[j:j + length].decode("latin1")
                i = j + length
                continue
            if data[i] in (0xF0, 0xF7):                       # system exclusive: skip
                length, j = read_varlen(data, i + 1)
                i = j + length
                continue
            if data[i] & 0x80:                                # new status byte (else running status)
                status = data[i]
                i += 1
            kind, chan = status & 0xF0, status & 0x0F
            if kind in (0xC0, 0xD0):                          # one data byte: skip
                i += 1
                continue
            pitch, vel = data[i], data[i + 1]
            i += 2
            if kind == 0x90 and vel > 0:                      # note on
                held[pitch] = (tick, vel)
                channel = chan
            elif kind in (0x80, 0x90) and pitch in held:      # note off
                start, v = held.pop(pitch)
                notes.append((start / ticks_per_beat, (tick - start) / ticks_per_beat, pitch, v))
        tracks.append({"name": name, "channel": channel, "notes": sorted(notes)})
        pos = end
    return ticks_per_beat, tracks


def write_midi(path, ticks_per_beat, tracks):
    chunks = b""
    for track in tracks:
        name = track["name"].encode("latin1")
        events = [(0, 0, b"\xFF\x03" + write_varlen(len(name)) + name)]
        for start, length, pitch, vel in track["notes"]:
            on, off = int(start * ticks_per_beat), int((start + length) * ticks_per_beat)
            events.append((on, 1, bytes([0x90 | track["channel"], pitch, vel])))
            events.append((off, 0, bytes([0x80 | track["channel"], pitch, 0])))
        events.append((len(PROGRESSION) * BEATS_PER_BAR * ticks_per_beat, 2, b"\xFF\x2F\x00"))
        body, last = b"", 0
        for tick, _, msg in sorted(events):
            body += write_varlen(tick - last) + msg
            last = tick
        chunks += b"MTrk" + struct.pack(">I", len(body)) + body
    with open(path, "wb") as f:
        f.write(b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), ticks_per_beat) + chunks)


# ---------------------------------------------------------------------------
# Main: read, transform, print, write.
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 3 or sys.argv[2].upper() not in KEY_OFFSET:
        print("usage: python tools/transpose_midi.py <file.mid> <key: C D E F G A B>")
        return
    path, key = sys.argv[1], sys.argv[2].upper()
    ticks_per_beat, tracks = read_midi(path)
    out_tracks = []
    for track in tracks:
        if not track["notes"]:
            continue
        is_drums = track["channel"] == 9                      # MIDI channel 10
        notes = follow_progression(track["notes"], is_drums)
        if not is_drums:
            notes = [(s, l, move_to_key(p, key), v) for s, l, p, v in notes]
        out_tracks.append({"name": track["name"], "channel": track["channel"], "notes": notes})

        print(f"\n{track['name']}  ({'drums, not moved' if is_drums else key + ' major'})")
        for bar, (chord, _) in enumerate(PROGRESSION):
            in_bar = [p for s, _, p, _ in notes if int(s // BEATS_PER_BAR) == bar]
            print(f"  bar {bar + 1}  {chord:<3} " + " ".join(note_name(p) for p in in_bar))

    out_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "midi_preview")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{os.path.splitext(os.path.basename(path))[0]}_{key}_major.mid")
    write_midi(out_path, ticks_per_beat, out_tracks)
    print(f"\nwrote {out_path}")


if __name__ == "__main__":
    main()
