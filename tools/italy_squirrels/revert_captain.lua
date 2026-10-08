-- Oct 5 2026: undo a model swap (swap_model.template.lua) - Shannon: "change the captain squirrel back to what he was before".
-- The OLD pair waits in ServerStorage.SquirrelSwapBackup as <id>_color_old_oct5c / <id>_gray_old_oct5c, still at its own CFrame.
-- Moves back whatever the swap carried over (extra children of the model and of the Squirrel mesh), copies the live
-- attributes back (not ColorTexture/GrayTexture), then parks the NEW pair in the backup as <id>_color_new_oct5.
-- Registry/bubble are untouched (same id). warn + return on anything missing, before the first edit.
local id='seacaptain_squirrel'
local SS=game:GetService('ServerStorage')
local bk=SS:FindFirstChild('SquirrelSwapBackup')
local old=bk and bk:FindFirstChild(id..'_color_old_oct5c')
local oldg=bk and bk:FindFirstChild(id..'_gray_old_oct5c')
local new=workspace:FindFirstChild(id..'_color')
local twins=workspace:FindFirstChild('SquirrelTwins')
local newg=twins and twins:FindFirstChild(id..'_gray')
if not (old and oldg and new and newg and old:FindFirstChild('Squirrel') and new:FindFirstChild('Squirrel')) then
	warn('QR@ABORT',id,'old',old,'oldg',oldg,'new',new,'newg',newg) return end
if bk:FindFirstChild(id..'_color_new_oct5') then warn('QR@ABORT backup name taken',id..'_color_new_oct5') return end
local ocm,cm=old.Squirrel,new.Squirrel
local moved={}
for _,ch in ipairs(new:GetChildren()) do
	if ch~=cm and not ch:IsA('Bone') and ch.Name~='AnimationController' and not old:FindFirstChild(ch.Name) then
		ch.Parent=old table.insert(moved,ch.Name)
	end
end
for _,ch in ipairs(cm:GetChildren()) do
	if not ch:IsA('Bone') and not ch:IsA('SurfaceAppearance') and not ocm:FindFirstChild(ch.Name) then
		ch.Parent=ocm table.insert(moved,'Squirrel.'..ch.Name)
	end
end
for k,v in pairs(new:GetAttributes()) do if not k:match('^RBX_') then old:SetAttribute(k,v) end end
for k,v in pairs(cm:GetAttributes()) do
	if not k:match('^RBX_') and k~='ColorTexture' and k~='GrayTexture' then ocm:SetAttribute(k,v) end
end
local parent=new.Parent
new.Name=id..'_color_new_oct5' new.Parent=bk
newg.Name=id..'_gray_new_oct5' newg.Parent=bk
old.Name=id..'_color' old.Parent=parent
oldg.Name=id..'_gray' oldg.Parent=twins
game:GetService('ChangeHistoryService'):SetWaypoint('Revert '..id..' model')
local hb=ocm.Position-Vector3.new(0,ocm.Size.Y/2,0)
warn('QR@OK',id,'restored at',ocm.Position,'bottom',hb,'size',ocm.Size,'moved back',table.concat(moved,','),
	'ColorTexture',ocm:GetAttribute('ColorTexture')~=nil,'GrayTexture',ocm:GetAttribute('GrayTexture')~=nil)
local B={} for _,d in ipairs(old:GetDescendants()) do if d:IsA('Bone') then B[d.Name]=d end end
local hl=B.Head and ocm.CFrame:PointToObjectSpace(B.Head.WorldPosition)
local sz=(hl and hl.Z<0) and 1 or -1
local fwd=(ocm.CFrame-ocm.Position):VectorToWorldSpace(Vector3.new(0,0,-sz))*Vector3.new(1,0,1)
local t=hb+Vector3.new(0,1.6,0)
local cam=workspace.CurrentCamera
cam.CameraType=Enum.CameraType.Fixed cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+fwd.Unit*7+Vector3.new(1.5,1.5,0),t)
