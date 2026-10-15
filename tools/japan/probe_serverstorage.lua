-- probe_serverstorage.lua - READ-ONLY (Studio EDIT): what fills ServerStorage. survey104 counted 318,798 descendants there, of which
-- the Japan folders are only 22,263 - the rest is in the place file and in every server's memory too. Lists the 40 biggest children
-- by descendant count and the total. Prints "QQ SS ..." lines; send them unchanged.
local SS = game:GetService("ServerStorage")
local rows = {}
local total = 0
for _, c in ipairs(SS:GetChildren()) do
	local n = #c:GetDescendants()
	total += n + 1
	table.insert(rows, {c = c, n = n})
end
table.sort(rows, function(a, b) return a.n > b.n end)
print(string.format("QQ SS ServerStorage: %d children, %d descendants in all", #rows, total))
for i, r in ipairs(rows) do
	if i > 40 then print(string.format("QQ SS   ... and %d more children (%d descendants)", #rows - 40, (function() local s = 0; for j = 41, #rows do s += rows[j].n end; return s end)())) break end
	local sub = ""
	if r.c:IsA("Folder") and r.n > 2000 then
		local kids = {}
		for _, k in ipairs(r.c:GetChildren()) do table.insert(kids, {k = k, n = #k:GetDescendants()}) end
		table.sort(kids, function(a, b) return a.n > b.n end)
		local l = {}
		for j = 1, math.min(5, #kids) do table.insert(l, kids[j].k.Name .. " " .. kids[j].n) end
		sub = " (" .. #kids .. " children; biggest: " .. table.concat(l, ", ") .. ")"
	end
	print(string.format("QQ SS   %s (%s): %d descendants%s", r.c.Name, r.c.ClassName, r.n, sub))
end
print("QQ SS END")
