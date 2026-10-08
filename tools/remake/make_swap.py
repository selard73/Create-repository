"""make_swap.py <id> <newfx> <newfy> [flip] : fill swap_model.template.lua for one of the 9 remaining harbour squirrels
with its old feet centre (from its own installer) and pack it as italy_squirrels/s_<short>.rbxmx (folder Swap_<short>).
Old feet centres (Blender units), read Oct 5 2026 from the installers:
  install_three.lua placed by the mesh centre -> 0,0; install_tourist/move_tourist_v2 put cm centre on P -> 0,0;
  painter + tightrope used the tail-side sx guess -> 'tail'; conductor/octopus/sunbather used sx 1 -> 'one'."""
import sys, subprocess
from pathlib import Path
T = {
    'customs_squirrel':     ('customs', 0, 0, 'one'),
    'deckhand_squirrel':    ('deckhand', 0, 0, 'one'),
    'netmender_squirrel':   ('netmender', 0, 0, 'one'),
    'boatpainter_squirrel': ('painter', 0.02, -0.43, 'tail'),
    'italytourist_squirrel':('tourist', 0, 0, 'one'),
    'tightrope_squirrel':   ('tightrope', -0.37, -0.51, 'tail'),   # the standing foot, not the feet centre
    'sunbather_squirrel':   ('sunbather', -0.14, -0.47, 'one'),
    'conductor_squirrel':   ('conductor', -0.09, -0.31, 'one'),
    'octopus_squirrel':     ('octopus', 0.06, -0.27, 'one'),
}
sid, nfx, nfy = sys.argv[1], sys.argv[2], sys.argv[3]
flip = 'true' if len(sys.argv) > 4 and sys.argv[4] == 'flip' else 'false'
short, ofx, ofy, osx = T[sid]
D = Path(r'C:\Users\slard\roblox-props\tools\italy_squirrels')
s = (D / 'swap_model.template.lua').read_text(encoding='utf-8')
for k, v in (('%ID%', sid), ('%OLDFX%', ofx), ('%OLDFY%', ofy), ('%OLDSX%', osx), ('%NEWFX%', nfx), ('%NEWFY%', nfy), ('%OLDFLIP%', flip)):
    s = s.replace(k, str(v))
assert '%' not in s.replace('%.', ''), 'unfilled placeholder'
out = D / f'swap_{short}.lua'
out.write_text(s, encoding='utf-8')
print(subprocess.run([sys.executable, str(D / 'pack.py'), str(out), str(D / f's_{short}.rbxmx'), f'Swap_{short}'], capture_output=True, text=True).stdout)
print('Studio:', f"local m=workspace:FindFirstChild('Swap_{short}',true) require(m.PatchModule)() m:Destroy()")
