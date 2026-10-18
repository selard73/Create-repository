from pathlib import Path
D=Path(__file__).resolve().parent
client=(D/'MazeTrailClient.lua').read_text(encoding='utf-8')
header='''-- Acorn trail: preview in Play Server; stopped Edit requires Shannon's yes.
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
client.Source=[====[__CLIENT__]====];client.Parent=bridge
local probe=Instance.new("ModuleScript");probe.Source="return function()\\n"..client.Source.."\\nend";probe.Parent=game.ServerStorage
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
'''
(D/'install_maze_trail1.lua').write_text(header.replace('__CLIENT__',client),encoding='utf-8')
print('Maze trail installer prepared')
