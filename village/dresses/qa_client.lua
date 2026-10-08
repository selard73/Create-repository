local p=game.Players.LocalPlayer
local g=p.PlayerGui.DressShopGui
local list=g.Panel:FindFirstChildOfClass('ScrollingFrame')
warn('QQ BOUTIQUE LIST '..tostring(list.AbsoluteSize)..' canvas '..tostring(list.AbsoluteCanvasSize)..' layout '..tostring(list.UIListLayout.AbsoluteContentSize)..' enabled '..tostring(list.ScrollingEnabled)..' active '..tostring(list.Active))
for _,f in ipairs(list:GetChildren())do if f:IsA('Frame')then warn('QQ STYLE '..f.Name..' '..tostring(f.Visible)..' '..tostring(f.AbsolutePosition))end end
list.CanvasPosition=Vector2.new(0,296)
local c=p.Character
assert(not c:FindFirstChild('DressPreview'),'category switch cancels preview')
for _,part in ipairs(c.WornSunglasses:GetDescendants())do if part:IsA('BasePart')then assert(part.LocalTransparencyModifier==0)end end
assert(p:GetAttribute('Acorns')==760,'preview never charges')
warn('QQ BOUTIQUE CLIENT PASS: preview cancellation restores worn sunglasses; no charge')
