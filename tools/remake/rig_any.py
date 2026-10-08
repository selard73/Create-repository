import os, subprocess, time, json, sys, glob
from PIL import Image, ImageFilter, ImageEnhance
B = os.path.join(os.environ["LOCALAPPDATA"], r"Microsoft\WindowsApps\blender-launcher.exe")
H = r"C:\Users\slard\roblox-props\squirrels"
N = sys.argv[2]
os.chdir(H)
def wait(log, words, secs=900):
    t = time.time()
    while time.time() - t < secs:
        if os.path.exists(log):
            s = open(log, errors="ignore").read()
            if any(w in s for w in words): return s
        time.sleep(4)
    return "(timeout)"
def run(script, logname, words, *a):
    log = os.path.join(D, logname)
    if os.path.exists(log): os.remove(log)
    subprocess.run([B, "--background", "--python", os.path.join(H, script), "--", *a])
    s = wait(log, words); time.sleep(4); return s
step = sys.argv[1]
D = os.path.join(H, N)
RIGARGS = os.environ.get("RIGARGS", "9 0 99 99 -0.55 1.5").split()
REGIONS = os.environ.get("REGIONS", "[]")
TAILYMIN = os.environ.get("TAILYMIN", "0.5")
if step == "rig":
    png = glob.glob(os.path.join(D, "src*", "*", "*_texture.png"))[0]
    im = Image.open(png).convert("RGB")
    im.resize((1024, 1024), Image.LANCZOS).save(os.path.join(D, N + "_1k_plain.png"))
    c = im.resize((2048, 2048), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=2, percent=70, threshold=2)).resize((1024, 1024), Image.LANCZOS)
    c = c.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    c = ImageEnhance.Contrast(ImageEnhance.Color(c).enhance(float(os.environ.get("COLORBOOST","1.12")))).enhance(float(os.environ.get("CONTRAST","1.05")))
    c.save(os.path.join(D, N + "_1k.png"))
    print(subprocess.run([sys.executable, "make_gray.py", D, N], capture_output=True, text=True).stdout[-100:])
    print(run("rig_squirrel.py", "rig_log.txt", ["RIG_DONE", "Traceback"], D, N, *RIGARGS))
    print(run("audit_generic.py", "audit_log.txt", ["AUDIT_DONE", "Traceback"], D, N))
elif step == "fixw":
    neck = sys.argv[3]
    R = REGIONS
    print(run("fix_weights.py", "fixw_log.txt", ["FIXW_DONE", "Traceback"], D, N, neck, "1.2", TAILYMIN, "0.30", R))
    for out, off in (("turn_q34.png", ("3.2", "-4.2", "2.2")), ("turn_close.png", ("-1.4", "-2.4", "2.1"))):
        p = os.path.join(D, out)
        if os.path.exists(p): os.remove(p)
        subprocess.run([B, "--background", "--python", os.path.join(H, "render_turned_view.py"), "--", D, N, out, *off])
        t = time.time()
        while not os.path.exists(p) and time.time() - t < 300: time.sleep(3)
        time.sleep(2)
    f = os.path.join(D, N + "_rigged.blend.feet.txt")
    if os.path.exists(f): os.remove(f)
    subprocess.run([B, "--background", "--python", os.path.join(H, "feet_probe.py"), "--", os.path.join(D, N + "_rigged.blend")])
    t = time.time()
    while not os.path.exists(f) and time.time() - t < 200: time.sleep(3)
    time.sleep(1)
    print(open(f).read() if os.path.exists(f) else "no feet")
