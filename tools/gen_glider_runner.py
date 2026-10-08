# gen_glider_runner.py TAG -> run_glider.lua: the live shop patch (glider row, server rule, OpenAt) + domaine/build_glider.lua
import sys

TAG = sys.argv[1] if len(sys.argv) > 1 else "v1"
build = open(r"C:\Users\slard\roblox-props\domaine\build_glider.lua", encoding="utf-8").read()
assert "]===]" not in build and "[===[" not in build

SHOP = r'''
-- ---- the Acorn Store: the glider's row, its rule on the server, and a way to open the store at a row ----
local out = {}
local Shop = workspace:FindFirstChild("Shop")
if not Shop then warn("QQ GLIDER no workspace.Shop - nothing changed") return end
local srv, cli = Shop:FindFirstChild("ShopServer"), Shop:FindFirstChild("ShopClient")
if not (srv and cli) then warn("QQ GLIDER the shop scripts are missing - nothing changed") return end
local function once(src, anchor, add, label)
	local i, j = src:find(anchor, 1, true)
	if not i then return nil, label .. ": anchor not found" end
	if src:find(anchor, j + 1, true) then return nil, label .. ": anchor found twice" end
	return src:sub(1, j) .. add .. src:sub(j + 1), label
end
local s1, s2 = srv.Source, cli.Source
local why
if not s1:find('glider     = {once = true', 1, true) then
	s1, why = once(s1, [===[	backpack   = {once = true},]===], [===[
	-- the hang glider takes off from the Sandstone Climb's summit in the Chateau, so it is sold once the Chateau is open
	-- to you (like the zipline handle); bought once and kept - the ramp checks Item_glider (workspace.HangGlider)
	glider     = {once = true, needsArea = "village"},]===], "server rule")
	if not s1 then warn("QQ GLIDER " .. why .. " - nothing changed") return end
	table.insert(out, why)
end
if not s2:find('{id = "glider"', 1, true) then
	s2, why = once(s2, [===[	{id = "backpack",   name = "Backpack",        blurb = "Carry your things, and your favourite squirrel, on your back.", once = true},]===], [===[
	{id = "glider",     name = "Hang glider",     blurb = "Yours to keep. Take off from the top of the Sandstone Climb and glide into the Rue.", once = true},]===], "store row")
	if not s2 then warn("QQ GLIDER " .. why .. " - nothing changed") return end
	table.insert(out, why)
end
if not s2:find("OPEN AT A ROW", 1, true) then
	s2, why = once(s2, [===[shade.MouseButton1Click:Connect(function() setOpen(false) end)]===], [===[


-- OPEN AT A ROW: something in the world can open the store at its own row (the hang glider's ramp, for somebody who has
-- no glider yet: "see it in the Acorn Store"). workspace.Shop.OpenAt:Fire(id) - the row scrolls into view and its edge
-- glows gold for a moment.
task.spawn(function()
	local openAt = F:WaitForChild("OpenAt", 20)
	if not openAt then return end
	openAt.Event:Connect(function(id)
		if F:GetAttribute("Open") == false then return end
		if not gui.Enabled then setOpen(true) end
		local rec = rows[id]
		if not rec then return end
		local index = 1
		for i, item in ipairs(ITEMS) do if item.id == id then index = i end end
		list.CanvasPosition = Vector2.new(0, math.max(0, (index - 1) * 94 - 6))      -- rows are 84 tall with 10 between
		local st = rec.frame:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = GOLD; st.Thickness = 3; st.Transparency = 0
			task.delay(1.8, function() st.Color = SLOT_EDGE; st.Thickness = 2; st.Transparency = 0.45 end)
		end
	end)
end)]===], "open-at hook")
	if not s2 then warn("QQ GLIDER " .. why .. " - nothing changed") return end
	table.insert(out, why)
end
local f1, e1 = loadstring(s1); local f2, e2 = loadstring(s2)
if not f1 or not f2 then warn("QQ GLIDER COMPILE " .. tostring(e1) .. " | " .. tostring(e2) .. " - nothing changed") return end
srv.Source = s1; cli.Source = s2
if not Shop:FindFirstChild("OpenAt") then local e = Instance.new("BindableEvent"); e.Name = "OpenAt"; e.Parent = Shop; table.insert(out, "OpenAt made") end
Shop:SetAttribute("Price_glider", 1000); Shop:SetAttribute("Sell_glider", true)
table.insert(out, "price " .. tostring(Shop:GetAttribute("Price_glider")) .. ", on sale " .. tostring(Shop:GetAttribute("Sell_glider")))
'''

runner = (
    "-- run_glider.lua " + TAG + " (EDIT mode): the hang glider - the Acorn Store's glider row + rule + OpenAt, then the ramp, arch,\n"
    "-- display glider, windsock and the GliderServer/GliderClient (domaine/build_glider.lua)\n"
    'if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end\n'
    + SHOP +
    "\nlocal build = (function()\n" + build + "\nend)()\n"
    "local ok, res = pcall(build, {})\n"
    'if not ok then warn("QQ GLIDER BUILD FAILED " .. tostring(res)) return end\n'
    'for _, n in ipairs({"GliderServer", "GliderClient"}) do\n'
    '\tlocal f, e = loadstring(res[n].Source)\n'
    '\ttable.insert(out, n .. (f and " compiles" or (" COMPILE ERROR " .. tostring(e))))\n'
    'end\n'
    'warn("QQ GLIDER ' + TAG + ' done - " .. table.concat(out, ", ") .. " | " .. tostring(res and res:GetFullName()))\n'
)
open(r"C:\Users\slard\AppData\Local\Temp\claude\C--Users-slard\580647d7-7ff4-4cf5-b0fd-5f0547bee56a\scratchpad\run_glider.lua", "w", encoding="utf-8", newline="\n").write(runner)
print("run_glider.lua", TAG, len(runner), "chars")
