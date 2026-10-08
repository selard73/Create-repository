-- run_solid.lua v1 (EDIT mode): the squirrels are solid (Shannon, Sep 27: "I should not be able to walk through the
-- squirrels which I can, they should be solid") - every SquirrelSetup made each squirrel CanCollide false when the server
-- started; now true (clicking one to find it works the same)
if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end
local OLD = "p.Anchored = true; p.CanCollide = false; p.CanTouch = true"
local NEW = "p.Anchored = true; p.CanCollide = true; p.CanTouch = true"
local out = {}
for _, root in ipairs({workspace, game:GetService("ServerScriptService"), game:GetService("ServerStorage"), game:GetService("ReplicatedStorage")}) do
	for _, s in ipairs(root:GetDescendants()) do
		if s:IsA("LuaSourceContainer") and s.Source:find(OLD, 1, true) then
			local src, n = s.Source, 0
			local i, j = src:find(OLD, 1, true)
			while i do src = src:sub(1, i - 1) .. NEW .. src:sub(j + 1); n += 1; i, j = src:find(OLD, i + #NEW, true) end
			local f, e = loadstring(src)
			if f then s.Source = src; table.insert(out, s:GetFullName() .. " x" .. n) else table.insert(out, s:GetFullName() .. " COMPILE ERROR " .. tostring(e)) end
		end
	end
end
warn("QQ SOLID v1 - " .. (#out > 0 and table.concat(out, ", ") or "no script had the line"))
