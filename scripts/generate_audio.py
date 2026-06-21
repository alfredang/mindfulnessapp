#!/usr/bin/env python3
"""
Generate the guided-meditation audio matrix for Mindfulness Practice.

Sessions:
  original     -> from Resources/transcript.txt (timestamped). FLEXIBLE length:
                  produces an `intro` clip (lines 1-10) and an `outro` clip
                  (lines 11-12). The app schedules a variable silence between
                  them so the wake-up always lands at the chosen session length.
  awareness10  -> en-Trinh Mai_10 Minute Awareness of Breath.txt (plain, ~10 min)
  awareness5   -> en-Heidi_5 Minute Awareness of Breath.txt (plain, ~5 min)

Voices:
  en-f  English female  (neural)  -> original: re-paced from the EXISTING anna m4a
                                      others : pocket-tts cloned from that same anna voice
  en-m  English male    (neural)  -> pocket-tts cloned from a `say` Daniel reference
  zh-f  中文 female      (Apple)   -> say Tingting (Mandarin)
  zh-m  中文 male        (Apple)   -> say "Eddy (Chinese (China mainland))"

Output: MindfulnessPractice/Resources/audio/<session>-<voice>[-intro|-outro].m4a
Resumable: existing outputs are skipped.
"""
import os, re, subprocess, sys, tempfile, shutil, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "MindfulnessPractice", "Resources")
OUT = os.path.join(RES, "audio")
WORK = os.path.join(ROOT, "build", "audiowork")
os.makedirs(OUT, exist_ok=True)
os.makedirs(WORK, exist_ok=True)
SR = 24000

def run(cmd, **kw):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, **kw)

def dur(path):
    r = run(["ffprobe","-v","error","-show_entries","format=duration",
             "-of","default=noprint_wrappers=1:nokey=1", path])
    return float(r.stdout.strip())

# ---------------------------------------------------------------- ffmpeg helpers
def silence(seconds, path):
    run(["ffmpeg","-y","-f","lavfi","-i",f"anullsrc=r={SR}:cl=mono",
         "-t",f"{seconds:.3f}", path])

def to_wav(src, path):
    run(["ffmpeg","-y","-i",src,"-ar",str(SR),"-ac","1", path])

def concat_wavs(parts, path):
    lst = path + ".txt"
    with open(lst,"w") as f:
        for p in parts:
            f.write(f"file '{p}'\n")
    run(["ffmpeg","-y","-f","concat","-safe","0","-i",lst,"-ar",str(SR),"-ac","1", path])

def soft_bell(path):
    # A warm singing-bowl-ish tone: low fundamental with slow decay.
    run(["ffmpeg","-y","-f","lavfi",
         "-i","sine=frequency=210:duration=6",
         "-f","lavfi","-i","sine=frequency=420:duration=6",
         "-filter_complex",
         "[0]volume=0.6[a];[1]volume=0.25[b];[a][b]amix=inputs=2,"
         "afade=t=out:st=1.2:d=4.8,aecho=0.8:0.9:120:0.3",
         "-ar",str(SR),"-ac","1", path])

def calm_master(src, out_m4a, tempo=0.94, warm=True):
    """Slow slightly, warm + gentle reverb, normalise, encode AAC m4a."""
    chain = [f"atempo={tempo}"]
    if warm:
        chain += ["aecho=0.85:0.9:90:0.22","lowpass=f=8200"]
    chain += ["dynaudnorm=p=0.7:m=8","afade=t=in:st=0:d=0.6"]
    af = ",".join(chain)
    run(["ffmpeg","-y","-i",src,"-af",af,
         "-c:a","aac","-b:a","96k","-ar","44100","-ac","1", out_m4a])

# ---------------------------------------------------------------- TTS backends
DANIEL_REF = os.path.join(WORK,"ref_male.wav")
MALE_VOICE = os.path.join(WORK,"voice_en_m.safetensors")
FEMALE_VOICE = os.path.join(WORK,"voice_en_f.safetensors")
SRC_M4A = os.path.join(RES,"MindfulnessPractice.m4a")

def ensure_en_voices():
    if not os.path.exists(MALE_VOICE):
        run(["say","-v","Daniel","-o",os.path.join(WORK,"ref_male.aiff"),
             "Breathing in, I notice the air moving gently through my body. "
             "Breathing out, I let go, and allow my shoulders to soften and rest. "
             "There is nowhere to be, and nothing to do, but to be here, calmly, with this breath."])
        to_wav(os.path.join(WORK,"ref_male.aiff"), DANIEL_REF)
        run(["pocket-tts","export-voice",DANIEL_REF,MALE_VOICE,"-q"])
    if not os.path.exists(FEMALE_VOICE):
        # Clone the existing "anna" female timbre from a clean segment of the bundled track.
        ref = os.path.join(WORK,"ref_female.wav")
        run(["ffmpeg","-y","-ss","0","-t","13.5","-i",SRC_M4A,"-ar",str(SR),"-ac","1",ref])
        run(["pocket-tts","export-voice",ref,FEMALE_VOICE,"-q"])

