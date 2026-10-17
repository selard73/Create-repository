-- Run after catcafe1.lua: play-test Server first; approved Edit installation later.
-- The existing MapMusic player handles the cafe playlist and its entry/exit fades.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and game.PlaceId==117372258657114,"Wrong place or not Studio")
assert(Run:IsRunning() or CATCAFE1_ALLOW_EDIT==true,"Preview first; Edit requires Shannon's approval")
local J=assert(workspace:FindFirstChild("JapanMap"))
local cafe=assert(J:FindFirstChild("ShopFronts") and J.ShopFronts:FindFirstChild("CatCafe"),"Build the cafe preview first")
assert(cafe:GetAttribute("CatCafeBuildVersion")=="cafe1","Unexpected cafe version")
local music=assert(workspace:FindFirstChild("MapMusic"))
local client=assert(music:FindFirstChild("MusicClient"))
assert(client:IsA("Script") and client.RunContext==Enum.RunContext.Client,"Unexpected music controller")
local original=client.Source
local updated=original
local function replaceOnce(s,old,new)
 local a,b=s:find(old,1,true)
 assert(a and not s:find(old,b+1,true),"Music source changed; review before patching: "..old)
 return s:sub(1,a-1)..new..s:sub(b+1)
end
local zone=[==[
local function areaAt(pos)
	-- CATCAFE1_AUDIO_20261017: the cafe takes priority over the street district.
	local cafeFrame=folder:GetAttribute("JapanCatCafeFrame")
	local cafeHalf=folder:GetAttribute("JapanCatCafeHalfSize")
	if isPreview() and typeof(cafeFrame)=="CFrame" and typeof(cafeHalf)=="Vector3" then
		local p=cafeFrame:PointToObjectSpace(pos)
		if math.abs(p.X)<=cafeHalf.X and math.abs(p.Y)<=cafeHalf.Y and math.abs(p.Z)<=cafeHalf.Z then
			return "japan_catcafe"
		end
	end
]==]
local startup=[==[
local folder = script.Parent
-- These sounds belong to this controller. Retire its old voices on a preview restart.
for _,s in ipairs(SoundService:GetChildren())do
	if s:IsA("Sound") and (s.Name=="MusicA" or s.Name=="MusicB" or s.Name=="CatCafeMeow")then s:Stop();s:Destroy()end
end
]==]
local meows=[==[

-- CATCAFE1_MEOWS_20261017: one local call at a time, only while inside the cafe.
local meow=Instance.new("Sound")
meow.Name="CatCafeMeow";meow.Volume=.28;meow.Looped=false;meow.Parent=SoundService
local meowIds={"134699420140804","134881862056957","83454004588488","133371725828981"}
local rng=Random.new()
task.spawn(function()
	local wasInside=false
	local nextCall=0
	local last=0
	local stopAt=0
	while script.Parent and meow.Parent do
		local now=os.clock()
		if current=="japan_catcafe" and player.Character and player.Character:FindFirstChild("HumanoidRootPart")then
			if not wasInside then nextCall=now+rng:NextNumber(12,22);wasInside=true end
			-- Bound failed loads or unexpectedly long clips; never overlap two meows.
			if meow.IsPlaying and now>=stopAt then meow:Stop()end
			if now>=nextCall and not meow.IsPlaying then
				local pick=rng:NextInteger(1,#meowIds-(last>0 and 1 or 0))
				if last>0 and pick>=last then pick+=1 end
				last=pick;meow.SoundId="rbxassetid://"..meowIds[pick]
				meow.TimePosition=0;meow:Play()
				stopAt=now+20;nextCall=now+rng:NextNumber(30,60)
			end
		elseif wasInside then
			meow:Stop();wasInside=false
		end
		task.wait(.25)
	end
end)
]==]
if not updated:find("CATCAFE1_AUDIO_20261017",1,true)then
 updated=replaceOnce(updated,"local function areaAt(pos)\n",zone)
 updated=replaceOnce(updated,"local folder = script.Parent\n",startup)
 updated=replaceOnce(updated,'"japan_countryside", "japan_teahouse"','"japan_countryside", "japan_teahouse", "japan_catcafe"')
 updated..=meows
else
 assert(updated:find("CATCAFE1_MEOWS_20261017",1,true),"Incomplete cafe audio patch; review first")
end
local values={
 japan_catcafe="91013239854044,132290528373653",
 Volume_japan_catcafe=.22,
 JapanCatCafeFrame=cafe:GetPivot()*CFrame.new(0,4,-10),
 JapanCatCafeHalfSize=Vector3.new(12.7,4.2,9.9),
}
local oldValues={};for key in pairs(values)do oldValues[key]=music:GetAttribute(key)end
local wasEnabled=client.Enabled
local SS=game:GetService("ServerStorage")
local hb=SS:FindFirstChild("HudBackup")
if not hb then hb=Instance.new("Folder");hb.Name="HudBackup";hb.Parent=SS end
if not hb:FindFirstChild("CatCafe1MusicOriginal")then
 assert(not original:find("CATCAFE1_AUDIO_20261017",1,true),"Original music backup missing; stop before editing")
 local backup=Instance.new("Folder");backup.Name="CatCafe1MusicOriginal"
 local copy=client:Clone();copy.Name="MusicClient";copy.Enabled=false;copy.Parent=backup
 backup:SetAttribute("OriginalEnabled",wasEnabled)
 for key in pairs(values)do backup:SetAttribute("Had_"..key,oldValues[key]~=nil);backup:SetAttribute(key,oldValues[key])end
 backup.Parent=hb
end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("Before Cat cafe1 audio")end)
local ok,err=pcall(function()
 client.Enabled=false
 if Run:IsRunning()then task.wait(.2)end
 for key,value in pairs(values)do music:SetAttribute(key,value)end
 client.Source=updated
 if Run:IsRunning()then task.wait(.2)end
 client.Enabled=wasEnabled
end)
if not ok then
 client.Enabled=false;client.Source=original
 for key in pairs(values)do music:SetAttribute(key,oldValues[key])end
 client.Enabled=wasEnabled
 error("Cafe audio changes reverted: "..tostring(err))
end
pcall(function()game:GetService("ChangeHistoryService"):SetWaypoint("After Cat cafe1 audio")end)
print("QQ CATCAFE1 AUDIO: playlist 91013239854044,132290528373653; cafe volume 0.22; existing map fades retained")
print("QQ CATCAFE1 MEOWS: 134699420140804,134881862056957,83454004588488,133371725828981; one at a time, 30-60 seconds apart, no immediate repeat")
print("QQ CATCAFE1 AUDIO VERIFY: check all six asset loads and both playlist transitions in the Client; configuration is not proof of audibility")
print("QQ CATCAFE1 AUDIO STATUS: "..(Run:IsRunning() and "PLAY-TEST SERVER PREVIEW ONLY; discarded on stop" or "EDIT; NOT PUBLISHED"))
