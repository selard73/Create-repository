-- chase30 (Oct 21 2026): cards26 gated the Baguette Chase card's tablet centring on the viewport size READ AT SCRIPT
-- START, and the viewport can still be 1x1 then - so the iPad was treated as a phone and the card stayed at the top
-- (Shannon: "the baguette chase instruction should still be a little lower"). The check now runs live, like sling24's:
-- placed at once and again whenever the viewport changes. Phones keep the top spot; tablets get the centred one
-- (anchor 0.5,0.5 at scale 0.45 - the spot every other screen uses).
-- Run in Studio EDIT. Backs ChaseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local chase = workspace.Baguette.ChaseClient
local old = [[	local vpM = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
	if math.min(vpM.X, vpM.Y) < 600 then
		modal.AnchorPoint = Vector2.new(0.5, 0); modal.Position = UDim2.new(0.5, 0, 0, 4)
	end]]
local new = [[	local function placeModal()   -- live: at script start the viewport can read 1x1, which looked like a phone (Oct 21)
		local vpM = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
		if math.min(vpM.X, vpM.Y) < 600 then
			modal.AnchorPoint = Vector2.new(0.5, 0); modal.Position = UDim2.new(0.5, 0, 0, 4)
		else
			modal.AnchorPoint = Vector2.new(0.5, 0.5); modal.Position = UDim2.fromScale(0.5, 0.45)
		end
	end
	placeModal()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeModal) end]]
local src = chase.Source
local a, b = src:find(old, 1, true)
assert(a, "ChaseClient: cards26 block not found - nothing changed")
assert(not src:find(old, b + 1, true), "ChaseClient: cards26 block found twice - nothing changed")
local newSrc = src:sub(1, a - 1) .. new .. src:sub(b + 1)
local bk = chase:Clone(); bk.Name = "ChaseClient_pre_chase30"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(chase, function() return newSrc end)
print(string.format("chase30: ChaseClient %d -> %d chars", #src, #chase.Source))
return "chase30 installed"
