-- Keep the normal orbit controls, but keep the camera's near plane inside this room.
-- The fitted lining is a non-collidable U-shaped mesh; the default camera only sees
-- the outer structural walls and can slip into the gap behind that lining.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local cafe=script.Parent
local binding="CatCafeCamera_"..game:GetService("HttpService"):GenerateGUID(false)
local roomMin=Vector3.new(-12.45,.12,-19.32)
local roomMax=Vector3.new(12.45,8.0,-.15)

local function fitCamera(frame,focus,desired,fov,aspect,near)
 local halfY=math.tan(math.rad(fov)*.5)*near
 local halfX=halfY*aspect
 local lower,upper=roomMin,roomMax
 -- Include both the camera itself and all four corners of its near plane.
 for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do
  local offset=frame:VectorToObjectSpace(desired.LookVector*near+desired.RightVector*(x*halfX)+desired.UpVector*(y*halfY))
  lower=lower:Max(roomMin-offset);upper=upper:Min(roomMax-offset)
 end end
 if lower.X>upper.X or lower.Y>upper.Y or lower.Z>upper.Z then return desired end
 local anchor=frame:PointToObjectSpace(focus)
 anchor=Vector3.new(math.clamp(anchor.X,lower.X,upper.X),math.clamp(anchor.Y,lower.Y,upper.Y),math.clamp(anchor.Z,lower.Z,upper.Z))
 local destination=frame:PointToObjectSpace(desired.Position)
 local delta=destination-anchor
 local t=1
 for _,axis in ipairs({"X","Y","Z"})do
  local d=delta[axis]
  if d>1e-6 then t=math.min(t,(upper[axis]-anchor[axis])/d)
  elseif d< -1e-6 then t=math.min(t,(lower[axis]-anchor[axis])/d)end
 end
 if t>=1 then return desired end
 local position=frame:PointToWorldSpace(anchor+delta*math.max(t,0))
 return CFrame.new(position)*desired.Rotation
end

RunService:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+1,function()
 local camera=workspace.CurrentCamera
 if not camera or (camera.CameraType~=Enum.CameraType.Custom and camera.CameraType~=Enum.CameraType.Follow)then return end
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local humanoid=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 local frame=cafe:GetPivot()
 local p=frame:PointToObjectSpace(root.Position)
 if math.abs(p.X)>12.9 or p.Y< -.5 or p.Y>8.5 or p.Z< -19.9 or p.Z>0 then return end
 local view=camera.ViewportSize
 camera.CFrame=fitCamera(frame,camera.Focus.Position,camera.CFrame,camera.FieldOfView,view.X/math.max(view.Y,1),math.abs(camera.NearPlaneZ))
end)
script.Destroying:Connect(function()RunService:UnbindFromRenderStep(binding)end)
