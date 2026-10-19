-- Extend the two cat cafe chair back slats to meet their cushions.
-- Installed in Studio Edit Oct 18 2026; new MeshParts are the existing chair rail mesh.
local Run = game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId == 117372258657114, "Wrong place")
assert((Run:IsRunning() and Run:IsServer()) or CAFE_CHAIR_SLATS1_ALLOW_EDIT == true, "Edit installation not enabled")

local cafe = workspace.JapanMap.ShopFronts:FindFirstChild("CatCafeInterior")
assert(cafe, "CatCafeInterior missing")
local furniture = cafe:FindFirstChild("Furniture")
assert(furniture, "Cafe furniture missing")
assert(furniture:GetAttribute("ChairBackSlatsVersion") == nil, "Chair slats already extended")

local checked = {}
for i = 0, 1 do
    local prefix = "C1_Chair" .. i .. "_"
    local rail = furniture:FindFirstChild(prefix .. "OakLight")
    local frame = furniture:FindFirstChild(prefix .. "Oak")
    local cushion = furniture:FindFirstChild(prefix .. (i == 0 and "Indigo" or "Rose"))
    assert(rail and rail:IsA("MeshPart") and frame and frame:IsA("MeshPart") and cushion, "Chair source missing")
    assert(math.abs(rail.Position.Y - 1203.46) < .03 and math.abs(cushion.Position.Y - 1201.84) < .03, "Chair moved; inspect before patching")
    for j = 1, 3 do
        assert(not furniture:FindFirstChild(prefix .. "LowerBackSlat_" .. j), "A slat extension already exists")
    end
    checked[i] = {rail = rail, frame = frame}
end

for i = 0, 1 do
    local rail, frame = checked[i].rail, checked[i].frame
    for j, offset in ipairs({-.55, 0, .55}) do
        local slat = rail:Clone()
        slat.Name = "C1_Chair" .. i .. "_LowerBackSlat_" .. j
        slat.Size = Vector3.new(.11, .28, .12)
        slat.CFrame = (rail.CFrame - rail.Position) + Vector3.new(rail.Position.X + .03, 1202.095, rail.Position.Z + offset)
        slat.Color = frame.Color
        slat.Material = frame.Material
        slat.CanCollide = false
        slat.CanTouch = false
        slat.CanQuery = false
        slat.Anchored = true
        slat:SetAttribute("ChairBackSlatExtension", true)
        slat.Parent = furniture
    end
end
furniture:SetAttribute("ChairBackSlatsVersion", "seat1")
print("QQ CAFE CHAIR SLATS1: six real wood mesh extensions join the back slats to the cushions on both café chairs; chairs and seats otherwise unchanged")
