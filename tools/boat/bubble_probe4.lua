-- bubble_probe4 v1: READ-ONLY. Verbatim CrocClient lines 236-280 (praiseBubble: the croc-challenge speech bubble).
local ok, t = pcall(function() return workspace.Lagoon.CrocClient.Source end)
if not ok then print("QQ B4 no source"); return end
local L = {}
for line in (t .. "\n"):gmatch("(.-)\n") do L[#L + 1] = line end
for i = 236, math.min(280, #L) do print(string.format("QQ B4 %d: %s", i, L[i]:sub(1, 190))) end
print("QQ B4 DONE")
