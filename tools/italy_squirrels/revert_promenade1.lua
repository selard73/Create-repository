-- Oct 5 2026: UNDO promenade step 1 (only if she asks). Restores every PromOldCF/PromOldSize/PromOldPivot and removes PromenadeFill copies.
local n,m,d=0,0,0
local roots={workspace.PortoNocciola,workspace:FindFirstChild('deckhand_squirrel_color'),workspace:FindFirstChild('fishmonger_squirrel_color'),workspace:FindFirstChild('SquirrelTwins'),
	workspace:FindFirstChild('octopus_squirrel_color'),workspace:FindFirstChild('seacaptain_squirrel_color'),workspace:FindFirstChild('CrabGame')}
-- also afterwards: workspace.PortoNocciola:SetAttribute('PromFix5',nil) and ['04 Piers and fishing boats']:SetAttribute('PiersOut10',nil)
-- terrain: Terrain:PasteRegion(game.ServerStorage.PromenadeBackup.TerrainBefore, Vector3int16.new(51,-18,-179), true)
for _,r in ipairs(roots) do
	if r then
		local list=r:GetDescendants() table.insert(list,r)
		for _,x in ipairs(list) do
			for k,v in pairs(x:GetAttributes()) do   -- fix5: world-position attributes shifted with their owners
				if k:sub(1,8)=='PromOld_' then x:SetAttribute(k:sub(9),v) x:SetAttribute(k,nil) end
			end
			if x:GetAttribute('PromenadeFill') then x:Destroy() d+=1
			elseif x:IsA('BasePart') and x:GetAttribute('PromOldCF') then
				x.CFrame=x:GetAttribute('PromOldCF') if x:GetAttribute('PromOldSize') then x.Size=x:GetAttribute('PromOldSize') end
				x:SetAttribute('PromOldCF',nil) x:SetAttribute('PromOldSize',nil) n+=1
			elseif x:IsA('Model') and x:GetAttribute('PromOldPivot') then
				x:PivotTo(x:GetAttribute('PromOldPivot')) x:SetAttribute('PromOldPivot',nil) m+=1
			end
		end
	end
end
warn('PRM@REVERT parts',n,'models',m,'fills removed',d,'(ServerStorage.PromenadeBackup kept)')
