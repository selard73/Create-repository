-- Rejoin the cat cafe's existing cedar posts and facade corner beams to its roof.
-- Run in stopped Studio Edit on the original place. No new visible geometry.
local cafe = workspace.JapanMap["Outdoor market revision"]["Cat cafe"]
assert(cafe:GetAttribute("RoofSupportJoinVersion") ~= 1, "roof supports already joined")
local facade = cafe["Traditional downtown facade"]

local function extendToRoof(part)
    local oldBottom = part.Position.Y - part.Size.Y / 2
    local oldTop = part.Position.Y + part.Size.Y / 2
    assert(oldTop > 19.85 and oldTop < 19.95, "unexpected support top: " .. part:GetFullName())
    assert(oldBottom >= -0.01 and oldBottom < 10, "unexpected support base: " .. part:GetFullName())
    part:SetAttribute("RoofSupportJoinOriginalSizeY", part.Size.Y)
    part:SetAttribute("RoofSupportJoinOriginalCenterY", part.Position.Y)
    local newTop = 20.25
    part.Size = Vector3.new(part.Size.X, newTop - oldBottom, part.Size.Z)
    part.CFrame = part.CFrame + Vector3.new(0, (newTop + oldBottom) / 2 - part.Position.Y, 0)
end

local posts = 0
for _, child in ipairs(cafe:GetChildren()) do
    if child:IsA("BasePart") and child.Name == "Cedar corner post" then
        extendToRoof(child)
        posts += 1
    end
end
assert(posts == 4, "expected four cedar corner posts")

local beams = 0
for _, child in ipairs(facade:GetChildren()) do
    if child:IsA("BasePart") and child.Name == "Timber corner beam" then
        extendToRoof(child)
        beams += 1
    end
end
assert(beams == 2, "expected two facade corner beams")

cafe:SetAttribute("RoofSupportJoinVersion", 1)
print("QQ CAFE ROOF SUPPORTS1: four cedar corner posts and two matching front beams extended from top Y19.90 to Y20.25; bases and all other cafe geometry unchanged")
