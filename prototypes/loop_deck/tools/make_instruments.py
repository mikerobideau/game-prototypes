# Renders the synthwave instrument samples into instruments/<dir>/.
#
# Pitched voices get one sample every 3 semitones (C, Eb, Gb, A in each octave); the game
# re-pitches the nearest sample by up to 1.5 semitones for the notes in between, so every key
# works. Drum kits get one sample per drum (kick.wav, snare.wav ...), mapped from General MIDI
# drum notes by DRUM_FILES in loop_deck_data.gd. Any file can be replaced by a recording with
# the same name (mono or stereo WAV, any rate).
import math, os, random, shutil, struct, wave
from multiprocessing import Pool

DST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'instruments')
SR = 32000
TAU = 2 * math.pi
POINTS = {0: 'C', 3: 'Eb', 6: 'Gb', 9: 'A'}

# dir: (lowest MIDI note, highest MIDI note, seconds)
VOICES = {
    'saw_bass': (24, 57, 2.6),
    'pulse_bass': (24, 57, 2.6),
    'sub_bass': (24, 57, 2.6),
    'saw_lead': (57, 93, 2.6),
    'square_lead': (57, 93, 2.6),
    'pwm_lead': (57, 93, 2.6),
    'synth_pluck': (45, 93, 2.0),
    'brass': (45, 84, 2.6),
    'poly_pad': (33, 84, 2.9),
}
KITS = ['kit_gated', 'kit_analog']
DRUMS = ['kick', 'snare', 'clap', 'rim', 'hat_closed', 'hat_open', 'tom_low', 'tom_mid', 'tom_high', 'crash']


