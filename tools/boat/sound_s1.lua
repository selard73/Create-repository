-- s1 READ-ONLY: check sound asset 15067494918 (info + does it load). Makes nothing in the place.
local id = 15067494918
local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(id, Enum.InfoType.Asset) end)
if ok and info then
	print("QQ S1 name", info.Name, "| type", info.AssetTypeId, "| creator", info.Creator and info.Creator.Name, info.Creator and info.Creator.CreatorType, "| public", tostring(info.IsPublicDomain), "| forsale", tostring(info.IsForSale), "| price", tostring(info.PriceInRobux))
	print("QQ S1 desc", (info.Description or ""):sub(1, 160))
else
	print("QQ S1 info failed", tostring(info))
end
local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id
local t0 = os.clock()
local okp, err = pcall(function() game:GetService("ContentProvider"):PreloadAsync({s}) end)
print("QQ S1 preload", okp, tostring(err), "| loaded", s.IsLoaded, "| length", s.TimeLength, "| took", string.format("%.1f", os.clock() - t0))
s:Destroy()
print("QQ DONE s1")
