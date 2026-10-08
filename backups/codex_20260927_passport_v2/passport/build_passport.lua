-- Passport + free books + illustrated Acorn Store. Edit mode only.
return function()
assert(not game:GetService("RunService"):IsRunning(),"EDIT only")
local changes = {}
table.insert(changes,{target=workspace.Bookshop.BookServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local action = RS:WaitForChild("BookAction")
local ev = RS:WaitForChild("BookEvent")
local Books = require(F:WaitForChild("Books"))
local byId = {}
for _, b in ipairs(Books) do byId[b.id] = b end
local function v3(prefix) return Vector3.new(F:GetAttribute(prefix .. "X"), F:GetAttribute(prefix .. "Y"), F:GetAttribute(prefix .. "Z")) end

-- inside, the camera cannot be scrolled out past the walls: a short zoom leash, given back at the door (or on respawn)
local INSIDE_ZOOM = F:GetAttribute("InsideZoom") or 16
local savedZoom = {}
local function leash(player, on)
	if on then
		if savedZoom[player] == nil then savedZoom[player] = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = INSIDE_ZOOM
	elseif savedZoom[player] ~= nil then
		player.CameraMaxZoomDistance = savedZoom[player]; savedZoom[player] = nil
	end
end
local function watch(player)
	player.CharacterAdded:Connect(function() leash(player, false) end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) savedZoom[p] = nil end)
-- the doors: fade, move, unfade (the client draws the fade; the server moves the character while it is dark)
local moving = {}
local function through(player, toInside)
	if moving[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	moving[player] = true
	local fade = F:GetAttribute("FadeSeconds") or 0.45
	ev:FireClient(player, "fade", fade, toInside)
	task.delay(fade + 0.05, function()
		if char.Parent and hrp.Parent then
			if toInside then
				local p = v3("In"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1)))
			else
				local p = v3("Out"); char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
			end
			char:SetAttribute("InBookshop", toInside or nil)
			leash(player, toInside)
		end
		task.wait(0.15)
		ev:FireClient(player, "unfade", fade)
		moving[player] = nil
	end)
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(F) then return end
	if prompt.Name == "EnterPrompt" then through(player, true)
	elseif prompt.Name == "ExitPrompt" then through(player, false)
	elseif prompt.Name == "BookPrompt" then
		local id = prompt:GetAttribute("BookId")
		local b = byId[id]
		if not b or b.soon then return end
		ev:FireClient(player, "book", id, true) -- everyone may read
	end
end)
-- Free reading: no purchase, ownership grant, or acorn deduction.
action.OnServerInvoke = function(player, what, id)
	local b = type(id) == "string" and byId[id]
	if not b or b.soon then return false, "no such book" end
	if what == "buy" or what == "owned" then return true, "Free to read" end
	if what == "read" then
		local char = player.Character
		local passport = RS:FindFirstChild("PassportActivity")
		if passport and char and char:GetAttribute("InBookshop") then passport:Fire(player,"book") end
		return true, {title = b.title, by = b.by, text = b.text, audio = b.audio or 0}
	end
	return false, "no such thing"
end
print("BookServer: ready - " .. #Books .. " books on the table")
]====]})
table.insert(changes,{target=workspace.Bookshop.BookClient,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local function hotbar(on) pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, on) end) end   -- the hotbar sits where the book's buttons go on a small screen
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local action = RS:WaitForChild("BookAction")
local ev = RS:WaitForChild("BookEvent")
local C = Color3.fromRGB
local Books = require(F:WaitForChild("Books"))
local byId = {}
for _, b in ipairs(Books) do byId[b.id] = b end
local COVER = {crumbs = C(46, 92, 140), story2 = C(160, 48, 44), story3 = C(58, 120, 72)}

-- the shop's sounds: the door as you go through it, and its own music, low, while you are inside; the music stops
-- while a book is open and comes back when it is closed (the map music goes quiet in here: MusicClient checks InBookshop)
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local doorSfx = Instance.new("Sound"); doorSfx.Name = "ShopDoor"; doorSfx.SoundId = F:GetAttribute("DoorSound") or "rbxassetid://131845870598154"; doorSfx.Volume = F:GetAttribute("DoorVolume") or 0.6; doorSfx.Parent = SoundService
local music = Instance.new("Sound"); music.Name = "ShopMusic"; music.SoundId = F:GetAttribute("ShopMusic") or "rbxassetid://9045766377"; music.Looped = true; music.Volume = 0; music.Parent = SoundService
task.spawn(function() pcall(function() ContentProvider:PreloadAsync({doorSfx, music}) end) end)
local MUSIC_VOL = F:GetAttribute("MusicVolume") or 0.1
local inside, reading = false, false
local musicTween
local function musicTo(target, secs)
	if musicTween then musicTween:Cancel() end
	musicTween = TweenService:Create(music, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Volume = target}); musicTween:Play()
end
local function updateMusic()
	if inside and not reading then
		if music.IsPaused then music:Resume() elseif not music.IsPlaying then music.Volume = 0; music:Play() end
		musicTo(MUSIC_VOL, 1.2)
	elseif inside then                                   -- a book is open: quiet, and hold the place in the tune
		musicTo(0, 0.4)
		task.delay(0.45, function() if inside and reading and music.IsPlaying then music:Pause() end end)
	else
		musicTo(0, 0.8)
		task.delay(0.85, function() if not inside and music.Volume <= 0.001 then music:Stop() end end)
	end
end
local function watchChar(char)
	inside = char:GetAttribute("InBookshop") == true
	updateMusic()
	char:GetAttributeChangedSignal("InBookshop"):Connect(function()
		inside = char:GetAttribute("InBookshop") == true
		updateMusic()
	end)
end
if player.Character then watchChar(player.Character) end
player.CharacterAdded:Connect(watchChar)

-- the fade to black for the doors
local fadeGui = Instance.new("ScreenGui"); fadeGui.Name = "BookshopFade"; fadeGui.ResetOnSpawn = false; fadeGui.IgnoreGuiInset = true; fadeGui.DisplayOrder = 20; fadeGui.Parent = pg
local black = Instance.new("Frame"); black.Size = UDim2.fromScale(1, 1); black.BackgroundColor3 = Color3.new(0, 0, 0); black.BackgroundTransparency = 1; black.BorderSizePixel = 0; black.Parent = fadeGui
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -100); note.Size = UDim2.fromOffset(460, 40); note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1
note.BorderSizePixel = 0; note.Font = Enum.Font.FredokaOne; note.TextSize = 18; note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""; note.Parent = fadeGui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local shownAt = 0
local function say(text)
	note.Text = text; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(3, function() if shownAt ~= mine then return end; TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
end

-- the book on screen: a 760x470 spread scaled to fit the screen
local FONT, SIZE, PAGE_W, PAGE_H = Enum.Font.Merriweather, 16, 312, 340
local gui = Instance.new("ScreenGui"); gui.Name = "BookReader"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 12; gui.Enabled = false; gui.Parent = pg
local dim = Instance.new("TextButton"); dim.Size = UDim2.fromScale(1, 1); dim.BackgroundColor3 = Color3.new(0, 0, 0); dim.BackgroundTransparency = 0.45; dim.Text = ""; dim.AutoButtonColor = false; dim.Parent = gui
local book = Instance.new("Frame"); book.AnchorPoint = Vector2.new(0.5, 0.5); book.Position = UDim2.fromScale(0.5, 0.5); book.Size = UDim2.fromOffset(760, 470)
book.BackgroundColor3 = C(92, 58, 40); book.BorderSizePixel = 0; book.Active = true; book.Parent = gui
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 14); bc.Parent = book
local scale = Instance.new("UIScale"); scale.Parent = book
local function fit()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 600)
	scale.Scale = math.clamp(math.min((vp.X - 30) / 760, (vp.Y - 30) / 470), 0.45, 1)
end
fit(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() fit() end) end
local function page(x)
	local p = Instance.new("Frame"); p.Position = UDim2.fromOffset(x, 18); p.Size = UDim2.fromOffset(356, 400); p.BackgroundColor3 = C(250, 242, 222); p.BorderSizePixel = 0; p.ClipsDescendants = true; p.Parent = book
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = p
	local t = Instance.new("TextLabel"); t.Name = "Text"; t.Position = UDim2.fromOffset(22, 20); t.Size = UDim2.fromOffset(PAGE_W, PAGE_H); t.BackgroundTransparency = 1
	t.Font = FONT; t.TextSize = SIZE; t.TextColor3 = C(52, 40, 30); t.TextWrapped = true; t.RichText = true; t.TextXAlignment = Enum.TextXAlignment.Left; t.TextYAlignment = Enum.TextYAlignment.Top; t.Text = ""; t.Parent = p
	local n = Instance.new("TextLabel"); n.Name = "Num"; n.AnchorPoint = Vector2.new(0.5, 1); n.Position = UDim2.new(0.5, 0, 1, -10); n.Size = UDim2.fromOffset(60, 16); n.BackgroundTransparency = 1
	n.Font = FONT; n.TextSize = 13; n.TextColor3 = C(140, 120, 100); n.Text = ""; n.Parent = p
	return p
end
local left, right = page(18), page(386)
local function pill(text, x, w)
	local b = Instance.new("TextButton"); b.Position = UDim2.fromOffset(x, 426); b.Size = UDim2.fromOffset(w, 34); b.BackgroundColor3 = C(240, 200, 90); b.BorderSizePixel = 0
	b.Font = Enum.Font.FredokaOne; b.TextSize = 17; b.TextColor3 = C(84, 48, 18); b.Text = text; b.AutoButtonColor = false; b.Visible = false; b.Parent = book
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = b
	return b
end
local prev, nxt = pill("<", 26, 44), pill(">", 690, 44)
local listen, close, buy = pill("Listen", 300, 160), pill("Close", 560, 110), pill("Buy", 240, 280)
-- a cover, for a book you do not own yet
local cover = Instance.new("Frame"); cover.Position = UDim2.fromOffset(18, 18); cover.Size = UDim2.fromOffset(724, 400); cover.BackgroundColor3 = C(46, 92, 140); cover.BorderSizePixel = 0; cover.Visible = false; cover.Parent = book
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = cover
local ct = Instance.new("TextLabel"); ct.Position = UDim2.fromOffset(40, 50); ct.Size = UDim2.new(1, -80, 0, 150); ct.BackgroundTransparency = 1; ct.Font = Enum.Font.Antique; ct.TextScaled = true; ct.TextWrapped = true; ct.TextColor3 = C(255, 246, 220); ct.Parent = cover
local cb = Instance.new("TextLabel"); cb.Position = UDim2.fromOffset(40, 215); cb.Size = UDim2.new(1, -80, 0, 30); cb.BackgroundTransparency = 1; cb.Font = FONT; cb.TextSize = 18; cb.TextColor3 = C(255, 246, 220); cb.Parent = cover
local cp = Instance.new("TextLabel"); cp.Position = UDim2.fromOffset(40, 290); cp.Size = UDim2.new(1, -80, 0, 60); cp.BackgroundTransparency = 1; cp.Font = Enum.Font.FredokaOne; cp.TextSize = 22; cp.TextColor3 = C(255, 246, 220); cp.TextWrapped = true; cp.Parent = cover

