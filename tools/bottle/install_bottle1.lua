-- install_bottle1.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW - discarded on stop). Job 118: the MESSAGE IN
-- A BOTTLE game on the main Porto beach. Scans the beach for open sand and the waterline, puts the stand 10..18 studs from the water
-- (its back to the sea), picks up to 10 wash-up spots, builds workspace.Bottles + ReplicatedStorage.BottleTemplate. Sources: BottleText
-- (11018), BottleServer (10292), BottleClient (18668) chars. No DataStore of ours (the save is touched only through RS.AwardItems /
-- AwardAcorns), no publish. Output "QQ BOTTLE".
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local SRC = {BottleText = [===[
-- BottleText (ModuleScript in workspace.Bottles): every word of the message-in-a-bottle game. Shared by BottleServer and BottleClient;
-- only INDEXES travel over the network and onto the save, so no player-typed text exists anywhere. Shannon (Oct 6 / Oct 15 2026):
-- fill-in-the-blank notes sent TO someone at sea; the next day a reply washes up that answers what you picked; silly bottles wash up too.
local T = {}
-- who the bottle is for (the reply is signed by them)
T.TO = {
	{label = "a stranded pirate", sign = "Captain Barnacle, on a very small island"},
	{label = "the lighthouse keeper", sign = "Old Lucia, keeper of the lighthouse"},
	{label = "the big whale", sign = "Balena, the big whale"},
	{label = "a crab on the rocks", sign = "Granchio, a crab of few words"},
	{label = "the grumpy squid", sign = "The Squid (still grumpy)"},
	{label = "whoever finds this", sign = "Someone who found your bottle"},
	{label = "a squirrel far, far away", sign = "Hana, a squirrel very far to the east"},
}
-- the message cards: text with two blanks, the choices for each, and the reply's first line that answers them.
-- (round 3, Shannon: "the fill in the blank is nonsensical" - every option in a blank is the same kind of word, and EVERY pairing of
-- blank 1 with blank 2 reads as a sensible (silly) sentence; the echo lines work for every pairing and every recipient)
T.CARDS = {
	{text = "Ahoy! Do you have enough {A} out there? I'm sending you {B}.",
	 A = {"snacks", "sunscreen", "socks", "friends", "books", "games"},
	 B = {"a sandwich", "a joke", "a map", "a tiny umbrella", "a lucky acorn", "a drawing of a squirrel"},
	 echo = {"Thank you for {B}! I definitely do not have enough {A}.", "Nobody has ever sent me {B} before. Now I just need more {A}."}},
	{text = "Today in Porto I ate {A}. It was {B}!",
	 A = {"a giant gelato", "a slice of pizza", "a lemon", "a bowl of spaghetti", "a fish sandwich", "a whole watermelon"},
	 B = {"delicious", "too big", "very sticky", "the best ever", "a little sour", "gone in one bite"},
	 echo = {"You ate {A} and it was {B}? Now I'm hungry.", "I've never tried {A}. Was it really {B}?"}},
	{text = "Help! A {A} stole my {B}!",
	 A = {"seagull", "crab", "pelican", "sneaky squirrel", "big wave", "cat"},
	 B = {"hat", "gelato", "sandwich", "flip-flop", "sunglasses", "towel"},
	 echo = {"Oh no! I'll keep an eye out for a {A} with a {B}.", "I saw a {A} go past this morning with a {B}. It looked very pleased with itself."}},
	{text = "If you come to Porto, bring {A} and we can {B}.",
	 A = {"a kite", "a picnic", "a beach ball", "a boat", "a swimsuit", "a camera"},
	 B = {"go swimming", "eat gelato", "look for squirrels", "watch the whale", "build a sandcastle", "ride the funicular"},
	 echo = {"I'll bring {A}! I've always wanted to {B}.", "Packing {A} right now. Save me a spot so we can {B}."}},
	{text = "Greetings from the beach! It's {A} today and I'm feeling {B}.",
	 A = {"sunny", "windy", "rainy", "very hot", "cloudy", "perfect"},
	 B = {"happy", "sleepy", "brave", "hungry", "silly", "fancy"},
	 echo = {"It's {A} here too! I'm feeling a bit {B} as well.", "{A} and {B}? That sounds like a great beach day."}},
	{text = "My best friend is a {A} who loves {B}.",
	 A = {"squirrel", "crab", "seagull", "dolphin", "lighthouse keeper", "pirate"},
	 B = {"dancing", "singing", "napping", "telling jokes", "collecting shells", "eating acorns"},
	 echo = {"A {A} who loves {B}? Please introduce me!", "Tell your {A} I love {B} too."}},
}
-- (round 3, Shannon: "we should be able to personalize it more, otherwise, no sense in the anticipation of coming back the next day")
-- a question to ask - and each recipient answers it in their own voice (same order as T.TO)
T.QUESTIONS = {"What's your favourite food?", "What do you do all day?", "Do you have any pets?", "What's the best thing about the sea?", "Can you keep a secret?", "What should I do in Porto?"}
T.ANSWER = {
	{"Coconuts. Only coconuts. It's coconuts or nothing on this island.", "I count waves. Yesterday there were 4,000. Or 12. I lost count.", "A crab named Gerald. He doesn't know he's my pet.", "The best thing about the sea is that it brought me your bottle.", "Arr, I can! I've kept one for years. I just can't remember what it is.", "Eat a gelato for me. Two, if they're small."},
	{"Toast with lemon jam, by the light of the big lamp.", "I polish the lamp, wave at the boats, and tell the seagulls off.", "A cat called Faro. She sleeps right next to the light.", "The sunsets. From up here, every one is the best I've ever seen.", "Of course. A lighthouse shines on the sea, never on secrets.", "Climb up to the lighthouse and wave. I'll wave back!"},
	{"Krill. Millions of them. Is that greedy? It feels greedy.", "I swim, I sing, and I splash the fishing boats by accident.", "A little fish follows me everywhere. I think he thinks I'm a rock.", "It's very big, like me. We get along.", "I'm a whale. Everything I say is very, very loud. But I'll try.", "Look out to sea from the beach. A big splash is me saying hi."},
	{"Seaweed. Crunchy seaweed. Click click.", "I walk sideways. Then I walk sideways back.", "A pebble. His name is Pebble. He is a very good pebble.", "The rocks. Also the sea. Mostly the rocks.", "Yes. Crabs never tell. We just pinch.", "Try the crab game. But please don't catch me."},
	{"Spaghetti. Don't laugh. All eight of my arms like spaghetti.", "Mostly I sulk in my cave. It's a very good cave for sulking.", "No. Pets are for happy squids. ...A starfish, maybe. Just one.", "Nobody bothers me down here. Well, nobody until your bottle.", "I keep everyone's secrets. Then I forget them. Squid brain.", "Don't come into my cave. Unless you bring spaghetti."},
	{"Pizza, today. Tomorrow? Also pizza.", "I walk on the beach and pick up bottles. Mostly yours, it turns out.", "A goldfish called Captain. He's very brave for a goldfish.", "Finding bottles like yours. It's like getting mail from the waves.", "I can! My lips are sealed. Like a bottle.", "Find all the squirrels. I'm still looking for one in a tiny hat."},
	{"Mochi! Soft, sweet and a little bit chewy.", "I sweep the temple steps and watch the cherry blossoms fall.", "A koi fish named Sunny. He lives in the garden pond.", "It carries bottles all the way to me. Like yours!", "Yes. Here we fold secrets into paper cranes.", "Ride the funicular to the top, then look east. That's where I am!"},
}
-- the second line of a reply, in each sender's own voice (same order as T.TO)
T.VOICE = {
	{"I've been on this island for 300 days. Or 3. I lost count.", "Send more bottles. I'm building a raft out of them.", "Arr. That means thank you.", "P.S. If you see my ship, tell it to come back."},
	{"The light is on, the kettle is on, and now I have a letter. Lovely day.", "Wave at the lighthouse tonight. I'll blink back.", "The seagulls here read over my shoulder. Rude.", "I keep every bottle on a shelf. Yours is next to the one with a sock in it."},
	{"BLUB. (That means hello.)", "I tried to write back, but my flippers are very big. A fish helped.", "I'll swim past the harbour later. Look for the big splash.", "I sang your letter to my friends. They loved it."},
	{"Click click. Good letter.", "I read it sideways. Crabs read everything sideways.", "Do not tell the seagulls where I live.", "I have pinched your bottle as a souvenir. Sorry. Not sorry."},
	{"Hmph. I suppose that was... nice. Don't tell anyone.", "I have eight arms, and none of them wanted to write back. But here we are.", "This changes nothing. I am still grumpy. Slightly less grumpy.", "I am keeping the bottle. It's shiny."},
	{"I found your bottle while looking for my other shoe. Still no shoe, but this was better.", "Your bottle bonked me on the head. Worth it.", "I'm writing back from a very wet beach. Hi!", "I'm going to send one too. Watch out for it!"},
	{"Your bottle floated all the way to me! The sea is very big.", "Here we have cherry trees and very fast trains. Come visit one day.", "I'm drinking tea and reading your letter. Perfect.", "Konnichiwa! That means hello. Your turn to say it."},
}
-- silly bottles that wash up on their own (anyone can find them)
T.BEACH = {
	{"Whoever finds this: the gelato shop is open. RUN.", "A seagull who has already been"},
	{"If found, please return this bottle. It is my favourite bottle.", "Somebody, somewhere"},
	{"Day 4 on the raft. Still no snacks. Morale: medium.", "Captain Barnacle"},
	{"Roses are red, the sea is blue, I lost my sandwich, have you seen it too?", "A hungry pelican"},
	{"This is a test bottle. If you are reading this, the test worked.", "The Porto Bottle Company"},
	{"The fish say hello. I don't know why they told me. I'm a crab.", "Granchio"},
	{"Do NOT go into the cave. Unless you want to. It's quite nice actually.", "The Squid"},
	{"Seen today: one whale, two boats, three squirrels in sunglasses.", "Old Lucia at the lighthouse"},
	{"I wrote this upside down. Please turn your head.", "A very silly squirrel"},
	{"Lost: one flip-flop, left foot. Reward: the right flip-flop.", "A beach squirrel"},
	{"Is this thing on? Hello? HELLO?", "Balena, the big whale"},
	{"The waves are doing a lot today. Too much, if you ask me.", "Granchio"},
	{"Note to self: do not let the crab hold the map.", "Captain Barnacle"},
	{"Greetings from far away! The cherry trees say hi.", "Hana, a squirrel very far to the east"},
	{"Your hair looks great today. (I can't see you. I'm a bottle.)", "The bottle"},
	{"Free hugs. Some assembly required.", "An octopus who is NOT the squid"},
}
local function fill(s, a, b) return (s:gsub("{A}", a):gsub("{B}", b)) end
function T.valid(to, card, a, b, q)
	local c = T.CARDS[card]
	return T.TO[to] ~= nil and c ~= nil and c.A[a] ~= nil and c.B[b] ~= nil and (q == nil or q == 0 or T.QUESTIONS[q] ~= nil)
end
function T.message(to, card, a, b, q, from)                -- what the player sent
	local c = T.CARDS[card]
	local m = "To " .. T.TO[to].label .. ":\n" .. fill(c.text, c.A[a], c.B[b])
	if q and T.QUESTIONS[q] then m ..= " " .. T.QUESTIONS[q] end
	if from then m ..= "\nFrom " .. from end
	return m
end
function T.reply(to, card, a, b, seed, q, info, name)    -- (round 3b, Shannon: "the replies ... should be short goofy one liners"):
	local c = T.CARDS[card]                                  -- Dear <name>, then ONE line - their own answer to the question asked;
	local line                                               -- a bottle sent before round 3 (no question) gets its echo line
	if q and T.ANSWER[to] and T.ANSWER[to][q] then line = T.ANSWER[to][q]
	else
		line = fill(c.echo[(seed % #c.echo) + 1], c.A[a], c.B[b])
		line = line:sub(1, 1):upper() .. line:sub(2)
	end
	local body = (name and ("Dear " .. name .. ",\n") or "") .. line
	if type(info) == "table" and info.hintName then body ..= "\nP.S. I spotted " .. info.hintName .. (info.hintWhere and (" in " .. info.hintWhere) or "") .. "!" end   -- (only when the folder's ReplyHints is on)
	return body, T.TO[to].sign
end
return T
]===], BottleServer = [===[
-- BottleServer (Script, server; in workspace.Bottles). The message-in-a-bottle game (job 118). Shannon (Oct 6 / Oct 15 2026):
--  * at the stand on the Porto beach a player writes a fill-in-the-blank note TO someone at sea (pirate, lighthouse keeper, whale, ...),
--    pays SendCost acorns and tosses it; ONE a day. After the game's daily reset a reply washes up for them by the stand, answering
--    what they picked, signed by whoever they wrote to.
--  * silly bottles wash up along the beach on their own (MaxBeach at a time); uncorking one pays FindPrize acorns, FindCap a day.
-- The save holds only numbers, through the game's own ledger (RS.AwardItems deltas - no DataStore here):
--   Item_bottle_out   = the day it was sent + 1 (0 = nothing at sea)   Item_bottle_card = to*1e6 + card*1e4 + a*100 + b
--   Item_bottle_paid  = day*10 + finds paid that day                    Item_bottles_found / Item_bottle_replies = counts
-- The day is the Daily's: floor((os.time() - DayOffsetHours h) / 86400), DayOffsetHours from workspace.Daily (9 by default).
-- Studio only: the folder attribute TestDayOffset moves "today" forward, to see a reply without waiting.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local Text = require(F:WaitForChild("BottleText"))
local ev = F:WaitForChild("BottleEvent")
local awardItems = RS:WaitForChild("AwardItems", 60)
local awardAcorns = RS:WaitForChild("AwardAcorns", 60)
if not (awardItems and awardAcorns) then warn("Bottles: ReplicatedStorage is missing AwardItems / AwardAcorns; the bottles are off") return end
local function A(name, default) local v = F:GetAttribute(name); if v == nil then return default end; return v end
local function realDay()                                                   -- what is STORED: always the real day
	local D = workspace:FindFirstChild("Daily")
	local off = (D and tonumber(D:GetAttribute("DayOffsetHours"))) or 9
	return math.floor((os.time() - off * 3600) / 86400)
end
local function today()                                                     -- what is COMPARED: in Studio, moved by TestDayOffset (never stored)
	local t = realDay()
	if RunService:IsStudio() then t += math.floor(tonumber(F:GetAttribute("TestDayOffset")) or 0) end
	return t
end
local function item(p, id) return math.floor(tonumber(p:GetAttribute("Item_" .. id)) or 0) end
-- the ledger answers at the end of the frame, so the server keeps its own view of each player's numbers while they play
local view = {}
local function get(p, id) local v = view[p]; if v and v[id] ~= nil then return v[id] end; return item(p, id) end
local function put(p, id, value)
	value = math.max(0, math.floor(value))
	local d = value - get(p, id)
	view[p] = view[p] or {}; view[p][id] = value
	if d ~= 0 then awardItems:Fire(p, id, d) end
end
local function pay(p, n)
	if n == 0 then return end
	awardAcorns:Fire(p, n)
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + n)
end
local function ready(p) return p:GetAttribute("SaveLoaded") == true end
-- Item_bottle_card: round 3 = to*1e8 + q*1e6 + card*1e4 + a*100 + b (the question); round 1-2 bottles still at sea = to*1e6 + ...
local function decode(code)
	if code >= 1e8 then return math.floor(code / 1e8) % 100, math.floor(code / 1e4) % 100, math.floor(code / 100) % 100, code % 100, math.floor(code / 1e6) % 100 end
	return math.floor(code / 1e6) % 100, math.floor(code / 1e4) % 100, math.floor(code / 100) % 100, code % 100, 0
end
-- how the sender is getting on, for the reply (round 3): squirrels found, the treehouse, and one squirrel they have not met yet
local Registry
pcall(function() local ss = workspace:FindFirstChild("SquirrelScripts"); local m = ss and ss:FindFirstChild("SquirrelRegistry"); if m then Registry = require(m) end end)
local function progress(p, seed)
	local info = {treeDone = (tonumber(p:GetAttribute("Item_tree_done")) or 0) >= 1}
	if type(Registry) ~= "table" or type(Registry.squirrels) ~= "table" then return info end
	local found = {}
	for id in tostring(p:GetAttribute("FoundIds") or ""):gmatch("[^,]+") do found[id] = true end
	local mapName, areaName = {}, {}
	for _, m in ipairs(Registry.maps or {}) do
		mapName[m.id] = m.name
		for _, a in ipairs(m.areas or {}) do areaName[a.id] = a.name end
	end
	local n, total, porto, other = 0, 0, {}, {}
	for _, e in ipairs(Registry.squirrels) do
		if mapName[e.map] then
			total += 1
			if found[e.id] then n += 1
			else table.insert(e.map == "porto" and porto or other, e) end
		end
	end
	info.found, info.total = n, total
	local pool = #porto > 0 and porto or other                               -- (the sea knows Porto best)
	if #pool > 0 then
		local e = pool[(seed % #pool) + 1]
		info.hintName = e.name
		info.hintWhere = (e.area and areaName[e.area]) or mapName[e.map]
	end
	return info
end
-- what this player's stand should say, and whether a reply is waiting
local function state(p)
	local out, day = get(p, "bottle_out"), today()
	local s = {cost = A("SendCost", 15), acorns = tonumber(p:GetAttribute("Acorns")) or 0, ready = ready(p)}
	if out > 0 then
		s.sentDay = out - 1
		s.replyReady = day > out - 1
		local to, card, a, b, q = decode(get(p, "bottle_card"))
		if Text.valid(to, card, a, b, q) then s.sent = {to, card, a, b, q} end
	end
	return s
end
local function push(p) ev:FireClient(p, "state", state(p)) end
local last = {}
local function throttle(p) local t = os.clock(); if last[p] and t - last[p] < 1 then return false end; last[p] = t; return true end
ev.OnServerEvent:Connect(function(p, what, a1, a2, a3, a4, a5)
	if what == "state" then push(p) return end
	if not throttle(p) then return end
	if not ready(p) then ev:FireClient(p, "msg", "Your save is still loading - try again in a moment") return end
	if what == "send" then
		local to, card, a, b, q = tonumber(a1), tonumber(a2), tonumber(a3), tonumber(a4), tonumber(a5) or 0
		if not (to and card and a and b and Text.valid(to, card, a, b, q)) then return end
		local s = state(p)
		if s.sentDay then
			ev:FireClient(p, "msg", s.replyReady and "Your reply is waiting at the kiosk - read it first!" or "Your bottle is already out at sea. Come back to the kiosk tomorrow!")
			return
		end
		local cost = math.max(0, math.floor(A("SendCost", 15)))
		local have = tonumber(p:GetAttribute("Acorns")) or 0
		if have < cost then ev:FireClient(p, "msg", string.format("A bottle costs %d acorns - you have %d", cost, have)) return end
		pay(p, -cost)
		put(p, "bottle_card", to * 1e8 + q * 1e6 + card * 1e4 + a * 100 + b)
		put(p, "bottle_out", realDay() + 1)
		ev:FireClient(p, "sent", to, card, a, b, q)
		push(p)
	elseif what == "reply" then
		local out = get(p, "bottle_out")
		if out <= 0 or today() <= out - 1 then push(p) return end
		local to, card, a, b, q = decode(get(p, "bottle_card"))
		put(p, "bottle_out", 0); put(p, "bottle_card", 0)
		put(p, "bottle_replies", get(p, "bottle_replies") + 1)
		if Text.valid(to, card, a, b, q) then
			local seed = (out * 31 + card * 7 + a * 3 + b + q * 11) % 997
			ev:FireClient(p, "reply", to, card, a, b, seed, q, (F:GetAttribute("ReplyHints") == true) and progress(p, seed) or nil)   -- (3b: one-liners; the squirrel-hint P.S. only if ReplyHints is on)
		end
		push(p)
	end
end)
-- ---------- the silly bottles on the beach ----------
local spots = {}
pcall(function() spots = HttpService:JSONDecode(F:GetAttribute("WashSpots") or "[]") end)
local beachF = F:FindFirstChild("Beach") or Instance.new("Folder"); beachF.Name = "Beach"; beachF.Parent = F
beachF:ClearAllChildren()
local template = RS:FindFirstChild("BottleTemplate")
local taken = {}
local function wash()
	if #spots == 0 or not template then return end
	local free = {}
	for i = 1, #spots do if not taken[i] then table.insert(free, i) end end
	if #free == 0 then return end
	local i = free[math.random(#free)]
	local s = spots[i]
	local m = template:Clone(); m.Name = "BeachBottle"
	m:PivotTo(CFrame.new(s[1], s[2] + 0.35, s[3]) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0) * CFrame.Angles(0, 0, math.rad(8)))   -- lying on its side (a Cylinder's length is X), neck a little up
	m.Parent = beachF
	taken[i] = m
	local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(p)
			if taken[i] ~= m or not ready(p) then return end
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - m:GetPivot().Position).Magnitude > 14 then return end
			taken[i] = nil; m:Destroy()
			local day, paid = realDay(), get(p, "bottle_paid")
			local n = (math.floor(paid / 10) == day) and (paid % 10) or 0
			local prize = 0
			if n < math.min(9, math.floor(A("FindCap", 5))) then prize = math.floor(A("FindPrize", 10)); put(p, "bottle_paid", day * 10 + n + 1) end
			pay(p, prize)
			put(p, "bottles_found", get(p, "bottles_found") + 1)
			ev:FireClient(p, "beach", math.random(#Text.BEACH), prize)
		end)
	end
end
task.spawn(function()
	for _ = 1, math.max(0, math.floor(A("MaxBeach", 3))) do wash() end
	while true do
		task.wait(math.max(10, tonumber(A("RespawnSeconds", 75)) or 75))
		local n = 0
		for _, m in pairs(taken) do if m and m.Parent then n += 1 end end
		if n < math.floor(A("MaxBeach", 3)) then wash() end
	end
end)
Players.PlayerRemoving:Connect(function(p) view[p] = nil; last[p] = nil end)
-- a reply comes due at the daily reset while people play: tell every client when the day turns (and when TestDayOffset moves in Studio)
local function pushAll() for _, p in ipairs(Players:GetPlayers()) do if ready(p) then push(p) end end end
F:GetAttributeChangedSignal("TestDayOffset"):Connect(pushAll)
task.spawn(function()
	local seen = today()
	while true do
		task.wait(30)
		local d = today()
		if d ~= seen then seen = d; pushAll() end
	end
end)
Players.PlayerAdded:Connect(function(p)
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and not ready(p) and os.clock() - t0 < 120 do task.wait(0.5) end
		if p.Parent then push(p) end
	end)
end)
print(string.format("Bottles: %d wash-up spots, send %d acorns, find %d acorns (%d a day)", #spots, A("SendCost", 15), A("FindPrize", 10), A("FindCap", 5)))
]===], BottleClient = [===[
-- BottleClient (Script, RunContext Client; in workspace.Bottles). The stand's writing panel, the toss, the reply bottle by the stand
-- (only its sender sees it), and the note card for every bottle opened. Job 118. All the words come from BottleText.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local Text = require(F:WaitForChild("BottleText"))
local ev = F:WaitForChild("BottleEvent")
local RGB = Color3.fromRGB
local FACE, RIM, PAPER = RGB(250, 241, 219), RGB(118, 80, 46), RGB(255, 250, 236)
local SLOT, INK, INK_DIM, GOLD, BTN_INK, SEA = RGB(228, 212, 179), RGB(64, 42, 22), RGB(132, 108, 80), RGB(255, 202, 62), RGB(84, 48, 18), RGB(40, 118, 160)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end
local function stroke(o, col, th) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = o end
local function label(parent, text, x, y, w, h, size, colour, align)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(x, y); l.Size = UDim2.fromOffset(w, h); l.BackgroundTransparency = 1
	l.FontFace = FONT; l.TextSize = size; l.TextColor3 = colour or INK; l.Text = text; l.TextWrapped = true
	l.TextXAlignment = align or Enum.TextXAlignment.Left; l.ZIndex = 4; l.Parent = parent
	return l
end
local function button(parent, text, x, y, w, h, fill, size)
	local b = Instance.new("TextButton"); b.Position = UDim2.fromOffset(x, y); b.Size = UDim2.fromOffset(w, h); b.BackgroundColor3 = fill or GOLD
	b.BorderSizePixel = 0; b.FontFace = FONT; b.TextSize = size or 18; b.TextColor3 = BTN_INK; b.Text = text; b.AutoButtonColor = true; b.ZIndex = 4; b.Parent = parent
	corner(b, 10); stroke(b, RGB(150, 98, 36), 2)
	return b
end
local function fit(frame, w, h)
	local sc = Instance.new("UIScale"); sc.Parent = frame
	local function upd()
		local cam = workspace.CurrentCamera; local v = cam and cam.ViewportSize or Vector2.new(1000, 800)
		sc.Scale = math.clamp(math.min((v.X - 24) / w, (v.Y - 110) / h), 0.5, 1)   -- (round 2: 110 px kept clear for the top HUD bar)
	end
	upd(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(upd) end
end
for _, n in ipairs({"BottleGui"}) do local g = pg:FindFirstChild(n); if g then g:Destroy() end end
local gui = Instance.new("ScreenGui"); gui.Name = "BottleGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 8; gui.Parent = pg
-- ---------- the toast ----------
local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -150); toast.Size = UDim2.fromOffset(420, 44)
toast.BackgroundColor3 = RGB(38, 30, 52); toast.BackgroundTransparency = 1; toast.TextTransparency = 1; toast.FontFace = FONT; toast.TextSize = 17
toast.TextColor3 = RGB(255, 244, 214); toast.TextWrapped = true; toast.ZIndex = 10; toast.Parent = gui
corner(toast, 14)
local toastAt = 0
local function say(text, secs)
	toast.Text = text; toast.BackgroundTransparency = 0.15; toast.TextTransparency = 0
	local mine = os.clock(); toastAt = mine
	task.delay(secs or 3.5, function()
		if toastAt ~= mine then return end
		TweenService:Create(toast, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
	end)
end
-- ---------- the note card (every bottle opened) ----------
local NW, NH = 420, 340                                                    -- (round 3b: Dear <name> and a one-line reply)
local note = Instance.new("Frame"); note.AnchorPoint = Vector2.new(0.5, 0.5); note.Position = UDim2.new(0.5, 0, 0.5, 24); note.Size = UDim2.fromOffset(NW, NH)
note.BackgroundColor3 = PAPER; note.BorderSizePixel = 0; note.Visible = false; note.ZIndex = 3; note.Parent = gui
corner(note, 18); stroke(note, RIM, 3); fit(note, NW, NH)
local nHead = label(note, "", 20, 14, NW - 40, 30, 22, SEA, Enum.TextXAlignment.Center)
local nBody = label(note, "", 26, 50, NW - 52, 120, 19, INK, Enum.TextXAlignment.Center); nBody.TextYAlignment = Enum.TextYAlignment.Center
nBody.TextScaled = true; do local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 20; c.MinTextSize = 12; c.Parent = nBody end
local nSign = label(note, "", 26, 176, NW - 52, 22, 15, INK_DIM, Enum.TextXAlignment.Right)
local nPrize = label(note, "", 26, 204, NW - 52, 64, 14, RGB(150, 104, 20), Enum.TextXAlignment.Center); nPrize.TextYAlignment = Enum.TextYAlignment.Top
nPrize.TextScaled = true; do local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 15; c.MinTextSize = 10; c.Parent = nPrize end
local nClose = button(note, "Lovely!", (NW - 130) / 2, 282, 130, 40)
local function chime()
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://9116394876"; s.Volume = 0.3; s.PlaybackSpeed = 1.1; s.Parent = gui; s:Play(); Debris:AddItem(s, 4)
end
local function showNote(head, body, sign, prize)
	nHead.Text = head; nBody.Text = body; nSign.Text = sign and ("- " .. sign) or ""; nPrize.Text = prize or ""
	note.Visible = true; pg:SetAttribute("OpenPanel", "bottle"); chime()
end
nClose.Activated:Connect(function() note.Visible = false; if pg:GetAttribute("OpenPanel") == "bottle" then pg:SetAttribute("OpenPanel", nil) end end)
-- ---------- the writing panel ----------
local W, H = 640, 330                                                      -- (round 2: wide and short, two columns - a landscape phone keeps ~0.9 scale)
local shade = Instance.new("TextButton"); shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = RGB(20, 12, 6); shade.BackgroundTransparency = 0.5
shade.Text = ""; shade.AutoButtonColor = false; shade.BorderSizePixel = 0; shade.Visible = false; shade.ZIndex = 1; shade.Parent = gui
local panel = Instance.new("Frame"); panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.new(0.5, 0, 0.5, 24); panel.Size = UDim2.fromOffset(W, H)
panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0; panel.Visible = false; panel.ZIndex = 2; panel.Parent = gui
corner(panel, 18); stroke(panel, RIM, 3); fit(panel, W, H)
label(panel, "Messaggi in Bottiglia", 20, 12, 420, 30, 24, INK)
local close = button(panel, "X", W - 52, 12, 38, 38, SLOT, 20)
local status = label(panel, "", 20, 46, W - 80, 22, 15, SEA)
local choice = {to = 1, card = 1, a = 1, b = 1, q = 1}
local rows = {}
local function cycler(y, title, get, count, set)
	label(panel, title, 20, y + 10, 70, 24, 15, INK_DIM)
	local prev = button(panel, "<", 92, y, 40, 44, SLOT, 22)
	local mid = Instance.new("TextLabel"); mid.Position = UDim2.fromOffset(138, y); mid.Size = UDim2.fromOffset(170, 44); mid.BackgroundColor3 = PAPER
	mid.BorderSizePixel = 0; mid.FontFace = FONT; mid.TextScaled = true; mid.TextColor3 = INK; mid.TextWrapped = true; mid.ZIndex = 4; mid.Parent = panel
	local mc = Instance.new("UITextSizeConstraint"); mc.MaxTextSize = 17; mc.MinTextSize = 10; mc.Parent = mid
	local mp = Instance.new("UIPadding"); mp.PaddingLeft = UDim.new(0, 6); mp.PaddingRight = UDim.new(0, 6); mp.Parent = mid
	corner(mid, 8)
	local nxt = button(panel, ">", 314, y, 40, 44, SLOT, 22)
	local row = {mid = mid, get = get}
	prev.Activated:Connect(function() set(((get() - 2) % count()) + 1) end)
	nxt.Activated:Connect(function() set((get() % count()) + 1) end)
	table.insert(rows, row)
	return row
end
local preview, send
local function card() return Text.CARDS[choice.card] end
local function refresh()
	rows[1].mid.Text = Text.TO[choice.to].label
	rows[2].mid.Text = "Note " .. choice.card .. " of " .. #Text.CARDS        -- (round 2: the whole sentence is in the preview)
	rows[3].mid.Text = card().A[choice.a]
	rows[4].mid.Text = card().B[choice.b]
	rows[5].mid.Text = Text.QUESTIONS[choice.q]
	preview.Text = Text.message(choice.to, choice.card, choice.a, choice.b, choice.q, player.DisplayName)
end
cycler(76, "To:", function() return choice.to end, function() return #Text.TO end, function(v) choice.to = v; refresh() end)
cycler(124, "Note:", function() return choice.card end, function() return #Text.CARDS end, function(v) choice.card = v; choice.a = 1; choice.b = 1; refresh() end)
cycler(172, "Blank 1:", function() return choice.a end, function() return #card().A end, function(v) choice.a = v; refresh() end)
cycler(220, "Blank 2:", function() return choice.b end, function() return #card().B end, function(v) choice.b = v; refresh() end)
cycler(268, "Ask:", function() return choice.q end, function() return #Text.QUESTIONS end, function(v) choice.q = v; refresh() end)   -- (round 3: they answer it tomorrow)
local paper = Instance.new("Frame"); paper.Position = UDim2.fromOffset(372, 76); paper.Size = UDim2.fromOffset(W - 392, 180); paper.BackgroundColor3 = PAPER
paper.BorderSizePixel = 0; paper.ZIndex = 3; paper.Parent = panel
corner(paper, 10); stroke(paper, RGB(196, 170, 120), 1.5)
preview = label(paper, "", 12, 10, W - 416, 160, 18, INK, Enum.TextXAlignment.Center); preview.TextYAlignment = Enum.TextYAlignment.Center
preview.TextScaled = true; local pc = Instance.new("UITextSizeConstraint"); pc.MaxTextSize = 19; pc.MinTextSize = 11; pc.Parent = preview
send = button(panel, "Cork it & toss it!", 372, 268, W - 392, 44)
send.TextScaled = true; local sc2 = Instance.new("UITextSizeConstraint"); sc2.MaxTextSize = 18; sc2.MinTextSize = 11; sc2.Parent = send
local sp2 = Instance.new("UIPadding"); sp2.PaddingLeft = UDim.new(0, 8); sp2.PaddingRight = UDim.new(0, 8); sp2.Parent = send
local st = {}
local function setStatus()
	if st.sentDay and st.replyReady then status.Text = "A reply to your bottle is waiting right here by the kiosk. Go and read it!"; send.Visible = false
	elseif st.sentDay then status.Text = "Your bottle is out at sea. A reply will wash up here tomorrow!"; send.Visible = false
	else status.Text = "One bottle a day. A reply washes up tomorrow."; send.Visible = true; send.Text = string.format("Cork it & toss it! (%d acorns)", st.cost or 15) end
end
local function open()
	ev:FireServer("state")
	-- (round 6, Shannon: "if you already sent a message that day ... you should not get the menu ... only the note") - a bottle at sea: just
	-- the note; a reply waiting: E reads it straight away; otherwise the writing panel
	if st.sentDay and not st.replyReady then say("Your bottle is out at sea. A reply will wash up here tomorrow!", 4) return end
	if st.sentDay and st.replyReady then ev:FireServer("reply") return end
	refresh(); setStatus()
	shade.Visible = true; panel.Visible = true; pg:SetAttribute("OpenPanel", "bottle")
	toastAt = 0; toast.BackgroundTransparency = 1; toast.TextTransparency = 1          -- (round 5: no toast left over the panel)
end
local function closePanel() shade.Visible = false; panel.Visible = false; if pg:GetAttribute("OpenPanel") == "bottle" then pg:SetAttribute("OpenPanel", nil) end end
close.Activated:Connect(closePanel); shade.Activated:Connect(closePanel)
send.Activated:Connect(function() ev:FireServer("send", choice.to, choice.card, choice.a, choice.b, choice.q) end)
-- ---------- the bottle in the world (the toss, the reply) ----------
local stand = F:WaitForChild("Stand", 60)
local template = RS:WaitForChild("BottleTemplate", 60)
local function standCF() return stand and stand:GetPivot() or CFrame.new() end
local function seaward()                                                  -- the stand's back faces the sea
	local cf = standCF(); return -cf.LookVector
end
local function toss()                                                      -- (round 5, Shannon: "so quick you can't tell what is happening") ~7 s:
	if not template then return end                                        -- the shore, a big bottle flying out, the camera following it, the
	local view                                                             -- landing, a long bob out to sea
	pcall(function() view = HttpService:JSONDecode(F:GetAttribute("TossView") or "null") end)
	local b = template:Clone(); b.Name = "TossedBottle"
	for _, d in ipairs(b:GetDescendants()) do if d:IsA("ProximityPrompt") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end end
	pcall(function() b:ScaleTo(2.2) end)                                    -- big enough to see from the shore
	local glass = b:FindFirstChild("Glass")
	if glass then local sp = Instance.new("Sparkles"); sp.SparkleColor = Color3.fromRGB(255, 240, 180); sp.Parent = glass end
	local from, to, camAt
	if view then
		from, to, camAt = Vector3.new(view.from[1], view.from[2], view.from[3]), Vector3.new(view.to[1], view.to[2], view.to[3]), Vector3.new(view.cam[1], view.cam[2], view.cam[3])
	else
		from = standCF().Position + Vector3.new(0, 4, 0); to = from + seaward() * 42 + Vector3.new(0, -5, 0)
	end
	local cam = workspace.CurrentCamera
	local before = cam and cam.CFrame
	local function look(at) if camAt and cam then cam.CFrame = CFrame.lookAt(camAt, at) end end
	if camAt and cam then cam.CameraType = Enum.CameraType.Scriptable end
	b:PivotTo(CFrame.new(from) * CFrame.Angles(0, 0, math.rad(60))); b.Parent = F
	look(from:Lerp(to, 0.3))
	task.wait(0.9)                                                         -- a moment on the shore with the bottle before it goes
	local v = Instance.new("NumberValue"); v.Value = 0
	v.Changed:Connect(function(t)
		local p = from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 14, 0)
		b:PivotTo(CFrame.new(p) * CFrame.Angles(t * 6, 0, math.rad(60) + t * 3))
		look(p:Lerp(to, 0.25))
	end)
	local tw = TweenService:Create(v, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = 1}); tw:Play()
	tw.Completed:Wait()
	-- the landing: a splash of spray and the toss sound, then a long bob out to sea
	local sp = Instance.new("Part"); sp.Anchored = true; sp.CanCollide = false; sp.CanQuery = false; sp.CanTouch = false; sp.Transparency = 1; sp.Size = Vector3.new(1, 1, 1)
	sp.CFrame = CFrame.new(to); sp.Parent = F
	local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(10, 16); e.SpreadAngle = Vector2.new(35, 35); e.EmissionDirection = Enum.NormalId.Top
	e.Lifetime = NumberRange.new(0.6, 1.1); e.Acceleration = Vector3.new(0, -30, 0); e.Size = NumberSequence.new(0.9, 0.2); e.Color = ColorSequence.new(Color3.fromRGB(230, 245, 255))
	e.Transparency = NumberSequence.new(0.1, 1); e.Parent = sp; e:Emit(60); Debris:AddItem(sp, 2.5)
	local sid = tostring(F:GetAttribute("TossSound") or "")
	if sid ~= "" then local s = Instance.new("Sound"); s.SoundId = sid; s.Volume = 0.6; s.Parent = gui; s:Play(); Debris:AddItem(s, 4) end
	local drift = Instance.new("NumberValue"); drift.Value = 0
	local away = (to - from) * Vector3.new(1, 0, 1); away = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, -1)
	drift.Changed:Connect(function(t)
		local p = to + away * t * 16 + Vector3.new(0, math.sin(t * 14) * 0.4 - 0.3, 0)
		b:PivotTo(CFrame.new(p) * CFrame.Angles(0, t * 1.5, math.rad(80) + math.sin(t * 9) * 0.2))
		look(p)
	end)
	local tw2 = TweenService:Create(drift, TweenInfo.new(3.0, Enum.EasingStyle.Linear), {Value = 1}); tw2:Play()
	tw2.Completed:Wait()
	task.wait(0.3)
	b:Destroy(); v:Destroy(); drift:Destroy()
	if camAt and cam then
		cam.CameraType = Enum.CameraType.Custom
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then cam.CameraSubject = h end
		if before then cam.CFrame = before end
	end
end
local replyBottle
local function placeReply(want)
	if not want then if replyBottle then replyBottle:Destroy(); replyBottle = nil end return end
	if replyBottle or not template then return end
	local spot
	pcall(function() spot = HttpService:JSONDecode(F:GetAttribute("ReplySpot") or "null") end)
	local pos = spot and Vector3.new(spot[1], spot[2] + 0.35, spot[3]) or (standCF().Position + seaward() * 8)
	local b = template:Clone(); b.Name = "ReplyBottle"
	b:PivotTo(CFrame.new(pos) * CFrame.Angles(0, 0.6, math.rad(8))); b.Parent = F   -- lying on its side; (round 2: kept in the game's folder)
	local prompt = b:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then prompt.ObjectText = "A reply to your bottle!"; prompt.ActionText = "Read it"; prompt.MaxActivationDistance = 14; prompt.Triggered:Connect(function() ev:FireServer("reply") end) end
	local glow = Instance.new("Highlight"); glow.FillColor = GOLD; glow.OutlineColor = RGB(255, 236, 160); glow.FillTransparency = 0.7; glow.Parent = b
	replyBottle = b
end
local told = false
local promptText                                                           -- (defined below, with the kiosk prompt; the state handler calls it)
ev.OnClientEvent:Connect(function(what, a, b, c, d, e, f, g)
	if what == "state" then
		st = type(a) == "table" and a or {}
		setStatus(); placeReply(st.replyReady == true); if promptText then promptText() end
		if st.replyReady and not told then told = true; task.delay(4, function() say("A reply to your bottle is waiting at the bottle kiosk by the boat club!", 5) end) end
	elseif what == "sent" then
		closePanel()
		task.spawn(toss)
		task.delay(4.2, function() say("Off it goes! Come back to the kiosk tomorrow for a reply.", 4) end)   -- (round 5: as it lands)
	elseif what == "reply" then
		if replyBottle then replyBottle:Destroy(); replyBottle = nil end
		local q, info = f, g
		local body, sign = Text.reply(a, b, c, d, e or 0, q, info, player.DisplayName)
		local wrote = Text.CARDS[b].text:gsub("{A}", Text.CARDS[b].A[c]):gsub("{B}", Text.CARDS[b].B[d])
		if q and Text.QUESTIONS[q] then wrote ..= " " .. Text.QUESTIONS[q] end
		showNote("A reply washed up!", body, sign, "You wrote: " .. wrote)
	elseif what == "beach" then
		local n = Text.BEACH[a]
		if n then showNote("A message in a bottle!", n[1], n[2], (b or 0) > 0 and ("+" .. b .. " acorns") or "You've found all the paid bottles for today - this one's just for fun") end
	elseif what == "msg" then
		say(tostring(a), 4)
	end
end)
local prompt = stand and stand:FindFirstChild("WritePrompt", true)
if prompt then prompt.Triggered:Connect(open) end
promptText = function()                                                    -- (round 6) this player's own view of the kiosk prompt
	if not prompt then return end
	if st.sentDay and st.replyReady then prompt.ActionText = "Read your reply"
	elseif st.sentDay then prompt.ActionText = "Your bottle is at sea"
	else prompt.ActionText = "Write a message" end
end
ev:FireServer("state")
]===]}
for n, s in pairs(SRC) do
	local ok, f, err = pcall(function() return loadstring(s) end)
	if ok and not f then print("QQ BOTTLE ABORT: " .. n .. " does not compile: " .. tostring(err)) return end
end
if not (RS:FindFirstChild("AwardItems") and RS:FindFirstChild("AwardAcorns")) then print("QQ BOTTLE ABORT: ReplicatedStorage.AwardItems / AwardAcorns missing") return end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Bottles") end)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local old = workspace:FindFirstChild("Bottles")                          -- (round 2: kept in place until the scan has passed; an ABORT leaves it working)
-- ---------- 1: the beach scan ----------
local X1, X2, Z1, Z2, STEP = 215, 340, -800, -690, 4
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = false
local skip = {}
for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
if old then table.insert(skip, old) end                                     -- (a re-run: the old stand never blocks its own site)
rp.FilterDescendantsInstances = skip
local sand, water = {}, {}
for x = X1, X2, STEP do
	for z = Z1, Z2, STEP do
		local h = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -260, 0), rp)
		if h and h.Instance == T then
			if h.Material == Enum.Material.Water then table.insert(water, Vector3.new(x, h.Position.Y, z))
			elseif h.Material == Enum.Material.Sand or h.Material == Enum.Material.Ground then table.insert(sand, h.Position) end
		end
	end
end
print(string.format("QQ BOTTLE scan: x %d..%d z %d..%d step %d - %d open sand points, %d water points", X1, X2, Z1, Z2, STEP, #sand, #water))
if #sand < 6 or #water < 6 then print("QQ BOTTLE ABORT: too little open sand or water in the scan box - tell the cloud thread (the beach may sit elsewhere)") return end
local function nearestWater(p)
	local best, bp = math.huge, nil
	for _, w in ipairs(water) do local d = (Vector3.new(w.X, 0, w.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude; if d < best then best, bp = d, w end end
	return best, bp
end
local hByXZ = {}
for _, s in ipairs(sand) do hByXZ[math.floor(s.X + 0.5) .. "," .. math.floor(s.Z + 0.5)] = s.Y end
local function level(s)
	for _, o in ipairs({{STEP, 0}, {-STEP, 0}, {0, STEP}, {0, -STEP}}) do
		local y = hByXZ[math.floor(s.X + o[1] + 0.5) .. "," .. math.floor(s.Z + o[2] + 0.5)]
		if not y or math.abs(y - s.Y) > 1.5 then return false end
	end
	return true
end
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {T, table.unpack(skip)}
local function clear(s, r)
	for _, pt in ipairs(workspace:GetPartBoundsInRadius(s + Vector3.new(0, 3, 0), r, op)) do
		local top = pt.Position.Y + pt.Size.Y / 2
		if top > s.Y + 0.6 and (pt.Transparency < 1 or pt.CanCollide) then return false, pt end   -- (round 4: the floor under it does not count)
	end
	return true
end
-- ---------- 2: the stand ----------
local SPAWN = Vector3.new(232, -47, -580)
local site, siteWater, standCF
local FIXED = {x = 473.3, z = -970.9, yaw = 98.6}
if FIXED then
	local h = workspace:Raycast(Vector3.new(FIXED.x, 120, FIXED.z), Vector3.new(0, -260, 0), rp)
	if not h then print("QQ BOTTLE ABORT: nothing under the chosen kiosk spot - tell the cloud thread") return end
	site = h.Position
	local d, wp = nearestWater(site); siteWater = wp
	standCF = CFrame.new(site) * CFrame.Angles(0, math.rad(FIXED.yaw), 0)          -- its front (LookVector) faces the way she faced
	local ok, by = clear(site, 3)
	print(string.format("QQ BOTTLE stand (her spot): (%.1f, %.1f, %.1f) on %s, facing yaw %.0f; %s; nearest water %.0f studs", site.X, site.Y, site.Z,
		h.Instance == T and ("terrain " .. h.Material.Name) or h.Instance:GetFullName(), FIXED.yaw, ok and "3 studs clear" or ("a part's box reaches the spot (check by eye): " .. by:GetFullName()), d))
end
local cands = {}
for _, s in ipairs(sand) do
	local d, wp = nearestWater(s)
	if d >= 10 and d <= 18 and level(s) then table.insert(cands, {s = s, w = wp, k = (s - SPAWN).Magnitude}) end
end
table.sort(cands, function(a, b) return a.k < b.k end)
local blocked = 0
for _, c in ipairs(FIXED and {} or cands) do
	local ok = clear(c.s, 7)
	if ok then site, siteWater = c.s, c.w break end
	blocked += 1
end
if not site and not FIXED then print(string.format("QQ BOTTLE ABORT: no open level sand 10..18 studs from the water with 7 clear studs (%d candidates, %d blocked) - tell the cloud thread", #cands, blocked)) return end
if not FIXED then
local seaward = Vector3.new(siteWater.X - site.X, 0, siteWater.Z - site.Z).Unit
standCF = CFrame.lookAt(site, site - seaward)                            -- its front (LookVector) faces inland, its back the sea
print(string.format("QQ BOTTLE stand: (%.1f, %.1f, %.1f), %.0f studs from the water, back to the sea toward (%.2f, %.2f); %d candidates, %d blocked before it",
	site.X, site.Y, site.Z, (Vector3.new(siteWater.X, 0, siteWater.Z) - Vector3.new(site.X, 0, site.Z)).Magnitude, seaward.X, seaward.Z, #cands, blocked))
end
-- ---------- 3: the wash spots ----------
local spots = {}
local shore = {}
for _, s in ipairs(sand) do local d = nearestWater(s); if d <= 5 and clear(s, 2.5) then table.insert(shore, s) end end
table.sort(shore, function(a, b) return (a - site).Magnitude < (b - site).Magnitude end)
for _, s in ipairs(shore) do
	local far = true
	for _, o in ipairs(spots) do if (Vector3.new(o[1], 0, o[3]) - Vector3.new(s.X, 0, s.Z)).Magnitude < 12 then far = false break end end
	if far then table.insert(spots, {math.floor(s.X * 10 + 0.5) / 10, math.floor(s.Y * 100 + 0.5) / 100, math.floor(s.Z * 10 + 0.5) / 10}) end
	if #spots >= 10 then break end
end
if #spots == 0 then print("QQ BOTTLE ABORT: no wash-up spots at the waterline - tell the cloud thread") return end
local list = {}
for i, s in ipairs(spots) do table.insert(list, string.format("%d (%.0f, %.1f, %.0f)", i, s[1], s[2], s[3])) end
if #spots < 2 then print("QQ BOTTLE ABORT: only one waterline spot - tell the cloud thread") return end
local replySpot
if (Vector3.new(spots[1][1], 0, spots[1][3]) - Vector3.new(site.X, 0, site.Z)).Magnitude <= 30 then
	replySpot = table.remove(spots, 1)                                     -- (round 2: the reply spot is never a wash spot - no beach bottle inside the reply bottle)
else                                                                       -- (round 3: the kiosk is up on the landing - the reply lies at its foot)
	local f = (standCF * CFrame.new(2.5, 0, -4.5)).Position
	local h = workspace:Raycast(f + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), rp)
	replySpot = {math.floor(f.X * 10 + 0.5) / 10, math.floor(((h and h.Position.Y) or site.Y) * 100 + 0.5) / 100, math.floor(f.Z * 10 + 0.5) / 10}
	print(string.format("QQ BOTTLE the reply spot: in front of the kiosk at (%.0f, %.1f, %.0f) - the waterline is more than 30 studs away", replySpot[1], replySpot[2], replySpot[3]))
end
print("QQ BOTTLE waterline spots: " .. table.concat(list, " | ") .. string.format("; %d wash spots%s", #spots, (#list > #spots) and ", no. 1 (nearest the kiosk) is the REPLY spot" or " (the reply lies at the kiosk)"))
-- every check passed: now the old install goes
if old then local n = 1; while hb:FindFirstChild("Bottles_pre_" .. n) do n += 1 end; old.Name = "Bottles_pre_" .. n; old.Parent = hb; for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end end
local oldT = RS:FindFirstChild("BottleTemplate"); if oldT then oldT:Destroy() end
-- ---------- 4: the template ----------
local function part(parent, name, size, color, cf, mat, shape, transp)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Transparency = transp or 0; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = parent
	return p
end
local C = Color3.fromRGB
local tpl = Instance.new("Model"); tpl.Name = "BottleTemplate"
local glass = part(tpl, "Glass", Vector3.new(1.6, 0.72, 0.72), C(150, 205, 175), CFrame.new(), Enum.Material.Glass, Enum.PartType.Cylinder, 0.35)
glass.Reflectance = 0.2; glass.CanQuery = true
part(tpl, "Neck", Vector3.new(0.5, 0.36, 0.36), C(150, 205, 175), CFrame.new(1.0, 0, 0), Enum.Material.Glass, Enum.PartType.Cylinder, 0.35)
part(tpl, "Cork", Vector3.new(0.32, 0.3, 0.3), C(176, 132, 84), CFrame.new(1.38, 0, 0), Enum.Material.Wood, Enum.PartType.Cylinder)
part(tpl, "Note", Vector3.new(1.0, 0.3, 0.3), C(250, 240, 210), CFrame.new(-0.05, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
part(tpl, "Ribbon", Vector3.new(0.08, 0.32, 0.32), C(200, 60, 60), CFrame.new(-0.05, 0, 0), Enum.Material.Fabric, Enum.PartType.Cylinder)
tpl.PrimaryPart = glass
local pr = Instance.new("ProximityPrompt"); pr.Name = "UncorkPrompt"; pr.ActionText = "Uncork"; pr.ObjectText = "Message in a bottle"
pr.MaxActivationDistance = 12; pr.RequiresLineOfSight = false; pr.HoldDuration = 0; pr.Parent = glass
local sp = Instance.new("Sparkles"); sp.SparkleColor = C(255, 240, 180); sp.TimeScale = 0.6; sp.Parent = glass
tpl.Parent = RS
-- ---------- 5: the folder, the stand, the scripts ----------
local Fd = Instance.new("Folder"); Fd.Name = "Bottles"
for k, v in pairs({SendCost = 15, FindPrize = 10, FindCap = 5, MaxBeach = 1, RespawnSeconds = 90, TestDayOffset = 0, TossSound = "rbxassetid://129669875728815"}) do Fd:SetAttribute(k, v) end   -- (round 5b: TossSound = her pick "Splash.mp3", not the croc's; any id, or "" for none)   -- (round 3: ONE silly bottle at a time)
Fd:SetAttribute("WashSpots", HttpService:JSONEncode(spots))
Fd:SetAttribute("ReplySpot", HttpService:JSONEncode(replySpot))
do	-- (round 4/5) the toss view: a shore spot where the camera, the throw and the landing see each other over OPEN water (round 4's view
	-- looked into the quay wall - runner 7). Each waterline spot is tried, nearest the kiosk first; the first with clear sight lines wins.
	local los = RaycastParams.new(); los.FilterType = Enum.RaycastFilterType.Exclude; los.IgnoreWater = true; los.FilterDescendantsInstances = skip
	local chosen
	local all = {replySpot and replySpot or nil}
	for _, s0 in ipairs(spots) do table.insert(all, s0) end
	for _, s0 in ipairs(all) do
		if type(s0) == "table" then
			local sp = Vector3.new(s0[1], s0[2], s0[3])
			local d, wp = nearestWater(sp)
			if wp and d <= 8 then
				local out = Vector3.new(wp.X - sp.X, 0, wp.Z - sp.Z); out = out.Magnitude > 0.1 and out.Unit or Vector3.new(0, 0, -1)
				local target = Vector3.new(sp.X, wp.Y, sp.Z) + out * 28
				local down = workspace:Raycast(target + Vector3.new(0, 30, 0), Vector3.new(0, -60, 0), rp)
				local overWater = down and down.Instance == T and down.Material == Enum.Material.Water
				local cam = sp - out * 8 + Vector3.new(0, 10, 0)
				local from = sp + Vector3.new(0, 3, 0)
				local function sees(a, b) local r = workspace:Raycast(a, b - a, los); return r == nil or (r.Position - b).Magnitude < 2 end
				local mid = from:Lerp(target, 0.5) + Vector3.new(0, 14, 0)
				if overWater and sees(cam, target + Vector3.new(0, 1, 0)) and sees(cam, mid) and sees(cam, from) and sees(from, mid) and sees(mid, target + Vector3.new(0, 1, 0)) then
					chosen = {cam = {cam.X, cam.Y, cam.Z}, from = {from.X, from.Y, from.Z}, to = {target.X, target.Y, target.Z}}
					print(string.format("QQ BOTTLE toss view: the camera at (%.0f, %.0f, %.0f) on the shore, the bottle lands at (%.0f, %.1f, %.0f) on open water - clear sight lines", cam.X, cam.Y, cam.Z, target.X, target.Y, target.Z))
					break
				end
			end
		end
	end
	if chosen then Fd:SetAttribute("TossView", HttpService:JSONEncode(chosen))
	else print("QQ BOTTLE toss view: NO shore spot sees open water clearly - the toss flies from the kiosk without the camera cut; tell the cloud thread") end
end
local evt = Instance.new("RemoteEvent"); evt.Name = "BottleEvent"; evt.Parent = Fd
local mod = Instance.new("ModuleScript"); mod.Name = "BottleText"; mod.Source = SRC.BottleText; mod.Parent = Fd
local St = Instance.new("Model"); St.Name = "Stand"; St.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local WOOD, WOOD_D, CREAM, RED, BLUE = C(176, 128, 78), C(120, 82, 48), C(250, 244, 228), C(206, 72, 60), C(48, 110, 168)
local function L(x, y, z) return standCF * CFrame.new(x, y, z) end
local function solid(name, size, color, cf, mat) local p = part(St, name, size, color, cf, mat or Enum.Material.WoodPlanks); p.CanCollide = true; p.CanQuery = true; return p end
local counter = solid("Counter", Vector3.new(7, 3.4, 2.4), WOOD, L(0, 1.7, -0.8))
solid("CounterTop", Vector3.new(7.6, 0.3, 2.9), WOOD_D, L(0, 3.55, -0.8))
for _, x in ipairs({-3.4, 3.4}) do solid("Post", Vector3.new(0.4, 7.6, 0.4), WOOD_D, L(x, 3.8, 0.6), Enum.Material.Wood) end
for i = 0, 6 do part(St, "Awning", Vector3.new(1.1, 0.2, 3.6), (i % 2 == 0) and BLUE or CREAM, L(-3.3 + i * 1.1, 7.7, -0.6) * CFrame.Angles(math.rad(-14), 0, 0), Enum.Material.Fabric) end
for i = 0, 6 do part(St, "AwningFringe", Vector3.new(1.1, 0.45, 0.08), (i % 2 == 0) and BLUE or CREAM, L(-3.3 + i * 1.1, 7.0, -2.35), Enum.Material.Fabric) end
local crate = solid("Crate", Vector3.new(2.2, 1.4, 1.6), WOOD_D, L(-4.8, 0.7, -0.2))
for i = 0, 3 do
	local b = tpl:Clone(); for _, d in ipairs(b:GetDescendants()) do if d:IsA("ProximityPrompt") or d:IsA("Sparkles") then d:Destroy() end end
	b:PivotTo(L(-5.5 + i * 0.48, 1.9, -0.2) * CFrame.Angles(0, 0, math.rad(80 + (i % 2) * 8))); b.Name = "CrateBottle"; b.Parent = St
end
for i = 0, 2 do
	local b = tpl:Clone(); for _, d in ipairs(b:GetDescendants()) do if d:IsA("ProximityPrompt") or d:IsA("Sparkles") then d:Destroy() end end
	b:PivotTo(L(-1.6 + i * 1.4, 4.1, -0.6) * CFrame.Angles(0, math.rad(20 * i), math.rad(90))); b.Name = "CounterBottle"; b.Parent = St
end
-- (round 4, Shannon: "you cannot see it under the awning unless you tilt the view") - the board stands ON the awning, clear of the fringe
for _, x in ipairs({-2.6, 2.6}) do solid("SignPost", Vector3.new(0.25, 1.6, 0.25), WOOD_D, L(x, 8.6, 0.05), Enum.Material.Wood) end   -- (round 5: BEHIND the board - its back face is at z -0.175)
local board = solid("SignBoard", Vector3.new(7.0, 1.9, 0.25), CREAM, L(0, 9.75, -0.3), Enum.Material.SmoothPlastic)
solid("SignTrim", Vector3.new(7.3, 0.18, 0.32), WOOD_D, L(0, 10.75, -0.3), Enum.Material.Wood)
local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(660, 150); sg.LightInfluence = 0.5; sg.Parent = board
local function sgText(text, y, h, colour) local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = UDim2.fromScale(0, y); t.Size = UDim2.fromScale(1, h); t.Text = text; t.TextScaled = true; t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json"); t.TextColor3 = colour; t.Parent = sg end
sgText("MESSAGGI IN BOTTIGLIA", 0.06, 0.52, BLUE); sgText("Messages in a Bottle", 0.6, 0.34, WOOD_D)
do local back = sg:Clone(); back.Face = Enum.NormalId.Back; back.Parent = board end   -- (round 2: lettered on the sea side too)
local wp = Instance.new("ProximityPrompt"); wp.Name = "WritePrompt"; wp.ActionText = "Write a message"; wp.ObjectText = "Messages in a Bottle"
wp.MaxActivationDistance = 10; wp.RequiresLineOfSight = false; wp.HoldDuration = 0; wp.Parent = counter
St.PrimaryPart = counter
St.WorldPivot = standCF
St.Parent = Fd
local s1 = Instance.new("Script"); s1.Name = "BottleServer"; s1.RunContext = Enum.RunContext.Server; s1.Source = SRC.BottleServer; s1.Parent = Fd
local s2 = Instance.new("Script"); s2.Name = "BottleClient"; s2.RunContext = Enum.RunContext.Client; s2.Source = SRC.BottleClient; s2.Parent = Fd
Fd.Parent = workspace
-- (round 2) the gifts popup waits while a bottle panel is open; the interaction counter skips the bottle bookkeeping items
local function patchOne(label, sc, find, repl, mark)
	if not (sc and sc:IsA("LuaSourceContainer")) then print("QQ BOTTLE " .. label .. ": not found; skipped") return end
	local o = sc.Source
	if o:find(mark, 1, true) then print("QQ BOTTLE " .. label .. ": already patched") return end
	local a, b = o:find(find, 1, true)
	if not a or o:find(find, b + 1, true) then print("QQ BOTTLE " .. label .. ": anchor not found once; skipped (harmless - tell the cloud thread)") return end
	local n = o:sub(1, a - 1) .. repl .. o:sub(b + 1)
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ BOTTLE " .. label .. ": would not compile; skipped") return end
	local bn = sc.Name .. "_pre_bottle1"; if not hb:FindFirstChild(bn) then local c = sc:Clone(); c.Name = bn; c.Enabled = false; c.Parent = hb end
	sc.Source = n
	print(string.format("QQ BOTTLE %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, bn))
end
local G = workspace:FindFirstChild("Gifts")
patchOne("GiftsClient", G and G:FindFirstChild("GiftsClient"),
	[==[album = true, boat = true}]==], [==[album = true, boat = true, bottle = true}   -- BOTTLE1_20261015: the bottle panel is modal too]==], "BOTTLE1_20261015")
local IA = workspace:FindFirstChild("Interact")
patchOne("InteractServer", IA and IA:FindFirstChild("InteractServer"),
	[==[local SKIP_PREFIX = {"daily_", "passport_", "champion", "thanks_"}]==], [==[local SKIP_PREFIX = {"daily_", "passport_", "champion", "thanks_", "bottle_"}   -- BOTTLE1_20261015: the bottle game's bookkeeping]==], "BOTTLE1_20261015")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Bottles") end)
print(string.format("QQ BOTTLE DONE: workspace.Bottles (BottleServer %d, BottleClient %d, BottleText %d chars); the stand at (%.0f, %.1f, %.0f); %d wash spots + the reply spot; send 15, find 10 (5 a day)%s",
	#s1.Source, #s2.Source, #mod.Source, site.X, site.Y, site.Z, #spots, old and ("; the old folder is HudBackup." .. old.Name) or ""))
