-- ChatterClient (workspace.SquirrelChatter, RunContext Client): the squirrels of Porto Nocciola, and the two church mice,
-- talk to you as you walk by (Shannon, Oct 11 2026). Scattered on purpose: when you come within Range studs of a squirrel
-- that has a line pool, ONE nearby squirrel may speak, by Chance, after a short random pause; then nobody speaks for Gap
-- seconds, and that squirrel rests for about Cooldown seconds. Standing among them, one of them pipes up every Linger
-- seconds or so. A squirrel talks once you have found it (the mice too); TalkUnfound true lets the hidden ones talk.
-- Lines come from the ChatterLines module beside this script; the bubble is the game's SquirrelBubble (VR included).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local Lines = require(F:WaitForChild("ChatterLines"))
local okB, Bubble = pcall(function() return require(RS:WaitForChild("SquirrelBubble", 30)) end)
if not (okB and type(Bubble) == "table" and Bubble.say) then warn("ChatterClient: no SquirrelBubble module - nobody talks") return end
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end

local found = {}
local function refreshFound()
	found = {}
	for id in tostring(player:GetAttribute("FoundIds") or ""):gmatch("[^,]+") do found[id] = true end
end
refreshFound()
player:GetAttributeChangedSignal("FoundIds"):Connect(refreshFound)

-- the squirrel as it stands for you: the colour model once found, else the gray one (both stand on the same spot)
local function modelOf(id)
	local first, second = id .. "_gray", id .. "_color"
	if found[id] then first, second = second, first end
	for _, name in ipairs({first, second}) do
		local m = workspace:FindFirstChild(name)
		local part = m and (m:FindFirstChild("Squirrel") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true))
		if part then return m, part end
	end
	return nil
end
local function someoneTalking(part)
	local g = pg:FindFirstChild("SquirrelBubbleGui")
	if g and #g:GetChildren() > 0 then return true end
	if part and (part:FindFirstChild("SquirrelBubbleVR") or (part.Parent and part.Parent:FindFirstChild("SquirrelBubbleVR", true))) then return true end
	return false
end

local state = {}      -- [id] = {near = bool, restUntil = clock}
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
			local close = (part.Position - hrp.Position).Magnitude < range
			if close and eligible(id, entry) and now >= st.restUntil then
				local cand = {id = id, entry = entry, m = m, part = part}
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
	if now >= quietUntil and not someoneTalking(nil) then
		if #arrivals > 0 then
			local c = arrivals[math.random(#arrivals)]
			if math.random() < num("Chance", 0.55) then pick = c else state[c.id].restUntil = now + 20 end
		elseif #around > 0 and now >= lingerAt then
			pick = around[math.random(#around)]
		end
	end
	if pick then
		local st = state[pick.id]
		st.restUntil = now + num("Cooldown", 120) * (0.7 + math.random() * 0.6)
		quietUntil = now + num("Gap", 9) * (0.8 + math.random() * 0.6)
		newLinger(now)
		local delay = 0.4 + math.random() * 2.2
		task.delay(delay, function()
			local c = player.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
			if not (r and pick.part.Parent and (pick.part.Position - r.Position).Magnitude < range * 1.6) then return end   -- (walked on already)
			if someoneTalking(pick.part) then return end
			speak(pick.id, pick.entry, pick.m, pick.part)
		end)
	end
end
