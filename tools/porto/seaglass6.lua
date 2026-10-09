-- porto/seaglass6 (job 48): EDIT mode. Bella's game on a phone: her words at the left of the screen, the reveal in the
-- middle, the panel hard against the right edge (Shannon, mobile). Four exact finds in workspace.SeaGlass.SeaGlassClient
-- (after job 41, about 13322 chars); compiled before writing; original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass6.
-- Output "QQ SG6".
if game:GetService("RunService"):IsRunning() then warn("QQ SG6 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG6 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - 13322) > 60 then warn(string.format("QQ SG6 ABORT - SeaGlassClient is %d chars, expected about 13322 (job 41 not run yet, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
for i, p in ipairs({{[===[
local function say(line, secs)
	local m = bella()
	if Bubble and m then pcall(function() Bubble.say(m, line, {secs = secs or 4.5}) end) end
end
]===], [===[
local open = false
local phoneAnchor   -- a phone: Bella's words pinned to the left of the screen (an invisible part her bubble follows), clear of the panel (Oct 9)
local function phone() local cam = workspace.CurrentCamera; return UIS.TouchEnabled and cam ~= nil and cam.ViewportSize.Y < 560 end
local function say(line, secs)
	local m = bella()
	if not (Bubble and m) then return end
	if open and phone() then
		local cam = workspace.CurrentCamera
		if not (phoneAnchor and phoneAnchor.Parent) then
			phoneAnchor = Instance.new("Part"); phoneAnchor.Name = "BellaWordsAnchor"; phoneAnchor.Anchored = true; phoneAnchor.CanCollide = false; phoneAnchor.CanQuery = false; phoneAnchor.CanTouch = false
			phoneAnchor.Transparency = 1; phoneAnchor.CastShadow = false; phoneAnchor.Size = Vector3.new(0.05, 0.05, 0.05); phoneAnchor.Parent = cam
			local conn; conn = game:GetService("RunService").RenderStepped:Connect(function()
				if not (phoneAnchor and phoneAnchor.Parent) then conn:Disconnect() return end
				local c = workspace.CurrentCamera; if not c then return end
				local v = c.ViewportSize
				local ray = c:ScreenPointToRay(v.X * 0.17, v.Y * 0.5)   -- the bubble's middle: a sixth of the way in, mid-height
				phoneAnchor.CFrame = CFrame.new(ray.Origin + ray.Direction * 6 - Vector3.new(0, 1.5, 0))
			end)
		end
		pcall(function() Bubble.say(phoneAnchor, line, {secs = secs or 4.5}) end)
		return
	end
	pcall(function() Bubble.say(m, line, {secs = secs or 4.5}) end)
end
]===]}, {[===[
local open = false
local function closePanel()
]===], [===[
local function closePanel()
]===]}, {[===[
	panel.Size = UDim2.fromOffset(math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s))
]===], [===[
	panel.Size = UDim2.fromOffset(math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s))
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
]===]}, {[===[
	local base = root and (root.CFrame * CFrame.new(0, 1.2, -3.2)) or (cam and cam.CFrame * CFrame.new(0, -0.5, -5)) or CFrame.new()
]===], [===[
	local base = root and (root.CFrame * CFrame.new(-1.7, 0.6, -3.0)) or (cam and cam.CFrame * CFrame.new(-1.2, -0.8, -5)) or CFrame.new()   -- left and low: clear of her bubble (Oct 9)
	if phone() and cam then local bm = bella(); local d = bm and (bm:GetPivot().Position - cam.CFrame.Position).Magnitude or 8; base = cam.CFrame * CFrame.new(0, -0.9, -math.max(3.5, d - 2.5)) end   -- a phone: dead centre, just in front of Bella (Oct 9)
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG6 ABORT - find " .. i .. " not found (already patched?); nothing changed. Source is " .. #s.Source .. " chars") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG6 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG6 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass6"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG6 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass6", before, #s.Source))
