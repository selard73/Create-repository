-- darkrockfix1.lua (runner 7, Oct 16 2026): the BLACK rocks by the stream. Cause: their Blender meshes carry dark vertex colours
-- (luminance ~0.13-0.27) that Roblox multiplies over colour, material, variant and texture. The same meshes rebuilt WITHOUT vertex
-- colours (tools/japan/rocks/rebuild_dark_meshes.py, same mesh-space size) sit in ServerStorage.JapanGardenKit.dark_rock_fix.
-- For each one: the original MeshPart is cloned to ServerStorage.HudBackup.DarkRockOriginals (once), then old:ApplyMesh(new) swaps
-- only the geometry - CFrame, Size, Rock + JM_PhotographicRock and colour stay. Re-runnable (DarkRockFixed attribute). Output "QQ DARKROCK1".
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local FIX = KIT and KIT:FindFirstChild("dark_rock_fix")
local ST = workspace:FindFirstChild("JapanMap") and workspace.JapanMap:FindFirstChild("BlenderScenery") and workspace.JapanMap.BlenderScenery:FindFirstChild("Sculpted terrain")
if not (FIX and ST) then print("QQ DARKROCK1 ABORT: JapanGardenKit.dark_rock_fix or JapanMap.BlenderScenery['Sculpted terrain'] missing") return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bk = hb:FindFirstChild("DarkRockOriginals") or Instance.new("Folder"); bk.Name = "DarkRockOriginals"; bk.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before darkrockfix1") end)
local done = 0
for _, new in ipairs(FIX:GetDescendants()) do
	if new:IsA("MeshPart") then
		local old = ST:FindFirstChild(new.Name)
		if not (old and old:IsA("MeshPart")) then print("QQ DARKROCK1 " .. new.Name .. ": no original in Sculpted terrain - skipped")
		elseif old:GetAttribute("DarkRockFixed") then print("QQ DARKROCK1 " .. new.Name .. ": already fixed - skipped")
		else
			local ds = (old.Size - new.Size).Magnitude
			if ds > 0.05 then print(string.format("QQ DARKROCK1 %s: size differs by %.3f (old %s, new %s) - skipped", new.Name, ds, tostring(old.Size), tostring(new.Size)))
			else
				if not bk:FindFirstChild(old.Name) then local c = old:Clone(); c.Parent = bk end
				local oldMesh = old.MeshId
				local ok, err = pcall(function() old:ApplyMesh(new) end)
				if ok then
					old:SetAttribute("DarkRockFixed", true); old:SetAttribute("DarkRockOldMeshId", oldMesh); done += 1
					print(string.format("QQ DARKROCK1 %s: mesh swapped (%s -> %s), size %s, %s / '%s' kept", old.Name, oldMesh, old.MeshId, tostring(old.Size), old.Material.Name, old.MaterialVariant))
				else print("QQ DARKROCK1 " .. old.Name .. ": ApplyMesh FAILED " .. tostring(err)) end
			end
		end
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after darkrockfix1") end)
print(string.format("QQ DARKROCK1 DONE: %d meshes swapped to the colour-free copies; originals in HudBackup.DarkRockOriginals", done))
