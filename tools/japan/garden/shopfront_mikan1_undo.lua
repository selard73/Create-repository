-- Targeted rollback of shopfront_mikan1. Authorized by Shannon on 2026-10-17.
-- Restores only Mikan's 16 retired original awning parts. Archives only its 11 added front pieces.
-- Does not publish, touch DataStores, move the camera, or modify another shop.
local SS = game:GetService("ServerStorage")
local J = assert(workspace:FindFirstChild("JapanMap"), "JapanMap missing")
local market = assert(J:FindFirstChild("Outdoor market revision"), "Market missing")
local shop = assert(market:FindFirstChild("Mikan greengrocer"), "Mikan missing")
local originalAwning = assert(shop:FindFirstChild("Weathered cloth awning"), "Original awning container missing")
local hb = assert(SS:FindFirstChild("HudBackup"), "HudBackup missing")
local bak = assert(hb:FindFirstChild("MikanFrontReplaced"), "MikanFrontReplaced missing")
local fronts = J:FindFirstChild("ShopFronts")
local added = fronts and fronts:FindFirstChild("Mikan")
local expected = {["Canvas panel"]=13, ["Awning bracket"]=2, ["Awning front rail"]=1}
local function counts(parent)
    local count = {}
    for _, p in ipairs(parent:GetChildren()) do
        if expected[p.Name] then count[p.Name] = (count[p.Name] or 0) + 1 end
    end
    return count
end
if not added and #bak:GetChildren() == 0 then
    local count = counts(originalAwning)
    for name, amount in pairs(expected) do assert(count[name] == amount, "Incomplete prior rollback: "..name) end
    print("QQ MIKANFRONT1_UNDO ALREADY DONE: Mikan additions absent; all 16 original awning parts restored")
    return
end
assert(added, "Added Mikan folder missing while originals remain in backup; inspect first")
assert(#added:GetChildren() == 11, "Unexpected addition count; inspect first")
assert(#bak:GetChildren() == 16, "Expected all 16 original parts; inspect first")
local existing = counts(originalAwning)
for name in pairs(expected) do assert(not existing[name], "Original awning already has "..name.."; inspect first") end
local items, observed = {}, {}
for _, p in ipairs(bak:GetChildren()) do
    assert(p:IsA("BasePart") and expected[p.Name], "Unexpected backup item: "..p.Name)
    assert(p:GetAttribute("MikanWasIn") == originalAwning:GetFullName(), "Unexpected restore destination: "..p.Name)
    observed[p.Name] = (observed[p.Name] or 0) + 1
    table.insert(items, {part=p, cf=p.CFrame, size=p.Size, origin=p:GetAttribute("MikanWasIn")})
end
for name, amount in pairs(expected) do assert(observed[name] == amount, "Wrong original count: "..name) end
-- Snapshot all existing Japan instances outside the rejected front before touching anything.
local protected = {}
for i, v in ipairs(J:GetDescendants()) do
    if v ~= added and not v:IsDescendantOf(added) then
        local record = {instance=v, parent=v.Parent, name=v.Name}
        if v:IsA("BasePart") then
            record.cf=v.CFrame; record.size=v.Size; record.color=v.Color; record.material=v.Material
            record.transparency=v.Transparency; record.anchored=v.Anchored
            record.collide=v.CanCollide; record.touch=v.CanTouch; record.query=v.CanQuery
        end
        table.insert(protected, record)
    end
    if i % 1000 == 0 then task.wait() end
end
local backs = assert(J:FindFirstChild("ShopBacks"), "ShopBacks missing before rollback")
local backPieces, backDescendants = #backs:GetChildren(), #backs:GetDescendants()
local shopBefore = #shop:GetDescendants()
local archiveName = "MikanFrontRejected_20261017"
if hb:FindFirstChild(archiveName) then archiveName = archiveName .. "_" .. tostring(os.time()) end
assert(not hb:FindFirstChild(archiveName), "Archive collision")
local history = game:GetService("ChangeHistoryService")
pcall(function() history:SetWaypoint("Before targeted Mikan front rollback") end)
local archive = Instance.new("Folder")
archive.Name = archiveName
archive.Parent = hb
local ok, failure = pcall(function()
    added.Parent = archive
    for _, item in ipairs(items) do
        item.part.Parent = originalAwning
        item.part:SetAttribute("MikanWasIn", nil)
    end
    assert(not fronts:FindFirstChild("Mikan"), "Added front still in map")
    assert(#bak:GetChildren() == 0, "Original parts remain in backup")
    assert(#shop:GetDescendants() == shopBefore + 16, "Unexpected Mikan count")
    for _, item in ipairs(items) do
        assert(item.part.Parent == originalAwning and item.part.CFrame == item.cf and item.part.Size == item.size, "Original transform changed")
    end
    for _, r in ipairs(protected) do
        local v = r.instance
        assert(v.Parent == r.parent and v.Name == r.name, "Protected instance changed: "..r.name)
        if v:IsA("BasePart") then
            assert(v.CFrame == r.cf and v.Size == r.size and v.Color == r.color and v.Material == r.material
                and v.Transparency == r.transparency and v.Anchored == r.anchored
                and v.CanCollide == r.collide and v.CanTouch == r.touch and v.CanQuery == r.query,
                "Protected part changed: "..v:GetFullName())
        end
    end
    assert(#backs:GetChildren() == backPieces and #backs:GetDescendants() == backDescendants, "ShopBacks changed")
end)
if not ok then
    for _, item in ipairs(items) do item.part.Parent=bak; item.part:SetAttribute("MikanWasIn", item.origin) end
    added.Parent=fronts
    archive:Destroy()
    error("Mikan rollback aborted and reverted: "..tostring(failure))
end
pcall(function() history:SetWaypoint("After targeted Mikan front rollback") end)
print("QQ MIKANFRONT1_UNDO DONE: 11 added front pieces removed from JapanMap.ShopFronts.Mikan -> ServerStorage.HudBackup."..archiveName..".Mikan")
print("QQ MIKANFRONT1_UNDO RESTORED: 13 Canvas panels, 2 Awning brackets, 1 Awning front rail to Mikan greengrocer.Weathered cloth awning; original transforms preserved")
print(string.format("QQ MIKANFRONT1_UNDO VERIFIED: %d existing Japan instances outside the rejected front unchanged; ShopBacks %d pieces / %d descendants unchanged", #protected, backPieces, backDescendants))
print("QQ MIKANFRONT1_UNDO STATUS: Edit only; not published; no replacement front installed")
