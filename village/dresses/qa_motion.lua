-- Run in disposable Studio client while trying on a dress.
local Run=game:GetService('RunService');assert(Run:IsStudio() and Run:IsRunning() and Run:IsClient())
local p=game.Players.LocalPlayer;local c=p.Character;assert(c:FindFirstChild('DressPreview'))
local cam=workspace.CurrentCamera;local cf,focus=cam.CFrame,cam.Focus
local checked,misses=0,0
Run:BindToRenderStep('BoutiqueCoverageProbe',Enum.RenderPriority.Last.Value+1,function()
 for _,n in ipairs({'LeftUpperLeg','RightUpperLeg','LeftLowerLeg','RightLowerLeg','LeftFoot','RightFoot'})do
  local o=c:FindFirstChild(n);if o then checked+=1;if o.Transparency<1 and o.LocalTransparencyModifier<1 then misses+=1 end end
 end
end)
for _,name in ipairs({'run','jump','sit'})do
 local a=c.Animate:FindFirstChild(name):FindFirstChildWhichIsA('Animation')
 local track=c.Humanoid.Animator:LoadAnimation(a);track.Priority=Enum.AnimationPriority.Action;track.Looped=true;track:Play()
 -- This exact camera transition exposed all four leg segments before the fix.
 cam.CameraType=Enum.CameraType.Custom;task.wait(.4)
 cam.CameraType=Enum.CameraType.Scriptable;cam.CFrame=cf;cam.Focus=focus
 task.wait(1.5);track:Stop();track:Destroy()
end
Run:UnbindFromRenderStep('BoutiqueCoverageProbe')
assert(checked>300,'insufficient rendered samples')
assert(misses==0,'visible leg/foot samples='..misses..'/'..checked)
warn('QQ MOTION QA PASS: run/jump/sit; three camera resets; '..checked..' covered leg/foot samples; zero visible samples')
-- Leave a bent-knee pose for visual review; it ends automatically.
local track=c.Humanoid.Animator:LoadAnimation(c.Animate.sit.SitAnim);track.Priority=Enum.AnimationPriority.Action;track.Looped=true;track:Play()
task.delay(30,function()track:Stop();track:Destroy()end)