-- flowing a story into pages: paragraph by paragraph, and word by word when a paragraph is longer than a page
local function fits(text) return TextService:GetTextSize(text, SIZE, FONT, Vector2.new(PAGE_W, 100000)).Y <= PAGE_H end
local function paginate(text)
	text = text:gsub("\r", "")
	local pages, cur = {}, ""
	local function push() if cur ~= "" then pages[#pages + 1] = cur; cur = "" end end
	for para in string.gmatch(text .. "\n\n", "(.-)\n\n") do
		para = para:gsub("^%s+", ""):gsub("%s+$", "")
		if para ~= "" then
			local cand = (cur == "") and para or (cur .. "\n\n" .. para)
			if fits(cand) then
				cur = cand
			else
				push()
				if fits(para) then
					cur = para
				else
					for word in para:gmatch("%S+") do
						local c2 = (cur == "") and word or (cur .. " " .. word)
						if fits(c2) then cur = c2 else push(); cur = word end
					end
				end
			end
		end
	end
	push()
	if #pages == 0 then pages[1] = "" end
	return pages
end

local current                                                -- {id, pages, spread, audio, sound}
local function stopSound()
	if current and current.sound then current.sound:Stop(); current.sound:Destroy(); current.sound = nil end
	listen.Text = "Listen"
end
local function show(spread)
	local pages = current.pages
	current.spread = spread
	local single = book:GetAttribute("SinglePage") == true
	local li, ri = single and spread or spread * 2 - 1, single and spread or spread * 2
	left.Text.Text = pages[li] or ""; left.Num.Text = pages[li] and tostring(li) or ""
	right.Text.Text = pages[ri] or ""; right.Num.Text = pages[ri] and tostring(ri) or ""
	prev.Visible = spread > 1
	nxt.Visible = ri < #pages
end
local function openReader(id, data)
	stopSound()
	local head = string.upper(data.title) .. "\n" .. (data.by or "") .. "\n\n"
	current = {id = id, sourceText = head .. (data.text or ""), pages = paginate(head .. (data.text or "")), spread = 1, audio = tonumber(data.audio) or 0}
	cover.Visible = false; buy.Visible = false
	left.Visible, right.Visible = true, book:GetAttribute("SinglePage") ~= true
	close.Visible = true; listen.Visible = current.audio > 0
	show(1)
	gui.Enabled = true; hotbar(false)
	reading = true; updateMusic()
end
local function openCover(id)
	stopSound()
	local b = byId[id]; if not b then return end
	current = {id = id}
	left.Visible, right.Visible = false, false
	prev.Visible, nxt.Visible, listen.Visible = false, false, false
	cover.Visible = true; cover.BackgroundColor3 = COVER[id] or C(46, 92, 140)
	ct.Text = b.title; cb.Text = b.by or ""; cp.Text = "Free to read. Make yourself comfortable."
	buy.Visible = true; buy.Text = "Read - free"; close.Visible = true
	gui.Enabled = true; hotbar(false)
end
local busy = false
buy.Activated:Connect(function()
	if not current or busy then return end
	busy = true; buy.Text = "..."
	local ok, res = action:InvokeServer("buy", current.id)
	if not ok then say(tostring(res)); buy.Text = "Read - free"; busy = false; return end
	local ok2, data = action:InvokeServer("read", current.id)
	busy = false
	if ok2 then say("It is yours. Enjoy."); openReader(current.id, data) end
end)
prev.Activated:Connect(function() if current and current.spread and current.spread > 1 then show(current.spread - 1) end end)
nxt.Activated:Connect(function() if current and current.spread then show(current.spread + 1) end end)
local function shut() stopSound(); gui.Enabled = false; current = nil; hotbar(true); reading = false; updateMusic() end
close.Activated:Connect(shut)
dim.Activated:Connect(shut)
listen.Activated:Connect(function()
	if not current then return end
	if current.sound then stopSound() return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. tostring(current.audio); s.Volume = 1; s.Parent = book; s:Play()
	current.sound = s; listen.Text = "Stop"
	s.Ended:Connect(function() if current and current.sound == s then stopSound() end end)
end)
-- the prompts say Buy or Read depending on what you own (locally: a prompt's text is per screen)
local function refreshPrompts()
	for _, pr in ipairs(F:GetDescendants()) do
		if pr:IsA("ProximityPrompt") and pr.Name == "BookPrompt" then
			local id = pr:GetAttribute("BookId"); local b = byId[id]
			if b and not b.soon then
				local text = "Read - free"
				if pr.ActionText ~= text then
					pr.ActionText = text
					-- the prompt pill only reads its text when the prompt appears, so blink it if it is showing (a
					-- same-frame toggle is a no-op to the engine; it needs a frame or two off)
					pr.Enabled = false; task.delay(0.15, function() pr.Enabled = true end)
				end
			end
		end
	end
end
refreshPrompts()
for _, b in ipairs(Books) do player:GetAttributeChangedSignal("Item_book_" .. b.id):Connect(refreshPrompts) end
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "fade" then
		doorSfx.TimePosition = 0; doorSfx:Play()                 -- the door, going in and coming out
		TweenService:Create(black, TweenInfo.new(a or 0.45), {BackgroundTransparency = 0}):Play()
	elseif what == "unfade" then
		TweenService:Create(black, TweenInfo.new((a or 0.45) * 1.4), {BackgroundTransparency = 1}):Play()
	elseif what == "book" then
		if byId[a] then
			local ok, data = action:InvokeServer("read", a)
			if ok then openReader(a, data) else say(tostring(data)) end
		else
			openCover(a)
		end
	end
end)

-- A phone gets one readable page, with native text sizing and 44px controls.
fit=function()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000,600)
 local mobile=game:GetService("UserInputService").TouchEnabled or vp.Y<520
 local w,h=mobile and math.min(560,vp.X-28) or 760,mobile and math.min(470,vp.Y-88) or 470
 book:SetAttribute("SinglePage",mobile)
 book.AnchorPoint=Vector2.new(.5,0);book.Position=UDim2.new(.5,0,0,72)
 book.Size=UDim2.fromOffset(w,h);scale.Scale=mobile and 1 or math.min(1,(vp.Y-88)/470,(vp.X-28)/760)
 PAGE_W=mobile and w-80 or 312;PAGE_H=mobile and h-126 or 340;SIZE=mobile and 17 or 16
 left.Size=UDim2.fromOffset(mobile and w-36 or 356,mobile and h-78 or 400)
 left.Text.Size=UDim2.fromOffset(PAGE_W,PAGE_H);left.Text.TextSize=SIZE
 right.Visible=not mobile and reading
 for _,b in ipairs({prev,nxt,listen,close,buy}) do b.Position=UDim2.fromOffset(b.Position.X.Offset,mobile and h-52 or 426);b.Size=UDim2.fromOffset(b.Size.X.Offset,mobile and 44 or 34) end
 prev.Position=UDim2.fromOffset(18,mobile and h-52 or 426)
 nxt.Position=UDim2.fromOffset(w-62,mobile and h-52 or 426)
 close.Position=UDim2.fromOffset(w-182,mobile and h-52 or 426)
 listen.Position=UDim2.fromOffset(82,mobile and h-52 or 426)
 if current and current.sourceText then current.pages=paginate(current.sourceText);show(math.min(current.spread,math.max(1,math.ceil(#current.pages/(mobile and 1 or 2))))) end
end
fit()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 fit();if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() fit() end) end
end)
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
 if gui.Enabled then pg:SetAttribute("OpenPanel","book")
 elseif pg:GetAttribute("OpenPanel")=="book" then pg:SetAttribute("OpenPanel",nil) end
end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if gui.Enabled and pg:GetAttribute("OpenPanel")~="book" then shut() end end)
]====]})
table.insert(changes,{target=workspace.Bookshop.Books,source=[====[-- Books: the three books on the Librairie's table. text = the story (a blank line starts a new paragraph; the reader
-- flows it into pages; <i>..</i> and <b>..</b> work); audio = a narration sound id, or 0 for none yet; soon = still
-- being written. The source stays plain ASCII: "@e" becomes an e-acute and "--" an em dash when the module loads.
local E, EG, AC, DASH = utf8.char(233), utf8.char(232), utf8.char(226), utf8.char(8212)   -- e-acute, e-grave, a-circumflex, em dash
local function fix(s) return (s:gsub("@e", E):gsub("@g", EG):gsub("@b", AC):gsub("%-%-", DASH)) end
local books = {
	{id = "crumbs", title = "The Spy Who Came In From the Crumbs", by = "as told to G@erard the Mailman Squirrel", price = 0, audio = 0, text = [[
The International Spy Squirrel had a secret code name, a secret hideout and a secret handshake, and on Tuesday morning he forgot all three at once.

"Part of the cover," he told his reflection in the boulangerie window.

Behind the glass, the French Waiter Squirrel glided past with a tray held high on one paw. The tray was covered with a silver dome. A DOME. Nobody covers a croissant with a dome unless it is not a croissant.

The Spy narrowed his eyes. "Mission," he whispered, and pulled his beret down so far that he walked into a lamp post.

He tailed the tray across the Rue de Noisette.

Past the fountain, where the Bird Feeder Squirrel's pigeons saluted. Past the cafe, where the Philosopher Squirrel looked up from a cup he had been drinking since spring and asked, "If a secret can be smelled from the bridge, is it still a secret?"

The Spy did not answer. Spies do not answer. Also his stomach was making a noise like a small motorbike.

Outside the bookshop, Marcel the Mime pressed both paws against an invisible wall and mouthed something urgent. It was either "DANGER" or "BUTTER". It was hard to tell with Marcel.

At the corner the Waiter stopped, turned, and lifted the dome with a sigh so dramatic that three flowerpots wilted.

Underneath sat one warm croissant, golden as a medal.

"For you, monsieur," said the Waiter. "You have followed me for eleven minutes. In this town, that is practically a reservation."

The Spy took the croissant. He ate it in two bites, which is not how spies eat, but it had been a long morning.

That evening, in his secret hideout (the third bench on the left), he wrote his report:

MISSION ACCOMPLISHED. TARGET DELICIOUS. HANDSHAKE STILL MISSING.

Then he fell asleep with crumbs in his beret, which is how every good spy story ends.
]]},
	{id = "story2", title = "La Tortue", by = "by Shannon", price = 0, audio = 0, text = [[
In the village of Saint-Bidule, the mail arrived at 4 p.m., which was impressive, because it left the post office at 8 a.m. and the village had eleven houses.

This was because of G@erard.

G@erard was a gray squirrel who had delivered the mail for thirty-one years. He stopped to bury an acorn in every third flowerpot, and he believed every letter deserved to be read aloud to its recipient, with commentary.

"A postcard from your sister in Nice," he told Madame Fournier, holding it up to the light. "She says the pinecones are lovely. Her lowercase <i>g</i>, however, is a cry for help."

Madame Fournier snatched it and slammed her door shut. G@erard nodded, satisfied, and scampered up the hill to the last house on his route: the atelier of Margaux Delacroix-Pim, fashion designer and red squirrel.

Margaux was not having a good week.

Her show at Paris Fashion Week was in three days. She had nothing. Her floor was covered in chewed-up sketches, and pinned above her desk was the review that had haunted her for a year. It came from La Tortue, the most feared fashion critic among the squirrels of France, whom no one had ever seen. La Tortue had described her last collection in four words:

<i>"A beige apology. Pass."</i>

G@erard knocked. Margaux opened the door with a pencil behind each ear and a third in her tail.

"Acorn bill," G@erard announced. "The font is aggressive. I would not pay it."

"G@erard, I don't have time--"

He was already looking past her at the sketches. "Those tail sleeves," he said gently, "are too polite."

She shut the door on him.

* * *

That was when the tourist appeared.

His name was Dale, he was a fox squirrel from Tulsa, and he had arrived in France by stowing away in a family's carry-on bag, which he described as "a real nice flight, a little snug." He was wearing a white hotel bathrobe belted over cargo shorts, a sun visor, a fanny pack, one hiking boot, and one flip-flop. A souvenir beret sat on top of the visor. A paper map was knotted around his neck like a cape, flapping in the wind.

"Hi there!" Dale said. "The airline lost my luggage. Is this the way to the Eiffel Tower? I hear it's the tallest tree in France."

G@erard considered this. "It is 700 kilometers that way. And it is not a tree. Many have been disappointed."

"Well, shoot. Is it hoppable?"

Margaux's door flew open. She had seen Dale through the window, and she was staring at him the way other squirrels stare at a bird feeder.

"Don't. Move."

Dale froze, which, for a squirrel, is an emergency setting. "Is there a hawk?"

"The bathrobe," Margaux whispered. "Over the <i>cargo shorts</i>. The beret <i>on top</i> of the visor. One boot, one <i>flip-flop</i>. It's wrong in every way. It's <i>magnificent</i>."

She dragged Dale inside, sat him on a stool, and began sketching so fast her whiskers vibrated.

G@erard leaned in the doorway. "Make the visor bigger," he said.

"Nobody asked you, G@erard."

He shrugged and left. Margaux made the visor bigger.

* * *

Three days later, the lights went down on a park bench in the Jardin du Luxembourg, and the collection called <b>PERDUE</b> -- "Lost" -- came down the runway.

Squirrels in silk bathrobes. Squirrels in cashmere cargo shorts. A gown made entirely of folded maps. Visors so wide they cast shade on the front row. Every model wore one boot and one flip-flop, which made the walk sound like <i>clomp-flap, clomp-flap</i>, and gave the whole show the rhythm of a very confused horse.

The bench was silent.

Then a chipmunk editor from Milan stood up and began to applaud. Then everyone did.

Dale, in the front row in his same bathrobe, turned to the squirrel next to him. "I don't get it, but I love it."

She was taking notes on a leaf. "That's fashion, darling."

* * *

The next morning, Margaux was pacing her tiny Paris hotel room when there was a knock.

It was G@erard, holding a single envelope.

"G@erard? You're three hours from your route!"

"Special delivery," he said. "I rode in a baguette delivery truck. It was very slow. I felt at home."

Margaux tore open the envelope. Inside was a review, handwritten on the famous green leaf paper:

<i>"Finally, she was brave. Five stars. -- La Tortue."</i>

She read it twice. Then she studied the handwriting. The slanted capitals. The small, judgmental dot over the <i>i</i>.

She had seen that handwriting before. On a note stuck to her acorn bill last spring that read, <i>Pay this, but know that I disapprove of the font.</i>

Her tail puffed up to twice its size.

"<i>You're</i> La Tortue?"

G@erard adjusted his cap. "Every letter in France passes through a mail squirrel's paws. You learn a great deal about taste."

"But why a <i>turtle</i>?"

He gave her a long, patient look. "Madame. Have you seen how I deliver the mail?"

* * *

Dale hopped in to say goodbye, still in the bathrobe. G@erard reached into his mail pouch and pulled out a battered suitcase with a tag reading <i>DALE -- TULSA</i>.

"This arrived at my post office in March," he said.

"<i>March?</i> It's June!"

"The tag was written in Comic Sans. I needed time to recover."

Margaux held her breath as Dale unzipped it. This was it. The real Dale. The proper clothes. The end of the magic.

Dale lifted out a fresh white bathrobe. Then a second pair of cargo shorts. Then another visor, another beret, one hiking boot, and one flip-flop.

"Oh, thank goodness," Dale said. "My backups."

Margaux fell over sideways, the way squirrels do.

G@erard nodded approvingly. "Now <i>that</i>," he said, "is a squirrel who is not apologizing."
]]},
	{id = "story3", title = "Picnic Pierre Will Not Come Down", by = "as told by Sleepy Sylvain, who slept through it", price = 0, audio = 0, text = [[
Picnic Pierre climbed the windmill on a Tuesday with a baguette under one arm and a small round cheese under the other, and he did not come back down.

"Lunch tastes better up here," he called, from the very tip of the highest sail. "Also I cannot get down. But mostly the first thing."

By Wednesday the whole Ch@bteau had gathered at the bottom of the hill.

Farmer Fernand brought the tractor, in case a tractor helped. It did not help. The rooster crowed at Pierre several times, which was not so much a plan as a habit.

Grape Stomper Gigi stomped a great heap of grapes into a purple cushion at the foot of the mill, in case Pierre fell. "It is either a cushion or a jam," she said. "We will find out."

The Beekeeper sent up a bee with a message. The bee came back with crumbs on it. The message had not been read. The bee had been fed.

The Truffle Hunter's pig sniffed the windmill carefully from every side and then found a truffle, which was not the point, but was still quite a good truffle.

The Shepherd and his lamb stood together and looked worried. The lamb looked more worried. It is hard to say why.

Sleepy Sylvain slept through the entire thing on a hay bale and was, in the end, the only one who did not get sunburnt.

"Has anyone asked," said the Ch@gvre Squirrel from the well, "whether he <i>wants</i> to come down?"

Everybody looked at everybody else. Then everybody looked up.

"NO," said Pierre, and bit into his baguette, and the sail turned him gently out of sight.

* * *

On Thursday a small figure came puffing up the lavender path with a letter bag over his shoulder. It was G@erard, the mail squirrel from the village, and he had a postcard for Pierre.

"It is from his aunt in Lyon," G@erard told the crowd, holding it up to the light. "She hopes he is eating well. The exclamation marks are excessive. Three, for a postcard. Who does she think she is?"

"He is up there," said Gigi, pointing.

G@erard looked at the sail. Then he took off his cap, tucked it into his bag, waited for the lowest arm to sweep past, and grabbed on.

The Ch@bteau watched a mail squirrel go all the way round a windmill, upside down at the top, holding a postcard in his teeth and giving no sign whatsoever that this was unusual.

At the tip of the highest sail he handed Pierre the postcard, read it to him anyway, sat down, and was given some cheese.

"Well?" shouted the Beekeeper, when the sail brought them round again.

"He is right," G@erard called down. "Lunch does taste better up here."

* * *

That is how the Ch@bteau came to have its picnic on the windmill.

Gigi went up first, because someone had to test the cushion and she wanted it to be her. Then the Shepherd, carrying the lamb, who was fine about it. Then the Beekeeper, who left the bees behind, and the Truffle Hunter, who did not leave the pig behind, and regretted it a little at the top.

Farmer Fernand parked the tractor and went up with a basket of tomatoes, and the rooster went up on the tractor's roof, then on Fernand's head, then on the sail, and crowed at the whole valley from the highest point in it, which he had always wanted to do.

Sleepy Sylvain woke at noon, saw the entire Ch@bteau turning slowly in the sky, eating lunch, and decided he was still asleep. He turned over. He was, for once, the only one on the ground.

And Picnic Pierre, who still could not get down and no longer wished to, passed the baguette along the sail and said what he always says.

"It tastes better up here."

Nobody, that day, disagreed.
]]},
}
for _, b in ipairs(books) do b.title = fix(b.title); b.by = fix(b.by or ""); b.text = fix(b.text) end
return books
]====]})
table.insert(changes,{target=workspace.Glaces.GlaceServer,source=[====[local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")
local F = script.Parent
local ev = F:WaitForChild("GlaceEvent")
local C = Color3.fromRGB
local FLAVOURS = {{"Lavande", C(186, 160, 222)}, {"Pistache", C(170, 210, 130)}, {"Fraise", C(245, 150, 170)},
	{"Chocolat", C(125, 78, 52)}, {"Citron", C(250, 232, 120)}, {"Vanille", C(252, 244, 220)}}
local WAFFLE, WAFFLE2 = C(214, 166, 96), C(190, 140, 78)
local UP = CFrame.Angles(0, 0, math.rad(90))
local MYSTERE = "Myst" .. utf8.char(232) .. "re"
local SPRINKLES = {C(255, 90, 110), C(255, 200, 60), C(90, 200, 120), C(90, 160, 255), C(200, 110, 230), C(255, 140, 60)}

local function sound(key, parent)
	local id = tonumber(F:GetAttribute(key)) or 0
	if id <= 0 or not parent then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = 0.7
	s.RollOffMinDistance = 8; s.RollOffMaxDistance = 60; s.Parent = parent; s:Play()
	Debris:AddItem(s, 7)
	return s
end

local function piece(name, size, colour, shape, handle, offset, tool)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = colour; p.Material = Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = handle.CFrame * offset
	local w = Instance.new("Weld"); w.Part0 = handle; w.Part1 = p; w.C0 = offset; w.Parent = p
	p.Parent = tool
	return p, w
end

-- the cone: five waffle rings narrowing to a point, the Handle an invisible block at the rim; scoops of 0.56
-- stacked on top, each on its own weld so a lick can shrink it and settle it back down on the one below
local function makeCone(n)
	local tool = Instance.new("Tool"); tool.Name = "Ice Cream"; tool.CanBeDropped = false; tool.RequiresHandle = true
	tool.ToolTip = "Tap to lick!"
	local gx, gy, gz = F:GetAttribute("GripX") or 0, F:GetAttribute("GripY") or 0, F:GetAttribute("GripZ") or 0
	tool.Grip = CFrame.Angles(math.rad(gx), math.rad(gy), math.rad(gz))
	local h = Instance.new("Part"); h.Name = "Handle"; h.Size = Vector3.new(0.3, 0.3, 0.3); h.Transparency = 1
	h.CanCollide = false; h.CanQuery = false; h.CanTouch = false; h.Massless = true; h.CFrame = CFrame.new(0, 100, 0); h.Parent = tool
	for i, r in ipairs({0.07, 0.12, 0.17, 0.22, 0.27}) do
		piece("Cone", Vector3.new(0.14, r * 2, r * 2), (i % 2 == 0) and WAFFLE2 or WAFFLE, Enum.PartType.Cylinder, h,
			CFrame.new(0, -0.62 + i * 0.13, 0) * UP, tool)
	end
	local scoops, names, mystery = {}, {}, false
	for i = 1, n do
		-- the secret flavour: now and then one scoop is the Mystere - white, with rainbow sprinkles - just for the surprise
		local secret = not mystery and math.random() < (F:GetAttribute("MysteryChance") or 0.12)
		local f = secret and {MYSTERE, C(252, 244, 250)} or FLAVOURS[math.random(#FLAVOURS)]
		local p, w = piece("Scoop", Vector3.new(0.56, 0.56, 0.56), f[2], Enum.PartType.Ball, h, CFrame.new(0, 0.28 + (i - 1) * 0.42, 0), tool)
		if secret then
			mystery = true
			for k = 1, 9 do                                      -- sprinkles, riding on the scoop (and gone with it)
				local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.1, math.random() - 0.5).Unit
				local s = Instance.new("Part"); s.Name = "Sprinkle"; s.Shape = Enum.PartType.Ball; s.Size = Vector3.new(0.1, 0.1, 0.1)
				s.Color = SPRINKLES[(k - 1) % #SPRINKLES + 1]; s.Material = Enum.Material.SmoothPlastic
				s.CanCollide = false; s.CanQuery = false; s.CanTouch = false; s.Massless = true; s.CFrame = p.CFrame * CFrame.new(dir * 0.28)
				local sw = Instance.new("Weld"); sw.Name = "SprinkleWeld"; sw.Part0 = p; sw.Part1 = s; sw.C0 = CFrame.new(dir * 0.28); sw.Parent = s
				s.Parent = p
			end
		end
		scoops[i] = {part = p, weld = w, licks = 0}
		if not table.find(names, f[1]) then names[#names + 1] = f[1] end
	end
	return tool, scoops, names, mystery
end

local holding = {}                                   -- player -> the tool they are holding
local function brainFreeze(player, char)
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local a = Instance.new("Attachment"); a.Parent = head
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255), Color3.fromRGB(150, 210, 255)); pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}); pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(3, 7); pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.Parent = a
	pe:Emit(40)
	Debris:AddItem(a, 2)
	local bb = Instance.new("BillboardGui"); bb.Name = "BrainFreeze"; bb.Size = UDim2.fromOffset(220, 54); bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true; bb.MaxDistance = 70; bb.Adornee = head
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.FredokaOne
	t.TextScaled = true; t.Text = "BRAIN FREEZE!"; t.TextColor3 = Color3.fromRGB(150, 215, 255); t.TextStrokeTransparency = 0
	t.TextStrokeColor3 = Color3.fromRGB(255, 255, 255); t.Parent = bb
	bb.Parent = head
	Debris:AddItem(bb, 2.2)
	sound("FreezeSound", head)
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "glace") end
	ev:FireClient(player, "freeze")
end

local function give(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return end
	if holding[player] and holding[player].Parent then holding[player]:Destroy() end
	local roll = math.random()
	local tool, scoops, names, mystery = makeCone(roll < 0.3 and 1 or (roll < 0.75 and 2 or 3))
	holding[player] = tool
	local busy = false
	-- one lick sound at a time: Shannon's lick runs 4.7 s and taps can come every 0.2 s, so each new lick stops the last,
	-- and the brain freeze stops the final one just after it starts
	local lickSnd
	local function hush() if lickSnd then lickSnd:Stop(); lickSnd:Destroy(); lickSnd = nil end end
	tool.Activated:Connect(function()
		if busy then return end
		busy = true
		-- the arm brings the cone up to the mouth on every screen (GlaceClient), and the lick lands when it gets there
		ev:FireAllClients("lick", player, tool)
		task.wait(0.3)
		local top = scoops[#scoops]
		if top then
			top.licks += 1
			local per = F:GetAttribute("Licks") or 2
			hush(); lickSnd = sound("LickSound", tool:FindFirstChild("Handle"))
			if top.licks >= per then
				top.part:Destroy(); scoops[#scoops] = nil
			else
				local s = 0.56 * (1 - top.licks / (per + 0.6))       -- a lick smaller, its bottom where it was: still on the one below
				top.part.Size = Vector3.new(s, s, s)
				top.weld.C0 = CFrame.new(0, 0.28 + (#scoops - 1) * 0.42 - (0.56 - s) / 2, 0)
				for _, sp in ipairs(top.part:GetChildren()) do          -- the sprinkles stay on the surface
					local sw = sp:FindFirstChild("SprinkleWeld")
					if sw then sw.C0 = CFrame.new(sw.C0.Position.Unit * (s / 2)) end
				end
			end
		end
		if #scoops == 0 then
			task.delay(0.6, hush)
			brainFreeze(player, char)
			-- then a bite of the cone: up to the mouth once more, the crunch, and it is gone (the tool goes once the arm is
			-- back down, so the arm is not left hanging in the air)
			task.delay(0.85, function() if tool.Parent then ev:FireAllClients("lick", player, tool, true) end end)
			task.delay(1.2, function()
				if not tool.Parent then return end
				sound("CrunchSound", char and char:FindFirstChild("Head"))
				for _, d in ipairs(tool:GetDescendants()) do if d:IsA("BasePart") then d.Transparency = 1 end end
				task.delay(0.75, function() if tool.Parent then tool:Destroy() end end)
			end)
			return
		end
		task.wait(0.25)
		busy = false
	end)
	tool.Parent = char                                   -- straight into the hand
	sound("GetSound", char:FindFirstChild("Head"))
	ev:FireClient(player, "got", names)
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "GlacePrompt" and prompt:IsDescendantOf(F) then give(player) end
end)
Players.PlayerRemoving:Connect(function(p) holding[p] = nil end)
print("Glaces: the cart is open")
]====]})
table.insert(changes,{target=workspace.SandstoneClimb.ClimbServer,source=[====[-- ClimbServer: the Sandstone Climb's clock (server-side), the bell, the board and the personal-best acorns
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("ClimbEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local zone = F:WaitForChild("Summit"):WaitForChild("BellZone")
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- the bell: whoever reaches it rings it for everyone, one ring at a time ----
local lastRing = 0
local function ring(player)
	if os.clock() - lastRing < 6 then return end
	lastRing = os.clock()
	ev:FireAllClients("ring", player and player.DisplayName or "")
end

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "CliffClimb_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("ClimbBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a climber"
			end
		end
	end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end
				return cs
			end)
		end)
		if not ok then warn("SandstoneClimb: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a climb ----
local climbs = {}                                            -- player -> {phase, t0}
local function stop(player, why)
	local c = climbs[player]
	if not c then return end
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	ev:FireClient(player, "stop", why)
end
local function start(player)
	if climbs[player] then stop(player, "restart") end
	if player:GetAttribute("Racing") then ev:FireClient(player, "busy"); return end
	if not player:GetAttribute("SaveLoaded") then return end
	local c = {phase = "count"}
	climbs[player] = c
	player:SetAttribute("Climbing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, item(player, "climb_best"))
	task.delay(cd, function()
		if climbs[player] ~= c then return end
		c.phase = "run"; c.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 10) * 60, function() if climbs[player] == c then stop(player, "time") end end)
	end)
end
local function finish(player)
	local c = climbs[player]
	if not c or c.phase ~= "run" then return end
	local secs = os.clock() - c.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	climbs[player] = nil
	player:SetAttribute("Climbing", nil)
	local best = item(player, "climb_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "climb_best", cs) end
	local minS = F:GetAttribute("MinSeconds") or 10
	local prize = 0
	if isBest and secs >= minS then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "climb") end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("SandstoneClimb: %s climbed to the bell in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= minS then
		if isBest then task.spawn(submit, player, cs) end
	else
		warn(string.format("SandstoneClimb: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
zone.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	ring(player)
	if climbs[player] then finish(player) end
end)
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
local function startSpot()
	local st = F:FindFirstChild("StartStone", true)
	local y = F:GetAttribute("StartY") or ((st and st.Position.Y or 5) + 3)
	return Vector3.new(st and st.Position.X or 498, y, st and st.Position.Z or -243)
end
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not climbs[player] then
		local char = player.Character
		local p = startSpot()
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(0, 0, -1))) end
		task.wait(0.3)
		start(player)
	end
end)
local function watch(player)
	player.CharacterAdded:Connect(function() if climbs[player] then stop(player, "fell") end end)
end
Players.PlayerAdded:Connect(watch)
for _, pl in ipairs(Players:GetPlayers()) do watch(pl) end
Players.PlayerRemoving:Connect(function(pl) climbs[pl] = nil end)
if RunService:IsStudio() then                               -- Studio only: start a climb without the prompt (for tests)
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ClimbDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) start(player); return "started" end
end
print("SandstoneClimb: ready")
]====]})
table.insert(changes,{target=workspace.ForestRace.RaceServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("RaceEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local MAP = F:GetAttribute("Map") or "forest"
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local isRace = {}
for _, e in ipairs(Registry.squirrels) do if e.map == MAP then isRace[e.id] = true end end

local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- which squirrels are in the race, and hearing their clicks ----
local races = {}                                            -- player -> {phase, found, n, total, t0}
local ids, total = {}, 0
local hooked = setmetatable({}, {__mode = "k"})
local finish
local function stop(player, why)
	if not races[player] then return end
	races[player] = nil
	player:SetAttribute("Racing", nil)
	ev:FireClient(player, "stop", why)
end
local function onClick(player, id)
	local r = races[player]
	if not r or r.phase ~= "run" or r.found[id] then return end
	r.found[id] = true; r.n += 1
	ev:FireClient(player, "tick", id, r.n, r.total, os.clock() - r.t0)
	if r.n >= r.total then finish(player) end
end
local function scan()
	local list, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and isRace[id] and not list[id] then
			list[id] = true; n += 1
			for _, cd in ipairs(m:GetDescendants()) do
				if cd:IsA("ClickDetector") and not hooked[cd] then
					hooked[cd] = true
					cd.MouseClick:Connect(function(player) onClick(player, id) end)
				end
			end
		end
	end
	ids, total = list, n
	F:SetAttribute("Total", n)
end
task.spawn(function() while true do scan(); task.wait(total == 0 and 1 or 8) end end)

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "ForestRace_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("RaceBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}     -- gold, silver, bronze
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil                                   -- no empty stripes
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a squirrel finder"
			end
		end
	end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end         -- the board keeps a player's fastest
				return cs
			end)
		end)
		if not ok then warn("ForestRace: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a race ----
local function idList() local t = {} for id in pairs(ids) do t[#t + 1] = id end return t end
local function start(player)
	if races[player] or total == 0 or not player:GetAttribute("SaveLoaded") then return end
	local r = {phase = "count", found = {}, n = 0, total = total}
	races[player] = r
	player:SetAttribute("Racing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, r.total, idList(), item(player, "race_best"))
	task.delay(cd, function()
		if races[player] ~= r then return end
		r.phase = "run"; r.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 20) * 60, function() if races[player] == r then stop(player, "time") end end)
	end)
end
finish = function(player)
	local r = races[player]
	if not r then return end
	local secs = os.clock() - r.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	races[player] = nil
	player:SetAttribute("Racing", nil)
	local best = item(player, "race_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "race_best", cs) end
	-- a few acorns for beating your own best (Shannon: "a few acorns if you beat your best time ok"); not for a time too
	-- quick to be real (the same MinSeconds that keeps it off the board)
	local prize = 0
	if isBest and secs >= (F:GetAttribute("MinSeconds") or 45) then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player, "race") end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("ForestRace: %s ran the forest in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= (F:GetAttribute("MinSeconds") or 45) then
		if isBest then task.spawn(submit, player, cs) end
	else
		warn(string.format("ForestRace: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not races[player] then
		local char = player.Character
		local p = Vector3.new(F:GetAttribute("StartX"), F:GetAttribute("StartY"), F:GetAttribute("StartZ"))
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(1, 0, 0))) end
		task.wait(0.3)
		start(player)
	end
end)
Players.PlayerRemoving:Connect(function(p) races[p] = nil end)
if RunService:IsStudio() then                               -- Studio only: count n more squirrels as found, as if clicked
	local dbg = Instance.new("BindableFunction"); dbg.Name = "RaceDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player, n)
		local r = races[player]
		if not r or r.phase ~= "run" then return "not racing" end
		local k = 0
		for id in pairs(ids) do
			if k >= n then break end
			if not r.found[id] then k += 1; onClick(player, id) end
		end
		return tostring(r.n) .. "/" .. tostring(r.total)
	end
end
print("ForestRace: ready")
]====]})
table.insert(changes,{target=workspace.Baguette.ChaseServer,source=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local join = F:WaitForChild("ChaseJoin")
local ev = F:WaitForChild("ChaseEvent")
local stand = F:WaitForChild("Stand")
local prize = stand:WaitForChild("ChaseBaguette")
local award = RS:WaitForChild("AwardAcorns", 30)
local C = Color3.fromRGB
local UP = CFrame.Angles(0, 0, math.rad(90))
local LAND = {}
for entry in string.gmatch(F:GetAttribute("Landmarks") or "", "[^;]+") do
	local name, x, z = entry:match("^(.-)|(%-?%d+)|(%-?%d+)$")
	if name then table.insert(LAND, {name, tonumber(x), tonumber(z)}) end
end
local function A(k) return F:GetAttribute(k) end

local joined = {}                                       -- player -> true
local holder, immuneUntil, heldSince, earnedThisHold = nil, 0, 0, 0
local noTakeBack = {}                                   -- player -> clock until which they can't take it back
local grabs = {}                                        -- UserId -> {count, since}

local function parts(p)
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid"), c
end
local function count() local n = 0; for p in pairs(joined) do if p.Parent then n += 1 end end; return n end
local function give(p, n)
	if n <= 0 then return end
	if award then award:Fire(p, n) end
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + n)
end

-- the baguette on the holder's back, crumbs falling behind
local function removeHeld(p)
	local _, _, c = parts(p)
	local m = c and c:FindFirstChild("ChaseBaguette")
	if m then m:Destroy() end
end
local function attach(p)
	local hrp, _, c = parts(p)
	local torso = c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
	if not (hrp and torso) then return end
	removeHeld(p)
	local m = Instance.new("Model"); m.Name = "ChaseBaguette"
	local function piece(name, size, colour, shape, offset)
		local q = Instance.new("Part"); q.Name = name; q.Size = size; q.Color = colour; q.Material = Enum.Material.SmoothPlastic
		if shape then q.Shape = shape end
		q.CanCollide = false; q.CanQuery = false; q.CanTouch = false; q.Massless = true
		local cf = CFrame.new(0, 0.2, 0.62) * CFrame.Angles(0, 0, math.rad(55)) * offset     -- slung across the back
		q.CFrame = torso.CFrame * cf
		local w = Instance.new("Weld"); w.Part0 = torso; w.Part1 = q; w.C0 = cf; w.Parent = q
		q.Parent = m
		return q
	end
	local loaf = piece("Loaf", Vector3.new(3.1, 0.44, 0.44), C(226, 172, 96), Enum.PartType.Cylinder, CFrame.new())
	for i = -1, 1 do
		piece("Slash", Vector3.new(0.4, 0.06, 0.3), C(240, 206, 150), nil, CFrame.new(i * 0.8, 0, -0.19) * CFrame.Angles(0, math.rad(35), 0))
	end
	piece("Ribbon", Vector3.new(0.3, 0.48, 0.48), C(200, 60, 70), Enum.PartType.Cylinder, CFrame.new(0, 0, 0))
	local a = Instance.new("Attachment"); a.Parent = loaf
	local crumbs = Instance.new("ParticleEmitter"); crumbs.Name = "Crumbs"; crumbs.Color = ColorSequence.new(C(214, 164, 100))
	crumbs.Size = NumberSequence.new(0.14); crumbs.Rate = 7; crumbs.Lifetime = NumberRange.new(1.2, 1.8); crumbs.Speed = NumberRange.new(0.5, 1.5)
	crumbs.Acceleration = Vector3.new(0, -18, 0); crumbs.SpreadAngle = Vector2.new(60, 60); crumbs.Parent = a
	m.Parent = c
end

local function where(p)
	local hrp = parts(p)
	if not hrp or #LAND == 0 then return "" end
	local best, bd = LAND[1][1], math.huge
	for _, l in ipairs(LAND) do
		local d = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(l[2], l[3])).Magnitude
		if d < bd then best, bd = l[1], d end
	end
	return best
