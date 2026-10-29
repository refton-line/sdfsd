#!/usr/bin/env python3
"""Renders the interface sounds into assets/sounds/*.wav (48 kHz, mono, 16-bit PCM).
Everything is synthesised here from damped resonances, soft tones and filtered noise; no samples
or third-party audio. Deterministic: the noise is seeded. Usage: python3 scripts/render-sounds.py [DIR]
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 48000
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'assets' / 'sounds'

# Pitches of the tonal cues: one key (E major), so every cue sits with the others.
E5, GS5, B5, E6 = 659.26, 830.61, 987.77, 1318.51


def mix(dst, src, at=0.0, gain=1.0):
    start = int(round(at * SR))
    if len(dst) < start + len(src):
        dst.extend([0.0] * (start + len(src) - len(dst)))
    for i, v in enumerate(src):
        dst[start + i] += v * gain
    return dst


def scaled(sig, gain):
    return [v * gain for v in sig]


def mode(freq, tau, amp=1.0, attack=0.0004):
    """One damped resonance: what a struck hard object rings with."""
    w = 2 * math.pi * freq / SR
    return [amp * min(1.0, i / (attack * SR)) * math.exp(-i / (tau * SR)) * math.sin(w * i)
            for i in range(int(tau * 8 * SR))]


def tone(freq, tau, amp=1.0, attack=0.004, partials=((1, 1.0), (2, 0.2), (3, 0.05))):
    """A soft note: a few harmonics after a short attack; the upper ones die away first."""
    out = []
    for i in range(int(tau * 7 * SR)):
        t = i / SR
        v = sum(g * math.exp(-t * k / tau) * math.sin(2 * math.pi * freq * k * t) for k, g in partials)
        out.append(amp * min(1.0, t / attack) * v)
    return out


def noise(tau, seed, amp=1.0):
    rnd = random.Random(seed)
    return [amp * rnd.uniform(-1.0, 1.0) * math.exp(-i / (tau * SR)) for i in range(int(tau * 8 * SR))]


def biquad(sig, kind, f0, q=0.707):
    w = 2 * math.pi * f0 / SR
    c, s = math.cos(w), math.sin(w)
    alpha = s / (2 * q)
    if kind == 'bp':
        b = (alpha, 0.0, -alpha)
    elif kind == 'hp':
        b = ((1 + c) / 2, -(1 + c), (1 + c) / 2)
    else:
        b = ((1 - c) / 2, 1 - c, (1 - c) / 2)
    a0 = 1 + alpha
    b0, b1, b2 = (x / a0 for x in b)
    a1, a2 = -2 * c / a0, (1 - alpha) / a0
    out, x1, x2, y1, y2 = [], 0.0, 0.0, 0.0, 0.0
    for x in sig:
        y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x, y1, y
        out.append(y)
    return out


def tick(freq, seed, amp=1.0):
    """A small hard click: band-passed noise for the edge, two resonances for the body."""
    s = scaled(biquad(noise(0.0012, seed), 'bp', freq * 1.9, 1.3), 1.8)
    mix(s, mode(freq, 0.007, 0.55))
    mix(s, mode(freq * 2.13, 0.0028, 0.25))
    return scaled(s, amp)


def clack(detune, gap, seed, weight=1.0):
    """Teeth meeting: a dry broadband snap, bony resonances, a hollow knock from the skull and a
    second, weaker contact a few milliseconds later as the jaw settles."""
    def contact(amp, shift, seed):
        s = scaled(biquad(noise(0.0009, seed), 'hp', 1500), 1.4)
        for f, tau, a in ((1080, 0.016, 0.55), (1870, 0.011, 0.5), (2960, 0.007, 0.4),
                          (4410, 0.004, 0.3), (6100, 0.0025, 0.2)):
            mix(s, mode(f * detune * shift, tau, a))
        for f, tau, a in ((650, 0.014, 0.4), (190, 0.022, 0.45 * weight), (380, 0.012, 0.2)):
            mix(s, mode(f * detune, tau, a))
        return scaled(s, amp)
    return mix(contact(1.0, 1.0, seed), contact(0.42, 1.03, seed + 1), gap)


def thump(seed):
    return scaled(biquad(noise(0.006, seed), 'lp', 400), 0.6)


def finish(sig, peak_db):
    """No rumble or hiss, trimmed tail, short fades so nothing clicks, then a fixed peak level."""
    sig = biquad(biquad(sig, 'hp', 70), 'lp', 11000)
    peak = max(abs(v) for v in sig)
    end = max(i for i, v in enumerate(sig) if abs(v) > peak * 10 ** (-45 / 20)) + 1
    sig = sig[:end]
    fade_in, fade_out = int(0.0003 * SR), min(int(0.03 * SR), len(sig) // 6)
    for i in range(min(fade_in, len(sig))):
        sig[i] *= i / fade_in
    for i in range(min(fade_out, len(sig))):
        sig[-1 - i] *= i / fade_out
    gain = 10 ** (peak_db / 20) / max(abs(v) for v in sig)
    return scaled(sig, gain)


def cues():
    tap = mix(tick(1850, 1), mode(620, 0.006, 0.22))
    select = mix(mix(mode(1320, 0.012, 0.8), mode(2640, 0.005, 0.25)), mode(440, 0.010, 0.2))
    mix(select, scaled(biquad(noise(0.0012, 2), 'bp', 2600, 1.2), 1.2))
    step = mix(mode(2500, 0.004), scaled(biquad(noise(0.001, 3), 'bp', 4200, 1.3), 1.4))
    remove = mix(mix(mode(520, 0.022), mode(1040, 0.009, 0.3)), mode(260, 0.018, 0.35))
    mix(remove, scaled(biquad(noise(0.002, 4), 'bp', 1200, 1.0), 0.8))
    count = mix(tone(E5, 0.045, partials=((1, 1.0), (2, 0.22), (3, 0.06))),
                scaled(biquad(noise(0.0008, 5), 'bp', 3000, 1.2), 0.3))
    soft = ((1, 1.0), (2, 0.15))
    done = []
    for i, f in enumerate((E5, GS5, B5)):
        mix(done, tone(f, 0.13), i * 0.09)
    mix(done, tone(E6, 0.2, 0.7), 0.27)
    error = mix(tone(220.0, 0.045, partials=((1, 1.0), (2, 0.35), (3, 0.18))), thump(6))
    mix(error, tone(207.65, 0.06, 0.9, partials=((1, 1.0), (2, 0.35), (3, 0.18))), 0.12)
    mix(error, thump(7), 0.12)
    return {
        'tap': (tap, -17),
        'select': (select, -15),
        'switchOn': (mix(tick(1250, 8, 0.7), tick(1900, 9), 0.034), -14),
        'switchOff': (mix(tick(1900, 10, 0.85), tick(1250, 11, 0.75), 0.034), -15),
        'step': (step, -21),
        'count': (count, -12),
        'start': (mix(mix(tone(E5, 0.07), tone(B5, 0.11), 0.075), tone(E6, 0.08, 0.18), 0.075), -9),
        'stop': (mix(tone(B5, 0.06, 0.85, partials=soft), tone(E5, 0.10, partials=soft), 0.075), -10),
        'done': (done, -10),
        'confirm': (mix(tone(B5, 0.05, 0.8), tone(E6, 0.09), 0.06), -12),
        'remove': (remove, -14),
        'error': (error, -10),
        'jaw': (clack(1.0, 0.0042, 21), -6),
        'jaw2': (clack(0.94, 0.0031, 31, weight=0.9), -7),
    }


def write(path, sig):
    frames = b''.join(struct.pack('<h', max(-32767, min(32767, round(v * 32767)))) for v in sig)
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (sig, peak_db) in cues().items():
        sig = finish(sig, peak_db)
        write(OUT / f'{name}.wav', sig)
        print(f'{name:9s} {len(sig) / SR * 1000:6.1f} ms  peak {peak_db} dBFS')
    print(f'Sounds: {OUT}')
