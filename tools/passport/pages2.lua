-- passport/pages2 (job 30): EDIT mode. Fix to job 25: a stamp updated the right page but wrote it back under the French
-- key, so Porto stamps copied the Porto page over the French page. Two exact finds in workspace.Passport.PassportServer
-- (9188 chars); compiled before writing; original -> ServerStorage.HudBackup.PassportServer_pre_pages2. Output "QQ PAGE2".
if game:GetService("RunService"):IsRunning() then warn("QQ PAGE2 ABORT - Play mode") return end
local P = workspace:FindFirstChild("Passport")
local s = P and P:FindFirstChild("PassportServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ PAGE2 ABORT - missing Passport.PassportServer") return end
if #s.Source ~= 9188 then warn(string.format("QQ PAGE2 ABORT - PassportServer is %d chars, expected 9188 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{[===[
 local batch=s.journal[J.cityOf(id)=="italy" and "_batch_porto" or "_batch"]
 if batch then
]===], [===[
 local pageKey=J.cityOf(id)=="italy" and "_batch_porto" or "_batch"
 local batch=s.journal[pageKey]
 if batch then
]===]}, {[===[
  if changed then write(p,"_batch",b) end
]===], [===[
  if changed then write(p,pageKey,b) end
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ PAGE2 ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ PAGE2 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ PAGE2 ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PassportServer_pre_pages2"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ PAGE2 DONE: PassportServer %d chars; backup ServerStorage.HudBackup.PassportServer_pre_pages2", #s.Source))
