-- rugs4 (Oct 21 2026): the REAL mini tutorial (Shannon: "is this what you consider a tutorial? that is not what I
-- wanted" / "it should be when you climb into the treehouse for the first time"). The rugs1-3 one-toast tip is
-- replaced by a guided chain, previewed and approved in a play test:
--   first climb into the finished room -> welcome note + the Passport button glows -> Passport open -> the
--   Treehouse tab glows -> tab open -> "Pick a rug for your floor!" + the Place buttons pulse -> first rug placed
--   -> sparkles on the rug + "Looks lovely in here!". Each step advances only when the player does it; left
--   half-way it re-arms on the next climb (after leaving the room), session after session, until the first rug is
--   down. DecorServer marks Item_tree_decortip on that first place - placing a rug any other way counts too, so the
--   chain never nags someone who found the tab alone. A treehouse reset claws the flag, re-arming it on purpose.
-- Run in Studio EDIT. Backs TreehouseClient + DecorServer up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")

-- ---------- 1. TreehouseClient: the tip block becomes the chain ----------
local tc = workspace.Treehouse.TreehouseClient
local src = tc.Source
assert(not src:find("rugs4", 1, true), "TreehouseClient already patched")
local header = "\n-- THE FIRST-BUILD DECOR TIP"
local a = src:find(header, 1, true)
assert(a, "TreehouseClient: tip block header not found - nothing changed")
assert(not src:find(header, a + 1, true), "TreehouseClient: tip header found twice - nothing changed")
local chain = [==[

-- THE FIRST-CLIMB DECOR TUTORIAL (rugs4, Oct 21 2026; Shannon: a toast "is not what I wanted" - "it should be when
-- you climb into the treehouse for the first time"): once the house is done, the FIRST climb into the room starts a
-- guided chain to the first rug: a welcome note + the Passport button glows -> Passport open -> the Treehouse tab
-- glows -> tab open -> "Pick a rug for your floor!" + the Place buttons pulse -> first rug placed -> sparkles on
-- the rug + a last word. Left half-way, it re-arms on the next climb until the first rug is down; DecorServer sets
-- Item_tree_decortip on that first place, and a treehouse reset claws it to re-arm the whole thing on purpose.
task.spawn(function()
	local t0 = os.clock()
	while player:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
	local act = RS:WaitForChild("DecorAction", 30)
	if not act then return end
	local function flag() return (tonumber(player:GetAttribute("Item_tree_decortip")) or 0) >= 1 end
	local function built() return (tonumber(player:GetAttribute("Item_tree_done")) or 0) >= 1 end
	local function inRoom()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return false end
		local l = base:PointToObjectSpace(root.Position)
		return math.abs(l.X) < 9.5 and math.abs(l.Z) < 9.5 and l.Y > 10 and l.Y < 20
	end
	local function say(txt, secs)
		local tg = Instance.new("ScreenGui"); tg.Name = "DecorTut"; tg.ResetOnSpawn = false; tg.DisplayOrder = 8; tg.Parent = pg
		local n = Instance.new("TextLabel"); n.AnchorPoint = Vector2.new(0.5, 1); n.Position = UDim2.new(0.5, 0, 1, -118)
		n.Size = UDim2.fromOffset(470, 44); n.BackgroundColor3 = NAVY; n.BackgroundTransparency = 0.1
		n.Font = FONT; n.TextSize = 16; n.TextColor3 = GOLD; n.TextWrapped = true; n.Text = txt; n.Parent = tg
		local nc2 = Instance.new("UICorner"); nc2.CornerRadius = UDim.new(0, 14); nc2.Parent = n
		local ns2 = Instance.new("UIStroke"); ns2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ns2.Color = GOLD; ns2.Thickness = 2; ns2.Parent = n
		Debris:AddItem(tg, secs or 7)
	end
	local function glowOn(obj)
		local g = Instance.new("UIStroke"); g.Name = "DecorTutGlow"; g.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		g.Color = C(255, 222, 120); g.Thickness = 3.5; g.Parent = obj
		task.spawn(function()
			while g.Parent do
				TweenService:Create(g, TweenInfo.new(0.6), {Transparency = 0.65}):Play(); task.wait(0.65)
				if not g.Parent then break end
				TweenService:Create(g, TweenInfo.new(0.6), {Transparency = 0}):Play(); task.wait(0.65)
			end
		end)
		return g
	end
	local function passportButton()
		for _, g in ipairs(pg:GetChildren()) do
			if g:IsA("ScreenGui") and g.Enabled then
				for _, d in ipairs(g:GetDescendants()) do
					if d:IsA("TextLabel") and d.Text == "Passport" and d.Visible then return d.Parent end
				end
			end
		end
	end
	local function waitFor(cond, secs)                     -- true when cond met; false on a timeout or once the flag is in
		local t1 = os.clock()
		while os.clock() - t1 < secs do
			if flag() then return false end
			if cond() then return true end
			task.wait(0.3)
		end
		return false
	end
	while not flag() do
		while not flag() and not (built() and inRoom()) do task.wait(0.5) end
		if flag() then break end
		say("Welcome home! You can decorate this place - open your Passport.", 10)
		local pb = passportButton()
		local g1 = pb and glowOn(pb)
		local opened = waitFor(function() return pg:GetAttribute("OpenPanel") == "passport" end, 120)
		if g1 then g1:Destroy() end
		if opened then
			local pGui = pg:FindFirstChild("PassportGui")
			local panel = pGui and pGui:FindFirstChild("Page", true)
			local tab = panel and panel:FindFirstChild("Treehouse")
			local decorPage = panel and panel:FindFirstChild("DecorContent")
			local g2 = (tab and tab.Visible) and glowOn(tab) or nil
			local onTab = waitFor(function() return decorPage ~= nil and decorPage.Visible end, 120)
			if g2 then g2:Destroy() end
			if onTab then
				local greet = Instance.new("TextLabel"); greet.Name = "DecorTutGreet"; greet.AnchorPoint = Vector2.new(1, 0)
				greet.Position = UDim2.new(1, -6, 0, 0); greet.Size = UDim2.fromOffset(240, 20); greet.BackgroundTransparency = 1
				greet.Font = FONT; greet.TextSize = 15; greet.TextColor3 = C(64, 112, 48); greet.Text = "Pick a rug for your floor!"
				greet.TextXAlignment = Enum.TextXAlignment.Right; greet.ZIndex = 6; greet.Parent = decorPage
				local pulses = {}
				for _, d in ipairs(decorPage:GetDescendants()) do
					if d:IsA("TextButton") and d.Text == "Place" then table.insert(pulses, glowOn(d)) end
				end
				waitFor(function() return false end, 180)      -- the flag itself ends this wait (the first rug placed)
				for _, g in ipairs(pulses) do g:Destroy() end
				greet:Destroy()
			end
		end
		if flag() then
			local lf = workspace:FindFirstChild("Treehouse_local")
			local lh = lf and lf:FindFirstChild("House")
			local rugPart = lh and lh:FindFirstChild("HomebaseRug")
			if rugPart and rugPart.Transparency < 1 then
				local att = Instance.new("Attachment"); att.Parent = rugPart
				local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				pe.Rate = 0; pe.Lifetime = NumberRange.new(0.8, 1.4); pe.Speed = NumberRange.new(3, 6)
				pe.SpreadAngle = Vector2.new(180, 180); pe.Color = ColorSequence.new(C(255, 222, 120))
				pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
				pe.Parent = att
				pe:Emit(40)
				Debris:AddItem(att, 3)
			end
			say("Looks lovely in here! Swap or store your rugs any time.", 7)
			break
		end
		task.wait(2)
		while not flag() and inRoom() do task.wait(1) end   -- half-done: re-arm only after they leave the room
	end
end)
]==]
local out = src:sub(1, a - 1) .. chain
local bk1 = tc:Clone(); bk1.Name = "TreehouseClient_pre_rugs4"; bk1.Enabled = false; bk1.Parent = backup
SES:UpdateSourceAsync(tc, function() return out end)
print(string.format("rugs4 part 1: TreehouseClient -> %d chars", #tc.Source))

-- ---------- 2. DecorServer: the first place marks the tutorial done ----------
local ds = workspace.Treehouse.DecorServer
local old2 = [=[		clearFloor(p)
		if id ~= "red" then award:Fire(p, "rugon_" .. id, 1) end   -- red is the default; it needs no line
		return true]=]
local new2 = [=[		clearFloor(p)
		if id ~= "red" then award:Fire(p, "rugon_" .. id, 1) end   -- red is the default; it needs no line
		if (tonumber(p:GetAttribute("Item_tree_done")) or 0) >= 1 and (tonumber(p:GetAttribute("Item_tree_decortip")) or 0) < 1 then
			award:Fire(p, "tree_decortip", 1)                      -- (rugs4) the first rug placed = the tutorial's job done
		end
		return true]=]
local src2 = ds.Source
local c, d = src2:find(old2, 1, true)
assert(c, "DecorServer: place block not found - nothing changed")
assert(not src2:find(old2, d + 1, true), "DecorServer: place block found twice - nothing changed")
local out2 = src2:sub(1, c - 1) .. new2 .. src2:sub(d + 1)
local bk2 = ds:Clone(); bk2.Name = "DecorServer_pre_rugs4"; bk2.Enabled = false; bk2.Parent = backup
SES:UpdateSourceAsync(ds, function() return out2 end)
print(string.format("rugs4 part 2: DecorServer -> %d chars", #ds.Source))
return "rugs4 installed"
