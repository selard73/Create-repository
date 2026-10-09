#!/usr/bin/env python3
"""Builds tools/shop/keepsakes1.lua (job 43): keepsakes in the Acorn Store's inventory. Shannon, Oct 9: "if you make the
perfume bottle it says yours, but where do you see that you have it in your inventory?" Two rows on the Porto tab of
workspace.Shop.ShopClient (34513 chars, the job 42 text): "Parfum bottle" and "Pearl", shown only once owned, labelled
"yours", never for sale. Five exact finds; original -> ServerStorage.HudBackup.ShopClient_pre_keepsakes1.
Run from the repo root: python3 tools/shop/make_keepsakes1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
P = [
    ('glide into the Rue.", once = true},\n}\n',
     'glide into the Rue.", once = true},\n'
     '\t-- keepsakes (Oct 9 2026): not for sale here; the row shows once the thing is yours\n'
     '\t{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},\n'
     '\t{id = "pearl",         name = "Pearl",         blurb = "From the oyster at the back of the Grotta Azzurra. Bella pays well for it in a box of shells.", keepsake = true},\n}\n'),
    ('\tcrabtrap = {italy = true}, camera = {italy = true},\n}\n',
     '\tcrabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true}, pearl = {italy = true},\n}\n'),
    ('\t\t\telseif item.once and owned then\n\t\t\t\tlabel = "owned"\n',
     '\t\t\telseif item.keepsake then\n\t\t\t\tlabel = owned and "yours" or "find it"\n\t\t\telseif item.once and owned then\n\t\t\t\tlabel = "owned"\n'),
    ('\t\t\tif not selling then label = "soon" end\n', '\t\t\tif not selling and not item.keepsake then label = "soon" end\n'),
    ('\t\t\t\trec.frame.Visible = rec.passOk and onTab(item)\n\t\t\tend\n',
     '\t\t\t\trec.frame.Visible = rec.passOk and onTab(item)\n\t\t\tend\n'
     '\t\t\tif item.keepsake then rec.frame.Visible = owned and onTab(item) end   -- a keepsake row shows once it is yours\n'),
]
def tbl(pairs_): return "{" + ", ".join("{%s, %s}" % (L(a), L(b)) for a, b in pairs_) + "}"
lua = r'''-- shop/keepsakes1 (job 43): EDIT mode. Keepsake rows in the Acorn Store (Porto tab): Parfum bottle and Pearl, shown
-- once owned, "yours", never for sale. Five exact finds in workspace.Shop.ShopClient (34513 chars); compiled before
-- writing; original -> ServerStorage.HudBackup.ShopClient_pre_keepsakes1. Output lines "QQ KEEP".
if game:GetService("RunService"):IsRunning() then warn("QQ KEEP ABORT - Play mode") return end
local Shop = workspace:FindFirstChild("Shop")
local s = Shop and Shop:FindFirstChild("ShopClient")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ KEEP ABORT - missing workspace.Shop.ShopClient") return end
if #s.Source ~= 34513 then warn(string.format("QQ KEEP ABORT - ShopClient is %d chars, expected 34513 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs(@@P@@) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ KEEP ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ KEEP ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ KEEP ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "ShopClient_pre_keepsakes1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ KEEP DONE: ShopClient %d chars; backup ServerStorage.HudBackup.ShopClient_pre_keepsakes1", #s.Source))
'''
lua = lua.replace("@@P@@", tbl(P))
(ROOT / "tools/shop/keepsakes1.lua").write_text(lua, encoding="utf-8")
print("keepsakes1.lua", len(lua.encode()), "chars")
