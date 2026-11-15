"""Original 16-bar scores, arcade Foley, ambience and CC0 sample processing.
Regeneration needs numpy and ffmpeg; players and exports use the checked-in
Ogg files, with no runtime dependencies. CC0 sources live in tools/audio_sources."""
from pathlib import Path
import json
import re
import numpy as np
import subprocess

RATE = 44100
ROOT = Path(__file__).resolve().parent
SRC = ROOT / "audio_sources"
OUT = ROOT.parent / "godot/assets/audio"
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(240115)
REPORT = {}
PEAK_LIMIT = 10 ** (-1 / 20)  # keep every decoded file under -1 dBFS

def voice(midi, duration, kind="pluck"):
    t = np.arange(int(RATE * duration)) / RATE
    phase = 2 * np.pi * (440 * 2 ** ((midi - 69) / 12)) * t
    if kind == "bell":
        tone = np.sin(phase) + .32*np.sin(phase*2.01)*np.exp(-t*7) + .15*np.sin(phase*3.99)*np.exp(-t*12)
        env = np.exp(-t*3.5)
    elif kind == "flute":
        tone = np.sin(phase + .025*np.sin(2*np.pi*5*t)) + .15*np.sin(phase*2)
        env = np.exp(-t*1.3)
    elif kind == "bass":
        tone = np.sin(phase) + .22*np.sin(phase*2) + .08*np.sin(phase*3)
        env = np.exp(-t*3)
    elif kind == "keys":
        tone = np.sin(phase + .6*np.sin(phase*2)*np.exp(-t*6)) + .1*np.sin(phase*3)
        env = np.exp(-t*2.7)
    else:
        tone = np.sin(phase) + .3*np.sin(phase*2) + .14*np.sin(phase*3) + .05*np.sin(phase*5)
        env = np.exp(-t*5)
    return tone * env * np.minimum(t/.009, 1) * np.clip((duration-t)/.06, 0, 1)

def drum(kind):
    t = np.arange(int(RATE*.24))/RATE
    noise = RNG.uniform(-1, 1, len(t))
    if kind == "kick":
        return np.sin(2*np.pi*(52*t + 6*(1-np.exp(-t*35))))*np.exp(-t*20)
    if kind == "snare":
        return (.65*noise + .35*np.sin(2*np.pi*185*t))*np.exp(-t*30)
    if kind == "wood":
        return (np.sin(2*np.pi*830*t) + .4*np.sin(2*np.pi*1270*t))*np.exp(-t*75)
    return (noise - np.roll(noise, 1))*np.exp(-t*90)*.45

def place(mix, sample, seconds, gain, pan=0, wrap=False):
    indices = np.arange(len(sample)) + round(seconds*RATE)
    if sample.ndim == 1:
        values = sample[:, None]*gain*np.array([np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)])
    else:
        values = sample*gain
    if wrap:
        np.add.at(mix, indices % len(mix), values)
    else:
        valid = indices < len(mix)
        mix[indices[valid]] += values[valid]

def loudness(path):
    result = subprocess.run(["ffmpeg", "-nostats", "-i", str(path), "-af", "ebur128", "-f", "null", "-"],
                            capture_output=True, text=True)
    found = re.findall(r"I:\s+(-?\d+\.\d) LUFS", result.stderr)
    return float(found[-1]) if found else None

def save(name, mix, peak=.8, quality=4, gain=None):
    """Writes Ogg Vorbis, checks the decoded file and returns the gain used."""
    mix = np.asarray(mix, dtype=float)
    if gain is None:
        gain = peak / max(.001, np.max(np.abs(mix)))
    mix = mix * gain
    path = OUT / f"{name}.ogg"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", str(mix.shape[1]),
                    "-i", "pipe:0", "-c:a", "libvorbis", "-q:a", str(quality), str(path)],
                   input=mix.astype("<f4").tobytes(), check=True)
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "pipe:1"])
    decoded = np.frombuffer(raw, dtype="<f4")
    assert np.isfinite(decoded).all()
    assert np.max(np.abs(decoded)) < PEAK_LIMIT, name
    seconds = len(mix) / RATE
    REPORT[name] = {"seconds": round(seconds, 3), "peak": round(float(np.max(np.abs(decoded))), 4),
                    "rms": round(float(np.sqrt(np.mean(decoded**2))), 4), "bytes": path.stat().st_size}
    if seconds >= 3:
        REPORT[name]["lufs"] = loudness(path)
    return gain

