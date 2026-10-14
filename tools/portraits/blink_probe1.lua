-- blink_probe1.lua - PLAY TEST, run in the CLIENT context (execute_luau on the client, the phone emulator). READ-ONLY: it hooks
-- signals and prints "QQ BLINK t=<seconds> ..." lines for PROBE_SECS, then disconnects. Changes nothing, installs nothing.
-- Job 96 (Shannon: "the portraits in the French section have the characters in them continuously blinking in and out on mobile
-- and VR, but not on desktop"; "slow, every few seconds"; "only the character, not the easel or setting"). How the gallery is
-- drawn (village/build_portraits.lua, PortraitClient): the server's Picture (a SurfaceGui with a ViewportFrame Portrait3D and the
-- sitter model in its World) is the template; the client clones the whole Picture into PlayerGui.PortraitGalleryPictures (a
-- "mount") and swaps the mount for a fresh clone on many triggers (RenderToken / GalleryModelKey attributes, any GuiObject's
-- Visible / Image / Size / Position, children added to the models folder, ...). The frame and background are plain images and
-- draw at once; the sitter is a ViewportFrame that needs a frame or more to render, so on a slow device every swap shows as the
-- character blinking out and in. This probe logs every REMOUNT and every candidate trigger with a timestamp, so the one that
-- fires every few seconds can be named. Send every QQ BLINK line unchanged.
local PROBE_SECS = 90
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local G = workspace:WaitForChild("PortraitGallery", 30)
local slots = G and G:WaitForChild("Slots", 30)
local models = RS:WaitForChild("PortraitGalleryModels", 30)
local pics = pg:WaitForChild("PortraitGalleryPictures", 30)
if not (slots and models and pics) then print("QQ BLINK ABORT: gallery, models folder or PlayerGui.PortraitGalleryPictures not found") return end
local t0, n, cons = os.clock(), 0, {}
local function say(fmt, ...) n += 1; print(string.format("QQ BLINK t=%6.2f " .. fmt, os.clock() - t0, ...)) end
local function on(signal, fn) local c = signal:Connect(fn); table.insert(cons, c); return c end
local function slotOf(o) local s = o; while s and s.Parent ~= slots do s = s.Parent end; return s and s.Name or "?" end
local function mountLine(c)
	local vp = c:FindFirstChild("Portrait3D"); local w = vp and vp:FindFirstChild("World"); local img = c:FindFirstChild("Portrait")
	return string.format("viewport %s, sitter parts %d, image %s/%s", vp and tostring(vp.Visible) or "-", w and #w:GetDescendants() or 0, img and tostring(img.Visible) or "-", img and ((img.Image ~= "") and "set" or "none") or "-")
end
-- 1. the mounts in PlayerGui (one per slot): every swap is a REMOUNT
local mountCount = 0
on(pics.ChildAdded, function(c) task.defer(function() mountCount += 1; say("REMOUNT %s (%s)", c.Name, mountLine(c)) end) end)
on(pics.ChildRemoved, function(c) say("unmount %s", c.Name) end)
-- 2. the triggers on the server templates
local WATCH = {Visible = true, Image = true, Size = true, Position = true}
local nCanvas = 0
for _, c in ipairs(slots:GetDescendants()) do
	if c.Name == "Canvas" and c:IsA("BasePart") then
		nCanvas += 1
		local picture = c:FindFirstChild("Picture"); local vp = picture and picture:FindFirstChild("Portrait3D")
		local slot = slotOf(c)
		if vp then
			on(vp:GetAttributeChangedSignal("RenderToken"), function() say("trigger %s RenderToken = %s", slot, tostring(vp:GetAttribute("RenderToken"))) end)
			on(vp:GetAttributeChangedSignal("GalleryModelKey"), function() say("trigger %s GalleryModelKey = %s", slot, tostring(vp:GetAttribute("GalleryModelKey"))) end)
			local w = vp:FindFirstChild("World")
			if w then on(w.ChildAdded, function(o) say("template %s World child added %s", slot, o.Name) end); on(w.ChildRemoved, function(o) say("template %s World child removed %s", slot, o.Name) end) end
		end
		if picture then
			for _, obj in ipairs(picture:GetDescendants()) do
				if obj:IsA("GuiObject") then on(obj.Changed, function(p) if WATCH[p] then say("trigger %s %s.%s -> %s", slot, obj.Name, p, tostring(obj[p])) end end) end
			end
			on(picture.DescendantAdded, function(o) say("trigger %s template descendant added %s (%s)", slot, o.Name, o.ClassName) end)
			on(picture.DescendantRemoving, function(o) say("trigger %s template descendant removing %s (%s)", slot, o.Name, o.ClassName) end)
		end
	end
end
-- 3. the models folder (any change here re-schedules every canvas)
on(models.ChildAdded, function(m) say("models child added %s", m.Name) end)
on(models.ChildRemoved, function(m) say("models child removed %s", m.Name) end)
on(models.DescendantAdded, function(o) local top = o; while top.Parent and top.Parent ~= models do top = top.Parent end; say("models descendant added %s under %s", o.Name, top.Name) end)
on(models.DescendantRemoving, function(o) local top = o; while top.Parent and top.Parent ~= models do top = top.Parent end; say("models descendant removing %s under %s", o.Name, top.Name) end)
-- 4. streaming of the slots themselves
on(slots.DescendantAdded, function(o) if o.Name == "Canvas" then say("stream IN canvas of %s", slotOf(o)) end end)
on(slots.DescendantRemoving, function(o) if o.Name == "Canvas" then say("stream OUT canvas of %s", slotOf(o)) end end)
-- 5. a heartbeat every 10 s
local mem0 = Stats:GetTotalMemoryUsageMb()
say("START: %d canvases, %d models, %d mounts, memory %.0f MB, device %s", nCanvas, #models:GetChildren(), #pics:GetChildren(), mem0, tostring(game:GetService("UserInputService").TouchEnabled and "touch" or "mouse"))
task.spawn(function()
	for i = 1, math.floor(PROBE_SECS / 10) do
		task.wait(10)
		say("heartbeat %d: %d mounts in PlayerGui, %d remounts so far, memory %.0f MB", i, #pics:GetChildren(), mountCount, Stats:GetTotalMemoryUsageMb())
	end
	for _, c in ipairs(cons) do c:Disconnect() end
	print(string.format("QQ BLINK END (%d lines, %d remounts in %d s)", n, mountCount, PROBE_SECS))
end)
