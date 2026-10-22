-- MailServer (workspace.Mail; mail3, Oct 22 2026): the treehouse mailbox's post. Shannon: "Periodically we will send the
-- player a letter and they will collect it from the mailbox." One letter a day (the daily card's day, 09:00 UTC) once
-- the player has a mailbox (the first treehouse piece), only from a squirrel they have found - the welcome letter comes
-- at once. One letter waits at a time - never two (Shannon: "you should not get a new letter until and unless you have read
-- the last letter, they should not accumulate") - and the next is written the day AFTER the last one was opened.
-- The ledger (RS.AwardItems / AwardAcorns, never a DataStore): Item_mail_<id> = delivered, Item_mail_wait = the waiting
-- letter's number in Letters (0 = none), Item_mail_day = the day of the last delivery or opening, Item_mail_read = letters opened.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local award = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local LETTERS = require(F:WaitForChild("Letters"))
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local NAMES = {}
for _, q in ipairs(Registry.squirrels) do NAMES[q.id] = q.name end
-- the sender's portrait for the letter's stamp (Shannon: "in the corner of the letter, please make sure to include the image
-- of that particular squirrel"): a bare copy of the squirrel's mesh, coloured, waits in RS.MailPortraits for the client's
-- little camera - the squirrel itself may be too far away to be loaded on the reader's screen
local portraits = RS:FindFirstChild("MailPortraits") or Instance.new("Folder")
portraits.Name = "MailPortraits"; portraits.Parent = RS
local function portraitOf(id)
	if portraits:FindFirstChild(id) then return end
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name:lower() == id .. "_color" then
			for _, mp in ipairs(m:GetDescendants()) do
				if mp:IsA("MeshPart") and mp:FindFirstChild("Head", true) and mp:FindFirstChild("Root", true) then
					local copy = mp:Clone()
					for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
					local colour = mp:GetAttribute("ColorTexture"); if colour then copy.TextureID = colour end
					copy.Anchored = true; copy.CanCollide = false; copy.CanQuery = false; copy.CanTouch = false
					copy.Name = id; copy.Parent = portraits
					return
				end
			end
		end
	end
end
local act = RS:FindFirstChild("MailAction")
if not act then act = Instance.new("RemoteFunction"); act.Name = "MailAction"; act.Parent = RS end

local function today()
	local daily = workspace:FindFirstChild("Daily")
	return math.floor((os.time() - ((daily and daily:GetAttribute("DayOffsetHours")) or 9) * 3600) / 86400)
end
local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end
local function setItem(p, id, value)                            -- an absolute value, sent as a delta so it merges safely
	local d = value - item(p, id)
	if d ~= 0 then award:Fire(p, id, d) end
end
local function hasMailbox(p)                                    -- the mailbox stands from the first treehouse piece
	if item(p, "tree_done") >= 1 then return true end
	for name, v in pairs(p:GetAttributes()) do
		if name:match("^Item_tree_p%d+$") and (tonumber(v) or 0) >= 1 then return true end
	end
	return false
end
local function nextLetter(p)
	local found = {}
	for id in string.gmatch(p:GetAttribute("FoundIds") or "", "[^,]+") do found[id] = true end
	for i, L in ipairs(LETTERS) do
		if item(p, "mail_" .. L.id) < 1 and (L.always or found[L.from]) then return i, L end
	end
end
local postedDay = {}                                             -- (in-session guard: never two letters on one day)
local function deliver(p)
	if p.Parent ~= Players or p:GetAttribute("SaveLoaded") ~= true or not hasMailbox(p) then return end
	if item(p, "mail_wait") > 0 then return end
	local day = today()
	if item(p, "mail_day") >= day or postedDay[p] == day then return end
	local i, L = nextLetter(p)
	if not i then return end
	postedDay[p] = day
	award:Fire(p, "mail_" .. L.id, 1)
	setItem(p, "mail_wait", i)
	setItem(p, "mail_day", day)
	print(string.format("MailServer: a letter for %s - %s from %s", p.Name, L.id, NAMES[L.from] or L.from))
end

local last = {}
act.OnServerInvoke = function(p, what)
	if os.clock() - (last[p] or 0) < 0.5 then return nil end
	last[p] = os.clock()
	if what ~= "open" then return nil end
	local i = item(p, "mail_wait")
	local L = LETTERS[i]
	if i < 1 or not L then
		local left = nextLetter(p) ~= nil
		return {none = true, more = left}
	end
	setItem(p, "mail_wait", 0)
	setItem(p, "mail_day", today())                              -- the next letter comes tomorrow, not straight after
	award:Fire(p, "mail_read", 1)
	local gift = tonumber(L.gift) or 0
	if gift > 0 then
		awardAcorns:Fire(p, gift)
		p:SetAttribute("Acorns", (p:GetAttribute("Acorns") or 0) + gift)
	end
	pcall(portraitOf, L.from)
	print(string.format("MailServer: %s opened %s", p.Name, L.id))
	return {id = L.id, from = L.from, signer = NAMES[L.from] or "A friend", sign = L.sign or "",
		text = (L.text:gsub("{name}", p.DisplayName)), gift = gift}
end

-- the post comes round: as the save arrives, as the first piece of a treehouse lands, and once a minute (a new day)
local function watch(p)
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent == Players and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(1) end
		task.wait(3)                                             -- (after TreehouseReset's own start-up claw)
		deliver(p)
		p.AttributeChanged:Connect(function(name)
			if name == "Item_tree_done" or name:match("^Item_tree_p%d+$") then task.delay(1, deliver, p) end
		end)
		while p.Parent == Players do
			task.wait(60)
			deliver(p)
		end
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) last[p] = nil; postedDay[p] = nil end)
print(string.format("MailServer: ready - %d letters, one a day from a found squirrel", #LETTERS))
