-- PLAY-TEST PREVIEW ONLY (mail3): the MailServer code run in this play test (Studio has no data access; nothing saves)
-- MailServer (workspace.Mail; mail3, Oct 22 2026): the treehouse mailbox's post. Shannon: "Periodically we will send the
-- player a letter and they will collect it from the mailbox." One letter a day (the daily card's day, 09:00 UTC) once
-- the player has a mailbox (the first treehouse piece), only from a squirrel they have found - the welcome letter comes
-- at once. One letter waits at a time - never two (Shannon: "you should not get a new letter until and unless you have read
-- the last letter, they should not accumulate") - and the next is written the day AFTER the last one was opened.
-- The ledger (RS.AwardItems / AwardAcorns, never a DataStore): Item_mail_<id> = delivered, Item_mail_wait = the waiting
-- letter's number in Letters (0 = none), Item_mail_day = the day of the last delivery or opening, Item_mail_read = letters opened.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local award = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local LETTERS = {
	{id = "welcome", from = "ranger_squirrel", always = true, gift = 15, sign = "Your neighbour on the trail,",
	 text = "Welcome to your new treehouse! As Forest Ranger I checked the ladder twice and the rope three times. Rule number one: always climb facing the ladder. Rule number two: check this mailbox every day. The squirrels LOVE writing letters.\n\nP.S. I tucked a few acorns in the envelope. Every new home needs a little something."},
	{id = "betty1", from = "baking_betty_squirrel", gift = 10, sign = "Sprinkles and hugs,",
	 text = "I baked you a welcome-home cupcake with extra frosting and a little acorn on top. Then I ate it. Quality control, you understand. I will bake you another one tomorrow. Probably.\n\nP.S. Here are some acorns instead. They are crunchier."},
	{id = "holmes1", from = "detective_squirrel", gift = 0, sign = "Discreetly yours,",
	 text = "I have been watching your treehouse for three days. Purely for investigative reasons. My conclusion: somebody lives there, and that somebody is you. Case closed. I will send my bill in the morning. (There is no bill. I just like saying that.)"},
	{id = "gordo1", from = "gordo_squirrel", gift = 10, sign = "Your hungry friend,",
	 text = "Do you have any snacks in your treehouse? I am asking for a friend. The friend is me. If you ever find an acorn under your rug, it is mine. Please keep it safe until I come over for a nap.\n\nP.S. I put some acorns in here for you. It was very, very hard."},
	{id = "fairy1", from = "fairy_squirrel", gift = 20, sign = "Twinkles,",
	 text = "It is Tuesday somewhere, so I am granting you one small wish. I wished you a really good acorn, and then a few more because I sneezed. Sorry about the glitter on the envelope. And on the mailbox. And on the tree."},
	{id = "buccaneer1", from = "squirrel_buccaneer", gift = 0, sign = "Arr and ahoy,",
	 text = "Ahoy, {name}! I found a treasure map that leads straight to your treehouse. I followed it all morning and ended up at the bakery. Twice. If you spot a big X anywhere near your ladder, send word at once. The map may have been upside down."},
	{id = "scientifico1", from = "squirrel_scientist", gift = 0, sign = "For science,",
	 text = "I measured your treehouse with my Acornometer. Results: one hundred percent cozy, zero percent explosions. Very disappointing for science, very good for you. I have attached my findings. They are this letter."},
	{id = "surfer1", from = "surfing_squirrel", gift = 0, sign = "Hang ten, dude,",
	 text = "Duuude! Your treehouse is SO high up. If it rains enough, do you think the whole forest turns into one giant wave? Asking for science. And surfing. Mostly surfing. If it happens, I call the first ride."},
	{id = "birds1", from = "birdwatch_squirrel", gift = 0, sign = "Binoculars up,",
	 text = "A bird landed on your roof this morning. I wrote it down. It was a brown one. Page five of my bird list is now all about your treehouse. I hope you do not mind. Please wave next time. The bird will not, but I will."},
	{id = "rainy1", from = "rainy_day_squirrel", gift = 10, sign = "Stay dry,",
	 text = "The clouds over your treehouse look suspicious. I have sent you a spare umbrella in this envelope. It is very small because it had to fit. Also my spare-spare umbrella. Also some acorns, in case the umbrellas do not work."},
}
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

_G.MailPreviewDeliver = function(p) postedDay[p] = nil; p:SetAttribute("Item_mail_day", 0); deliver(p) end
return "server preview running"
