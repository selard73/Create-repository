-- Oct 4 2026 (her circle): rescue boat to the far side of the lifeguard chair, on the grass along the line Rocco -> chair,
-- lying lengthwise toward the water (bow along Rocco's facing), tilted to the ground. Orientation is set outright from the
-- hull's own axes (long axis = the 6.6 side, up = the 1.33 side, bow = away from the lettering's centre).
local post=workspace.PortoNocciola:FindFirstChild('Lifeguard Post')
local boat=post and post:FindFirstChild('Rescue Boat SALVATAGGIO')
if not boat then warn('QB@ABORT no boat') return end
local SPOT=Vector3.new(260.76,0,-715.4)
local WANT=Vector3.new(-0.533,0,-0.846).Unit
local LEFT=-WANT:Cross(Vector3.yAxis)
local AT=SPOT+LEFT*7.6+WANT*1.8
local BOW=WANT
local col=workspace:FindFirstChild('lifeguard_squirrel_color')
local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances={post,col,workspace:FindFirstChild('SquirrelTwins')}
local function ground(p) local q=workspace:Raycast(Vector3.new(p.X,-30,p.Z),Vector3.new(0,-40,0),rp) return q and q.Position.Y end
local function part(m,name) for _,p in ipairs(m:GetDescendants()) do if p:IsA('BasePart') and p.Name:find(name,1,true) then return p end end end
local hull,text=part(boat,'Boat_Hull'),part(boat,'Boat_Text')
if not (hull and text) then warn('QB@ABORT parts') return end
local sz=hull.Size
local longX=sz.X>sz.Z
local tl=hull.CFrame:PointToObjectSpace(text.Position)
local s=((longX and tl.X or tl.Z)<0) and 1 or -1                    -- bow is on the side away from the lettering centre
-- ground heights -> tilted bow/up
local side=BOW:Cross(Vector3.yAxis).Unit
local yb,ys=ground(AT+BOW*2.6),ground(AT-BOW*2.6)
local yp,yq=ground(AT+side*1.0),ground(AT-side*1.0)
local y0=ground(AT)
if not (yb and ys and yp and yq and y0) then warn('QB@ABORT ground') return end
local pitch=math.clamp(math.atan2(yb-ys,5.2),-0.25,0.25) local roll=math.clamp(math.atan2(yp-yq,2.0),-0.2,0.2)
local tilt=CFrame.fromAxisAngle(side,pitch)*CFrame.fromAxisAngle(BOW,-roll)
local bowW=tilt:VectorToWorldSpace(BOW) local upW=tilt:VectorToWorldSpace(Vector3.yAxis)
local X,Y,Z
if longX then X=bowW*s Y=upW Z=X:Cross(Y) else Z=bowW*s Y=upW X=Y:Cross(Z) end
local target=CFrame.fromMatrix(hull.Position,X,Y,Z)
boat:PivotTo(target*hull.CFrame:Inverse()*boat:GetPivot())
local gmid=(yb+ys+yp+yq+y0)/5
local hcf2,hsz=hull.CFrame,hull.Size
local low=1e9 for _,a in ipairs({-1,1}) do for _,b in ipairs({-1,1}) do for _,c in ipairs({-1,1}) do
	low=math.min(low,(hcf2*CFrame.new(hsz.X/2*a,hsz.Y/2*b,hsz.Z/2*c)).Position.Y) end end end
boat:PivotTo(boat:GetPivot()+Vector3.new(AT.X-hull.Position.X,(gmid-0.18)-low,AT.Z-hull.Position.Z))
game:GetService('ChangeHistoryService'):SetWaypoint('Rescue boat beside the chair')
local chair=post:FindFirstChild('Lifeguard Chair')
local cw=chair and part(chair,'Chair_Wood')
local bowNow=(hull.Position-text.Position)*Vector3.new(1,0,1)
warn('QB@MOVED boat',hull.Position,'ground',y0,'pitch',math.deg(pitch),'roll',math.deg(roll),'bow',bowNow.Magnitude>0 and bowNow.Unit,
	'dist to chair centre',cw and ((hull.Position-cw.Position)*Vector3.new(1,0,1)).Magnitude)
local cam=workspace.CurrentCamera
local t=(SPOT+AT)/2+Vector3.new(0,y0+2,0)
cam.Focus=CFrame.new(t)
cam.CFrame=CFrame.lookAt(t+WANT*13+LEFT*2+Vector3.new(0,5,0),t)
