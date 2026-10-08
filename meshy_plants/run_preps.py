"""Run the Blender prep for each Meshy plant, one at a time (the Store launcher returns at once, so each run is
waited for through its report.json). Also makes the 1024px colour textures first.
Run: python run_preps.py [name ...]"""
import glob, json, os, subprocess, sys, time
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
LAUNCHER = os.path.join(os.environ["LOCALAPPDATA"], r"Microsoft\WindowsApps\blender-launcher.exe")
PLANTS = {                                  # folder: (roblox name, height in studs, target tris)
    "happy_harvest_pumpkin": ("Pumpkin", 4.2, 8000),
    "sunny_smiles": ("Sunflower", 7.0, 8000),
    "shy_carrot": ("Carrot", 3.6, 8000),
    "giggleberry": ("Strawberry", 3.2, 8000),
}
want = sys.argv[1:] or list(PLANTS)
for folder in want:
    name, height, tris = PLANTS[folder]
    d = os.path.join(HERE, folder)
    fbx = glob.glob(os.path.join(d, "**", "*.fbx"), recursive=True)
    fbx = [f for f in fbx if not os.path.basename(f).startswith(name)]
    tex = [t for t in glob.glob(os.path.join(d, "**", "*texture.png"), recursive=True)]
    assert fbx and tex, (folder, fbx, tex)
    tex1k = os.path.join(d, name + "_colour_1k.png")
    im = Image.open(tex[0]).convert("RGB"); im.thumbnail((1024, 1024)); im.save(tex1k)
    rep = os.path.join(d, "report.json")
    if os.path.exists(rep):
        os.remove(rep)
    args = [LAUNCHER, "--background", "--python", os.path.join(HERE, "prep_plant.py"), "--", fbx[0], d, name, tex1k, str(tris), str(height)]
    print("launch", folder, flush=True)
    subprocess.Popen(args)
    t0 = time.time()
    while not os.path.exists(rep) and time.time() - t0 < 900:
        time.sleep(2)
    if not os.path.exists(rep):
        print("TIMEOUT", folder, flush=True)
        continue
    time.sleep(1)
    r = json.load(open(rep))
    print(json.dumps({k: r.get(k) for k in ("name", "ok", "dims_in", "dims_out", "tris_before", "tris_after", "error")}), flush=True)
print("ALL DONE", flush=True)
