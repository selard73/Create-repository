-- v13 EDIT MODE: portraits option C (up to 3 paintings per sitter, each with its own scene/companion turn) + store blurb
-- (9 easels) + passport price (80) + bookshop register (books are free). Exact-match patches only: if any anchor is
-- missing or not unique, or the new store words need more room than the old, NOTHING is changed.
local RS = game:GetService("RunService")
if RS:IsRunning() then warn("QQ10 ABORT - run this in edit mode, not Play") return end
-- the store row gives its words 308 px (panel 440 on every landscape screen, phones too) and 44 px of height: take the
-- first wording that needs no more lines than the old one did
local OLD_BLURB = "The painter paints you and sets you on an easel in his gallery by the river - the twelve newest sitters stay."
local TS = game:GetService("TextService")
local function tall(s) return TS:GetTextSize(s, 13, Enum.Font.FredokaOne, Vector2.new(308, 1000)).Y end
local NEW_BLURB
for _, w in ipairs({
	"The painter paints you and sets you on an easel in his gallery by the river - the nine newest stay, up to three of you.",
	"The painter paints you and sets you on an easel by the river - the nine newest stay, up to three of you.",
	"The painter paints you and sets you on an easel in his gallery by the river - nine easels, up to three of you.",
	"The painter paints you for his gallery by the river - the nine newest stay, up to three of you.",
}) do
	print("QQ10 store words " .. tall(w) .. " px (old " .. tall(OLD_BLURB) .. "): " .. w)
	if not NEW_BLURB and tall(w) <= tall(OLD_BLURB) then NEW_BLURB = w end
end
if not NEW_BLURB then warn("QQ10 ABORT - no store wording fits in the old room; nothing changed") return end
print("QQ10 store words chosen: " .. NEW_BLURB)
local G = workspace.PortraitGallery
local jobs = {
	{G.PortraitServer, {
		{[==[local MAX = G:GetAttribute("Slots") or 12
]==], [==[local MAX = G:GetAttribute("Slots") or 12
local PER_SITTER = G:GetAttribute("PerSitter") or 3              -- paintings one sitter may have on the easels at once (Shannon, Sep 29: option C)
]==]},
		{[==[			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
]==], [==[			local id = e and tonumber(e.id) or 0
			-- a sitter's other paintings turn the scene and the companion on (the entry's variant), so two paintings of one
			-- sitter never look like copies; entries without a variant keep the scene they always had
			local turn = e and tonumber(e.variant) or 0
			local scene = ((id + turn) % 5) + 1
			local buddy = ((math.floor(id / 7) + turn) % 5) + 1           -- 5 = alone
]==]},
		{[==[local function merge(saved, entry)
	local out = {}
	if entry then out[1] = entry end
	for _, e in ipairs(saved or {}) do
		if type(e) == "table" and e.id and (not entry or e.id ~= entry.id) and #out < MAX then out[#out + 1] = e end
	end
	return out
end
]==], [==[local function merge(saved, entry)
	-- newest first, at most MAX; each sitter keeps their PER_SITTER newest paintings (an older one of theirs steps down, not
	-- someone else's), and one painting is never listed twice (a retried save merges the same entry again)
	local out, mine, seen = {}, {}, {}
	local function add(e)
		if type(e) ~= "table" or not e.id or #out >= MAX then return end
		local key, who = portraitKey(e), tostring(e.id)
		if seen[key] or (mine[who] or 0) >= PER_SITTER then return end
		seen[key] = true; mine[who] = (mine[who] or 0) + 1
		out[#out + 1] = e
	end
	add(entry)
	for _, e in ipairs(saved or {}) do add(e) end
	return out
end
]==]},
		{[==[ return {id=player.UserId,name=player.DisplayName,t=os.time(),receipt=game:GetService("HttpService"):GenerateGUID(false),look=look,rig=hum.RigType.Name,appearance=saveDescription(hum:GetAppliedDescription())}
]==], [==[ -- the first turn of the scene that none of this sitter's paintings on the easels already has
 local used={};for _,e in ipairs(list)do if tonumber(e.id)==player.UserId then used[tonumber(e.variant)or 0]=true end end
 local variant=0;while used[variant]and variant<4 do variant+=1 end
 return {id=player.UserId,name=player.DisplayName,t=os.time(),receipt=game:GetService("HttpService"):GenerateGUID(false),look=look,rig=hum.RigType.Name,appearance=saveDescription(hum:GetAppliedDescription()),variant=variant}
]==]},
		{[==[done:FireClient(player,"reveal",{id=entry.id,name=entry.name,modelKey=paintedModel.Name})]==],
		 [==[done:FireClient(player,"reveal",{id=entry.id,name=entry.name,modelKey=paintedModel.Name,variant=entry.variant})]==]},
	}},
	{G.PortraitClient, {
		{[==[			local id = e and tonumber(e.id) or 0
			local scene = (id % 5) + 1
			local buddy = (math.floor(id / 7) % 5) + 1                    -- 5 = alone
]==], [==[			local id = e and tonumber(e.id) or 0
			-- the same turn of scene and companion as the easel (PortraitServer show)
			local turn = e and tonumber(e.variant) or 0
			local scene = ((id + turn) % 5) + 1
			local buddy = ((math.floor(id / 7) + turn) % 5) + 1           -- 5 = alone
]==]},
	}},
	{workspace.Shop.ShopClient, {
		{[==[blurb = "The painter paints you and sets you on an easel in his gallery by the river - the twelve newest sitters stay."]==],
		 'blurb = "' .. NEW_BLURB .. '"'},
	}},
	{workspace.Passport.Catalogue, {
		{[==[A portrait costs 120 acorns and joins the gallery collection.]==], [==[A portrait costs 80 acorns and joins the gallery collection.]==]},
	}},
}
local reg = workspace:FindFirstChild("Bookshop") and workspace.Bookshop:FindFirstChild("Room") and workspace.Bookshop.Room:FindFirstChild("Register")
local regLabel = reg and reg:FindFirstChild("Screen") and reg.Screen:FindFirstChild("SurfaceGui") and reg.Screen.SurfaceGui:FindFirstChild("TextLabel")
if not regLabel or regLabel.Text ~= "25 acorns" then warn("QQ10 ABORT - the bookshop register does not say 25 acorns; nothing changed") return end
local out = {}
for _, job in ipairs(jobs) do
	local scr, src = job[1], job[1].Source
	for i, p in ipairs(job[2]) do
		local a, b = src:find(p[1], 1, true)
		if not a then warn("QQ10 ABORT - " .. scr:GetFullName() .. " anchor " .. i .. " not found; nothing changed") return end
		if src:find(p[1], b + 1, true) then warn("QQ10 ABORT - " .. scr:GetFullName() .. " anchor " .. i .. " not unique; nothing changed") return end
		src = src:sub(1, a - 1) .. p[2] .. src:sub(b + 1)
	end
	out[#out + 1] = {scr, src}
end
local CH = game:GetService("ChangeHistoryService")
local rec = CH:TryBeginRecording("Portraits option C")
for _, o in ipairs(out) do
	local before = #o[1].Source
	o[1].Source = o[2]
	print("QQ10 patched " .. o[1]:GetFullName() .. " " .. before .. " -> " .. #o[1].Source)
end
G:SetAttribute("PerSitter", 3)
regLabel.Text = "Free to read"
print("QQ10 bookshop register now says: " .. regLabel.Text)
if rec then CH:FinishRecording(rec, Enum.FinishRecordingOperation.Commit) end
print("QQ10 DONE - PerSitter " .. tostring(G:GetAttribute("PerSitter")))
