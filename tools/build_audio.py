"""Original 16-bar scores and arcade Foley. Regeneration needs numpy/ffmpeg;
players and exports use checked-in Ogg files, with no runtime dependencies."""
from pathlib import Path
import json
import numpy as np
import subprocess
RATE = 24000
OUT = Path(__file__).resolve().parents[1] / "godot/assets/audio"
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(240115)
REPORT = {}

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
    values = sample[:, None]*gain*np.array([np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)])
    if wrap:
        np.add.at(mix, indices % len(mix), values)
    else:
        valid = indices < len(mix)
        mix[indices[valid]] += values[valid]

def save(name, mix, peak=.85):
    mix *= peak/max(.001, np.max(np.abs(mix)))
    path = OUT / f"{name}.ogg"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "2",
                    "-i", "pipe:0", "-c:a", "libvorbis", "-q:a", "4", str(path)],
                   input=mix.astype("<f4").tobytes(), check=True)
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "pipe:1"])
    decoded = np.frombuffer(raw, dtype="<f4")
    assert np.isfinite(decoded).all()
    assert np.max(np.abs(decoded)) < 1, name
    REPORT[name] = {"seconds": round(len(mix)/RATE, 3), "peak": round(float(np.max(np.abs(decoded))), 4),
                    "rms": round(float(np.sqrt(np.mean(decoded**2))), 4), "bytes": (OUT / f"{name}.ogg").stat().st_size}

def score(theme, root, bpm, lead):
    beat = 60/bpm
    mix = np.zeros((round(64*beat*RATE), 2))
    phrases = [[0,4,7,9,7,4,2,4], [5,9,12,9,7,5,4,2], [9,12,14,12,9,7,4,7], [7,11,14,12,11,7,2,-1],
               [12,7,9,7,4,2,0,4], [5,7,9,12,9,5,4,2], [9,7,4,7,12,14,12,9], [7,4,2,-1,2,7,4,0]]
    chords = [(0,4,7), (5,9,12), (9,12,16), (7,11,14)]
    for bar in range(16):
        chord = chords[bar % 4]
        for step, note in enumerate(phrases[bar % 8]):
            octave = 12 if bar >= 8 and step in (2,6) else 0
            place(mix, voice(root+12+note+octave, beat*.75, lead), (bar*4+step*.5)*beat, .24, -.15, True)
            if step % 2:
                place(mix, voice(root+chord[(step//2)%3], beat*.7, "keys"), (bar*4+step*.5)*beat, .11, .48, True)
        for b in (0,1.5,2,3.5):
            note = root-12+(chord[0] if b < 2 else chord[2]-12)
            place(mix, voice(note, beat*.85, "bass"), (bar*4+b)*beat, .35, 0, True)
        for b in (0,2):
            for note in chord:
                place(mix, voice(root+note, beat*1.8, "keys"), (bar*4+b)*beat, .075, -.5, True)
            place(mix, drum("kick"), (bar*4+b)*beat, .3, 0, True)
        for b in (1,3):
            place(mix, drum("wood" if theme == "jungle" else "snare"), (bar*4+b)*beat, .17, .1, True)
        for b in np.arange(0,4,.5):
            place(mix, drum("hat"), (bar*4+b)*beat, .07 if b % 1 else .11, -.3, True)
    # Circular room taps preserve tails across the loop boundary.
    mix += np.roll(mix[:, ::-1], round(beat*.75*RATE), axis=0)*.14
    mix += np.roll(mix, round(beat*1.5*RATE), axis=0)*.07
    save(f"music_{theme}", mix, .72)

def effect(name, duration):
    mix = np.zeros((round(duration*RATE), 2))
    t = np.arange(len(mix))/RATE
    if name in ("pickup", "go", "lap", "finish", "countdown", "warning"):
        notes = {"pickup":[76,80,83,88], "go":[62,69,74], "lap":[74,78,81,86],
                 "finish":[62,66,69,74,73,74,78,81], "countdown":[81], "warning":[78,74]}[name]
        for i, note in enumerate(notes):
            when = i*(.18 if name == "finish" else .12)
            place(mix, voice(note, .5, "bell"), when, .6, (i%2-.5)*.5)
            if name == "finish":
                place(mix, voice(note-12, .6, "keys"), when, .4)
    elif name in ("crash", "coconut"):
        noise = RNG.normal(0,.5,len(t))
        thump = np.sin(2*np.pi*(65*t+2*(1-np.exp(-t*25))))*np.exp(-t*12)
        wood = np.sin(2*np.pi*(420 if name == "coconut" else 185)*t)*np.exp(-t*17)
        place(mix, thump*.8 + noise*np.exp(-t*37)*.65 + wood*.4, 0, 1)
        place(mix, drum("wood"), .06, .25, .5)
        place(mix, drum("wood"), .13, .18, -.4)
    else:
        smooth = np.convolve(RNG.normal(0,.3,len(t)), np.ones(6)/6, mode="same")
        rise = np.sin(2*np.pi*(170*t+650*t**2))*.22
        place(mix, (smooth*1.8+rise)*np.sin(np.pi*t/duration)**1.5, 0, 1)
        if name == "boost":
            for i, note in enumerate([50,57,62,69]):
                place(mix, voice(note,.25), i*.11, .35, (i-1.5)*.2)
    mix[:120] *= np.linspace(0,1,120)[:,None]
    mix[-120:] *= np.linspace(1,0,120)[:,None]
    save(name, mix)

if __name__ == "__main__":
    for args in [("alpine",62,126,"pluck"), ("jungle",67,132,"flute"), ("candy",63,138,"bell"), ("city",57,130,"keys")]:
        score(*args)
    for name, duration in {"pickup":1., "go":.9, "lap":1.1, "finish":2.2, "countdown":.5, "warning":.6,
                           "crash":.55, "coconut":.5, "boost":.8, "speed":.45, "throw":.3}.items():
        effect(name,duration)
    (OUT/"README.md").write_text("# Original audio\n\nOriginal procedural compositions and effects generated by `tools/build_audio.py`. No third-party samples. 24 kHz stereo Ogg Vorbis; four seamless 16-bar scores. Regenerate with Python, numpy and ffmpeg. Runtime builds use the checked-in Ogg files.\n", encoding="utf-8")
    print(json.dumps(REPORT, indent=2))
