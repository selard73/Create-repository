-- ChatterClient (workspace.SquirrelChatter, RunContext Client): the squirrels of Porto Nocciola, and the two church mice,
-- talk to you as you walk by (Shannon, Oct 11 2026). Scattered on purpose: when you come within Range studs of a squirrel
-- that has a line pool, ONE nearby squirrel may speak, by Chance, after a short random pause; then nobody speaks for Gap
-- seconds, and that squirrel rests for about Cooldown seconds. Standing among them, one of them pipes up every Linger
-- seconds or so. A squirrel talks once you have found it (the mice too); TalkUnfound true lets the hidden ones talk.
-- Nothing is said while a panel is open, while an interact pill is up (on a screen any pill, drawn by the player's head; in
-- VR one within PillRange of the speaker), or (on a screen) while the speaker is not well inside the view; a picked line waits
-- up to PendingSecs for its moment, then is let go.
-- Lines come from the ChatterLines module beside this script; the bubble is the game's SquirrelBubble (VR included), whose
-- Bubble.talking() says whether any bubble is up and which lets the newest bubble replace an older one (never two at once).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local Lines = require(F:WaitForChild("ChatterLines"))
local okB, Bubble = pcall(function() return require(RS:WaitForChild("SquirrelBubble", 30)) end)
if not (okB and type(Bubble) == "table" and Bubble.say) then warn("ChatterClient: no SquirrelBubble module - nobody talks") return end
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end

local found = {}
local state = {}      -- [id] = {near = bool, restUntil = clock}
local pending = nil   -- a picked line waiting for its moment (the speaker in view, no pill, no panel, nobody talking)
local function refreshFound()
	local was = found
	found = {}
	for id in tostring(player:GetAttribute("FoundIds") or ""):gmatch("[^,]+") do
		found[id] = true
		if not was[id] and state[id] then task.delay(2, function() if state[id] then state[id].near = false end end) end   -- (just found while standing at it: count as a fresh arrival after the reveal)
	end
end
refreshFound()
player:GetAttributeChangedSignal("FoundIds"):Connect(refreshFound)

-- the squirrel's model: <id>_color (at run time the gray look is a texture swap on it; SquirrelSetup removes the _gray
-- twin, which is only tried in case that ever changes - both stand on the same spot)
local SUFFIXES = {"_color", "_gray"}
local function modelOf(id)
	for _, suf in ipairs(SUFFIXES) do
		local m = workspace:FindFirstChild(id .. suf)
		local part = m and (m:FindFirstChild("Squirrel") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true))
		if part then return m, part end
	end
	return nil
end
-- is any speech bubble up? On a screen every bubble is a child of PlayerGui.SquirrelBubbleGui. In VR each one is a
-- BillboardGui "SquirrelBubbleVR" under its speaker's part, so the speakers' models are looked through: every one with
-- lines, both the colour and the gray, plus the ones other scripts make talk (Tonio, Polpo the octopus).
local VR = game:GetService("VRService").VREnabled
local OTHER_TALKERS = {"conductor_squirrel_color", "conductor_squirrel_gray", "Grotta.PolpoBrontolone"}   -- (a dot = a path under workspace)
local function byPath(path)
	local node = workspace
	for name in path:gmatch("[^.]+") do node = node:FindFirstChild(name); if not node then return nil end end
	return node
end
local function someoneTalking()
	if type(Bubble.talking) == "function" then return Bubble.talking() == true end   -- (the module knows every bubble, screen or VR; the rest is the fallback for an unpatched module)
	local g = pg:FindFirstChild("SquirrelBubbleGui")
	if g and #g:GetChildren() > 0 then return true end
	if VR then
		for id in pairs(Lines) do
			for _, suf in ipairs(SUFFIXES) do
				local m = workspace:FindFirstChild(id .. suf)
				if m and m:FindFirstChild("SquirrelBubbleVR", true) then return true end
			end
		end
		for _, name in ipairs(OTHER_TALKERS) do
			local m = byPath(name)
			if m and m:FindFirstChild("SquirrelBubbleVR", true) then return true end
		end
	end
	return false
end

local lastSaid = {}   -- [id] = the last line's index
local quietUntil = 0  -- nobody speaks before this
local lingerAt = 0    -- the next "someone pipes up while you stand here"
local function newLinger(now) lingerAt = now + num("Linger", 45) * (0.8 + math.random() * 0.8) end

