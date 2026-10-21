-- tablet1 (Oct 20 2026): two fixes from the iPad Air tablet check (over half the players are on tablets).
--  1. HintClient: on touch screens the Baguette Chase button (ChaseClient, 10 px under Roblox's top bar) was drawn on top of
--     the Hint button; while it shows, Hint now sits just under it, and back at its own spot when it does not.
--  2. ShopClient fit(): on a touch screen whose short side is 600+ (the funnel's Tablet test) the Acorn Store is 20 % bigger
--     and taller (440x560 at UIScale 1.2); phones and computers keep today's size.
-- Run in Studio EDIT (command bar / execute_luau). Backs both scripts up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local function patch(script, name, find, replace)
	local src = script.Source
	local a, b = src:find(find, 1, true)
	assert(a, name .. ": anchor not found - nothing changed")
	assert(not src:find(find, b + 1, true), name .. ": anchor found twice - nothing changed")
	return src:sub(1, a - 1) .. replace .. src:sub(b + 1)
end

-- ---------- 1. HintClient ----------
local hint = workspace.HintShop.HintClient
local hintAnchor = [[local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 2; bs.Parent = btn
]]
local hintAdd = hintAnchor .. [[-- (Oct 20 2026, tablet check) the Baguette Chase button has this same corner on touch screens (ChaseClient: 10 px under
-- Roblox's top bar) and was drawn on top of Hint on every phone and tablet: while it shows, Hint sits just under it
if isMobile then
	task.spawn(function()
		local cg = player:WaitForChild("PlayerGui"):WaitForChild("ChaseGui", 30)
		local join = cg and cg:WaitForChild("Join", 30)
		if not join then return end
		local GuiService = game:GetService("GuiService")
		local function place()
			if cg.Enabled and join.Visible and join.AbsoluteSize.Y > 0 then   -- (this gui ignores the inset; the Join button's does not)
				btn.Position = UDim2.fromOffset(12, join.AbsolutePosition.Y + GuiService:GetGuiInset().Y + join.AbsoluteSize.Y + 8)
			else
				btn.Position = UDim2.new(0, 12, 0, 64)
			end
		end
		for _, prop in ipairs({"Visible", "AbsolutePosition", "AbsoluteSize"}) do join:GetPropertyChangedSignal(prop):Connect(place) end
		cg:GetPropertyChangedSignal("Enabled"):Connect(place)
		place()
	end)
end
]]
assert(not hint.Source:find("tablet check", 1, true), "HintClient already patched")
local newHint = patch(hint, "HintClient", hintAnchor, hintAdd)

-- ---------- 2. ShopClient ----------
local shop = workspace.Shop.ShopClient
local shopAnchor = [[local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local height=math.min(H,vp.Y-140)
 panel.Size=UDim2.fromOffset(math.min(W,vp.X-28),height)
 scale.Scale=1
]]
local shopNew = [[-- (Oct 20 2026, tablet check: over half the players are on tablets, where this phone-sized page showed two items in a
-- small box) on a touch screen whose short side is 600+ (the funnel's own Tablet test) the page is 20 % bigger and taller
local fitUIS = game:GetService("UserInputService")
local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local s=(fitUIS.TouchEnabled and math.min(vp.X,vp.Y)>=600) and 1.2 or 1
 local height=math.min(s>1 and 560 or H,(vp.Y-140)/s)
 panel.Size=UDim2.fromOffset(math.min(W,(vp.X-28)/s),height)
 scale.Scale=s
]]
assert(not shop.Source:find("tablet check", 1, true), "ShopClient already patched")
local newShop = patch(shop, "ShopClient", shopAnchor, shopNew)

-- ---------- backups, then write ----------
for _, pair in ipairs({{hint, "HintClient_pre_tablet1"}, {shop, "ShopClient_pre_tablet1"}}) do
	local b = pair[1]:Clone(); b.Name = pair[2]; b.Enabled = false; b.Parent = backup
end
SES:UpdateSourceAsync(hint, function() return newHint end)
SES:UpdateSourceAsync(shop, function() return newShop end)
print(string.format("tablet1: HintClient %d -> %d chars, ShopClient %d -> %d chars; backups in ServerStorage.HudBackup",
	#backup.HintClient_pre_tablet1.Source, #hint.Source, #backup.ShopClient_pre_tablet1.Source, #shop.Source))
return "tablet1 installed"
