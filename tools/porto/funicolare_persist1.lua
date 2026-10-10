-- funicolare_persist1.lua (Studio EDIT mode; re-runnable). Job 75.
-- Shannon (Oct 10, VR): "you can see the rails only from the funicolare when you are up in the balloon, not the whole
-- funicolare". The place streams (StreamingEnabled): from the balloon (240-600 studs off) the 375-stud rails and haul
-- cables still reach into range, the cars, stations, sleepers and piers do not. ModelStreamingMode Atomic on the whole
-- "15 Funicolare" model: whenever any part of it is in range (the rails always are from the balloon) the whole model comes
-- in, and it leaves only as a whole (the show balloons use the same mode). Not Persistent: that would keep its 288 parts and
-- the cars' every-frame moves on every client in every map, Quest headsets included (review).
-- Undo: set ModelStreamingMode back to the value kept in the model's attribute StreamingWas. Nothing else changes; no publish.
local town = workspace:FindFirstChild("PortoNocciola")
local M = town and town:FindFirstChild("15 Funicolare")
if not M or not M:IsA("Model") then print("QQ FUNI ABORT: workspace.PortoNocciola['15 Funicolare'] (a Model) not found") return end
local n = 0; for _, d in ipairs(M:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
if M:GetAttribute("StreamingWas") == nil then M:SetAttribute("StreamingWas", M.ModelStreamingMode.Name) end
M.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
print(string.format("QQ FUNI DONE: %s is %s (%d parts; was %s); parent %s is %s", M:GetFullName(), M.ModelStreamingMode.Name, n,
	tostring(M:GetAttribute("StreamingWas")), town.Name, town:IsA("Model") and town.ModelStreamingMode.Name or town.ClassName))