def tts_en(text, voice_path, out_wav):
    run(["pocket-tts","generate","--voice",voice_path,"--text",text,
         "--output-path",out_wav,"-q"])

SAY_VOICE = {"zh-f":"Tingting", "zh-m":"Eddy (Chinese (China mainland))"}
def tts_zh(text, voice_key, out_wav):
    aiff = out_wav + ".aiff"
    run(["say","-v",SAY_VOICE[voice_key],"-r","150","-o",aiff,text])
    to_wav(aiff, out_wav)
    os.remove(aiff)

def synth(text, voice, idx):
    """Synthesize one chunk of `text` for `voice`; return wav path."""
    w = os.path.join(WORK, f"chunk_{voice}_{idx}.wav")
    if voice == "en-m": tts_en(text, MALE_VOICE, w)
    elif voice == "en-f": tts_en(text, FEMALE_VOICE, w)
    else: tts_zh(text, voice, w)
    return w

# ---------------------------------------------------------------- scripts
def parse_timestamped():
    lines = []
    with open(os.path.join(RES,"transcript.txt")) as f:
        for ln in f:
            ln = ln.strip()
            if not ln: continue
            lines.append(re.sub(r"^\d{2}:\d{2}\s*","",ln))
    return lines  # 12 lines

ORIG_ZH = [
 "舒适地坐在椅子上，双脚平放在地面，身体保持端正。先觉察身体与周围环境的接触，感受自己坐在椅子上，感受你的双脚。",
 "感受双脚踏在地面上。感受膝盖或手肘的弯曲，感受衣物贴在皮肤上的感觉。",
 "让你的目光柔和地放松下来，花一点时间，留意你所听到的每一个声音。",
 "轻轻地把注意力从周围的声音中收回，放在鼻尖上。开始觉察气息在鼻孔间进出的感觉。",
 "留意吸气与呼气之间，空气温度的变化。吸进来的空气，略微凉爽。",
 "比呼出去的空气更凉一些。温柔地跟随你的呼吸，觉察鼻孔中的气息。",
 "带着温柔的觉察，也留意胸腔与腹部的起伏。放松地呼吸，让呼吸自然而不刻意。",
 "只是单纯地，觉察呼吸。",
 "如果你被思绪带走，只要觉察到这一点，再把注意力带回到呼吸上。即使分心一百次，也没有关系，就一百次温柔地回来。只是不断地回到呼吸，觉察那起与落。",
 "现在，用接下来的几分钟，全然地陪伴你的呼吸。",
 "当你准备好时，把注意力从呼吸上移开，用片刻时间，留意周围的声音。",
 "然后，再次感受身体的觉受。当你准备好时，让目光回到周围的房间。如果愿意，可以伸展一下身体，然后继续你的一天。",
]

def load_plain(fname):
    with open(os.path.join(ROOT,"MindfulnessPractice",fname)) as f:
        txt = f.read()
    txt = txt.replace("******","follow")
    txt = re.sub(r"\s+"," ",txt).strip()
    # split into sentences, keep terminators
    parts = re.split(r"(?<=[\.\?\!])\s+", txt)
    return [p.strip() for p in parts if p.strip()]

