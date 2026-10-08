-- Oct 5 2026 read-only: every part of the Rosina, grouped by name: count, top height range, x/z span, a sample size.
local boat=workspace.PortoNocciola['04 Piers and fishing boats']:FindFirstChild('Rosina')
if not boat then warn('QR2@ABORT') return end
local g={}
for _,d in ipairs(boat:GetDescendants()) do
	if d:IsA('BasePart') then
		local e=g[d.Name] or {n=0,ylo=1e9,yhi=-1e9,xlo=1e9,xhi=-1e9,zlo=1e9,zhi=-1e9,s=d.Size,cls=d.ClassName,q=d.CanQuery}
		local cf,sz=d.CFrame,d.Size
		local top=d.Position.Y+(math.abs(cf.UpVector.Y)*sz.Y+math.abs(cf.RightVector.Y)*sz.X+math.abs(cf.LookVector.Y)*sz.Z)/2
		e.n+=1 e.ylo=math.min(e.ylo,top) e.yhi=math.max(e.yhi,top)
		e.xlo=math.min(e.xlo,d.Position.X) e.xhi=math.max(e.xhi,d.Position.X) e.zlo=math.min(e.zlo,d.Position.Z) e.zhi=math.max(e.zhi,d.Position.Z)
		g[d.Name]=e
	end
end
for nm,e in pairs(g) do
	warn(string.format('QR2@ %-34s x%-3d %s top %.2f..%.2f  x %.1f..%.1f  z %.1f..%.1f  size %.1f,%.1f,%.1f q=%s',nm,e.n,e.cls,e.ylo,e.yhi,e.xlo,e.xhi,e.zlo,e.zhi,e.s.X,e.s.Y,e.s.Z,tostring(e.q)))
end
warn('QR2@DONE')