end

local function showAtBakery(on)
	F:SetAttribute("AtBakery", on)
	prize.Transparency = on and 0 or 1
	prize.ShineAt.Shine.Enabled = on
end
local function setHolder(p, reason, from)
	if holder then removeHeld(holder) end
	holder = p
	if p then
local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(p, "baguette") end
			attach(p)
		F:SetAttribute("Holder", p.UserId); F:SetAttribute("HolderName", p.DisplayName); F:SetAttribute("HolderWhere", where(p))
		immuneUntil = os.clock() + (A("Immune") or 5); heldSince = os.clock(); earnedThisHold = 0
		showAtBakery(false)
	else
		F:SetAttribute("Holder", 0); F:SetAttribute("HolderName", ""); F:SetAttribute("HolderWhere", "")
	end
	for q in pairs(joined) do
		if q.Parent then ev:FireClient(q, "holder", p and p.DisplayName or "", from and from.DisplayName or "", reason or "", p and p.UserId or 0, from and from.UserId or 0) end
	end
end
local function grabPrize(p)
	local now = os.clock()
	local g = grabs[p.UserId]
	if not g or now - g.since > 3600 then g = {count = 0, since = now}; grabs[p.UserId] = g end
	g.count += 1
	if g.count <= (A("GrabCap") or 12) then give(p, A("GrabPrize") or 10) return true end
	return false
end

local function setJoined(p, on)
	if on then joined[p] = true; p:SetAttribute("InChase", true)
	else
		joined[p] = nil; p:SetAttribute("InChase", nil)
		if holder == p then setHolder(nil, "left") end
	end
	F:SetAttribute("Playing", count())
