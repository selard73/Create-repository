-- RoomHide: the bookshop's and the chapel's insides are rooms hung 300 studs over the map, and anyone who looked
-- straight up could see them floating in the sky. Shannon (Sep 25 2026): "those should not be visible in the sky or
-- anywhere unless you are inside them". So each player's own screen hides a room - its parts, decals and signs -
-- unless that player's camera or character is in it, and hides anyone else who is up in a room, name tags and all.
-- Only what shows is changed, and only on that one screen: nothing moves and nothing stops being solid, so the doors,
-- the pews and the floor under your feet work as before, and whoever is inside sees the room as it always was.
-- The rooms: every Model tagged "SkyRoom", carrying BoxCF (CFrame) and BoxSize (Vector3), the box around it. This
-- tags workspace.Bookshop.Room and workspace.Chapel.Room; their builders tag them again whenever they are rebuilt.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local CS = game:GetService("CollectionService")
	local report = {}
	for _, name in ipairs({"Bookshop", "Chapel"}) do
		local home = workspace:FindFirstChild(name)
		local room = home and home:FindFirstChild("Room")
		if room and room:IsA("Model") then
			local cf, size = room:GetBoundingBox()
			room:SetAttribute("BoxCF", cf); room:SetAttribute("BoxSize", size)
			CS:AddTag(room, "SkyRoom")
			table.insert(report, string.format("%s room %.0f x %.0f x %.0f at %.0f,%.0f,%.0f", name, size.X, size.Y, size.Z, cf.X, cf.Y, cf.Z))
		else
			table.insert(report, name .. ": no Room")
		end
	end

	local old = workspace:FindFirstChild("RoomHide")
	if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "RoomHide"
	F:SetAttribute("Margin", opts.margin or 16)         -- how far outside its box a camera still counts as in the room

	local CLIENT = [==[
local CS = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local F = script.Parent
local MARGIN = F:GetAttribute("Margin") or 16

-- things that are switched off rather than faded: signs on the walls, name tags, sparkles
local SWITCHED = {"SurfaceGui", "BillboardGui", "ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles"}
local function switched(d)
	for _, c in ipairs(SWITCHED) do if d:IsA(c) then return true end end
	return false
end

local rooms = {}                                        -- room model -> {cf, half, hidden, off = what this switched off}
local function within(r, p, m)
	local q = r.cf:PointToObjectSpace(p)
	return math.abs(q.X) <= r.half.X + m and math.abs(q.Y) <= r.half.Y + m and math.abs(q.Z) <= r.half.Z + m
end
-- only what is really up in the room: anything of a room's that sits down on the map stays in sight
local function upThere(r, d)
	local part = d:IsA("BasePart") and d or d:FindFirstAncestorWhichIsA("BasePart")
	return part ~= nil and within(r, part.Position, 2)
end
local function apply(r, d, hide)
	if d:IsA("BasePart") or d:IsA("Decal") then            -- Decal takes in Texture too
		if not hide then d.LocalTransparencyModifier = 0
		elseif upThere(r, d) then d.LocalTransparencyModifier = 1 end
	elseif switched(d) then
		if hide then
			if d.Enabled and upThere(r, d) then r.off[d] = true; d.Enabled = false end
		elseif r.off[d] then
			r.off[d] = nil; d.Enabled = true
		end
	end
end
local function setHidden(r, hide)
	r.hidden = hide
	for _, d in ipairs(r.model:GetDescendants()) do apply(r, d, hide) end
end
local function addRoom(room)
	if rooms[room] or not room:IsA("Model") then return end
	local cf, size = room:GetAttribute("BoxCF"), room:GetAttribute("BoxSize")
	if typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" then return end
	local r = {model = room, cf = cf, half = size / 2, hidden = false, off = {}}
	rooms[room] = r
	r.conn = room.DescendantAdded:Connect(function(d) if r.hidden then apply(r, d, true) end end)   -- streamed in later
	setHidden(r, true)                                  -- the first frame shows it again if you are in it
end
for _, room in ipairs(CS:GetTagged("SkyRoom")) do addRoom(room) end
CS:GetInstanceAddedSignal("SkyRoom"):Connect(addRoom)
CS:GetInstanceRemovedSignal("SkyRoom"):Connect(function(room)
	local r = rooms[room]
	if r then r.conn:Disconnect(); rooms[room] = nil end
end)

-- someone else up in a room this screen is not showing is out of sight with it
local hiddenChars = {}                                  -- their character -> what this switched off on it
local function hideChar(char)
	local off = hiddenChars[char] or {}
	hiddenChars[char] = off
	for _, d in ipairs(char:GetDescendants()) do        -- again every check, for a hat put on while up there
		if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 1
		elseif switched(d) and d.Enabled then off[d] = true; d.Enabled = false end
	end
end
local function showChar(char)
	local off = hiddenChars[char]
	hiddenChars[char] = nil
	if not (off and char.Parent) then return end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 0
		elseif off[d] then d.Enabled = true end
	end
end

-- every frame, just after the camera moves, so a room is never a frame late appearing as you arrive in it
local nextOthers = 0
RunService:BindToRenderStep("RoomHide", Enum.RenderPriority.Camera.Value + 2, function()
	local cam = workspace.CurrentCamera
	local c = cam and cam.CFrame.Position
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local h = hrp and hrp.Position
	for _, r in pairs(rooms) do
		local inside = (c ~= nil and within(r, c, MARGIN)) or (h ~= nil and within(r, h, MARGIN))
		if inside == r.hidden then setHidden(r, not inside) end
	end
	local now = os.clock()
	if now < nextOthers then return end
	nextOthers = now + 0.25
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local oc = other.Character
			local oh = oc and oc:FindFirstChild("HumanoidRootPart")
			local hide = false
			if oh then
				for _, r in pairs(rooms) do
					if r.hidden and within(r, oh.Position, 6) then hide = true break end
				end
			end
			if hide then hideChar(oc) elseif oc and hiddenChars[oc] then showChar(oc) end
		end
	end
	for ch in pairs(hiddenChars) do if not ch.Parent then hiddenChars[ch] = nil end end
end)
]==]
	local c = Instance.new("Script"); c.Name = "RoomHideClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	return table.concat(report, " | ")
end
