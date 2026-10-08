-- v3 READ-ONLY PortraitWall lookup: GetAsync / ListVersionsAsync / ListKeysAsync only - nothing is written
local DSS = game:GetService("DataStoreService")
local H = game:GetService("HttpService")
local ds = DSS:GetDataStore("PortraitWall")
local function P(...) local t = {} for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end print("QQ " .. table.concat(t, " | ")) end
local function fmt(ms) return ms and os.date("!%Y-%m-%d %H:%M:%S", math.floor(ms / 1000)) or "-" end
local function when(t) return type(t) == "number" and os.date("!%Y-%m-%d %H:%M:%S", t) or tostring(t) end
local ok, v, info = pcall(function() return ds:GetAsync("latest") end)
P("latest", ok, typeof(v), info and fmt(info.UpdatedTime), info and info.Version)
if ok and type(v) == "table" then
	P("latest n", #v, #H:JSONEncode(v))
	for i, e in ipairs(v) do
		if type(e) == "table" then
			P("entry", i, e.id, e.name, when(e.t), e.receipt, e.rig, e.look and H:JSONEncode(e.look) or "-", e.appearance and ("appearance acc=" .. tostring(e.appearance.accessories and #e.appearance.accessories)) or "no-appearance", #H:JSONEncode(e))
		else P("entry", i, typeof(e)) end
	end
elseif not ok then P("latest err", v) end
local keys = {}
local okK, kp = pcall(function() return ds:ListKeysAsync("", 50) end)
if okK then
	local n = 0
	repeat
		for _, k in ipairs(kp:GetCurrentPage()) do n += 1; keys[#keys + 1] = k.KeyName end
		if kp.IsFinished or n >= 200 then break end
		kp:AdvanceToNextPageAsync()
	until false
	P("keys", #keys)
else P("keys err", kp) end
for _, key in ipairs(keys) do
	if key ~= "latest" then
		local ok2, v2, info2 = pcall(function() return ds:GetAsync(key) end)
		local desc
		if type(v2) == "table" then
			desc = "target=" .. tostring(v2.target) .. " t=" .. when(v2.entry and v2.entry.t) .. " receipt=" .. tostring(v2.entry and v2.entry.receipt) .. " look=" .. (v2.entry and v2.entry.look and H:JSONEncode(v2.entry.look) or "-")
		else desc = tostring(v2) end
		P("key", key, ok2, desc, info2 and fmt(info2.UpdatedTime), info2 and fmt(info2.CreatedTime))
	end
	task.wait(0.1)
end
for _, key in ipairs({"latest", "pending_u9611145467", "painted_u9611145467"}) do
	local ok3, pages = pcall(function() return ds:ListVersionsAsync(key, Enum.SortDirection.Descending, DateTime.now().UnixTimestampMillis - 4 * 86400 * 1000) end)
	if ok3 then
		local n = 0
		repeat
			for _, ver in ipairs(pages:GetCurrentPage()) do n += 1; P("ver", key, fmt(ver.CreatedTime), ver.Version, ver.IsDeleted) end
			if pages.IsFinished or n >= 80 then break end
			pages:AdvanceToNextPageAsync()
		until false
	else P("ver err", key, pages) end
end
P("DONE3")