end
join.OnServerEvent:Connect(function(p, on) setJoined(p, on == true) end)
PPS.PromptTriggered:Connect(function(prompt, p)
	if prompt.Name == "ChasePrompt" and prompt:IsDescendantOf(F) then setJoined(p, true); ev:FireClient(p, "joined") end
end)
Players.PlayerRemoving:Connect(function(p) setJoined(p, false); noTakeBack[p] = nil end)
local function watch(p) p.CharacterAdded:Connect(function() task.wait(0.5); if holder == p then attach(p) end end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- the holder's whereabouts for the hints, and the slow reward for keeping it
task.spawn(function()
	local lastPay = os.clock()
	while true do
		task.wait(1)
		if holder then F:SetAttribute("HolderWhere", where(holder)) end
		if holder and os.clock() - lastPay >= (A("HoldEvery") or 10) then
			lastPay = os.clock()
			local cap = A("HoldCap") or 30
			if count() >= (A("MinPlayers") or 2) and earnedThisHold < cap then
				local n = math.min(A("HoldPrize") or 1, cap - earnedThisHold)
				earnedThisHold += n
				give(holder, n)
			end
		end
	end
end)

-- the chase itself
while true do
	task.wait(0.1)
	local n = count()
	if n < (A("MinPlayers") or 2) then
		if holder then setHolder(nil, "waiting") end
		if F:GetAttribute("AtBakery") then showAtBakery(false) end
	elseif not holder then
		if not F:GetAttribute("AtBakery") then
			showAtBakery(true)
			for q in pairs(joined) do if q.Parent then ev:FireClient(q, "bakery") end end
		end
		for q in pairs(joined) do                       -- first to the basket takes it
			local r, h = parts(q)
			if r and h and h.Health > 0 and (r.Position - prize.Position).Magnitude < 6 then
				setHolder(q, "bakery")
				local paid = grabPrize(q)
				ev:FireClient(q, "grabbed", paid)
				break
			end
		end
	elseif os.clock() > immuneUntil then
		local hr, hh = parts(holder)
		if hr and hh and hh.Health > 0 then
			for q in pairs(joined) do
				if q ~= holder and q.Parent and os.clock() > (noTakeBack[q] or 0) then
					local r, h = parts(q)
					if r and h and h.Health > 0 and (r.Position - hr.Position).Magnitude < (A("Range") or 4) then
						local lost = holder
						noTakeBack[lost] = os.clock() + (A("NoTakeBack") or 30)
						setHolder(q, "stolen", lost)
						local paid = grabPrize(q)
						ev:FireClient(q, "grabbed", paid)
						break
					end
				end
			end
		end
	end
end
]====]})
table.insert(changes,{target=workspace.HudBarUI.HudBarClient,source=[====[local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local C = Color3.fromRGB
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local NEED = (workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need")) or 10
local UIS = game:GetService("UserInputService")
local isMobile = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or script.Parent:GetAttribute("ForceMobile") == true
local PANEL_Y = isMobile and 114 or 64          -- phones keep room for the Hint button under the icons
local PANEL, CREAM, GOLD, DIM = C(38, 30, 52), C(255, 246, 220), C(255, 214, 90), C(120, 110, 140)

-- ---------------------------------------------------------------- the areas ----
-- world rectangles (the same ones the boundary walls use), the order you travel them, and what unlocks each
local AREAS = {
	{id = "forest",  x0 = -130, x1 = 142, z0 = -215, z1 = 25,  needs = nil},
	{id = "village", x0 = 150,  x1 = 352, z0 = -205, z1 = 5,   needs = "forest"},
	{id = "domaine", x0 = 352,  x1 = 700, z0 = -250, z1 = 30,  needs = "village"},
}
local NAME, TOTAL = {}, {}
for _, m in ipairs(Registry.maps) do NAME[m.id] = m.name end
for _, e in ipairs(Registry.squirrels) do TOTAL[e.map] = (TOTAL[e.map] or 0) + 1 end
local function unlocked(a) return (not a.needs) or (player:GetAttribute("Found_" .. a.needs) or 0) >= NEED end
local function areaAt(pos)
	for _, a in ipairs(AREAS) do
		if pos.X >= a.x0 and pos.X <= a.x1 and pos.Z >= a.z0 and pos.Z <= a.z1 then return a end
	end
end

-- ---------------------------------------------------------------- the bar ----
pcall(function() pg.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor end)         -- phones stay in landscape, either way up
for _, g in ipairs(pg:GetChildren()) do if g.Name == "HudBar" then g:Destroy() end end        -- never two bars
local gui = Instance.new("ScreenGui"); gui.Name = "HudBar"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 6; gui.Parent = pg
local bar = Instance.new("Frame"); bar.Name = "Bar"; bar.AnchorPoint = Vector2.new(1, 0); bar.Position = UDim2.new(1, -10, 0, 8)
bar.Size = UDim2.fromOffset(216, 48); bar.BackgroundTransparency = 1; bar.Parent = gui
local layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = bar

local function iconButton(order, tip)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(48, 48); b.BackgroundColor3 = PANEL; b.BackgroundTransparency = 0.1
	b.BorderSizePixel = 0; b.Text = ""; b.AutoButtonColor = false; b.LayoutOrder = order; b.Parent = bar
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = b
	local s = Instance.new("UIStroke"); s.Color = GOLD; s.Thickness = 2; s.Transparency = 0.35; s.Parent = b
	local label = Instance.new("TextLabel"); label.Name = "Tip"; label.AnchorPoint = Vector2.new(0.5, 1); label.Position = UDim2.new(0.5, 0, 0, -4)
	label.Size = UDim2.fromOffset(96, 20); label.BackgroundColor3 = PANEL; label.BackgroundTransparency = 0.15; label.TextColor3 = CREAM
	label.Font = Enum.Font.FredokaOne; label.TextSize = 13; label.Text = tip; label.Visible = false; label.Parent = b
	local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 8); lc.Parent = label
	b.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.12), {Transparency = 0}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.35}):Play() end)
	return b, s
end
local function acorn(parent, size, cx, cy)                      -- a little acorn drawn from frames
	local nut = Instance.new("Frame"); nut.Size = UDim2.fromOffset(size * 0.62, size * 0.62); nut.Position = UDim2.fromOffset(cx - size * 0.31, cy - size * 0.18)
	nut.BackgroundColor3 = C(206, 146, 82); nut.BorderSizePixel = 0; nut.Parent = parent
	local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0.45, 0); nc.Parent = nut
	local cap = Instance.new("Frame"); cap.Size = UDim2.fromOffset(size * 0.78, size * 0.34); cap.Position = UDim2.fromOffset(cx - size * 0.39, cy - size * 0.40)
	cap.BackgroundColor3 = C(110, 70, 40); cap.BorderSizePixel = 0; cap.Parent = parent
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0.4, 0); cc.Parent = cap
	local stem = Instance.new("Frame"); stem.Size = UDim2.fromOffset(size * 0.12, size * 0.2); stem.Position = UDim2.fromOffset(cx - size * 0.06, cy - size * 0.56)
	stem.BackgroundColor3 = C(86, 56, 34); stem.BorderSizePixel = 0; stem.Parent = parent
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0.4, 0); sc.Parent = stem
end

-- A squirrel in profile, using the GAME'S OWN mesh rather than an approximation assembled from rounded frames.
-- The frames version came out looking like a fluffy caterpillar: at thirty pixels a tail drawn as a row of
-- circles merges with the body and the head disappears. This is the actual squirrel, lit from nowhere and
-- flattened to one colour, so it reads as a true silhouette of the thing the inventory holds.
-- The squirrels face local -Z, so a camera out along local X sees one side-on.
local function squirrelIcon(parent, size, cx, cy)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "SquirrelIcon"
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromOffset(cx, cy)
	-- square and no larger than asked: the button is 48 across and the found-count owns the bottom of it,
	-- so an icon that overruns its size sits on top of the numbers
	vp.Size = UDim2.fromOffset(size, size)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.new(1, 1, 1)                             -- no shading at all: a flat cut-out shape
	vp.LightColor = Color3.new(0, 0, 0)
	vp.Parent = parent

	task.spawn(function()
		local src
		for attempt = 1, 60 do
			for _, o in ipairs(workspace:GetDescendants()) do
				if o:IsA("Model") and o.Name:sub(-6) == "_color" then
					for _, q in ipairs(o:GetDescendants()) do
						-- skip the wide ones; those are the squirrels posed lying down
						if q:IsA("MeshPart") and q.Size.X < 2.4 then src = q break end
					end
				end
				if src then break end
			end
			if src then break end
			task.wait(0.5)                                       -- the squirrels may not have loaded in yet
		end
		if not src or not vp.Parent then return end
		local m = src:Clone()
		for _, c in ipairs(m:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
		m.TextureID = ""                                         -- no fur texture; the shape is the whole point
		m.Color = CREAM
		m.Material = Enum.Material.SmoothPlastic
		m.Transparency = 0
		m.CFrame = CFrame.new()
		m.Parent = vp
		local cam = Instance.new("Camera")
		cam.FieldOfView = 26
		cam.Parent = vp
		vp.CurrentCamera = cam
		-- close enough that the squirrel fills its corner of the bar; at thirty pixels every one counts
		cam.CFrame = CFrame.lookAt(Vector3.new(m.Size.Magnitude * 1.72, 0, 0), Vector3.new())
	end)
end

local squirrelBtn = iconButton(1, "Squirrels")
squirrelIcon(squirrelBtn, 32, 24, 17)                            -- a squirrel for the squirrels; the acorn
                                                                 -- belongs to the purse beside it
local countTag = Instance.new("TextLabel"); countTag.AnchorPoint = Vector2.new(0.5, 1); countTag.Position = UDim2.new(0.5, 0, 1, -2); countTag.Size = UDim2.fromOffset(44, 14)
countTag.BackgroundTransparency = 1; countTag.Font = Enum.Font.FredokaOne; countTag.TextSize = 13; countTag.TextColor3 = GOLD; countTag.Text = "0"; countTag.Parent = squirrelBtn
local mapBtn = iconButton(2, "Map")
do                                                               -- a folded map: three panels, a route and a pin
	for i, tint in ipairs({C(228, 216, 186), C(214, 200, 166), C(228, 216, 186)}) do
		local p = Instance.new("Frame"); p.Size = UDim2.fromOffset(9, i == 2 and 26 or 22); p.Position = UDim2.fromOffset(10 + (i - 1) * 10, i == 2 and 10 or 13)
		p.BackgroundColor3 = tint; p.BorderSizePixel = 0; p.Parent = mapBtn
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 2); c.Parent = p
	end
	local pin = Instance.new("Frame"); pin.Size = UDim2.fromOffset(8, 8); pin.Position = UDim2.fromOffset(26, 16); pin.BackgroundColor3 = C(214, 60, 60); pin.BorderSizePixel = 0; pin.Parent = mapBtn
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pin
end

-- ---- the acorn purse: a square LEFT of the two icons, showing what you have collected ----
-- Now a button: it opens the store. LayoutOrder 0 puts it leftmost - the row is right-aligned and lays its
-- children out in order.
local purse = Instance.new("TextButton")
purse.Name = "Purse"; purse.Size = UDim2.fromOffset(48, 48); purse.BackgroundColor3 = PANEL
purse.BackgroundTransparency = 0.1; purse.BorderSizePixel = 0; purse.LayoutOrder = 0
purse.Text = ""; purse.AutoButtonColor = false; purse.Parent = bar
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = purse
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Transparency = 0.35; st.Parent = purse
end
acorn(purse, 21, 24, 14)                                         -- the same acorn as the collectible on the ground
local purseCount = Instance.new("TextLabel")
purseCount.Name = "Count"; purseCount.AnchorPoint = Vector2.new(0.5, 1); purseCount.Position = UDim2.new(0.5, 0, 1, -3)
purseCount.Size = UDim2.fromOffset(44, 17); purseCount.BackgroundTransparency = 1
purseCount.Font = Enum.Font.FredokaOne; purseCount.TextSize = 15; purseCount.TextColor3 = GOLD
purseCount.Text = "0"; purseCount.Parent = purse

-- ---------------------------------------------------------------- the squirrel panel (the existing HUD) ----
local hudGui, hudPanel
local function viewport()
	local c = workspace.CurrentCamera
	return c and c.ViewportSize or Vector2.new(1280, 720)
end
-- the squirrel panel and the squirrel card are built at a fixed pixel size; on a phone they run off the screen, so
-- each gets a UIScale that shrinks it to whatever room is left
local function fitPanel()
	if not hudPanel then return end
	local sc = hudPanel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", hudPanel)
	local vp = viewport()
	local w, h = hudPanel.Size.X.Offset, hudPanel.Size.Y.Offset
	if w <= 0 or h <= 0 then return end
	sc.Scale = math.clamp(math.min((vp.Y - PANEL_Y - 16) / h, (vp.X * 0.52) / w), 0.45, 1)
end
-- the squirrel card is built tall and narrow, which does not suit a phone held sideways. On a phone it is laid out
-- again in landscape: the portrait on the left, the name and story on the right. The card's own pop animation drives
-- its UIScale, so any size clamp has to be applied after that tween has finished.
local CARD_W, CARD_H = 646, 306
local function relayoutCard(prim)
	local big, ring, hint, title, bio
	for _, d in ipairs(prim:GetDescendants()) do
		if d:IsA("Frame") and d.Size.X.Offset == 326 then big = d
		elseif d:IsA("Frame") and d.Size.X.Offset == 288 then ring = d
		elseif d:IsA("TextLabel") then
			local y = d.Position.Y.Offset
			if y == 350 then hint = d elseif y == 368 then title = d elseif y == 414 then bio = d end
		end
	end
	prim.Size = UDim2.fromOffset(CARD_W, CARD_H)
	if big then
		big.AnchorPoint = Vector2.new(0, 0.5); big.Position = UDim2.new(0, 16, 0.5, 0); big.Size = UDim2.fromOffset(252, 252)
	end
	if ring then ring.Size = UDim2.fromOffset(228, 228); ring.Position = UDim2.new(0.5, 0, 0.5, 0) end
	if hint then hint.Position = UDim2.new(0, 16, 1, -24); hint.Size = UDim2.fromOffset(252, 16) end
	if title then title.Position = UDim2.new(0, 288, 0, 30); title.Size = UDim2.new(1, -312, 0, 42) end
	if bio then bio.Position = UDim2.new(0, 290, 0, 84); bio.Size = UDim2.new(1, -314, 1, -118) end
end
local function fitCard(card)
	for _, d in ipairs(card:GetChildren()) do
		if d:IsA("Frame") and d.AnchorPoint.X == 0.5 and d.Size.X.Offset > 200 then
			if isMobile then relayoutCard(d) end
			task.delay(0.45, function()                        -- after the card's pop-in tween has settled
				if not d.Parent then return end
				local sc = d:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", d)
				local vp = viewport()
				sc.Scale = math.clamp(math.min((vp.Y - 20) / d.Size.Y.Offset, (vp.X - 20) / d.Size.X.Offset), 0.4, 1)
			end)
		end
	end
end
-- takes charge of a squirrel HUD: its panel goes below the bar (and the Hint button on phones), closed, fitted to the screen
local function hookHud(g)
	hudGui = g
	local p = g:WaitForChild("Panel", 30)
	if not p or hudGui ~= g then return end
	hudPanel = p
	p.Position = UDim2.new(1, -10, 0, PANEL_Y)
	p.Visible = false
	p.AnchorPoint = Vector2.new(1, 0)
	fitPanel()
	p:GetPropertyChangedSignal("Size"):Connect(fitPanel)
	for _, c in ipairs(g:GetChildren()) do if c.Name == "Card" then fitCard(c) end end
	g.ChildAdded:Connect(function(c)                            -- the card is rebuilt every time one is opened
		if c.Name == "Card" then task.defer(fitCard, c) end
	end)
