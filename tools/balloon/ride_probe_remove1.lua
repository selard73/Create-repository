-- ride_probe_remove1.lua (Studio EDIT mode): takes the job 79 readout out again - the RideProbe script, the Probe attribute
-- and the RideProbe_* tags on the sentinel parts. Prints QQ PROBE GONE.
local CS = game:GetService("CollectionService")
local bf = workspace:FindFirstChild("BalloonField")
local removed = 0
for _, label in ipairs({"Landscape", "Hillside", "Coast", "Planting"}) do
	local tag = "RideProbe_" .. label
	for _, o in ipairs(CS:GetTagged(tag)) do CS:RemoveTag(o, tag); removed += 1 end
end
if bf then local s = bf:FindFirstChild("RideProbe"); if s then s:Destroy() end; bf:SetAttribute("Probe", nil) end
print(string.format("QQ PROBE GONE: script removed, %d tags removed", removed))
