-- Oct 5 2026 (Shannon): the harbour squirrels get plain job names (Gino the Deck Hand, Penny the Tourist, Signora Chiave
-- keep theirs). Also the player-visible lines that said "Beppe". Every anchor is checked first; nothing changes unless all
-- are found exactly once. Backups: ServerStorage.NameBackup_oct5.
local SS=game:GetService('ServerStorage')
local reg=workspace.SquirrelScripts.SquirrelRegistry
local shop=workspace.Shop.ShopClient
local crabS=workspace.CrabGame.CrabServer
local crabC=game.StarterPlayer.StarterPlayerScripts.CrabClient
local EDITS={
	{reg,'name = "Signor Timbro"','name = "Customs Officer Squirrel"'},
	{reg,'name = "Beppe the Fishmonger"','name = "Fish Market Squirrel"'},
	{reg,'name = "Nonno Reti"','name = "Net Mender Squirrel"'},
	{reg,'name = "Giulia the Gelato Squirrel"','name = "Gelato Squirrel"'},
	{reg,'name = "Vito the Boat Painter"','name = "Boat Painter Squirrel"'},
	{reg,'name = "Tito the Tightrope Walker"','name = "Tightrope Walker Squirrel"'},
	{reg,'name = "Capitano Remo"','name = "Boat Captain Squirrel"'},
	{reg,'name = "Sandro the Sunbather"','name = "Sunbather Squirrel"'},
	{reg,'name = "Enzo the Crab Catcher"','name = "Crab Catcher Squirrel"'},
	{reg,'name = "Tonio the Conductor"','name = "Conductor Squirrel"'},
	{reg,'name = "Rocco the Lifeguard"','name = "Lifeguard Squirrel"'},
	{reg,'name = "Lello the Octopus Catcher"','name = "Octopus Catcher Squirrel"'},
	{reg,'The fishermen say it was Beppe."','The fishermen say it was the Fish Market Squirrel."'},
	{shop,'then sell your catch to Beppe."','then sell your catch to the Fish Market Squirrel."'},
	{crabS,'"Your bucket is full! Sell your crabs to Beppe at the fish stall."','"Your bucket is full! Sell your crabs to the Fish Market Squirrel at the fish stall."'},
	{crabC,'"\\nsell to Beppe"','"\\nsell at the fish market"'},
}
local src={}
for _,e in ipairs(EDITS) do src[e[1]]=src[e[1]] or e[1].Source end
local bad={}
for i,e in ipairs(EDITS) do
	local s=src[e[1]]
	local a,b=s:find(e[2],1,true)
	if not a or s:find(e[2],b+1,true) then table.insert(bad,i) end
end
if #bad>0 then warn('QRN@ABORT anchors missing/duplicated:',table.concat(bad,',')) return end
local bk=SS:FindFirstChild('NameBackup_oct5') or Instance.new('Folder',SS) bk.Name='NameBackup_oct5'
for scr,_ in pairs(src) do
	if not bk:FindFirstChild(scr.Name) then local x=scr:Clone() if x:IsA('BaseScript') then x.Disabled=true end x.Parent=bk end
end
for _,e in ipairs(EDITS) do
	local s=src[e[1]] local a,b=s:find(e[2],1,true)
	src[e[1]]=s:sub(1,a-1)..e[3]..s:sub(b+1)
end
for scr,s in pairs(src) do scr.Source=s end
game:GetService('ChangeHistoryService'):SetWaypoint('Harbour squirrels renamed')
local names={}
for n in reg.Source:gmatch('map = "porto", name = "([^"]+)"') do table.insert(names,n) end
warn('QRN@OK',#EDITS,'edits; porto names:',table.concat(names,' | '))
