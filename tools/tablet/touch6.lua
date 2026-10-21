-- touch6 (Oct 20 2026): the message-in-a-bottle kiosk. Its "Write a message" prompt pill (PromptTouch, DisplayOrder 30)
-- stayed on top of the bottle panel and covered the "To:" row's left arrow on the iPad Air (pill x 365-558 y 344-391);
-- Shannon: "that is actually an issue on the phone too, the write a message button is over the selector". BottleClient,
-- PHONES AND TABLETS (TouchEnabled): the kiosk prompt hides while the panel is open and comes back when it closes.
-- Computers unchanged. Run in Studio EDIT; backs BottleClient up first. No DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local bc = workspace.Bottles.BottleClient
local src = bc.Source
assert(not src:find("tablet check", 1, true), "BottleClient already patched")
assert(src:find("\nlocal panel", 1, true), "BottleClient: no top-level panel - nothing changed")
assert(src:find("\nlocal prompt = stand and stand:FindFirstChild(\"WritePrompt\", true)", 1, true), "BottleClient: no top-level prompt - nothing changed")
local add = [[

-- (Oct 20 2026, tablet check; Shannon: "that is actually an issue on the phone too, the write a message button is over the
-- selector") on a touch screen the kiosk's own "Write a message" button stayed on top of this panel, over the To: arrows:
-- on phones and tablets it hides while the panel is open and comes back when it closes. Computers keep it as it was.
if prompt and game:GetService("UserInputService").TouchEnabled then
	local hidden = false
	panel:GetPropertyChangedSignal("Visible"):Connect(function()
		if panel.Visible and prompt.Enabled then prompt.Enabled = false; hidden = true
		elseif not panel.Visible and hidden then prompt.Enabled = true; hidden = false end
	end)
end
]]
local bk = bc:Clone(); bk.Name = "BottleClient_pre_touch6"; bk.Enabled = false; bk.Parent = backup
local newSrc = src:gsub("%s+$", "") .. "\n" .. add
SES:UpdateSourceAsync(bc, function() return newSrc end)
return string.format("touch6 installed: BottleClient %d -> %d chars; backup BottleClient_pre_touch6", #bk.Source, #bc.Source)
