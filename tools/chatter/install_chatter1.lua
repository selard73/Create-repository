-- install_chatter1.lua (Studio EDIT mode; re-runnable). Job 88. Squirrel chatter: the Porto squirrels and both church mice
-- talk to passers-by (scattered: one at a time, by chance, with rests). workspace.SquirrelChatter with ChatterLines
-- (15444 chars) and ChatterClient (10755 chars). Undo: delete workspace.SquirrelChatter. No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local bub = RS:FindFirstChild("SquirrelBubble")
if not (bub and bub:IsA("ModuleScript")) then print("QQ CHATTER ABORT: ReplicatedStorage.SquirrelBubble not found") return end
-- every compile check before the first change, so an ABORT always means nothing changed
local LINES = [===[
-- ChatterLines (ModuleScript in workspace.SquirrelChatter): what the squirrels of Porto Nocciola, and the two church mice,
-- say to a passer-by (Shannon, Oct 11 2026: "squirrels in the Italy map randomly talk more to passers by"; "church mice at
-- both churches tell players that Jesus loves them as they walk by, with an Italian and French flair"). One pool per
-- registry id; the client picks a line at random, never the same one twice running. Keep a line under about 90 letters
-- so the bubble stays small. Everyone, the mice included, speaks only once you have found them (Shannon, Oct 11).
-- range = N: this one is heard from N studs instead of the folder's Range (for the ones standing high up).
return {
	-- ---------- the church mice ----------
	church_mouse_cousin = {lines = {
		"Buongiorno, amico! Jesus loves you - and so does this little mouse.",
		"Psst... Gesu ti ama. Jesus loves you. Pass it on!",
		"Ciao! The bells say it every hour: Jesus loves you.",
		"Welcome to Santa Marina. Jesus loves you - never forget it, okay?",
		"Mamma mia, what a beautiful day! Jesus loves you, you know.",
		"I may be small, but this is big news: Jesus loves you!",
		"Dio ti benedica. God bless you, friend - Jesus loves you.",
		"Quiet as a church mouse... except about this: Jesus loves you!",
	}},
	church_mouse = {lines = {
		"Bonjour, mon ami! Jesus loves you - and that is the best news in all of France.",
		"Psst... Jesus t'aime. Jesus loves you. Pass it on!",
		"Bienvenue! The bells say it every hour: Jesus loves you.",
		"Ooh la la, what a lovely day! Jesus loves you, you know.",
		"Slow down near the door and you get a sermon. The short one: Jesus loves you.",
		"Que Dieu te benisse. God bless you, friend - Jesus loves you.",
		"Three hundred and sixty-five sermons, one ending: Jesus loves you.",
		"Merci for stopping by! Remember: Jesus loves you.",
	}},

	-- ---------- the harbour ----------
	customs_squirrel = {lines = {
		"Anything to declare? No? Then welcome to Porto Nocciola!",
		"Passport, please... ah, you again. Avanti, avanti!",
		"You are dripping on my floor. Did you come by waterfall again?",
		"A stamp for you, a stamp for me. Everyone loves a stamp.",
	}},
	fishmonger_squirrel = {lines = {
		"Pesce fresco! Fresh fish! Fresher than the seagulls deserve.",
		"Caught any crabs? Bring them to Beppe, I pay in acorns! Golden ones pay best.",
		"Enzo catches the crabs, I sell the crabs. The crabs have not agreed to any of this.",
		"A crab trap and a little patience, and you are in business. The crab is not.",
		"Those seagulls owe me three sardines and an apology.",
		"The octopus is not for sale. He is a colleague.",
	}},
	deckhand_squirrel = {lines = {
		"Hop in, hop in! Mind the puddle. Mind the other puddle.",
		"The Stella Marina has never sunk. Well, not all the way.",
		"I swab the deck, I coil the rope, I nap. Mostly the nap.",
		"A sailor's life for me! Right after lunch.",
	}},
	netmender_squirrel = {lines = {
		"Every net has a hole. The trick is knowing which ones are on purpose.",
		"Sit, sit. Nonno Reti has a story. It is a long one.",
		"I mended this net in 1978. Or was it the other net?",
		"The sea gives, the sea takes, and the sea tangles everything.",
	}},
	gelato_squirrel = {lines = {
		"Today's flavour is Lemon Surprise. The surprise is how sour it is.",
		"One scoop or two? Three is also a number.",
		"Gelato tastes better by the sea. This is science.",
		"Tomorrow's flavour is named after whoever walks in first. Be nice.",
	}},
	boatpainter_squirrel = {lines = {
		"Fresh paint! Fresh paint! Why is everyone touching the fresh paint?",
		"This blue took me three tries. The sea got it right first time.",
		"My overalls have had more coats than the Nuova Alba.",
		"A boat without a name is just a floating bathtub.",
	}},
	realtor_squirrel = {lines = {
		"Sea view, sea breeze, sea gulls. Three for the price of one!",
		"Cosy, charming, compact. That means small. Very small.",
		"From the roof you can see the sea. Do not stand on the roof.",
		"Location, location, and a little bit more location.",
	}},
	italytourist_squirrel = {lines = {
		"Ciao! That means hello. Also goodbye. Also 'where is the bathroom?'",
		"Y'all, this is prettier than the pecan-pie contest, and that's saying something.",
		"Say cheese! Oh, wait, how do you say cheese in Italian? Ciao?",
		"I have taken four hundred pictures of the same boat. It keeps moving.",
	}},
	tightrope_squirrel = {range = 20, lines = {   -- (on the washing line, ~14 studs up)
		"Do not look down. I say that to myself, mostly.",
		"Signora Rosa says get off her washing line. Almost there!",
		"A little wobble is part of the act. The big wobble is not.",
		"Balance is easy. It is the falling that takes practice.",
	}},
	seacaptain_squirrel = {lines = {
		"I steer by the stars. On cloudy nights, by the bakery.",
		"The sea is calm today. Suspiciously calm.",
		"All aboard the Azzurra! Life jackets are under the... somewhere.",
		"A captain never gets lost. He takes the scenic route.",
	}},
	sunbather_squirrel = {lines = {
		"Any minute now, the perfect wave. Any minute.",
		"The sun is free, the view is free, the towel was five acorns.",
		"Surf's up! Well, surf's... level. Surf's here.",
		"Shh. I am working on my tan. It is very serious work.",
	}},
	crabcatcher_squirrel = {lines = {
		"Walk sideways. Think sideways. Be the crab.",
		"The crabs know it is me. The tourists do not.",
		"Want to catch crabs? Get a trap in the Acorn Store!",
		"One pinch and you learn. Two pinches and you learn properly.",
	}},
	-- (Tonio the Conductor is not here: TonioTalk already speaks for him when you walk up)
	lifeguard_squirrel = {lines = {
		"No swimming right after pizza! Wait half an hour. Twenty minutes for a small slice.",
		"I have whistled at every wave this summer. Not one has listened.",
		"No running! No splashing! No... fine, a little splashing.",
		"Pizza, then a nap, then a swim. In that order. The order matters.",
		"The water is lovely. I checked it from up here.",
		"Safety first! Sunscreen second. Gelato third. Pizza much, much later.",
	}},
	octopus_squirrel = {lines = {
		"The octopus took my bait. Then my bucket. Then my hat.",
		"Eight arms against two. The maths were never on my side.",
		"Today is the day I catch him. I say that every day.",
		"Have you seen a bucket? Red, with a dent? He has it.",
	}},

	-- ---------- the Via della Piazza ----------
	sassyshopper_squirrel = {lines = {
		"I am not shopping. I am investing in handbags.",
		"Excuse me, do you have this in a smaller size and a bigger discount?",
		"Three bags, two paws, one problem.",
		"Darling, that colour is so last summer. Mine is this summer.",
	}},
	pogo_squirrel = {lines = {
		"Boing! Boing! Boing! Sorry, I cannot stop. Literally.",
		"Up, down, up, down. The view changes a lot.",
		"I have bounced over this whole piazza. Twice. Today.",
		"Pogo tip: never stop. Second tip: there is no second tip.",
	}},
	pizzadelivery_squirrel = {lines = {
		"Thirty minutes or it is free. It is usually free.",
		"Hot pizza coming through! Well, warm pizza. Pizza.",
		"The address says third floor. There are two floors.",
		"I deliver pizza by day. By night I deliver more pizza.",
	}},
	baker_squirrel = {lines = {
		"Bread is out at six, gone by seven, missed by eight.",
		"The secret ingredient is love. And a lot of flour.",
		"Smell that? That is tomorrow's breakfast.",
		"A warm loaf can fix almost anything. Almost.",
	}},
	giulia_market_squirrel = {lines = {
		"Tomatoes, tomatoes! Red as a sunburnt tourist!",
		"Squeeze the peach, not the seller.",
		"Fresh today, fresher yesterday, who's counting?",
		"Buy two, I throw in a smile. Buy three, two smiles.",
	}},
	officer_acorn_police_squirrel = {lines = {
		"Move along, nothing to see here. Except the view. Look at the view.",
		"Acorn Police! Have you seen any suspicious nuts?",
		"Jaywalking is a crime. Jay-bouncing? I am still checking the rulebook.",
		"I keep the peace. The pizza keeps me.",
	}},
	goldenyears_squirrel = {lines = {
		"Fifty-four years. He still holds my paw crossing the piazza. Even when there are no carts.",
		"The secret? Say sorry first, laugh second, and share the last cannoli.",
		"We met right here, on this bench. It was a different bench. Same us.",
		"She still laughs at my jokes. I still tell the same ones. It works.",
		"We danced at every festa since 1972. Slower now, but still every one.",
		"Grow old with someone who makes you laugh. Then keep laughing. That is all.",
		"He forgets the bread. I forget to be cross. Fifty-four years of that.",
		"Come, sit a moment. The bench has room, and so do our hearts.",
	}},
	goodneighbor_squirrel = {lines = {
		"Need sugar? Need a ladder? Need a chat? I have all three.",
		"Your laundry is dry, your plants are watered, and I fed your cat.",
		"A good neighbour knocks. A great neighbour brings lasagna. Guess which one I am.",
		"Smell that? Lasagna. Two streets over, they are already running.",
	}},
	operasinger_squirrel = {lines = {
		"Laaaa! Pardon me, the high note just comes out sometimes.",
		"Every aria needs an audience. You will do nicely.",
		"I sing for the piazza. The piazza has not asked me to stop. Yet.",
		"Bravo! Brava! Bravissimo! That is for me, not you. Sorry.",
	}},
	broomseller_squirrel = {lines = {
		"A broom! A broom! Your doorstep has never looked worse!",
		"Free demonstration with every broom. Also without.",
		"This one sweeps. This one really sweeps. This one is a mop.",
		"Clean steps, clean heart. Buy a broom.",
	}},
	accordion_squirrel = {lines = {
		"Thirty years I play for the Fat Lady. Thirty years she sings over me.",
		"Request? I know every song. I play all of them the same.",
		"The accordion is heavy. The tips are light. Such is music.",
		"Dance if you like! Nobody is watching. Everybody is watching.",
	}},
	pizzamaker_squirrel = {lines = {
		"Watch this spin! Watch it! Watch out!",
		"Thin crust, thick crust, I make them all. Some on purpose.",
		"The oven is hot, the dough is ready, and the ceiling is a little bit pizza.",
		"Pineapple? In Porto Nocciola? We do not speak of this.",
	}},
	clockmaker_squirrel = {range = 34, lines = {   -- (on the clock tower's balcony, ~28 studs above the piazza)
		"The clock is right twice a day. I am working on a third.",
		"Tick, tock, tick... tock... there it goes again.",
		"Time flies. My clocks, sadly, do not.",
		"Do you have the time? Neither does the tower, apparently.",
	}},
	postcard_squirrel = {lines = {
		"Wish you were here! You are here. Buy a postcard anyway.",
		"A postcard a day keeps the family happy. Two a day and they frame them.",
		"This one has the sea, this one has the sea, this one has the sea at night.",
		"Stamps are extra. Smiles are included.",
	}},

	-- ---------- the Groves ----------
	lemonseller_squirrel = {lines = {
		"Lemons! Fresh from the tree behind me. Do not look at the tree behind me.",
		"Sour face? Try a lemon. Still sour? Try two.",
		"When life gives you lemons, sell them. That is business.",
		"These lemons saw the sunrise this morning. So did I. We are both tired.",
	}},
	olivepicker_squirrel = {lines = {
		"One for the basket, one for me. The basket is patient.",
		"Olive picking is slow work. Olive eating is fast work.",
		"These trees are older than the town. They have seen things.",
		"An olive a day keeps the... hmm. Keeps something away.",
	}},
	snorkel_squirrel = {lines = {
		"Gerald says hello. The fish. All of the fish are Gerald.",
		"Blub blub blub. Oh, sorry, I still had the snorkel in.",
		"The bay is full of wonders. Also a flip-flop. Just the one.",
		"Today I saw a fish so big it had its own smaller fish.",
	}},
	hiker_squirrel = {lines = {
		"The watchtower is four minutes away. I packed for three days.",
		"Always carry water, a map, and a snack. Mostly the snack.",
		"Which way is up? Trick question. Up is always up.",
		"I have hiked this path a hundred times. It is still uphill.",
	}},
	cliffdiver_squirrel = {lines = {
		"Ten out of ten! The judges agree. I am the judges.",
		"The trick is to jump before you think. Thinking is for the climb up.",
		"Splash first, questions later.",
		"From up here the sea looks small. From the sea, I look small. Fair.",
	}},
	stargazer_squirrel = {lines = {
		"I found three new stars last night. Two were the lighthouse.",
		"The stars are out all day too. The sun just talks over them.",
		"Make a wish! No, the other one, that one is a plane.",
		"Look up. No, further up. There. That is the one I named after you.",
	}},
	treasurehunter_squirrel = {lines = {
		"The treasure is where the gulls will not land. Think about it. I have, for years.",
		"Forty-two bottle caps, a spoon, and someone's car keys. Getting warmer. I can feel it.",
		"Three paces from the crooked rock, when the shadow points at the sea. Or was it the moon?",
		"X marks the spot. Sadly, so do all the other X's.",
		"Real treasure does not shine, you know. It waits. So do I. Mostly it waits.",
		"The map was drawn by a seagull. It is mostly circles. Seagulls love circles.",
		"Shh. Do you hear that? The sand is keeping a secret. Sand is terrible at secrets.",
		"They say a pirate buried his heart on this beach. I am looking for his lunchbox.",
	}},
	lighthousekeeper_squirrel = {lines = {
		"Forty years I keep the light. The light has never once thanked me.",
		"Fog tonight. Or steam from the pasta. Hard to say.",
		"I carry a lantern in case the lighthouse forgets.",
		"Ships see my light from ten miles away. My wife sees my socks from two.",
	}},
	keeperswife_squirrel = {lines = {
		"Married him for the view. Stayed for the laundry. So much laundry.",
		"Up those stairs twice a day with a basket. My knees have opinions.",
		"The sea is lovely, dear. Now bring in the washing before it is sea too.",
		"Forty years of lighthouse. Forty years of damp socks.",
	}},
	photographer_squirrel = {lines = {
		"One more! Just one more! Okay, one more after that.",
		"Say 'formaggio'! That is cheese. Hold it... hold it...",
		"The light is perfect right now. And now. And... missed it.",
		"I have a thousand sunset pictures. This one will be different.",
	}},
	droneflyer_squirrel = {lines = {
		"The drone has been up the lighthouse more than the keeper has.",
		"Smile! You are on camera. Very small camera. Very high up.",
		"Battery at five percent. Which means a crash landing. Which means a landing.",
		"From up there the whole town looks like a postcard. A wobbly one.",
	}},
	seaglass_squirrel = {lines = {
		"Green, brown, white, blue. Still looking for the purple one.",
		"Thirty years of waves to make one smooth piece. The sea is slow. I am slower.",
		"Every piece was a bottle once. Some of them were lemonade. I can tell.",
		"Look down when you walk the beach. Also so you do not step on me.",
	}},
	guitarist_squirrel = {lines = {
		"I know one song. Would you like to hear it again?",
		"Strum, strum, strum. That is the whole song, actually.",
		"Music is the language of the heart. Mine only knows one sentence.",
		"Requests welcome, as long as you request this song.",
	}},
	butterfly_squirrel = {lines = {
		"Three hats and a sandwich. Not one butterfly. The net is cursed.",
		"Shh! There is one! There it... goes. There it goes.",
		"Butterflies are faster than they look. Hats are slower.",
		"One day I will catch one. Today I caught a leaf. Progress.",
	}},
}
]===]
local CLIENT = [===[
-- ChatterClient (workspace.SquirrelChatter, RunContext Client): the squirrels of Porto Nocciola, and the two church mice,
-- talk to you as you walk by (Shannon, Oct 11 2026). Scattered on purpose: when you come within Range studs of a squirrel
-- that has a line pool, ONE nearby squirrel may speak, by Chance, after a short random pause; then nobody speaks for Gap
-- seconds, and that squirrel rests for about Cooldown seconds. Standing among them, one of them pipes up every Linger
-- seconds or so. A squirrel talks once you have found it (the mice too); TalkUnfound true lets the hidden ones talk.
-- Nothing is said while a panel is open, while an interact pill is up (on a screen any pill, drawn by the player's head; in
-- VR one within PillRange of the speaker), or (on a screen) unless the speaker stands where its bubble has room; a picked
-- line waits up to PendingSecs for its moment, then is let go.
-- Lines come from the ChatterLines module beside this script; the bubble is the game's own SquirrelBubble, unchanged (VR
-- included). Before speaking it checks that no bubble is up (the bubble ScreenGui on a screen, the billboards in VR).
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
		if not VR then   -- (on a flat screen the bubble sits up and to the right of the speaker: it must have room there, under the top row)
			local cam = workspace.CurrentCamera
			local v, on = cam:WorldToViewportPoint(pk.part.Position)
			local W, H = cam.ViewportSize.X, cam.ViewportSize.Y
			inView = on and v.X > 0.08 * W and v.X < 0.68 * W and v.Y > 0.4 * H and v.Y < 0.95 * H
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
]===]
for _, pair in ipairs({{"lines", LINES}, {"client", CLIENT}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ CHATTER ABORT: the " .. pair[1] .. " module does not compile: " .. tostring(err)) return end
end
local okL, tbl = pcall(loadstring(LINES)); if not (okL and type(tbl) == "table") then print("QQ CHATTER ABORT: the lines module does not return a table: " .. tostring(tbl)) return end
local ids, lines, missing = 0, 0, {}
for id, e in pairs(tbl) do
	ids += 1; lines += (type(e.lines) == "table" and #e.lines or 0)
	if not (workspace:FindFirstChild(id .. "_color") or workspace:FindFirstChild(id .. "_gray")) then table.insert(missing, id) end
end
table.sort(missing)
local old = workspace:FindFirstChild("SquirrelChatter")
local attrs = {}
if old then
	for k, v in pairs(old:GetAttributes()) do attrs[k] = v end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("SquirrelChatter_pre_" .. n) do n += 1 end
	old.Name = "SquirrelChatter_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetChildren()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "SquirrelChatter"
local defaults = {Range = 10, Chance = 0.55, Cooldown = 120, Gap = 9, Linger = 45, Secs = 4.2, PillRange = 8, PendingSecs = 6, TalkUnfound = false, Enabled = true}
for k, v in pairs(defaults) do if attrs[k] ~= nil then F:SetAttribute(k, attrs[k]) else F:SetAttribute(k, v) end end
local m = Instance.new("ModuleScript"); m.Name = "ChatterLines"; m.Source = LINES; m.Parent = F
local c = Instance.new("Script"); c.Name = "ChatterClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ CHATTER DONE: workspace.SquirrelChatter (ChatterLines %d, ChatterClient %d chars; %d speakers, %d lines; Range %s, Chance %s, Cooldown %s, Gap %s, Linger %s, Secs %s, TalkUnfound %s, Enabled %s)%s%s",
	#m.Source, #c.Source, ids, lines, tostring(F:GetAttribute("Range")), tostring(F:GetAttribute("Chance")), tostring(F:GetAttribute("Cooldown")), tostring(F:GetAttribute("Gap")), tostring(F:GetAttribute("Linger")), tostring(F:GetAttribute("Secs")), tostring(F:GetAttribute("TalkUnfound")), tostring(F:GetAttribute("Enabled")),
	#missing > 0 and ("; NO MODEL in workspace for: " .. table.concat(missing, ", ")) or "; every speaker has a model",
	(old and ("; the old folder is HudBackup." .. old.Name) or "") .. "; SquirrelBubble untouched (" .. #bub.Source .. ")"))
