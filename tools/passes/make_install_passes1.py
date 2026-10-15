#!/usr/bin/env python3
"""Builds tools/passes/install_passes1.lua (job 109): Game Passes beside the Acorn Store's once-items - the zip line handle (pass
2036372649) and the hand glider (pass 2037656625). (1) workspace.Passes {PassServer (RunContext Server)} with attributes
Pass_ziphandle / Pass_glider (existing values kept on a re-run). (2) Four exact-string patches of workspace.Shop.ShopClient
(marker PASS1): a PASSES lookup, a green Robux button on the row of any item that has a pass id (the price fetched from Roblox; a
click opens Roblox's own purchase prompt; PassServer grants the item), and the row layout - acorns on the left, Robux on the right
until the item is yours. Self-test: the patches applied to both repo copies of the client (ShopClient.lua 35014 and ShopClient_modes1.lua
38666 - the runner confirms which is live) and compiled with the luau CLI. Backup HudBackup.ShopClient_pre_pass1. Run from the repo root."""
import pathlib, subprocess, os
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src/PassServer.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER
ZIP_PASS = 2036372649
GLIDER_PASS = 2037656625   # (Shannon, Oct 15)
P = [
 ('local buy = RS:WaitForChild("ShopBuy")\n',
  'local buy = RS:WaitForChild("ShopBuy")\n'
  'local PASSES = workspace:WaitForChild("Passes", 5)   -- PASS1 (Oct 15 2026): Game Pass ids per item, attributes Pass_<id> on workspace.Passes\n'),
 ('\trec.btn = btn\n\tif HOTBAR[item.id] then\n',
  '\trec.btn = btn\n'
  '\t-- PASS1 (Shannon: "purchase with a LOT of acorns OR purchase for robux"): an item with a Game Pass gets a second, green button;\n'
  '\t-- Roblox\'s own prompt sells the pass and PassServer grants the item the moment the purchase completes\n'
  '\tlocal passId = PASSES and tonumber(PASSES:GetAttribute("Pass_" .. item.id)) or 0\n'
  '\tif passId > 0 and item.once and not item.robux then\n'
  '\t\tlocal b3 = Instance.new("TextButton")\n'
  '\t\tb3.Name = "RobuxBtn"; b3.AnchorPoint = Vector2.new(1, 0); b3.Position = UDim2.new(1, -12, 0, 106)\n'
  '\t\tb3.Size = UDim2.fromOffset(70, 36); b3.BackgroundColor3 = RGB(70, 170, 110); b3.BorderSizePixel = 0\n'
  '\t\tb3.FontFace = FONT; b3.TextSize = 15; b3.TextColor3 = RGB(255, 255, 255); b3.Text = ROBUX .. " ..."\n'
  '\t\tb3.AutoButtonColor = false; b3.ZIndex = 4; b3.Visible = false; b3.Parent = row\n'
  '\t\tcorner(b3, UDim.new(0, 10)); stroke(b3, RGB(40, 110, 70), 2, 0.2)\n'
  '\t\trec.btn3 = b3\n'
  '\t\tbtn.TextScaled = true; local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 18; tc.MinTextSize = 9; tc.Parent = btn   -- ("1000 acorns" fits the half-width button)\n'
  '\t\ttask.spawn(function()\n'
  '\t\t\tlocal ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(passId, Enum.InfoType.GamePass) end)\n'
  '\t\t\tif ok and type(info) == "table" and info.PriceInRobux then b3.Text = ROBUX .. " " .. tostring(info.PriceInRobux) end\n'
  '\t\tend)\n'
  '\t\tb3.MouseButton1Click:Connect(function()\n'
  '\t\t\tif player:GetAttribute("SaveLoaded") ~= true then say(rec, "still loading your save", false) return end   -- (never sell the pass before we know what is already theirs)\n'
  '\t\t\tif (player:GetAttribute("Item_" .. item.id) or 0) > 0 then say(rec, "already yours", true) return end\n'
  '\t\t\tgame:GetService("MarketplaceService"):PromptGamePassPurchase(player, passId)\n'
  '\t\tend)\n'
  '\tend\n'
  '\tif HOTBAR[item.id] then\n'),
 ('\t\t\t\telse\n\t\t\t\t\trec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18\n\t\t\t\t\trec.btn2.Visible = false\n\t\t\t\tend\n\t\t\tend\n',
  '\t\t\t\telse\n\t\t\t\t\trec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18\n\t\t\t\t\trec.btn2.Visible = false\n\t\t\t\tend\n\t\t\tend\n'
  '\t\t\tif rec.btn3 then   -- PASS1: acorns on the left, Robux on the right, until it is yours\n'
  '\t\t\t\tif owned or player:GetAttribute("SaveLoaded") ~= true then   -- (hidden until the save says what is theirs)\n'
  '\t\t\t\t\trec.btn3.Visible = false\n'
  '\t\t\t\t\tif not rec.btn2 then rec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18 end\n'
  '\t\t\t\telse\n'
  '\t\t\t\t\trec.btn3.Visible = true\n'
  '\t\t\t\t\trec.btn.Size = UDim2.fromOffset(70, 36); rec.btn.Position = UDim2.new(1, -86, 0, 106); rec.btn.TextSize = 12\n'
  '\t\t\t\tend\n'
  '\t\t\tend\n'),
 ('player:GetAttributeChangedSignal("Acorns"):Connect(refresh)\n',
  'player:GetAttributeChangedSignal("Acorns"):Connect(refresh)\nplayer:GetAttributeChangedSignal("SaveLoaded"):Connect(refresh)   -- PASS1: the Robux buttons appear once the save has loaded\n'),
]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
chk = HERE / "check"; chk.mkdir(exist_ok=True)
luau = os.environ.get("LUAU_COMPILE")
for name in ("ShopClient.lua", "ShopClient_modes1.lua"):
    src = (ROOT / "tools/shop/src" / name).read_text(encoding="utf-8")
    assert "PASS1" not in src
    out = src
    for i, (f, r) in enumerate(P):
        assert out.count(f) == 1, (name, i, out.count(f))
        out = out.replace(f, r)
    (chk / (name.replace(".lua", "_pass1.lua"))).write_text(out, encoding="utf-8")
    if luau:
        res = subprocess.run([luau, "--null", str(chk / name.replace(".lua", "_pass1.lua"))], capture_output=True, text=True)
        assert "Error" not in (res.stdout + res.stderr), name + res.stdout + res.stderr
    print(f"self-test {name}: {len(src)} -> {len(out)} chars" + (", compiles" if luau else ""))
