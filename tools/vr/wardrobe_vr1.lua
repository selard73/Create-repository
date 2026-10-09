-- vr/wardrobe_vr1 (job 44): EDIT mode. The Wardrobe tab finds its Passport page on the VR window too. One exact find in
-- the Script named WardrobeClient; compiled before writing; original -> ServerStorage.HudBackup.WardrobeClient_pre_vr1.
-- Output lines "QQ WARD".
if game:GetService("RunService"):IsRunning() then warn("QQ WARD ABORT - Play mode") return end
local found = {}
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Script") and d.Name == "WardrobeClient" then table.insert(found, d) end end
if #found ~= 1 then warn("QQ WARD ABORT - expected one WardrobeClient in the workspace, found " .. #found) return end
local s = found[1]
local a, b = s.Source:find([===[
local passport=pg:WaitForChild("PassportGui"):WaitForChild("Page")
]===], 1, true)
if not a or s.Source:find([===[
local passport=pg:WaitForChild("PassportGui"):WaitForChild("Page")
]===], b + 1, true) then warn(string.format("QQ WARD ABORT - the find does not match exactly once in %s (%d chars); nothing changed", s:GetFullName(), #s.Source)) return end
local o = s.Source:sub(1, a - 1) .. [===[
local passport do -- the page lives on the ScreenGui, or on the VR window's canvas in a headset (Oct 9 2026)
 local pgui=pg:WaitForChild("PassportGui")
 repeat
  local vrw=pg:FindFirstChild("VRWindow");local box=vrw and vrw:FindFirstChild("PassportGui")
  passport=(box and box:FindFirstChild("Page")) or pgui:FindFirstChild("Page")
  if not passport then task.wait(0.2) end
 until passport
end
]===] .. s.Source:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ WARD ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "WardrobeClient_pre_vr1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ WARD DONE: %s %d chars; backup ServerStorage.HudBackup.WardrobeClient_pre_vr1", s:GetFullName(), #s.Source))
