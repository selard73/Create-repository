-- churchfix1.lua (Oct 22 2026): Shannon: "In the church at the top of the windows there is that flick problem on the vr".
-- The church (JapanMap.Church.Shell) is a Blender shell, one MeshPart per material; the three stained-glass meshes
-- (Church_Glass_Blue / Red / Gold) each span EVERY window and were all Glass at Transparency 0.3 with near-identical centres,
-- so Roblox's transparency sort flipped their order frame to frame where the gold arch ring and the red panes overlap the
-- blue pane (only 0.02 apart) - the flicker at the window tops, worst in VR. Rays from inside also found opaque faces sharing
-- planes: the roof's gable faces 0.005 / 0.025 from the plaster on +x, timber beam ends flush with the roof's +x face, the
-- -z timber trim 0.01 proud of the plaster.
-- Fix: the gold ring and the red panes become OPAQUE stained glass (one transparent sheet left = nothing to mis-sort), and
-- each whole mesh is nudged by an amount read off the measured gaps so nothing lands on another face. Old values in
-- ChurchFix1WasCFrame / ChurchFix1WasTransparency. Re-runnable (offsets always from the originals). "QQ CHURCHFIX1".
-- Verified Oct 22: 47k rays over all four walls, 6 near-coincident rays left (< 0.012), all on the -x corner post low on the +z
-- face (x 6099, y 4-10) - pea-sized specks, not the window tops; the ray probe is tools/japan/landfix1/churchfix1_probe notes
-- in HANDOFF_2026-10-24.md.
local shell = workspace.JapanMap.Church.Shell
local moves = {
	{"Church_Glass_Gold", Vector3.new(0, 0, 0.05)},      -- 0.02 outside the blue -> 0.07
	{"Church_Glass_Red",  Vector3.new(0, 0, -0.03)},     -- 0.02 inside the blue -> 0.05; still 0.03 clear of the timber behind it
	{"Church_Roof",       Vector3.new(0, 0.075, 0)},     -- UP: its gable faces sat 0.005 / 0.025 from the plaster on +x (sideways nudges
	                                                     -- kept landing on the sloped underside; a grid test found 0.075 up = 0 hits)
	{"Church_Timber",     Vector3.new(0.035, 0, -0.03)}, -- beam ends flush with the roof's +x face -> 0.023 beyond it; -z corner post 0.01 proud -> 0.04
}
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before churchfix1") end)
local out = {}
for _, mv in ipairs(moves) do
	local p = shell[mv[1]]
	if p:GetAttribute("ChurchFix1WasCFrame") == nil then p:SetAttribute("ChurchFix1WasCFrame", p.CFrame) end
	p.CFrame = p:GetAttribute("ChurchFix1WasCFrame") + mv[2]
	table.insert(out, string.format("QQ CHURCHFIX1 %s offset (%.3f, %.3f, %.3f)", mv[1], mv[2].X, mv[2].Y, mv[2].Z))
end
for _, n in ipairs({"Church_Glass_Gold", "Church_Glass_Red"}) do
	local p = shell[n]
	if p:GetAttribute("ChurchFix1WasTransparency") == nil then p:SetAttribute("ChurchFix1WasTransparency", p.Transparency) end
	p.Transparency = 0
	table.insert(out, "QQ CHURCHFIX1 " .. n .. " now opaque")
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after churchfix1") end)
return table.concat(out, "\n")
