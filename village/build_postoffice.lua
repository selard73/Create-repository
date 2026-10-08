-- La Poste: letters to the dev. Shannon: "you can mail the dev a note at the post office for so many acorns and in
-- about 24 hours, you check back at the post office and the dev has mailed you a personalized note back".
--
-- A yellow post box on the pavement outside LA POSTE (Rue de Noisette) with a prompt. Open it and you can write a
-- note (up to MaxChars) and send it for Price acorns; one letter out at a time. The note goes through Roblox's text
-- filter and into the "PostOffice_v1" DataStore (u<userId> = {letter, reply, state}, plus a "pending" list of who is
-- waiting). Shannon (DevIds) opens the same box and gets the dev desk: every waiting letter with a reply box. Her
-- reply is filtered, saved, and the writer is told - a toast if they are online, else the moment they next join
-- ("There is a letter for you at the post office") - and reads it at the box. Replies take however long she takes;
-- the box says "about a day".
--
-- Acorns move the way every spend does: AwardAcorns (negative) for SquirrelSetup's ledger plus the attribute for the
-- screen. Nothing else here touches the squirrel save. In Studio with API access off the store cannot be read or
-- written, so records live in memory for the session (enough to test both sides on one account).
-- Run in edit mode (re-runnable). Attributes on workspace.PostOffice: Price (30), MaxChars (240), DevIds, Open.
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local C = Color3.fromRGB
	local PO = workspace:FindFirstChild("PostOffice")
	if not PO then PO = Instance.new("Folder"); PO.Name = "PostOffice"; PO.Parent = workspace end
	if PO:GetAttribute("Price") == nil or opts.price then PO:SetAttribute("Price", opts.price or 30) end
	if PO:GetAttribute("MaxChars") == nil then PO:SetAttribute("MaxChars", 240) end
	if PO:GetAttribute("DevIds") == nil or opts.devIds then PO:SetAttribute("DevIds", opts.devIds or "9611145467") end
	if PO:GetAttribute("Open") == nil then PO:SetAttribute("Open", true) end
	if not PO:FindFirstChild("PostAction") then local f = Instance.new("RemoteFunction"); f.Name = "PostAction"; f.Parent = PO end
	if not PO:FindFirstChild("PostNotify") then local e = Instance.new("RemoteEvent"); e.Name = "PostNotify"; e.Parent = PO end
	for _, n in ipairs({"PostBox", "PostServer", "PostClient"}) do local o = PO:FindFirstChild(n); if o then o:Destroy() end end

	-- ---- the post box, on the pavement to the right of LA POSTE's door, facing the street
	local at = opts.at or Vector3.new(189.6, 0.5, -137.5)            -- ground point on the south sidewalk (y 0.5), back against the shop front
	local facing = opts.facing or Vector3.new(0, 0, 1)                 -- the door looks -z into the shop; the street is +z
	local box = Instance.new("Model"); box.Name = "PostBox"
	local YELLOW, YELLOW_DEEP, NAVY, SLOT = C(255, 205, 40), C(214, 166, 20), C(30, 50, 100), C(40, 36, 30)
	local base = CFrame.lookAt(at, at + facing)                        -- LookVector = facing: the front of every part faces the street
	local function part(name, size, cf, colour, material)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true; p.Parent = box
		return p
	end
	part("Post", Vector3.new(0.5, 1.6, 0.5), base * CFrame.new(0, 0.8, 0), NAVY, Enum.Material.Metal)
	local body = part("Body", Vector3.new(1.7, 1.7, 1.1), base * CFrame.new(0, 2.45, 0), YELLOW)
	part("Lid", Vector3.new(1.9, 0.22, 1.3), base * CFrame.new(0, 3.4, 0), YELLOW_DEEP)
	part("Band", Vector3.new(1.74, 0.16, 1.14), base * CFrame.new(0, 1.7, 0), NAVY)
	local slot = part("Slot", Vector3.new(1.1, 0.14, 0.08), base * CFrame.new(0, 2.95, -0.56), SLOT); slot.CanCollide = false
	local face = part("Face", Vector3.new(1.4, 0.7, 0.04), base * CFrame.new(0, 2.25, -0.57), YELLOW); face.CanCollide = false
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 100; sg.Parent = face
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 0.55); t.BackgroundTransparency = 1; t.Font = Enum.Font.FredokaOne
	t.TextScaled = true; t.TextColor3 = NAVY; t.Text = "LA POSTE"; t.Parent = sg
	local t2 = Instance.new("TextLabel"); t2.Size = UDim2.fromScale(1, 0.4); t2.Position = UDim2.fromScale(0, 0.58); t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.FredokaOne; t2.TextScaled = true; t2.TextColor3 = NAVY; t2.Text = "letters to the dev"; t2.Parent = sg
	local prompt = Instance.new("ProximityPrompt"); prompt.Name = "PostPrompt"; prompt.ActionText = "Open"; prompt.ObjectText = "La Poste - write to the dev"
	prompt.KeyboardKeyCode = Enum.KeyCode.E; prompt.MaxActivationDistance = 9; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Default; prompt.Parent = body
	box.PrimaryPart = body
	box.Parent = PO

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[
-- PostServer: the letters (send / status / read) and the dev desk (list / reply); the DataStore, the text filter, the purse
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local PO = script.Parent
local action = PO:WaitForChild("PostAction")
local notify = PO:WaitForChild("PostNotify")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local store
do
	local ok, err = pcall(function() store = DataStoreService:GetDataStore("PostOffice_v1") end)
	if not ok then warn("PostOffice: no store (" .. tostring(err) .. "); letters live in memory this session") end
end
local records = {}                                            -- uid -> record: {letter = {text, t, name, user}, reply = {text, t, by}, state}
local pending                                                 -- list of uids with a letter waiting (mirror of the "pending" key)
local storeDown = false

local function devs()
	local set = {}
	for id in string.gmatch(tostring(PO:GetAttribute("DevIds") or ""), "%d+") do set[tonumber(id)] = true end
	return set
end
local function isDev(player) return devs()[player.UserId] == true end
local function firstDev() for id in pairs(devs()) do return id end return 0 end

local function load(uid)
	if records[uid] then return records[uid] end
	local rec
	if store then
		local ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
		if ok then if type(data) == "table" then rec = data end
		else if not storeDown then warn("PostOffice: could not read the store (" .. tostring(data) .. ")"); storeDown = true end end
	end
	rec = rec or {}
	records[uid] = rec
	return rec
end
-- A store call, tried up to three times a second apart; true once it goes through. In Studio with API access off the
-- store refuses everything and the records simply live in memory for the session, so there it counts as done.
local function tryStore(what, fn)
	if not store then return RunService:IsStudio() end
	for i = 1, 3 do
		local ok, err = pcall(fn)
		if ok then return true end
		if RunService:IsStudio() then return true end
		warn("PostOffice: could not " .. what .. " (" .. tostring(err) .. ")" .. (i < 3 and " - trying again" or " - giving up"))
		if i < 3 then task.wait(1) end
	end
	return false
end
local function save(uid, rec)
	records[uid] = rec
	return tryStore("save u" .. uid, function() store:SetAsync("u" .. uid, rec) end)
end
-- the waiting list: this server's copy (read from the store the first time) ...
local function withPending()
	if pending == nil then
		pending = {}
		if store then
			local ok, data = pcall(function() return store:GetAsync("pending") end)
			if ok and type(data) == "table" then pending = data end
		end
	end
	return pending
end
-- ... and a change to it, made to the copy and to the store; true if the store took it
local function updatePending(fn)
	pending = fn(withPending()) or pending
	return tryStore("update the waiting list", function()
		store:UpdateAsync("pending", function(old) return fn(type(old) == "table" and old or {}) end)
	end)
end
local function addPending(uid) return function(list) for _, u in ipairs(list) do if u == uid then return list end end; table.insert(list, uid); return list end end
local function dropPending(uid) return function(list) local out = {} for _, u in ipairs(list) do if u ~= uid then table.insert(out, u) end end return out end end
-- FRESH READS. A server used to read a record or the waiting list once and trust its copy from then on, so a letter
-- posted in another server never showed on this server's dev desk, and a reply written in another server never
-- reached someone whose record this server had already read (even after they left and came back to it). Now the
-- box, the desk and a reply read the store each time; the copy is only the fallback when the store does not answer.
local function fresh(uid)
	if store then
		local ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
		if ok and type(data) == "table" then records[uid] = data end
	end
	return load(uid)
end
local function freshPending()
	if store then
		local ok, data = pcall(function() return store:GetAsync("pending") end)
		if ok and type(data) == "table" then pending = data end
	end
	return withPending()
end

-- Roblox's filter. For ONE known reader when that reader is in this server; otherwise - the usual case: the dev is
-- rarely in the writer's server, and a writer is rarely still here when the dev answers - the version that is safe
-- for anyone to read. (The first version always filtered for the reader, and Roblox only does that for someone
-- connected to the same server, so on the live game every letter came back "could not read that" - Shannon, on her
-- second account on her phone: "I tried to send it and it would not send".) The raw text is kept only in Studio,
-- where the filter will not answer.
local function filtered(text, fromUid, toUid)
	local ok, res = pcall(function()
		local obj = TextService:FilterStringAsync(text, fromUid)
		if toUid and Players:GetPlayerByUserId(toUid) then
			local ok2, one = pcall(function() return obj:GetNonChatStringForUserAsync(toUid) end)
			if ok2 then return one end
		end
		return obj:GetNonChatStringForBroadcastAsync()
	end)
	if ok then return res end
	if RunService:IsStudio() then return text end
	warn("PostOffice: the filter did not answer (" .. tostring(res) .. ")")
	return nil
end
local function trimmed(text)
	text = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
	return text
end
local function view(player, rec)
	return {
		price = PO:GetAttribute("Price") or 30, max = PO:GetAttribute("MaxChars") or 240, open = PO:GetAttribute("Open") ~= false,
		state = rec.state, letter = rec.letter and rec.letter.text, sentAt = rec.letter and rec.letter.t,
		reply = rec.reply and rec.reply.text, repliedAt = rec.reply and rec.reply.t, by = rec.reply and rec.reply.by,
		dev = isDev(player), acorns = player:GetAttribute("Acorns") or 0,
	}
end
-- a dev in this server hears about a new letter at once; one elsewhere hears the moment she next joins (onJoin)
local function tellDevs(from)
	for _, p in ipairs(Players:GetPlayers()) do
		if isDev(p) and p ~= from then
			p:SetAttribute("LettersWaiting", (p:GetAttribute("LettersWaiting") or 0) + 1)
			notify:FireClient(p, "A new letter from " .. from.DisplayName .. " is waiting at La Poste!")
		end
	end
end
local busy = {}
local function handle(player, kind, a, b)
	local uid = player.UserId
	if kind == "status" then return true, view(player, fresh(uid)) end
	if kind == "send" then
		if PO:GetAttribute("Open") == false then return false, "the post office is closed" end
		if type(a) ~= "string" then return false, "write something first" end
		local text = trimmed(a)
		local max = PO:GetAttribute("MaxChars") or 240
		if #text == 0 then return false, "write something first" end
		if #text > max then return false, "too long - " .. max .. " letters at most" end
		local rec = load(uid)
		if rec.state == "sent" then return false, "your letter is still with the dev" end
		local price = PO:GetAttribute("Price") or 30
		local have = player:GetAttribute("Acorns") or 0
		if have < price then return false, "not enough acorns" end
		local clean = filtered(text, uid, firstDev())
		if not clean then return false, "the post office could not read that; try again in a moment" end
		-- NOTHING IS CHARGED UNTIL THE LETTER IS SAFE IN THE STORE. Shannon: "I just want to make sure I get messages if any
		-- user sends one". It used to take the acorns first and save after, ignoring a failed save, so a hiccup in the
		-- store could lose a letter its writer had paid for and been told was posted. Now: onto the waiting list first (a
		-- name on the list with no letter behind it is simply skipped by the desk), then the letter, each tried three
		-- times; if either fails the writer is told to try again and nothing is taken.
		local SORRY = "the post office could not send that just now - try again in a minute (no acorns taken)"
		if not updatePending(addPending(uid)) then return false, SORRY end
		local before = {letter = rec.letter, reply = rec.reply, state = rec.state}
		rec.letter = {text = clean, t = os.time(), name = player.DisplayName, user = player.Name}
		rec.reply = nil
		rec.state = "sent"
		if not save(uid, rec) then
			rec.letter, rec.reply, rec.state = before.letter, before.reply, before.state
			return false, SORRY
		end
		awardAcorns:Fire(player, -price)                       -- the stamp: a negative award, same ledger as every spend
		player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or have) - price)
		player:SetAttribute("MailWaiting", false)
		print(string.format("PostOffice: %s posted a letter (%d chars)", player.Name, #clean))
		tellDevs(player)
		return true, view(player, rec)
	end
	if kind == "read" then
		local rec = load(uid)
		if rec.state == "answered" then rec.state = "read"; save(uid, rec) end
		player:SetAttribute("MailWaiting", false)
		return true, view(player, rec)
	end
	if not isDev(player) then return false, "not for you" end
	if kind == "list" then
		local out = {}
		for _, u in ipairs(freshPending()) do
			local rec = fresh(u)
			if rec.state == "sent" and rec.letter then
				table.insert(out, {uid = u, name = rec.letter.name or "?", user = rec.letter.user or "?", text = rec.letter.text, t = rec.letter.t})
			end
			if #out >= 60 then break end
		end
		table.sort(out, function(x, y) return (x.t or 0) < (y.t or 0) end)
		player:SetAttribute("LettersWaiting", #out)
		return true, out
	end
	if kind == "reply" then
		local toUid, text = tonumber(a), (type(b) == "string") and trimmed(b) or ""
		if not toUid then return false, "who to?" end
		if #text == 0 then return false, "write the reply first" end
		if #text > 1000 then return false, "too long" end
		local rec = fresh(toUid)
		if not rec.letter then return false, "no letter from them" end
		local clean = filtered(text, uid, toUid)
		if not clean then return false, "the filter did not answer; try again" end
		local before = {reply = rec.reply, state = rec.state}
		rec.reply = {text = clean, t = os.time(), by = player.DisplayName}
		rec.state = "answered"
		if not save(toUid, rec) then
			rec.reply, rec.state = before.reply, before.state
			return false, "the store did not take that - try again in a minute"
		end
		updatePending(dropPending(toUid))                    -- if this fails the desk skips it anyway: it is answered
		player:SetAttribute("LettersWaiting", math.max(0, (player:GetAttribute("LettersWaiting") or 1) - 1))
		local them = Players:GetPlayerByUserId(toUid)
		if them then them:SetAttribute("MailWaiting", true); notify:FireClient(them, "There is a letter for you at the post office!") end
		print(string.format("PostOffice: %s replied to u%d", player.Name, toUid))
		return true
	end
	return false, "no such thing"
end
action.OnServerInvoke = function(player, kind, a, b)
	if busy[player] then return false, "one thing at a time" end
	busy[player] = true
	local ok, res, extra = pcall(handle, player, kind, a, b)
	busy[player] = nil
	if not ok then warn("PostOffice: " .. tostring(kind) .. " failed - " .. tostring(res)); return false, "the post office is not answering" end
	return res, extra
end
local function onJoin(player)
	task.spawn(function()
		local rec = fresh(player.UserId)
		if rec.state == "answered" then
			player:SetAttribute("MailWaiting", true)
			task.wait(6)
			if player.Parent then notify:FireClient(player, "There is a letter for you at the post office!") end
		end
	end)
	-- the dev hears how many letters are waiting for her, the moment she joins
	if isDev(player) then
		task.spawn(function()
			local n = 0
			for i, u in ipairs(freshPending()) do
				if i > 40 then break end
				local r = fresh(u)
				if r.state == "sent" and r.letter then n += 1 end
			end
			player:SetAttribute("LettersWaiting", n)
			if n > 0 then
				task.wait(8)
				if player.Parent then notify:FireClient(player, n == 1 and "A letter is waiting for you at La Poste!" or (n .. " letters are waiting for you at La Poste!")) end
			end
		end)
	end
end
Players.PlayerAdded:Connect(onJoin)
for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil; records[p.UserId] = nil end)   -- read afresh if they come back
print("PostOffice: open - " .. tostring(PO:GetAttribute("Price")) .. " acorns a letter")
]==]

	-- ---------------------------------------------------------------- the client ----
	local CLIENT = [==[
-- PostClient: the prompt opens the panel; write and send, or read what came back; the dev desk for Shannon
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
-- On a phone the keyboard covers the Send button, and the only way to put it away was to tap outside the box - which
-- closed the whole panel and lost the letter (Shannon). Now the box is one wrapping line on touch screens, so the
-- keyboard's Done key puts it away; a tap outside only puts the keyboard away; and what you wrote is kept until sent.
local TOUCH = UIS.TouchEnabled
local draft, replyDrafts = "", {}
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local PO = script.Parent
local action = PO:WaitForChild("PostAction")
local notify = PO:WaitForChild("PostNotify")
local RGB = Color3.fromRGB
local FACE, FACE_DEEP, RIM = RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)
local SLOT, SLOT_EDGE = RGB(228, 212, 179), RGB(162, 131, 90)
local INK, INK_DIM, GOLD, BTN_INK, NAVY = RGB(64, 42, 22), RGB(132, 108, 80), RGB(255, 202, 62), RGB(84, 48, 18), RGB(30, 50, 100)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o; return c end
local function stroke(o, col, th, tr) local st = Instance.new("UIStroke"); st.Color = col; st.Thickness = th; st.Transparency = tr or 0; st.Parent = o; return st end
local function label(parent, text, x, y, w, h, size, colour, wrap, align)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.new(1, -x - 24, 0, h)
	if w then l.Size = UDim2.fromOffset(w, h) end
	l.BackgroundTransparency = 1; l.FontFace = FONT; l.TextSize = size; l.TextColor3 = colour or INK; l.Text = text
	l.TextWrapped = wrap ~= false; l.TextXAlignment = align or Enum.TextXAlignment.Left; l.TextYAlignment = Enum.TextYAlignment.Top
	l.ZIndex = 4; l.Parent = parent
	return l
end
local function button(parent, text, x, y, w, h, fill, ink)
	local b = Instance.new("TextButton"); b.Position = UDim2.fromOffset(x, y); b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = fill or GOLD; b.BorderSizePixel = 0; b.FontFace = FONT; b.TextSize = 18; b.TextColor3 = ink or BTN_INK
	b.Text = text; b.AutoButtonColor = false; b.ZIndex = 4; b.Parent = parent
	corner(b, UDim.new(0, 10)); stroke(b, RGB(150, 98, 36), 2, 0.2)
	return b
end
local function ago(t)
	if not t then return "" end
	local d = os.time() - t
	if d < 3600 then return math.max(1, math.floor(d / 60)) .. " min ago" end
	if d < 86400 then return math.floor(d / 3600) .. " h ago" end
	return math.floor(d / 86400) .. " days ago"
end

local gui = Instance.new("ScreenGui"); gui.Name = "PostOffice"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 7; gui.Enabled = false; gui.Parent = pg
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = RGB(20, 12, 6); shade.BackgroundTransparency = 0.45
shade.Text = ""; shade.AutoButtonColor = false; shade.BorderSizePixel = 0; shade.ZIndex = 1; shade.Parent = gui
local W, H = 460, 430
local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(W, H); panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.ZIndex = 2; panel.Parent = gui
corner(panel, UDim.new(0, 22)); stroke(panel, RIM, 4, 0)
local scale = Instance.new("UIScale"); scale.Parent = panel
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min((vp.Y - 40) / H, (vp.X - 40) / W), 0.5, 1)
end
task.spawn(function()
	for _ = 1, 40 do if workspace.CurrentCamera then break end task.wait(0.25) end
	fit()
	if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
end)
local title = label(panel, "La Poste", 24, 16, 300, 34, 28, RGB(58, 36, 16), false)
local close = button(panel, "X", W - 50, 18, 32, 32, SLOT, INK)
local page = Instance.new("Frame"); page.Position = UDim2.fromOffset(16, 62); page.Size = UDim2.new(1, -32, 1, -78); page.BackgroundTransparency = 1; page.ZIndex = 3; page.Parent = panel