TRINH_ZH = [
 "这是一段觉察呼吸的禅修。",
 "持续地练习这个禅修，能够培养觉察、专注，与内在的平静。",
 "在练习中，心念游走，或是感到昏沉，都是很常见的。",
 "试着放下对于「应该有什么感觉」的期待。",
 "这个练习，是一份邀请——以接纳与好奇，去陪伴当下所升起的一切。",
 "找到一个既稳定又舒适的坐姿，可以坐在椅子上，也可以坐在地上的坐垫上。",
 "如果坐在椅子上，让双脚平放在地面。",
 "坐着，是什么样的感觉呢？",
 "去感受身体被地面、坐垫或椅子所支撑的部位。",
 "下半身安稳地扎根，脊柱与背部向上挺立，却不僵硬，像一座庄严的山，端坐着，带着尊严。",
 "胸膛与心，是敞开的；双肩，柔和地垂落在身体两侧。",
 "眼睛可以闭上，或是微微下垂，柔和地凝视。",
 "脸部与嘴角，都放松下来。",
 "觉察此刻你的注意力在哪里，承认它，然后温柔而坚定地，把注意力转向呼吸的感觉。",
 "你正在吸气，还是在呼气呢？",
 "看看你是否能够跟随气息，在身体里进进出出，感受身体的扩张与收缩，不需要以任何方式去控制呼吸，只是与它同在。",
 "看看你的心，是否已经飘向了过去或未来的念头。",
 "这是完全正常的。",
 "承认你的心飘到了哪里，然后温柔而坚定地，把注意力带回到呼吸，回到吸气与呼气。",
 "或许带着一份好奇——你在哪里，最清晰地感受到呼吸呢？",
 "是空气进入鼻孔的时候，还是胸腔或腹部的起伏？",
 "找到那个地方，让你的注意力，就安住在这里。",
 "注意力会从呼吸，移到过去或未来的念头，或是身体的某些感受。",
 "再一次，这是完全正常的。",
 "当你注意到这一点，这正是一个从迷失与分心中醒来的机会。",
 "于是，把握这个机会，只是单纯地，回到呼吸。",
 "吸气，感受气息流入；觉察吸气与呼气之间，那短暂的停顿。",
 "呼气，感受气息流出，释放到空间之中，尽你所能，与这次呼气，长久地同在。",
 "每一次吸气，都是一个重新开始的机会；每一次呼气，都是一次放下的机会。",
 "看看此刻你的注意力在哪里；如果它已经离开了呼吸，承认是什么吸引了你，然后温柔而坚定地，把注意力带回呼吸。",
 "就是这样，这就是练习。",
 "以呼吸，支持你安住在当下这一刻。",
 "它是一个锚，你随时都可以回到这里。",
 "只是觉知这一次呼吸，这份活着的本质，感受每一次气息，在身体里流动、穿行。",
 "与你的生命同在，一次一个呼吸。",
 "钟声响起，保持与呼吸同在，直到你再也听不见钟声。",
 "觉察此刻你的感受，带着觉知与心意，过渡到你接下来的活动。",
]

HEIDI_ZH = [
 "这是一段觉察呼吸的禅修。",
 "持续地练习这个禅修，能够培养觉察、专注，与内在的平静。",
 "安住在一个既稳定又舒适的坐姿里，可以坐在椅子上，也可以坐在地上的坐垫上。",
 "如果坐在椅子上，让双脚平放在地面。",
 "去感觉、去感受身体被地面、坐垫或椅子所支撑的部位。",
 "下半身安稳地扎根，脊柱与背部向上挺立，不僵硬，却是挺拔的；双肩，柔和地垂落在身体两侧。",
 "眼睛可以闭上，或是微微下垂。脸部与嘴角，都放松下来。",
 "现在，把注意力转向呼吸。感受身体里的呼吸。",
 "你正在吸气，还是在呼气呢？",
 "看看你是否能够跟随气息，在身体里进进出出。",
 "感受身体随着呼吸，扩张又收缩。",
 "不需要以任何方式去控制或改变呼吸，只是与呼吸同在。",
 "觉察你的心，是否飘向了过去或未来的念头。这是完全正常的，无需评判自己。",
 "只要温柔而坚定地，把注意力带回到呼吸，回到吸气与呼气。",
 "或许带着一份好奇——你在身体的哪个部位，最清晰地感受到呼吸呢？",
 "是空气进入鼻孔的时候，还是胸腔或腹部的起伏？",
 "让你的注意力，安住在身体里最清晰感受到呼吸的地方。",
 "让注意力，安住在呼吸上。",
 "呼吸，是通往当下的锚。",
 "我们无法在过去呼吸，也无法在未来呼吸，我们只能在此刻呼吸。",
 "你可以一次又一次地回到呼吸，把它当作一个家，一个稳定的依靠。",
 "钟声响起，宣告这段禅修即将结束，保持与呼吸同在，直到你再也听不见钟声。",
 "觉察一下此刻你的感受，带着觉知，过渡到你接下来的活动。",
]