end
task.spawn(function()
	local g = pg:WaitForChild("SquirrelHUD", 60)
	if g then hookHud(g) end
end)
-- A RESET REBUILDS THE SQUIRREL HUD (Shannon, Sep 26, on her phone: "I reset my count for squirrels and the squirrel
-- inventory is open and it will not close ... the menu is also overlapping with the 3 pills at the upper right"): the
-- squirrels' own script destroys the HUD and makes a new one, open, in its old corner under these icons - and the icon was
-- still opening and closing the old one. Every new one is taken over the same way, so the icon keeps working.
pg.ChildAdded:Connect(function(c)
	if c.Name == "SquirrelHUD" and c ~= hudGui then task.defer(hookHud, c) end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel) end
local function squirrelOpen() return hudPanel and hudPanel.Visible end

-- ---------------------------------------------------------------- the map panel ----
-- a drawn parchment chart (marketing/make_map.py, uploaded as an image); the names, tallies, the "?" covers over
-- areas you have not reached and the "you are here" dot are drawn on top of it
local MAP_ID = 127000767898563
local IMG_W, IMG_H, IMG_M = 1024, 560, 26                     -- the image, and the margin its world area starts at
local DISP_W = 560                                            -- how wide the chart is drawn in the panel
local DISP_H = DISP_W * IMG_H / IMG_W
local F = DISP_W / IMG_W
local WX0, WX1, WZ0, WZ1 = -130, 700, -250, 30
local IS = math.min((IMG_W - 2 * IMG_M) / (WX1 - WX0), (IMG_H - 2 * IMG_M) / (WZ1 - WZ0))
local IOX = (IMG_W - (WX1 - WX0) * IS) / 2
local IOZ = (IMG_H - (WZ1 - WZ0) * IS) / 2
local function toMap(x, z)                                    -- world -> panel pixels
	return (IOX + (x - WX0) * IS) * F, (IOZ + (z - WZ0) * IS) * F
end

local map = Instance.new("Frame"); map.Name = "MapPanel"; map.AnchorPoint = Vector2.new(1, 0); map.Position = UDim2.new(1, -10, 0, PANEL_Y)
map.Size = UDim2.fromOffset(DISP_W + 16, DISP_H + 48); map.BackgroundColor3 = PANEL; map.BackgroundTransparency = 0.08
map.BorderSizePixel = 0; map.Visible = false; map.Parent = gui
local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = map
local ms = Instance.new("UIStroke"); ms.Color = GOLD; ms.Thickness = 2; ms.Parent = map
local here = Instance.new("TextLabel"); here.Size = UDim2.new(1, -20, 0, 26); here.Position = UDim2.new(0, 10, 0, 6); here.BackgroundTransparency = 1
here.Font = Enum.Font.FredokaOne; here.TextSize = 17; here.TextColor3 = CREAM; here.TextXAlignment = Enum.TextXAlignment.Left
here.Text = "You are here"; here.Parent = map
local chart = Instance.new("ImageLabel"); chart.Name = "Chart"; chart.Position = UDim2.new(0, 8, 0, 36)
chart.Size = UDim2.fromOffset(DISP_W, DISP_H); chart.BackgroundTransparency = 1; chart.Image = "rbxassetid://" .. MAP_ID
chart.ScaleType = Enum.ScaleType.Stretch; chart.Parent = map
local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0, 8); cc2.Parent = chart

local cards = {}
for _, a in ipairs(AREAS) do
	local x0, z0 = toMap(a.x0, a.z0)
	local x1, z1 = toMap(a.x1, a.z1)
	local holder = Instance.new("Frame"); holder.Name = a.id; holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(x0, z0); holder.Size = UDim2.fromOffset(x1 - x0, z1 - z0); holder.Parent = chart
	-- the cover that hides an area you have not reached
	local cover = Instance.new("Frame"); cover.Name = "Cover"; cover.Size = UDim2.fromScale(1, 1); cover.BackgroundColor3 = C(226, 208, 166)
	cover.BorderSizePixel = 0; cover.Parent = holder
	local cs = Instance.new("UIStroke"); cs.Color = C(150, 118, 74); cs.Thickness = 2; cs.Parent = cover
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Font = Enum.Font.Antique
	q.TextSize = 44; q.TextColor3 = C(126, 96, 58); q.Text = "?"; q.Parent = cover
	-- the name plate for an area you have reached
	local plate = Instance.new("Frame"); plate.Name = "Plate"; plate.AnchorPoint = Vector2.new(0.5, 0); plate.Position = UDim2.new(0.5, 0, 0, 4)
	plate.Size = UDim2.fromOffset(math.min(x1 - x0 - 8, 190), 34); plate.BackgroundColor3 = C(248, 240, 214); plate.BackgroundTransparency = 0.12
	plate.BorderSizePixel = 0; plate.Parent = holder
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 6); pc.Parent = plate
	local pstroke = Instance.new("UIStroke"); pstroke.Color = C(150, 118, 74); pstroke.Thickness = 1; pstroke.Parent = plate
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Size = UDim2.new(1, -6, 0, 17); title.Position = UDim2.new(0, 3, 0, 2)
	title.BackgroundTransparency = 1; title.Font = Enum.Font.Antique; title.TextSize = 15; title.TextColor3 = C(88, 58, 32)
	title.TextScaled = false; title.Parent = plate
	local tally = Instance.new("TextLabel"); tally.Name = "Tally"; tally.Size = UDim2.new(1, -6, 0, 13); tally.Position = UDim2.new(0, 3, 0, 18)
	tally.BackgroundTransparency = 1; tally.Font = Enum.Font.FredokaOne; tally.TextSize = 12; tally.TextColor3 = C(120, 84, 44); tally.Parent = plate
	cards[a.id] = {cover = cover, plate = plate, title = title, tally = tally}
end

local dot = Instance.new("Frame"); dot.Name = "You"; dot.Size = UDim2.fromOffset(13, 13); dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.BackgroundColor3 = C(210, 50, 50); dot.BorderSizePixel = 0; dot.ZIndex = 6; dot.Parent = chart
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
local ds = Instance.new("UIStroke"); ds.Color = C(252, 246, 230); ds.Thickness = 2; ds.Parent = dot
local ring = Instance.new("Frame"); ring.Size = UDim2.fromOffset(26, 26); ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.5, 0.5)
ring.BackgroundTransparency = 1; ring.ZIndex = 5; ring.Parent = dot
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1, 0); rc.Parent = ring
local rs = Instance.new("UIStroke"); rs.Color = C(210, 70, 70); rs.Thickness = 2; rs.Transparency = 0.4; rs.Parent = ring

local function refreshMap()
	for _, a in ipairs(AREAS) do
		local card = cards[a.id]
		local open = unlocked(a)
		card.cover.Visible = not open
		card.plate.Visible = open
		if open then
			card.title.Text = NAME[a.id] or a.id
			local found = player:GetAttribute("Found_" .. a.id) or 0
			card.tally.Text = string.format("%d / %d found", found, TOTAL[a.id] or 0)
		end
	end
end
local function refreshCount()
	local n = player:GetAttribute("SquirrelsFound") or 0
	local all = #Registry.squirrels
	countTag.Text = string.format("%d/%d", n, all)
end

-- ---------------------------------------------------------------- opening and closing ----
local function setSquirrels(open)
	if open then pg:SetAttribute("OpenPanel","collection") end
	if hudPanel then hudPanel.Visible = open end
	if open then map.Visible = false end
end
local function setMap(open)
	if open then pg:SetAttribute("OpenPanel","map") end
	map.Visible = open
	if open then refreshMap(); if hudPanel then hudPanel.Visible = false end end
end
squirrelBtn.Activated:Connect(function() setSquirrels(not squirrelOpen()) end)
mapBtn.Activated:Connect(function() setMap(not map.Visible) end)
for _, a in ipairs(AREAS) do
	if a.needs then player:GetAttributeChangedSignal("Found_" .. a.needs):Connect(refreshMap) end
	player:GetAttributeChangedSignal("Found_" .. a.id):Connect(refreshMap)
end
player:GetAttributeChangedSignal("SquirrelsFound"):Connect(refreshCount)

-- the purse follows the Acorns attribute, which the server sets; a small pop so a pickup is felt as well as seen
local purseScale = Instance.new("UIScale"); purseScale.Parent = purse
local function refreshPurse()
	purseCount.Text = tostring(player:GetAttribute("Acorns") or 0)
end
player:GetAttributeChangedSignal("Acorns"):Connect(function()
	refreshPurse()
	purseScale.Scale = 1.22
	TweenService:Create(purseScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1}):Play()
	-- a backstop: an interrupted tween once left a UIScale stuck large over the panel, and a counter frozen
	-- mid-bounce looks broken in a way that is hard to explain
	task.delay(0.6, function() if purseScale then purseScale.Scale = 1 end end)
end)
refreshPurse()
refreshCount(); refreshMap()

-- on a narrow screen (phones) the map shrinks to fit rather than covering everything
local mapScale = Instance.new("UIScale"); mapScale.Parent = map
local function fitMap()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	mapScale.Scale = math.clamp(math.min((vp.X - 30) / (DISP_W + 16), (vp.Y - PANEL_Y - 16) / (DISP_H + 48)), 0.5, 1)
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMap) end
fitMap()

-- the "you are here" dot follows the player while the map is open
RunService.RenderStepped:Connect(function()
	if not map.Visible then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then dot.Visible = false; return end
	local p = root.Position
	local cx, cz = toMap(math.clamp(p.X, WX0, WX1), math.clamp(p.Z, WZ0, WZ1))
	dot.Visible = true
	dot.Position = UDim2.fromOffset(cx, cz)
	local a = areaAt(p)
	here.Text = a and ("You are here: " .. (NAME[a.id] or a.id)) or "You are here"
	rs.Transparency = 0.25 + 0.35 * math.abs(math.sin(os.clock() * 2))
end)

-- Passport entry uses the same top-right control row, without an extra floating widget.
local passportBtn = iconButton(-1,"Passport"); passportBtn.Name="Passport"
local art = require(game:GetService("ReplicatedStorage"):WaitForChild("SquirrelIllustrations"))
local illustration
local function passportCover()
 if illustration then illustration:Destroy() end
 illustration=art.draw(passportBtn,(player:GetAttribute("Item_passport_outings") or 0)>=5 and "goldpassport" or "passport",42);illustration.Position=UDim2.fromOffset(3,3)
end
passportCover();player:GetAttributeChangedSignal("Item_passport_outings"):Connect(passportCover)
passportBtn.Activated:Connect(function() game:GetService("ReplicatedStorage").PassportToggle:Fire() end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
 local active=pg:GetAttribute("OpenPanel")
 if active and active~="map" then map.Visible=false end
 if active and active~="collection" and hudPanel then hudPanel.Visible=false end
end)
]====]})
table.insert(changes,{target=workspace.Shop.ShopClient,source=[====[local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local buy = RS:WaitForChild("ShopBuy")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ROBUX = utf8.char(0xE002)                 -- the official Robux symbol, in Roblox's own fonts

local RGB = Color3.fromRGB
local FACE, FACE_DEEP, RIM = RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)
local SLOT, SLOT_EDGE = RGB(228, 212, 179), RGB(162, 131, 90)
local EDGE, INK, INK_DIM = RGB(203, 150, 48), RGB(64, 42, 22), RGB(132, 108, 80)
local GOLD, BTN_INK = RGB(255, 202, 62), RGB(84, 48, 18)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o; return c end
local function stroke(o, col, th, tr)
	local st = Instance.new("UIStroke"); st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Color = col; st.Thickness = th; st.Transparency = tr or 0
	st.Parent = o; return st
end

-- what each thing is, in the player's words. The server owns ids and prices; this owns the label and the joke.
local ITEMS = {
	-- the mime is tipped at his hat, in the street, not from a menu
	{id = "seed",       name = "Seed packet",     blurb = "Plant it in the garden. Nobody knows what comes up."},
	{id = "ziphandle",  name = "Zipline handle",  blurb = "Yours to keep. Grab on at the top of the forest tower and fly out over the farm.", once = true},
	{id = "bubbles",    name = "Fountain colour", blurb = "Tip it in and the fountain runs your colour, bubbles and all, for ten minutes - for everyone here.", palette = 6},
	{id = "binoculars", name = "Spotter's binoculars", blurb = "Hiding squirrels glow red - even through the trees. Robux only.", once = true, robux = true},
	{id = "zoomies",    name = "Zoomies",         blurb = "Ten minutes of running faster, everywhere. Buy again for ten more. Not on the race clock."},
	{id = "portrait",   name = "Sit for a portrait", blurb = "The painter paints you and sets you on an easel in his gallery by the river - the twelve newest sitters stay."},
	{id = "slingshot",  name = "Slingshot",       blurb = "There is a hoop in the forest. An acorn a shot; sink one and win three.", once = true},
	{id = "backpack",   name = "Backpack",        blurb = "Carry your things, and your favourite squirrel, on your back.", once = true},	{id = "glider",     name = "Hang glider",     blurb = "Yours to keep. Take off from the top of the Sandstone Climb and glide into the Rue.", once = true},
}

local gui = Instance.new("ScreenGui")
gui.Name = "ShopPanel"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 7
gui.Enabled = false; gui.Parent = pg

local shade = Instance.new("TextButton")                 -- tap anywhere outside to close
shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = RGB(20, 12, 6)
shade.BackgroundTransparency = 0.45; shade.Text = ""; shade.AutoButtonColor = false
shade.BorderSizePixel = 0; shade.ZIndex = 1; shade.Parent = gui

local W, H = 440, 470
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(W, H); panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0
panel.ZIndex = 2; panel.Parent = gui
corner(panel, UDim.new(0, 22))
stroke(panel, RIM, 4, 0)
local scale = Instance.new("UIScale"); scale.Parent = panel

-- a phone held sideways has little room; shrink the whole page rather than letting it run off the edge
local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local height=math.min(H,vp.Y-140)
 panel.Size=UDim2.fromOffset(math.min(W,vp.X-28),height)
 scale.Scale=1
 local entries=panel:FindFirstChildOfClass("ScrollingFrame")
 if entries then entries.Size=UDim2.new(1,-32,1,-78) end
end
-- The camera may not exist yet when this runs, and asking an absent camera for its size quietly gives the
-- default 1280x720 - which is bigger than a phone, so the panel would never shrink. Wait for it.
task.spawn(function()
	for _ = 1, 40 do
		if workspace.CurrentCamera then break end
		task.wait(0.25)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
end)
fit()

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(24, 18); title.Size = UDim2.fromOffset(W - 140, 34)
title.BackgroundTransparency = 1; title.Text = "Acorn Store"; title.TextXAlignment = Enum.TextXAlignment.Left
title.FontFace = FONT; title.TextSize = 28; title.TextColor3 = RGB(58, 36, 16); title.ZIndex = 3
title.Parent = panel

-- the purse, so the decision and the balance are on the same page
local purse = Instance.new("TextLabel")
purse.AnchorPoint = Vector2.new(1, 0); purse.Position = UDim2.new(1, -58, 0, 20)
purse.Size = UDim2.fromOffset(110, 30); purse.BackgroundColor3 = SLOT; purse.BorderSizePixel = 0
purse.FontFace = FONT; purse.TextSize = 19; purse.TextColor3 = INK; purse.Text = "0"; purse.ZIndex = 3
purse.Parent = panel
corner(purse, UDim.new(0, 10)); stroke(purse, SLOT_EDGE, 2, 0.3)

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -18, 0, 18)
close.Size = UDim2.fromOffset(40, 40); close.BackgroundColor3 = SLOT; close.BorderSizePixel = 0
close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = INK; close.Text = "X"
close.AutoButtonColor = false; close.ZIndex = 3; close.Parent = panel
corner(close, UDim.new(0, 10)); stroke(close, SLOT_EDGE, 2, 0.3)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(16, 62); list.Size = UDim2.fromOffset(W - 32, H - 78)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new(); list.ZIndex = 3
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 10)
lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list

local rows = {}
local Illustrations=require(RS:WaitForChild("SquirrelIllustrations"))
-- THE FOUNTAIN IS EVERYONE'S (Shannon, Sep 26: "when somebody turns the fountain color with bubbles, I want everybody to
-- be able to see it ... It can only be chosen if it's not currently colored"): one colour at a time for the whole
-- server; while it runs, the row says whose colour it is and when it's free again, and no swatch can be bought
local COLOUR_NAMES = {"pink", "orange", "gold", "green", "blue", "violet"}
local function fountainNow()
	local FC = workspace:FindFirstChild("FountainColour")
	local idx = FC and FC:GetAttribute("ActiveColour") or 0
	local untilT = FC and FC:GetAttribute("ActiveUntil") or 0
	local left = untilT - workspace:GetServerTimeNow()
	if idx > 0 and left > 0 then return idx, math.ceil(left), (FC:GetAttribute("ActiveBy") or "someone") end
	return 0, 0, nil
end
local function mmss(s) return string.format("%d:%02d", math.floor(s / 60), s % 60) end
local function priceOf(item)
	return F:GetAttribute("Price_" .. item.id)
end

-- One record per row, held beside the frame rather than on it: Roblox will not let you invent fields on an
-- Instance, so row.note would simply throw.
local function say(rec, text, good)
	rec.note.Text = text
	rec.note.TextColor3 = good and RGB(64, 112, 48) or RGB(150, 52, 30)
	rec.note.TextTransparency = 0
	TweenService:Create(rec.note, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.1),
		{TextTransparency = 1}):Play()
end

-- on sale if the whole store is, or if this one thing has been switched on by itself
local function onSale(item)
	return F:GetAttribute("Selling") == true or F:GetAttribute("Sell_" .. item.id) == true
end

local busy = false
local function attempt(item, rec, amount)
	if busy then return end
	busy = true
	if rec.btn then rec.btn.Text = "..." end
	local ok, res, why = pcall(function() return buy:InvokeServer(item.id, amount) end)
	busy = false
	if rec.btn then rec.btn.Text = rec.label end
	if not ok then say(rec, "the shop did not answer", false) return end
	if res then
		say(rec, item.id == "tip" and "he tips his hat" or "bought", true)
	else
		say(rec, tostring(why or "no"), false)
	end
