-- Oct 17, 2026: Shannon approved "Welcome, <display name>!" on the completed sign.
-- Patch only the signText completion branch; keep the treehouse name and all gameplay.
local Run=game:GetService("RunService")
assert(Run:IsStudio()and not Run:IsRunning(),"Apply in stopped Studio Edit")
assert(game.PlaceId==117372258657114,"Wrong place")
local tree=assert(workspace:FindFirstChild("Treehouse"))
local client=assert(tree:FindFirstChild("TreehouseClient"))
local before=[==[	if n >= TOTAL then return NAME .. "\nWelcome home, " .. player.DisplayName .. "!" end   -- (r6b, Shannon: "Maybe do Homebase Treehouse Welcome home SelBell?")]==]
local after=[==[	if n >= TOTAL then return NAME .. "\nWelcome, " .. player.DisplayName .. "!" end   -- r7: Shannon requested a shorter completed-sign greeting.]==]
local source=client.Source
local a,b=source:find(before,1,true)
if not a then assert(source:find(after,1,true),"Sign wording differs; inspect first");print("QQ TREEHOUSE SIGN: already Welcome, <display name>!");return end
assert(not source:find(before,b+1,true),"Ambiguous completed-sign branch")
local updated=source:sub(1,a-1)..after..source:sub(b+1)
local server,reset=tree.TreehouseServer.Source,tree.TreehouseReset.Source
local count=#tree:GetDescendants()
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("Before shorter treehouse welcome sign")end)
client.Source=updated
assert(client.Source==updated,"Source readback failed")
assert(tree.TreehouseServer.Source==server and tree.TreehouseReset.Source==reset and #tree:GetDescendants()==count)
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("After shorter treehouse welcome sign")end)
print("QQ TREEHOUSE SIGN: completed sign now shows the treehouse name, then Welcome, <display name>!")
print("QQ TREEHOUSE PRESERVED: only one client source line changed; progress wording, completion sequence, server and reset unchanged")
print("QQ TREEHOUSE STATUS: EDIT; NOT PUBLISHED")
