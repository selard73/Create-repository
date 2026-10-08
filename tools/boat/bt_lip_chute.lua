-- bt_lip_chute v1 (PLAY, SERVER, test only): puts the first player's boat (they must be seated in it) 12 studs upstream of the
-- brink, pointing downstream, so the fall can be tested without the 400-stud drive. With CHUTE = true the player is given
-- the Sky Diving Squirrel find for this play session only (an attribute; nothing is saved with API off).
local CHUTE = true
local plr = game.Players:GetPlayers()[1]
local m = workspace.Boat:FindFirstChild("Boat_" .. plr.UserId)
if not m then warn("QQ BTL no boat for " .. plr.Name); return end
if CHUTE then plr:SetAttribute("FoundIds", (plr:GetAttribute("FoundIds") or "") .. ",parachute_squirrel") end
local hull = m.PrimaryPart
local target = CFrame.new(184.3, hull.Position.Y, -534.0)        -- identity rotation = bow downstream (-z)
m:PivotTo(target)
task.wait(0.3)
warn(string.format("QQ BTL boat at (%.1f, %.1f, %.1f) chute=%s falling=%s", hull.Position.X, hull.Position.Y, hull.Position.Z, tostring(CHUTE), tostring(m:GetAttribute("Falling"))))