def sample(relative, seconds=None, floor_db=-50, release=.04):
    """Trimmed, peak-normalised stereo copy of a CC0 source recording."""
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(SRC / relative), "-f", "f32le",
                                   "-ac", "2", "-ar", str(RATE), "pipe:1"])
    return _trim(np.frombuffer(raw, dtype="<f4").reshape(-1, 2).astype(float), seconds, floor_db, release)

def _trim(x, seconds=None, floor_db=-50, release=.04):
    level = np.abs(x).max(axis=1)
    loud = np.nonzero(level > level.max() * 10 ** (floor_db / 20))[0]
    x = x[loud[0]:loud[-1] + 1]
    if seconds:
        x = x[:round(seconds * RATE)]
    x = x / max(np.abs(x).max(), 1e-6)
    attack = min(len(x) // 4, round(RATE * .004))
    if attack:
        x[:attack] *= np.linspace(0, 1, attack)[:, None]
    fade = min(len(x) // 2, round(RATE * release))
    x[-fade:] *= np.linspace(1, 0, fade)[:, None]
    return x

def score(theme, root, bpm, lead):
    """Writes a melodic stem and a drums/hat stem that sum to the full arrangement."""
    beat = 60/bpm
    shape = (round(64*beat*RATE), 2)
    base, drive = np.zeros(shape), np.zeros(shape)
    phrases = [[0,4,7,9,7,4,2,4], [5,9,12,9,7,5,4,2], [9,12,14,12,9,7,4,7], [7,11,14,12,11,7,2,-1],
               [12,7,9,7,4,2,0,4], [5,7,9,12,9,5,4,2], [9,7,4,7,12,14,12,9], [7,4,2,-1,2,7,4,0]]
    chords = [(0,4,7), (5,9,12), (9,12,16), (7,11,14)]
    for bar in range(16):
        chord = chords[bar % 4]
        for step, note in enumerate(phrases[bar % 8]):
            octave = 12 if bar >= 8 and step in (2,6) else 0
            place(base, voice(root+12+note+octave, beat*.75, lead), (bar*4+step*.5)*beat, .24, -.15, True)
            if step % 2:
                place(base, voice(root+chord[(step//2)%3], beat*.7, "keys"), (bar*4+step*.5)*beat, .11, .48, True)
        for b in (0,1.5,2,3.5):
            note = root-12+(chord[0] if b < 2 else chord[2]-12)
            place(base, voice(note, beat*.85, "bass"), (bar*4+b)*beat, .35, 0, True)
        for b in (0,2):
            for note in chord:
                place(base, voice(root+note, beat*1.8, "keys"), (bar*4+b)*beat, .075, -.5, True)
            place(drive, drum("kick"), (bar*4+b)*beat, .3, 0, True)
        for b in (1,3):
            place(drive, drum("wood" if theme == "jungle" else "snare"), (bar*4+b)*beat, .17, .1, True)
        for b in np.arange(0,4,.5):
            place(drive, drum("hat"), (bar*4+b)*beat, .07 if b % 1 else .11, -.3, True)
    # Circular room taps preserve tails across the loop boundary.
    for stem in (base, drive):
        stem += np.roll(stem[:, ::-1], round(beat*.75*RATE), axis=0)*.14
        stem += np.roll(stem, round(beat*1.5*RATE), axis=0)*.07
    gain = .72 / np.max(np.abs(base + drive))
    save(f"music_{theme}", base, quality=4, gain=gain)
    save(f"music_{theme}_drive", drive, quality=4, gain=gain)

def jingle(name, notes, spacing, shift=0):
    mix = np.zeros((round(JINGLE_SECONDS[name]*RATE), 2))
    for i, note in enumerate(notes):
        when = i*spacing
        place(mix, voice(note+shift, .5, "bell"), when, .6, (i%2-.5)*.5)
        if name == "finish":
            place(mix, voice(note+shift-12, .6, "keys"), when, .4)
    return mix

JINGLE_SECONDS = {"pickup": 1., "go": .9, "lap": 1.1, "finish": 2.2, "countdown": .5, "warning": .6,
                  "final_lap": 1.5, "overtake": .7}

def finish_effect(mix):
    mix[:120] *= np.linspace(0,1,120)[:,None]
    mix[-120:] *= np.linspace(1,0,120)[:,None]
    return mix

def whoosh(duration, rise_rate):
    mix = np.zeros((round(duration*RATE), 2))
    t = np.arange(len(mix))/RATE
    smooth = np.convolve(RNG.normal(0,.3,len(t)), np.ones(6)/6, mode="same")
    rise = np.sin(2*np.pi*(170*t + rise_rate*t**2))*.22
    place(mix, (smooth*1.8+rise)*np.sin(np.pi*t/duration)**1.5, 0, 1)
    return mix

def impact_variant(kind, variant):
    mix = np.zeros((round(.75*RATE), 2))
    t = np.arange(len(mix))/RATE
    if kind == "crash":
        noise = RNG.normal(0, .5, len(t))
        thump = np.sin(2*np.pi*((58 + 4*variant)*t + 2*(1-np.exp(-t*25))))*np.exp(-t*12)
        place(mix, thump*.5 + noise*np.exp(-t*37)*.25, 0, 1)
        place(mix, sample(f"kenney_impact/impactWood_heavy_00{variant}.ogg", .6), 0, .9)
        place(mix, sample(f"kenney_impact/impactSoft_heavy_00{variant % 3}.ogg", .5), 0, .75)
        place(mix, drum("wood"), .07 + .012*variant, .12, .5)
    else:
        bonk = np.sin(2*np.pi*(520*t - 180*(1-np.exp(-t*14))*1.0))*np.exp(-t*16)
        place(mix, bonk*.45, 0, 1)
        place(mix, sample(f"kenney_impact/impactPlank_medium_00{variant}.ogg", .5), 0, .85)
        place(mix, sample(f"kenney_impact/impactWood_light_00{variant}.ogg", .35), .015, .6)
        place(mix, drum("wood"), .11, .1, -.4)
    return finish_effect(mix)

def effects():
    jingles = {"pickup": ([76,80,83,88], .12), "go": ([62,69,74], .12), "lap": ([74,78,81,86], .12),
               "finish": ([62,66,69,74,73,74,78,81], .18), "countdown": ([81], .12), "warning": ([78,74], .12),
               "final_lap": ([69,74,78,81,86], .13), "overtake": ([81,88], .1)}
    for name, (notes, spacing) in jingles.items():
        if name == "pickup":
            for variant, shift in enumerate((0, 2, -3)):
                save(f"pickup_{variant}", finish_effect(jingle(name, notes, spacing, shift)))
        else:
            save(name, finish_effect(jingle(name, notes, spacing)))
    for variant in range(3):
        save(f"throw_{variant}", finish_effect(whoosh(.3, 650 + 120*variant)))
    save("speed", finish_effect(whoosh(.45, 650)))
    for variant in range(2):
        mix = whoosh(.8, 650 + 90*variant)
        for i, note in enumerate([50,57,62,69]):
            place(mix, voice(note + 2*variant, .25), i*.11, .35, (i-1.5)*.2)
        save(f"boost_{variant}", finish_effect(mix))
    for variant in range(4):
        save(f"crash_{variant}", impact_variant("crash", variant))
    for variant in range(3):
        save(f"coconut_{variant}", impact_variant("coconut", variant))

def dogs():
    """Six bark variants, plus a howl, from CC0 recordings. Pitch is shifted per breed at runtime."""
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(SRC / "oga/dog_barking_mono.wav"),
                                   "-f", "f32le", "-ac", "1", "-ar", str(RATE), "pipe:1"])
    mono = np.frombuffer(raw, dtype="<f4").astype(float)
    hop = round(RATE*.01)
    frames = len(mono) // hop
    level = np.sqrt(np.mean(mono[:frames*hop].reshape(frames, hop)**2, axis=1) + 1e-12)
    active = 20*np.log10(level / level.max()) > -34
    spans, start, last = [], None, 0
    for i, on in enumerate(active):
        if on:
            start = i if start is None else start
            last = i
        elif start is not None and (i - last)*.01 > .12:
            spans.append((start, last + 1))
            start = None
    if start is not None:
        spans.append((start, last + 1))
    assert len(spans) == 4, spans
    barks = []
    for a, b in spans:
        chunk = mono[max(0, a*hop - round(RATE*.015)):(b*hop + round(RATE*.05))]
        barks.append(_trim(np.stack([chunk, chunk], axis=1), release=.05))
    barks.append(sample("oga/barking_01.ogg"))
    barks.append(sample("oga/barking_02.ogg"))
    for i, bark in enumerate(barks):
        save(f"dog_bark_{i}", bark, peak=.8)
    save("dog_howl", sample("oga/howl.ogg", release=.08), peak=.7)

def ui_sounds():
    ui = {"ui_hover": ("tick_001", .35), "ui_select": ("select_001", .6), "ui_confirm": ("confirmation_001", .7),
          "ui_back": ("back_001", .6), "ui_toggle": ("toggle_001", .55), "ui_open": ("open_001", .6),
          "ui_close": ("close_001", .6)}
    for name, (source, peak) in ui.items():
        save(name, sample(f"kenney_interface/{source}.ogg", 1.0), peak=peak)

def spectral(seconds, low, high, slope=0.0):
    """Band-limited stereo noise that loops without a seam, because it is built in the frequency domain."""
    n = round(seconds*RATE)
    freqs = np.maximum(np.fft.rfftfreq(n, 1/RATE), 1)
    response = 1/(1 + (low/freqs)**4) / (1 + (freqs/high)**4) * (freqs/1000)**slope
    out = np.stack([np.fft.irfft(np.fft.rfft(RNG.normal(size=n))*response, n) for _ in range(2)], axis=1)
    return out / out.std()

def cycles(seconds, count, phase=0.0):
    t = np.arange(round(seconds*RATE))/RATE
    return np.sin(2*np.pi*count*t/seconds + phase)[:, None]

def foley():
    length = 4.0
    glide = spectral(length, 450, 6500, -.4) * (1 + .16*cycles(length, 3) + .08*cycles(length, 7, 1.3))
    save("runner_glide", glide, peak=.5, quality=2)
    scrape = spectral(length, 1800, 10000) * (.78 + .22*cycles(length, 36)) * (1 + .15*cycles(length, 2))
    save("runner_scrape", scrape, peak=.5, quality=2)
    n = round(length*RATE)
    crunch = np.zeros((n, 2))
    t = np.arange(round(.04*RATE))/RATE
    for _ in range(int(length*48)):
        burst = RNG.normal(0, 1, len(t))*np.exp(-t*170)
        place(crunch, burst, RNG.uniform(0, length), RNG.uniform(.3, 1), RNG.uniform(-.5, .5), True)
    spec = np.fft.rfft(crunch, axis=0)
    freqs = np.maximum(np.fft.rfftfreq(n, 1/RATE), 1)[:, None]
    crunch = np.fft.irfft(spec/(1 + (100/freqs)**4)/(1 + (freqs/3200)**4), n, axis=0)
    save("runner_rough", crunch, peak=.55, quality=2)
    pant_length, pant_cycles = 3.0, 10
    envelope = np.zeros((round(pant_length*RATE), 2))
    burst = np.sin(np.pi*np.arange(round(.2*RATE))/round(.2*RATE))**2
    for i in range(pant_cycles):
        place(envelope, burst, i*pant_length/pant_cycles + .02, RNG.uniform(.7, 1), 0, True)
    breath = spectral(pant_length, 800, 4800)*.75 + spectral(pant_length, 220, 700)*.35
    save("dog_pant", breath*envelope[:, :1], peak=.5, quality=2)

def chirp(start, end, duration):
    t = np.arange(round(duration*RATE))/RATE
    return np.sin(2*np.pi*(start*t + (end-start)*t**2/(2*duration)))*np.sin(np.pi*t/duration)**2*(1 + .25*np.sin(2*np.pi*28*t))

def ambience():
    length = 16.0
    t = np.arange(round(length*RATE))/RATE
    gust = np.clip(.6 + .25*cycles(length, 1, .4) + .15*cycles(length, 3, 2.1), 0, 1)
    wind = spectral(length, 80, 900, -.3)*gust + spectral(length, 1400, 2600)*.08*gust**3
    save("ambience_alpine", wind, peak=.5, quality=2)
    water = spectral(length, 300, 6000, -.2)*(.55 + .12*cycles(length, 5))
    insects = spectral(length, 3800, 9000)*.09*(1 + .5*cycles(length, 64))
    jungle = water*.8 + insects
    for _ in range(9):
        start = RNG.uniform(1800, 3200)
        notes = [chirp(start, start*RNG.uniform(.7, 1.5), .09 + .05*RNG.random()) for _ in range(RNG.integers(2, 4))]
        when = RNG.uniform(0, length)
        for i, note in enumerate(notes):
            place(jungle, note, when + i*.13, .12 + .06*RNG.random(), RNG.uniform(-.8, .8), True)
    save("ambience_jungle", jungle, peak=.5, quality=2)
    candy = spectral(length, 5500, 12000)*.05*(1 + .4*cycles(length, 6))
    candy += spectral(length, 120, 600)*.05
    for note in RNG.choice([74, 76, 79, 81, 83, 86], 13):
        place(candy, voice(int(note), 1.6, "bell"), RNG.uniform(0, length), .11, RNG.uniform(-.7, .7), True)
    save("ambience_candy", candy, peak=.5, quality=2)
    city = spectral(length, 30, 380, -.5)*.7 + .05*np.sin(2*np.pi*60*t)[:, None]
    city += spectral(length, 200, 1600)*.18*np.clip(.5 + .5*cycles(length, 2, .7), 0, 1)
    city += spectral(length, 500, 2400)*.07*(1 + .3*cycles(length, 9))
    save("ambience_city", city, peak=.5, quality=2)

def write_readme():
    (OUT/"README.md").write_text("# Audio\n\nProcedural scores and effects are generated by `tools/build_audio.py`; impacts, dog voices and menu clicks are processed CC0 recordings (see `CREDITS.md`). 44.1 kHz Ogg Vorbis. Each course has a melodic stem and a synchronised drums stem for dynamic intensity, plus an ambience bed. Speed-reactive sled Foley and dog panting are seamless loops. Regenerate with Python, numpy and ffmpeg; sources are in `tools/audio_sources`. Runtime builds use the checked-in Ogg files.\n", encoding="utf-8")

if __name__ == "__main__":
    for args in [("alpine",62,126,"pluck"), ("jungle",67,132,"flute"), ("candy",63,138,"bell"), ("city",57,130,"keys")]:
        score(*args)
    effects()
    dogs()
    ui_sounds()
    foley()
    ambience()
    music = [v["lufs"] for k, v in REPORT.items() if k.startswith("music_") and not k.endswith("_drive")]
    assert all(-30 < value < -12 for value in music), music
    write_readme()
    print(json.dumps(REPORT, indent=2))
