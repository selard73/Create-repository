-- Preview on Play Server. Edit only after Shannon approves the pictures.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and SUSHI_SIGN1_ALLOW_EDIT==true),"Preview first; Edit requires approval")
local J=workspace.JapanMap;local shop=J["Outdoor market revision"]["Sushi bar"]
local sign=assert(shop:FindFirstChild("Handwritten shop sign"))
assert(sign:IsA("BasePart") and not sign:GetAttribute("SushiSignPlacementVersion"),"Inspect sign first")
assert((sign.Position-Vector3.new(5984.5,9.44999981,-29.59000015)).Magnitude<.001,"Unexpected sign position")
local label=assert(sign:FindFirstChildWhichIsA("TextLabel",true));assert(label.Text=="寿司  Sushi bar")
local old=sign.CFrame
local destination=CFrame.new(5984.32,9.85,-25)*old.Rotation
local before={};for i,p in J:GetDescendants()do
 if p:IsA("BasePart")then before[p]={parent=p.Parent,cf=p.CFrame,size=p.Size,color=p.Color,mat=p.Material,alpha=p.Transparency,collide=p.CanCollide}end
 if i%1000==0 then task.wait()end
end
local backup
if not Run:IsRunning()then
 assert(not game.ServerStorage.HudBackup:FindFirstChild("SushiSign_pre_center1"),"Backup exists")
 backup=sign:Clone();backup.Name="SushiSign_pre_center1";backup.Parent=game.ServerStorage.HudBackup
 game.ChangeHistoryService:SetWaypoint("Before sushi sign placement")
end
local ok,err=pcall(function()
 sign.CFrame=destination
 for p,r in before do assert(p.Parent==r.parent and p.Size==r.size and p.Color==r.color and p.Material==r.mat and p.Transparency==r.alpha and p.CanCollide==r.collide,"Unrelated part change");assert(p.CFrame==(p==sign and destination or r.cf),"Unrelated movement")end
 assert(label.Text=="寿司  Sushi bar")
 sign:SetAttribute("SushiSignWasCFrame",old);sign:SetAttribute("SushiSignPlacementVersion","center1")
end)
if not ok then sign.CFrame=old;if backup then backup:Destroy()end;error(err)end
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After sushi sign placement")end
print("QQ SUSHI SIGN1: existing sign centered atZ-25, raised0.40 and set against front beam; wording, size and materials retained")
print("QQ SUSHI SIGN1 PRESERVED: all other Japan parts and the approved sushi interior unchanged")
print("QQ SUSHI SIGN1 STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")
