-- boat_ownerpass v1: CHANGES THE PLACE (two one-line script edits). Her ask 06:5x: "set me up to test the boat". The jetty
-- prompt needs all 44 squirrels; the game's owner (game.CreatorId, i.e. Shannon, in the live game and in Studio play tests
-- where saves are off) can now take the boat regardless. Players are unchanged.
--  workspace.Boat.BoatServer take(): "if n < NEED then" -> "if n < NEED and p.UserId ~= game.CreatorId then"
--  workspace.Boat.BoatClient refreshPrompt(): the prompt reads "Bateau" for the owner instead of "Needs all 44 ...".
-- Re-running is harmless.
local B = workspace.Boat
local out = {}
local function patch(s, old, new)
	local src = s.Source
	if src:find(new, 1, true) then out[#out + 1] = s.Name .. ": already" return end
	local i, j = src:find(old, 1, true)
	if not i then out[#out + 1] = s.Name .. ": NOT FOUND" return end
	s.Source = src:sub(1, i - 1) .. new .. src:sub(j + 1)
	out[#out + 1] = s.Name .. ": patched"
end
patch(B.BoatServer, "\tif n < NEED then\n", "\tif n < NEED and p.UserId ~= game.CreatorId then\n")
patch(B.BoatClient, 'prompt.ObjectText = n >= NEED and "Bateau" or', 'prompt.ObjectText = (n >= NEED or player.UserId == game.CreatorId) and "Bateau" or')
print(string.format("QQ OP1 %s; CreatorId %d CreatorType %s", table.concat(out, "; "), game.CreatorId, tostring(game.CreatorType)))
print("QQ OP1 DONE")
