-- Oct 4 2026: slide Enzo forward (his facing) until his front boots reach the kidney pool's rim, trap out over the water.
local col=workspace:FindFirstChild('crabcatcher_squirrel_color')
if not col then warn('QC@ABORT missing') return end
local pools=workspace.PortoNocciola:FindFirstChild('Natural tide pools',true)
local shelf,water=pools.TidePoolShelf,pools.TidePoolWater
local cm=col.Squirrel
local B={} for _,d in ipairs(col:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local sz=cm.CFrame:PointToObjectSpace(B.Head.WorldPosition).Z<0 and 1 or -1
local k=3.4/cm.Size.Y
local R=cm.CFrame-cm.Position
local f=(R:VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)).Unit
local feet={{-0.47,-0.38},{-0.15,-0.38},{-0.47,0.0},{-0.15,0.0},{0.13,-0.42},{0.44,-0.42},{0.13,0.0},{0.44,0.0}}
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={shelf,water}
local base={} for i,p in ipairs(feet) do base[i]=cm.Position+R:VectorToWorldSpace(Vector3.new(p[1],0,sz*p[2])*k) end
local function test(d)
	local hi,lo=-1e9,1e9
	for _,w in ipairs(base) do
		local q=workspace:Raycast(Vector3.new(w.X+f.X*d,-40,w.Z+f.Z*d),Vector3.new(0,-20,0),rp)
		if not q or q.Instance~=shelf then return nil end
		hi=math.max(hi,q.Position.Y) lo=math.min(lo,q.Position.Y)
	end
	return hi,lo
end
local best
for d=0,3,0.1 do
	local hi,lo=test(d)
	if hi and hi-lo<0.15 then best={d=d,hi=hi,lo=lo} end
	if not hi then break end
end
if not best or best.d<0.05 then warn('QC@NOMOVE',best and best.d) return end
-- front of the trap: is it over water now?
local tip=cm.Position+f*(best.d+1.4)
local q=workspace:Raycast(Vector3.new(tip.X,-40,tip.Z),Vector3.new(0,-20,0),rp)
local bottom=cm.Position.Y-cm.Size.Y/2
col:PivotTo(col:GetPivot()+f*best.d+Vector3.new(0,best.hi+0.02-bottom,0))
game:GetService('ChangeHistoryService'):SetWaypoint('Enzo to the pool rim')
warn('QC@MOVED',best.d,'spread',best.hi-best.lo,'pos',cm.Position,'trap over',q and q.Instance.Name)
