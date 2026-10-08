-- bt_ids v1 (PLAY, SERVER, read-only): what does the player's FoundIds attribute say now, and where is the Sky Diving Squirrel?
local plr = game.Players:GetPlayers()[1]
local sq = workspace:FindFirstChild("parachute_squirrel_color")
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
warn(string.format("QQ IDS FoundIds=%s SquirrelsFound=%s; chute squirrel at %s found=%s", tostring(plr:GetAttribute("FoundIds")), tostring(plr:GetAttribute("SquirrelsFound")), mesh and tostring(mesh.Position) or "?", tostring(sq and sq:GetAttribute("Found"))))
