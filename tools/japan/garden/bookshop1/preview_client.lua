local p=game.Players.LocalPlayer;pcall(function()p:RequestStreamAroundAsync(Vector3.new(5987,4,-65),10)end)
local m=workspace.JapanMap.ShopFronts:WaitForChild('BookStationery',10);assert(m)
local s=Instance.new('Folder');s.Name='BookshopPreviewRestore';s:SetAttribute('CameraCFrame',workspace.CurrentCamera.CFrame);s:SetAttribute('CameraType',workspace.CurrentCamera.CameraType.Name);s:SetAttribute('FOV',workspace.CurrentCamera.FieldOfView);s.Parent=p
local f=m:GetPivot();s:SetAttribute('View',CFrame.lookAt(f:PointToWorldSpace(Vector3.new(-2,5.4,15)),f:PointToWorldSpace(Vector3.new(0,3.6,-1.7))));s:SetAttribute('PreviewFOV',58)
for _,d in p.Character:GetDescendants()do if d:IsA('BasePart')then d:SetAttribute('BookshopPreviewWasLTM',d.LocalTransparencyModifier);d.LocalTransparencyModifier=1 end end
local h=p.Character:FindFirstChildOfClass('Humanoid');h:SetAttribute('BookshopPreviewWasDisplay',h.DisplayDistanceType.Name);h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
game.RunService:BindToRenderStep('BookshopPreviewCamera',Enum.RenderPriority.Camera.Value+50,function()workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable;workspace.CurrentCamera.FieldOfView=s:GetAttribute('PreviewFOV');workspace.CurrentCamera.CFrame=s:GetAttribute('View')end)
game.RunService:BindToRenderStep('BookshopPreviewHide',Enum.RenderPriority.Last.Value,function()for _,root in ipairs({p.PlayerGui,p.Character})do for _,g in root:GetDescendants()do if g:IsA('ScreenGui')or g:IsA('BillboardGui')then if g:GetAttribute('BookshopPreviewWasEnabled')==nil then g:SetAttribute('BookshopPreviewWasEnabled',g.Enabled)end;g.Enabled=false end end end end)
local parts={};for _,d in m:GetDescendants()do if d:IsA('MeshPart')then table.insert(parts,d)end end;local states={};game.ContentProvider:PreloadAsync(parts,function(id,status)states[status.Name]=(states[status.Name]or 0)+1 end);task.wait(.5)
local labels={};for _,d in m:GetDescendants()do if d:IsA('TextLabel')then table.insert(labels,{text=d.Text,size=d.TextSize,fits=d.TextFits});assert(d.TextFits and d.TextSize>=15)end end
return game.HttpService:JSONEncode({meshParts=#parts,assetStates=states,labels=labels})
