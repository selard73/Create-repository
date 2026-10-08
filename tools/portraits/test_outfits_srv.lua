-- v21 (PLAY, SERVER view, Studio only, API OFF): outfit test - live gallery list in an in-memory store, then shop clothes
-- A (magician, aviators, top hat) for sitting 1 and B (sage petal dress, cat-eyes, pearls, boater) for sitting 2
local RS = game:GetService("RunService")
if not RS:IsServer() or not RS:IsRunning() or not RS:IsStudio() then warn("QQ P18 ABORT - Play, server view") return end
local H = game:GetService("HttpService")
local p = game.Players:GetPlayers()[1]
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local total = {}
for _, e in ipairs(Registry.squirrels) do total[e.map] = (total[e.map] or 0) + 1 end
p:SetAttribute("Found_forest", total.forest); p:SetAttribute("Found_village", total.village)
p:SetAttribute("Acorns", 1000)
local appearanceNumbers={"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg","Face","Shirt","Pants","GraphicTShirt","HeadScale","HeightScale","WidthScale","DepthScale","BodyTypeScale","ProportionScale","MoodAnimation","StaticFacialAnimation"}
local appearanceColors={"HeadColor","TorsoColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor"}
local function saveDescription(desc)
 local data={version=1,properties={},colors={},accessories={}}
 for _,key in ipairs(appearanceNumbers)do
  local ok,value=pcall(function()return desc[key]end)
  if ok and type(value)=="number"then data.properties[key]=value end
 end
 for _,key in ipairs(appearanceColors)do local c=desc[key];data.colors[key]={c.R,c.G,c.B}end
 for _,accessory in ipairs(desc:GetAccessories(true))do
  local copy={}
  for key,value in pairs(accessory)do
   if typeof(value)=="EnumItem"then copy[key]={enum=value.Name}
   elseif typeof(value)=="Vector3"then copy[key]={vector={value.X,value.Y,value.Z}}
   else copy[key]=value end
  end
  data.accessories[#data.accessories+1]=copy
 end
 return data
end
local selbell = {id = p.UserId, name = p.DisplayName, t = 1790715558, receipt = "525d3c31-cacd-4761-bb12-4f7ec172d46a",
	look = {hat = "bowler_1", boutique = "soiree_2,cateye_3,pearls_1"}, rig = "R15",
	appearance = saveDescription(p.Character:FindFirstChildOfClass("Humanoid"):GetAppliedDescription())}
local poodle = {id = 8461502241, name = "poodleses4", t = 1790445897}
local fixture = game.ServerStorage:FindFirstChild("PortraitReliabilityFixture") or Instance.new("Folder")
fixture.Name = "PortraitReliabilityFixture"; fixture:SetAttribute("Data", H:JSONEncode({latest = {selbell, poodle}})); fixture.Parent = game.ServerStorage
local mock = [==[
assert(game:GetService('RunService'):IsStudio())
local fixture=assert(game.ServerStorage:FindFirstChild('PortraitReliabilityFixture'))
local H=game:GetService('HttpService')
store={GetAsync=function(_,key)return H:JSONDecode(fixture:GetAttribute('Data'))[key]end,UpdateAsync=function(_,key,fn)
 local data=H:JSONDecode(fixture:GetAttribute('Data'));data[key]=fn(data[key]);fixture:SetAttribute('Data',H:JSONEncode(data));return H:JSONDecode(fixture:GetAttribute('Data'))[key]
end}
]==]
local g = workspace.PortraitGallery
local src = g.PortraitServer.Source
if not src:find("PER_SITTER", 1, true) then warn("QQ P18 ABORT - this Play copy has not got the option C server") return end
local marker = 'local portraitCrops={["9611145467:1790618485"]="waist"}'
local _, b = src:find(marker, 1, true)
if not b then warn("QQ P18 ABORT - marker not found") return end
g.PortraitServer.Enabled = false
game.ReplicatedStorage.PortraitGalleryModels:ClearAllChildren()
g.PortraitServer.Source = src:sub(1, b) .. "\n" .. mock .. src:sub(b + 1)
g.PortraitServer.Enabled = true
p.Character:PivotTo(CFrame.lookAt(Vector3.new(197, 6, -24), Vector3.new(190, 5, -12)))
-- the shops' own flags: Item_dress_/Item_hat_ = owned, Item_dresswear_/Item_hatwear_ = worn (the shops redress on change)
local AI = game.ReplicatedStorage.AwardItems
local Cat = require(game.ReplicatedStorage.DressKit.Catalogue)
local function put(name, want)
	local n = tonumber(p:GetAttribute("Item_" .. name)) or 0
	if want > 0 and n <= 0 then AI:Fire(p, name, 1) elseif want <= 0 and n > 0 then AI:Fire(p, name, -n) end
end
local function outfit(o, prev)
	if prev then
		for _, id in ipairs(prev.dress) do put("dresswear_" .. id, 0) end
		put("hatwear_" .. prev.hat, 0)
	end
	for _, id in ipairs(o.dress) do put("dress_" .. id, 1); put("dresswear_" .. id, 1) end
	put("hat_" .. o.hat, 1); put("hatwear_" .. o.hat, 1)
end
local function wearing(o)
	local char = p.Character
	if not char then return false end
	for _, id in ipairs(o.dress) do
		local m = char:FindFirstChild(Cat.models[Cat.slot(id)])
		if not m or m:GetAttribute("DressId") ~= id then return false end
	end
	local h = char:FindFirstChild("WornHat")
	return h ~= nil and h:GetAttribute("HatId") == o.hat
end
local A = {dress = {"moonmagician_2", "aviator_1"}, hat = "top_1"}
local B = {dress = {"jardin_3", "cateye_3", "pearls_1"}, hat = "boater_1"}
local function report(tag)
	local data = H:JSONDecode(fixture:GetAttribute("Data"))
	for i, e in ipairs(data.latest or {}) do
		warn("QQ P18 " .. tag .. " list " .. i .. ": " .. tostring(e.name) .. " v" .. tostring(e.variant) .. " look " .. (e.look and H:JSONEncode(e.look) or "-"))
	end
	for _, m in ipairs(game.ReplicatedStorage.PortraitGalleryModels:GetChildren()) do
		local worn = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:GetAttribute("DressId") and d:IsA("Model") then worn[#worn + 1] = d.Name .. "=" .. d:GetAttribute("DressId") end
			if d.Name == "WornHat" and d:GetAttribute("HatId") then worn[#worn + 1] = "WornHat=" .. d:GetAttribute("HatId") end
		end
		warn("QQ P18 " .. tag .. " model " .. m.Name:sub(10, 40) .. ": " .. table.concat(worn, " "))
	end
end
task.spawn(function()
	outfit(A)
	local t0 = os.clock(); repeat task.wait(0.3) until wearing(A) or os.clock() - t0 > 20
	warn("QQ P18 outfit A worn: " .. tostring(wearing(A)))
	p:SetAttribute("QQOutfit", "A")
	repeat task.wait(0.5) until (tonumber(p:GetAttribute("Item_portrait")) or 0) >= 1 and not p:GetAttribute("PortraitSitting") and not g:GetAttribute("SessionUser")
	task.wait(5)
	report("after 1")
	outfit(B, A)
	t0 = os.clock(); repeat task.wait(0.3) until wearing(B) or os.clock() - t0 > 20
	warn("QQ P18 outfit B worn: " .. tostring(wearing(B)))
	p:SetAttribute("QQOutfit", "B")
	repeat task.wait(0.5) until (tonumber(p:GetAttribute("Item_portrait")) or 0) >= 2 and not p:GetAttribute("PortraitSitting") and not g:GetAttribute("SessionUser")
	task.wait(5)
	report("after 2")
	warn("QQ P18 DONE")
end)
warn("QQ P18 v21 restarted PortraitServer (option C) with the live list; dressing in outfit A")