-- the toast (its own gui, shown whether or not the panel is open)
local toastGui = Instance.new("ScreenGui"); toastGui.Name = "PostToast"; toastGui.ResetOnSpawn = false; toastGui.IgnoreGuiInset = true; toastGui.DisplayOrder = 8; toastGui.Parent = pg
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118); toast.Size = UDim2.fromOffset(420, 48)   -- above the hotbar, under any panel
toast.BackgroundColor3 = NAVY; toast.BackgroundTransparency = 0.08; toast.BorderSizePixel = 0; toast.FontFace = FONT; toast.TextSize = 20
toast.TextColor3 = RGB(255, 205, 40); toast.TextWrapped = true; toast.Text = ""; toast.Visible = false; toast.Parent = toastGui
corner(toast, UDim.new(0, 14)); stroke(toast, RGB(255, 205, 40), 2, 0.2)
local toastAt = 0
local function say(text, secs)
	toast.Text = text; toast.Visible = true
	local t = os.clock(); toastAt = t
	task.delay(secs or 5, function() if toastAt == t then toast.Visible = false end end)
end
notify.OnClientEvent:Connect(function(msg) say(msg, 6) end)
-- the envelope: built from frames, it pops out of the panel, wobbles, and flies off to the top right with a whoosh
local function flyEnvelope()
	local env = Instance.new("Frame"); env.AnchorPoint = Vector2.new(0.5, 0.5); env.Position = UDim2.fromScale(0.5, 0.52); env.Size = UDim2.fromOffset(150, 96)
	env.BackgroundColor3 = RGB(250, 244, 226); env.BorderSizePixel = 0; env.Rotation = -8; env.ZIndex = 20; env.Parent = toastGui
	corner(env, UDim.new(0, 8)); stroke(env, RGB(150, 118, 76), 3, 0)
	local flapL = Instance.new("Frame"); flapL.AnchorPoint = Vector2.new(0, 0); flapL.Position = UDim2.fromScale(0.03, 0.04); flapL.Size = UDim2.fromScale(0.54, 0.09)
	flapL.BackgroundColor3 = RGB(150, 118, 76); flapL.BorderSizePixel = 0; flapL.Rotation = 34; flapL.ZIndex = 21; flapL.Parent = env
	local flapR = flapL:Clone(); flapR.AnchorPoint = Vector2.new(1, 0); flapR.Position = UDim2.fromScale(0.97, 0.04); flapR.Rotation = -34; flapR.Parent = env
	local stamp = Instance.new("Frame"); stamp.AnchorPoint = Vector2.new(1, 0); stamp.Position = UDim2.new(1, -8, 0, 8); stamp.Size = UDim2.fromOffset(34, 40)
	stamp.BackgroundColor3 = RGB(255, 205, 40); stamp.BorderSizePixel = 0; stamp.ZIndex = 22; stamp.Parent = env
	stroke(stamp, RGB(250, 244, 226), 3, 0)
	local nut = Instance.new("Frame"); nut.AnchorPoint = Vector2.new(0.5, 0.5); nut.Position = UDim2.fromScale(0.5, 0.55); nut.Size = UDim2.fromOffset(16, 18)
	nut.BackgroundColor3 = RGB(196, 136, 66); nut.BorderSizePixel = 0; nut.ZIndex = 23; nut.Parent = stamp; corner(nut, UDim.new(1, 0))
	local cap = Instance.new("Frame"); cap.AnchorPoint = Vector2.new(0.5, 1); cap.Position = UDim2.fromScale(0.5, 0.36); cap.Size = UDim2.fromOffset(18, 8)
	cap.BackgroundColor3 = RGB(120, 78, 40); cap.BorderSizePixel = 0; cap.ZIndex = 24; cap.Parent = stamp; corner(cap, UDim.new(0, 4))
	local mark = Instance.new("Frame"); mark.AnchorPoint = Vector2.new(0.5, 0.5); mark.Position = UDim2.fromScale(0.5, 0.5); mark.Size = UDim2.fromOffset(44, 44)
	mark.BackgroundTransparency = 1; mark.ZIndex = 25; mark.Parent = stamp; stroke(mark, RGB(200, 60, 60), 2, 0.25); corner(mark, UDim.new(1, 0))
	for i, y in ipairs({0.46, 0.6, 0.74}) do
		local line = Instance.new("Frame"); line.Position = UDim2.fromScale(0.1, y); line.Size = UDim2.fromScale(i == 3 and 0.35 or 0.5, 0.05)
		line.BackgroundColor3 = RGB(150, 118, 76); line.BackgroundTransparency = 0.35; line.BorderSizePixel = 0; line.ZIndex = 21; line.Parent = env
	end
	local s = Instance.new("Sound"); s.SoundId = "rbxasset://sounds/button.wav"; s.Volume = 0.7; s.PlaybackSpeed = 0.6; s.Parent = toastGui; s:Play(); game:GetService("Debris"):AddItem(s, 3)
	-- pop, wobble, then away
	env.Size = UDim2.fromOffset(20, 12)
	TweenService:Create(env, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(150, 96), Rotation = 6}):Play()
	task.delay(0.35, function()
		TweenService:Create(env, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = -10}):Play()
	end)
	task.delay(0.7, function()
		TweenService:Create(env, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.fromScale(0.92, 0.06), Size = UDim2.fromOffset(30, 20), Rotation = 40}):Play()
		task.delay(0.95, function() env:Destroy() end)
	end)
