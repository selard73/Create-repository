-- hud34 (Oct 21 2026, late): two of Shannon's live notes, previewed in play tests and approved ("Install all of it with
-- backups"):
--   PHONES - "The passport open model on the cell phone is too small" + the Treehouse page "is not scrollable because it
--     overlaps with the icons at the bottom of the screen": on a phone (touch, short side under 600) the open Passport now
--     reaches down to 8 px from the bottom (was 92), over the movement controls (her rule: windows may cover the bottom
--     bar - you do not use it while reading); while it is open Roblox's tool bar and screenshot bar and the Reset progress
--     button step aside (the hat and dress shops already hide the tool bar this way). The Treehouse page's rugs now live
--     in a scrolling list inside the Passport (the Outings page's gold scrollbar), with the tutorial's "Pick a rug" line
--     scrolling with them. iPad and computer: the page fits, nothing changes there.
--   COMPUTERS (and VR, which shows the same HUD row) - "the hint button should go above the baguette button; just get
--     rid of the medal completely": Hint leaves the top row for the left side under Roblox's buttons (its phone/tablet
--     spot, 12,64), its message under both (12,170); the Baguette Chase button sits just under Hint, measured from it.
--     The medal is gone on EVERY device (phones and tablets already had none); the title pill still opens the case.
-- Run in Studio EDIT. Backs every script up to ServerStorage.HudBackup as <name>_pre_hud34 first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local jobs = {}
local function patch(script, edits)
	local src = script.Source
	assert(not src:find("hud34", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	table.insert(jobs, {script = script, src = src})
end

-- ---------- 1. PassportClient: the taller phone Passport, and what steps aside while it is open ----------
patch(workspace.Passport.PassportClient, {
	{[==[ -- Keep the HUD and movement/reset controls outside the page on every screen.
 local topSafe,bottomSafe=68,mobile and 92 or 84]==],
	[==[ -- Keep the HUD and movement/reset controls outside the page on every screen - except a phone (hud34, Oct 21 2026;
 -- Shannon: "The passport open model on the cell phone is too small"): there it reaches down over the bottom controls
 local phoneTall=UIS.TouchEnabled and math.min(vp.X,vp.Y)<600
 local topSafe,bottomSafe=68,phoneTall and 8 or (mobile and 92 or 84)]==], "fit's safe margins"},
	{[==[pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels);pg.ChildAdded:Connect(function()task.defer(coordinatePanels)end)]==],
	[==[pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels);pg.ChildAdded:Connect(function()task.defer(coordinatePanels)end)
-- (hud34) on a phone the open Passport covers the bottom of the screen, so while it is open Roblox's tool bar and
-- screenshot bar and the Reset progress button step aside, and come back as they were when it closes
local coverWas=nil
local function phoneCover()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local on=pg:GetAttribute("OpenPanel")=="passport" and UIS.TouchEnabled and math.min(vp.X,vp.Y)<600
 local SG=game:GetService("StarterGui")
 if on and not coverWas then
  coverWas={}
  pcall(function()coverWas.backpack=SG:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack);SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)end)
  pcall(function()coverWas.captures=SG:GetCoreGuiEnabled(Enum.CoreGuiType.Captures);SG:SetCoreGuiEnabled(Enum.CoreGuiType.Captures,false)end)
  local rg=pg:FindFirstChild("ResetGui");if rg then coverWas.reset=rg.Enabled;rg.Enabled=false end
 elseif not on and coverWas then
  local was=coverWas;coverWas=nil
  pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,was.backpack~=false)end)
  pcall(function()SG:SetCoreGuiEnabled(Enum.CoreGuiType.Captures,was.captures~=false)end)
  local rg=pg:FindFirstChild("ResetGui");if rg and was.reset~=nil then rg.Enabled=was.reset end
 end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(phoneCover)]==], "the panel coordinator hook-up"},
})

