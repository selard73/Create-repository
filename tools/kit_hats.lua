-- kit_hats.lua v1 (EDIT mode): the imported hats (workspace.Hats, from village/hats/Hats.obj) become the template kit
-- ReplicatedStorage.HatKit (both the server, which dresses players, and each client, for the try-on and the pictures,
-- need the meshes)
if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end
local RS = game:GetService("ReplicatedStorage")
local imp = workspace:FindFirstChild("Hats")
if not imp then warn("QQ HATKIT no imported workspace.Hats - nothing changed") return end
local kit = RS:FindFirstChild("HatKit")
if not kit then kit = Instance.new("Folder"); kit.Name = "HatKit"; kit.Parent = RS end
local n, names = 0, {}
for _, p in ipairs(imp:GetDescendants()) do
	if p:IsA("MeshPart") then
		local old = kit:FindFirstChild(p.Name); if old then old:Destroy() end
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
		p.Material = Enum.Material.Fabric; p.Color = Color3.fromRGB(200, 200, 200)
		p.Parent = kit
		n += 1; table.insert(names, string.format("%s %.2f,%.2f,%.2f", p.Name, p.Size.X, p.Size.Y, p.Size.Z))
	end
end
imp:Destroy()
table.sort(names)
warn("QQ HATKIT v1 done - " .. n .. " pieces: " .. table.concat(names, " | "))
