-- Oct 5 2026 read-only: details for the +10 promenade build.
-- 1) every direct child of '01 Curved waterfront' and '11 Fitted surface joins': class, name, material, top y, children classes
-- 2) Stella Marina mooring parts + pier posts/hitches near her; 3) gangway parts with CFrame + size
local P=workspace.PortoNocciola
local function f(v) return string.format('%.2f,%.2f,%.2f',v.X,v.Y,v.Z) end
local seen={}
for _,sec in ipairs({'01 Curved waterfront','11 Fitted surface joins'}) do
	for _,ch in ipairs(P[sec]:GetChildren()) do
		local key=sec..'|'..ch.ClassName..'|'..ch.Name
		local top,mat,kids='-','-',{}
		if ch:IsA('BasePart') then
			top=string.format('%.2f',ch.Position.Y+ch.Size.Y/2) mat=ch.Material.Name..'/'..ch.MaterialVariant..'/'..tostring(ch.Color)
			if math.abs(ch.CFrame.UpVector.Y)<0.99 then mat=mat..' TILTED' end
		end
		for _,k in ipairs(ch:GetChildren()) do kids[k.ClassName]=(kids[k.ClassName] or 0)+1 end
		local ks='' for k,n in pairs(kids) do ks=ks..k..'x'..n..' ' end
		seen[key]=(seen[key] or 0)+1
		if seen[key]<=2 then warn('QP3@ring',key,'top',top,mat,'kids',ks) end
	end
end
for k,n in pairs(seen) do warn('QP3@count',k,n) end
local B=P['04 Piers and fishing boats']
for _,d in ipairs(B:GetDescendants()) do
	if d:IsA('BasePart') then
		local p=d.Position
		local inMoor=d:FindFirstAncestor('Stella Marina') and d:FindFirstAncestor('Attached boat moorings')
		local nearPier=(p.Z<-638 and p.Z>-641.5 and p.X>214 and p.X<226)
		if inMoor or (nearPier and not d:FindFirstAncestor('Stella Marina')) then
			warn('QP3@moor',d:GetFullName():gsub('Workspace.PortoNocciola.04 Piers and fishing boats.',''),d.ClassName,f(p),'size',f(d.Size))
		end
		if d.Name:match('Gangway') or d.Name:match('Gentle timber') then
			warn('QP3@gw',d.Name,'cf',string.format('%.3f,%.3f,%.3f, %.4f,%.4f,%.4f, %.4f,%.4f,%.4f, %.4f,%.4f,%.4f',d.CFrame:GetComponents()),'size',f(d.Size))
		end
	end
end
local SM=B:FindFirstChild('Stella Marina',true)
if SM then warn('QP3@stella',SM:GetFullName(),SM.ClassName,'pivot',f(SM:GetPivot().Position)) end
local g=workspace:FindFirstChild('deckhand_squirrel_color')
if g then warn('QP3@gino',g:GetFullName(),'pivot',f(g:GetPivot().Position),'anchored',tostring(g.PrimaryPart and g.PrimaryPart.Anchored)) end
local fm=workspace:FindFirstChild('fishmonger_squirrel_color')
if fm then warn('QP3@fish',fm:GetFullName(),'pivot',f(fm:GetPivot().Position)) end
-- anything welded/constrained between moving and non-moving things
for _,sec in ipairs({'01 Curved waterfront','03 Fish market','04 Piers and fishing boats','06 Piazza details and planting','05 Boatyard and nets'}) do
	local n=0 for _,d in ipairs(P[sec]:GetDescendants()) do if d:IsA('JointInstance') or d:IsA('Constraint') or d:IsA('WeldConstraint') then n+=1 end end
	local un=0 for _,d in ipairs(P[sec]:GetDescendants()) do if d:IsA('BasePart') and not d.Anchored then un+=1 end end
	warn('QP3@joints',sec,n,'unanchored',un)
end
warn('QP3@DONE')
