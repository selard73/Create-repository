-- Oct 4 2026: the crab trap becomes a hotbar Tool + Equip/Store in the Acorn Store (Shannon: "yes please").
-- Needs the imported icon carrier (workspace.icon_carrier / CrabIconCarrier MeshPart) for the hotbar picture.
-- Exact-anchor edits; a missing anchor warns and skips that one; never inserts twice. No asserts after the first edit.
local RS=game.ReplicatedStorage local SS=game.ServerStorage
local kit=RS:FindFirstChild('CrabGame')
if not (kit and kit:FindFirstChild('Trap')) then warn('QH@ABORT no CrabGame kit') return end
local carrier=workspace:FindFirstChild('CrabIconCarrier',true)
local ICON=(carrier and carrier:IsA('MeshPart') and carrier.TextureID) or (SS:FindFirstChild('CrabTrapTool') and SS.CrabTrapTool.TextureId) or ''
if ICON=='' then warn('QH@ABORT no icon texture yet') return end
local carModel=workspace:FindFirstChild('icon_carrier') if carModel then carModel:Destroy() elseif carrier then carrier:Destroy() end

-- the trap a little smaller, held and flying alike
local trap=kit.Trap
if not trap:GetAttribute('Scaled') then pcall(function() trap:ScaleTo(0.8) end) trap:SetAttribute('Scaled',0.8) end
-- the Tool: an invisible handle at the hoop's top, the trap hanging below it
local old=SS:FindFirstChild('CrabTrapTool') if old then old:Destroy() end
local tool=Instance.new('Tool') tool.Name='CrabTrapTool' tool.ToolTip='Crab trap' tool.CanBeDropped=false tool.RequiresHandle=true
tool.TextureId=ICON
local body=trap:Clone()
local fr=body.TrapFrame
local s=fr.Size
-- the trap's own axis is its shortest side (hoops are round); hang it with the hoops facing forward, axis along the arm's side
local axis=(s.X<s.Y and s.X<s.Z) and Vector3.xAxis or ((s.Z<s.Y) and Vector3.zAxis or Vector3.yAxis)
local h=Instance.new('Part') h.Name='Handle' h.Size=Vector3.new(0.35,0.35,0.35) h.Transparency=1 h.CanCollide=false h.CanQuery=false h.CanTouch=false h.Massless=true
local r=math.max(s.X,s.Y,s.Z)/2
-- body placed so its centre is r+0.05 under the handle, its axis along the handle's X
local rot=CFrame.fromMatrix(Vector3.zero, axis, (axis==Vector3.yAxis) and Vector3.zAxis or Vector3.yAxis)   -- local frame with X = trap axis
h.CFrame=CFrame.new(0,100,0)
body:PivotTo(h.CFrame*CFrame.new(0,-(r+0.05),0)*rot:Inverse())
for _,v in ipairs(body:GetDescendants()) do
	if v:IsA('BasePart') then
		v.Anchored=false v.Massless=true v.CanCollide=false v.CanQuery=false v.CanTouch=false
		local w=Instance.new('WeldConstraint') w.Part0=h w.Part1=v w.Parent=v
		v.Parent=tool
	end
end
body:Destroy()
h.Parent=tool
tool.Grip=CFrame.new(0,0,0)
tool.Parent=SS

-- Equip / Store
local re=RS:FindFirstChild('HotbarStow') if not re then re=Instance.new('RemoteEvent') re.Name='HotbarStow' re.Parent=RS end
local oldS=workspace.Shop:FindFirstChild('StowServer') if oldS then oldS:Destroy() end
local stow=Instance.new('Script') stow.Name='StowServer' stow.Source=[==[%STOW%]==] stow.Parent=workspace.Shop

local function insert(scr,anchor,add,dupKey,after)
	local src=scr.Source
	if src:find(dupKey,1,true) then warn('QH@SKIP already',scr:GetFullName(),dupKey) return true end
	local a,b=src:find(anchor,1,true)
	if not a then warn('QH@MISSING',scr:GetFullName(),anchor:sub(1,40)) return false end
	if after then scr.Source=src:sub(1,b)..add..src:sub(b+1) else scr.Source=src:sub(1,a-1)..add..src:sub(a) end
	return true
end
local res={}
-- givers: skip a stored tool, hand it back when equipped again
for _,g in ipairs({{workspace.Hoop.SlingServer,'slingshot'},{workspace.Binoculars.BinocularsServer,'binoculars'}}) do
	local scr,id=g[1],g[2]
	table.insert(res,insert(scr,'\tif (player:GetAttribute("Item_'..id..'") or 0) <= 0 then return end\n\tlocal char = player.Character\n',
		'\tif (player:GetAttribute("Item_stow_'..id..'") or 0) > 0 then return end   -- put away from the Acorn Store (StowServer, Oct 4 2026)\n',
		'Item_stow_'..id..'") or 0) > 0 then return end',false))
	-- (insert BEFORE the char line: place it between the two anchor lines)
	table.insert(res,insert(scr,'\tplayer:GetAttributeChangedSignal("Item_'..id..'"):Connect(function() give(player) end)\n',
		'\tplayer:GetAttributeChangedSignal("Item_stow_'..id..'"):Connect(function() give(player) end)\n',
		'GetAttributeChangedSignal("Item_stow_'..id..'")',true))