end

for i, item in ipairs(ITEMS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 150); row.BackgroundColor3 = FACE_DEEP; row.BorderSizePixel = 0
	row.LayoutOrder = i; row.ZIndex = 3; row.Parent = list
	corner(row, UDim.new(0, 14)); stroke(row, SLOT_EDGE, 2, 0.45)

	local name = Instance.new("TextLabel")
	local illustration=Illustrations.draw(row,item.id,68);illustration.Position=UDim2.fromOffset(8,10)
	name.Position = UDim2.fromOffset(86, 9); name.Size = UDim2.new(1, -100, 0, 24)
	name.BackgroundTransparency = 1; name.Text = item.name; name.TextXAlignment = Enum.TextXAlignment.Left
	name.FontFace = FONT; name.TextSize = 19; name.TextColor3 = RGB(58, 36, 16); name.ZIndex = 4
	name.Parent = row

	local blurb = Instance.new("TextLabel")
	-- 228 wide, stopping at x242: the three tip buttons reach back to x253, so nothing can run under them
	blurb.Position = UDim2.fromOffset(86, 39); blurb.Size = UDim2.new(1, -100, 0, 44)   -- room for the swatches
	blurb.BackgroundTransparency = 1; blurb.Text = item.blurb; blurb.TextWrapped = true
	blurb.TextXAlignment = Enum.TextXAlignment.Left; blurb.TextYAlignment = Enum.TextYAlignment.Top
	blurb.FontFace = FONT; blurb.TextSize = 13; blurb.TextColor3 = INK_DIM; blurb.ZIndex = 4
	blurb.Parent = row

	local note = Instance.new("TextLabel")
	note.AnchorPoint = Vector2.zero; note.Position = UDim2.fromOffset(12, 88)
	note.Size = UDim2.new(1,-24,0,16);note.TextTruncate=Enum.TextTruncate.AtEnd; note.BackgroundTransparency = 1; note.Text = ""
	note.TextXAlignment = Enum.TextXAlignment.Left; note.FontFace = FONT; note.TextSize = 13
	note.TextTransparency = 1; note.ZIndex = 4; note.Parent = row

	local rec = {frame = row, note = note, label = "", blurb = blurb}
	rows[item.id] = rec

	if item.palette then
		-- SIX SWATCHES instead of a button, each the buy button for its colour; the colours come from the same
		-- attributes the fountain itself reads, so the shop and the fountain can never disagree
		local FC = workspace:FindFirstChild("FountainColour")
		rec.swatches = {}
		local n = item.palette
		for i = 1, n do
			local sw = Instance.new("TextButton"); sw.Name = "Swatch" .. i; sw.Text = ""
			sw.AnchorPoint = Vector2.new(1, 0); sw.Position = UDim2.new(1, -12 - (n - i) * 38, 0, 108)
			sw.Size = UDim2.fromOffset(32, 32); sw.BorderSizePixel = 0; sw.AutoButtonColor = false; sw.ZIndex = 4
			sw.BackgroundColor3 = (FC and FC:GetAttribute("Colour" .. i)) or RGB(200, 200, 200)
			sw.Parent = row
			corner(sw, UDim.new(1, 0)); stroke(sw, RGB(84, 48, 18), 2, 0.25)
			sw.MouseButton1Click:Connect(function()
				if not onSale(item) then say(rec, "not in the shop yet", false) return end
				local runIdx, left = fountainNow()
				if runIdx > 0 then say(rec, "the fountain is taken - free in " .. mmss(left), false) return end
				attempt(item, rec, i)
			end)
			rec.swatches[i] = sw
		end
		local pl = Instance.new("TextLabel"); pl.Name = "PriceLabel"; pl.AnchorPoint = Vector2.new(1, 0); pl.Position = UDim2.new(0, 10 + n * 0, 0, 110); pl.AnchorPoint = Vector2.zero
		pl.Size = UDim2.fromOffset(140, 26); pl.BackgroundTransparency = 1; pl.FontFace = FONT; pl.TextSize = 14
		pl.TextColor3 = INK_DIM; pl.TextXAlignment = Enum.TextXAlignment.Left; pl.Text = ""; pl.ZIndex = 4; pl.Parent = row
		rec.priceLabel = pl
	else
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0); btn.Position = UDim2.new(1, -12, 0, 106)
	btn.Size = UDim2.fromOffset(142, 36); btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0
	btn.FontFace = FONT; btn.TextSize = 18; btn.TextColor3 = BTN_INK
	btn.AutoButtonColor = false; btn.ZIndex = 4; btn.Parent = row
	corner(btn, UDim.new(0, 10)); stroke(btn, RGB(150, 98, 36), 2, 0.2)
	rec.btn = btn
	btn.MouseButton1Click:Connect(function()
		if item.id == "backpack" and (player:GetAttribute("Item_backpack") or 0) > 0 then
			local BW = workspace:FindFirstChild("BackpackWear"); local ev = BW and BW:FindFirstChild("ToggleWear")
			if ev then ev:FireServer() else say(rec, "the backpack is not answering", false) end
			return
		end
		if item.robux then
			-- a Game Pass: Roblox's own purchase prompt does the selling; the server grants the item when it completes
			if (player:GetAttribute("Item_" .. item.id) or 0) > 0 then say(rec, "already yours", true) return end
			local B = workspace:FindFirstChild(item.passHome or "Binoculars")
			local passId = B and tonumber(B:GetAttribute(item.passAttr or "BinocularsPassId")) or 0
			if passId <= 0 then say(rec, "coming soon", false) return end
			game:GetService("MarketplaceService"):PromptGamePassPurchase(player, passId)
			return
		end
		if not onSale(item) then say(rec, "not in the shop yet", false) return end
		attempt(item, rec)
	end)
	end
end

-- ---- answers to purchases made from a prompt in the world (the cheese stand): a toast, since there is no row
local said = RS:WaitForChild("ShopSaid")
local saidGui = Instance.new("ScreenGui"); saidGui.Name = "ShopSaid"; saidGui.ResetOnSpawn = false; saidGui.IgnoreGuiInset = true; saidGui.DisplayOrder = 8; saidGui.Parent = pg
local saidLabel = Instance.new("TextLabel"); saidLabel.AnchorPoint = Vector2.new(0.5, 1); saidLabel.Position = UDim2.new(0.5, 0, 1, -118); saidLabel.Size = UDim2.fromOffset(380, 44)
saidLabel.BackgroundColor3 = RGB(58, 36, 16); saidLabel.BackgroundTransparency = 0.1; saidLabel.BorderSizePixel = 0; saidLabel.FontFace = FONT; saidLabel.TextSize = 20
saidLabel.TextColor3 = GOLD; saidLabel.Text = ""; saidLabel.Visible = false; saidLabel.Parent = saidGui
corner(saidLabel, UDim.new(0, 14)); stroke(saidLabel, GOLD, 2, 0.2)
local saidAt = 0
said.OnClientEvent:Connect(function(id, ok, why)
	if ok and id == "cheese" then return end                   -- the eating says it
	local text = ok and "Bought!" or (why == "not on sale yet" and "Coming soon" or tostring(why or "no"))
	saidLabel.Text = text; saidLabel.Visible = true
	local t = os.clock(); saidAt = t
	task.delay(3, function() if saidAt == t then saidLabel.Visible = false end end)
end)

-- ---- ACORN PACKS: Robux straight into the purse. Developer Products; the id of each lives on workspace.AcornPacks as
-- Product_<key> (0 until Shannon creates it on the Creator Hub) and what it grants as Acorns_<key>. The price is whatever
-- the product says, read from Roblox, so re-pricing is done there and nowhere else. The ReceiptRouter grants the acorns.
local PACKS = {
	{key = "handful", name = "A handful of acorns",     blurb = "Tipped straight into your purse. A slingshot's worth, or a portrait with change."},
	{key = "basket",  name = "A basket of acorns",      blurb = "The painter could do the whole family."},
	{key = "barrow",  name = "A wheelbarrow of acorns", blurb = "A backpack's worth, and a portrait to celebrate."},
}
local PK = workspace:WaitForChild("AcornPacks", 10)
local packRows, packPrice = {}, {}
local refreshPacks
local function fetchPackPrice(pk)
	local id = PK and PK:GetAttribute("Product_" .. pk.key) or 0
	if id <= 0 or packPrice[pk.key] ~= nil then return end
	packPrice[pk.key] = "..."
	task.spawn(function()
		local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Product) end)
		packPrice[pk.key] = (ok and info and info.PriceInRobux) or false
		refreshPacks()
	end)
end
local packHeader = Instance.new("TextLabel")
packHeader.TextWrapped=true;packHeader.Size = UDim2.new(1, 0, 0, 42); packHeader.BackgroundTransparency = 1; packHeader.LayoutOrder = 50; packHeader.ZIndex = 3
packHeader.Text = "Acorn packs  -  Robux, straight into your purse"; packHeader.TextXAlignment = Enum.TextXAlignment.Left
packHeader.FontFace = FONT; packHeader.TextSize = 16; packHeader.TextColor3 = RGB(58, 36, 16); packHeader.Visible = false; packHeader.Parent = list
for i, pk in ipairs(PACKS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 132); row.BackgroundColor3 = FACE_DEEP; row.BorderSizePixel = 0
	row.LayoutOrder = 50 + i; row.ZIndex = 3; row.Visible = false; row.Parent = list
	corner(row, UDim.new(0, 14)); stroke(row, SLOT_EDGE, 2, 0.45)
	local name = Instance.new("TextLabel")
	local illustration=Illustrations.draw(row,"acorn",64);illustration.Position=UDim2.fromOffset(8,13)
	name.TextWrapped=true;name.Position = UDim2.fromOffset(86, 7); name.Size = UDim2.new(1,-100,0,42); name.BackgroundTransparency = 1
	name.TextXAlignment = Enum.TextXAlignment.Left; name.FontFace = FONT; name.TextSize = 19; name.TextColor3 = RGB(58, 36, 16); name.ZIndex = 4; name.Parent = row
	local blurb = Instance.new("TextLabel")
	blurb.Position = UDim2.fromOffset(86, 53); blurb.Size = UDim2.new(1,-100,0,36); blurb.BackgroundTransparency = 1
	blurb.Text = pk.blurb; blurb.TextWrapped = true; blurb.TextXAlignment = Enum.TextXAlignment.Left; blurb.TextYAlignment = Enum.TextYAlignment.Top
	blurb.FontFace = FONT; blurb.TextSize = 13; blurb.TextColor3 = INK_DIM; blurb.ZIndex = 4; blurb.Parent = row
	local note = Instance.new("TextLabel")
	note.AnchorPoint = Vector2.new(0, 1); note.Position = UDim2.new(0, 12, 1, -12); note.Size = UDim2.fromOffset(150, 16)
	note.BackgroundTransparency = 1; note.Text = ""; note.TextXAlignment = Enum.TextXAlignment.Left; note.FontFace = FONT
	note.TextSize = 13; note.TextTransparency = 1; note.ZIndex = 4; note.Parent = row
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0); btn.Position = UDim2.new(1, -12, 0, 93); btn.Size = UDim2.fromOffset(120, 34)
	btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0; btn.FontFace = FONT; btn.TextSize = 18; btn.TextColor3 = BTN_INK
	btn.AutoButtonColor = false; btn.ZIndex = 4; btn.Parent = row
	corner(btn, UDim.new(0, 10)); stroke(btn, RGB(150, 98, 36), 2, 0.2)
	local rec = {frame = row, note = note, btn = btn, name = name, label = ""}
	packRows[pk.key] = rec
	btn.MouseButton1Click:Connect(function()
		local id = PK and PK:GetAttribute("Product_" .. pk.key) or 0
		if id > 0 then
			MarketplaceService:PromptProductPurchase(player, id)      -- Roblox's own prompt sells it; the router grants it
		elseif RunService:IsStudio() and PK then
			PK.PackTry:FireServer(pk.key)                              -- free while testing, until the product exists
		else
			say(rec, "coming soon", false)
		end
	end)
end
refreshPacks = function()
	local studio = RunService:IsStudio()
	local anyLive = studio
	for _, pk in ipairs(PACKS) do
		local rec = packRows[pk.key]
		local id = PK and PK:GetAttribute("Product_" .. pk.key) or 0
		local n = PK and PK:GetAttribute("Acorns_" .. pk.key) or 0
		rec.name.Text = string.format("%s  (%d)", pk.name, n)
		if id > 0 then
			anyLive = true
			fetchPackPrice(pk)
			local price = packPrice[pk.key]
			rec.label = (type(price) == "number") and (ROBUX .. " " .. tostring(price)) or (ROBUX .. " ...")
		elseif studio then
			rec.label = "try (Studio)"
		else
			rec.label = "soon"
		end
		rec.btn.Text = rec.label
		local live = id > 0 or studio
		rec.btn.BackgroundColor3 = live and GOLD or RGB(214, 202, 176)
		rec.btn.TextColor3 = live and BTN_INK or INK_DIM
	end
	packHeader.Visible = anyLive
	for _, pk in ipairs(PACKS) do packRows[pk.key].frame.Visible = anyLive end
end
refreshPacks()
if PK then
	for _, pk in ipairs(PACKS) do
		PK:GetAttributeChangedSignal("Product_" .. pk.key):Connect(function() packPrice[pk.key] = nil; refreshPacks() end)
		PK:GetAttributeChangedSignal("Acorns_" .. pk.key):Connect(refreshPacks)
	end
	-- the toast: its own ScreenGui, because the panel's is disabled whenever the store is closed (Roblox's prompt closes it)
	local toastGui = Instance.new("ScreenGui"); toastGui.Name = "PackToast"; toastGui.ResetOnSpawn = false; toastGui.IgnoreGuiInset = true
	toastGui.DisplayOrder = 8; toastGui.Parent = pg
	local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118)   -- above the hotbar, under any panel
	toast.Size = UDim2.fromOffset(380, 44); toast.BackgroundColor3 = RGB(58, 36, 16); toast.BackgroundTransparency = 0.1; toast.BorderSizePixel = 0
	toast.FontFace = FONT; toast.TextSize = 20; toast.TextColor3 = GOLD; toast.Text = ""; toast.Visible = false; toast.Parent = toastGui
	corner(toast, UDim.new(0, 14)); stroke(toast, GOLD, 2, 0.2)
	local toastAt = 0
	PK.PackBought.OnClientEvent:Connect(function(key, n)
		toast.Text = string.format("+%d acorns!  The squirrels thank you.", n)
		toast.Visible = true
		local t = os.clock(); toastAt = t
		task.delay(3.5, function() if toastAt == t then toast.Visible = false end end)
		local rec = packRows[key]; if rec then say(rec, "+" .. tostring(n) .. " acorns", true) end
	end)
end

-- Everything that can change while the panel is open: the balance, what a thing costs, and whether you own it
-- already. Redrawn rather than reasoned about, so the page can never disagree with the server.
local function refresh()
	local have = player:GetAttribute("Acorns") or 0
	purse.Text = tostring(have) .. "  acorns"
	for _, item in ipairs(ITEMS) do
		local rec = rows[item.id]
		if rec and rec.swatches then
			local price = priceOf(item)
			local selling = onSale(item)
			local runIdx, left, by = fountainNow()
			if runIdx > 0 then                                          -- someone's colour is running: whose, and until when
				rec.priceLabel.Text = "free in " .. mmss(left)
				if rec.blurb then rec.blurb.Text = string.format("In use: %s's %s. Free again in %s.", tostring(by), COLOUR_NAMES[runIdx] or "colour", mmss(left)) end
			else
				rec.priceLabel.Text = selling and (type(price) == "number" and (tostring(price) .. " acorns") or "-") or "soon"
				if rec.blurb then rec.blurb.Text = item.blurb end
			end
			local can = selling and type(price) == "number" and have >= price and runIdx == 0
			for i, sw in ipairs(rec.swatches) do
				sw.BackgroundTransparency = (can or i == runIdx) and 0 or 0.55
				local st = sw:FindFirstChildOfClass("UIStroke")
				if st then st.Color = (i == runIdx) and RGB(255, 246, 220) or RGB(84, 48, 18); st.Thickness = (i == runIdx) and 3 or 2; st.Transparency = (i == runIdx) and 0 or 0.25 end
			end
		elseif rec and rec.btn then
			local price = priceOf(item)
			local owned = (player:GetAttribute("Item_" .. item.id) or 0) > 0
			local label
			if item.id == "backpack" and owned then                    -- the bag comes off and goes back on from here
				label = ((player:GetAttribute("Item_bagoff") or 0) > 0) and "Wear it" or "Take it off"
			elseif item.once and owned then
				label = "owned"
			elseif item.robux then
				label = "Robux"
			elseif type(price) ~= "number" then
				label = "-"
			else
				label = tostring(price) .. " acorns"
			end
			-- Nothing is for sale yet, so every button says so rather than pretending to work. The price stays
			-- on show above it, because knowing what things will cost is the point of looking.
			local selling = item.robux or onSale(item)              -- a Robux row is sold by Roblox's prompt
			if not selling then label = "soon" end
			rec.label = label
			if rec.btn.Text ~= "..." then rec.btn.Text = label end
			-- greyed when you cannot have it, either because it is already yours or you are short
			local affordable = selling and not (item.once and owned) and (item.robux or (type(price) == "number" and have >= price))
			if item.id == "backpack" and owned then affordable = true end       -- the wear switch is always live
			rec.btn.BackgroundColor3 = affordable and GOLD or RGB(214, 202, 176)
			rec.btn.TextColor3 = affordable and BTN_INK or INK_DIM
			if item.passAttr then                                       -- a pass row stays hidden until its pass exists
				local home = workspace:FindFirstChild(item.passHome or "")
				rec.frame.Visible = (home ~= nil) and (tonumber(home:GetAttribute(item.passAttr)) or 0) > 0
			end
		end
	end