-- ---------- 2. DecorClient: the Treehouse page scrolls inside the Passport ----------
patch(workspace.Treehouse.DecorClient, {
	{[==[if not decor then return end]==],
	[==[if not decor then return end
-- (hud34, Oct 21 2026; Shannon: on a phone the page "is not scrollable because it overlaps with the icons at the bottom of
-- the screen") everything on the page lives in a scrolling list inside the Passport, styled like the Outings page's;
-- where the page has room (iPad, computer) it never needs to scroll and looks as before
local entries = page:FindFirstChild("Entries")
local list = Instance.new("ScrollingFrame"); list.Name = "DecorList"; list.Size = UDim2.fromScale(1, 1)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = entries and entries.ScrollBarThickness or 3
list.ScrollBarImageColor3 = entries and entries.ScrollBarImageColor3 or C(240, 200, 90)
list.ScrollingDirection = Enum.ScrollingDirection.Y; list.VerticalScrollBarInset = Enum.ScrollBarInset.None
list.ZIndex = 3; list.Active = true; list.Parent = decor]==], "the page check"},
	{[==[	l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 4; l.Parent = decor]==],
	[==[	l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 4; l.Parent = list]==], "the label parent"},
	{[==[row.BorderSizePixel = 0; row.ZIndex = 4; row.Parent = decor]==],
	[==[row.BorderSizePixel = 0; row.ZIndex = 4; row.Parent = list]==], "the row parent"},
	{[==[label("Decor you find or buy out in the game appears here.", 3, 72 + #RUGS * 60 + 8, 460, 16, 12, MUTED, Enum.Font.BuilderSans)]==],
	[==[label("Decor you find or buy out in the game appears here.", 3, 72 + #RUGS * 60 + 8, 460, 16, 12, MUTED, Enum.Font.BuilderSans)
list.CanvasSize = UDim2.fromOffset(0, 72 + #RUGS * 60 + 8 + 16 + 8)   -- (hud34) the list's full height]==], "the footer"},
})

-- ---------- 3. TreehouseClient: the tutorial's "Pick a rug" line scrolls with the rugs ----------
patch(workspace.Treehouse.TreehouseClient, {
	{[==[greet.TextXAlignment = Enum.TextXAlignment.Right; greet.ZIndex = 6; greet.Parent = decorPage]==],
	[==[greet.TextXAlignment = Enum.TextXAlignment.Right; greet.ZIndex = 6
				greet.Parent = decorPage:FindFirstChild("DecorList") or decorPage   -- (hud34) inside the scrolling list, never over a Place button]==], "the greet line"},
})

-- ---------- 4. HintClient: on a computer, Hint on the left under Roblox's buttons ----------
patch(workspace.HintShop.HintClient, {
	{[==[else                                                      -- desktop: in the top row, its bottom level with the Roblox pills
	btn.Position = UDim2.new(0, 222, 0, 14)]==],
	[==[else                                                      -- desktop (hud34, Oct 21 2026; Shannon: "the hint button should go above the
	btn.Position = UDim2.new(0, 12, 0, 64)                    -- baguette button"): on the left under Roblox's buttons, as on a phone]==], "the desktop spot"},
	{[==[note.Position = isMobile and UDim2.new(0, 12, 0, 170) or UDim2.new(0, 222, 0, 62)]==],
	[==[note.Position = UDim2.new(0, 12, 0, 170)]==], "the message spot"},   -- (mid-line: no comment there, it would swallow the rest)
})

-- ---------- 5. ChaseClient: on a computer, the Baguette Chase button just under Hint ----------
patch(workspace.Baguette.ChaseClient, {
	{[==[local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 15); bc.Parent = button]==],
	[==[-- (hud34, Oct 21 2026; Shannon, desktop: "the hint button should go above the baguette button") a computer (and VR):
-- Hint now sits on the left under Roblox's buttons (HintClient), so this button goes just under it, measured from it
if not PHONE then
	task.spawn(function()
		local hg = player:WaitForChild("PlayerGui"):WaitForChild("HintGui", 30)
		local hb = hg and hg:WaitForChild("HintButton", 30)
		if not hb then return end
		local function place()
			if hg.Enabled and hb.Visible and hb.AbsoluteSize.Y > 0 then
				button.Position = UDim2.fromOffset(12, hb.AbsolutePosition.Y + hb.AbsoluteSize.Y + 8)
			else
				button.Position = UDim2.new(0, 12, 0, 58)
			end
		end
		for _, prop in ipairs({"Visible", "AbsolutePosition", "AbsoluteSize"}) do hb:GetPropertyChangedSignal(prop):Connect(place) end
		hg:GetPropertyChangedSignal("Enabled"):Connect(place)
		place()
	end)
end
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 15); bc.Parent = button]==], "the button corner"},
})

-- ---------- 6. BadgeCaseClient: no medal on any device ----------
patch(workspace.BadgeCase.BadgeCaseClient, {
	{[==[local NO_MEDAL = medalUIS.TouchEnabled and not medalUIS.KeyboardEnabled   -- (the same touch test HintClient uses)]==],
	[==[local NO_MEDAL = true   -- (hud34, Oct 21 2026; Shannon: "just get rid of the medal completely") every device; the title pill opens the case]==], "the medal switch"},
})

-- every check passed: back up, then write
for _, j in ipairs(jobs) do
	local bk = j.script:Clone(); bk.Name = j.script.Name .. "_pre_hud34"; bk.Enabled = false; bk.Parent = backup
end
local out = {}
for _, j in ipairs(jobs) do
	SES:UpdateSourceAsync(j.script, function() return j.src end)
	table.insert(out, string.format("%s -> %d chars", j.script.Name, #j.script.Source))
end
print("hud34: " .. table.concat(out, "; "))
return "hud34 installed: " .. table.concat(out, "; ")