end
-- the store: Equip / Store buttons
local SC=workspace.Shop.ShopClient
table.insert(res,insert(SC,'local busy = false\nlocal function attempt(',
[[-- EQUIP / STORE (Oct 4 2026, Shannon): what you own that rides in the hotbar gets two buttons instead of "owned"
local HOTBAR = {binoculars = true, slingshot = true, crabtrap = true}
local function stowIt(item, rec, stow)
	local e = RS:FindFirstChild("HotbarStow")
	if not e then say(rec, "not ready yet", false) return end
	e:FireServer(item.id, stow)
	say(rec, stow and "stored - off your hotbar" or "equipped - on your hotbar", true)
end
]],'local HOTBAR = {',false))
table.insert(res,insert(SC,'\trec.btn = btn\n',
[[	if HOTBAR[item.id] then
		local b2 = Instance.new("TextButton")
		b2.AnchorPoint = Vector2.new(1, 0); b2.Position = UDim2.new(1, -12, 0, 106)
		b2.Size = UDim2.fromOffset(70, 36); b2.BackgroundColor3 = GOLD; b2.BorderSizePixel = 0
		b2.FontFace = FONT; b2.TextSize = 15; b2.TextColor3 = BTN_INK; b2.Text = "Store"
		b2.AutoButtonColor = false; b2.ZIndex = 4; b2.Visible = false; b2.Parent = row
		corner(b2, UDim.new(0, 10)); stroke(b2, RGB(150, 98, 36), 2, 0.2)
		rec.btn2 = b2
		b2.MouseButton1Click:Connect(function() stowIt(item, rec, true) end)
	end
]],'rec.btn2 = b2',true))
table.insert(res,insert(SC,'\tbtn.MouseButton1Click:Connect(function()\n',
'\t\tif HOTBAR[item.id] and (player:GetAttribute("Item_" .. item.id) or 0) > 0 then stowIt(item, rec, false) return end\n',
'then stowIt(item, rec, false) return end',true))
table.insert(res,insert(SC,'\t\t\trec.btn.TextColor3 = affordable and BTN_INK or INK_DIM\n',
[[			if rec.btn2 then
				local stowed = (player:GetAttribute("Item_stow_" .. item.id) or 0) > 0
				if owned then
					local GREEN = RGB(112, 160, 84)
					rec.btn.Size = UDim2.fromOffset(70, 36); rec.btn.Position = UDim2.new(1, -86, 0, 106); rec.btn.TextSize = 15
					rec.btn2.Visible = true
					rec.label = stowed and "Equip" or "Equipped"
					if rec.btn.Text ~= "..." then rec.btn.Text = rec.label end
					rec.btn2.Text = stowed and "Stored" or "Store"
					rec.btn.BackgroundColor3 = stowed and GOLD or GREEN; rec.btn.TextColor3 = stowed and BTN_INK or RGB(255, 255, 255)
					rec.btn2.BackgroundColor3 = stowed and GREEN or GOLD; rec.btn2.TextColor3 = stowed and RGB(255, 255, 255) or BTN_INK
				else
					rec.btn.Size = UDim2.fromOffset(142, 36); rec.btn.Position = UDim2.new(1, -12, 0, 106); rec.btn.TextSize = 18
					rec.btn2.Visible = false
				end
			end
]],'if rec.btn2 then\n\t\t\t\tlocal stowed',true))
table.insert(res,insert(SC,'player:GetAttributeChangedSignal("Item_bagoff"):Connect(refresh)\n',
'for id in pairs(HOTBAR) do player:GetAttributeChangedSignal("Item_stow_" .. id):Connect(refresh) end\n',
'GetAttributeChangedSignal("Item_stow_" .. id)',true))
-- the crab scripts
local srv=workspace.CrabGame:FindFirstChild('CrabServer') if srv then srv.Source=[==[%SERVER%]==] end
local cli=game.StarterPlayer.StarterPlayerScripts:FindFirstChild('CrabClient') if cli then cli.Source=[==[%CLIENT%]==] end
game:GetService('ChangeHistoryService'):SetWaypoint('Crab trap tool + Equip/Store')
local ok=0 for _,v in ipairs(res) do if v then ok+=1 end end
warn('QH@OK edits',ok,'of',#res,'icon',ICON,'trap size',fr.Size,'axis',axis,'tool parts',#tool:GetChildren(),'server',srv and #srv.Source,'client',cli and #cli.Source)
