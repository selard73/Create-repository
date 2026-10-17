-- Cafe-local reflection control. Capture on entry and restore on exit/cleanup.
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local player=Players.LocalPlayer
local previous=nil
local function update()
 if player:GetAttribute("InCatCafeInterior")==true then
  if previous==nil then previous=Lighting.EnvironmentSpecularScale end
  Lighting.EnvironmentSpecularScale=.12
 elseif previous~=nil then
  Lighting.EnvironmentSpecularScale=previous;previous=nil
 end
end
local connection=player:GetAttributeChangedSignal("InCatCafeInterior"):Connect(update)
script.Destroying:Connect(function()
 connection:Disconnect()
 if previous~=nil then Lighting.EnvironmentSpecularScale=previous;previous=nil end
end)
update()
