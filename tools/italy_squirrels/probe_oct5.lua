-- Oct 5 2026 read-only probe: title text sources, bell, lifeguard chair, sunbather, old models' children.
local out={}
local function P(...) local t={} for _,v in ipairs({...}) do table.insert(t,tostring(v)) end table.insert(out,table.concat(t,' ')) end
-- 1) every script mentioning Grand Keeper / Maestro / TitleLabel
for _,s in ipairs(game:GetDescendants()) do
	if s:IsA('LuaSourceContainer') then
		local ok,src=pcall(function() return s.Source end)
		if ok and src then
			for _,w in ipairs({'Grand Keeper','Squirrel Maestro','Keeper of the'}) do
				local i=src:find(w,1,true)
				if i then
					local a=math.max(1,i-160) local b=math.min(#src,i+160)
					P('SRC',s:GetFullName(),w,'@',i,'::',(src:sub(a,b):gsub('\n',' | ')))
				end
			end
		end
	elseif (s:IsA('TextLabel') or s:IsA('TextButton')) and (s.Text:find('Keeper',1,true) or s.Text:find('Maestro',1,true)) then
		P('GUI',s:GetFullName(),s.Text)
	end
end
-- 2) bell-ish parts in PortoNocciola
local PN=workspace:FindFirstChild('PortoNocciola')
for _,d in ipairs((PN or workspace):GetDescendants()) do
	if d:IsA('BasePart') and (d.Name:lower():find('bell') or (d.Parent and d.Parent.Name:lower():find('bell'))) then
		P('BELL',d:GetFullName(),d.ClassName,d.Position,d.Size,d.Color,d.Material)
	end
end
for _,d in ipairs((PN or workspace):GetDescendants()) do
	if (d:IsA('Model') or d:IsA('Folder')) and (d.Name:lower():find('rent') or d.Name:lower():find('kiosk') or d.Name:lower():find('boat') or d.Name:lower():find('sail')) then
		local cf,sz=nil,nil if d:IsA('Model') then cf,sz=d:GetBoundingBox() end
		P('KIOSK?',d:GetFullName(),cf and cf.Position or '',sz or '')
	end
end
-- 3) lifeguard chair + Rocco; sunbather
local lp=PN and PN:FindFirstChild('Lifeguard Post',true)
if lp then
	for _,c in ipairs(lp:GetChildren()) do
		local cf,sz if c:IsA('Model') then cf,sz=c:GetBoundingBox() elseif c:IsA('BasePart') then cf,sz=c.CFrame,c.Size end
		P('LGPOST',c:GetFullName(),c.ClassName,cf and cf.Position or '',sz or '')
		if c:IsA('Model') then for _,p in ipairs(c:GetDescendants()) do if p:IsA('BasePart') then P('  part',p.Name,p.Position,p.Size) end end end
	end
end
for _,id in ipairs({'lifeguard_squirrel','sunbather_squirrel','fishmonger_squirrel','crabcatcher_squirrel'}) do
	for _,m in ipairs(workspace:GetChildren()) do
		if m.Name==id..'_color' then
			local cm=m:FindFirstChild('Squirrel')
			local kids={} for _,c in ipairs(m:GetChildren()) do if not c:IsA('Bone') then table.insert(kids,c.Name..':'..c.ClassName) end end
			local ck={} if cm then for _,c in ipairs(cm:GetChildren()) do if not c:IsA('Bone') then table.insert(ck,c.Name..':'..c.ClassName) end end end
			P('SQ',id,cm and cm.Position,cm and cm.Size,cm and cm.Orientation,'kids',table.concat(kids,','),'cmkids',table.concat(ck,','))
			if cm then local a={} for k,v in pairs(cm:GetAttributes()) do table.insert(a,k..'='..tostring(v)) end P('  attrs',table.concat(a,' ')) end
			local a2={} for k,v in pairs(m:GetAttributes()) do table.insert(a2,k..'='..tostring(v)) end P('  mattrs',table.concat(a2,' '))
		end
	end
end
-- sunbather props nearby (towel/umbrella)
local sb=workspace:FindFirstChild('sunbather_squirrel_color')
if sb then
	local p=sb.Squirrel.Position
	for _,d in ipairs((PN or workspace):GetDescendants()) do
		if (d:IsA('Model') or d:IsA('BasePart')) and d.Parent and not d.Parent:IsA('Model') or (d:IsA('Model') and d.Parent==PN) then
			local pos=d:IsA('Model') and d:GetPivot().Position or d.Position
			if (pos-p).Magnitude<12 then P('NEARSUN',d:GetFullName(),d.ClassName,pos) end
		end
	end
end
for i=1,#out,1 do warn('QP@'..i..' '..out[i]) end
warn('QP@DONE',#out)
