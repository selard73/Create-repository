#!/usr/bin/env python3
"""Builds tools/japan/japan_guest1.lua (job 116): a GUEST on the private Japan preview. Shannon (Oct 15 2026): "can you set shademade up
so that his balloon also goes to Japan map, even though its not done yet, I want him to see it." Shademade = Roblox user id 3121141
(users API). The preview is owner-only in eight scripts; the server side all asks JapanPreviewAccess.IsAllowed, the client side reads
the owner id directly. Exact-string patches (marker JAPANGUEST1_20261015; each anchor counted first, each result compiled, originals
to HudBackup.<Name>_pre_japanguest1):
 1. ServerScriptService.JapanPreviewAccess: IsAllowed = the owner, the GuestUserIds table (Shademade), or any id in the module's
    attribute GuestUserIds (comma-separated - Shannon can add or remove a guest in Properties, no code). Everything server-side
    follows: the balloon flies a guest to Japan (and skips the 44-squirrel lock for that ride), the guard lets them stay, the train,
    the taxi home, the Area "japan". JapanPreviewGuard already mirrors IsAllowed onto the player's JapanPreviewAllowed attribute
    every 0.2 s - the clients below read that.
 2. Workspace.BalloonField.BalloonClient: previewOwner = owner or JapanPreviewAllowed, kept current, the prompt re-labelled on change.
 3. StarterPlayerScripts.JapanPreviewVisibility: waits (up to 8 s) for the attribute, and a guest is not hidden from Japan.
 4. StarterPlayerScripts.JapanAtmosphere, 5. JapanWaterAppearance: Japan's lighting and water for a guest too.
 6. Workspace.MapMusic.MusicClient: Japan's music areas for a guest (four owner checks -> isPreview()).
 7. JapanMap's three AutomaticFoodSeatContact (server): the food seats for a guest.
Self-test against the Oct 15 exports with japan_fix1 applied (tools/japan/check/, from make_japan_fix1.py). Run from the repo root."""
import pathlib, subprocess, os
HERE = pathlib.Path(__file__).resolve().parent
EXP, CHK = HERE / "studio_2026-10-15", HERE / "check"
MARK = "JAPANGUEST1_20261015"
GUEST_IDS = {3121141: "Shademade"}
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
OWN = "player.UserId == 9611145467"
ids_lua = ", ".join(f"[{i}] = true" for i in GUEST_IDS)
SCRIPTS = [
 {"name": "JapanPreviewAccess", "src": EXP / "JapanPreviewAccess.lua", "find": 'path', "path": ["ServerScriptService", "JapanPreviewAccess"], "patches": [
   ("function Access.IsAllowed(player)\n\treturn player ~= nil and player.UserId == Access.OwnerUserId\nend\n",
    "-- JAPANGUEST1_20261015: guests on the private preview (Shannon). Add more in Properties: this module's attribute GuestUserIds, ids comma-separated.\n"
    f"Access.GuestUserIds = {{{ids_lua}}}   -- " + ", ".join(GUEST_IDS.values()) + "\n"
    "function Access.IsAllowed(player)\n"
    "\tif player == nil then return false end\n"
    "\tif player.UserId == Access.OwnerUserId or Access.GuestUserIds[player.UserId] then return true end\n"
    "\tlocal extra = script:GetAttribute(\"GuestUserIds\")\n"
    "\tif type(extra) == \"string\" then for id in extra:gmatch(\"%d+\") do if tonumber(id) == player.UserId then return true end end end\n"
    "\treturn false\nend\n", 1)]},
 {"name": "BalloonClient", "src": CHK / "BalloonClient_japanfix1.lua", "path": ["Workspace", "BalloonField", "BalloonClient"], "patches": [
   ("local previewOwner = player.UserId == 9611145467\n",
    "local previewOwner = player.UserId == 9611145467 or player:GetAttribute(\"JapanPreviewAllowed\") == true   -- JAPANGUEST1_20261015: the owner or a guest\n", 1),
   ("player:GetAttributeChangedSignal(\"Item_balloon_flights\"):Connect(updatePrompt)\n",
    "player:GetAttributeChangedSignal(\"Item_balloon_flights\"):Connect(updatePrompt)\n"
    "player:GetAttributeChangedSignal(\"JapanPreviewAllowed\"):Connect(function() previewOwner = player.UserId == 9611145467 or player:GetAttribute(\"JapanPreviewAllowed\") == true; updatePrompt() end)   -- (JAPANGUEST1)\n", 1)]},
 {"name": "JapanPreviewVisibility", "src": CHK / "JapanPreviewVisibility_japanfix1.lua", "path": ["StarterPlayer", "StarterPlayerScripts", "JapanPreviewVisibility"], "patches": [
   ("if player.UserId==9611145467 then return end\n",
    "do local t0=os.clock(); while player:GetAttribute('JapanPreviewAllowed')==nil and os.clock()-t0<8 do task.wait(0.1) end end   -- JAPANGUEST1_20261015: the server's word first\n"
    "if player.UserId==9611145467 or player:GetAttribute('JapanPreviewAllowed')==true then return end\n", 1)]},
 {"name": "JapanAtmosphere", "src": CHK / "JapanAtmosphere_japanfix1.lua", "path": ["StarterPlayer", "StarterPlayerScripts", "JapanAtmosphere"], "patches": [
   ("local inside=hrp and player.UserId==9611145467 and ",
    "local inside=hrp and (player.UserId==9611145467 or player:GetAttribute('JapanPreviewAllowed')==true --[[JAPANGUEST1_20261015]]) and ", 1)]},
 {"name": "JapanWaterAppearance", "src": CHK / "JapanWaterAppearance_japanfix1.lua", "path": ["StarterPlayer", "StarterPlayerScripts", "JapanWaterAppearance"], "patches": [
   ("local inside=p and Players.LocalPlayer.UserId==9611145467 and ",
    "local inside=p and (Players.LocalPlayer.UserId==9611145467 or Players.LocalPlayer:GetAttribute('JapanPreviewAllowed')==true --[[JAPANGUEST1_20261015]]) and ", 1)]},
 {"name": "MusicClient", "src": EXP / "MusicClient.lua", "path": ["Workspace", "MapMusic", "MusicClient"], "patches": [
   ("local function areaAt(pos)\n",
    "local function isPreview() return player.UserId == 9611145467 or player:GetAttribute(\"JapanPreviewAllowed\") == true end   -- JAPANGUEST1_20261015: the owner or a guest\nlocal function areaAt(pos)\n", 1),
   ("if " + OWN, "if isPreview()", 4)]},
 {"name": "AutomaticFoodSeatContact", "src": EXP / "AutomaticFoodSeatContact.lua", "path": None, "patches": [
   ("if not player or player.UserId~=9611145467 or busy[player]then return end\n",
    "if not player or not (player.UserId==9611145467 or player:GetAttribute(\"JapanPreviewAllowed\")==true) or busy[player]then return end   -- JAPANGUEST1_20261015\n", 1)]},
]
def apply(src, patches):
    for f, r, n in patches:
        assert src.count(f) == n, (f[:60], src.count(f), n)
        src = src.replace(f, r)
    return src