end

local status
local render
local function call(kind, a, b)
	local ok, res, extra = pcall(function() return action:InvokeServer(kind, a, b) end)
	if not ok then return false, "the post office is not answering" end
	return res, extra
end
local function clearPage() for _, c in ipairs(page:GetChildren()) do c:Destroy() end end
local function noteLine(text, y, colour)
	return label(page, text, 0, y, nil, 40, 14, colour or INK_DIM)
end

-- the compose page: a box to write in, the price, the promise
local function composePage()
	clearPage()
	label(page, "Write to the dev", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	noteLine("Ask a question, tell her something, say hello. Replies take about a day - come back and check the box.", 26)
	local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(0, 70); slot.Size = UDim2.new(1, 0, 0, 150); slot.BackgroundColor3 = RGB(255, 252, 244)
	slot.BorderSizePixel = 0; slot.ZIndex = 4; slot.Parent = page; corner(slot, UDim.new(0, 12)); stroke(slot, SLOT_EDGE, 2, 0.3)
	local tb = Instance.new("TextBox"); tb.Position = UDim2.fromOffset(10, 8); tb.Size = UDim2.new(1, -20, 1, -16); tb.BackgroundTransparency = 1
	tb.FontFace = FONT; tb.TextSize = 16; tb.TextColor3 = INK; tb.PlaceholderText = "Dear dev, ..."; tb.PlaceholderColor3 = INK_DIM; tb.Text = ""
	tb.TextWrapped = true; tb.MultiLine = not TOUCH; tb.ClearTextOnFocus = false; tb.TextXAlignment = Enum.TextXAlignment.Left; tb.TextYAlignment = Enum.TextYAlignment.Top
	tb.Text = draft
	tb.ZIndex = 5; tb.Parent = slot
	local count = label(page, "0 / " .. tostring(status.max), 0, 226, nil, 18, 13, INK_DIM, false, Enum.TextXAlignment.Right)
	local send = button(page, "", 0, 256, 220, 42)
	local line = noteLine("", 306)
	local function refreshSend()
		local n = utf8.len(tb.Text) or #tb.Text
		count.Text = tostring(n) .. " / " .. tostring(status.max)
		local can = status.open and n > 0 and n <= status.max and status.acorns >= status.price
		send.Text = "Send for " .. tostring(status.price) .. " acorns"
		send.BackgroundColor3 = can and GOLD or RGB(214, 202, 176); send.TextColor3 = can and BTN_INK or INK_DIM
		if not status.open then line.Text = "The post office is closed just now."
		elseif status.acorns < status.price then line.Text = string.format("You have %d acorns; a stamp is %d.", status.acorns, status.price)
		elseif n > status.max then line.Text = "That is more than the envelope holds."
		else line.Text = "" end
	end
	tb:GetPropertyChangedSignal("Text"):Connect(function()
		if (utf8.len(tb.Text) or #tb.Text) > status.max + 40 then tb.Text = string.sub(tb.Text, 1, status.max + 40) end
		draft = tb.Text
		refreshSend()
	end)
	refreshSend()
	if status.reply then
		local again = button(page, "Read the dev's last letter", 232, 256, 196, 42, SLOT, INK)
		again.Activated:Connect(function() render("reply") end)
	end
	send.Activated:Connect(function()
		local n = utf8.len(tb.Text) or #tb.Text
		if not (status.open and n > 0 and n <= status.max and status.acorns >= status.price) then return end
		send.Text = "..."
		local ok, res = call("send", tb.Text)
		if ok then draft = ""; status = res; flyEnvelope(); say("Posted. The dev will write back in about a day.", 6); render()
		else line.Text = tostring(res); refreshSend() end
	end)
end
-- the letter is with the dev
local function sentPage()
	clearPage()
	label(page, "Your letter is with the dev", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	noteLine("Sent " .. ago(status.sentAt) .. ". Replies take about a day - come back and check the box.", 26)
	local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(0, 70); slot.Size = UDim2.new(1, 0, 0, 170); slot.BackgroundColor3 = RGB(255, 252, 244)
	slot.BorderSizePixel = 0; slot.ZIndex = 4; slot.Parent = page; corner(slot, UDim.new(0, 12)); stroke(slot, SLOT_EDGE, 2, 0.3)
	local l = label(slot, status.letter or "", 10, 8, nil, 150, 15, INK); l.Size = UDim2.new(1, -20, 1, -16); l.ZIndex = 5
end
-- a letter from the dev
local function replyPage()
	clearPage()
	label(page, "A letter for you", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	noteLine("From " .. tostring(status.by or "the dev") .. ", " .. ago(status.repliedAt) .. (status.letter and ("  -  in answer to: " .. string.sub(status.letter, 1, 60) .. ((#status.letter > 60) and "..." or "")) or ""), 26)
	local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(0, 70); slot.Size = UDim2.new(1, 0, 0, 190); slot.BackgroundColor3 = RGB(255, 252, 244)
	slot.BorderSizePixel = 0; slot.ZIndex = 4; slot.Parent = page; corner(slot, UDim.new(0, 12)); stroke(slot, SLOT_EDGE, 2, 0.3)
	local l = label(slot, status.reply or "", 10, 8, nil, 170, 15, INK); l.Size = UDim2.new(1, -20, 1, -16); l.ZIndex = 5
	local keep = button(page, status.state == "answered" and "Keep it" or "Write another", 0, 272, 220, 42)
	keep.Activated:Connect(function()
		if status.state == "answered" then local ok, res = call("read"); if ok then status = res end end
		render("compose")
	end)
end
-- the dev desk: every letter waiting, each with a reply box
local function deskPage()
	clearPage()
	label(page, "Dev desk", 0, 0, nil, 24, 20, RGB(58, 36, 16), false)
	local back = button(page, "My own letters", W - 32 - 170, 0, 170, 30, SLOT, INK)
	back.Activated:Connect(function() render("compose") end)
	local list = Instance.new("ScrollingFrame"); list.Position = UDim2.fromOffset(0, 36); list.Size = UDim2.new(1, 0, 1, -36); list.BackgroundTransparency = 1
	list.BorderSizePixel = 0; list.ScrollBarThickness = 5; list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new(); list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ZIndex = 4; list.Parent = page
	local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 10); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list
	local ok, letters = call("list")
	if not ok then noteLine(tostring(letters), 40); return end
	if #letters == 0 then label(list, "Nothing waiting. The box is empty.", 0, 0, nil, 30, 15, INK_DIM); return end
	for i, e in ipairs(letters) do
		local row = Instance.new("Frame"); row.Size = UDim2.new(1, -8, 0, 250); row.BackgroundColor3 = FACE_DEEP; row.BorderSizePixel = 0; row.LayoutOrder = i; row.ZIndex = 4; row.Parent = list
		corner(row, UDim.new(0, 14)); stroke(row, SLOT_EDGE, 2, 0.45)
		label(row, string.format("%s  (@%s)  -  %s", e.name, e.user, ago(e.t)), 12, 8, nil, 20, 15, RGB(58, 36, 16), false)
		local body = label(row, e.text, 12, 30, nil, 78, 14, INK); body.Size = UDim2.new(1, -24, 0, 78)
		local slot = Instance.new("Frame"); slot.Position = UDim2.fromOffset(12, 112); slot.Size = UDim2.new(1, -24, 0, 84); slot.BackgroundColor3 = RGB(255, 252, 244)
		slot.BorderSizePixel = 0; slot.ZIndex = 5; slot.Parent = row; corner(slot, UDim.new(0, 10)); stroke(slot, SLOT_EDGE, 2, 0.3)
		local tb = Instance.new("TextBox"); tb.Position = UDim2.fromOffset(8, 6); tb.Size = UDim2.new(1, -16, 1, -12); tb.BackgroundTransparency = 1
		tb.FontFace = FONT; tb.TextSize = 14; tb.TextColor3 = INK; tb.PlaceholderText = "Your reply..."; tb.PlaceholderColor3 = INK_DIM; tb.Text = ""
		tb.TextWrapped = true; tb.MultiLine = not TOUCH; tb.ClearTextOnFocus = false; tb.TextXAlignment = Enum.TextXAlignment.Left; tb.TextYAlignment = Enum.TextYAlignment.Top
		tb.Text = replyDrafts[e.uid] or ""
		tb:GetPropertyChangedSignal("Text"):Connect(function() replyDrafts[e.uid] = tb.Text end)
		tb.ZIndex = 6; tb.Parent = slot
		local send = button(row, "Send reply", 12, 204, 160, 36)
		local note = label(row, "", 184, 212, nil, 20, 13, INK_DIM, false)
		send.Activated:Connect(function()
			if #tb.Text == 0 then note.Text = "write the reply first"; return end
			send.Text = "..."
			local ok2, why = call("reply", e.uid, tb.Text)
			if ok2 then replyDrafts[e.uid] = nil; row:Destroy() else send.Text = "Send reply"; note.Text = tostring(why) end
		end)
	end
end
render = function(which)
	if not status then return end
	if which == "desk" then deskPage(); return end
	if which == "reply" and status.reply then replyPage(); return end
	if which == "compose" then composePage(); return end
	if status.state == "sent" then sentPage()
	elseif status.state == "answered" then replyPage()
	else composePage() end
end
local deskBtn = button(panel, "Dev desk", W - 50 - 12 - 110, 18, 110, 32, NAVY, RGB(255, 205, 40)); deskBtn.Visible = false
deskBtn.Activated:Connect(function() render("desk") end)
local function open()
	local ok, res = call("status")
	gui:SetAttribute("LastStatus", tostring(ok) .. " " .. tostring(res))
	if not ok then say(tostring(res), 4); return end
	status = res
	deskBtn.Visible = status.dev == true
	gui.Enabled = true
	fit()
	local want = scale.Scale; scale.Scale = want * 0.86
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = want}):Play()
	local okr, err = pcall(render)
	if not okr then gui:SetAttribute("RenderError", tostring(err)); warn("PostClient: render failed - " .. tostring(err)) end
end
local function closePanel() gui.Enabled = false end
close.Activated:Connect(closePanel)
-- (a tap on the shade only puts the keyboard away - it no longer closes the panel; the X does)

-- the prompt on the box, and its label when a letter is waiting
local function hookPrompt()
	-- at join the box model can arrive before the prompt inside it, so wait for the prompt itself, not just the model
	local box = PO:WaitForChild("PostBox", 60)
	local body = box and box:WaitForChild("Body", 60)
	local prompt = body and body:WaitForChild("PostPrompt", 60)
	if not prompt then warn("PostClient: no prompt on the post box"); return end
	gui:SetAttribute("Hooked", true)
	prompt.Triggered:Connect(function() gui:SetAttribute("Triggers", (gui:GetAttribute("Triggers") or 0) + 1); open() end)   -- on the client this fires for the local player only
	local function relabel()
		local n = player:GetAttribute("LettersWaiting") or 0              -- only the dev ever has these
		if player:GetAttribute("MailWaiting") then prompt.ObjectText = "La Poste - a letter is waiting for you!"
		elseif n > 0 then prompt.ObjectText = "La Poste - " .. n .. (n == 1 and " letter" or " letters") .. " to answer"
		else prompt.ObjectText = "La Poste - write to the dev" end
	end
	relabel()
	player:GetAttributeChangedSignal("MailWaiting"):Connect(relabel)
	player:GetAttributeChangedSignal("LettersWaiting"):Connect(relabel)
end
task.spawn(hookPrompt)
]==]
	local function install(name, ctx, src)
		local s = Instance.new("Script"); s.Name = name; s.RunContext = ctx; s.Source = src; s.Parent = PO
	end
	install("PostServer", Enum.RunContext.Server, SERVER)
	install("PostClient", Enum.RunContext.Client, CLIENT)
	print(string.format("PostOffice: box at (%.1f,%.1f,%.1f); %s acorns a letter; dev ids %s", at.X, at.Y, at.Z, tostring(PO:GetAttribute("Price")), tostring(PO:GetAttribute("DevIds"))))
end
