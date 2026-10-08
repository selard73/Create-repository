"""unzip_any.py <squirrel_id> <zip glob> <src folder name> : move current outputs to old_<stamp>/, unzip to plain names."""
import glob, zipfile, os, shutil, sys, re
sid, zglob, srcname = sys.argv[1], sys.argv[2], sys.argv[3]
D = os.path.join(r"C:\Users\slard\roblox-props\squirrels", sid)
z = glob.glob(zglob)[0]
print(z, os.path.getsize(z) // 2**20, "MB;", shutil.disk_usage("C:/").free // 2**20, "MB free")
old = os.path.join(D, os.environ.get("OLDNAME", "old_oct5"))   # a second redo the same day: OLDNAME=old_oct5_v2
os.makedirs(old, exist_ok=True)
for f in os.listdir(D):
    if f.startswith("old_") or f == "mid":
        continue
    shutil.move(os.path.join(D, f), os.path.join(old, f))
out = os.path.join(D, srcname, "Meshy_AI_new_texture_fbx")
os.makedirs(out, exist_ok=True)
with zipfile.ZipFile(z) as zf:
    for m in zf.infolist():
        if m.is_dir():
            continue
        name = os.path.basename(m.filename)
        i = name.index("_texture")
        with zf.open(m) as src, open(os.path.join(out, "Meshy_AI_new" + name[i:]), "wb") as dst:
            shutil.copyfileobj(src, dst)
print(os.listdir(out))
print(shutil.disk_usage("C:/").free // 2**20, "MB free")
