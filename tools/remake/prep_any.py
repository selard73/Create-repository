import os, sys, subprocess, time
B = os.path.join(os.environ["LOCALAPPDATA"], r"Microsoft\WindowsApps\blender-launcher.exe")
H = r"C:\Users\slard\roblox-props\squirrels"
JOBS = [(sys.argv[1], sys.argv[2] + r"\Meshy_AI_new_texture_fbx\Meshy_AI_new_texture")]   # prep_any.py <id> <srcdir>
TGT = 15000
def wait(log, words, secs=1200):
    t=time.time()
    while time.time()-t<secs:
        if os.path.exists(log):
            s=open(log,errors="ignore").read()
            if any(w in s for w in words): return s
        time.sleep(5)
    return "(timeout)"
def run(script,*a): subprocess.run([B,"--background","--python",os.path.join(H,script),"--",*a])
for name, base in JOBS:
    D = os.path.join(H, name); FBX = os.path.join(D, base + ".fbx"); PNG = os.path.join(D, base + ".png")
    os.makedirs(D + r"\mid", exist_ok=True)
    for tgt,inp,out in [(280000,FBX,D+r"\mid\n280k.fbx"),(TGT,D+r"\mid\n280k.fbx",D+rf"\mid\n{TGT}.fbx")]:
        log=out+".log"
        if os.path.exists(log): os.remove(log)
        run("prep_premerge.py",inp,out,str(tgt),log)
        s=wait(log,["PREMERGE_DONE","Traceback"]); print(name, tgt, s[-400:], flush=True); time.sleep(5)
    log=D+r"\prep_log.txt"
    if os.path.exists(log): os.remove(log)
    run("prep_squirrel.py",D+rf"\mid\n{TGT}.fbx",D,name,PNG,str(TGT+400),"2.4","0")
    s=wait(log,["PREP_DONE","Traceback"]); print(name, "PREP", s[-300:], flush=True); time.sleep(5)
print("ALL_DONE")
