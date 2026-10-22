-- decorvr1 (Oct 22 2026): the Treehouse tab in VR. Shannon: "when you open the menu for treehouse items on vr it is blank".
-- In a headset VRWindowClient moves the Passport's Page off PassportGui onto its floating window (a Frame named
-- PassportGui inside PlayerGui.VRWindow). DecorClient waited for PassportGui.Page, never found it, and gave up - so the
-- tab stayed empty. It now looks in both places, as WardrobeClient has done since Oct 9. The first-build tip in
-- TreehouseClient (its glow on the Treehouse tab) looked in the same wrong place in VR; same fix.
-- Run in Studio EDIT. Backs both scripts up to ServerStorage.HudBackup (<name>_pre_decorvr1) first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local function patched(script, edits)
	local src = script.Source
	assert(not src:find("(decorvr1", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	return src
end
local dc = workspace.Treehouse.DecorClient
local dcSrc = patched(dc, {
	{[==[local gui = pg:WaitForChild("PassportGui", 60)
local page = gui and gui:WaitForChild("Page", 30)
local decor = page and page:WaitForChild("DecorContent", 30)]==],
	 [==[-- (decorvr1, Oct 22 2026; Shannon: "when you open the menu for treehouse items on vr it is blank") in a headset
-- VRWindowClient moves the Passport's Page onto its floating window, so look for it there too (as WardrobeClient does)
local gui = pg:WaitForChild("PassportGui", 60)
local page
local t0 = os.clock()
while gui and not page and os.clock() - t0 < 60 do
	local vrw = pg:FindFirstChild("VRWindow"); local box = vrw and vrw:FindFirstChild("PassportGui")
	page = (box and box:FindFirstChild("Page")) or gui:FindFirstChild("Page")
	if not page then task.wait(0.2) end
end
local decor = page and page:WaitForChild("DecorContent", 30)]==], "the Passport page lookup"},
})
local tc = workspace.Treehouse.TreehouseClient
local tcSrc = patched(tc, {
	{[==[			local pGui = pg:FindFirstChild("PassportGui")
			local panel = pGui and pGui:FindFirstChild("Page", true)]==],
	 [==[			local vrw = pg:FindFirstChild("VRWindow")   -- (decorvr1: in a headset the Page is on the VR window)
			local pGui = (vrw and vrw:FindFirstChild("PassportGui")) or pg:FindFirstChild("PassportGui")
			local panel = pGui and pGui:FindFirstChild("Page", true)]==], "the tip's Passport lookup"},
})
for _, s in ipairs({dc, tc}) do
	local b = s:Clone(); b.Name = s.Name .. "_pre_decorvr1"; b.Enabled = false; b.Parent = backup
end
SES:UpdateSourceAsync(dc, function() return dcSrc end)
SES:UpdateSourceAsync(tc, function() return tcSrc end)
print(string.format("decorvr1: DecorClient %d chars, TreehouseClient %d chars", #dc.Source, #tc.Source))
return "decorvr1 installed"
