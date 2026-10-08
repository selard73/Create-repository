-- champion_patch1 v1: Workspace.Champion.ChampionServer - the game owner (game.CreatorId) never takes a Grand Keeper slot
-- (Shannon, Oct 1 2026: she completes the 44 for testing in the live game); other user ids can be listed in the Champion
-- folder attribute NoKeeperUserIds ("123, 456"). Everyone else wins exactly as before. Safe to re-run.
local s = workspace:FindFirstChild("Champion") and workspace.Champion:FindFirstChild("ChampionServer")
if not s then print("QQ CP no ChampionServer"); return end
local src = s.Source
local old = "local function crown(player)\n\tlocal day = today()\n"
local new = "local function crown(player)\n"
	.. "\t-- the owner never takes a Keeper slot (Shannon, Oct 1 2026: she completes the 44 for testing in the live game); other\n"
	.. "\t-- user ids can be listed in the Champion folder attribute NoKeeperUserIds (\"123, 456\"). Everyone else wins as before.\n"
	.. "\tlocal listed = tostring(F:GetAttribute(\"NoKeeperUserIds\") or \"\"):find(\"%f[%d]\" .. tostring(player.UserId) .. \"%f[%D]\") ~= nil\n"
	.. "\tif listed or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId) then\n"
	.. "\t\tprint(string.format(\"Champion: %s found them all but takes no Keeper slot (owner / NoKeeperUserIds)\", player.Name))\n"
	.. "\t\treturn\n"
	.. "\tend\n"
	.. "\tlocal day = today()\n"
if src:find("takes no Keeper slot", 1, true) then print("QQ CP ChampionServer already patched"); return end
local i, j = src:find(old, 1, true)
if not i then print("QQ CP pattern not found; nothing changed"); return end
s.Source = src:sub(1, i - 1) .. new .. src:sub(j + 1)
if workspace.Champion:GetAttribute("NoKeeperUserIds") == nil then workspace.Champion:SetAttribute("NoKeeperUserIds", "") end
local n = 0
for _ in (s.Source .. "\n"):gmatch("(.-)\n") do n += 1 end
print(string.format("QQ CP ChampionServer patched: owner (CreatorId %d) and NoKeeperUserIds never take a Keeper slot; %d lines", game.CreatorId, n))
