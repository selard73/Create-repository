-- bt_v22 v1 (PLAY, CLIENT, test only): the squirrel (new bubbles; frames meanwhile), the jetty + boat (music check), then
-- the boat moved to the gorge bend where the river leaves the old watchdog box (x 144, z -320); hold W for 8 s and the
-- script reports 9 s later whether the boat survived the bend.
local plr = game.Players.LocalPlayer
local SoundService = game:GetService("SoundService")
local function char() return plr.Character end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function musicState()
	local out = {}
	for _, s in ipairs(SoundService:GetChildren()) do
		if s:IsA("Sound") then out[#out + 1] = string.format("%s playing=%s vol=%.2f", s.Name, tostring(s.IsPlaying), s.Volume) end
	end
	return #out > 0 and table.concat(out, "; ") or "no sounds in SoundService"
end
warn("QQ V22 found " .. tostring(plr:GetAttribute("SquirrelsFound")) .. "; music before: " .. musicState())
-- 1. the squirrel
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("QQ V22 no squirrel"); return end
local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
char():PivotTo(CFrame.lookAt(mesh.Position + Vector3.new(0, 1.5, 5), mesh.Position))
task.wait(1.2)
local sp = mesh:FindFirstChild("ChutePrompt")
if not sp then warn("QQ V22 no ChutePrompt"); return end
sp.MaxActivationDistance = 30
sp:InputHoldBegin(); task.wait(0.5); sp:InputHoldEnd()
task.wait(1.0)
local pg = plr:FindFirstChildOfClass("PlayerGui")
local bb = pg and pg:FindFirstChild("SquirrelBubble")
warn(string.format("QQ V22 squirrel: bubble=%s size=%s prompt.Enabled=%s pack=%s HasChute=%s", tostring(bb ~= nil), bb and tostring(bb.AbsoluteSize) or "-", tostring(sp.Enabled), tostring(char():FindFirstChild("ChutePack") ~= nil), tostring(plr:GetAttribute("HasChute"))))
task.wait(10)   -- the three bubbles play; frames are taken meanwhile
warn("QQ V22 after speech: prompt.Enabled=" .. tostring(sp.Enabled))
-- 2. the jetty
h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
char():PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(1.0)
local prompt = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
prompt.RequiresLineOfSight = false; prompt.MaxActivationDistance = 30
task.wait(0.5)
prompt:InputHoldBegin(); task.wait(0.7); prompt:InputHoldEnd()
task.wait(2.5)
h = hum()
local m = workspace.Boat:FindFirstChild("Boat_" .. plr.UserId)
warn(string.format("QQ V22 jetty: seat=%s boat=%s NoMusic=%s; music now: %s", tostring(h and h.SeatPart and h.SeatPart.Name), tostring(m ~= nil), tostring(char():GetAttribute("NoMusic")), musicState()))
if not m then return end
-- 3. the bend
task.wait(0.5)
local hull = m.PrimaryPart
m:PivotTo(CFrame.new(144.1, hull.Position.Y, -320.0))     -- identity = bow downstream (-z); the river swings out to x 110 ahead
task.wait(0.3)
warn(string.format("QQ V22 boat at (%.1f, %.1f, %.1f) - hold W now", hull.Position.X, hull.Position.Y, hull.Position.Z))
task.delay(9, function()
	local m2 = workspace.Boat:FindFirstChild("Boat_" .. plr.UserId)
	local hrp = char() and char():FindFirstChild("HumanoidRootPart")
	warn(string.format("QQ V22 after 9 s: boat=%s at %s; player at %s; music: %s", tostring(m2 ~= nil), m2 and tostring(m2.PrimaryPart.Position) or "-", hrp and tostring(hrp.Position) or "?", musicState()))
end)
