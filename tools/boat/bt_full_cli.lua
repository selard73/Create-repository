-- bt_full v1 (PLAY, CLIENT, test only): one run = the whole end-game path for this client: next to the Sky Diving Squirrel
-- and hold Talk (the chute), to the jetty and take the boat, then the boat 12 studs above the brink. Then hold W.
local plr = game.Players.LocalPlayer
local function char() return plr.Character end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
warn(string.format("QQ BF found %s/%s/%s SquirrelsFound=%s", tostring(plr:GetAttribute("Found_forest")), tostring(plr:GetAttribute("Found_village")), tostring(plr:GetAttribute("Found_domaine")), tostring(plr:GetAttribute("SquirrelsFound"))))
-- 1. the squirrel
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("QQ BF no squirrel"); return end
local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
char():PivotTo(CFrame.lookAt(mesh.Position + Vector3.new(0, 1.5, 5), mesh.Position))
task.wait(1.2)
local sp = mesh:FindFirstChild("ChutePrompt")
if not sp then warn("QQ BF no ChutePrompt"); return end
sp.MaxActivationDistance = 30
sp:InputHoldBegin(); task.wait(0.5); sp:InputHoldEnd()
task.wait(2)
warn(string.format("QQ BF squirrel: '%s'; pack=%s HasChute=%s", sp.ActionText, tostring(char():FindFirstChild("ChutePack") ~= nil), tostring(plr:GetAttribute("HasChute"))))
-- 2. the jetty
h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
char():PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(1.0)
local prompt = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
prompt.RequiresLineOfSight = false; prompt.MaxActivationDistance = 30
task.wait(0.5)
prompt:InputHoldBegin(); task.wait(0.7); prompt:InputHoldEnd()
task.wait(1.5)
h = hum()
local m = workspace.Boat:FindFirstChild("Boat_" .. plr.UserId)
warn(string.format("QQ BF jetty: seat=%s boat=%s", tostring(h and h.SeatPart and h.SeatPart.Name), tostring(m ~= nil)))
if not m then return end
-- 3. the brink
task.wait(0.5)
local hull = m.PrimaryPart
m:PivotTo(CFrame.new(184.3, hull.Position.Y, -534.0))
task.wait(0.3)
warn(string.format("QQ BF boat at (%.1f, %.1f, %.1f) falling=%s - hold W now", hull.Position.X, hull.Position.Y, hull.Position.Z, tostring(m:GetAttribute("Falling"))))