luau = os.environ.get("LUAU_COMPILE")
for sc in SCRIPTS:
    s = sc["src"].read_text(encoding="utf-8")
    assert MARK not in s
    out = apply(s, sc["patches"])
    f = CHK / (sc["name"] + "_japanguest1.lua"); f.write_text(out, encoding="utf-8")
    if luau:
        r = subprocess.run([luau, "--null", str(f)], capture_output=True, text=True)
        assert "Error" not in (r.stdout + r.stderr), sc["name"] + r.stdout + r.stderr
    print(f"self-test {sc['name']}: {len(s)} -> {len(out)} chars, compiles" if luau else f"self-test {sc['name']}: anchors ok")
# ---- the installer ----
entries = []
for sc in SCRIPTS:
    pats = ", ".join("{" + L(f) + ", " + L(r) + ", " + str(n) + "}" for f, r, n in sc["patches"])
    path = "nil" if sc["path"] is None else "{" + ", ".join('"' + p + '"' for p in sc["path"]) + "}"
    entries.append('\t{name = "%s", path = %s, patches = {%s}},' % (sc["name"], path, pats))
lua = r'''-- japan/japan_guest1 (job 116): EDIT mode. A guest on the private Japan preview: Shademade (user id 3121141), at Shannon's ask (Oct 15
-- 2026). Exact-string patches of the eight scripts that gate the preview (JapanPreviewAccess, BalloonClient, JapanPreviewVisibility,
-- JapanAtmosphere, JapanWaterAppearance, MapMusic.MusicClient, JapanMap's AutomaticFoodSeatContact x3); every anchor counted before any
-- script changes (a miss = that script skipped, said in a line), each result compiled, originals -> HudBackup.<Name>_pre_japanguest1.
-- More guests later: JapanPreviewAccess's attribute GuestUserIds (ids, comma-separated). Remove a guest: take the id out (the table one
-- needs the module edited, or restore HudBackup.JapanPreviewAccess_pre_japanguest1). No publish. Output lines "QQ JGUEST".
if game:GetService("RunService"):IsRunning() then print("QQ JGUEST ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local MARK = @@MARK@@
local SCRIPTS = {
@@ENTRIES@@
}
local function find(path)
	local o = game
	for i, n in ipairs(path) do
		if i == 1 then o = game:GetService(n) else o = o:FindFirstChild(n) end
		if not o then return nil end
	end
	return o
end
local function countOf(s, f) local n, i = 0, 1; while true do local a, b = s:find(f, i, true); if not a then return n end; n += 1; i = b + 1 end end
local function patchOne(label, s, patches)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ JGUEST " .. label .. ": not found; skipped") return "missing" end
	local o = s.Source
	if o:find(MARK, 1, true) then print("QQ JGUEST " .. label .. ": already patched (" .. #o .. ")") return "already" end
	for i, p in ipairs(patches) do
		local c = countOf(o, p[1])
		if c ~= p[3] then print(string.format("QQ JGUEST %s: anchor %d found %d times (want %d); skipped - tell the cloud thread", label, i, c, p[3])) return "anchor" end
	end
	local n = o
	for _, p in ipairs(patches) do
		local out, i = {}, 1
		while true do
			local a, b = n:find(p[1], i, true)
			if not a then table.insert(out, n:sub(i)) break end
			table.insert(out, n:sub(i, a - 1)); table.insert(out, p[2]); i = b + 1
		end
		n = table.concat(out)
	end
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ JGUEST " .. label .. ": patched source does not compile: " .. tostring(err) .. "; skipped") return "compile" end
	local bn = s.Name .. "_pre_japanguest1"
	local k = 1; while hb:FindFirstChild(bn .. (k > 1 and ("_" .. k) or "")) do k += 1 end
	local c = s:Clone(); c.Name = bn .. (k > 1 and ("_" .. k) or ""); if c:IsA("BaseScript") then c.Enabled = false end; c.Parent = hb
	s.Source = n
	print(string.format("QQ JGUEST %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, c.Name))
	return "ok"
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before JapanGuest1") end)
local results = {}
for _, sc in ipairs(SCRIPTS) do
	if sc.path then
		table.insert(results, sc.name .. " " .. patchOne(sc.name, find(sc.path), sc.patches))
	else
		local J = workspace:FindFirstChild("JapanMap"); local n = 0
		for _, d in ipairs(J and J:GetDescendants() or {}) do
			if d.Name == sc.name and d:IsA("LuaSourceContainer") then n += 1; table.insert(results, sc.name .. "#" .. n .. " " .. patchOne(sc.name .. " (" .. d.Parent.Name .. ")", d, sc.patches)) end
		end
		if n == 0 then table.insert(results, sc.name .. " none found") end
	end
end
local acc = game:GetService("ServerScriptService"):FindFirstChild("JapanPreviewAccess")
if acc and acc:GetAttribute("GuestUserIds") == nil then acc:SetAttribute("GuestUserIds", "") end
local BF = workspace:FindFirstChild("BalloonField")
print("QQ JGUEST BalloonField.JapanPreview = " .. tostring(BF and BF:GetAttribute("JapanPreview")) .. " (false would give everyone, guests included, the ordinary ride)")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after JapanGuest1") end)
print("QQ JGUEST DONE: " .. table.concat(results, " | "))
'''
lua = lua.replace("@@MARK@@", L(MARK)).replace("@@ENTRIES@@", "\n".join(entries))
assert "@@" not in lua
(HERE / "japan_guest1.lua").write_text(lua, encoding="utf-8")
print("japan_guest1.lua", len(lua.encode()), "bytes")
