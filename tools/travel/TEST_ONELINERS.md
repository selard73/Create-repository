# Travel / boat play-test one-liners (Oct 1 2026)

Typed into the command bar during a Studio play test (Client / Server tab as marked). Attributes only; with API access off
nothing is saved. Never run outside a play test.

**Server: the 44 finds as attributes (opens the gates; the boat lock)**
```lua
local p=game.Players:GetPlayers()[1] p:SetAttribute("Found_forest",15) p:SetAttribute("Found_village",14) p:SetAttribute("Found_domaine",15) p:SetAttribute("SquirrelsFound",44) print("QQ G44 test attributes set (no save)")
```

**Server: open Porto Nocciola for the test player (Item_porto = 1 through AwardItems)**
```lua
local p=game.Players:GetPlayers()[1] game.ReplicatedStorage.AwardItems:Fire(p,"porto",1) task.wait(0.4) print("QQ TG item_porto="..tostring(p:GetAttribute("Item_porto")).." area="..tostring(p:GetAttribute("Area")).." loaded="..tostring(p:GetAttribute("SaveLoaded")).." rank="..tostring(p:GetAttribute("Item_frenchrank")))
```

**Client: hold the nearest travel board (tools/travel/tt_go_cli.lua)** - fade, teleport, report after 3.5 s.

**Client: onto the jetty and take the boat (4 holds: 3 warnings, the 4th sails; the owner needs no 44)**
```lua
local plr=game.Players.LocalPlayer local ch=plr.Character local hum=ch:FindFirstChildOfClass("Humanoid") hum:ChangeState(Enum.HumanoidStateType.GettingUp) ch:PivotTo(CFrame.lookAt(Vector3.new(161.6,3.6,-165.5),Vector3.new(157.6,3.6,-165.5))) task.wait(1) local pr=workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt pr.RequiresLineOfSight=false pr.MaxActivationDistance=30 task.wait(0.5) for i=1,4 do pr:InputHoldBegin() task.wait(0.8) pr:InputHoldEnd() task.wait(1.4) end task.wait(1) hum=plr.Character:FindFirstChildOfClass("Humanoid") print("QQ BT seat="..tostring(hum.SeatPart and hum.SeatPart.Name).." busy="..tostring(workspace.Boat:GetAttribute("DockBusy")))
```
Then click the viewport, hold W (5 s = 50 studs), press Space to jump out.

**Client: the runaway boat, the dock and me, twice**
```lua
local plr=game.Players.LocalPlayer local function rep(tag) local r=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") local b=nil for _,m in ipairs(workspace.Boat:GetChildren()) do if m:IsA("Model") and m.Name:sub(1,5)=="Boat_" then b=m end end local v=workspace.River.BoatPreview:FindFirstChildWhichIsA("MeshPart",true) print(string.format("QQ AD %s me=(%.1f,%.1f,%.1f) state=%s boat=%s adrift=%s busy=%s visT=%s", tag, r.Position.X, r.Position.Y, r.Position.Z, tostring(hum and hum:GetState()), b and b.PrimaryPart and string.format("(%.1f,%.1f,%.1f)", b.PrimaryPart.Position.X, b.PrimaryPart.Position.Y, b.PrimaryPart.Position.Z) or "none", tostring(b and b:GetAttribute("Adrift")), tostring(workspace.Boat:GetAttribute("DockBusy")), tostring(v.Transparency))) end rep("t0") task.wait(6) rep("t6")
```

**Edit mode: install without the clipboard** - pack the installer as a PatchModule (tools/travel/export/*.rbxmx, see the
python in this chat's handoff), Explorer > right-click Workspace > Insert > Import Roblox Model > type the path > Enter,
then `require(workspace.InstallBoat.PatchModule)()` and `workspace.InstallBoat:Destroy()`.
