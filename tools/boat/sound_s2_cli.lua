-- s2 (PLAY, CLIENT, test copy only): does sound 15067494918 load for this game? (quiet, not played)
local s = Instance.new("Sound"); s.SoundId = "rbxassetid://15067494918"; s.Volume = 0; s.Parent = game:GetService("SoundService")
local ok, err = pcall(function() game:GetService("ContentProvider"):PreloadAsync({s}) end)
local t = 0
while not s.IsLoaded and t < 8 do task.wait(0.25); t += 0.25 end
warn("QQ S2 preload", ok, tostring(err), "| loaded", s.IsLoaded, "| length", s.TimeLength)
s:Destroy()
