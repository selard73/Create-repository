-- Guardian of the Harbour: first fresh Italy completion per 09:00 UTC day.
-- Daily ledger is separate from player saves; the historical "first" record is read-only.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local BadgeService = game:GetService("BadgeService")
local MessagingService = game:GetService("MessagingService")
local Http = game:GetService("HttpService")
local F = script.Parent
local ev = RS:WaitForChild("PortoKeeperEvent")
local collected = RS:WaitForChild("SquirrelCollectedServer")
local getAttempts = RS:WaitForChild("GetItalyAttempts")
local acknowledge = RS:WaitForChild("AckItalyAttempt")
local STUDIO = RunService:IsStudio()
local Core = require(F:WaitForChild("DailyKeeperCore"))
local Store = require(F:WaitForChild("DailyKeeperStore"))
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local ALL_ID, PORTO_ID = Core.registry(Registry.squirrels)
local registryTotal = 0
for _ in pairs(PORTO_ID) do registryTotal += 1 end
assert(registryTotal == Core.NEED and (tonumber(F:GetAttribute("Need")) or 44) == Core.NEED, "Italy daily award requires the 44-squirrel registry")
local daily = workspace:FindFirstChild("Daily")
local OFFSET = daily and daily:GetAttribute("DayOffsetHours") or 9
local TOPIC = "PortoKeeperDaily_v2"
local function need() return Core.NEED end
local function title() return F:GetAttribute("Title") or "Guardian of the Harbour" end
local function dateOf(rec)
    return os.date("!%B %d, %Y", rec.day and (rec.day * 86400 + 43200) or rec.t)
end
local GOLD, GOLD_D, GOLD_DD = Color3.new(1, 0.807843, 0.25098), Color3.new(0.839216, 0.627451, 0.172549), Color3.new(0.745098, 0.533333, 0.156863)
