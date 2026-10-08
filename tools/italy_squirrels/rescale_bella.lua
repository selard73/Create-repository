-- Oct 5 2026: the All Things Bella props read too small in the big display windows -> scale each prop about its
-- bottom centre (the hanging suncatcher about its top), keep clear of the back shelf (bottom y -43.30 from x 268.41)
-- and the glass (x 266.79); price tags re-stood in front of each item.
local SF=workspace.PortoNocciola['02 Pastel waterfront']['Casa Azzurra']['Finished exterior shopfront']
local OUT=SF:FindFirstChild('All Things Bella display')
if not OUT then warn('QBS@ABORT') return end
local F={Lamp=1.25,Vase=1.3,Box=1.5,Sun=1.4,Mirror=1.5,Neck=1.5,Candle=1.5}
local MOVEX={Lamp=267.92,Box=268.0}
local SHELF={Vase=true,Candle=true}
local function bbox(M)
	local lo,hi=Vector3.new(1e9,1e9,1e9),Vector3.new(-1e9,-1e9,-1e9)
	for _,p in ipairs(M:GetDescendants()) do
		if p:IsA('BasePart') then
			local cf,s=p.CFrame,p.Size
			local ex=Vector3.new(math.abs(cf.RightVector.X)*s.X+math.abs(cf.UpVector.X)*s.Y+math.abs(cf.LookVector.X)*s.Z,
				math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z,
				math.abs(cf.RightVector.Z)*s.X+math.abs(cf.UpVector.Z)*s.Y+math.abs(cf.LookVector.Z)*s.Z)/2
			lo=Vector3.new(math.min(lo.X,p.Position.X-ex.X),math.min(lo.Y,p.Position.Y-ex.Y),math.min(lo.Z,p.Position.Z-ex.Z))
			hi=Vector3.new(math.max(hi.X,p.Position.X+ex.X),math.max(hi.Y,p.Position.Y+ex.Y),math.max(hi.Z,p.Position.Z+ex.Z))
		end
	end
	return lo,hi
end
local rep={}
for name,f in pairs(F) do
	local M=OUT:FindFirstChild(name)
	if M then
		local tag=M:FindFirstChild('Price tag') if tag then tag.Parent=OUT end
		local lo,hi=bbox(M)
		local c=(lo+hi)/2
		local anchor=(name=='Sun') and Vector3.new(c.X,hi.Y,c.Z) or Vector3.new(c.X,lo.Y,c.Z)
		M.WorldPivot=CFrame.new(anchor)
		M:ScaleTo(M:GetScale()*f)
		if MOVEX[name] then M:PivotTo(CFrame.new(MOVEX[name],anchor.Y,anchor.Z)) end
		lo,hi=bbox(M)
		if tag then
			local p=tag.Position
			local tx=SHELF[name] and 268.5 or 267.42
			tag.CFrame=CFrame.new(tx,p.Y,p.Z)*(tag.CFrame-tag.Position)
			tag.Parent=M
		end
		table.insert(rep,string.format('%s x%.2f -> x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f',name,f,lo.X,hi.X,lo.Y,hi.Y,lo.Z,hi.Z))
	end
end
game:GetService('ChangeHistoryService'):SetWaypoint('All Things Bella props scaled up')
for _,r in ipairs(rep) do warn('QBS@'..r) end
local cam=workspace.CurrentCamera
cam.CameraType=Enum.CameraType.Fixed
cam.CFrame=CFrame.lookAt(Vector3.new(262.5,-43.2,-651.8),Vector3.new(268.6,-44.0,-651.8))
