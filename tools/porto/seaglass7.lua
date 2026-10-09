-- porto/seaglass7 (job 50): EDIT mode. Bella's panel stays inside the screen on a phone (it was cut off at the right).
-- One exact find in workspace.SeaGlass.SeaGlassClient (after job 48, about 15059 chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass7. Output "QQ SG7".
if game:GetService("RunService"):IsRunning() then warn("QQ SG7 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG7 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - 15059) > 60 then warn(string.format("QQ SG7 ABORT - SeaGlassClient is %d chars, expected about 15059 (job 48 not run yet, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
local a, b = o:find([===[
local function layout()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local h = ROW_Y + #R.recipes * ROW_H + 24
	local sc = panel:FindFirstChild("PhoneScale") or Instance.new("UIScale"); sc.Name = "PhoneScale"; sc.Parent = panel
	local s = math.clamp((v.Y - 130) / h, 0.6, 1); sc.Scale = s -- a phone keeps the top HUD bar and the jump button clear
	panel.Size = UDim2.fromOffset(math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s))
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
end
]===], 1, true)
if not a then warn("QQ SG7 ABORT - the layout function was not found as expected (already patched?); nothing changed. Source is " .. before .. " chars") return end
if o:find([===[
local function layout()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local h = ROW_Y + #R.recipes * ROW_H + 24
	local sc = panel:FindFirstChild("PhoneScale") or Instance.new("UIScale"); sc.Name = "PhoneScale"; sc.Parent = panel
	local s = math.clamp((v.Y - 130) / h, 0.6, 1); sc.Scale = s -- a phone keeps the top HUD bar and the jump button clear
	panel.Size = UDim2.fromOffset(math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s))
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
end
]===], b + 1, true) then warn("QQ SG7 ABORT - the find matches more than once; nothing changed") return end
o = o:sub(1, a - 1) .. [===[
-- the panel's face scales as one piece inside it; the panel itself keeps a plain pixel size, so its right edge is where it
-- is anchored (with the scale on the panel a phone cut it off at the right - Shannon, Oct 9)
local inner = Instance.new("Frame"); inner.Name = "Inner"; inner.BackgroundTransparency = 1; inner.ZIndex = 8; inner.Parent = panel
for _, c in ipairs(panel:GetChildren()) do if c ~= inner and c:IsA("GuiObject") then c.Parent = inner end end
local function layout()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local h = ROW_Y + #R.recipes * ROW_H + 24
	local sc = inner:FindFirstChild("PhoneScale") or Instance.new("UIScale"); sc.Name = "PhoneScale"; sc.Parent = inner
	local s = math.clamp((v.Y - 130) / h, 0.6, 1); sc.Scale = s -- a phone keeps the top HUD bar and the jump button clear
	local w, hh = math.min(380, (v.X - 24) / s), math.min(h, (v.Y - 16) / s)
	inner.Size = UDim2.fromOffset(w, hh)
	panel.Size = UDim2.fromOffset(w * s, hh * s)
	panel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)
	task.defer(function()   -- and never past it, whatever the screen does
		local over = panel.AbsolutePosition.X + panel.AbsoluteSize.X - (v.X - 2)
		if over > 0 then panel.Position = panel.Position - UDim2.fromOffset(over, 0) end
	end)
end
]===] .. o:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ SG7 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass7"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG7 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass7", before, #s.Source))
