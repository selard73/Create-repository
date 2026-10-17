local R=game:GetService("RunService");R:UnbindFromRenderStep("CafePreviewPhoto");R:UnbindFromRenderStep("CafePreviewHide")
local p=game.Players.LocalPlayer
for _,v in ipairs(p.PlayerGui:GetChildren())do if (v:IsA("ScreenGui")or v:IsA("BillboardGui"))and v.Name~="CafeDoorwayFade"then if v:GetAttribute("CafePhotoWasEnabled")==nil then v:SetAttribute("CafePhotoWasEnabled",v.Enabled)end;v.Enabled=false end end
local parts={};for _,v in ipairs(p.Character:GetDescendants())do if v:IsA("BasePart")then if v:GetAttribute("CafePhotoWasLTM")==nil then v:SetAttribute("CafePhotoWasLTM",v.LocalTransparencyModifier)end;table.insert(parts,v)elseif v:IsA("BillboardGui")then if v:GetAttribute("CafePhotoWasEnabled")==nil then v:SetAttribute("CafePhotoWasEnabled",v.Enabled)end;v.Enabled=false end end
R:BindToRenderStep("CafePreviewHide",1001,function()for _,v in ipairs(parts)do v.LocalTransparencyModifier=1 end end)
