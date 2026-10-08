-- FunicularTags (StarterPlayerScripts, Oct 4 2026): anyone seated in a funicular car has their overhead name and title
-- hidden on this screen while they ride (Shannon: "the user's name and title sticks out the top when they are seated
-- inside"), and shown again the moment they get off. Purely visual and local: every player's own copy does the same.
local Players = game:GetService("Players")
local hidden = {}            -- [character] = {gui = previous Enabled, ...}

local function cars()
	local P = workspace:FindFirstChild("PortoNocciola")
	local F = P and P:FindFirstChild("15 Funicolare")
	return F and F:FindFirstChild("Cars")
end

local function hide(char)
	if hidden[char] then return end
	local rec = {guis = {}, hum = nil}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Enabled then rec.guis[d] = true d.Enabled = false end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then rec.hum = hum.DisplayDistanceType hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	hidden[char] = rec
end

local function show(char)
	local rec = hidden[char]
	if not rec then return end
	hidden[char] = nil
	for g in pairs(rec.guis) do if g.Parent then g.Enabled = true end end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and rec.hum then hum.DisplayDistanceType = rec.hum end
end

while true do
	task.wait(0.25)
	local C = cars()
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		if char and C and seat and seat:IsDescendantOf(C) then hide(char) elseif char then show(char) end
	end
	for char in pairs(hidden) do if not char.Parent then hidden[char] = nil end end
end
