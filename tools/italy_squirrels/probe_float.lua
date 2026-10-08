-- Oct 5 2026 read-only: where are known Porto parts now vs this morning's values
local PN=workspace:FindFirstChild('PortoNocciola')
local function p(x) return x and (x:IsA('Model') and x:GetPivot().Position or x.Position) end
local bell=PN and PN:FindFirstChild('Brass harbour bell',true)
local chair=PN and PN:FindFirstChild('Chair_Wood',true)
local crate=PN and PN:FindFirstChild('BeppeCrate',true)
warn('QF@bell',p(bell),'expected 251,-41,-596.67')
warn('QF@chair',p(chair),'expected 258.4,-45.04,-714.27')
warn('QF@crate',p(crate),'expected ~253.4,?,-637.2')
warn('QF@PN pivot',PN and PN:GetPivot())
warn('QF@PN parent',PN and PN.Parent, 'children',PN and #PN:GetChildren())
for _,c in ipairs(PN and PN:GetChildren() or {}) do
	local pos=c:IsA('Model') and c:GetPivot().Position or (c:IsA('BasePart') and c.Position) or nil
	warn('QF@child',c.Name,c.ClassName,pos)
end
local sel=game:GetService('Selection'):Get()
warn('QF@selection',#sel, sel[1] and sel[1]:GetFullName(), sel[2] and sel[2]:GetFullName())
