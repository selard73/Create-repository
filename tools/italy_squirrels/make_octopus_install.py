"""Build install_octopus.lua from install_lifeguard.lua (placement part) + oct_head.lua.part + reg_octopus.lua.part."""
from pathlib import Path
src = Path('install_lifeguard.lua').read_text(encoding='utf-8')
s = src[:src.index('-- ---------- props:')]
def rep(a, b):
    global s
    assert s.count(a) == 1, a[:80]
    s = s.replace(a, b)
rep(s[:s.index("local id='lifeguard_squirrel'")],
    "-- Oct 4 2026 (her pick): Lello the Octopus Catcher (octopus_squirrel, Meshy 'Octopus Catch of the Day', 7k tris) standing in\n"
    "-- the rowboat La Limonaia moored by the pier, facing the gangway where players come; registry after Rocco (bio D). Squirrel 15.\n")
rep("local id='lifeguard_squirrel'", "local id='octopus_squirrel'")
a0 = s.index("local chair,boat="); a1 = s.index("-- ---------- Rocco")
s = s[:a0] + Path('oct_head.lua.part').read_text(encoding='utf-8') + s[a1:]
rep("-- ---------- Rocco (same placement code as Tonio)", "-- ---------- Lello (same placement code as Tonio/Rocco); feet on the boat's floor")
fa = s.index("-- feet (feet_probe)"); fb = s.index("local k=3.4/cm.Size.Y")
s = (s[:fa] + "-- feet (feet_probe): L x -0.65..-0.27 y -0.55..-0.15, R x 0.26..0.78 y -0.47..0.04; centre (0.06,-0.27)\n"
     "local feet={{-0.60,-0.50},{-0.32,-0.50},{-0.60,-0.20},{-0.32,-0.20},{0.31,-0.42},{0.72,-0.42},{0.31,-0.02},{0.72,-0.02}}\n" + s[fb:])
rep("Vector3.new(-0.09,0,sz*-0.28)*k", "Vector3.new(0.06,0,sz*-0.27)*k")
rep("for dx=-0.3,0.3,0.1 do for dz=-0.3,0.3,0.1 do", "for dl=-3,3,0.25 do for da=-0.6,0.6,0.2 do")
rep("local c=SPOT+Vector3.new(dx,0,dz)", "local c=SPOT+LONG*dl+ACROSS*da")
rep("local score=(hi-lo)*10+math.abs(dx)+math.abs(dz)",
    "local score=(hi-lo)*10+hi*0.5+math.abs(dl)*0.15+math.abs(da)*0.3   -- flat, low (the floor, not a seat), near the middle")
rep("no ground for Rocco", "no floor in the boat")
rep("'QL@ROCCO feet centre'", "'QL@LELLO feet centre'")
s += ("game:GetService('ChangeHistoryService'):SetWaypoint('Lello in La Limonaia')\nlocal cam=workspace.CurrentCamera\n"
      "local t=L+Vector3.new(0,1.4,0)\ncam.Focus=CFrame.new(t)\ncam.CFrame=CFrame.lookAt(t+WANT*9+ACROSS*3+Vector3.new(0,3.5,0),t)\n\n")
s += Path('reg_octopus.lua.part').read_text(encoding='utf-8')
for bad in ('lifeguard', 'Rocco the', 'chair'):
    assert bad not in s.split('-- registry:')[0].split('\n', 2)[2], bad
Path('install_octopus.lua').write_text(s, encoding='utf-8'); print('ok', len(s))
