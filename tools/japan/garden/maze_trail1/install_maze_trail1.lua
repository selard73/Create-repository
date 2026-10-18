-- Acorn trail: preview in Play Server; stopped Edit requires Shannon's yes.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place")
assert((Run:IsRunning()and Run:IsServer())or(not Run:IsRunning()and MAZETRAIL1_ALLOW_EDIT==true),"Preview first; approved Edit only")
local maze=assert(workspace.JapanMap:FindFirstChild("BambooMaze"))
local kit=assert(game.ServerStorage:FindFirstChild("JapanGardenKit"))
local source=assert(kit:FindFirstChild("maze_trail_acorn"),"Import and anchor kit30 first")
local saved={}
for _,s in ipairs(maze:GetChildren())do if s:IsA("LuaSourceContainer")then saved[s]=s.Source end end
local mazeCount=#maze:GetDescendants()
local acorn=source:Clone();acorn.Name="Acorn"
local colors={TrailAcorn_Nut=Color3.fromRGB(231,169,69),TrailAcorn_Cap=Color3.fromRGB(133,88,43),TrailAcorn_Stem=Color3.fromRGB(96,64,36)}
local parts=0
for _,p in ipairs(acorn:GetDescendants())do
 if p:IsA("BasePart")then
  assert(p:IsA("MeshPart"),"Acorn must contain real meshes only")
  local k=p.Name:gsub("%.%d+$","");assert(colors[k],"Unexpected acorn piece: "..p.Name)
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true;p.Material=Enum.Material.SmoothPlastic;p.Color=colors[k];parts+=1
 elseif p:IsA("LuaSourceContainer")or p:IsA("ProximityPrompt")then error("Unexpected interactive acorn component")end
