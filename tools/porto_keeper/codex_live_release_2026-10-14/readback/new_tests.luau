local Celebration=require("./KeeperCelebration")
local function gate(clock)return Celebration.new(clock or function()return now end,function(at)return Core.day(at,9)end)end
test("Fresh signal occurs only on a newly collected 44th Italy squirrel",function()
 local d=environment(save(42));local emitted={}
 d.freshFire=function(p,rec)table.insert(emitted,{p=p,rec=Core.copy(rec)})end
 d.load();eq(#emitted,0);d.collect("porto_squirrel_43");eq(#emitted,0)
 d.collect("porto_squirrel_44");eq(#emitted,1);eq(emitted[1].p,d.player)
 d.drain();eq(emitted[1].rec.claimId,d.api.pending(d.player)[1].claimId)
 d.collect("porto_squirrel_44");d.api.save(d.player);d.drain();eq(#emitted,1)
 local reload=environment(d.store.data.u200);reload.freshFire=function()error("Load is not fresh")end;reload.load()
end)
local function freshRuntime()
 local d=environment(save(43));d.load();local ds=fakeStore({first=legacy});local k=keeper(d,ds)
 d.freshFire=function(p,rec)k.onFresh(p,rec)end
 d.collect("porto_squirrel_44");d.drain()
 return d,ds,k
end
test("Actual fresh win broadcasts stamped crown only after ledger commit",function()
 local d,ds,k=freshRuntime();eq(#k.broadcasts,0);eq(ds.writes,0)
 k.api.process(d.player);d.drain();eq(ds.writes,1);eq(#k.broadcasts,1);eq(k.publishes,1)
 local rec=k.broadcasts[1].rec;eq(rec.celebrationVersion,1);eq(rec.day,Core.day(now,9));eq(rec.celebrationAt,now)
 eq(ds.data[Core.KEY].winners["200"].celebrationAt,nil)
end)
test("Lost write response and repeated unacked win celebrate once",function()
 local d,ds,k=freshRuntime();ds.loseResponse=true;k.dropAck=true
 k.api.process(d.player);d.drain();eq(#k.broadcasts,1)
 k.api.process(d.player);d.drain();eq(#k.broadcasts,1);eq(k.publishes,1);eq(ds.writes,1)
end)
test("Current-day outbox recovery gets its award with no celebration",function()
 local rec=Epoch.newAttempt(200,"Test","Test",0,now,9,"recovered-today")
 local data=save(44);data.italyAttempts={["0"]=rec}
 local d=environment(data);d.load();local ds=fakeStore({first=legacy});local k=keeper(d,ds)
 k.api.process(d.player);d.drain();eq(ds.writes,1);eq(#k.broadcasts,0);eq(k.publishes,nil);eq(#k.acks,1)
 eq(d.player:GetAttribute("PortoKeeperTitle"),"Guardian of the Harbour")
end)
test("Rejoin replay of a committed winner does not celebrate again",function()
 local d,ds,k=freshRuntime();k.dropAck=true;k.api.process(d.player);d.drain();eq(#k.broadcasts,1)
 k.api.forget(d.player)
 local reload=environment(d.store.data.u200);reload.load();local second=keeper(reload,ds)
 second.api.process(reload.player);reload.drain();eq(#second.broadcasts,0);eq(second.publishes,nil);eq(ds.writes,1)
end)
test("Leaving before a delayed claim clears cosmetic eligibility only",function()
 local d,ds,k=freshRuntime();k.api.forget(d.player);k.api.process(d.player);d.drain()
 eq(ds.writes,1);eq(#k.acks,1);eq(#k.broadcasts,0)
end)
test("Historical completion never turns into current-day fireworks",function()
 local rec=candidate(200);rec.day-=1;rec.t-=86400
 local g=gate();local p={UserId=200};g.markFresh(p,rec);eq(g.localRecord(p,rec),nil)
end)
test("Cosmetic token does not mutate original award record",function()
 local rec=candidate(200);local p={UserId=200};local g=gate();g.markFresh(p,rec)
 local event=g.localRecord(p,rec);assert(event and event~=rec);eq(rec.celebrationAt,nil);eq(rec.celebrationVersion,nil)
 assert(g.accept(event));eq(g.localRecord(p,rec),nil)
end)
test("Remote live win must match persisted claim and is consumed once",function()
 local rec=candidate(200);local g=gate()
 eq(g.remoteRecord(rec,{claimId="wrong",celebrationVersion=1,celebrationAt=now}),nil)
 local event=g.remoteRecord(rec,{claimId=rec.claimId,celebrationVersion=1,celebrationAt=now})
 assert(event and g.accept(event));assert(not g.accept(event))
end)
test("Startup suppresses broadcasts older than this server or client",function()
 local clock=now;local old=candidate(200);old.celebrationVersion=1;old.celebrationAt=clock
 local first=gate(function()return clock end);assert(first.accept(old))
 clock+=0.01;local rejoined=gate(function()return clock end);assert(not rejoined.accept(old))
end)
test("Legacy messages and stale or future timestamps cannot celebrate",function()
 local clock=now;local g=gate(function()return clock end);local rec=candidate(200)
 eq(g.remoteRecord(rec,{claimId=rec.claimId}),nil)
 rec.celebrationVersion=1;rec.celebrationAt=clock;clock+=121;assert(not g.accept(rec))
 rec.celebrationAt=clock+6;assert(not g.accept(rec))
 rec.celebrationAt=0/0;assert(not g.accept(rec))
end)
test("Rollover rejects a previously current-day celebration",function()
 local clock=now;local g=gate(function()return clock end);local rec=candidate(200)
 rec.celebrationVersion=1;clock+=86400;rec.celebrationAt=clock;assert(not g.accept(rec))
end)
test("Client actual crown handler shows one banner, chat and 25-second show",function()
 local handler;local output,banners,shows={},{},{};local g=gate()
 clientFactory({ev={OnClientEvent={Connect=function(_,fn)handler=fn end}},player={UserId=200},
  workspace={FindFirstChild=function()return nil end},os=os,celebrationGate=g,
  chat=function(s)table.insert(output,s)end,banner=function(...)table.insert(banners,{...})end,fireworks=function(secs)table.insert(shows,secs)end})
 local rec=candidate(200);rec.celebrationAt=now;rec.celebrationVersion=1
 handler("crowned",rec);handler("crowned",rec)
 eq(#output,1);eq(#banners,1);eq(#shows,1);eq(shows[1],25);assert(banners[1][1]:find("You are",1,true))
end)
test("Other clients see the winner's name in the same broadcast",function()
 local handler;local message
 clientFactory({ev={OnClientEvent={Connect=function(_,fn)handler=fn end}},player={UserId=999},
  workspace={FindFirstChild=function()return nil end},os=os,celebrationGate=gate(),
  chat=function()end,banner=function(s)message=s end,fireworks=function()end})
 local rec=candidate(200);rec.name="Test winner";rec.celebrationAt=now;rec.celebrationVersion=1
 handler("crowned",rec);assert(message:find("Test winner",1,true))
end)
test("Recovery, losing and already-won receipts have no VFX or crown banner",function()
 local handler
 clientFactory({ev={OnClientEvent={Connect=function(_,fn)handler=fn end}},player={UserId=200},workspace={},os=os,
  celebrationGate=gate(),chat=function()end,banner=function()error("unexpected banner")end,fireworks=function()error("unexpected show")end})
 handler("recovered",{claimId="recover",day=Core.day(now,9)-1});handler("late",{claimId="loss",day=Core.day(now,9),name="Other"});handler("already")
end)
local bannerFactory=require("./banner_fixture")
test("Actual banner queue waits behind the honours banner",function()
 local clock,shown=0,nil;local visible=true
 local pg={FindFirstChild=function(_,name)
  if name=="HonourBar" then return {FindFirstChild=function()return {IsA=function()return true end,Visible=visible}end}end
 end}
 local banner=bannerFactory({pg=pg,os={clock=function()return clock end},task={spawn=function(fn)fn()end,wait=function(t)clock+=t;if clock>=1.2 then visible=false end end},showBanner=function()shown=clock end})
 banner("Winner","Italy");assert(shown>=1.2 and shown<2)
end)
test("Actual banner queue waits behind daily card and has a bounded fallback",function()
 local clock,shown=0,nil
 local pg={FindFirstChild=function(_,name)if name=="DailyGui" then return {Enabled=true,FindFirstChild=function()return {IsA=function()return true end,Visible=true}end}end end}
 local banner=bannerFactory({pg=pg,os={clock=function()return clock end},task={spawn=function(fn)fn()end,wait=function(t)clock+=t end},showBanner=function()shown=clock end})
 banner("Winner","Italy");assert(shown>=90 and shown<91)
end)
local chatFactory=require("./chat_fixture")
test("Actual chat uses modern channel and escapes display text",function()
 local delivered
 local chat=chatFactory({task={spawn=function(fn)fn()end},warn=function()error("unexpected warning")end,
  TextChatService={WaitForChild=function(_,name)eq(name,"TextChannels");return {WaitForChild=function(_,channel)eq(channel,"RBXGeneral");return {DisplaySystemMessage=function(_,text)delivered=text end}end}end}})
 chat("A & B <winner>");eq(delivered,"A &amp; B &lt;winner&gt;")
end)
test("Missing chat channel cannot crash the celebration handler",function()
 local warnings=0
 local chat=chatFactory({task={spawn=function(fn)fn()end},warn=function()warnings+=1 end,TextChatService={WaitForChild=function()return nil end}})
 chat("Winner");eq(warnings,1)
end)
test("Firework setup failure does not suppress banner or chat",function()
 local handler;local messages,banners,warnings=0,0,0
 clientFactory({ev={OnClientEvent={Connect=function(_,fn)handler=fn end}},player={UserId=200},
  workspace={FindFirstChild=function()return nil end},os=os,celebrationGate=gate(),
  chat=function()messages+=1 end,banner=function()banners+=1 end,fireworks=function()error("No audio")end,warn=function()warnings+=1 end})
 local rec=candidate(200);rec.celebrationAt=now;rec.celebrationVersion=1
 handler("crowned",rec);eq(messages,1);eq(banners,1);eq(warnings,1)
end)
local vfxFactory=require("./vfx_fixture")
test("Actual fireworks scheduler runs 25 seconds at surveyed Italy sites even if audio fails",function()
 local clock,rockets=0,{}
 local vec={};function vec.new(x,y)return setmetatable({X=x,Y=y},{__sub=function(a,b)return {Magnitude=math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2)}end})end
 local dependencies={task={spawn=function(fn)fn()end,delay=function()end,wait=function(secs)clock+=secs end},os={clock=function()return clock end},
  F={GetAttribute=function()return nil end},Instance={new=function(kind)eq(kind,"Sound");return {Play=function()error("Audio denied")end}end},
  game={GetService=function()return {}end},workspace={CurrentCamera={CFrame={Position={X=490,Z=-1130}}}},Vector3={zero={X=0,Z=0}},Vector2=vec,
  rocket=function(x,z,y)table.insert(rockets,{x=x,z=z,y=y})end}
 local show=vfxFactory(dependencies);show(25);assert(clock>=25 and clock<26);assert(#rockets>50 and #rockets<300)
 for _,r in ipairs(rockets)do assert(r.x>=240 and r.x<=490 and r.z<=-580 and r.z>=-1130 and r.y>=-53 and r.y<17)end
 eq(rockets[1].x,490);eq(rockets[1].z,-1130)
end)
