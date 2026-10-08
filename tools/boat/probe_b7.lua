-- b7 READ-ONLY: how the zipline does its prompt / lock note / client script (so the boat matches). Changes nothing.
local Z = workspace:FindFirstChild("Zipline")
for _, d in ipairs(Z:GetDescendants()) do
	if d:IsA("ProximityPrompt") then
		print(("QQ PROMPT %s style %s hold %.2f dist %.1f los %s action '%s' object '%s' key %s"):format(d:GetFullName(), d.Style.Name, d.HoldDuration, d.MaxActivationDistance, tostring(d.RequiresLineOfSight), d.ActionText, d.ObjectText, d.KeyboardKeyCode.Name))
		for k, v in pairs(d:GetAttributes()) do print("QQ PROMPTATTR " .. k .. "=" .. tostring(v)) end
	elseif d:IsA("LuaSourceContainer") then
		print("QQ SCRIPT " .. d:GetFullName() .. " " .. d.ClassName .. (d:IsA("Script") and (" ctx " .. d.RunContext.Name) or ""))
	elseif d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
		print("QQ REMOTE " .. d:GetFullName())
	end
end
local src = Z.ZipServer.Source
local n = 0
for line in (src .. "\n"):gmatch("(.-)\n") do
	n += 1
	if (n >= 200 and n <= 238) or line:find("need") or line:find("Note") or line:find("Fire") then print(("QQ ZS %d: %s"):format(n, line:sub(1, 200))) end
end
local c = Z.ZipClient.Source; n = 0
for line in (c .. "\n"):gmatch("(.-)\n") do
	n += 1
	if line:find("OnClientEvent") or line:find("toast") or line:find("Toast") or line:find("PromptShown") or line:find("ActionText") then print(("QQ ZC %d: %s"):format(n, line:sub(1, 200))) end
end
local pc = workspace.PromptUI.PromptClient.Source; n = 0
for line in (pc .. "\n"):gmatch("(.-)\n") do
	n += 1
	if n <= 20 or line:find("Style") or line:find("PromptShown") or line:find("GetAttribute") then print(("QQ PC %d: %s"):format(n, line:sub(1, 200))) end
end
print("QQ SPS " .. table.concat((function() local t = {} for _, x in ipairs(game.StarterPlayer.StarterPlayerScripts:GetChildren()) do table.insert(t, x.Name .. ":" .. x.ClassName) end return t end)(), ", "))
print("QQ DONE b7")