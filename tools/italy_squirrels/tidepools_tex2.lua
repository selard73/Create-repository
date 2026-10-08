-- Oct 4 2026 (tide pools round 2): the shelf read snow-white in Studio's light. A darker, warmer texture was re-imported as a
-- spare model; copy its TextureID onto the placed shelf and remove the spare. Also swap the flat seaweed fronds for thin
-- leaning strands. No asserts after the first edit: warn + return.
local cove=workspace.PortoNocciola['14 Lighthouse coast']:FindFirstChild('Cala della Sabbia and tide pools')
local F=cove and cove:FindFirstChild('Natural tide pools')
local shelf=F and F:FindFirstChild('TidePoolShelf')
local spare=workspace:FindFirstChild('tidepools_roblox')
local nshelf=spare and spare:FindFirstChild('TidePoolShelf',true)
if not (shelf and nshelf) then warn('QX2@ABORT missing',shelf,nshelf) return end
if nshelf.TextureID=='' or nshelf.TextureID==shelf.TextureID then warn('QX2@ABORT texture not new',nshelf.TextureID) return end
local oldTex=shelf.TextureID
shelf.TextureID=nshelf.TextureID
shelf:SetAttribute('PrevTexture',oldTex)
spare:Destroy()
-- seaweed: replace each 3-frond tuft with 5 thin strands
local L=F:FindFirstChild('Sea life')
local spots={}
for _,p in ipairs(L:GetChildren()) do
	if p.Name=='Seaweed frond' then
		local b=p.Position-p.CFrame.UpVector*(p.Size.Y/2)
		local key=string.format('%.0f,%.0f',b.X*2,b.Z*2)
		if not spots[key] then spots[key]=b end
		p:Destroy()
	end
end
local rng=Random.new(77)
local n=0
for _,b in pairs(spots) do
	for i=1,5 do
		local h=rng:NextNumber(0.45,0.95)
		local s=Instance.new('Part') s.Name='Seaweed strand' s.Shape=Enum.PartType.Cylinder
		s.Size=Vector3.new(h,0.07,0.07)
		s.Color=Color3.fromRGB(46,92,44):Lerp(Color3.fromRGB(104,126,52),rng:NextNumber())
		s.Material=Enum.Material.SmoothPlastic
		local tilt=CFrame.Angles(0,math.rad(rng:NextNumber(0,360)),0)*CFrame.Angles(math.rad(rng:NextNumber(10,35)),0,0)
		s.CFrame=CFrame.new(b+Vector3.new(rng:NextNumber(-0.15,0.15),0,rng:NextNumber(-0.15,0.15)))*tilt*CFrame.new(0,h/2,0)*CFrame.Angles(0,0,math.rad(90))
		s.Anchored=true s.CanCollide=false s.CanTouch=false s.CanQuery=false s.CastShadow=false s.Parent=L
		n+=1
	end
end
game:GetService('ChangeHistoryService'):SetWaypoint('Tide pools: darker rock, seaweed strands')
warn('QX2@OK texture',oldTex,'->',shelf.TextureID,'strands',n)
