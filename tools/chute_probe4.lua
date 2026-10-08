-- chute_probe4 v1: READ-ONLY. The squirrels' speech bubble, verbatim: Workspace.Baguette.ChaseClient lines 255-300 (the
-- ChaseBubble + the speech sound), the Lagoon's SpeechSounds / SpeechMax attributes, and how the server triggers it.
local cc = workspace.Baguette:FindFirstChild("ChaseClient")
local ok, src = pcall(function() return cc.Source end)
if ok then
	local n = 0
	for line in (src .. "\n"):gmatch("(.-)\n") do
		n += 1
		if n >= 255 and n <= 300 then print(string.format("QQ P4 %d: %s", n, line:sub(1, 200))) end
	end
	-- where the bubble is fired from
	n = 0
	for line in (src .. "\n"):gmatch("(.-)\n") do
		n += 1
		local l = line:lower()
		if (l:find("bubble(") or l:find("squirrelsay") or l:find("onclientevent")) and (n < 255 or n > 300) then print(string.format("QQ P4 ref %d: %s", n, line:sub(1, 160))) end
	end
end
local lag = workspace:FindFirstChild("Lagoon")
if lag then
	local a = {}
	for k, v in pairs(lag:GetAttributes()) do a[#a + 1] = k .. "=" .. tostring(v) end
	print("QQ P4 Lagoon attrs: " .. table.concat(a, " | "))
end
local cs = workspace.Baguette:FindFirstChild("ChaseServer")
if cs then
	local ok2, s2 = pcall(function() return cs.Source end)
	if ok2 then
		local n = 0
		for line in (s2 .. "\n"):gmatch("(.-)\n") do
			n += 1
			local l = line:lower()
			if l:find("fireclient") and (l:find("say") or l:find("bubble") or l:find("speak")) then print(string.format("QQ P4 server %d: %s", n, line:sub(1, 160))) end
		end
	end
end
print("QQ P4 DONE")
