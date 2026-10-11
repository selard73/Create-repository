#!/usr/bin/env python3
"""SquirrelBubble vr2 from vr1 (Oct 11 2026): Bubble.talking(), newest-wins, and the screen bubble drawn BESIDE the speaker
(Shannon: "to the side of the squirrels, so you know they are saying it but it does not cover them in any way"): placed off
the speaker part's projected box, on the side with room (chosen once per bubble), never clamped into the speaker, kept under
the HUD row and, on phones, clear of the HUD column at the right edge; `current` is a plain table cleared explicitly."""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
v = (HERE / "SquirrelBubble.module.vr1.lua").read_text(encoding="utf-8")
assert len(v) == 8415
def rep(old, new):
    global v
    assert v.count(old) == 1, old[:70]; v = v.replace(old, new)
rep("-- ScreenGui pinned to the speaker every frame (world-space GUIs get tone-mapped and looked cream), a faint shadow, a\n",
    "-- ScreenGui pinned beside the speaker every frame (world-space GUIs get tone-mapped and looked cream), a faint shadow, a\n")
rep('local current = setmetatable({}, {__mode = "k"})                               -- speaker part -> its bubble (a new line replaces the old)\n',
'''local current = {}                                                             -- speaker part -> its bubble (a new line replaces the old; cleared when it goes)
local TOP_GUARD = 24                                                           -- inset-space px kept clear under the HUD row
local UIS = game:GetService("UserInputService")
local PHONE = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local COLUMN_GUARD, COLUMN_BOTTOM = PHONE and 62 or 0, 170                    -- phones: the HUD column at the right edge (x -58..-10, inset y to 166)
function Bubble.talking()                                                      -- is any bubble up, on a screen or in VR?
	for _, b in pairs(current) do if b.Parent then return true end end
	return false
end
''')
rep('\tif not (anchor and g and type(text) == "string" and text ~= "") then return nil end\n',
    '\tif not (anchor and g and type(text) == "string" and text ~= "") then return nil end\n\tfor a, b in pairs(current) do if a ~= anchor then if b.Parent then b:Destroy() end; current[a] = nil end end   -- (newest wins: one bubble at a time; the ambient chatter never starts over another, so this only cuts a chatter line short for a scripted one)\n')
# VR: clear the entry when the billboard goes
rep("\ttask.delay(secs, function() if bg.Parent then bg:Destroy() end end)\n\treturn bg\n",
    "\ttask.delay(secs, function() if bg.Parent then bg:Destroy() end; if current[anchor] == bg then current[anchor] = nil end end)\n\treturn bg\n")
# screen: the frame hangs by its bottom-left corner, placed each frame
rep('\tlocal root = Instance.new("Frame"); root.Name = "SquirrelBubble"; root.AnchorPoint = Vector2.new(0.5, 0.5)\n',
    '\tlocal root = Instance.new("Frame"); root.Name = "SquirrelBubble"; root.AnchorPoint = Vector2.new(0, 1)   -- (hung by its bottom-left corner, placed beside the speaker every frame)\n')
rep('''	-- pinned to the speaker: up and to the right in camera space, like a BillboardGui with an ExtentsOffset, but drawn flat
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not (root.Parent and anchor.Parent) then if conn then conn:Disconnect() end; return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local ext = anchor.Size
		local world = anchor.Position + Vector3.new(0, 1.5, 0) + cam.CFrame.RightVector * (0.9 * ext.X / 2) + cam.CFrame.UpVector * (1.0 * ext.Y / 2)
		local p = cam:WorldToScreenPoint(world)
		local dist = (world - cam.CFrame.Position).Magnitude
		root.Visible = p.Z > 0 and dist <= MAX_DIST
		root.Position = UDim2.fromOffset(p.X, p.Y)
	end)
''', '''	-- beside the speaker: the speaker part's box is projected to the screen each frame and the bubble hangs off its right
	-- side (or its left side, mirrored, when the right has no room), its bottom at the box's top when that fits under the
	-- HUD row, else alongside at body level. The side is picked once per bubble and only changes when it stops fitting and
	-- the other side would. The tail sits a third of the way in from the speaker's side, so when the bubble is wholly above
	-- the box it leans over the head by that much; alongside, it keeps fully clear. Never clamped into the speaker: with no
	-- room on either side it overhangs the screen's edge instead.
	local conn, side, flipped = nil, nil, false
	conn = RunService.RenderStepped:Connect(function()
		if not (root.Parent and anchor.Parent) then if conn then conn:Disconnect() end; return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local cf, hs = anchor.CFrame, anchor.Size / 2
		local x0, x1, y0, n = math.huge, -math.huge, math.huge, 0
		for i = 0, 7 do
			local c = cf * Vector3.new(i % 2 == 0 and -hs.X or hs.X, math.floor(i / 2) % 2 == 0 and -hs.Y or hs.Y, i < 4 and -hs.Z or hs.Z)
			local q = cam:WorldToScreenPoint(c)
			if q.Z > 0 then x0, x1, y0, n = math.min(x0, q.X), math.max(x1, q.X), math.min(y0, q.Y), n + 1 end
		end
		local dist = (anchor.Position - cam.CFrame.Position).Magnitude
		root.Visible = n > 0 and dist <= MAX_DIST
		if n == 0 then return end
		local gs, w, h = g.AbsoluteSize, root.AbsoluteSize.X, root.AbsoluteSize.Y
		local y = math.clamp(y0 - 2, TOP_GUARD + h, math.max(TOP_GUARD + h, gs.Y - 4))
		local lean = 0.33 * w * math.clamp(1 - (y - (y0 - 2)) / math.max(1, 0.25 * h), 0, 1)   -- (full lean when wholly above the box, none once pushed down alongside it)
		local rightEdge = gs.X - 4 - ((COLUMN_GUARD > 0 and y - h < COLUMN_BOTTOM) and COLUMN_GUARD or 0)
		local xr, xl = x1 + 6 - lean, x0 - 6 + lean - w                     -- the left edge on the right side / on the left side
		local roomR, roomL = rightEdge - xr - w, xl - 4
		if side == nil or (side == 1 and roomR < 0 and roomL >= 0) or (side == -1 and roomL < 0 and roomR >= 0) then
			side = (roomR >= 0 or roomR >= roomL) and 1 or -1
		end
		root.Position = UDim2.fromOffset(side == 1 and xr or xl, y)
		local flip = side == -1
		if flip ~= flipped then
			flipped = flip
			for _, i in ipairs({shadow, paper}) do i.ImageRectOffset = flip and Vector2.new(440, 0) or Vector2.new(0, 0); i.ImageRectSize = flip and Vector2.new(-440, 330) or Vector2.new(0, 0) end
		end
	end)
''')
rep("\ttask.delay(secs, function() if conn then conn:Disconnect() end; if root.Parent then root:Destroy() end end)\n\treturn root\n",
    "\ttask.delay(secs, function() if conn then conn:Disconnect() end; if root.Parent then root:Destroy() end; if current[anchor] == root then current[anchor] = nil end end)\n\treturn root\n")
(HERE / "SquirrelBubble.module.vr2.lua").write_text(v, encoding="utf-8", newline="\n")
print("SquirrelBubble.module.vr2.lua written:", len(v))
