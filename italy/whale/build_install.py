"""build_install.py : fill install_whale.template.lua with the settings below + WhaleClient.lua, write
tools/italy_squirrels/install_whale.lua and pack it as i_whale.rbxmx (folder InstallWhale).
Edit SETTINGS (or pass key=value args, e.g. ROUTE="100,-700;..." LENGTH=50) and re-run; re-running the installer in
Studio patches the existing PortoWhale (no re-import needed)."""
import sys, subprocess
from pathlib import Path
D = Path(__file__).resolve().parent
T = D.parent.parent / "tools" / "italy_squirrels"
SETTINGS = {
    "LENGTH": "60",
    "WATER_Y": "-52.9",
    "ROUTE": "200,-840;90,-940;40,-1110;210,-1215;340,-1165;362,-1102;215,-985",   # survey Oct 7: A bay mouth .. B off the pebble beach
    "BLOW_AT": "1,6",          # A = point 1 (bay mouth), B = point 6 (cave/pebble beach)
    "SPEED": "7",
    "BLOW_DUR": "12",
    "SOUND_ID": "rbxassetid://9114454664",   # her pick, Oct 7
    "BED_Y": "-77",            # whale lane floor: voxel floor -80 renders as a surface at -78 (Oct 7 probe)
}
for a in sys.argv[1:]:
    k, v = a.split("=", 1)
    SETTINGS[k] = v
client = (D / "WhaleClient.lua").read_text(encoding="utf-8")
assert "]==]" not in client and "]]>" not in client
s = (D / "install_whale.template.lua").read_text(encoding="utf-8").replace("%CLIENT%", client)
for k, v in SETTINGS.items():
    s = s.replace(f"%{k}%", v)
import re
assert not re.search(r"%[A-Z_]{3,}%", s), "unfilled placeholder: " + str(re.findall(r"%[A-Z_]{3,}%", s))
out = T / "install_whale.lua"
out.write_text(s, encoding="utf-8")
print(subprocess.run([sys.executable, str(T / "pack.py"), str(out), str(T / "i_whale.rbxmx"), "InstallWhale"], capture_output=True, text=True).stdout)
print("Studio:", "local m=workspace:FindFirstChild('InstallWhale',true) require(m.PatchModule)() m:Destroy()")
