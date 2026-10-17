-- The same small appearance/audio patch is used by the full staged installer and Play refresh.
local floorCount=0
for _,p in ipairs(room.Architecture:GetChildren())do
 if p:IsA("MeshPart")and(p.Name:find("CI2_Floor",1,true)==1 or p.Name=="CI2_VestibuleFloor_Oak")then
  p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromRGB(187,163,132);floorCount+=1
 end
end
assert(floorCount==5,"Unexpected cafe floor mesh count")
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
print("QQ CAFECOZY3 POLISH: five floor meshes in uniform matte honey oak; ten steam emitters reduced to small pale wisps; seven cats retained")
print("QQ CAFECOZY3 BELL: French shop sound 131845870598154 at volume .6; one ring per successful entry or exit")
