-- gifts8 (Oct 20 2026): Shannon: "the gifts modal on ipad can be a bit bigger please" -> on TABLETS only (touch + the
-- screen's short side 600+) the Gifts card gets a UIScale of 1.3, growing down from its top-centre anchor. Backup first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local gc = workspace.Gifts.GiftsClient
local src = gc.Source
assert(not src:find("TabletScale", 1, true), "GiftsClient already patched")
local anchor = [[text(card, "Gifts for squirrel friends"]]
local a, b = src:find(anchor, 1, true)
assert(a and not src:find(anchor, b + 1, true), "GiftsClient: anchor not found once - nothing changed")
local lineStart = a
while lineStart > 1 and src:sub(lineStart - 1, lineStart - 1) ~= "\n" do lineStart -= 1 end
local block = [[
-- (Oct 20 2026, tablet check; Shannon: "the gifts modal on ipad can be a bit bigger please") on a tablet (touch, the
-- screen's short side 600+) the card is 30 % bigger, growing down from its top-centre spot; phones and computers unchanged
local tabletScale = Instance.new("UIScale"); tabletScale.Name = "TabletScale"; tabletScale.Parent = card
local function tabletFit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.zero
	tabletScale.Scale = (UIS.TouchEnabled and math.min(vp.X, vp.Y) >= 600) and 1.3 or 1
end
tabletFit()
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y > 200 then break end task.wait(0.25) end
	tabletFit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(tabletFit) end
end)
]]
local newSrc = src:sub(1, lineStart - 1) .. block .. src:sub(lineStart)
local bk = gc:Clone(); bk.Name = "GiftsClient_pre_gifts8"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(gc, function() return newSrc end)
return string.format("gifts8 installed: GiftsClient %d -> %d chars; backup GiftsClient_pre_gifts8", #bk.Source, #gc.Source)
