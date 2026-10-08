-- kit_glider.lua v2 (EDIT mode): the imported (sunburst) sail (workspace.Glider, from domaine/glider/Glider.obj) becomes the hidden
-- template ServerStorage.GliderKit.GliderSail that the hang glider builds every glider from
if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local imp = workspace:FindFirstChild("Glider")
local sail = imp and imp:FindFirstChild("GliderSail", true)
if not sail then warn("QQ KIT no imported workspace.Glider.GliderSail - nothing changed") return end
local kit = SS:FindFirstChild("GliderKit")
if not kit then kit = Instance.new("Folder"); kit.Name = "GliderKit"; kit.Parent = SS end
local old = kit:FindFirstChild("GliderSail"); if old then old:Destroy() end
sail.Parent = kit
sail.Anchored = true; sail.CanCollide = false; sail.CanQuery = false; sail.CanTouch = false; sail.CastShadow = true
sail.Material = Enum.Material.Fabric
imp:Destroy()
warn(string.format("QQ KIT v2 done - sail %s | mesh %s | texture %s | %d tris? | kit has %d", tostring(sail.Size), sail.MeshId, sail.TextureID,
	0, #kit:GetChildren()))
