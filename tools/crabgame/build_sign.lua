-- Oct 4 2026 (Shannon: "create a sign on the tidepool area to designate it as the crab catching area"):
-- a weathered wooden sign on two posts, on the small sandy cove right where you step across onto the tide-pool rocks,
-- facing the bottom of the cove stairs. "ZONA GRANCHI / Crab Catching Area", a tide-pool crab sitting on top.
-- Rebuilds itself if run again. No asserts after the first edit: warn + return.
local cala=workspace.PortoNocciola:FindFirstChild('Cala della Sabbia and tide pools',true)
if not cala then warn('QS@ABORT no cala folder') return end
local old=cala:FindFirstChild('CrabZoneSign') if old then old:Destroy() end
local LOOK=Vector3.new(-0.32,0,1).Unit                 -- the way the lettering faces: toward the stairs' foot (~303,-777)
local BW,BH=5.6,2.5                                   -- board
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances={workspace:FindFirstChild('SquirrelTwins')}
-- Oct 4 2026 (Shannon: "the left post is falling off the edge; move it farther right and closer to the wall"): slide east
-- toward the wall; keep the spot farthest east where every point round both posts lands on the same flat sand and a box
-- round the whole sign touches nothing else, then step 0.6 back from that limit
local right=CFrame.lookAt(Vector3.zero,LOOK).RightVector*-1      -- the reader's right (the reader faces -LOOK)
local function groundAt(x,z)
	local q=workspace:Raycast(Vector3.new(x,-30,z),Vector3.new(0,-40,0),rp)
	return q and q.Position.Y, q and q.Instance
end
local G0=groundAt(305.6,-786.2)
if not G0 then warn('QS@ABORT no ground') return end
local best
for dx=0,7,0.2 do
	local c=Vector3.new(305.6+dx,0,-786.2)
	local ok=true
	for _,s in ipairs({-1,1}) do
		local post=c+right*s*(BW/2-0.55)
		for _,o in ipairs({Vector3.new(0,0,0),Vector3.new(0.8,0,0),Vector3.new(-0.8,0,0),Vector3.new(0,0,0.8),Vector3.new(0,0,-0.8)}) do
			local y=groundAt(post.X+o.X,post.Z+o.Z)
			if not y or math.abs(y-G0)>0.3 then ok=false end
		end
	end
	if ok then
		local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude
		op.FilterDescendantsInstances={workspace.Terrain,(cala:FindFirstChild('CrabZoneSign') or Instance.new('Folder'))}
		local cf=CFrame.lookAt(Vector3.new(c.X,G0+2.6,c.Z),Vector3.new(c.X,G0+2.6,c.Z)+LOOK)
		for _,hit in ipairs(workspace:GetPartBoundsInBox(cf,Vector3.new(BW+0.8,4.6,1.4),op)) do
			if hit.CanCollide and hit.Transparency<1 and hit.Position.Y>G0+0.2 then ok=false end
		end
	end
	if ok then best=dx elseif best then break end
end
if not best then warn('QS@ABORT no clear spot') return end
local BASE=Vector3.new(305.6+math.max(0,best-0.6),0,-786.2)
local G=groundAt(BASE.X,BASE.Z) or G0
local function frame(pos) return CFrame.lookAt(pos,pos+LOOK) end   -- -Z (Front) toward the reader
local M=Instance.new('Model') M.Name='CrabZoneSign'
local WOOD=Color3.fromRGB(196,170,130) local DARK=Color3.fromRGB(120,88,58) local POST=Color3.fromRGB(134,100,66)
local function part(name,size,cf,col,mat)
	local p=Instance.new('Part') p.Name=name p.Size=size p.CFrame=cf p.Color=col p.Material=mat or Enum.Material.Wood
	p.Anchored=true p.CanCollide=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=M
	return p
