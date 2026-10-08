-- Oct 5 2026 PROMENADE +10, step 4 (her flag: "extend the pier more and let the boats out further into the bay"; her OK):
-- both piers, all four boats, their moorings and the boat squirrels move 10 out (-X) from their ORIGINAL spots, and the two
-- gangways go back to their original 14-stud shape (also 10 out). Net: the pier/boat layout is the original one shifted
-- with the quay, so the piers keep their full visible length. Uses/keeps PromOldCF/PromOldSize/PromOldPivot (revert_promenade1.lua).
local B=workspace.PortoNocciola['04 Piers and fishing boats']
local DX=Vector3.new(-10,0,0)
local MOVE={['Molo dei Pescatori']=true,['Molo delle Reti']=true,['Rosina']=true,['Stella Marina']=true,['Azzurra']=true,['La Limonaia']=true,['Attached boat moorings']=true}
local GW={['Gentle timber gangway']=true,['Gangway edge beam']=true,['Gangway handrail']=true,['Gangway short post']=true}
local function partTo(p)   -- original CFrame/Size + DX
	local o=p:GetAttribute('PromOldCF')
	if o==nil then p:SetAttribute('PromOldCF',p.CFrame) o=p.CFrame end
	local s=p:GetAttribute('PromOldSize') if s then p.Size=s end
	p.CFrame=o+DX
end
local function modelTo(m)
	local o=m:GetAttribute('PromOldPivot')
	if o==nil then m:SetAttribute('PromOldPivot',m:GetPivot()) o=m:GetPivot() end
	m:PivotTo(o+DX)
end
if B:GetAttribute('PiersOut10') then warn('PRM4@ABORT already ran') return end
local moved,parts,skipped={},0,{}
for _,c in ipairs(B:GetChildren()) do
	if MOVE[c.Name] then
		if c.Name=='Attached boat moorings' then
			for _,d in ipairs(c:GetDescendants()) do if d:IsA('BasePart') then partTo(d) parts+=1 end end
		elseif c:IsA('Model') then modelTo(c) table.insert(moved,c.Name)
		end
	elseif c:IsA('BasePart') and GW[c.Name] then partTo(c) parts+=1
	else table.insert(skipped,c.Name) end
end
local sq={}
for _,id in ipairs({'octopus_squirrel_color','deckhand_squirrel_color','seacaptain_squirrel_color'}) do
	local m=workspace:FindFirstChild(id) if m then modelTo(m) table.insert(sq,id) end
end
B:SetAttribute('PiersOut10',true)
warn('PRM4@DONE models',table.concat(moved,', '),'| parts',parts,'| squirrels',table.concat(sq,', '),'| left alone',table.concat(skipped,', '))