end
refresh()
player:GetAttributeChangedSignal("Acorns"):Connect(refresh)
player:GetAttributeChangedSignal("Item_bagoff"):Connect(refresh)
do                                                     -- the fountain is the server's: its colour and clock, and the countdown
	local FCw = workspace:FindFirstChild("FountainColour")
	if FCw then for _, a in ipairs({"ActiveColour", "ActiveUntil", "ActiveBy"}) do FCw:GetAttributeChangedSignal(a):Connect(refresh) end end
	task.spawn(function()
		local was = false
		while true do
			task.wait(1)
			local running = fountainNow() > 0
			if gui.Enabled and (running or was) then refresh() end
			was = running
		end
	end)
end
F:GetAttributeChangedSignal("Selling"):Connect(refresh)
for _, item in ipairs(ITEMS) do
	player:GetAttributeChangedSignal("Item_" .. item.id):Connect(refresh)
	F:GetAttributeChangedSignal("Price_" .. item.id):Connect(refresh)
	F:GetAttributeChangedSignal("Sell_" .. item.id):Connect(refresh)
end

local function setOpen(on)
 gui.Enabled=on
 if on then pg:SetAttribute("OpenPanel","shop");refresh();fit()
 elseif pg:GetAttribute("OpenPanel")=="shop" then pg:SetAttribute("OpenPanel",nil) end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function()
 if pg:GetAttribute("OpenPanel")~="shop" then gui.Enabled=false end
end)
close.MouseButton1Click:Connect(function() setOpen(false) end)
shade.MouseButton1Click:Connect(function() setOpen(false) end)

-- OPEN AT A ROW: something in the world can open the store at its own row (the hang glider's ramp, for somebody who has
-- no glider yet: "see it in the Acorn Store"). workspace.Shop.OpenAt:Fire(id) - the row scrolls into view and its edge
-- glows gold for a moment.
task.spawn(function()
	local openAt = F:WaitForChild("OpenAt", 20)
	if not openAt then return end
	openAt.Event:Connect(function(id)
		if F:GetAttribute("Open") == false then return end
		if not gui.Enabled then setOpen(true) end
		local rec = rows[id]
		if not rec then return end
		local index = 1
		for i, item in ipairs(ITEMS) do if item.id == id then index = i end end
		list.CanvasPosition = Vector2.new(0, math.max(0, rec.frame.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 6))      -- rows are 84 tall with 10 between
		local st = rec.frame:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = GOLD; st.Thickness = 3; st.Transparency = 0
			task.delay(1.8, function() st.Color = SLOT_EDGE; st.Thickness = 2; st.Transparency = 0.45 end)
		end
	end)
end)

-- hang it off the purse square in the corner, whenever the bar turns up
task.spawn(function()
	for attempt = 1, 120 do
		local bar = pg:FindFirstChild("HudBar")
		local square = bar and bar:FindFirstChild("Bar") and bar.Bar:FindFirstChild("Purse")
		if square and square:IsA("TextButton") then
			square.MouseButton1Click:Connect(function()
				-- the purse always shows your count; it only OPENS the store when there is something in it
				-- worth buying. workspace.Shop.Open is the switch.
				if F:GetAttribute("Open") == false then return end
				setOpen(not gui.Enabled)
			end)
			F:GetAttributeChangedSignal("Open"):Connect(function()
				if F:GetAttribute("Open") == false and gui.Enabled then setOpen(false) end
			end)
			return
		end
		task.wait(0.5)
	end
	warn("ShopPanel: never found the purse button; the store cannot be opened")
end)
]====]})
local sources={}
sources.Catalogue=[====[-- Stable ids are saved in the existing item ledger. Never rename released ids.
return {
 {id="rescue", name="Swamp rescuer", area="forest", icon="rescue", hint="Free a baby squirrel from a cage in the swamp."},
 {id="riddle", name="Curious mind", area="forest", icon="book", hint="Have a go at the forest question board. Every answer counts."},
 {id="race", name="Forest dash", area="forest", icon="flag", hint="Finish a timed squirrel race in the forest."},
 {id="hoop", name="Nothing but net", area="forest", icon="hoop", item="slingshot", hint="Score a basket at the forest hoop. A shot costs 1 acorn; a basket awards 3."},
 {id="find", name="A new friend", area="forest", icon="rescue", hint="Find a squirrel you have not collected yet."},
 {id="gold", name="Golden discovery", area="gold", icon="rescue", hint="Find today's Golden Squirrel. Your clue is on the Clues page."},
 {id="book", name="One more page", area="village", icon="book", hint="Open a book in the bookstore. All stories are free to read."},
 {id="coffee", name="Café zoomies", area="village", icon="coffee", hint="Sit with a coffee at the café and enjoy the zoomies."},
 {id="cheese", name="A little mischief", area="village", icon="cheese", hint="Try the cheese in the Rue. A small snack with a big surprise."},
 {id="bubbles", name="A splash of colour", area="village", icon="bubbles", hint="Choose coloured bubbles for the village fountain."},
 {id="glace", name="Brain freeze!", area="village", icon="glace", hint="Eat a glace until the brain freeze arrives."},
 {id="hat", name="Hats off!", area="village", icon="hat", hint="Buy or wear a hat from the Chapelier. An owned hat counts too."},
 {id="portrait", name="A moment on canvas", area="village", icon="portrait", hint="Sit for the painter by the river and have your portrait painted."},
 {id="baguette", name="Baguette bandit", area="village", icon="baguette", hint="Grab the baguette in the chase. This activity needs other players."},
 {id="zipline", name="Above the treetops", area="domaine", icon="ziphandle", item="ziphandle", hint="Use your handle to take a zipline ride across the map."},
 {id="climb", name="Ring the bell", area="domaine", icon="bell", hint="Finish the Sandstone Climb and ring the summit bell."},
 {id="glider", name="A squirrel's-eye view", area="domaine", icon="glider", item="glider", hint="Launch your hang glider from the Sandstone summit."},
}
]====]
sources.Rules=[====[-- Pure progression rules. Mutate session state before emitting ledger writes.
local Rules = {}
function Rules.record(state, id, day, allowed)
 if not allowed[id] or state.stamps[id] == day then return nil end
 local old = state.stamps[id] or 0
 state.stamps[id] = day
 local changes = {{"passport_"..id, day - old}}
 local n = 0
 for key, d in pairs(state.stamps) do if allowed[key] and d == day then n += 1 end end
 if n >= 3 and state.last < day then
  table.insert(changes, {"passport_outing_last", day-state.last})
  table.insert(changes, {"passport_outings", 1})
  state.last = day; state.outings += 1
 end
 return changes
end
return Rules
]====]
sources.PassportServer=[====[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local catalogue = require(F.Catalogue)
local Rules = require(F.Rules)
local award = RS:WaitForChild("AwardItems")
local activity = RS:WaitForChild("PassportActivity") -- BindableEvent: never client-callable
local allowed, states, queued = {}, {}, {}
for _, entry in ipairs(catalogue) do allowed[entry.id] = true end
local function item(p,id) return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function today()
 local daily = workspace:FindFirstChild("Daily")
 local offset = daily and daily:GetAttribute("DayOffsetHours") or 9
 return math.floor((os.time()-offset*3600)/86400)
end
local function mark(p,id)
 if not p or p.Parent ~= Players or not allowed[id] then return end
 local state = states[p]
 if not state then
  queued[p] = queued[p] or {}; queued[p][id] = true
  return
 end
 local changes = Rules.record(state,id,today(),allowed)
 if changes then for _, pair in ipairs(changes) do award:Fire(p,pair[1],pair[2]) end end
end
activity.Event:Connect(mark)
award.Event:Connect(function(p,id,n)
 if type(id) ~= "string" or type(n) ~= "number" or n <= 0 then return end
 local mapped = ({baskets="hoop",croc_rescues="rescue",gassy="cheese",bubbles="bubbles",daily_gold="gold",portrait="portrait"})[id]
 if id:match("^hatwear_") or id:match("^hat_") then mapped="hat" end
 if id:match("^q_round_") then mapped="riddle" end
 if mapped then mark(p,mapped) end
end)
local function watchCharacter(p,char)
 for attribute,id in pairs({Riding="zipline",Gliding="glider"}) do
  char:GetAttributeChangedSignal(attribute):Connect(function() if char:GetAttribute(attribute)==true then mark(p,id) end end)
 end
end
local function watch(p)
 if queued[p] == nil then queued[p] = {} end
 p.CharacterAdded:Connect(function(c) watchCharacter(p,c) end)
 if p.Character then watchCharacter(p,p.Character) end
 p:GetAttributeChangedSignal("CoffeeUntil"):Connect(function()
  if (p:GetAttribute("CoffeeUntil") or 0) > workspace:GetServerTimeNow() then mark(p,"coffee") end
 end)
 task.spawn(function()
  while p.Parent==Players and not p:GetAttribute("SaveLoaded") do task.wait(0.1) end
  if p.Parent~=Players then return end
  -- The squirrel total is set just after SaveLoaded; don't mistake loading for a new find.
  task.wait()
  if p.Parent~=Players then return end
  local state={stamps={},last=item(p,"passport_outing_last"),outings=item(p,"passport_outings")}
  for id in pairs(allowed) do state.stamps[id]=item(p,"passport_"..id) end
  states[p]=state
  -- Existing achievements get a permanent stamp, without counting as an activity today.
  local historic={rescue=item(p,"croc_rescues")>0,hoop=item(p,"baskets")>0,race=item(p,"race_best")>0,climb=item(p,"climb_best")>0,find=(p:GetAttribute("SquirrelsFound") or 0)>0,gold=item(p,"daily_gold")>0,riddle=item(p,"q_round_forest")>0}
  for k,v in pairs(p:GetAttributes()) do if k:match("^Item_hat_") and type(v)=="number" and v>0 then historic.hat=true end end
  for id,done in pairs(historic) do if done and state.stamps[id]==0 then state.stamps[id]=1; award:Fire(p,"passport_"..id,1) end end
  local count=p:GetAttribute("SquirrelsFound") or 0
  p:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
   local nextCount=p:GetAttribute("SquirrelsFound") or 0
   if nextCount>count then mark(p,"find") end
   count=nextCount
  end)
  local waiting=queued[p]; queued[p]=nil
  if waiting then for id in pairs(waiting) do mark(p,id) end end
  p:SetAttribute("PassportReady",true)
 end)
end
Players.PlayerAdded:Connect(watch)
for _,p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) states[p]=nil;queued[p]=nil end)
print("Passport: 17 activity stamps; daily outings; existing save ledger")
]====]
sources.PassportClient=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local p=Players.LocalPlayer
local pg=p:WaitForChild("PlayerGui")
local F=workspace:WaitForChild("Passport")
local catalogue=require(F:WaitForChild("Catalogue"))
local Art=require(RS:WaitForChild("SquirrelIllustrations"))
local toggle=RS:WaitForChild("PassportToggle")
local C=Color3.fromRGB
local PAPER,INK,MUTED,GOLD,GREEN=C(250,241,219),C(64,42,22),C(123,102,75),C(210,159,62),C(63,105,80)
local gui=Instance.new("ScreenGui");gui.Name="PassportGui";gui.ResetOnSpawn=false;gui.DisplayOrder=8;gui.IgnoreGuiInset=true;gui.Parent=pg
local function round(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local function text(parent,txt,x,y,w,h,size,col,font)
 local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,h);l.Text=txt;l.TextSize=size;l.Font=font or Enum.Font.FredokaOne;l.TextColor3=col or INK;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center;l.TextWrapped=true;l.Parent=parent;return l
end
local panel=Instance.new("Frame");panel.Name="Page";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-12,0,68);panel.BackgroundColor3=PAPER;panel.BorderSizePixel=0;panel.Visible=false;panel.Active=true;panel.Parent=gui;round(panel,16)
local rim=Instance.new("UIStroke");rim.Color=C(118,80,46);rim.Thickness=2;rim.Parent=panel
local binding=Instance.new("Frame");binding.Size=UDim2.new(0,5,1,-26);binding.Position=UDim2.fromOffset(8,13);binding.BackgroundColor3=GOLD;binding.BorderSizePixel=0;binding.Parent=panel;round(binding,3)
local heading=text(panel,"My Passport",24,9,230,27,23)
local summary=text(panel,"Loading your stamps...",24,36,240,18,12,MUTED)
local close=Instance.new("TextButton");close.Name="Close";close.Text="×";close.Font=Enum.Font.GothamBold;close.TextSize=27;close.Size=UDim2.fromOffset(40,40);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-10,0,7);close.BackgroundColor3=C(234,220,189);close.TextColor3=INK;close.BorderSizePixel=0;close.Parent=panel;round(close,12)
local tabs={};local selected="Outing"
for i,name in ipairs({"Outing","Stamps","Clues"}) do
 local b=Instance.new("TextButton");b.Name=name;b.Text=name;b.Font=Enum.Font.FredokaOne;b.TextSize=14;b.Position=UDim2.fromOffset(22+(i-1)*90,61);b.Size=UDim2.fromOffset(84,36);b.BorderSizePixel=0;b.Parent=panel;round(b,10);tabs[name]=b
end
local scroll=Instance.new("ScrollingFrame");scroll.Name="Entries";scroll.Position=UDim2.fromOffset(22,104);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=GOLD;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,8);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local activeRows={}
local function item(id) return tonumber(p:GetAttribute("Item_"..id)) or 0 end
local function today()
 local d=workspace:FindFirstChild("Daily");local offset=d and d:GetAttribute("DayOffsetHours") or 9
 return math.floor((workspace:GetServerTimeNow()-offset*3600)/86400)
end
local function unlocked(area)
 local boundary=workspace:FindFirstChild("Boundary");local need=boundary and boundary:GetAttribute("Need") or 10
 if area=="village" then return (p:GetAttribute("Found_forest") or 0)>=need end
 if area=="domaine" then return (p:GetAttribute("Found_village") or 0)>=need end
 return true
end
local function availability(entry)
 if not unlocked(entry.area) then return false,entry.area=="village" and "Find 10 forest squirrels to open the Rue." or "Find 10 Rue squirrels to open the Château." end
 if entry.item and item(entry.item)<=0 then return false,"Needs your "..({slingshot="slingshot",ziphandle="zipline handle",glider="hang glider"})[entry.item].." from the Acorn Store." end
 return true,entry.hint
end
local function row(title,body,icon,status,done,height)
 local width=scroll.AbsoluteSize.X-(icon and 69 or 12)-19
 local bodyHeight=game:GetService("TextService"):GetTextSize(body,13,Enum.Font.Gotham,Vector2.new(width,1000)).Y
 height=math.max(height or 103,bodyHeight+61)
 local r=Instance.new("Frame");r.Name=title;r.Size=UDim2.new(1,-5,0,height or 103);r.BackgroundColor3=done and C(229,235,211) or C(238,225,196);r.BorderSizePixel=0;r.LayoutOrder=#activeRows+1;r.Parent=scroll;round(r,11)
 if icon then local a=Art.draw(r,icon,55);a.Position=UDim2.fromOffset(6,10) end
 local tx=icon and 69 or 12
 local w=scroll.AbsoluteSize.X-tx-19
 local t=text(r,title,tx,9,w,23,16);t.TextTruncate=Enum.TextTruncate.AtEnd;t.TextWrapped=false
 local b=text(r,body,tx,34,w,(height or 103)-59,13,MUTED,Enum.Font.Gotham);b.TextYAlignment=Enum.TextYAlignment.Top
 local s=text(r,status or "",tx,(height or 103)-22,w,17,11,done and GREEN or MUTED)
 table.insert(activeRows,r)
