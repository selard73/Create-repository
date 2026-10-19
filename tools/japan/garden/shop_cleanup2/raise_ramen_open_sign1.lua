-- Restore the original red ramen OPEN sign above the side entry.
-- Visual edit installed and inspected in Studio Oct 18/19 2026.
local Run = game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId == 117372258657114, "Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or RAMEN_OPEN_RAISED1_ALLOW_EDIT == true, "Edit installation not enabled")

local shop = workspace.JapanMap["Outdoor market revision"]["Ramen kitchen"]
local backup = game:GetService("ServerStorage").HudBackup:FindFirstChild("RamenOpenSign2")
assert(backup and shop:GetAttribute("EntranceSignVersion") == "door_pending", "Ramen sign state changed")
local sign = backup:FindFirstChild("Side entrance sign")
assert(sign and sign:IsA("BasePart") and (sign.Position - Vector3.new(5987.819824, 5.95, 27)).Magnitude < .05,
    "Original red sign missing or moved")
assert(not shop:FindFirstChild("Side entrance sign"), "Live sign already present")
local surface = sign:FindFirstChildOfClass("SurfaceGui")
local label = surface and surface:FindFirstChildWhichIsA("TextLabel", true)
assert(label and label.Text == "営業中\nOPEN", "Original lettering changed")

local original = sign:Clone()
original.Name = "SideEntranceSignBeforeRaised1"
original.Parent = backup
sign:SetAttribute("OriginalEntranceCFrame", sign.CFrame)
sign:SetAttribute("OriginalEntranceSize", sign.Size)
sign:SetAttribute("OriginalEntranceText", label.Text)

-- Lintel underside is Y8.375; this sign overlaps the beam while its bottom
-- stays 6.71 studs above the Y1.04 shop floor, clear of a 6.3-stud avatar.
sign.Size = Vector3.new(3.2, 1.10, .13)
sign.CFrame = (sign.CFrame - sign.Position) + Vector3.new(5987.82, 8.30, 26.95)
sign.CanCollide = false
label.Text = "営業中   OPEN"
label.TextScaled = true
sign.Parent = shop
shop:SetAttribute("EntranceSignVersion", "raised_red1")
print("QQ RAMEN OPEN SIGN RAISED1: original red bilingual sign mounted on the side-entry lintel, bottom 7.75; clear of player heads and lantern; rejected wooden plaque stays in backup")
