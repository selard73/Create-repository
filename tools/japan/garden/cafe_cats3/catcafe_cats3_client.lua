-- Gentle, stationary cafe-cat idles. The supplied poses are retained; this is not a walking controller.
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local player=Players.LocalPlayer
local root=script.Parent
local cats={}
local function add(model)
 if not model:IsA('Model') or not model:GetAttribute('CafeCatIndex') or cats[model] then return end
 local mesh=model:FindFirstChildWhichIsA('MeshPart',true)
 if not mesh then return end
 local cf=model:GetPivot()
 local prefix=assert(model:GetAttribute("CatBonePrefix"),"Cat bone prefix missing")
 local bones={}
 for _,b in ipairs(mesh:GetDescendants())do if b:IsA('Bone')then
  b.Transform=CFrame.identity
  assert(b.Name:sub(1,#prefix)==prefix,'Unexpected bone prefix')
  bones[b.Name:sub(#prefix+1)]={bone=b,up=b.WorldCFrame:VectorToObjectSpace(cf.UpVector),right=b.WorldCFrame:VectorToObjectSpace(cf.RightVector),forward=b.WorldCFrame:VectorToObjectSpace(cf.ZVector)}
 end end
 if not bones.Head or not bones.Chest then return end
 cats[model]={mesh=mesh,bones=bones,phase=model:GetAttribute('CafeCatIndex')*1.73,active=false}
end
for _,m in ipairs(root:GetChildren())do add(m)end
local added=root.ChildAdded:Connect(function(m)task.defer(add,m)end)
local streamed=root.DescendantAdded:Connect(function(d)
 if d:IsA('Bone')then task.defer(function()local m=d:FindFirstAncestorWhichIsA('Model');if m then add(m)end end)end
end)
local function turn(b,axis,angle)
 if b then b.bone.Transform=CFrame.fromAxisAngle(b[axis],math.rad(angle))end
end
local elapsed=0
local connection
connection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
 local char=player.Character;local hrp=char and char:FindFirstChild('HumanoidRootPart')
 local now=workspace:GetServerTimeNow()
 for m,c in pairs(cats)do
  if not m:IsDescendantOf(workspace)then cats[m]=nil
  else
   local nearby=hrp and (hrp.Position-c.mesh.Position).Magnitude<85
   if nearby then
    local t=now+c.phase;local b=c.bones
    -- Smooth motions at different rates; no twitching or synchronized cats.
    turn(b.Head,'up',8*math.sin(t*.24)+2*math.sin(t*.51))
    if b.Head then b.Head.bone.Transform*=CFrame.fromAxisAngle(b.Head.forward,math.rad(2.5*math.sin(t*.36)))end
    turn(b.Chest,'right',.35*math.sin(t*1.65))
    for j=1,4 do turn(b['Tail'..j],'up',(j==1 and 1 or 3.2)*math.sin(t*.72+j*.52))end
    local flick=math.max(0,math.sin(t*.37))^18
    turn(b['Ear.L'],'forward',-5*flick);turn(b['Ear.R'],'forward',4*math.max(0,math.sin(t*.31+2))^18)
    c.active=true
   elseif c.active then
    for _,b in pairs(c.bones)do b.bone.Transform=CFrame.identity end;c.active=false
   end
  end
 end
end)
script.Destroying:Connect(function()connection:Disconnect();added:Disconnect();streamed:Disconnect()end)
