-- Presentation layer only; authorization and travel are checked on the server.
local player=game:GetService('Players').LocalPlayer
if player.UserId==9611145467 then return end
local function hide(instance)
	if instance:IsA('BasePart') then instance.LocalTransparencyModifier=1;instance.CastShadow=false
	elseif instance:IsA('Decal') or instance:IsA('Texture') then instance.Transparency=1
	elseif instance:IsA('SurfaceGui') or instance:IsA('BillboardGui') or instance:IsA('ProximityPrompt') or instance:IsA('ParticleEmitter') or instance:IsA('Beam') or instance:IsA('Trail') or instance:IsA('Light') or instance:IsA('Clouds') or instance:IsA('Smoke') or instance:IsA('Fire') or instance:IsA('Sparkles') or instance:IsA('Highlight') then instance.Enabled=false --[[JAPANFIX1]]
	elseif instance:IsA('Sound') then instance.Volume=0 end
end
local function hook(map)
	map.DescendantAdded:Connect(hide)
	for i,instance in ipairs(map:GetDescendants()) do hide(instance);if i%1000==0 then task.wait() end end
	-- Existing visibility scripts can change parts when a player changes districts.
	local watched=setmetatable({},{__mode='k'})
	local function enforce(instance)
		if watched[instance] then return end
		local property,expected
		if instance:IsA('BasePart') then property='LocalTransparencyModifier';expected=1
		elseif instance:IsA('Decal') or instance:IsA('Texture') then property='Transparency';expected=1
		elseif instance:IsA('SurfaceGui') or instance:IsA('BillboardGui') or instance:IsA('ProximityPrompt') or instance:IsA('ParticleEmitter') or instance:IsA('Beam') or instance:IsA('Trail') or instance:IsA('Light') or instance:IsA('Clouds') or instance:IsA('Smoke') or instance:IsA('Fire') or instance:IsA('Sparkles') or instance:IsA('Highlight') then property='Enabled';expected=false
		elseif instance:IsA('Sound') then property='Volume';expected=0 end
		if not property then return end
		watched[instance]=true
		instance:GetPropertyChangedSignal(property):Connect(function()
			if instance[property]~=expected then instance[property]=expected end
		end)
	end
	map.DescendantAdded:Connect(enforce)
	for i,instance in ipairs(map:GetDescendants()) do enforce(instance);if i%1000==0 then task.wait() end end
end
local map=workspace:FindFirstChild('JapanMap')
if map then task.spawn(hook,map) end
workspace.ChildAdded:Connect(function(child) if child.Name=='JapanMap' then task.spawn(hook,child) end end)

