"""Oct 7 2026: the Drone Flyer's drone (Meshy "Aqua Scout Drone") -> props/drone: unzip, decimate (premerge 280k -> 6k),
sharpened 1k texture, finish_prop.py (centred, feet z=0, FBX + preview renders). Run: python props/prep_drone.py"""
import os, sys, glob, zipfile, shutil, subprocess, time
from PIL import Image, ImageFilter, ImageEnhance
B = os.path.join(os.environ["LOCALAPPDATA"], r"Microsoft\WindowsApps\blender-launcher.exe")
SQ = r"C:\Users\slard\roblox-props\squirrels"
D = r"C:\Users\slard\roblox-props\props\drone"
ZIP = r"C:\Users\slard\Downloads\Meshy_AI_Aqua_Scout_Drone_1008020350_texture_fbx.zip"
os.makedirs(os.path.join(D, "src"), exist_ok=True); os.makedirs(os.path.join(D, "mid"), exist_ok=True)
with zipfile.ZipFile(ZIP) as zf:
    for m in zf.infolist():
        if m.is_dir(): continue
        name = os.path.basename(m.filename); i = name.index("_texture")
        with zf.open(m) as src, open(os.path.join(D, "src", "drone" + name[i:]), "wb") as dst: shutil.copyfileobj(src, dst)
print(os.listdir(os.path.join(D, "src")))
def wait(log, words, secs=900):
    t = time.time()
    while time.time() - t < secs:
        if os.path.exists(log):
            s = open(log, errors="ignore").read()
            if any(w in s for w in words): return s
        time.sleep(4)
    return "(timeout)"
FBX = os.path.join(D, "src", "drone_texture.fbx")
for tgt, inp, out in [(280000, FBX, os.path.join(D, "mid", "d280k.fbx")), (6000, os.path.join(D, "mid", "d280k.fbx"), os.path.join(D, "mid", "d6k.fbx"))]:
    log = out + ".log"
    if os.path.exists(log): os.remove(log)
    subprocess.run([B, "--background", "--python", os.path.join(SQ, "prep_premerge.py"), "--", inp, out, str(tgt), log])
    print(tgt, wait(log, ["PREMERGE_DONE", "Traceback"])[-200:]); time.sleep(4)
im = Image.open(os.path.join(D, "src", "drone_texture.png")).convert("RGB")
c = im.resize((2048, 2048), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=2, percent=70, threshold=2)).resize((1024, 1024), Image.LANCZOS)
c = ImageEnhance.Contrast(ImageEnhance.Color(c).enhance(1.12)).enhance(1.05)
c.save(os.path.join(D, "drone_1k.png"))
log = os.path.join(D, "finish_log.txt")
if os.path.exists(log): os.remove(log)
subprocess.run([B, "--background", "--python", os.path.join(r"C:\Users\slard\roblox-props\props\broomcart", "finish_prop.py"), "--",
                os.path.join(D, "mid", "d6k.fbx"), os.path.join(D, "drone_1k.png"), D, "drone"])
print(wait(log, ["FINISH_DONE", "DONE", "Traceback"], 600)[-600:])
print(os.listdir(D))
