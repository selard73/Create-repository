-- housekeeping Oct 4 2026: hats in the passport wardrobe + mailbox "dev" -> "mayor" (player-facing text only). Aborts before writing anything if an anchor is missing.
local function at(path) local o=game for seg in path:gmatch("[^%.]+") do o=(seg=="Workspace") and workspace or o:FindFirstChild(seg) assert(o,"missing "..path) end return o end
local function count(s,p) local n,i=0,1 while true do local a,b=s:find(p,i,true) if not a then return n end n+=1 i=b+1 end end
local E={
{"Workspace.DressShop.WardrobeClient",[==[local action=RS:WaitForChild("DressShopAction")
]==],[==[local action=RS:WaitForChild("DressShopAction")
-- hats from the hat shop live in the same suitcase (Oct 4 2026); keys "hat:<id>" keep them apart from boutique ids
local hkit=RS:WaitForChild("HatKit")
local HCat=require(hkit:WaitForChild("Catalogue"))
local hatAction=RS:WaitForChild("HatShopAction")
local function isHat(key)return key:sub(1,4)=="hat:" end
local function rawId(key)return isHat(key) and key:sub(5) or key end
local function slotOf(key)return isHat(key) and "hat" or Cat.slot(key) end
]==]},
{"Workspace.DressShop.WardrobeClient",[==[local function owned(id)return (p:GetAttribute("Item_dress_"..id) or 0)>0 end
local function wearing(id)return (p:GetAttribute("Item_dresswear_"..id) or 0)>0 end
]==],[==[local function owned(id)if isHat(id)then return (p:GetAttribute("Item_hat_"..rawId(id)) or 0)>0 end;return (p:GetAttribute("Item_dress_"..id) or 0)>0 end
local function wearing(id)if isHat(id)then return (p:GetAttribute("Item_hatwear_"..rawId(id)) or 0)>0 end;return (p:GetAttribute("Item_dresswear_"..id) or 0)>0 end
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ local m=Instance.new("Model");for _,part in ipairs(Cat.pieces(kit,id,CFrame.new(),1))do part.Anchored=true;part.Parent=m end;m.Parent=vf
]==],[==[ local m=Instance.new("Model");for _,part in ipairs(isHat(id) and HCat.pieces(hkit,rawId(id),CFrame.new(),1) or Cat.pieces(kit,id,CFrame.new(),1))do part.Anchored=true;part.Parent=m end;m.Parent=vf
]==]},
{"Workspace.DressShop.WardrobeClient",[==[local function send(what,id)
]==],[==[local function send(what,id,hat)
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ local ok,accepted,why=pcall(function()return action:InvokeServer(what,id)end)
]==],[==[ local ok,accepted,why=pcall(function()if hat then return hatAction:InvokeServer("wear",id)end;return action:InvokeServer(what,id)end)
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ local d=Cat.byId[id]
]==],[==[ local d=isHat(id) and HCat.byId[rawId(id)] or Cat.byId[id]
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ wear.Activated:Connect(function()if not wearing(id)then send("wear",id)elseif Cat.slot(id)~="dress" then send("off",Cat.slot(id))end end)
]==],[==[ wear.Activated:Connect(function()if isHat(id)then if wearing(id)then send("off","",true)else send("wear",rawId(id),true)end;return end;if not wearing(id)then send("wear",id)elseif Cat.slot(id)~="dress" then send("off",Cat.slot(id))end end)
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ for _,id in ipairs(Cat.order)do
  local mine=owned(id);local show=loaded and mine and (category=="all" or Cat.slot(id)==category)
]==],[==[ local keys={};for _,id in ipairs(Cat.order)do keys[#keys+1]=id end;for _,id in ipairs(HCat.order)do keys[#keys+1]="hat:"..id end
 for _,id in ipairs(keys)do
  local mine=owned(id);local show=loaded and mine and (category=="all" or slotOf(id)==category)
]==]},
{"Workspace.DressShop.WardrobeClient",[==[    local on=wearing(id);c.button.Text=busy and "..." or on and (Cat.slot(id)=="dress" and "Wearing" or "Put away") or "Wear it"
]==],[==[    local on=wearing(id);c.button.Text=busy and "..." or on and (slotOf(id)=="dress" and "Wearing" or "Put away") or "Wear it"
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ empty.Text=not loaded and "Opening your saved wardrobe..." or category=="all" and "Your suitcase is ready!\nOutfits and accessories you buy at the boutique will appear here." or "Nothing packed in this category yet.\nYour boutique purchases will appear here."
]==],[==[ empty.Text=not loaded and "Opening your saved wardrobe..." or category=="all" and "Your suitcase is ready!\nOutfits, hats and accessories you buy in town will appear here." or "Nothing packed in this category yet.\nYour purchases will appear here."
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ if p:GetAttribute("SaveLoaded")then for _,id in ipairs(Cat.order)do if owned(id) and Cat.slot(id)=="dress" then has=true;break end end end
]==],[==[ if p:GetAttribute("SaveLoaded")then for _,id in ipairs(Cat.order)do if owned(id) and Cat.slot(id)=="dress" then has=true;break end end;if not has then for _,id in ipairs(HCat.order)do if owned("hat:"..id)then has=true;break end end end end
]==]},
{"Workspace.DressShop.WardrobeClient",[==[ if name=="SaveLoaded" or name:sub(1,11)=="Item_dress_" or name:sub(1,15)=="Item_dresswear_" then
]==],[==[ if name=="SaveLoaded" or name:sub(1,11)=="Item_dress_" or name:sub(1,15)=="Item_dresswear_" or name:sub(1,9)=="Item_hat_" or name:sub(1,13)=="Item_hatwear_" then
]==]},
{"Workspace.DressShop.WardrobeClient",[==[print("Wardrobe: nested in passport, unlocked by owned clothing")
]==],[==[print("Wardrobe: nested in passport, unlocked by owned clothing or hats")
]==]},
{"Workspace.PostOffice.PostClient",[==[Write to the dev]==],[==[Write to the mayor]==]},
{"Workspace.PostOffice.PostClient",[==["Dear dev, ..."]==],[==["Dear Mayor, ..."]==]},
{"Workspace.PostOffice.PostClient",[==[Read the dev's last letter]==],[==[Read the mayor's last letter]==]},
{"Workspace.PostOffice.PostClient",[==[Posted. The dev will write back in about a day.]==],[==[Posted. The mayor will write back in about a day.]==]},
{"Workspace.PostOffice.PostClient",[==["Your letter is with the dev"]==],[==["Your letter is with the mayor"]==]},
{"Workspace.PostOffice.PostClient",[==[tostring(status.by or "the dev")]==],[==[tostring(status.by or "the mayor")]==]},
{"Workspace.PostOffice.PostClient",[==["La Poste - write to the dev"]==],[==["La Poste - write to the mayor"]==]},
{"Workspace.PostOffice.PostServer",[==["your letter is still with the dev"]==],[==["your letter is still with the mayor"]==]},
}
local src={}
for _,e in ipairs(E) do local s=at(e[1]) src[e[1]]=src[e[1]] or s.Source assert(count(src[e[1]],e[2])==1,"anchor count ~=1 in "..e[1]..": "..e[2]:sub(1,50)) end
for _,e in ipairs(E) do local s=src[e[1]] local a,b=s:find(e[2],1,true) src[e[1]]=s:sub(1,a-1)..e[3]..s:sub(b+1) end
for path,s in pairs(src) do at(path).Source=s end
game:GetService("ChangeHistoryService"):SetWaypoint("Hats in wardrobe + mayor mailbox")
print("HOUSEKEEPING_OK",#E)
