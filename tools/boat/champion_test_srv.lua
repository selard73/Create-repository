-- champion_test v1 (PLAY, SERVER, test only): calls the Champion debug hook for the first player (what a real completion
-- would call) and reports what came back: with the owner exclusion it must print "takes no Keeper slot" and no title.
local p = game.Players:GetPlayers()[1]
local F = workspace.Champion
local r = F.ChampionDebug:Invoke(p)
warn(string.format("QQ CPT %s (UserId %d, CreatorId %d): ChampionDebug -> %s; ChampionTitle=%s; NoKeeperUserIds=%s", p.Name, p.UserId, game.CreatorId, tostring(r), tostring(p:GetAttribute("ChampionTitle")), tostring(F:GetAttribute("NoKeeperUserIds"))))
