import json,sys
L={
# client: log every speech sound created under a squirrel (loaded? playing? length)
'snd':"workspace.DescendantAdded:Connect(function(d) if d:IsA('Sound') and d.Parent and d.Parent.Parent and d.Parent.Parent.Name:find('_color') then task.wait(0.6) warn('QY@SND',d.Parent.Parent.Name,d.SoundId,d.IsLoaded,d.IsPlaying,math.floor(d.TimeLength*10)/10) end end) warn('QY@sndhook')",
# client: go to the bottom station by Tonio
'go':"game.Players.LocalPlayer.Character:PivotTo(CFrame.new(331,-43,-606))",
# client: walk-up spot 4 studs in front of the nearest seat of a docked car; report
'seat':"local hr=game.Players.LocalPlayer.Character.HumanoidRootPart local b,bd for _,s in workspace.PortoNocciola['15 Funicolare'].Cars:GetDescendants() do if s:IsA('Seat') then local d=(s.Position-hr.Position).Magnitude if not bd or d<bd then b,bd=s,d end end end _G.S=b hr.Parent:PivotTo(CFrame.lookAt(b.Position+b.CFrame.LookVector*4+Vector3.new(0,2,0),b.Position)) warn('QY@seat',b:GetFullName(),math.floor(bd))",
# client: state
'st':"local h=game.Players.LocalPlayer.Character.Humanoid warn('QY@st sit',h.Sit,_G.S and tostring(_G.S.Occupant),game.Players.LocalPlayer:GetAttribute('Found_porto'),_G.S and _G.S:FindFirstAncestorWhichIsA('Model'):GetAttribute('Docked'))",
# client: drop straight onto the seat (touch auto-sit)
'drop':"game.Players.LocalPlayer.Character:PivotTo(_G.S.CFrame+Vector3.new(0,3,0))",
# server: lock test as the owner
'nb':"workspace.PortoNocciola['15 Funicolare']:SetAttribute('NoOwnerBypass',true) warn('QY@nb on')",
# client: Enzo + Beppe bubbles through the same module call they use
'eb':"local B=require(game.ReplicatedStorage.SquirrelBubble) for _,n in {'crabcatcher_squirrel_color','fishmonger_squirrel_color'} do local m=workspace:FindFirstChild(n) warn('QY@spk',n,m~=nil) if m then B.say(m,'test line',{secs=3}) end end",
}
k=sys.argv[1]; s=L[k]
print(json.dumps([{"action":"type","text":s[i:i+15],"action_summary":"Types command chunk"} for i in range(0,len(s),15)]))
