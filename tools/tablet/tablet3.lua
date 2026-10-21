-- tablet3 (Oct 20 2026): Shannon, on the iPad store from tablet1 (440x560 at 1.2): "still too big and cut off at the bottom"
-- -> previewed 10 % (440x440 at 1.1) -> "a little bigger, maybe 20 % bigger?" -> 440x420 at UIScale 1.2 (528x504 on an iPad
-- Air screen, y 158-662 of 820: clear of the bottom strip). Phones and computers unchanged. Run in Studio EDIT.
local SES = game:GetService("ScriptEditorService")
local shop = workspace.Shop.ShopClient
local old = [[ local height=math.min(s>1 and 560 or H,(vp.Y-140)/s)
]]
local new = [[ local height=math.min(s>1 and 420 or H,(vp.Y-140)/s)   -- (tablet: 420 tall at 1.2 - Shannon: "560" was too big, cut off at the bottom)
]]
local src = shop.Source
local a, b = src:find(old, 1, true)
assert(a, "ShopClient: tablet1 line not found - nothing changed")
assert(not src:find(old, b + 1, true), "ShopClient: line found twice - nothing changed")
local out = src:sub(1, a - 1) .. new .. src:sub(b + 1)
SES:UpdateSourceAsync(shop, function() return out end)
return "tablet3 installed: " .. tostring(shop.Source:find("420 tall at 1.2", 1, true) ~= nil)
