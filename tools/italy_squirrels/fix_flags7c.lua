-- Oct 5 2026 her flag "edges of these rocks look very unnatural" = the stepped UNDERSIDE of the upper Sentiero del Faro stair
-- (slab bottoms -44..-36 over a hill that falls away west) seen from the Cala della Sabbia tide pools. Rock is filled under
-- the stair up to each part's underside (+0.6), with a short slope on the west side south of z -812 (none further north:
-- the crab catcher's tide-pool platform is there). FillBlock never replaces sea water. Backup: PromenadeBackup.TerrainStairBefore2.
local SS=game:GetService('ServerStorage')
local T=workspace.Terrain
local BK=SS.PromenadeBackup
if BK:FindFirstChild('TerrainStairBefore2') then warn('PRF7C@ABORT already ran') return end
local tb=T:CopyRegion(Region3int16.new(Vector3int16.new(75,-16,-210),Vector3int16.new(81,-7,-199)))   -- x 300..328, y -64..-24, z -840..-792
tb.Name='TerrainStairBefore2' tb:SetAttribute('Corner',Vector3.new(75,-16,-210)) tb.Parent=BK
local S=workspace.PortoNocciola:FindFirstChild('Sentiero del Faro',true)
local NAMES={['Level stair approach']=true,['Supported limestone stair']=true,['Solid turning landing']=true,['Level stair exit']=true}
local boxes={}
for _,d in ipairs(S:GetDescendants()) do
	if d:IsA('BasePart') and NAMES[d.Name] and d.Position.Z<-792 and d.Position.Z>-840 then
		local cf,s=d.CFrame,d.Size/2
		local mn,mx=Vector3.new(1e9,1e9,1e9),Vector3.new(-1e9,-1e9,-1e9)
		for _,k in ipairs({Vector3.new(1,1,1),Vector3.new(1,1,-1),Vector3.new(1,-1,1),Vector3.new(1,-1,-1),Vector3.new(-1,1,1),Vector3.new(-1,1,-1),Vector3.new(-1,-1,1),Vector3.new(-1,-1,-1)}) do
			local w=cf:PointToWorldSpace(s*k) mn=mn:Min(w) mx=mx:Max(w) end
		table.insert(boxes,{mn,mx})
	end
end
local rows,maxB=0,-99
for z=-796,-834,-1 do
	local B,xw,xe
	for _,b in ipairs(boxes) do
		if b[1].Z<=z and z<=b[2].Z then
			B=math.max(B or -99,b[1].Y) xw=math.min(xw or 1e9,b[1].X) xe=math.max(xe or -1e9,b[2].X)
		end
	end
	if B and B>-58 then
		local top=B+0.6
		T:FillBlock(CFrame.new((xw-1.5+xe)/2,(top-62)/2,z),Vector3.new(xe-xw+1.5,top+62,1.05),Enum.Material.Rock)
		if z<=-812 then
			local t2=B-2.5
			T:FillBlock(CFrame.new(xw-3.25,(t2-62)/2,z),Vector3.new(3.5,t2+62,1.05),Enum.Material.Rock)
		end
		rows+=1 maxB=math.max(maxB,B)
	end
end
warn('PRF7C@DONE rows',rows,'parts',#boxes,'highest underside',maxB)