if luau:
    res = subprocess.run([luau, "--null", str(HERE / "src/PassServer.lua")], capture_output=True, text=True)
    assert "Error" not in (res.stdout + res.stderr), res.stdout + res.stderr
lua = r'''-- install_passes1.lua (job 109): Studio EDIT mode. Game Passes beside the Acorn Store's once-items (Shannon, Oct 15 2026). (1)
-- workspace.Passes {PassServer} with attributes Pass_ziphandle = @@ZIP@@ and Pass_glider = @@GLIDER@@ (existing values kept). (2)
-- Four exact-string patches of workspace.Shop.ShopClient (a green Robux button on the row of any item with a pass id; Roblox's own
-- prompt sells it; PassServer grants the item). Anchors counted first; compiled where loadstring runs; backup
-- HudBackup.ShopClient_pre_pass1. Acorn prices untouched (Price_<id> attributes on workspace.Shop; her call). Output "QQ PASS".
if game:GetService("RunService"):IsRunning() then print("QQ PASS ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local SERVER = [===[
@@SERVER@@]===]
local Shop = workspace:FindFirstChild("Shop")
local s = Shop and Shop:FindFirstChild("ShopClient")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ PASS ABORT - missing workspace.Shop.ShopClient") return end
local o = s.Source
print("QQ PASS ShopClient is " .. #o .. " chars")
local P = {{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}, {@@F4@@, @@R4@@}}
local n = o
if o:find("PASS1", 1, true) then print("QQ PASS ShopClient already patched")
else
	for i, p in ipairs(P) do
		local a, b = o:find(p[1], 1, true)
		if not a then print("QQ PASS ABORT - ShopClient anchor " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then print("QQ PASS ABORT - ShopClient anchor " .. i .. " matches more than once; nothing changed") return end
	end
	for _, p in ipairs(P) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ PASS ABORT - patched ShopClient does not compile: " .. tostring(err) .. "; nothing changed") return end
end
do
	local ok, f, err = pcall(function() return loadstring(SERVER) end)
	if ok and not f then print("QQ PASS ABORT - PassServer does not compile: " .. tostring(err)) return end
end
-- the folder and the server
local F = workspace:FindFirstChild("Passes")
if not F then F = Instance.new("Folder"); F.Name = "Passes"; F.Parent = workspace end
if F:GetAttribute("Pass_ziphandle") == nil then F:SetAttribute("Pass_ziphandle", @@ZIP@@) end
if F:GetAttribute("Pass_glider") == nil then F:SetAttribute("Pass_glider", @@GLIDER@@) end
local old = F:FindFirstChild("PassServer")
if old then local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS; local k = 1; while hb:FindFirstChild("PassServer_pre_" .. k) do k += 1 end; old.Name = "PassServer_pre_" .. k; old.Enabled = false; old.Parent = hb end
local sv = Instance.new("Script"); sv.Name = "PassServer"; sv.RunContext = Enum.RunContext.Server; sv.Source = SERVER; sv.Parent = F
-- the client
if n ~= o then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("ShopClient_pre_pass1") then local c = s:Clone(); if c then c.Name = "ShopClient_pre_pass1"; c.Enabled = false; c.Parent = hb end end
	s.Source = n
end
print(string.format("QQ PASS DONE: workspace.Passes (PassServer %d chars; Pass_ziphandle %s, Pass_glider %s); ShopClient %d -> %d chars; Price_ziphandle %s, Price_glider %s acorns",
	#SERVER, tostring(F:GetAttribute("Pass_ziphandle")), tostring(F:GetAttribute("Pass_glider")), #o, #n, tostring(Shop:GetAttribute("Price_ziphandle")), tostring(Shop:GetAttribute("Price_glider"))))
'''
subs = {"@@SERVER@@": SERVER, "@@ZIP@@": str(ZIP_PASS), "@@GLIDER@@": str(GLIDER_PASS), "@@F1@@": L(P[0][0]), "@@R1@@": L(P[0][1]), "@@F2@@": L(P[1][0]), "@@R2@@": L(P[1][1]), "@@F3@@": L(P[2][0]), "@@R3@@": L(P[2][1]), "@@F4@@": L(P[3][0]), "@@R4@@": L(P[3][1])}
for k, v in subs.items():
    assert lua.count(k) >= 1, k
    lua = lua.replace(k, v)
assert "@@" not in lua
(HERE / "install_passes1.lua").write_text(lua, encoding="utf-8")
print("install_passes1.lua", len(lua.encode()), "bytes")
