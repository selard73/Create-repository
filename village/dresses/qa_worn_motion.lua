local Run=game:GetService('RunService');assert(Run:IsStudio() and Run:IsClient())
local p=game.Players.LocalPlayer;local c=p.Character;assert(c.WornDress and not c:FindFirstChild('DressPreview'))
assert(not p.PlayerGui.DressShopGui.Enabled)
local count=0
for _,name in ipairs({'walk','run','jump','sit'})do
 local a=c.Animate:FindFirstChild(name):FindFirstChildWhichIsA('Animation')
 local t=c.Humanoid.Animator:LoadAnimation(a);t.Priority=Enum.AnimationPriority.Action;t.Looped=true;t:Play()
 for i=1,45 do Run.RenderStepped:Wait();for _,n in ipairs({'LeftUpperLeg','RightUpperLeg','LeftLowerLeg','RightLowerLeg','LeftFoot','RightFoot'})do
  assert(c[n].Transparency==1,'worn dress exposed '..n);count+=1
 end end
 t:Stop();t:Destroy()
end
warn('QQ WORN MOTION PASS: bought dress; preview removed; mirror closed; walk/run/jump/sit; '..count..' hidden leg/foot samples')
