-- WelcomeClient (workspace.Welcome, RunContext Client; welcome1, Oct 22 2026): a brand-new player's first minute. Shannon:
-- "out of everyone who enters the game, less than half stay to get a first squirrel ... why are more than 50% leaving before
-- playing?" Nothing told a newcomer what to do, and the nearest squirrel was a small grey shape ~50 studs away among grey
-- rocks. Now, for a player who has found NO squirrel yet: the nearest unfound forest squirrel gets a gold outline (seen
-- through the trees) and sparkles, and calls out through SquirrelBubble ("Psst! Over here! ... Click on me!") until found; then
-- the squirrel that was found says how many are left. Anyone with a find already never sees any of it. Nothing is saved.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer
local Bubble = require(RS:WaitForChild("SquirrelBubble"))
local GOLD = Color3.fromRGB(255, 214, 90)
local CALLS = {
	"Psst! Over here! We're hiding all over France. Can you find all 44 of us? Click on me!",   -- (Shannon: "click on me. not tap me")
	"Over here! Click on me!",
	"Still here! Come and find me!",
	"Psst! Over here!",
}
local GIVE_UP = 180                                                      -- (then the free hint takes over)
local function finds() return tonumber(player:GetAttribute("SquirrelsFound")) or 0 end
local t0 = os.clock()
while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 60 do task.wait(0.25) end
if not player:GetAttribute("SaveLoaded") or finds() > 0 then return end
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart", 20)
task.wait(2)                                                            -- (the spawn settles, the forest streams in)
if not root or finds() > 0 or player:GetAttribute("Area") ~= "forest" then return end
local function idOf(m) return m:GetAttribute("SquirrelId") or (m.Name:lower():gsub("_color$", "")) end
local function inForest(pos) return pos.X < 150 and pos.Z > -300 end    -- (SpawnReturn's area lines)
local function nearest()
	local best, bd
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		if m:IsA("Model") and m:IsDescendantOf(workspace) and not m.Name:lower():find("gray") then
			local ok, cf = pcall(function() return m:GetBoundingBox() end)
			if ok and inForest(cf.Position) then
				local d = (cf.Position - root.Position).Magnitude
				if not bd or d < bd then best, bd = m, d end
			end
		end
	end
	return best
end
local target = nearest()
if not target then return end
local hl = Instance.new("Highlight"); hl.Name = "WelcomeGlow"; hl.FillTransparency = 1; hl.OutlineColor = GOLD
hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = target; hl.Parent = target
local body = target:FindFirstChildWhichIsA("BasePart", true)
local att, fx
if body then
	att = Instance.new("Attachment"); att.Name = "WelcomeSparkles"; att.Position = Vector3.new(0, 1.2, 0); att.Parent = body
	fx = Instance.new("ParticleEmitter"); fx.Color = ColorSequence.new(GOLD); fx.LightEmission = 1; fx.Rate = 8
	fx.Lifetime = NumberRange.new(0.9, 1.5); fx.Speed = NumberRange.new(1.5, 3); fx.SpreadAngle = Vector2.new(180, 180)
	fx.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
	fx.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}); fx.Parent = att
end
local done = false
local function stop()
	done = true
	if hl then hl:Destroy(); hl = nil end
	if att then att:Destroy(); att = nil end
	for _, d in ipairs(target:GetDescendants()) do                    -- (nothing of ours left behind, whatever happened)
		if d.Name == "WelcomeGlow" or d.Name == "WelcomeSparkles" then d:Destroy() end
	end
end
task.spawn(function()
	local i, start = 1, os.clock()
	while not done and finds() == 0 and os.clock() - start < GIVE_UP and target.Parent do
		Bubble.say(target, CALLS[i], {secs = (i == 1) and 7 or 4})
		i = (i % #CALLS) + 1
		if i == 1 then i = 2 end                                        -- (the long line only the first time)
		task.wait(12)
	end
	if not done and finds() == 0 then stop() end
end)
-- the first find: the squirrel that was found says how many are left
local con
con = player:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
	if finds() < 1 then return end
	con:Disconnect()
	stop()
	local ids = {}
	for id in tostring(player:GetAttribute("FoundIds") or ""):gmatch("[^,]+") do ids[id] = true end
	local speaker = target
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		if m:IsA("Model") and not m.Name:lower():find("gray") and ids[idOf(m)] then speaker = m break end
	end
	local forestLeft = 15 - (tonumber(player:GetAttribute("Found_forest")) or 1)
	task.wait(3.5)                                                      -- (after the find's own reveal)
	if speaker and speaker.Parent then
		Bubble.say(speaker, string.format("You found me! %d more of us are hiding in France - %d right here in the forest.", 44 - finds(), forestLeft), {secs = 6})
	end
end)
