"""Builder v4: cheese + chocolate displays, displays pulled up to the glass, CONFISERIE replaces NOISETTES & CIE."""
from pathlib import Path
p = Path(__file__).parent / "make_village_scripts.py"
s = p.read_text(encoding="utf-8")
def rep(old, new, count=1):
    global s
    assert s.count(old) == count, (s.count(old), old[:80])
    s = s.replace(old, new)
rep('''	"disp_bakery", "disp_dress", "disp_shelves", "disp_flowers", "disp_cafe", "disp_hats"}''',
    '''	"disp_bakery", "disp_dress", "disp_shelves", "disp_flowers", "disp_cafe", "disp_hats", "disp_cheese", "disp_chocolate"}''')
rep('''local SHOPS = {"BOULANGERIE", "CAFÉ DE L'ÉCUREUIL", "MODE ET STYLE", "FLEURISTE", "PÂTISSERIE", "FROMAGERIE", "NOISETTES & CIE",''',
    '''local SHOPS = {"BOULANGERIE", "CAFÉ DE L'ÉCUREUIL", "MODE ET STYLE", "FLEURISTE", "PÂTISSERIE", "FROMAGERIE", "CONFISERIE",''')
rep('''	["NOISETTES & CIE"] = {C(190, 140, 90), C(150, 100, 60), C(220, 190, 150), C(120, 80, 50)},''',
    '''	CONFISERIE = {C(240, 120, 150), C(120, 200, 230), C(250, 220, 90), C(150, 220, 150), C(230, 160, 220)},''')
rep('''local DISPLAY = {BOULANGERIE = "disp_bakery", ["PÂTISSERIE"] = "disp_bakery", FLEURISTE = "disp_flowers", CHAPELIER = "disp_hats"}''',
    '''local DISPLAY = {BOULANGERIE = "disp_bakery", ["PÂTISSERIE"] = "disp_bakery", FLEURISTE = "disp_flowers", CHAPELIER = "disp_hats",
	FROMAGERIE = "disp_cheese", CHOCOLATIER = "disp_chocolate"}''')
# colours
rep('''	Book = C(170, 150, 150), Hat = C(90, 85, 82), Brick = C(165, 140, 130)}''',
    '''	Book = C(170, 150, 150), Hat = C(90, 85, 82), Brick = C(165, 140, 130), Cheese = C(225, 210, 170), Choc = C(95, 80, 72), Wrap = C(200, 185, 160)}''')
rep('''	Book = C(200, 70, 70), Hat = C(60, 50, 45), Brick = C(152, 94, 78)}''',
    '''	Book = C(200, 70, 70), Hat = C(60, 50, 45), Brick = C(152, 94, 78), Cheese = C(240, 204, 100), Choc = C(64, 38, 26), Wrap = C(218, 178, 88)}
local CHEESES = {C(240, 204, 100), C(250, 236, 190), C(232, 152, 62), C(246, 240, 214), C(222, 190, 80), C(200, 200, 150)}
local CHOCS = {C(64, 38, 26), C(122, 74, 46), C(236, 220, 190), C(78, 48, 34)}
local WRAPS = {C(218, 178, 88), C(190, 50, 60), C(70, 90, 150), C(120, 70, 140), C(60, 130, 100), C(230, 230, 225)}''')
rep('''				elseif key == "Icing" then p.Color = pick(ICINGS)''',
    '''				elseif key == "Icing" then p.Color = pick(ICINGS)
				elseif key == "Cheese" then p.Color = pick(CHEESES)
				elseif key == "Choc" then p.Color = pick(CHOCS)
				elseif key == "Wrap" then p.Color = pick(WRAPS)''')
# displays up against the glass: front of the kit 0.35 studs behind the pane
rep('''					local gz = g.Position.Z - dz * 2.8
					for i = 1, n do''',
    '''					local _, ksz = templates[kit]:GetBoundingBox()
					local gz = g.Position.Z - dz * (ksz.Z / 2 + 0.35)
					for i = 1, n do''')
rep('''					local L = Instance.new("PointLight"); L.Range = 12; L.Brightness = 1.8;''',
    '''					local L = Instance.new("PointLight"); L.Range = 12; L.Brightness = 1.3;''')
p.write_text(s, encoding="utf-8"); print("builder v4 patched")