end
assert(parts==3,"Expected exactly three acorn meshes")
local cf,size=acorn:GetBoundingBox()
assert(size.X<5 and size.Y<5 and size.Z<5,"Unexpected import scale")
-- A stable bottom-center pivot; all rotations are baked into the kit mesh.
acorn.PrimaryPart=nil;acorn.WorldPivot=CFrame.new(cf.Position-Vector3.new(0,size.Y/2,0))
acorn:PivotTo(CFrame.new())
local bridge=Instance.new("Folder");bridge.Name="MazeTrail1"
acorn.Parent=bridge
local client=Instance.new("Script");client.Name="MazeTrailClient";client.RunContext=Enum.RunContext.Client
client.Source=[====[-- Personal, free breadcrumbs. No remotes, currency calls or saved player data.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local bridge=script.Parent
local maze=workspace:WaitForChild("JapanMap"):WaitForChild("BambooMaze")
local template=bridge:WaitForChild("Acorn")
if pg:FindFirstChild("MazeTrailGui")then return end
local gui=Instance.new("ScreenGui")
gui.Name="MazeTrailGui";gui.ResetOnSpawn=false;gui.DisplayOrder=15;gui.Enabled=false;gui.Parent=pg
local trail=Instance.new("Folder");trail.Name="MyMazeAcornTrail";trail.Parent=workspace
local markers={};local connections={};local inside=false;local lastDrop=0;local clearUntil=0;local messageUntil=0
local MAX=300;local SPACING=3
local C=Color3.fromRGB
local function rounded(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o end
local card=Instance.new("Frame");card.Name="Controls";card.AnchorPoint=Vector2.new(.5,1);card.Size=UDim2.fromOffset(284,82)
card.BackgroundColor3=C(38,42,30);card.BackgroundTransparency=.07;card.BorderSizePixel=0;card.Parent=gui;rounded(card,13)
local edge=Instance.new("UIStroke");edge.Color=C(164,141,82);edge.Transparency=.2;edge.Parent=card
local note=Instance.new("TextLabel");note.Name="Note";note.BackgroundTransparency=1;note.Position=UDim2.fromOffset(8,5);note.Size=UDim2.new(1,-16,0,22)
note.Font=Enum.Font.FredokaOne;note.TextSize=13;note.TextColor3=C(236,225,195);note.Text="Your trail · free acorns";note.Parent=card
local function button(name,text,x,w,color)
 local b=Instance.new("TextButton");b.Name=name;b.Position=UDim2.fromOffset(x,31);b.Size=UDim2.fromOffset(w,44)
 b.BackgroundColor3=color;b.BorderSizePixel=0;b.Font=Enum.Font.FredokaOne;b.TextSize=15;b.TextColor3=C(255,246,220);b.Text=text;b.Parent=card;rounded(b,9);return b
end
local drop=button("Drop","Drop acorn",7,158,C(116,84,39))
local clear=button("Clear","Clear trail",172,105,C(66,74,48));clear.TextSize=13
local function on(signal,fn)local c=signal:Connect(fn);table.insert(connections,c);return c end
local function message(t)note.Text=t;messageUntil=os.clock()+2.5 end
local function updateCount()
 gui:SetAttribute("MarkerCount",#markers)
 if os.clock()>=messageUntil then note.Text=string.format("Your trail · %d placed · free",#markers)end
end
local function bounds(p)
 local lo,hi=maze:GetAttribute("Footprint"),maze:GetAttribute("FootprintMax")
 return lo and hi and p.X>lo.X+.6 and p.X<hi.X-.6 and p.Z>lo.Y+.6 and p.Z<hi.Y-.6 and p.Y>-5 and p.Y<20
end
local function rootAndHumanoid()
 local ch=player.Character
 return ch and ch:FindFirstChild("HumanoidRootPart"),ch and ch:FindFirstChildOfClass("Humanoid")
end
local function canUse()
 local root,h=rootAndHumanoid()
 return inside and gui.Enabled and pg:GetAttribute("OpenPanel")==nil and root and h and h.Health>0 and not h.Sit and bounds(root.Position),root,h
end
local function resetTrail()
 trail:ClearAllChildren();table.clear(markers);clearUntil=0;clear.Text="Clear trail";updateCount()
end
local function dropAcorn()
 local usable,root,h=canUse()
 if not usable or UIS:GetFocusedTextBox()or os.clock()-lastDrop<.4 then return end
 lastDrop=os.clock();clearUntil=0;clear.Text="Clear trail"
 if #markers>=MAX then message("Trail full — clear to start again");return end
 if h.FloorMaterial==Enum.Material.Air then message("Stand on the path to drop one");return end
 -- Under the player's feet, never through a wall or onto bamboo overhead.
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 local exclude={trail};for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(exclude,p.Character)end end
 params.FilterDescendantsInstances=exclude;params.RespectCanCollide=true
 local hit=workspace:Raycast(root.Position,Vector3.new(0,-10,0),params)
 if not hit or hit.Normal.Y<.85 or math.abs(hit.Position.Y)>.75 or not bounds(hit.Position)then message("Drop an acorn on the maze path");return end
 for _,entry in ipairs(markers)do
  local d=entry.pos-hit.Position
  if d.X*d.X+d.Z*d.Z<SPACING*SPACING then message("There's already an acorn here");return end
 end
 local acorn=template:Clone();acorn.Name=string.format("TrailAcorn_%03d",#markers+1)
 acorn:PivotTo(CFrame.new(hit.Position+Vector3.new(0,.045,0))*CFrame.Angles(0,math.rad((#markers*137.5)%360),0))
 acorn.Parent=trail
 table.insert(markers,{model=acorn,pos=hit.Position})
 message("Acorn dropped · only you see your trail");updateCount()
end
on(drop.Activated,dropAcorn)
on(clear.Activated,function()
 if not canUse()then return end
 if #markers==0 then message("Your trail is already clear");return end
 if os.clock()<clearUntil then resetTrail();message("Trail cleared")
 else clearUntil=os.clock()+3;clear.Text="Clear? Again";message("Tap Clear again to remove your trail")end
end)
on(UIS.InputBegan,function(input,processed)
 if not processed and (input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.ButtonY)then dropAcorn()end
end)
local function arrange()
 local camera=workspace.CurrentCamera;if not camera then return end
 local size=camera.ViewportSize
 local touch=UIS.PreferredInput==Enum.PreferredInput.Touch
 local gamepad=UIS.PreferredInput==Enum.PreferredInput.Gamepad
 drop.Text=gamepad and "Y  Drop acorn"or(touch and "Drop acorn"or"G  Drop acorn")
 if size.X<600 then card.AnchorPoint=Vector2.new(.5,0);card.Position=UDim2.new(.5,0,0,96)
 else card.AnchorPoint=Vector2.new(.5,1);card.Position=UDim2.new(.5,0,1,touch and -112 or -94)end
end
on(UIS:GetPropertyChangedSignal("PreferredInput"),arrange)
on(maze:GetAttributeChangedSignal("LayoutSeed"),function()resetTrail();message("New maze · a fresh trail")end)
local elapsed=0
on(Run.Heartbeat,function(dt)
 elapsed+=dt;if elapsed<.15 then return end;elapsed=0
 local root,h=rootAndHumanoid();inside=root~=nil and h~=nil and h.Health>0 and bounds(root.Position)or false
 gui.Enabled=inside and pg:GetAttribute("OpenPanel")==nil
 gui:SetAttribute("InsideMaze",inside)
 if clearUntil>0 and os.clock()>=clearUntil then clearUntil=0;clear.Text="Clear trail"end
 updateCount();arrange()
end)
local cleaned=false
local function cleanup()
 if cleaned then return end;cleaned=true
 for _,c in ipairs(connections)do c:Disconnect()end
 trail:Destroy();gui:Destroy()
end
on(script.Destroying,cleanup)
updateCount();arrange()
]====];client.Parent=bridge
local probe=Instance.new("ModuleScript");probe.Source="return function()\n"..client.Source.."\nend";probe.Parent=game.ServerStorage
local ok,fn=pcall(require,probe);probe:Destroy();assert(ok,fn);assert(type(fn)=="function")
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("Before personal maze acorn trail")end
local old=game.ReplicatedStorage:FindFirstChild("MazeTrail1")
if old then old:Destroy()end
bridge.Parent=game.ReplicatedStorage
for s,text in pairs(saved)do assert(s.Source==text,"Existing maze script changed")end
assert(#maze:GetDescendants()==mazeCount,"Maze geometry or reward changed")
if not Run:IsRunning()then game.ChangeHistoryService:SetWaypoint("After personal maze acorn trail")end
print("QQ MAZE TRAIL: three-mesh fallen acorn; personal client-only markers; G/ButtonY/touch; free; no currency or reward calls")
print("QQ MAZE TRAIL LIMITS: maze ground only; 3-stud spacing; 300 maximum; clear requires second tap; retained until cleared or session ends")
print("QQ MAZE TRAIL PRESERVED: existing maze layout, walls, camera, daily reward and scripts unchanged")
print("QQ MAZE TRAIL STATUS: "..(Run:IsRunning()and"SERVER PREVIEW"or"EDIT INSTALLED").."; NOT PUBLISHED")
