-- Local-only effects, scoped to Japan. Restores the existing atmosphere on exit.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local player=Players.LocalPlayer
local origin=Vector3.new(6000,0,0)
local map=workspace:WaitForChild('JapanMap',60)
if not map then return end
local active=false
local saved={}
local function enter()
 saved.ClockTime=Lighting.ClockTime;saved.FogEnd=Lighting.FogEnd;saved.FogStart=Lighting.FogStart
 saved.Atmospheres={}
 for _,a in ipairs(Lighting:GetChildren()) do if a:IsA('Atmosphere') then saved.Atmospheres[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare};a.Density=.08;a.Haze=0;a.Glare=.08 end end
 Lighting.ClockTime=15.1;Lighting.FogEnd=100000;Lighting.FogStart=99999
end
local function leave()
 if not saved.ClockTime then return end
 Lighting.ClockTime=saved.ClockTime;Lighting.FogEnd=saved.FogEnd;Lighting.FogStart=saved.FogStart
 for a,values in pairs(saved.Atmospheres or {}) do if a.Parent then for k,v in pairs(values) do a[k]=v end end end
 saved={}
end
local wheel=map:WaitForChild('TeaHills'):WaitForChild('Waterwheel')
local base=wheel:GetPivot()
local accumulator=0
RunService.Heartbeat:Connect(function(dt)
 accumulator+=dt
 if accumulator<.05 then return end
 accumulator=0
 local hrp=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local inside=hrp and math.abs(hrp.Position.X-origin.X)<1300 and hrp.Position.Z>-1400 and hrp.Position.Z<850
 if inside and not active then active=true;enter() elseif not inside and active then active=false;leave() end
 if active then wheel:PivotTo(base*CFrame.Angles(os.clock()*.22,0,0)) end
end)
script.Destroying:Connect(leave)
