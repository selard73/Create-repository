-- gifts9 (Oct 20 2026): Shannon, on the iPad Gifts card: "the modal is the right size but the buttons themselves are too fat"
-- / "too close to each other with no space between them" -> TABLETS only: the three row buttons 104x28 (were 112x36), so
-- there is clear space between them. Phones and computers unchanged. Backup first. (Installed from the command bar.)
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local gc = workspace.Gifts.GiftsClient
local src = gc.Source
assert(src:find("TabletScale", 1, true), "gifts8 is not installed")
assert(not src:find("rowButtons", 1, true), "gifts9 already installed")
local anchor = [[	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(tabletFit) end
end)
]]
local a, b = src:find(anchor, 1, true)
assert(a and not src:find(anchor, b + 1, true), "GiftsClient: gifts8 block end not found once - nothing changed")
local add = [[
-- (Oct 20 2026; Shannon, on the iPad: "the buttons themselves are too fat" - "too close to each other with no space between
-- them") on a tablet the three row buttons are a little shorter and narrower, so there is clear space between them
local rowButtons = {}
local function slimFit(btn) btn.Size = (tabletScale.Scale > 1) and UDim2.fromOffset(104, 28) or UDim2.fromOffset(112, 36) end
card.DescendantAdded:Connect(function(d)
	if d:IsA("TextButton") and d.Size == UDim2.fromOffset(112, 36) then table.insert(rowButtons, d); slimFit(d) end
end)
tabletScale:GetPropertyChangedSignal("Scale"):Connect(function() for _, btn in ipairs(rowButtons) do slimFit(btn) end end)
]]
local newSrc = src:sub(1, b) .. add .. src:sub(b + 1)
local bk = gc:Clone(); bk.Name = "GiftsClient_pre_gifts9"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(gc, function() return newSrc end)
return "gifts9 installed"
