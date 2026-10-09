-- shop/keepsakes1 (job 43): EDIT mode. Keepsake row in the Acorn Store (Porto tab): Parfum bottle, shown
-- once owned, "yours", never for sale. Five exact finds in workspace.Shop.ShopClient (34513 chars); compiled before
-- writing; original -> ServerStorage.HudBackup.ShopClient_pre_keepsakes1. Output lines "QQ KEEP".
if game:GetService("RunService"):IsRunning() then warn("QQ KEEP ABORT - Play mode") return end
local Shop = workspace:FindFirstChild("Shop")
local s = Shop and Shop:FindFirstChild("ShopClient")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ KEEP ABORT - missing workspace.Shop.ShopClient") return end
if #s.Source ~= 34513 then warn(string.format("QQ KEEP ABORT - ShopClient is %d chars, expected 34513 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{[===[
glide into the Rue.", once = true},
}
]===], [===[
glide into the Rue.", once = true},
	-- keepsakes (Oct 9 2026): not for sale here; the row shows once the thing is yours
	{id = "parfum_bottle", name = "Parfum bottle", blurb = "Made with Bella from the purple sea glass. Keep it safe for the parfumerie in France.", once = true, keepsake = true},
}
]===]}, {[===[
	crabtrap = {italy = true}, camera = {italy = true},
}
]===], [===[
	crabtrap = {italy = true}, camera = {italy = true}, parfum_bottle = {italy = true},
}
]===]}, {[===[
			elseif item.once and owned then
				label = "owned"
]===], [===[
			elseif item.keepsake then
				label = owned and "yours" or "find it"
			elseif item.once and owned then
				label = "owned"
]===]}, {[===[
			if not selling then label = "soon" end
]===], [===[
			if not selling and not item.keepsake then label = "soon" end
]===]}, {[===[
				rec.frame.Visible = rec.passOk and onTab(item)
			end
]===], [===[
				rec.frame.Visible = rec.passOk and onTab(item)
			end
			if item.keepsake then rec.frame.Visible = owned and onTab(item) end   -- a keepsake row shows once it is yours
]===]}}) do
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
