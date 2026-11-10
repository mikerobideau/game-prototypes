# Renders one sample per note for each pitched instrument into instruments/<dir>/<note>.wav.
#
# Only A minor pentatonic notes (A C D E G) are made, across each instrument's range.
# The game builds loops by placing these samples on the 2-bar timeline, so any file here can
# be swapped for a recorded sample with the same name (mono or stereo WAV, any rate).
import math, os, random, struct, wave
from multiprocessing import Pool

DST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'instruments')
SR = 32000
TAU = 2 * math.pi
PENTA = [0, 3, 5, 7, 10]
NAMES = {9: 'A', 0: 'C', 2: 'D', 4: 'E', 7: 'G'}

# dir: (lowest MIDI note, highest MIDI note, seconds)
VOICES = {
    'sine': (33, 81, 2.6),
    'saw': (33, 81, 2.6),
    'square': (57, 88, 2.6),
    'pluck': (33, 81, 2.6),
    'pad': (45, 76, 2.8),
    'epiano': (45, 88, 2.8),
    'organ': (45, 88, 2.6),
    'flute': (57, 88, 2.6),
    'bell': (55, 88, 3.0),
}


def note_name(m):
    return '%s%d' % (NAMES[m % 12], m // 12 - 1)


def notes(lo, hi):
    return [m for m in range(lo, hi + 1) if (m - 57) % 12 in PENTA]


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
    def __init__(self, f):
        self.dt = f / SR
        self.t = random.random()

    def __call__(self):
        v = 2 * self.t - 1 - blep(self.t, self.dt)
        self.t = (self.t + self.dt) % 1.0
        return v


class Square:
    def __init__(self, f):
        self.dt = f / SR
        self.t = 0.0

    def __call__(self):
        v = (1.0 if self.t < 0.5 else -1.0) + blep(self.t, self.dt) - blep((self.t + 0.5) % 1.0, self.dt)
        self.t = (self.t + self.dt) % 1.0
        return v


class Lowpass:
    def __init__(self):
        self.a = self.b = 0.0

    def __call__(self, x, fc):
        g = 1 - math.exp(-TAU * min(fc, SR * 0.45) / SR)
        self.a += g * (x - self.a)
        self.b += g * (self.a - self.b)
        return self.b


def attack(t, a):
    return min(1.0, t / a)


def render(voice, m, secs):
    random.seed(m * 31 + len(voice))
    f = hz(m)
    n = int(secs * SR)
    out = [0.0] * n
    if voice == 'sine':
        for i in range(n):
            t = i / SR
            ph = TAU * f * t
            env = attack(t, 0.008) * (0.75 + 0.25 * math.exp(-t * 4))
            out[i] = env * (math.sin(ph) + 0.18 * math.sin(2 * ph) + 0.06 * math.sin(3 * ph))
    elif voice == 'saw':
        a, b, lp = Saw(f * 2 ** (-7 / 1200)), Saw(f * 2 ** (7 / 1200)), Lowpass()
        for i in range(n):
            t = i / SR
            fc = f * 2 + 3200 * math.exp(-t * 5)
            out[i] = attack(t, 0.005) * (0.7 + 0.3 * math.exp(-t * 3)) * lp(a() + b(), fc)
    elif voice == 'square':
        sq, lp = Square(f), Lowpass()
        for i in range(n):
            t = i / SR
            out[i] = attack(t, 0.006) * (0.75 + 0.25 * math.exp(-t * 5)) * lp(sq(), 2600)
    elif voice == 'pluck':
        # Karplus-Strong string: a noise burst fed back through a short, slightly lossy delay.
        delay = SR / f - 0.5
        size = int(delay) + 3
        buf = [random.uniform(-1, 1) for _ in range(size)]
        for _ in range(2):
            buf = [(buf[j] + buf[j - 1]) * 0.5 for j in range(size)]
        t60 = 2.4 - (m - 33) / 48 * 1.3
        loss = 10 ** (-3 / (t60 * f))
        prev = 0.0
        for i in range(n):
            pos = i - delay
            k = math.floor(pos)
            fr = pos - k
            y = buf[k % size] * (1 - fr) + buf[(k + 1) % size] * fr
            buf[i % size] = loss * 0.5 * (y + prev)
            prev = y
            out[i] = y
    elif voice == 'pad':
        oscs = [Saw(f * 2 ** (c / 1200)) for c in (-11, 0, 12)]
        lp = Lowpass()
        for i in range(n):
            t = i / SR
            x = sum(o() for o in oscs) + 0.6 * math.sin(TAU * f * 0.5 * t)
            fc = 900 + 500 * math.sin(TAU * 0.35 * t)
            out[i] = attack(t, 0.35) * lp(x, fc)
    elif voice == 'epiano':
        for i in range(n):
            t = i / SR
            idx = 1.6 * math.exp(-t * 3.0) + 0.25
            body = math.sin(TAU * f * t + idx * math.sin(TAU * f * t))
            tine = 0.25 * math.exp(-t * 18) * math.sin(TAU * f * 7.0 * t)
            out[i] = attack(t, 0.002) * math.exp(-t * (0.9 + f / 900)) * (body + tine)
    elif voice == 'organ':
        bars = [(0.5, 0.5), (1, 1.0), (2, 0.6), (3, 0.45), (4, 0.3), (6, 0.18), (8, 0.14)]
        for i in range(n):
            t = i / SR
            x = sum(a * math.sin(TAU * f * h * t) for h, a in bars if f * h < SR * 0.45)
            click = random.uniform(-1, 1) * 0.3 * math.exp(-t * 400)
            out[i] = attack(t, 0.008) * (1 + 0.07 * math.sin(TAU * 6.2 * t)) * x + click
    elif voice == 'flute':
        lp = Lowpass()
        ph = 0.0
        for i in range(n):
            t = i / SR
            vib = 1 + 0.004 * min(1.0, max(0.0, (t - 0.25) / 0.3)) * math.sin(TAU * 5.2 * t)
            ph += TAU * f * vib / SR
            env = attack(t, 0.07)
            breath = lp(random.uniform(-1, 1), f * 3) * (0.35 + 0.5 * math.exp(-t * 12))
            out[i] = env * (math.sin(ph) + 0.22 * math.sin(2 * ph) + 0.06 * math.sin(3 * ph) + breath)
    elif voice == 'bell':
        for i in range(n):
            t = i / SR
            idx = 1.2 * math.exp(-t * 3.0) + 0.2
            body = math.sin(TAU * f * t + idx * math.sin(TAU * f * t)) * math.exp(-t * 1.3)
            ring = 0.35 * math.sin(TAU * f * 2.76 * t) * math.exp(-t * 4.0) + 0.15 * math.sin(TAU * f * 5.4 * t) * math.exp(-t * 9.0)
            out[i] = attack(t, 0.001) * (body + ring)
    peak = max(abs(v) for v in out) or 1.0
    fade = int(0.04 * SR)
    for i in range(fade):
        out[n - 1 - i] *= i / fade
    return [v / peak * 0.85 for v in out]


def job(args):
    voice, m, secs = args
    data = render(voice, m, secs)
    path = os.path.join(DST, voice, note_name(m) + '.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(v * 32767)) for v in data))
    return path


if __name__ == '__main__':
    jobs = []
    for voice, (lo, hi, secs) in VOICES.items():
        os.makedirs(os.path.join(DST, voice), exist_ok=True)
        jobs += [(voice, m, secs) for m in notes(lo, hi)]
    with Pool() as p:
        done = p.map(job, jobs)
    print(len(done), 'samples written to', DST)
