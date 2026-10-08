-- cb2 read-only: surface materials over the whole map (16-stud grid), where Limestone is used, Limestone's colour, and
-- visible parts inside the two reshape strips (west x -150..44 z -640..-530, east x 316..560 z -596..-530)
local T=workspace.Terrain
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={T}
local hist,lime={},{}
for x=-1016,1016,16 do for z=-1016,1016,16 do
	local h=workspace:Raycast(Vector3.new(x,200,z),Vector3.new(0,-400,0),rp)
	if h then local n=h.Material.Name hist[n]=(hist[n] or 0)+1 if n=='Limestone' and #lime<25 then table.insert(lime,x..','..math.floor(h.Position.Y)..','..z) end end
end end
local parts={} for k,v in pairs(hist) do table.insert(parts,k..'='..v) end
warn('QC@hist',table.concat(parts,' '))
warn('QC@lime',#lime,table.concat(lime,' '))
warn('QC@limecolour',T:GetMaterialColor(Enum.Material.Limestone),'sandstone',T:GetMaterialColor(Enum.Material.Sandstone),'grass',T:GetMaterialColor(Enum.Material.Grass))
local function inW(p) return p.X>-150 and p.X<44 and p.Z>-640 and p.Z<-530 end
local function inE(p) return p.X>316 and p.X<560 and p.Z>-596 and p.Z<-530 end
local n=0
for _,p in ipairs(workspace:GetDescendants()) do
	if p:IsA('BasePart') and p.Transparency<0.95 and not p:IsA('Terrain') and not p:IsDescendantOf(workspace.SouthGorge) then
		local c=p.Position
		if (inW(c) or inE(c)) and c.Y>-70 and c.Y<120 then n+=1 if n<=40 then warn('QC@zp',p:GetFullName():sub(-60),math.floor(c.X),math.floor(c.Y),math.floor(c.Z),math.floor(p.Size.X),math.floor(p.Size.Y),math.floor(p.Size.Z)) end end
	end
end
warn('QC@zpcount',n)
local tr=workspace.SouthGorge:FindFirstChild('Trees') local nt=0
if tr then for _,m in ipairs(tr:GetChildren()) do local ok,cf=pcall(function() return m:GetPivot() end) if ok and (inW(cf.Position) or inE(cf.Position)) then nt+=1 end end end
warn('QC@gorgetrees in strips',nt)
warn('QC@END2')
