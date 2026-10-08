-- Oct 5 2026 PROMENADE +10, step 2b (terrain fix-up after looking at step 2):
-- a) sandy foot v2: one full 4-stud cell of sand at the wall foot (v1's 1-stud steps were too thin to rise above the water);
--    still none beside the Rosina, Pescatori pier/gangway/Stella Marina, Reti pier/La Limonaia;
-- b) north corner: grass bank in front of the quay's undressed north-west face (land meets the quay like before);
-- c) south end: beach sand carried out around the quay's south face.
-- Same backup as step 2: ServerStorage.PromenadeBackup.TerrainBefore.
local T=workspace.Terrain
local W=workspace.PortoNocciola['01 Curved waterfront']
local stones={}
for _,p in ipairs(W:GetChildren()) do
	if p:IsA('BasePart') and (p.Name=='Seawall ashlar' or p.Name=='Rounded coping stone') then
		local cf,s=p.CFrame,p.Size/2
		local mn,mx=Vector3.new(1e9,1e9,1e9),Vector3.new(-1e9,-1e9,-1e9)
		for _,k in ipairs({Vector3.new(1,1,1),Vector3.new(1,1,-1),Vector3.new(1,-1,1),Vector3.new(1,-1,-1),Vector3.new(-1,1,1),Vector3.new(-1,1,-1),Vector3.new(-1,-1,1),Vector3.new(-1,-1,-1)}) do
			local w=cf:PointToWorldSpace(s*k) mn=mn:Min(w) mx=mx:Max(w) end
		table.insert(stones,{mn,mx})
	end
end
local function wallX(z)
	local best
	for _,b in ipairs(stones) do if b[1].Z-0.6<=z and z<=b[2].Z+0.6 then best=math.min(best or 1e9,b[1].X) end end
	return best
end
local function col(x0,x1,z0,z1,top,bottom,mat)
	if top>bottom then T:FillBlock(CFrame.new((x0+x1)/2,(top+bottom)/2,(z0+z1)/2),Vector3.new(x1-x0,top-bottom,math.abs(z1-z0)),mat) end
end
-- a) foot v2
local feet=0
for z=-600,-703,-1 do
	local ok=(z>=-623) or (z<=-650.5 and z>=-680.5)
	local xw=wallX(z)
	if ok and xw then col(xw-4,xw+0.5,z+0.525,z-0.525,-52.3,-60,Enum.Material.Sand) feet+=1 end
end
-- b) north corner bank (x 211..232, z -585..-600), grass on top, sand at the waterline
local nb=0
for z=-587,-600,-1 do   -- starts 2 studs clear of the SpawnDais (z >= -585.2)
	local xEnd=(z>-592.8) and 232 or 218.2
	for x=211,xEnd-1 do
		local top=(x>=218.5) and -48.6 or (-53.6+(x-211)*(5/7.5))
		col(x,x+1,z+0.525,z-0.525,top,-60,(top>-51) and Enum.Material.Grass or Enum.Material.Sand) nb+=1
	end
end
-- c) south end beach (z -700..-713, x 219..240)
local sb=0
for z=-700,-713,-1 do
	for x=219,239 do
		local inside=(z>-702.9 and x>=224.2)   -- under the quay itself: skip
		if not inside then
			local top=-50.2-math.max(0,(-703-z))*0.35-math.max(0,224-x)*0.6
			if z>-703 then top=math.min(top,-51) end      -- strip in front of the undressed west face, kept low near La Limonaia
			col(x,x+1,z+0.525,z-0.525,top,-60,Enum.Material.Sand) sb+=1
		end
	end
end
warn('PRM2B@DONE foot rows',feet,'north cols',nb,'south cols',sb)
