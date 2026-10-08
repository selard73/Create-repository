-- prepublish9.lua v2 (EDIT mode): v551 + the Sandstone Climb (clock, bell, summit board, Sunny Skies, solid bell, cliff camera)
-- + the hang glider (Acorn Store row, ramp, flight, sunburst sail, stays where it lands) + the Chapelier hat store + the
-- basket lift + the Sep 27 morning fixes; read only
if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end
local ok, err = pcall(function()
	local function has(inst, marker) return inst ~= nil and inst:IsA("LuaSourceContainer") and inst.Source:find(marker, 1, true) ~= nil end
	local RSx, SSx, CS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage"), game:GetService("CollectionService")
	local tool = SSx:FindFirstChild("SlingshotTool")
	local L, H = workspace.Lagoon, workspace.Hoop
	local sp = workspace.ForestRace:FindFirstChild("StartPrompt", true)
	local gateOnce = false
	for _, b in ipairs(workspace:GetChildren()) do if b.Name == "Boundary" and b:FindFirstChild("GateClient") then gateOnce = has(b.GateClient, "local told = (open == true)") end end
	local CL, G, HS, Shop = workspace:FindFirstChild("SandstoneClimb"), workspace:FindFirstChild("HangGlider"), workspace:FindFirstChild("HatShop"), workspace.Shop
	local bell = CL and CL:FindFirstChild("Summit") and CL.Summit:FindFirstChild("Bell")
	local solid = bell and bell:FindFirstChild("Solid")
	local MM = workspace:FindFirstChild("MapMusic")
	local kit = RSx:FindFirstChild("HatKit")
	local hatPieces = 0
	for _, p in ipairs(kit and kit:GetChildren() or {}) do if p:IsA("MeshPart") then hatPieces += 1 end end
	local prices = 0
	for _, s in ipairs({"top", "boater", "cloche", "sun", "bowler", "fedora", "beret"}) do if HS and type(HS:GetAttribute("Price_" .. s)) == "number" then prices += 1 end end
	local swBox = false
	for _, m in ipairs(CL and CL:GetDescendants() or {}) do
		if m:IsA("Model") and m.Name == "boxwood" then local cf = m:GetBoundingBox(); if (Vector3.new(cf.X, 0, cf.Z) - Vector3.new(485.5, 0, -254.5)).Magnitude < 2 then swBox = true end end
	end
	local sail = SSx:FindFirstChild("GliderKit") and SSx.GliderKit:FindFirstChild("GliderSail")
	local LF = workspace:FindFirstChild("BasketLift")
	local checks = {
		-- what v551 had
		{"statue", has(workspace.Champion:FindFirstChild("ChampionServer"), "local function standOn")},
		{"goldpill", has(workspace.Daily:FindFirstChild("DailyClient"), "you don't even need that")},
		{"restS", has(H:FindFirstChild("SlingServer"), "at the croc and the hoops alike")},
		{"restC", has(tool and tool:FindFirstChild("SlingClient"), "at the croc and the hoops - the server counts")},
		{"promptHead", has(workspace.PromptUI:FindFirstChild("PromptClient"), "NEXT TO YOU ON A PHONE")},
		{"promptClear", has(workspace.PromptUI:FindFirstChild("PromptClient"), "NOTHING OVERLAPS ON A PHONE")},
		{"arrow", has(workspace.DailyQuestion:FindFirstChild("QuestionClient"), "THE ARROW IS REAL NEON")},
		{"qnote", has(workspace.DailyQuestion:FindFirstChild("QuestionClient"), "the note finds a clear place")},
		{"reset", has(workspace.ResetUI:FindFirstChild("ResetClient"), "as far below the circle as the screen allows")},
		{"chaseBtn", has(workspace.Baguette:FindFirstChild("ChaseClient"), "move it down very, very slightly")},
		{"crocOuch", has(L:FindFirstChild("CrocClient"), "OuchSound")},
		{"portrait", has(workspace.PortraitGallery:FindFirstChild("PortraitServer"), "local function owed")},
		{"racePhone", sp ~= nil and sp:GetAttribute("PhoneSpot") == "sign" and typeof(sp:GetAttribute("PhoneAnchor")) == "Vector3"},
		{"keeperHall", has(workspace.Champion:FindFirstChild("ChampionServer"), "local function hallAppend")},
		{"gateOnce", gateOnce},
		{"fountainShared", has(workspace.FountainColour:FindFirstChild("FountainClient"), "F:GetAttribute(\"ActiveColour\")")},
		{"shopTaken", has(Shop:FindFirstChild("ShopServer"), "local function fountainTaken")},
		{"hallServer", workspace:FindFirstChild("HallOfFame") ~= nil and has(workspace.HallOfFame:FindFirstChild("HallServer"), "local function build(no)")},
		{"hudReset", has(workspace.HudBarUI:FindFirstChild("HudBarClient"), "local function hookHud")},
		{"sageServer", has(workspace.Honours:FindFirstChild("TitleServer"), 'title = "Squirrel Sage"')},
		{"lateMsg", has(workspace.Champion:FindFirstChild("ChampionClient"), "Today's statue is already")},
		-- the Sandstone Climb
		{"climbServer", CL ~= nil and has(CL:FindFirstChild("ClimbServer"), "local function ring(player)")},
		{"climbClient", CL ~= nil and has(CL:FindFirstChild("ClimbClient"), "local function ringBell()")},
		{"climbBoard", CL ~= nil and CL:FindFirstChild("ClimbBoard") ~= nil},
		{"climbEvent", RSx:FindFirstChild("ClimbEvent") ~= nil},
		{"bellSolid", solid ~= nil and solid.CanCollide == true and solid.Transparency == 1 and bell.Body.CanCollide == false},
		{"climbMusic", MM ~= nil and MM:GetAttribute("climb") == "139858799423522" and has(MM:FindFirstChild("MusicClient"), 'GetAttribute("Climbing")')},
		{"noSWBoxwood", not swBox},
		-- the hang glider
		{"gliderServer", G ~= nil and has(G:FindFirstChild("GliderServer"), "local function buildGlider")},
		{"gliderClient", G ~= nil and has(G:FindFirstChild("GliderClient"), "local function fly(") and has(G.GliderClient, "UDim2.new(0.5, 0, 1, -84)")},
		{"gliderRamp", G ~= nil and G:FindFirstChild("Ramp") ~= nil and G:FindFirstChild("TakeOff", true) ~= nil and G:GetAttribute("Sink") == 7},
		{"gliderKit", sail ~= nil and sail.TextureID ~= "" and sail.MeshId ~= ""},
		{"gliderEvent", RSx:FindFirstChild("GliderEvent") ~= nil},
		{"shopGlider", has(Shop:FindFirstChild("ShopServer"), 'glider     = {once = true, needsArea = "village"}') and has(Shop:FindFirstChild("ShopClient"), '{id = "glider"')
			and Shop:GetAttribute("Price_glider") == 1000 and Shop:GetAttribute("Sell_glider") == true},
		{"shopOpenAt", has(Shop:FindFirstChild("ShopClient"), "OPEN AT A ROW") and Shop:FindFirstChild("OpenAt") ~= nil},
		-- the Chapelier
		{"hatServer", HS ~= nil and has(HS:FindFirstChild("HatServer"), "local function dress(player)")},
		{"hatClient", HS ~= nil and has(HS:FindFirstChild("HatClient"), "HatMirrorStay") and not has(HS.HatClient, 'WaitForChild("PlayerModule")')},
		{"hatKit", hatPieces == 14 and kit:FindFirstChild("Catalogue") ~= nil},
		{"hatRoom", HS ~= nil and HS:FindFirstChild("Room") ~= nil and CS:HasTag(HS.Room, "SkyRoom") and typeof(HS.Room:GetAttribute("BoxCF")) == "CFrame"},
		{"hatRemotes", RSx:FindFirstChild("HatShopAction") ~= nil and RSx:FindFirstChild("HatShopEvent") ~= nil},
		{"hatPrices", prices == 7},
		-- Sep 27 (day): the sunburst sail, the glider staying where it lands, the basket lift, the morning fixes
		{"sailSunburst", sail ~= nil and sail.MeshId == "rbxassetid://76624547434738" and sail.TextureID == "rbxassetid://86534433563529"
			and math.abs(sail.Size.X - 13.2) < 0.01 and math.abs(sail.Size.Z - 7.2) < 0.01},
		{"gliderSettle", G ~= nil and has(G:FindFirstChild("GliderServer"), "local function settle(") and has(G.GliderServer, "local function restPose(")
			and has(G.GliderServer, "Vector3.new(0, 0.2564, -1.4)")},
		{"gliderClientLanded", G ~= nil and has(G:FindFirstChild("GliderClient"), "local function watchLanded(") and has(G.GliderClient, 'ev:FireServer("done", how, heading, v, hrp.CFrame)')
			and has(G:FindFirstChild("GliderServer"), "ModelStreamingMode.Persistent")},
		{"gliderLanded", G ~= nil and G:FindFirstChild("Landed") ~= nil and #G.Landed:GetChildren() == 0 and G:GetAttribute("LingerSeconds") == 20},
		{"gliderDisplay", G ~= nil and G:FindFirstChild("Display") ~= nil and (function()
			local m = G.Display:FindFirstChildWhichIsA("MeshPart"); return m ~= nil and sail ~= nil and m.MeshId == sail.MeshId and m.TextureID == sail.TextureID end)()},
		{"liftScripts", LF ~= nil and has(LF:FindFirstChild("LiftServer"), "local function backUp(") and has(LF:FindFirstChild("LiftClient"), "local function watchReturn(")},
		{"liftParts", LF ~= nil and LF:FindFirstChild("Hoist") ~= nil and LF:FindFirstChild("Basket") ~= nil and LF.Basket:FindFirstChild("Floor") ~= nil
			and LF.Basket.Floor:FindFirstChild("RideDown") ~= nil and LF.Basket.Floor.RideDown.Enabled == true},
		{"liftAtTop", LF ~= nil and LF:GetAttribute("Busy") == false and CL ~= nil and math.abs(LF.Basket:GetPivot().Position.Y - CL:GetAttribute("SummitY")) < 0.05
			and LF.Basket.Floor.Anchored == true and LF.Basket.Floor.CanCollide == true and LF.Basket:GetAttribute("T0") == nil},
		{"liftEvent", RSx:FindFirstChild("LiftEvent") ~= nil and LF ~= nil and type(LF:GetAttribute("HopX")) == "number" and math.abs((LF:GetAttribute("Drop") or 0) - 68.72) < 0.1},
		{"cliffCamera", CL ~= nil and has(CL:FindFirstChild("CliffCamera"), 'BindToRenderStep("CliffCamera"')},
		{"noStrayWing", workspace:FindFirstChild("Wing") == nil},
		{"squirrelsSolid", (function()
			local n = 0
			for _, root in ipairs({workspace, game:GetService("ServerScriptService")}) do
				for _, sc in ipairs(root:GetDescendants()) do
					if sc:IsA("Script") and sc.Source:find("p.Anchored = true; p.CanCollide = false; p.CanTouch = true", 1, true) then return false end
					if sc:IsA("Script") and sc.Source:find("p.Anchored = true; p.CanCollide = true; p.CanTouch = true", 1, true) then n += 1 end
				end
			end
			return n > 0 end)()},
		{"bollardsMoved", (function()
			for _, m in ipairs(workspace.Village.Props:GetChildren()) do
				if m.Name == "bollards" and m:IsA("Model") then local cf = m:GetBoundingBox(); if math.abs(cf.Z + 104.8) < 0.6 and math.abs(cf.X - 170.4) < 0.3 then return true end end
			end
			return false end)()},
	}
	local out, bad = {}, {}
	for _, c in ipairs(checks) do table.insert(out, c[1] .. "=" .. tostring(c[2] == true)); if c[2] ~= true then table.insert(bad, c[1]) end end
	warn("QQ PREPUB9 - " .. #checks - #bad .. "/" .. #checks .. " true" .. (#bad > 0 and (" | FALSE: " .. table.concat(bad, ", ")) or ""))
	warn("QQ PREPUB9 all - " .. table.concat(out, ", "))
	-- strays: test and import leftovers
	local stray = {}
	for _, c in ipairs(workspace:GetChildren()) do
		local n = c.Name
		if n == "ShotAcorn" or n == "SlingDraw_local" or n == "CanvasTest" or n == "Glider" or n == "Hats" or n == "SandCliff" or n == "HatPreview" or n == "WornHat"
			or n:find("^QQ") or n:lower():find("probe") then table.insert(stray, n) end
	end
	local chars = {}
	for _, m in ipairs(workspace:GetChildren()) do if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and game.Players:GetPlayerFromCharacter(m) == nil and m.Name ~= "Figure" then table.insert(chars, m.Name) end end
	local rt = {}
	if workspace:FindFirstChild("HallView_local") then table.insert(rt, "HallView_local") end
	if RSx:FindFirstChild("HallStatues") then table.insert(rt, "RS.HallStatues") end
	if workspace.Champion:GetAttribute("HallJson") then table.insert(rt, "Champion.HallJson") end
	for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "HangGlider" and d:IsA("Model") and d.Parent ~= workspace then table.insert(rt, d:GetFullName()) end end
	warn("QQ PREPUB9 - strays: " .. (#stray > 0 and table.concat(stray, ", ") or "none") .. " | loose characters: " .. (#chars > 0 and table.concat(chars, ", ") or "none")
		.. " | runtime leftovers: " .. (#rt > 0 and table.concat(rt, ", ") or "none") .. " | fountain ActiveColour " .. tostring(workspace.FountainColour:GetAttribute("ActiveColour")))
	-- anything unanchored outside a character (the pigeon wing that fell was one)
	local loose = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and not d.Anchored and not d:FindFirstAncestorWhichIsA("Tool") then
			local m = d:FindFirstAncestorWhichIsA("Model")
			local isChar = false
			while m do if m:FindFirstChildOfClass("Humanoid") then isChar = true break end; m = m.Parent and m.Parent:FindFirstAncestorWhichIsA("Model") end
			if not isChar then table.insert(loose, d:GetFullName()) end
		end
	end
	warn("QQ PREPUB9 - unanchored (outside characters): " .. #loose .. (#loose > 0 and (" | " .. table.concat(loose, ", ", 1, math.min(#loose, 12))) or ""))
	workspace.CurrentCamera.FieldOfView = 70
end)
if not ok then warn("QQ PREPUB9 FAILED - " .. tostring(err)) end
-- (padding so the command bar keeps its height)
