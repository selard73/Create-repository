-- ReceiptRouter: every Developer Product purchase in the game lands here and is granted exactly once.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local P = workspace:WaitForChild("AcornPacks")
local bought = P:WaitForChild("PackBought")
local tryEv = P:WaitForChild("PackTry")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local KEYS = {"handful", "basket", "barrow"}
local receipts
if not RunService:IsStudio() then
	local ok, err = pcall(function() receipts = DataStoreService:GetDataStore("Receipts_v1") end)
	if not ok then warn("Receipts: no receipt store (" .. tostring(err) .. "); purchases will still be granted, retries could grant twice") end
end

local function packFor(productId)
	for _, key in ipairs(KEYS) do
		local id = P:GetAttribute("Product_" .. key) or 0
		if id > 0 and id == productId then return key, P:GetAttribute("Acorns_" .. key) or 0 end
	end
end
local function grantAcorns(player, key, n, how)
	local have = player:GetAttribute("Acorns") or 0
	player:SetAttribute("Acorns", have + n)
	awardAcorns:Fire(player, n)                                   -- SquirrelSetup owns the saving
	bought:FireClient(player, key, n)
	print(string.format("Receipts: %s got %d acorns (%s, %s)", player.Name, n, key, how))
end
-- what a receipt is for, and the function that grants it; nil for a product this game does not know
local function handlerFor(receipt)
	local key, n = packFor(receipt.ProductId)
	if key then return function(player) grantAcorns(player, key, n, "receipt " .. tostring(receipt.PurchaseId)) end end
	local H = workspace:FindFirstChild("HintShop")
	if H and receipt.ProductId == (H:GetAttribute("HintProductId") or 0) then
		return function(player)
			local gf = H:FindFirstChild("GrantHint")
			if gf then gf:Invoke(player) end                      -- "nothing left to hint" is still a fulfilled purchase
		end
	end
end
MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end   -- gone; Roblox asks again when they are back
	local handler = handlerFor(receipt)
	if not handler then
		warn("Receipts: unknown product " .. tostring(receipt.ProductId) .. " - not granted")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not receipts then                                          -- Studio (or a store that would not open)
		local ok, err = pcall(handler, player)
		if not ok then warn("Receipts: grant failed - " .. tostring(err)); return Enum.ProductPurchaseDecision.NotProcessedYet end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local key = receipt.PlayerId .. "_" .. receipt.PurchaseId
	local ok, recorded = pcall(function()
		return receipts:UpdateAsync(key, function(already)
			if already then return already end                    -- granted before: keep the record, grant nothing
			local good, err = pcall(handler, player)
			if not good then error("Receipts: grant failed - " .. tostring(err)) end   -- aborts the record; Roblox retries
			return {uid = receipt.PlayerId, product = receipt.ProductId, t = os.time()}
		end)
	end)
	if not ok or recorded == nil then
		warn("Receipts: could not record " .. key .. " (" .. tostring(recorded) .. "); will be retried")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
-- Studio only: a pack whose product does not exist yet can be taken free, to test the grant and the toast
tryEv.OnServerEvent:Connect(function(player, key)
	if not RunService:IsStudio() or type(key) ~= "string" then return end
	local id, n = P:GetAttribute("Product_" .. key), P:GetAttribute("Acorns_" .. key)
	if id == nil or n == nil or id > 0 then return end             -- a real product is bought through the prompt
	grantAcorns(player, key, n, "Studio try")
end)
print("Receipts: router ready - the paid hint and the acorn packs")
