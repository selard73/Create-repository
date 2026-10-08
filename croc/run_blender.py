"""Run one Blender headless script through the Store launcher (which returns at once) and wait for its log to say
<MARK>_DONE or <MARK>_FAILED.  Run: python run_blender.py <log_path> <MARK> <script.py> [script args ...]"""
import os, subprocess, sys, time
LAUNCHER = os.path.join(os.environ["LOCALAPPDATA"], r"Microsoft\WindowsApps\blender-launcher.exe")
logp, mark, script, rest = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
if os.path.exists(logp):
    os.remove(logp)
subprocess.Popen([LAUNCHER, "--background", "--python", script, "--"] + rest)
t0 = time.time()
while time.time() - t0 < 1500:
    time.sleep(3)
    if os.path.exists(logp):
        txt = open(logp, encoding="utf-8", errors="replace").read()
        if mark + "_DONE" in txt or mark + "_FAILED" in txt:
            print(txt[-6000:] if len(txt) > 6000 else txt)
            print("elapsed %.0fs" % (time.time() - t0))
            sys.exit(0)
print("TIMEOUT after %.0fs" % (time.time() - t0))
if os.path.exists(logp):
    print(open(logp, encoding="utf-8", errors="replace").read()[-3000:])
