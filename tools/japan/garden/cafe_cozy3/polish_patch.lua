-- The same small appearance/audio patch is used by the full staged installer and Play refresh.
local floorCount=0
local grainCount=0
local floorTones={CI2_Floor_Oak={103,76,55},CI2_Floor_OakLight={106,78,57},CI2_Floor_OakDark={100,74,53}}
for _,p in ipairs(room.Architecture:GetChildren())do
 if p:IsA("MeshPart")and(p.Name:find("CI2_Floor",1,true)==1 or p.Name=="CI2_VestibuleFloor_Oak")then
  p.Material=Enum.Material.SmoothPlastic;p.MaterialVariant="";p.Color=Color3.fromRGB(table.unpack(floorTones[p.Name]or{103,76,55}));floorCount+=1
  -- Blend the building's existing cedar image over the boards at low contrast.
  -- The hidden floor base needs no texture; no extra geometry or uploaded assets.
  if p.Name~="CI2_FloorBase_OakDark"then
   local grain=p:FindFirstChild("CafeSoftWoodGrain")or Instance.new("Texture")
   assert(grain:IsA("Texture"),"Unexpected cafe grain instance")
   grain.Name="CafeSoftWoodGrain";grain.Texture="rbxassetid://114296702911787";grain.Face=Enum.NormalId.Top
   grain.StudsPerTileU=9;grain.StudsPerTileV=9;grain.OffsetStudsU=0;grain.OffsetStudsV=0
   grain.Color3=Color3.fromRGB(125,102,80);grain.Transparency=.65;grain.Parent=p;grainCount+=1
  end
 end
end
assert(floorCount==5,"Unexpected cafe floor mesh count")
assert(grainCount==4,"Expected grain on four visible floor meshes")
room:SetAttribute("CafeFloorFinish","rustic_walnut3")
print("QQ CAFECOZY3 FLOOR: five dark walnut floor meshes; subtle board tones and four soft cedar-grain textures; existing plank geometry retained")
local steamCount=0
for _,root in ipairs({room,display})do for _,v in ipairs(root:GetDescendants())do
 if v:IsA("ParticleEmitter")and v.Name=="GentleTeaSteam"then
  v.Rate=1.2;v.Lifetime=NumberRange.new(.9,1.25);v.Speed=NumberRange.new(.18,.27);v.Acceleration=Vector3.new(0,.04,0)
  v.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.055),NumberSequenceKeypoint.new(.45,.14),NumberSequenceKeypoint.new(1,.23)})
  v.Color=ColorSequence.new(Color3.fromRGB(250,247,240))
  v.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.93),NumberSequenceKeypoint.new(1,1)})
  v.LightInfluence=0;v.LightEmission=1;steamCount+=1
 end
end end
assert(steamCount==10,"Expected six interior mugs and four street-display mugs")
bridge:SetAttribute("DoorSound","rbxassetid://131845870598154");bridge:SetAttribute("DoorVolume",.6)
room:SetAttribute("CafePolishVersion","quiet_floor_steam_bell1")
print("QQ CAFECOZY3 POLISH: dark rustic walnut floor; ten steam emitters reduced to small pale wisps; seven cats retained")
print("QQ CAFECOZY3 BELL: French shop sound 131845870598154 at volume .6; one ring per successful entry or exit")
