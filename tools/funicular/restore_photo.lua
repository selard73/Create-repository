local car=workspace.PortoNocciola['15 Funicolare'].Cars.Car_Crema
local from=car:GetAttribute('PhotoFrom')
if from then car:PivotTo(from) car:SetAttribute('PhotoFrom',nil) warn('QP@RESTORED',from.Position) else warn('QP@NOTHING') end
