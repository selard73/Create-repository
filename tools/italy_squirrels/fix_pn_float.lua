-- Oct 5 2026: PortoNocciola was accidentally moved (~+148 up, slightly turned) by stray clicks/keys in the viewport.
-- Undo it exactly: T = (current Chair_Wood CFrame) * (original Chair_Wood CFrame)^-1, then PN:PivotTo(T^-1 * pivot).
-- Original Chair_Wood CFrame logged this morning (dump_src probe, QD@CHAIRCF). Checks the bell first; nothing moves
-- unless the bell maps back to its logged position within 0.1.
local PN=workspace.PortoNocciola
local chair=PN:FindFirstChild('Chair_Wood',true)
local bell=PN:FindFirstChild('Brass harbour bell',true)
local crate=PN:FindFirstChild('BeppeCrate',true)
if not (chair and bell and crate) then warn('QFX@ABORT parts missing') return end
local C0=CFrame.new(258.399933,-45.0406075,-714.268616, 0.846244574,0,0.532794595, 0,1,0, -0.532794595,0,0.846244574)
local T=chair.CFrame*C0:Inverse()
local Ti=T:Inverse()
local bellBack=Ti*bell.Position
local err=(bellBack-Vector3.new(251.00001525878906,-41,-596.6699829101562)).Magnitude
local crateBack=Ti*crate:GetPivot().Position
warn('QFX@CHECK bell back',bellBack,'err',err,'crate back',crateBack)
if err>0.1 then warn('QFX@ABORT bell does not map back') return end
-- also check things OUTSIDE Porto that a wide selection could have caught
for _,n in ipairs({'ComingSoonWall','SouthGorge','Boat','River'}) do
	local m=workspace:FindFirstChild(n)
	if m then local p=m:IsA('Model') and m:GetPivot().Position or (m:FindFirstChildWhichIsA('BasePart',true) and m:FindFirstChildWhichIsA('BasePart',true).Position) warn('QFX@OTHER',n,p) end
end
local SS=game:GetService('ServerStorage')
local bk=SS:FindFirstChild('PNFloatBackup_oct5')
if not bk then bk=Instance.new('Folder',SS) bk.Name='PNFloatBackup_oct5' bk:SetAttribute('FloatedPivot',PN:GetPivot()) end
PN:PivotTo(Ti*PN:GetPivot())
game:GetService('ChangeHistoryService'):SetWaypoint('Put Porto Nocciola back')
warn('QFX@DONE bell',bell.Position,'chair',chair.Position,'crate',crate:GetPivot().Position)
