-- v14 (PLAY, SERVER view, Studio only, API OFF): gallery = the live list [SelBell today, poodleses4] in an in-memory store,
-- gates open, 1000 acorns (Studio only, never saved); then every 5 s report the saved list and the easels
local RS = game:GetService("RunService")
if not RS:IsServer() or not RS:IsRunning() or not RS:IsStudio() then warn("QQ P11 ABORT - Play, server view") return end
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
fixture.Name = "PortraitReliabilityFixture"; fixture:SetAttribute("Data", H:JSONEncode({latest = {selbell, poodle}, ["painted_u" .. p.UserId] = 7})); fixture.Parent = game.ServerStorage
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
if not src:find("PER_SITTER", 1, true) then warn("QQ P11 ABORT - this Play copy has not got the option C server") return end
local marker = 'local portraitCrops={["9611145467:1790618485"]="waist"}'
local _, b = src:find(marker, 1, true)
if not b then warn("QQ P11 ABORT - marker not found") return end
g.PortraitServer.Enabled = false
game.ReplicatedStorage.PortraitGalleryModels:ClearAllChildren()
g.PortraitServer.Source = src:sub(1, b) .. "\n" .. mock .. src:sub(b + 1)
g.PortraitServer.Enabled = true
p.Character:PivotTo(CFrame.lookAt(Vector3.new(197, 6, -24), Vector3.new(190, 5, -12)))
warn("QQ P11 v14 restarted PortraitServer (option C) with the live list; acorns " .. tostring(p:GetAttribute("Acorns")))
local last = ""
task.spawn(function()
	for _ = 1, 60 do
		task.wait(5)
		local data = H:JSONDecode(fixture:GetAttribute("Data"))
		local rows = {}
		for i, e in ipairs(data.latest or {}) do rows[#rows + 1] = i .. ":" .. tostring(e.name) .. "/v" .. tostring(e.variant) .. "/" .. tostring(e.receipt or e.t):sub(1, 8) end
		local easels = {}
		for i = 1, 5 do
			local vp = g.Slots["Slot" .. i]:FindFirstChild("Canvas", true).Picture.Portrait3D
			easels[#easels + 1] = i .. "=" .. (vp.Visible and tostring(vp:GetAttribute("GalleryModelKey")):sub(10, 30) or "-")
		end
		local line = "latest [" .. table.concat(rows, "  ") .. "] | easels " .. table.concat(easels, " ") .. " | acorns " .. tostring(p:GetAttribute("Acorns")) .. " portraits " .. tostring(p:GetAttribute("Item_portrait")) .. " painted " .. tostring(data["painted_u" .. p.UserId])
		if line ~= last then warn("QQ P11 " .. line); last = line end
	end
end)
