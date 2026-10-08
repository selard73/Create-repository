-- Receipts: the game's ONE MarketplaceService.ProcessReceipt, and the acorn packs (Developer Products: Robux in,
-- acorns into the purse). Roblox allows a single receipt callback per server; the paid Hint used to own it, so the
-- Hint now exposes a GrantHint BindableFunction and this router calls it for a hint product.
--
-- Granted once, whatever happens to the server: in the live game the PurchaseId is recorded in the "Receipts_v1"
-- DataStore with UpdateAsync and the grant runs INSIDE the transform (Roblox's own pattern) - a repeat receipt is
-- answered PurchaseGranted without a second grant, and a failed grant aborts the record so Roblox asks again. In
-- Studio there is no DataStore and no charge, so the record is skipped and a pack whose product does not exist yet
-- can be "tried" free, to test the grant and the toast.
--
-- The packs live as attributes on workspace.AcornPacks: Product_<key> (the Developer Product id from the Creator Hub,
-- 0 = not created yet) and Acorns_<key> (what it grants). The purse moves the way every other award does: the Acorns
-- attribute for the screen and AwardAcorns for SquirrelSetup's ledger (a delta, merge-safe, applied on load if the
-- save is still loading). Prices are on the products themselves; the panel reads them from Roblox.
-- Run in edit mode (re-runnable): pack ids survive a rebuild unless passed in opts.
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local P = workspace:FindFirstChild("AcornPacks")
	if not P then P = Instance.new("Folder"); P.Name = "AcornPacks"; P.Parent = workspace end
	local PACKS = {{key = "handful", acorns = 150}, {key = "basket", acorns = 500}, {key = "barrow", acorns = 1200}}
	for _, pk in ipairs(PACKS) do
		if P:GetAttribute("Product_" .. pk.key) == nil then P:SetAttribute("Product_" .. pk.key, 0) end
		if opts[pk.key] then P:SetAttribute("Product_" .. pk.key, opts[pk.key]) end
		if P:GetAttribute("Acorns_" .. pk.key) == nil or opts.resetAmounts then P:SetAttribute("Acorns_" .. pk.key, pk.acorns) end
	end
	for _, n in ipairs({"PackBought", "PackTry"}) do
		if not P:FindFirstChild(n) then local e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = P end
	end
	local R = workspace:FindFirstChild("Receipts")
	if not R then R = Instance.new("Folder"); R.Name = "Receipts"; R.Parent = workspace end
	local old = R:FindFirstChild("ReceiptRouter"); if old then old:Destroy() end

	local SRC = [==[
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
]==]
	local s = Instance.new("Script"); s.Name = "ReceiptRouter"; s.RunContext = Enum.RunContext.Server
	s.Source = SRC; s.Parent = R
	local shown = {}
	for _, pk in ipairs(PACKS) do shown[#shown + 1] = string.format("%s %d acorns (product %s)", pk.key, P:GetAttribute("Acorns_" .. pk.key), tostring(P:GetAttribute("Product_" .. pk.key))) end
	print("Receipts: " .. table.concat(shown, ", "))
end
