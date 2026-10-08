-- Oct 5 2026 read-only: geometry of Casa Azzurra's two display windows (world AABB of every part, grouped by name),
-- to place the All Things Bella props on the platform / shelf without hitting the shelf or the glass.
local SF=workspace.PortoNocciola['02 Pastel waterfront']['Casa Azzurra']:FindFirstChild('Finished exterior shopfront')
local function aabb(p)
	local cf,s=p.CFrame,p.Size
	local e=Vector3.new(math.abs(cf.RightVector.X)*s.X+math.abs(cf.UpVector.X)*s.Y+math.abs(cf.LookVector.X)*s.Z,
		math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z,
		math.abs(cf.RightVector.Z)*s.X+math.abs(cf.UpVector.Z)*s.Y+math.abs(cf.LookVector.Z)*s.Z)/2
	return p.Position-e,p.Position+e
end
for _,wn in ipairs({'Left glazed display window','Right glazed display window'}) do
	local W=SF and SF:FindFirstChild(wn)
	if W then
		local g={}
		for _,d in ipairs(W:GetDescendants()) do
			if d:IsA('BasePart') then
				local lo,hi=aabb(d)
				local e=g[d.Name] or {n=0,lo=lo,hi=hi,t=d.Transparency,par=d.Parent.Name}
				e.n+=1 e.lo=Vector3.new(math.min(e.lo.X,lo.X),math.min(e.lo.Y,lo.Y),math.min(e.lo.Z,lo.Z))
				e.hi=Vector3.new(math.max(e.hi.X,hi.X),math.max(e.hi.Y,hi.Y),math.max(e.hi.Z,hi.Z)) g[d.Name]=e
			end
		end
		for n,e in pairs(g) do
			warn(string.format('QBW@%s | %-34s x%-2d in %-28s x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f T%.2f',wn:sub(1,5),n,e.n,e.par:sub(1,28),e.lo.X,e.hi.X,e.lo.Y,e.hi.Y,e.lo.Z,e.hi.Z,e.t))
		end
	else warn('QBW@ no',wn) end
end
warn('QBW@DONE')
