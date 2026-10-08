"""Rig + audit several prepped squirrels in turn (the Blender launcher detaches, so each step polls its own log).
Run: python run_rig_batch.py name1 name2 ...   (each folder needs <name>.blend from prep_squirrel.py and a src*/ Meshy texture)"""
import os, sys, glob, time, subprocess
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
B = os.path.join(os.environ["LOCALAPPDATA"], r"Microsoft\WindowsApps\blender-launcher.exe")

def blender(script, *args):
    subprocess.run([B, "--background", "--python", os.path.join(HERE, script), "--", *args])

def wait_for(path, words, secs=400):
    t0 = time.time()
    while time.time() - t0 < secs:
        if os.path.exists(path):
            s = open(path, encoding="utf-8", errors="ignore").read()
            if any(w in s for w in words): return s
        time.sleep(4)
    return open(path).read() if os.path.exists(path) else "(no log)"

for name in sys.argv[1:]:
    d = os.path.join(HERE, name)
    png = sorted(glob.glob(os.path.join(d, "src*", "*", "*_texture.png")))[0]
    Image.open(png).convert("RGB").resize((1024, 1024), Image.LANCZOS).save(os.path.join(d, f"{name}_1k.png"))
    subprocess.run([sys.executable, os.path.join(HERE, "make_gray.py"), d, name], capture_output=True)
    for f in ("rig_log.txt", "audit_log.txt"):
        p = os.path.join(d, f)
        if os.path.exists(p): os.remove(p)
    blender("rig_squirrel.py", d, name)
    rig = wait_for(os.path.join(d, "rig_log.txt"), ["RIG_DONE", "Traceback"])
    time.sleep(6)
    blender("audit_generic.py", d, name)
    aud = wait_for(os.path.join(d, "audit_log.txt"), ["AUDIT_DONE", "Traceback"])
    print("==", name)
    print("\n".join(l for l in rig.splitlines() if "head centre" in l or "DONE" in l or "Error" in l))
    print("\n".join(aud.splitlines()[:3]))
    sys.stdout.flush()
