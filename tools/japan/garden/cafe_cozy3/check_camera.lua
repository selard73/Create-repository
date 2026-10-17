local Run=game:GetService("RunService")
local cam=workspace.CurrentCamera
local frame=game.ReplicatedStorage.CafeInterior2Link:GetAttribute("RoomFrame")
local old=cam.CFrame;local oldFocus=cam.Focus;local desired
local focus=frame:PointToWorldSpace(Vector3.new(0,5,-14))
local minimum=Vector3.new(-16.8,.12,-27.8);local maximum=Vector3.new(16.8,9.15,-.15)
local count,maxError=0,0
cam.CameraType=Enum.CameraType.Custom
Run:BindToRenderStep("CozyCameraProbe",200,function()if desired then cam.CFrame=desired;cam.Focus=CFrame.new(focus)end end)
local ok,err=pcall(function()
 for yaw=0,315,45 do for _,pitch in ipairs({-80,-35,35,80})do
  local dir=(CFrame.Angles(0,math.rad(yaw),0)*CFrame.Angles(math.rad(pitch),0,0)).LookVector
  desired=CFrame.lookAt(focus-dir*50,focus)
  Run.RenderStepped:Wait();Run.RenderStepped:Wait()
  local near=math.abs(cam.NearPlaneZ);local halfY=math.tan(math.rad(cam.FieldOfView)/2)*near;local halfX=halfY*cam.ViewportSize.X/cam.ViewportSize.Y
  local points={cam.CFrame.Position}
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do table.insert(points,cam.CFrame.Position+cam.CFrame.LookVector*near+cam.CFrame.RightVector*x*halfX+cam.CFrame.UpVector*y*halfY)end end
  for _,v in ipairs(points)do local q=frame:PointToObjectSpace(v);for _,axis in ipairs({"X","Y","Z"})do maxError=math.max(maxError,minimum[axis]-q[axis],q[axis]-maximum[axis])end end
  count+=1
 end end
end)
Run:UnbindFromRenderStep("CozyCameraProbe");cam.CFrame=old;cam.Focus=oldFocus
assert(ok,err);assert(maxError<.001,"Camera escaped room bounds")
return {samples=count,maxOverflow=maxError,viewport=tostring(cam.ViewportSize),ceilingLimit=9.15}
