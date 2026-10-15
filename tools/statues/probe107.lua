-- probe107.lua - READ-ONLY (Studio EDIT or a play test; changes nothing). Job 107 (Shannon, Oct 15 2026: "the statue renders ... giving
-- the statues 2 arms on the right hand side, one that holds up the acorn and the original arm the player avatar has"). Two possible
-- causes: (a) two statue models standing on the same spot (one posed, one with its arms down - every other part overlaps exactly, so
-- only the raised arm shows twice), or (b) one model carrying two right arms (an accessory or a worn sleeve left at the side when the
-- arm was aimed). Lists every model that has a RightHand under workspace and ReplicatedStorage.HallStatues: where it stands, how many
-- RightHand / RightUpperArm parts it holds, whether its right hand is raised, and flags models standing within 2.5 studs of another.
-- Prints "QQ ARM ..." lines; send them unchanged.
local RS = game:GetService("ReplicatedStorage")
local out = {}
local function say(fmt, ...) table.insert(out, "QQ ARM " .. string.format(fmt, ...)) end
local roots = {workspace}
local hs = RS:FindFirstChild("HallStatues"); if hs then table.insert(roots, hs) end
local statues = {}
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "RightHand" then
			local m = d:FindFirstAncestorOfClass("Model")
			if m and not statues[m] then
				local hum = m:FindFirstChildOfClass("Humanoid")
				local isPlayer = hum and game:GetService("Players"):GetPlayerFromCharacter(m)
				if not isPlayer then
					local rh, rua, lh, heads, parts = 0, 0, 0, 0, 0
					for _, p in ipairs(m:GetDescendants()) do
						if p:IsA("BasePart") then
							parts += 1
							if p.Name == "RightHand" then rh += 1 elseif p.Name == "RightUpperArm" then rua += 1 elseif p.Name == "LeftHand" then lh += 1 elseif p.Name == "Head" then heads += 1 end
						end
					end
					local head = m:FindFirstChild("Head")
					local cf, size = m:GetBoundingBox()
					statues[m] = {m = m, pos = cf.Position, size = size, rh = rh, rua = rua, lh = lh, heads = heads, parts = parts,
						raised = head and (d.Position.Y > head.Position.Y) or false, anchored = d.Anchored, hum = hum ~= nil}
				end
			end
		end
	end
end
local list = {}
for _, s in pairs(statues) do table.insert(list, s) end
table.sort(list, function(a, b) return a.m:GetFullName() < b.m:GetFullName() end)
say("models with a RightHand (players excluded): %d", #list)
for i, s in ipairs(list) do
	local near = {}
	for j, t in ipairs(list) do
		if i ~= j and (s.pos - t.pos).Magnitude < 2.5 then table.insert(near, t.m:GetFullName()) end
	end
	say("%s: %d parts; RightHand x%d, RightUpperArm x%d, LeftHand x%d, Head x%d; right hand %s; %s%s; at (%.0f,%.0f,%.0f) box %.0fx%.0fx%.0f%s",
		s.m:GetFullName(), s.parts, s.rh, s.rua, s.lh, s.heads, s.raised and "RAISED" or "down", s.anchored and "anchored" or "UNANCHORED", s.hum and ", humanoid" or "",
		s.pos.X, s.pos.Y, s.pos.Z, s.size.X, s.size.Y, s.size.Z, #near > 0 and ("  <-- SHARES ITS SPOT WITH " .. table.concat(near, "; ")) or "")
	if s.rh > 1 or s.rua > 1 then
		for _, p in ipairs(s.m:GetDescendants()) do
			if p:IsA("BasePart") and (p.Name == "RightHand" or p.Name == "RightUpperArm" or p.Name == "RightLowerArm") then
				say("    %s under %s at (%.1f,%.1f,%.1f) size %s%s", p.Name, p.Parent and p.Parent.Name or "?", p.Position.X, p.Position.Y, p.Position.Z, tostring(p.Size), p:GetAttribute("BoutiqueSlot") and " (boutique)" or "")
			end
		end
	end
end
for _, l in ipairs(out) do print(l) end
print(string.format("QQ ARM END (%d lines)", #out))
return table.concat(out, "\n")