end
local BOARD_Y=G+3.05                                   -- board centre height (bottom ~1.8 above the sand)
local c0=frame(Vector3.new(BASE.X,BOARD_Y,BASE.Z))
local board=part('Board',Vector3.new(BW,BH,0.22),c0,WOOD)
-- posts behind the board, sunk 0.6 into the sand
for i,s in ipairs({-1,1}) do
	local top=BOARD_Y+BH/2+0.35 local bot=G-0.6
	part('Post'..i,Vector3.new(0.34,top-bot,0.34),c0*CFrame.new(s*(BW/2-0.55),(top+bot)/2-BOARD_Y,0.28),POST)
	part('PostCap'..i,Vector3.new(0.44,0.12,0.44),c0*CFrame.new(s*(BW/2-0.55),top-BOARD_Y+0.06,0.28),DARK)
end
-- frame trim, slightly proud of the board face
part('TrimTop',Vector3.new(BW+0.2,0.2,0.3),c0*CFrame.new(0,BH/2,0),DARK)
part('TrimBottom',Vector3.new(BW+0.2,0.2,0.3),c0*CFrame.new(0,-BH/2,0),DARK)
part('TrimLeft',Vector3.new(0.2,BH,0.3),c0*CFrame.new(-BW/2,0,0),DARK)
part('TrimRight',Vector3.new(0.2,BH,0.3),c0*CFrame.new(BW/2,0,0),DARK)
-- the back: plain boards held by two cross-battens between the posts (Shannon: "the back side of the sign looks really bad")
for i,y in ipairs({0.62,-0.62}) do
	part('Batten'..i,Vector3.new(BW-0.7,0.26,0.16),c0*CFrame.new(0,y,0.19),POST)
end
-- lettering on the front only
for _,face in ipairs({Enum.NormalId.Front}) do
	local sg=Instance.new('SurfaceGui') sg.Face=face sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud=60
	sg.LightInfluence=1 sg.Parent=board
	local function label(text,y,h,size,col)
		local t=Instance.new('TextLabel') t.BackgroundTransparency=1 t.Size=UDim2.new(0.9,0,h,0) t.Position=UDim2.new(0.05,0,y,0)
		t.Text=text t.TextScaled=true t.FontFace=Font.new('rbxasset://fonts/families/FredokaOne.json') t.TextColor3=col
		local cst=Instance.new('UITextSizeConstraint') cst.MaxTextSize=size cst.Parent=t
		t.Parent=sg return t
	end
	local a=label('ZONA GRANCHI',0.1,0.46,200,Color3.fromRGB(28,78,128))
	local st=Instance.new('UIStroke') st.Color=Color3.fromRGB(250,241,219) st.Thickness=3 st.Parent=a
	label('Crab Catching Area',0.58,0.3,200,Color3.fromRGB(150,52,30))
end
-- a tide-pool crab sitting on the top trim
local tmpl=game.ReplicatedStorage:FindFirstChild('TidePoolCrab')
if tmpl then
	local crab=tmpl:Clone() crab.Name='SignCrab'
	for _,d in ipairs(crab:GetDescendants()) do if d:IsA('BasePart') then d.Anchored=true d.CanCollide=false d.CanQuery=false d.CanTouch=false end end
	crab.Parent=M
	pcall(function() crab:ScaleTo(1.7) end)
	local topY=BOARD_Y+BH/2+0.1
	local want=c0*CFrame.new(0.9,0,0)                    -- a little right of centre, as you read it
	crab:PivotTo(CFrame.lookAt(want.Position,want.Position+LOOK))
	local cf,sz=crab:GetBoundingBox()
	crab:PivotTo(crab:GetPivot()+Vector3.new(want.X-cf.X,topY-(cf.Y-sz.Y/2),want.Z-cf.Z))
end
M:SetAttribute('Built','Oct 4 2026 crab game sign')
M.Parent=cala
game:GetService('ChangeHistoryService'):SetWaypoint('Crab zone sign')
warn('QS@SIGN slid',best,'ground',G,'board centre',board.Position,'faces',board.CFrame.LookVector)
local cam=workspace.CurrentCamera
local t=Vector3.new(BASE.X,BOARD_Y-0.4,BASE.Z)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+LOOK*9+Vector3.new(0,1.2,0),t)