def note_name(m):
    return '%s%d' % (POINTS[m % 12], m // 12 - 1)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def blep(t, dt):
    if t < dt:
        t /= dt
        return t + t - t * t - 1
    if t > 1 - dt:
        t = (t - 1) / dt
        return t * t + t + t + 1
    return 0.0


class Saw:
    def __init__(self, f, phase=None):
        self.dt = f / SR
        self.t = random.random() if phase is None else phase

    def __call__(self, fm=1.0):
        dt = self.dt * fm
        v = 2 * self.t - 1 - blep(self.t, dt)
        self.t = (self.t + dt) % 1.0
        return v


class Pulse:
    def __init__(self, f):
        self.dt = f / SR
        self.t = 0.0

    def __call__(self, pw=0.5, fm=1.0):
        dt = self.dt * fm
        v = (1.0 if self.t < pw else -1.0) + blep(self.t, dt) - blep((self.t - pw) % 1.0, dt)
        self.t = (self.t + dt) % 1.0
        return v


class Lowpass:
    def __init__(self):
        self.a = self.b = 0.0

    def __call__(self, x, fc):
        g = 1 - math.exp(-TAU * min(max(fc, 20.0), SR * 0.45) / SR)
        self.a += g * (x - self.a)
        self.b += g * (self.a - self.b)
        return self.b


class Highpass:
    def __init__(self, fc):
        self.k = math.exp(-TAU * fc / SR)
        self.x = self.y = 0.0

    def __call__(self, x):
        self.y = self.k * (self.y + x - self.x)
        self.x = x
        return self.y


def attack(t, a):
    return min(1.0, t / a) if a > 0 else 1.0


def vibrato(t):
    return 1 + 0.005 * min(1.0, max(0.0, (t - 0.3) / 0.3)) * math.sin(TAU * 5.5 * t)


def pitched(voice, m, secs):
    random.seed(m * 31 + len(voice))
    f = hz(m)
    n = int(secs * SR)
    out = [0.0] * n
    if voice == 'saw_bass':
        s, lp = Saw(f, 0.0), Lowpass()
        for i in range(n):
            t = i / SR
            x = s() + 0.5 * math.sin(TAU * f * 0.5 * t)
            out[i] = attack(t, 0.003) * (0.8 + 0.2 * math.exp(-t * 6)) * lp(x, f * 1.5 + 2200 * math.exp(-t * 9))
    elif voice == 'pulse_bass':
        p, lp = Pulse(f), Lowpass()
        for i in range(n):
            t = i / SR
            out[i] = attack(t, 0.003) * (0.8 + 0.2 * math.exp(-t * 6)) * lp(p(0.3), f * 2 + 1400 * math.exp(-t * 7))
    elif voice == 'sub_bass':
        for i in range(n):
            t = i / SR
            ph = TAU * f * t
            out[i] = attack(t, 0.005) * math.tanh(1.6 * (math.sin(ph) + 0.25 * math.sin(2 * ph)))
    elif voice == 'saw_lead':
        a, b, lp = Saw(f * 2 ** (-8 / 1200)), Saw(f * 2 ** (8 / 1200)), Lowpass()
        for i in range(n):
            t = i / SR
            v = vibrato(t)
            out[i] = attack(t, 0.01) * lp(a(v) + b(v), 3600 + 1500 * math.exp(-t * 6))
    elif voice == 'square_lead':
        p, lp = Pulse(f), Lowpass()
        for i in range(n):
            t = i / SR
            out[i] = attack(t, 0.008) * lp(p(0.5, vibrato(t)), 3000)
    elif voice == 'pwm_lead':
        p, lp = Pulse(f), Lowpass()
        for i in range(n):
            t = i / SR
            pw = 0.5 + 0.32 * math.sin(TAU * 0.9 * t)
            out[i] = attack(t, 0.01) * lp(p(pw, vibrato(t)), 2800)
    elif voice == 'synth_pluck':
        s, p, lp = Saw(f), Pulse(f * 2 ** (6 / 1200)), Lowpass()
        for i in range(n):
            t = i / SR
            out[i] = attack(t, 0.002) * math.exp(-t * 3.2) * lp(s() + 0.6 * p(0.5), f + 4500 * math.exp(-t * 14))
    elif voice == 'brass':
        a, b, lp = Saw(f * 2 ** (-5 / 1200)), Saw(f * 2 ** (5 / 1200)), Lowpass()
        for i in range(n):
            t = i / SR
            fc = 500 + f * 1.5 + 2600 * (1 - math.exp(-t * 14)) * (0.6 + 0.4 * math.exp(-t * 3))
            out[i] = attack(t, 0.03) * lp(a() + b(), fc)
    elif voice == 'poly_pad':
        oscs = [Saw(f * 2 ** (c / 1200)) for c in (-14, -5, 5, 14)]
        lp = Lowpass()
        for i in range(n):
            t = i / SR
            x = sum(o() for o in oscs) + 0.5 * math.sin(TAU * f * 0.5 * t)
            out[i] = attack(t, 0.45) * lp(x, 1300 + 500 * math.sin(TAU * 0.3 * t))
    return out


def noise():
    return random.uniform(-1, 1)


def metal(t, freqs):
    return sum(1.0 if (t * fr) % 1.0 < 0.5 else -1.0 for fr in freqs) / len(freqs)


HAT_FREQS = [205.3, 304.4, 369.6, 522.7, 540.0, 800.0]


def drum(kit, piece):
    random.seed(kit + piece)
    gated = kit == 'kit_gated'
    secs = {'kick': 0.9, 'snare': 0.7, 'clap': 0.6, 'rim': 0.15, 'hat_closed': 0.15, 'hat_open': 0.6, 'tom_low': 0.9, 'tom_mid': 0.8, 'tom_high': 0.7, 'crash': 2.6}[piece]
    n = int(secs * SR)
    out = [0.0] * n
    hp = Highpass(6000 if gated else 7000)
    hp2 = Highpass(1200)
    lp = Lowpass()
    gate = 0.32
    ph = 0.0
    for i in range(n):
        t = i / SR
        if piece == 'kick':
            f = (55 + 90 * math.exp(-t * 40)) if gated else (46 + 120 * math.exp(-t * 32))
            ph += TAU * f / SR
            dec = 9.0 if gated else 4.5
            out[i] = math.sin(ph) * math.exp(-t * dec) + noise() * 0.25 * math.exp(-t * 300)
        elif piece in ('snare', 'clap'):
            if piece == 'snare':
                body = (math.sin(TAU * 185 * t) + 0.6 * math.sin(TAU * 330 * t)) * math.exp(-t * 22)
                snap = hp2(noise()) * math.exp(-t * 16)
                x = 0.7 * body + 0.8 * snap
            else:
                bursts = sum(math.exp(-(t - d) * 120) for d in (0.0, 0.011, 0.022) if t >= d)
                x = lp(hp2(noise()), 2400) * (bursts + 0.6 * math.exp(-t * 14)) * 2.2
            if gated:
                # Gated reverb: a dense noise tail held flat, then cut short.
                tail = lp(noise(), 3800) * 0.45 * (1.0 if t < gate else max(0.0, 1 - (t - gate) / 0.02))
                x += tail * min(1.0, t / 0.01)
            out[i] = x
        elif piece == 'rim':
            out[i] = (math.sin(TAU * 1700 * t) + 0.5 * hp2(noise())) * math.exp(-t * 70)
        elif piece in ('hat_closed', 'hat_open'):
            x = hp(0.6 * metal(t, HAT_FREQS) + 0.6 * noise())
            out[i] = x * math.exp(-t * (55 if piece == 'hat_closed' else 7))
        elif piece.startswith('tom'):
            base = {'tom_low': 95, 'tom_mid': 135, 'tom_high': 185}[piece]
            f = base * (1 + 0.6 * math.exp(-t * 18))
            ph += TAU * f / SR
            x = math.sin(ph) * math.exp(-t * (5 if not gated else 7))
            if gated:
                x += lp(noise(), 3000) * 0.25 * (1.0 if t < gate else max(0.0, 1 - (t - gate) / 0.02))
            out[i] = x
        elif piece == 'crash':
            out[i] = hp(0.5 * metal(t, [f * 1.37 for f in HAT_FREQS]) + noise()) * math.exp(-t * 2.0) * min(1.0, t / 0.002)
    return out


def finish(data, path):
    peak = max(abs(v) for v in data) or 1.0
    fade = min(int(0.03 * SR), len(data) // 4)
    for i in range(fade):
        data[len(data) - 1 - i] *= i / fade
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(v / peak * 0.85 * 32767)) for v in data))
    return path


def job(args):
    kind, a, b, c = args
    if kind == 'voice':
        return finish(pitched(a, b, c), os.path.join(DST, a, note_name(b) + '.wav'))
    return finish(drum(a, b), os.path.join(DST, a, b + '.wav'))


if __name__ == '__main__':
    jobs = []
    for voice, (lo, hi, secs) in VOICES.items():
        shutil.rmtree(os.path.join(DST, voice), ignore_errors=True)
        os.makedirs(os.path.join(DST, voice))
        jobs += [('voice', voice, m, secs) for m in range(lo, hi + 1) if m % 12 in POINTS]
    for kit in KITS:
        shutil.rmtree(os.path.join(DST, kit), ignore_errors=True)
        os.makedirs(os.path.join(DST, kit))
        jobs += [('drum', kit, p, 0) for p in DRUMS]
    with Pool() as p:
        done = p.map(job, jobs)
    print(len(done), 'samples written to', DST)