end
local function render()
 if not panel.Visible then return end
 local previous=scroll.CanvasPosition
 for _,r in ipairs(activeRows) do r:Destroy() end;table.clear(activeRows)
 local day=today();local n,total=0,0
 for _,e in ipairs(catalogue) do local d=item("passport_"..e.id);if d>0 then total+=1 end;if d==day then n+=1 end end
 local outings=item("passport_outings")
 heading.Text=outings>=5 and "My Golden Passport" or "My Passport"
 heading.TextSize=outings>=5 and 20 or 23
 rim.Color=outings>=5 and GOLD or C(118,80,46)
 summary.Text=p:GetAttribute("PassportReady") and string.format("Today %d/3  ·  %d/%d stamps  ·  %d outings",math.min(n,3),total,#catalogue,outings) or "Loading your stamps..."
 for name,b in pairs(tabs) do b.BackgroundColor3=name==selected and GREEN or C(234,220,189);b.TextColor3=name==selected and PAPER or INK end
 if selected=="Outing" then
  local done=item("passport_outing_last")==day
  summary.Text=done and string.format("Outing complete!  ·  %d %s",outings,outings==1 and "outing" or "outings") or string.format("Enjoy 3 different activities today  ·  %d/3",math.min(n,3))
  local entries={}
  for i,e in ipairs(catalogue) do
   local usable=availability(e)
   if usable then table.insert(entries,{entry=e,index=i,done=item("passport_"..e.id)==day}) end
  end
  table.sort(entries,function(a,b) if a.done~=b.done then return not a.done end return a.index<b.index end)
  for _,v in ipairs(entries) do local e=v.entry;row(e.name,e.hint,e.icon,v.done and "Stamped today" or (e.area=="forest" and "Great Acorn Forest" or e.area=="domaine" and "Château de l'Acorn" or e.area=="gold" and "Today's Golden Squirrel" or "Rue de Noisette"),v.done) end
 elseif selected=="Stamps" then
  for _,e in ipairs(catalogue) do local usable,hint=availability(e);local stamp=item("passport_"..e.id)>0
   row(e.name,hint,e.icon,stamp and "Collected · yours to keep" or usable and "Waiting for a memory" or "A future adventure",stamp)
  end
 else
  local daily=workspace:FindFirstChild("Daily")
  local goldName=daily and daily:GetAttribute("GoldName") or ""
  local goldArea=daily and daily:GetAttribute("GoldArea") or ""
  local found=item("daily_gold")==day
  row("Today's Golden Squirrel",goldName~="" and (tostring(goldName).." is hiding in "..tostring(goldArea)..".") or "Today's clue is getting ready. Check back in a moment.","rescue",found and "Found today!" or "One golden visitor each day",found)
  row("Grand Keeper of the Great Acorn","Be the first eligible player to complete all 44 squirrels that day. The fountain statue and permanent Hall of Fame honour the winner.","bell",p:GetAttribute("ChampionTitle") or "Visit the Hall of Fame beside the Château",false,138)
  row("A moment on canvas","The painter by the river can paint your portrait. Find your picture in the riverside gallery.","portrait",tostring(workspace:FindFirstChild("Shop") and workspace.Shop:GetAttribute("Price_portrait") or "?").." acorns · optional",false,112)
  row("A fresh page tomorrow","Outings and Golden Squirrel clues refresh together. Your collected stamps and golden cover stay with you.","book","No missed-day penalty",false,112)
  row("Your golden passport","Enjoy 3 different activities in a day to complete an outing. Complete 5 outings for a golden cover. Missed days never erase progress.",outings>=5 and "goldpassport" or "passport",string.format("%d/5 outings · %d/%d permanent stamps",math.min(outings,5),total,#catalogue),outings>=5,130)
 end
 scroll.CanvasPosition=previous
end
local function fit()
 local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
 local mobile=UIS.TouchEnabled or vp.Y<500
 local width=math.min(mobile and 338 or 390,vp.X-24)
 local top=68
 local height=math.min(540,math.max(140,vp.Y-top-(mobile and 96 or 24)))
 panel.Size=UDim2.fromOffset(width,height)
 scroll.Size=UDim2.fromOffset(width-32,height-113)
 heading.Size=UDim2.fromOffset(width-78,27);summary.Size=UDim2.fromOffset(width-40,18)
 local tw=(width-52)/3
 for i,name in ipairs({"Outing","Stamps","Clues"}) do tabs[name].Position=UDim2.fromOffset(22+(i-1)*(tw+4),61);tabs[name].Size=UDim2.fromOffset(tw,36) end
 if panel.Visible then task.defer(render) end
end
local hidden={}
local suppressed={}
local quietNames={PromptTouch=true,PromptUI=true,HintGui=true,ChaseGui=true,ChaseInfoGui=true,DailyGui=true,SpeedGui=true}
local function coordinatePanels()
 local active=pg:GetAttribute("OpenPanel")
 local quiet=active=="passport" or active=="shop" or active=="book"
 if quiet then
  for _,g in ipairs(pg:GetChildren()) do
   if quietNames[g.Name] and (g:IsA("ScreenGui") or g:IsA("BillboardGui")) then
    if suppressed[g]==nil then suppressed[g]=g.Enabled end
    g.Enabled=false
   end
  end
 else
  for g,enabled in pairs(suppressed) do if g.Parent then g.Enabled=enabled end end
  table.clear(suppressed)
 end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(coordinatePanels)
pg.ChildAdded:Connect(function() task.defer(coordinatePanels) end)
local openedAt=0
local function closePage()
 panel.Visible=false
 if pg:GetAttribute("OpenPanel")=="passport" then pg:SetAttribute("OpenPanel",nil) end
 for o,was in pairs(hidden) do if o.Parent then o.Visible=was end end;table.clear(hidden)
end
local function openPage()
 pg:SetAttribute("OpenPanel","passport")
 for _,g in ipairs(pg:GetChildren()) do
  if g.Name=="ShopPanel" then g.Enabled=false end
  -- Leave established controls in place, while removing labels behind the open page.
  if g.Name=="DailyGui" then local pill=g:FindFirstChild("GoldPill");if pill and pill.Visible then hidden[pill]=true;pill.Visible=false end end
 end
 panel.Visible=true;openedAt=os.clock();fit();render()
end
toggle.Event:Connect(function() if panel.Visible then closePage() else openPage() end end)
close.Activated:Connect(closePage)
for name,b in pairs(tabs) do b.Activated:Connect(function() selected=name;scroll.CanvasPosition=Vector2.zero;render() end) end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if panel.Visible and pg:GetAttribute("OpenPanel")~="passport" then closePage() end end)
local function watchGui(g)
 if g:IsA("ScreenGui") and (g.Name=="ShopPanel" or g.Name=="BookReader" or g.Name=="HatShopGui" or g.Name=="GoldenReveal") then
  if g.Enabled and panel.Visible then closePage() end
  g:GetPropertyChangedSignal("Enabled"):Connect(function() if g.Enabled and panel.Visible then closePage() end end)
 end
end
pg.ChildAdded:Connect(watchGui);for _,g in ipairs(pg:GetChildren()) do watchGui(g) end
local pending=false
p.AttributeChanged:Connect(function(name)
 if panel.Visible and (name:sub(1,14)=="Item_passport_" or name:sub(1,6)=="Found_" or name=="PassportReady" or name=="ChampionTitle") and not pending then
  pending=true;task.defer(function() pending=false;render() end)
 end
end)
local function cameraChanged() fit();if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged);cameraChanged()
UIS.InputBegan:Connect(function(input,processed) if not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then closePage() end end)
RunService.Heartbeat:Connect(function()
 if not panel.Visible then return end
 local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not char or p:GetAttribute("Racing") or p:GetAttribute("Climbing") or p:GetAttribute("InChase") or char:GetAttribute("Riding") or char:GetAttribute("Gliding") then closePage();return end
 if hum and hum.MoveDirection.Magnitude>0.1 and os.clock()-openedAt>0.35 then closePage() end
end)
task.spawn(function() while gui.Parent do task.wait(30);if panel.Visible then render() end end end)
print("Passport: responsive journal ready")
]====]
sources.Illustrations=[====[-- Small, still, code-drawn illustrations. No external assets or per-frame animation.
local Art={}
local C=Color3.fromRGB
local colours={brown=C(112,72,42),gold=C(219,165,58),cream=C(255,246,220),green=C(76,119,92),blue=C(93,148,163)}
function Art.draw(parent,id,size)
 local canvas=Instance.new("Frame");canvas.Name="Illustration_"..id;canvas.Size=UDim2.fromOffset(size,size);canvas.BackgroundTransparency=1;canvas.ZIndex=parent.ZIndex+1;canvas.Parent=parent
 local function shape(x,y,w,h,col,r,rot)
  local f=Instance.new("Frame");f.Position=UDim2.fromScale(x,y);f.Size=UDim2.fromScale(w,h);f.BackgroundColor3=col;f.BorderSizePixel=0;f.Rotation=rot or 0;f.ZIndex=canvas.ZIndex;f.Parent=canvas
  if r then local c=Instance.new("UICorner");c.CornerRadius=UDim.new(r,0);c.Parent=f end
  return f
 end
 local function line(x,y,w,h,col,rot) return shape(x,y,w,h,col,0.5,rot) end
 local function circle(x,y,d,col) return shape(x,y,d,d,col,1) end
 local brown,gold,cream,green,blue=colours.brown,colours.gold,colours.cream,colours.green,colours.blue
 circle(.08,.08,.84,C(236,224,195))
 if id=="acorn" then
  shape(.31,.37,.43,.45,gold,.46,-12);shape(.25,.29,.51,.19,brown,.4,-12);line(.47,.17,.075,.17,brown,12)
  line(.40,.53,.025,.15,cream,-12)
 elseif id=="book" or id=="passport" or id=="goldpassport" then
  local cover=id=="goldpassport" and gold or green
  local foil=id=="goldpassport" and brown or gold
  shape(.24,.16,.55,.70,cover,.10,-6);shape(.22,.18,.05,.65,brown,.4,-6)
  shape(.32,.25,.34,.03,foil,.3,-6);shape(.34,.70,.31,.03,foil,.3,-6)
  circle(.40,.39,.21,foil);line(.48,.33,.04,.09,foil,-12)
 elseif id=="coffee" or id=="zoomies" then
  circle(.59,.43,.24,brown);circle(.64,.48,.13,cream)
  shape(.22,.35,.44,.40,cream,.18);shape(.25,.36,.38,.08,brown,1);line(.18,.76,.56,.04,brown)
  line(.31,.13,.04,.16,gold,-14);line(.47,.10,.04,.17,gold,14)
 elseif id=="glace" then
  shape(.40,.50,.20,.35,gold,.1,10);circle(.28,.27,.32,C(227,158,164));circle(.45,.29,.30,cream);circle(.39,.15,.29,C(122,76,50))
 elseif id=="cheese" then
  shape(.20,.38,.59,.36,gold,.10,-12);shape(.25,.31,.46,.12,C(252,208,95),.25,-12)
  for _,p in ipairs({{.30,.51,.10},{.57,.44,.12},{.57,.63,.06}}) do circle(p[1],p[2],p[3],C(166,114,37)) end
 elseif id=="bubbles" then
  shape(.27,.43,.25,.37,blue,.18);shape(.31,.34,.17,.10,gold,.12)
  for _,p in ipairs({{.52,.17,.22,C(205,144,170)},{.66,.42,.16,C(129,172,148)},{.33,.15,.13,C(160,146,197)}}) do circle(p[1],p[2],p[3],p[4]);circle(p[1]+.035,p[2]+.025,p[3]*.25,cream) end
 elseif id=="hat" then
  shape(.28,.24,.44,.44,green,.2);shape(.27,.57,.47,.10,gold,.1);shape(.14,.65,.72,.12,green,1)
 elseif id=="baguette" then
  shape(.34,.14,.31,.74,gold,.5,35)
  for i=1,3 do line(.32+i*.08,.29+i*.14,.18,.04,cream,-18) end
 elseif id=="bell" then
  circle(.31,.25,.39,gold);shape(.30,.43,.41,.29,gold,.10);shape(.21,.69,.60,.08,brown,.5);circle(.45,.74,.12,gold);line(.46,.16,.06,.12,brown)
 elseif id=="glider" then
  for i=0,4 do shape(.14+i*.145,.25+math.abs(i-2)*.075,.155,.26,({C(189,87,64),gold,cream,green,blue})[i+1],.05,(i-2)*13) end
  line(.48,.40,.04,.38,brown);line(.29,.57,.44,.04,brown);line(.31,.39,.035,.20,brown,-34);line(.65,.39,.035,.20,brown,34)
 elseif id=="ziphandle" then
  line(.12,.21,.76,.04,brown,-16);circle(.40,.19,.18,gold);circle(.44,.23,.10,brown);line(.48,.36,.05,.30,brown);line(.26,.65,.49,.09,brown);shape(.20,.62,.12,.16,gold,.3);shape(.68,.62,.12,.16,gold,.3)
 elseif id=="hoop" then
  shape(.48,.15,.34,.29,cream,.08);shape(.51,.19,.27,.21,blue,.08);line(.38,.43,.40,.06,brown)
  for i=0,3 do line(.39+i*.11,.49,.025,.21,cream,(i-1.5)*-15) end
  circle(.18,.58,.26,gold);line(.20,.70,.22,.025,brown,-14)
 elseif id=="flag" then
  line(.29,.19,.05,.63,brown);shape(.35,.21,.41,.28,green,.05);shape(.39,.25,.10,.10,cream);shape(.58,.37,.10,.09,cream)
 elseif id=="seed" then
  shape(.25,.22,.51,.59,cream,.10,-6);line(.48,.41,.03,.26,green);shape(.32,.38,.19,.10,green,.5,32);shape(.49,.33,.19,.10,green,.5,-32);line(.34,.71,.28,.025,brown)
 elseif id=="binoculars" then
  shape(.20,.28,.23,.39,green,.15,10);shape(.57,.28,.23,.39,green,.15,-10);line(.40,.39,.20,.10,brown);circle(.16,.56,.30,brown);circle(.54,.56,.30,brown);circle(.21,.61,.20,blue);circle(.59,.61,.20,blue)
 elseif id=="slingshot" then
  line(.48,.47,.10,.37,brown);line(.31,.22,.09,.36,brown,-35);line(.60,.22,.09,.36,brown,35);line(.23,.22,.51,.04,gold);circle(.42,.18,.16,brown)
 elseif id=="backpack" then
  shape(.29,.18,.42,.64,brown,.28);shape(.24,.31,.52,.51,green,.22);shape(.34,.53,.32,.22,gold,.14);line(.29,.40,.42,.04,cream)
 elseif id=="portrait" then
  shape(.24,.15,.52,.64,brown,.03);shape(.29,.20,.42,.53,cream,.01);circle(.39,.28,.23,gold);shape(.36,.52,.28,.16,green,.4);line(.31,.77,.04,.12,brown,-12);line(.67,.77,.04,.12,brown,12)
 else -- A friendly squirrel profile, including a large curled tail.
  circle(.14,.25,.40,brown);circle(.23,.32,.23,gold);shape(.38,.46,.30,.32,brown,.5,-15);circle(.53,.27,.26,brown);shape(.57,.19,.10,.19,brown,.4,-14);circle(.71,.37,.035,cream);line(.40,.79,.32,.05,brown)
 end
 return canvas
end
return Art
]====]
for _,c in ipairs(changes) do local f,e=loadstring(c.source);assert(f,e) end
for n,s in pairs(sources) do local f,e=loadstring(s);assert(f,n..": "..tostring(e)) end
local RS=game:GetService("ReplicatedStorage")
local hist=game:GetService("ChangeHistoryService");hist:SetWaypoint("Before Passport")
local F=workspace:FindFirstChild("Passport") or Instance.new("Folder");F.Name="Passport";F.Parent=workspace
for _,n in ipairs({"PassportActivity","PassportToggle"}) do local o=RS:FindFirstChild(n) or Instance.new("BindableEvent");assert(o:IsA("BindableEvent"));o.Name=n;o.Parent=RS end
for n,s in pairs(sources) do local parent=n=="Illustrations" and RS or F;local name=n=="Illustrations" and "SquirrelIllustrations" or n;local o=parent:FindFirstChild(name) or Instance.new((n=="PassportServer" or n=="PassportClient") and "Script" or "ModuleScript");o.Name=name;o.Source=s;if n=="PassportClient" then o.RunContext=Enum.RunContext.Client end;o.Parent=parent end
for _,c in ipairs(changes) do c.target.Source=c.source end
for _,p in ipairs(workspace.Bookshop:GetDescendants()) do if p:IsA("ProximityPrompt") and p.Name=="BookPrompt" then p.ActionText="Read - free" end end;workspace.Bookshop:SetAttribute("FreeReading",true)
F:SetAttribute("Version","1.0.0");hist:SetWaypoint("Passport and illustrated shop")
warn("QQ PASSPORT v5: 9 integrations and 5 Passport sources compiled and installed; portrait price "..tostring(workspace.Shop:GetAttribute("Price_portrait")))
end
