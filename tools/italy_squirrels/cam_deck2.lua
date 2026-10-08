-- Oct 5 2026: straight down on the Azzurra (bow = -z at the top of the picture)
local cam=workspace.CurrentCamera
cam.CameraType=Enum.CameraType.Fixed
cam.CFrame=CFrame.lookAt(Vector3.new(203.2,-34,-667.5),Vector3.new(203.2,-52,-667.51),Vector3.new(0,0,-1))
cam.Focus=CFrame.new(203.2,-52,-667.5)
-- and list every part on/around the deck that sticks up above the floor (seats, boxes)
local op=OverlapParams.new()
for _,b in ipairs(workspace:GetPartBoundsInBox(CFrame.new(203.2,-51,-667.5),Vector3.new(7,3,15),op)) do
	if b.Size.Y<1.6 and b.Position.Y+b.Size.Y/2>-52.3 and not b:IsDescendantOf(workspace.seacaptain_squirrel_color) then
		local m=b:FindFirstAncestorWhichIsA('Model')
		warn('QDK@',m and m.Name,'|',b.Name,'pos',b.Position,'size',b.Size,'top',b.Position.Y+b.Size.Y/2)
	end
end