# ---------------------------------------------------------------- builders
def build_clip(chunks, gaps, out_m4a, voice, lead=0.8, tail=2.5, bell_after=None):
    """chunks: list[text]; gaps: silence after each chunk (list, same len).
    bell_after: index after which to insert a bell, or None."""
    parts = []
    leadp = os.path.join(WORK,"lead.wav"); silence(lead, leadp); parts.append(leadp)
    bellp = None
    if bell_after is not None:
        bellp = os.path.join(WORK,"bell.wav"); soft_bell(bellp)
    for i, text in enumerate(chunks):
        parts.append(synth(text, voice, i))
        if bell_after is not None and i == bell_after:
            parts.append(bellp)
        g = gaps[i] if i < len(gaps) else 0
        if g > 0:
            sp = os.path.join(WORK,f"gap_{voice}_{i}.wav"); silence(g, sp); parts.append(sp)
    tailp = os.path.join(WORK,"tail.wav"); silence(tail, tailp); parts.append(tailp)
    raw = os.path.join(WORK,"raw.wav"); concat_wavs(parts, raw)
    warm = not voice.startswith("zh")          # lighter touch on the say voices
    calm_master(raw, out_m4a, tempo=0.96 if voice.startswith("zh") else 0.94, warm=warm)

def repace_existing(intro_out, outro_out):
    """Cut the bundled anna track on detected silence and re-place lines tightly."""
    segs = [(0,13.9),(35.81,42.10),(71.53,78.00),(106.84,117.39),(142.24,150.46),
            (177.28,185.54),(212.76,223.64),(248.54,250.33),(283.67,302.68),(319.43,323.47)]
    outro_segs = [(532.43,539.61),(568.00,578.89)]
    def cut(s,e,idx):
        p = os.path.join(WORK,f"seg_{idx}.wav")
        run(["ffmpeg","-y","-ss",f"{s}","-to",f"{e}","-i",SRC_M4A,"-ar",str(SR),"-ac","1",p])
        return p
    # intro: 6s gaps
    parts=[]; leadp=os.path.join(WORK,"lead.wav"); silence(0.6,leadp); parts.append(leadp)
    for i,(s,e) in enumerate(segs):
        parts.append(cut(s,e,i))
        sp=os.path.join(WORK,f"g_{i}.wav"); silence(6.0,sp); parts.append(sp)
    raw=os.path.join(WORK,"raw_intro.wav"); concat_wavs(parts,raw)
    calm_master(raw,intro_out,tempo=1.0,warm=False)
    # outro: 4s gap
    parts=[cut(outro_segs[0][0],outro_segs[0][1],90)]
    sp=os.path.join(WORK,"g_o.wav"); silence(4.0,sp); parts.append(sp)
    parts.append(cut(outro_segs[1][0],outro_segs[1][1],91))
    tp=os.path.join(WORK,"t_o.wav"); silence(2.0,tp); parts.append(tp)
    raw=os.path.join(WORK,"raw_outro.wav"); concat_wavs(parts,raw)
    calm_master(raw,outro_out,tempo=1.0,warm=False)

# ---------------------------------------------------------------- main
VOICES = ["en-f","en-m","zh-f","zh-m"]

def out(name): return os.path.join(OUT, name + ".m4a")
def done(name):
    p = out(name)
    return os.path.exists(p) and dur(p) > 1.0

def gen_original():
    en_lines = parse_timestamped()
    for v in VOICES:
        ip, op = f"original-{v}-intro", f"original-{v}-outro"
        if done(ip) and done(op):
            print("skip", ip, op); continue
        if v == "en-f":
            repace_existing(out(ip), out(op))
        else:
            lines = ORIG_ZH if v.startswith("zh") else en_lines
            intro_lines, outro_lines = lines[:10], lines[10:]
            build_clip(intro_lines, [6.0]*10, out(ip), v, lead=0.6, tail=2.0)
            build_clip(outro_lines, [4.0,0], out(op), v, lead=0.6, tail=2.0)
        print("built", ip, op, round(dur(out(ip)),1), round(dur(out(op)),1))

def gen_plain(session, en_file, zh_list, en_pause, zh_pause):
    en_sents = load_plain(en_file)
    for v in VOICES:
        name = f"{session}-{v}"
        if done(name): print("skip", name); continue
        zh = v.startswith("zh")
        sents = zh_list if zh else en_sents
        pause = zh_pause if zh else en_pause
        bell_idx = next((i for i,s in enumerate(sents) if ("bell" in s.lower() or "钟声" in s)), None)
        gaps = [pause]*len(sents)
        build_clip(sents, gaps, out(name), v, lead=1.0, tail=8.0, bell_after=bell_idx)
        print("built", name, round(dur(out(name)),1))

if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    ensure_en_voices()
    if which in ("all","original"): gen_original()
    if which in ("all","awareness10"):
        gen_plain("awareness10","en-Trinh Mai_10 Minute Awareness of Breath.txt",TRINH_ZH,en_pause=10.0,zh_pause=6.5)
    if which in ("all","awareness5"):
        gen_plain("awareness5","en-Heidi_5 Minute Awareness of Breath.txt",HEIDI_ZH,en_pause=6.0,zh_pause=4.2)
    print("DONE")
