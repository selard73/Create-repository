-- balloon/balloon_fix1: EDIT mode. BalloonClient used signPart before its declaration (128 errors a flight, the sky sign
-- never followed the basket). Two exact finds in workspace.BalloonField.BalloonClient (13854 chars); compiled first;
-- original -> ServerStorage.HudBackup.BalloonClient_pre_fix1. Output "QQ BFIX".
if game:GetService("RunService"):IsRunning() then warn("QQ BFIX ABORT - Play mode") return end
local F = workspace:FindFirstChild("BalloonField"); local s = F and F:FindFirstChild("BalloonClient")
if not s then warn("QQ BFIX ABORT - no workspace.BalloonField.BalloonClient") return end
if #s.Source ~= 13854 then warn(string.format("QQ BFIX ABORT - BalloonClient is %d chars, expected 13854; nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{[===[
local signBasket = nil
RunService.RenderStepped:Connect(function()
]===], [===[
local signBasket, signPart = nil, nil   -- (made below; the loop runs first)
RunService.RenderStepped:Connect(function()
]===]}, {[===[
local signPart = Instance.new("Part"); signPart.Name = "SkySign";]===], [===[
signPart = Instance.new("Part"); signPart.Name = "SkySign";]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a or o:find(p[1], b + 1, true) then warn("QQ BFIX ABORT - find " .. i .. " not exactly once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o); if not f then warn("QQ BFIX ABORT - does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage"); local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "BalloonClient_pre_fix1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ BFIX DONE: BalloonClient %d chars", #s.Source))
