-- Oct 5 2026 read-only: parts on the boat the captain stands on (Azzurra) that could be a chair/seat/bench
local cm=workspace.seacaptain_squirrel_color.Squirrel
local p=cm.Position
local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances={workspace.seacaptain_squirrel_color,workspace:FindFirstChild('SquirrelTwins')}
local seen={}
for _,b in ipairs(workspace:GetPartBoundsInRadius(p,9,op)) do
	local m=b:FindFirstAncestorWhichIsA('Model')
	local key=(m and m:GetFullName() or '')..'/'..b.Name
	if not seen[key] then seen[key]=true
		warn('QAZ@',m and m.Name,'|',b.Name,b.ClassName,'pos',b.Position,'size',b.Size,'top',b.Position.Y+b.Size.Y/2)
	end
end
warn('QAZ@captain',p,'bottom',p.Y-cm.Size.Y/2)