local function speak(id, entry, m, part)
	local pool = entry.lines
	if type(pool) ~= "table" or #pool == 0 then return end
	local i = math.random(#pool)
	if #pool > 1 and i == lastSaid[id] then i = i % #pool + 1 end
	lastSaid[id] = i
	pcall(Bubble.say, m, pool[i], {secs = num("Secs", 4.2)})
end

local function eligible(id, entry)
	return found[id] or F:GetAttribute("TalkUnfound") == true
end

-- when not to speak at all: a panel is open (the card's shade or the map would cover the bubble), or the speaker's own
-- interact pill is showing (the pills draw above the bubbles and would hide the words)
local shownPrompts = {}
PPS.PromptShown:Connect(function(prompt) shownPrompts[prompt] = true end)
PPS.PromptHidden:Connect(function(prompt) shownPrompts[prompt] = nil end)
local function pillNear(part)
	-- stale entries first (a prompt destroyed or moved away while shown, its PromptHidden missed): a shown prompt is always
	-- inside its own reach of the player
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for prompt in pairs(shownPrompts) do
		local holder = prompt.Parent
		local pos
		if holder and holder:IsA("BasePart") then pos = holder.Position
		elseif holder and holder:IsA("Attachment") then pos = holder.WorldPosition
		elseif holder and holder:IsA("Model") then pos = holder:GetPivot().Position end
		if not (prompt.Enabled and prompt:IsDescendantOf(workspace) and pos and (not root or (pos - root.Position).Magnitude <= prompt.MaxActivationDistance + 4)) then
			shownPrompts[prompt] = nil
		end
	end
	-- on a screen (phone or desktop) every pill is drawn by the player's own head and can land anywhere: any pill blocks;
	-- in VR the pill stands by its object, so only one near the speaker does
	if not VR then return next(shownPrompts) ~= nil end
	for prompt in pairs(shownPrompts) do
		local holder = prompt.Parent
		local pos = holder:IsA("BasePart") and holder.Position or holder:IsA("Attachment") and holder.WorldPosition or holder:GetPivot().Position
		if (pos - part.Position).Magnitude < num("PillRange", 8) then return true end
	end
	return false
end
local function panelOpen()
	if pg:GetAttribute("OpenPanel") ~= nil then return true end
	local daily = pg:FindFirstChild("DailyGui"); local dcard = daily and daily:FindFirstChild("DailyCard")
	return daily ~= nil and daily.Enabled and dcard ~= nil and dcard.Visible
end

task.wait(2)
while true do
	task.wait(0.5)
	if F:GetAttribute("Enabled") == false then continue end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then continue end
	local now = os.clock()
	local range = num("Range", 10)
	local arrivals, around = {}, {}
	for id, entry in pairs(Lines) do
		local st = state[id]; if not st then st = {near = false, restUntil = 0}; state[id] = st end
		local m, part = modelOf(id)
		if part then
			local r = tonumber(entry.range) or range   -- (the clock keeper and Tito stand high up: their own reach)
			local close = (part.Position - hrp.Position).Magnitude < r
			if close and eligible(id, entry) and now >= st.restUntil then
				local cand = {id = id, entry = entry, m = m, part = part, r = r}
				if not st.near then table.insert(arrivals, cand) end
				table.insert(around, cand)
			end
			st.near = close
		else
			st.near = false
		end
	end
	if lingerAt == 0 then newLinger(now) end
	if #around == 0 then newLinger(now) end   -- (nobody near: the linger clock starts over when you arrive)
	local pick
	if now >= quietUntil and not panelOpen() then
		if someoneTalking() then
			quietUntil = math.max(quietUntil, now + num("Gap", 9) * 0.5)   -- (someone else's bubble: hold the floor a while after it too)
		elseif #arrivals > 0 then
			local c = arrivals[math.random(#arrivals)]
			if pillNear(c.part) then state[c.id].restUntil = now + 20   -- (its pill is up: not now)
			elseif math.random() < num("Chance", 0.55) then pick = c else state[c.id].restUntil = now + 20 end
		elseif #around > 0 and now >= lingerAt then
			local c = around[math.random(#around)]
			if pillNear(c.part) then state[c.id].restUntil = now + 20; newLinger(now) else pick = c end
		end
	end
	if pick then
		-- the rests are charged only for a line actually said; until then just hold everyone quiet through the pause
		local st = state[pick.id]
		local delay = 0.2 + math.random() * 1.0
		local wait = num("PendingSecs", 6)
		quietUntil = now + delay + wait + 0.6
		st.restUntil = now + 20   -- (if the line is never said, this short rest stands; a said line replaces it)
		newLinger(now)            -- (a dropped linger pick must not bring the next one on the very next tick)
		pending = {pick = pick, from = now + delay, until_ = now + delay + wait}
	end
	-- the pending line: said the first tick its moment comes (within PendingSecs), else let go
	if pending and now >= pending.from then
		local pk = pending.pick
		local c = player.Character; local root = c and c:FindFirstChild("HumanoidRootPart")
		local near = root and pk.part.Parent and (pk.part.Position - root.Position).Magnitude < pk.r * 1.6
		local inView = true
		if not VR then   -- (on a flat screen the bubble hangs beside the speaker: the speaker must be well inside the view)
			local cam = workspace.CurrentCamera
			local v, on = cam:WorldToViewportPoint(pk.part.Position)
			local W, H = cam.ViewportSize.X, cam.ViewportSize.Y
			inView = on and v.X > 0.08 * W and v.X < 0.92 * W and v.Y > 0.3 * H and v.Y < 0.95 * H
		end
		if not near or now > pending.until_ then
			pending = nil; quietUntil = math.min(quietUntil, now + 1)
		elseif someoneTalking() then   -- (someone else is talking: the line waits a little after them too, if it still fits)
			pending.from = math.max(pending.from, now + num("Gap", 9) * 0.5)
		elseif inView and not (panelOpen() or pillNear(pk.part)) then
			pending = nil
			local st = state[pk.id]
			st.restUntil = now + num("Cooldown", 120) * (0.7 + math.random() * 0.6)
			quietUntil = now + num("Gap", 9) * (0.8 + math.random() * 0.6)
			newLinger(now)
			speak(pk.id, pk.entry, pk.m, pk.part)
		end
	end
end
