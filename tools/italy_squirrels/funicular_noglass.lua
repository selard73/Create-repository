-- Oct 5 2026 (Shannon: "remove the glass from the funicular, keep the roof and the side poles, remove all of the
-- transparent glass so they are open"): move every 'Car side glazing' / 'Car front glazing' of Car_Rosso and Car_Crema
-- to ServerStorage.FunicularBackup.Glass_oct5 (attribute FromPath = original parent's full name; restore by moving back).
-- Also lists every part of the Lifeguard Chair model (read-only) to find the raised seat cushion.
local PN=workspace.PortoNocciola
local F=PN:FindFirstChild('15 Funicolare')
if not F then warn('QNG@ABORT no funicular') return end
local SS=game:GetService('ServerStorage')
local fb=SS:FindFirstChild('FunicularBackup') or Instance.new('Folder',SS) fb.Name='FunicularBackup'
local gb=fb:FindFirstChild('Glass_oct5') or Instance.new('Folder',fb) gb.Name='Glass_oct5'
local moved=0
for _,carName in ipairs({'Car_Rosso','Car_Crema'}) do
	local car=F:FindFirstChild(carName,true)
	if car then
		for _,d in ipairs(car:GetDescendants()) do
			if d:IsA('BasePart') and (d.Name=='Car side glazing' or d.Name=='Car front glazing') then
				d:SetAttribute('FromPath',d.Parent:GetFullName())
				d:SetAttribute('FromCar',carName)
				d.Parent=gb moved+=1
			end
		end
	end
end
game:GetService('ChangeHistoryService'):SetWaypoint('Funicular cars open (glass removed)')
warn('QNG@MOVED glass panes',moved)
local chair=PN:FindFirstChild('Lifeguard Chair',true)
if chair then
	for _,d in ipairs(chair:GetDescendants()) do
		if d:IsA('BasePart') then
			warn(string.format('QNG@chair %s [%s] pos %.2f,%.2f,%.2f size %.2f,%.2f,%.2f col %d,%d,%d',d.Name,d.ClassName,
				d.Position.X,d.Position.Y,d.Position.Z,d.Size.X,d.Size.Y,d.Size.Z,d.Color.R*255,d.Color.G*255,d.Color.B*255))
		end
	end
end
local cam=workspace.CurrentCamera
local car=F:FindFirstChild('Car_Rosso',true)
if car then local cf,sz=car:GetBoundingBox() cam.CameraType=Enum.CameraType.Fixed cam.Focus=cf
	cam.CFrame=CFrame.lookAt(cf.Position+Vector3.new(-9,4,7),cf.Position) end
