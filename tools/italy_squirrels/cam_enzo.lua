-- Oct 5 2026: camera in front of a squirrel (by its mesh forward axis), slightly to the side and above
local id='crabcatcher_squirrel'
local col=workspace:FindFirstChild(id..'_color') local cm=col.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local hl=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition) local sz=hl.Z<0 and 1 or -1
local fwd=-((cm.CFrame-cm.Position):VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)).Unit
local base=cm.Position-Vector3.new(0,cm.Size.Y/2,0)
local t=base+Vector3.new(0,1.6,0)
local side=Vector3.new(-fwd.Z,0,fwd.X)
workspace.CurrentCamera.Focus=CFrame.new(t)
workspace.CurrentCamera.CFrame=CFrame.lookAt(t+fwd*7+side*2.5+Vector3.new(0,1.8,0),t)
warn('QCF@',id,'fwd',fwd)
