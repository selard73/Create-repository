local F=workspace.PortoNocciola['14 Lighthouse coast']['Cala della Sabbia and tide pools']['Natural tide pools']
local shelf=F.TidePoolShelf
-- Shannon: remove the crab
local nc=0
for _,p in ipairs(F['Sea life']:GetChildren()) do if p.Name:sub(1,4)=='Crab' then p:Destroy() nc+=1 end end
game:GetService('ChangeHistoryService'):SetWaypoint('Tide pools: crab removed')
warn('QC@CRAB removed parts',nc)
warn('QC@FID',shelf.CollisionFidelity.Name)
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={shelf}
for _,t in ipairs({{1,294.00,-770.00,-52.635},{1,296.30,-772.20,-52.635},{2,290.60,-779.40,-52.720},{2,291.50,-782.80,-52.720},{2,290.50,-786.00,-52.720},{3,296.80,-786.50,-52.203},{4,293.00,-793.60,-52.720},{4,295.60,-795.80,-52.720},{5,302.40,-800.40,-52.720},{5,304.70,-802.00,-52.720},{6,298.00,-777.20,-52.096}}) do
	local r=workspace:Raycast(Vector3.new(t[2],-40,t[3]),Vector3.new(0,-20,0),rp)
	warn(string.format('QC@POOL%d (%.1f,%.1f) bed %.2f  collision hit %s',t[1],t[2],t[3],t[4],r and string.format('%.2f',r.Position.Y) or 'none'))
end
warn('QC@END')