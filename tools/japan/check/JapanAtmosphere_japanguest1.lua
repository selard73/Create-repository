-- Local-only effects, scoped to Japan. Restores the existing atmosphere on exit.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local player=Players.LocalPlayer
local origin=Vector3.new(6000,0,0)
local map=workspace:WaitForChild('JapanMap',60)
if not map then return end
local active=false
-- JAPANFIX1_20261015: the baseline is what the game loaded with (the look pass), taken ONCE here - never at enter(), which used to come
-- after the balloon's reveal had already changed fog, atmosphere and clouds; the Clouds are part of it now
local clouds=workspace.Terrain:FindFirstChildOfClass('Clouds')
local saved={ClockTime=Lighting.ClockTime,FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,Atmospheres={},Clouds=clouds and {Cover=clouds.Cover,Density=clouds.Density,Color=clouds.Color} or nil}
for _,a in ipairs(Lighting:GetChildren()) do if a:IsA('Atmosphere') then saved.Atmospheres[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare} end end
local function enter()
 for a in pairs(saved.Atmospheres) do if a.Parent then a.Density=.08;a.Haze=0;a.Glare=.08 end end
 Lighting.ClockTime=15.1;Lighting.FogEnd=100000;Lighting.FogStart=99999
 if clouds and clouds.Parent then clouds.Cover=.08;clouds.Density=.1;clouds.Color=Color3.new(1,1,1) end
end
local function leave()
 Lighting.ClockTime=saved.ClockTime;Lighting.FogEnd=saved.FogEnd;Lighting.FogStart=saved.FogStart
 for a,values in pairs(saved.Atmospheres) do if a.Parent then for k,v in pairs(values) do a[k]=v end end end
 if clouds and clouds.Parent and saved.Clouds then for k,v in pairs(saved.Clouds) do clouds[k]=v end end
end
local wheel,base=nil,nil   -- (JAPANFIX1: the lighting no longer waits for the wheel to stream in)
task.spawn(function() local th=map:WaitForChild('TeaHills',60); wheel=th and th:WaitForChild('Waterwheel',600) or nil; if wheel then base=wheel:GetPivot() end end)
local accumulator=0
RunService.Heartbeat:Connect(function(dt)
 accumulator+=dt
 if accumulator<.05 then return end
 accumulator=0
 local hrp=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local inside=hrp and (player.UserId==9611145467 or player:GetAttribute('JapanPreviewAllowed')==true --[[JAPANGUEST1_20261015]]) and not player:GetAttribute("JapanPreviewInFlight") and math.abs(hrp.Position.X-origin.X)<1300 and hrp.Position.Z>-1400 and hrp.Position.Z<850
 if inside and not active then active=true;enter() elseif not inside and active then active=false;leave() end
 if active and wheel and base then wheel:PivotTo(base*CFrame.Angles(os.clock()*.22,0,0)) end
end)
script.Destroying:Connect(leave)

