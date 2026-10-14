local Core = require("./DailyKeeperCore")
local Store = require("./DailyKeeperStore")
local Epoch = require("./FindsEpoch")
local setupFactory = require("./setup_fixture")
local passed = 0
local function eq(actual, expected, message)
    assert(actual == expected, (message or "mismatch") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err), 0) end
    passed += 1; print("PASS " .. name)
end
local function size(t) local n=0;for _ in pairs(t or {}) do n+=1 end;return n end
local function entries()
    local out={}
    for _,pair in ipairs({{"porto",44},{"forest",15},{"village",14},{"domaine",15}}) do
        for i=1,pair[2] do table.insert(out,{id=pair[1].."_squirrel_"..i,map=pair[1],name=pair[1]..i}) end
    end
    return out
end
local registry={squirrels=entries(),maps={{id="porto"},{id="forest"},{id="village"},{id="domaine"}}}
local all, italy=Core.registry(registry.squirrels)
local function ids(n, france)
    local list={};for i=1,n do table.insert(list,"porto_squirrel_"..i) end
    if france then for i=1,15 do table.insert(list,"forest_squirrel_"..i) end end
    return list
end
local legacy={uid=1092515898,name="Darknight",user="superjohn9453",t=1791702904,total=44}
local now=100*86400+9*3600+100
local function candidate(uid,epoch,at,token)
    at=at or now
    return {uid=uid,name="Player"..uid,user="user"..uid,epoch=epoch or 0,t=at,day=Core.day(at,9),total=44,claimId=token or ("claim-"..uid.."-"..tostring(epoch or 0).."-"..at)}
end
local function fakeStore(initial)
    local ds={data=Core.copy(initial or {}),writes=0,reads=0,history={}}
    function ds:GetAsync(key)
        self.reads+=1
        if self.failRead then error("read unavailable") end
        if self.readOverride then return self.readOverride(key) end
        return Core.copy(self.data[key])
    end
    function ds:UpdateAsync(key,fn)
        if self.failWrite then error("write unavailable") end
        local value=fn(Core.copy(self.data[key]))
        if self.hook then local hook=self.hook;self.hook=nil;hook(key,fn);value=fn(Core.copy(self.data[key])) end
        if value then self.data[key]=Core.copy(value);self.writes+=1;table.insert(self.history,{key=key,value=Core.copy(value)}) end
        if self.loseResponse then self.loseResponse=false;error("committed but response lost") end
        return value and Core.copy(value) or nil
    end
    return ds
end
local function adapter(ds)
    return Store.new(Core,ds,{now=function()return now end,wait=function()end,offsetHours=9})
end

test("09:00 UTC boundary",function()
    eq(Core.day(100*86400+32399,9),99);eq(Core.day(100*86400+32400,9),100)
end)
test("Owner and listed IDs excluded without partial ID matches",function()
    assert(Core.excluded(9611145467,9611145467,true,""))
    assert(Core.excluded(200,9611145467,true,"100,200,300"))
    assert(not Core.excluded(20,9611145467,true,"100,200,300"))
    assert(not Core.excluded(9611145467,9611145467,false,""))
end)
test("Italy IDs deduplicated and normalized; France excluded",function()
    local list=ids(43,true);table.insert(list,"porto_squirrel_1_color");table.insert(list,"porto_squirrel_1_99")
    eq(Core.count(table.concat(list,","),all,italy),43)
    table.insert(list,"porto_squirrel_44");eq(Core.count(table.concat(list,","),all,italy),44)
    assert(not Core.freshCompletion("forest_squirrel_1",table.concat(list,","),0,all,italy))
end)
test("Legacy winner preserved and excluded without touching first",function()
    local ds=fakeStore({first=legacy});local api=adapter(ds)
    eq(api.claim(candidate(legacy.uid,5)),"already");eq(ds.writes,0)
    eq(ds.data.first.t,legacy.t);eq(ds.data.first.uid,legacy.uid)
    eq(api.claim(candidate(2)),"won")
    eq(ds.data.first.claimId,nil);eq(ds.data[Core.KEY].legacy.uid,legacy.uid)
    eq(ds.data[Core.KEY].winners[tostring(legacy.uid)].t,legacy.t)
end)
test("Concurrent callback retry selects one global winner",function()
    local ds=fakeStore({first=legacy});local a,b=adapter(ds),adapter(ds)
    assert(a.refresh());assert(b.refresh())
    ds.hook=function() eq(b.claim(candidate(20)),"won") end
    local status,holder=a.claim(candidate(10))
    eq(status,"late");eq(holder.uid,20);eq(size(ds.data[Core.KEY].days),1)
    eq(ds.data[Core.KEY].winners["10"],nil)
end)
test("Late completer must increment reset generation on another day",function()
    local ds=fakeStore({first=legacy});local api=adapter(ds)
    eq(api.claim(candidate(1)),"won");eq(api.claim(candidate(2)),"late")
    now+=86400
    eq(api.claim(candidate(2)),"attempted")
    eq(api.claim(candidate(2,1)),"won")
    now-=86400
end)
test("Winning again is blocked even after reset and rollover",function()
    local api=adapter(fakeStore({first=legacy}));eq(api.claim(candidate(5)),"won")
    now+=86400;eq(api.claim(candidate(5,1)),"already");now-=86400
end)
test("Successful write with lost response recovers same award",function()
    local ds=fakeStore({first=legacy});ds.loseResponse=true
    local api=adapter(ds);local rec=candidate(6)
    eq(api.claim(rec),"won");eq(ds.writes,1);eq(api.claim(rec),"won");eq(ds.writes,1)
end)
test("Read and write outages fail closed",function()
    local ds=fakeStore({first=legacy});ds.failRead=true;local api=adapter(ds)
    eq(api.claim(candidate(7)),"unavailable");eq(ds.writes,0)
    ds.failRead=false;ds.failWrite=true
    eq(api.claim(candidate(7)),"unavailable");eq(ds.data[Core.KEY],nil)
end)
test("Missing store cannot fabricate a winner",function()
    local api=Store.new(Core,nil,{now=function()return now end,wait=function()end})
    eq(api.claim(candidate(7)),"unavailable")
end)
test("Unreadable legacy and unsupported ledger never overwritten",function()
    local ds=fakeStore({first="invalid"});eq(adapter(ds).claim(candidate(8)),"unavailable");eq(ds.writes,0)
    ds=fakeStore({first=legacy,[Core.KEY]={version=99}});eq(adapter(ds).claim(candidate(8)),"unavailable");eq(ds.writes,0)
end)
test("Rollover clears today's selection and old retries stay on their day",function()
    local at=100*86400+32400-1;local oldNow=now;now=at+2
    local ds=fakeStore({first=legacy});local api=adapter(ds)
    eq(api.claim(candidate(9,0,at)),"won");eq(Core.current(api.snapshot(),now,9),nil)
    eq(api.claim(candidate(10)),"won");eq(Core.current(api.snapshot(),now,9).uid,10)
    eq(size(ds.data[Core.KEY].days),2);now=oldNow
end)
test("Expired completion cannot claim on a future day",function()
    local api=adapter(fakeStore({first=legacy}));eq(api.claim(candidate(9,0,now-301)),"expired")
end)
test("Slow refresh cannot replace newer committed cache",function()
    local ds=fakeStore({first=legacy});local api=adapter(ds);assert(api.refresh())
    eq(api.claim(candidate(9)),"won")
    ds.readOverride=function(key) if key=="first" then return legacy end;return nil end
    assert(api.refresh());eq(Core.current(api.snapshot(),now,9).uid,9)
end)
test("Polling observes another server's winner",function()
    local ds=fakeStore({first=legacy});local a,b=adapter(ds),adapter(ds)
    assert(b.refresh());eq(a.claim(candidate(50)),"won");assert(b.refresh())
    eq(Core.current(b.snapshot(),now,9).uid,50)
end)
test("Renderer recovers exception and missing avatar",function()
    local calls=0
    local r=Core.renderer(function() calls+=1;if calls==1 then error("avatar unavailable") end;return calls>2 end,function(f)f()end)
    r.request("day1",{});local key,busy=r.status();eq(key,nil);eq(busy,false)
    r.request("day1",{});eq(r.status(),nil)
    r.request("day1",{});eq(r.status(),"day1")
    r.request("day1",{});eq(calls,3)
    r.request("day1",{},true);eq(calls,4)
end)
test("A slow old render is followed by latest requested winner",function()
    local r;local rendered={}
    r=Core.renderer(function(rec)
        table.insert(rendered,rec.uid)
        if rec.uid==1 then r.request("new",{uid=2}) end
        return true
    end,function(f)f()end)
    r.request("old",{uid=1});eq(r.status(),"new");eq(rendered[2],2)
end)

local function environment(data)
    local d={Registry=registry,store=fakeStore({u200=data}),clock=100,warnings={},events={},resetEvents=0,queue={}}
    d.Players={}
    d.RunService={IsStudio=function()return false end}
    d.os={clock=function()return d.clock end,time=function()return now end}
    d.task={}
    function d.task.spawn(fn)
        local co=coroutine.create(fn);local ok,err=coroutine.resume(co);assert(ok,err)
        if coroutine.status(co)~="dead" then table.insert(d.queue,co) end
    end
    function d.task.wait(n) d.clock+=n or 0.1;coroutine.yield() end
    function d.drain()
        local steps=0
        while #d.queue>0 do
            steps+=1;assert(steps<1000,"mock scheduler stuck")
            local co=table.remove(d.queue,1);local ok,err=coroutine.resume(co);assert(ok,err)
            if coroutine.status(co)~="dead" then table.insert(d.queue,co) end
        end
    end
    d.Journal={merge=function(a,b) local t=Core.copy(a);for k,v in pairs(b)do t[k]=Core.copy(v)end;return t end}
    local seq=0
    d.Http={JSONEncode=function()return "journal"end,GenerateGUID=function()seq+=1;return "reset-"..seq end}
    d.workspace={FindFirstChild=function()return nil end}
    d.folder={GetAttribute=function(_,k)if k=="ClickDistance"then return 32 end end}
    local rs={FindFirstChild=function()return nil end}
    d.game={GetService=function()return rs end}
    d.ev={FireClient=function()end}
    d.collectedEv={Fire=function(_,...)table.insert(d.events,{...})end}
    d.resetFire=function()d.resetEvents+=1 end
    d.warn=function(message)table.insert(d.warnings,message)end
    local vector=setmetatable({Magnitude=0},{__sub=function()return {Magnitude=0}end})
    d.mesh={Position=vector,Size=vector}
    local humanoid={Health=100}
    local root={Position=vector}
    local character={FindFirstChild=function(_,k)if k=="HumanoidRootPart"then return root end end,FindFirstChildOfClass=function()return humanoid end}
    d.player={UserId=200,Name="Test",DisplayName="Test",Parent=d.Players,Character=character,attributes={}}
    function d.player:GetAttribute(k)return self.attributes[k]end
    function d.player:SetAttribute(k,v)self.attributes[k]=v end
    d.model={GetAttribute=function()return nil end}
    d.api=setupFactory(d)
    function d.load()d.api.load(d.player)end
    function d.collect(id)d.api.collect(d.player,d.model,id,d.mesh)end
    function d.reset()d.task.spawn(function()d.api.reset(d.player)end);d.drain()end
    return d
end
local function save(n)
    return {found=ids(n,true),acorns=123,items={porto=1,hat=2},passport={stamp={at=1}},area="village"}
end
test("Joining with 44 never emits a fresh completion",function()
    local d=environment(save(44));d.load();eq(#d.events,0)
    d.collect("porto_squirrel_44");d.drain();eq(#d.events,0)
    d.collect("village_squirrel_1");d.drain();eq(#d.events,0)
end)
test("Actual 44th find is saved before emitting award candidate",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    eq(#d.events,1);eq(#d.store.data.u200.found,59);eq(d.events[1][2][1].epoch,0)
    eq(d.store.data.u200.acorns,123);eq(d.store.data.u200.items.hat,2);eq(d.store.data.u200.passport.stamp.at,1)
    d.collect("porto_squirrel_44");d.drain();eq(#d.events,1)
end)
test("Pending currency and items received before load are not erased",function()
    local d=environment(save(43));d.api.owe(200,9);d.api.owe(200,1,"hat")
    d.load();assert(d.api.save(d.player))
    eq(d.store.data.u200.acorns,132);eq(d.store.data.u200.items.hat,3)
end)
test("Failed completion save cannot trigger an award",function()
    local d=environment(save(43));d.load();d.store.failWrite=true
    d.collect("porto_squirrel_44");d.drain();eq(#d.events,0);eq(#d.store.data.u200.found,58)
end)
test("Loaded completion reset to zero then recollected qualifies",function()
    local d=environment(save(44));d.load();d.reset();eq(d.api.snapshot(200).epoch,1)
    eq(d.player:GetAttribute("Found_porto"),0);eq(d.resetEvents,1)
    for i=1,44 do d.collect("porto_squirrel_"..i)end;d.drain()
    eq(#d.events,1);eq(d.events[1][2][1].epoch,1);eq(#d.store.data.u200.found,44)
end)
test("Explicit existing reset clears finds only and preserves valuables/history",function()
    local data=save(44);data.custom={important=true}
    local d=environment(data);d.load();d.reset()
    eq(#d.store.data.u200.found,0);eq(d.store.data.u200.acorns,123)
    eq(d.store.data.u200.items.hat,2);eq(d.store.data.u200.passport.stamp.at,1)
    eq(d.store.data.u200.custom.important,true)
end)
test("Failed reset leaves local finds and saved France/Italy untouched",function()
    local d=environment(save(44));d.load();d.store.failWrite=true;d.reset()
    eq(d.player:GetAttribute("Found_porto"),44);eq(d.player:GetAttribute("Found_forest"),15)
    eq(#d.store.data.u200.found,59);eq(d.resetEvents,0);eq(d.api.snapshot(200).canSave,false)
end)
test("Lost reset response increments generation only once",function()
    local d=environment(save(44));d.load();d.store.loseResponse=true;d.reset()
    eq(d.api.snapshot(200).epoch,1);eq(d.store.data.u200.findsEpoch,1);eq(d.resetEvents,1)
end)
test("Reset blocks collection while persistence is in flight",function()
    local d=environment(save(43));d.load()
    d.store.hook=function()d.collect("porto_squirrel_44")end
    d.reset();eq(#d.events,0);eq(#d.store.data.u200.found,0)
end)
test("Reset waits for autosave; pending currency and items are retained",function()
    local d=environment(save(43));d.load();d.api.owe(200,5)
    d.store.hook=function()
        d.task.spawn(function()d.api.reset(d.player)end)
        d.api.owe(200,7);d.api.owe(200,1,"hat")
    end
    assert(d.api.save(d.player));d.drain();assert(d.api.save(d.player))
    eq(#d.store.data.u200.found,0);eq(d.store.data.u200.acorns,135);eq(d.store.data.u200.items.hat,3)
end)
test("Collection during autosave remains dirty and final find gets persisted",function()
    local d=environment(save(43));d.load()
    d.store.hook=function()d.collect("porto_squirrel_44")end
    assert(d.api.save(d.player));d.drain()
    eq(#d.events,1);eq(#d.store.data.u200.found,59)
end)
test("Newer cross-server reset prevents an older save merging finds",function()
    local d=environment(save(43));d.load()
    d.store.data.u200=Epoch.reset(d.store.data.u200,0,now,"other-server")
    d.collect("porto_squirrel_44");d.drain()
    eq(#d.events,0);eq(#d.store.data.u200.found,0);eq(d.api.snapshot(200).canSave,false)
end)
test("Old server schema replacing a reset generation fails closed",function()
    local data=save(43);data.findsEpoch=2
    local d=environment(data);d.load();d.store.data.u200=save(43)
    d.collect("porto_squirrel_44");d.drain();eq(#d.events,0);eq(d.api.snapshot(200).canSave,false)
end)
test("Fresh rejoin replaces in-memory finds instead of merging an old session",function()
    local d=environment(save(44));d.load()
    d.store.data.u200=Epoch.reset(d.store.data.u200,0,now,"external-reset")
    d.load();eq(d.player:GetAttribute("Found_porto"),0);eq(d.api.snapshot(200).epoch,1);eq(#d.events,0)
end)
test("No load access means no competition and no reset writes",function()
    local d=environment(save(43));d.store.failRead=true
    d.task.spawn(function()d.load()end);d.drain()
    d.collect("porto_squirrel_44");d.drain();d.reset()
    eq(#d.events,0);eq(d.store.writes,0)
end)


test("Crash after player commit replays the exact durable intent on rejoin",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local rec=d.store.data.u200.italyAttempts["0"]
    eq(rec.total,44);eq(rec.day,Core.day(now,9));eq(rec.epoch,0)
    local rejoin=environment(d.store.data.u200);rejoin.load()
    eq(#rejoin.events,1);local replay=rejoin.api.pending(rejoin.player)[1]
    eq(replay.claimId,rec.claimId);eq(replay.t,rec.t);eq(replay.day,rec.day)
    local ds=fakeStore({first=legacy});eq(adapter(ds).claim(replay),"won")
    eq(ds.data[Core.KEY].winners["200"].claimId,rec.claimId)
end)

test("Crash before player commit cannot produce a recovery candidate",function()
    local d=environment(save(43));d.load();d.store.failWrite=true
    d.collect("porto_squirrel_44");d.drain()
    local rejoin=environment(d.store.data.u200);rejoin.load()
    eq(rejoin.player:GetAttribute("Found_porto"),43);eq(#rejoin.api.pending(rejoin.player),0)
end)

test("Lost player-save reply defers dispatch but recovers the committed ID",function()
    local d=environment(save(43));d.load();d.store.loseResponse=true
    d.collect("porto_squirrel_44");d.drain();eq(#d.events,0)
    local rec=d.store.data.u200.italyAttempts["0"];assert(rec)
    local rejoin=environment(d.store.data.u200);rejoin.load()
    eq(rejoin.api.pending(rejoin.player)[1].claimId,rec.claimId)
    assert(d.api.save(d.player));eq(d.api.pending(d.player)[1].claimId,rec.claimId)
end)

test("Extended outage recovery settles only the original day",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local rec=d.api.pending(d.player)[1];local originalNow=now;now+=3*86400
    local ds=fakeStore({first=legacy});local api=adapter(ds)
    eq(api.claim(rec),"won");eq(Core.current(api.snapshot(),now,9),nil)
    eq(ds.data[Core.KEY].days[tostring(rec.day)].uid,200)
    eq(ds.data[Core.KEY].days[tostring(Core.day(now,9))],nil)
    now=originalNow
end)

test("Recovered earlier intent cannot displace a committed original-day winner",function()
    local rec=Epoch.newAttempt(200,"Test","Test",0,now-1,9,"old-intent")
    local ds=fakeStore({first=legacy});local api=adapter(ds);eq(api.claim(candidate(201)),"won")
    local originalNow=now;now+=86400
    eq(api.claim(rec),"late");eq(ds.data[Core.KEY].days[tostring(rec.day)].uid,201)
    eq(Core.current(api.snapshot(),now,9),nil);eq(api.claim(rec),"late")
    now=originalNow
end)

test("Crash after ledger commit and before ack remains exactly one win",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local ds=fakeStore({first=legacy});local api=adapter(ds);ds.loseResponse=true
    local rec=d.api.pending(d.player)[1];eq(api.claim(rec),"won");eq(ds.writes,1)
    local rejoin=environment(d.store.data.u200);rejoin.load()
    eq(adapter(ds).claim(rejoin.api.pending(rejoin.player)[1]),"won");eq(ds.writes,1)
end)

test("Lost ack is replayable while saved ack removes only settled intent",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local rec=d.api.pending(d.player)[1];d.api.ack(d.player,rec.claimId)
    eq(#d.api.pending(d.player),0)
    local unflushed=environment(d.store.data.u200);unflushed.load()
    eq(unflushed.api.pending(unflushed.player)[1].claimId,rec.claimId)
    assert(d.api.save(d.player));eq(size(d.store.data.u200.italyAttempts),0)
    local flushed=environment(d.store.data.u200);flushed.load();eq(#flushed.events,0)
    flushed.collect("porto_squirrel_44");eq(#flushed.events,0)
end)

test("Reset preserves a durable original-day intent without retagging",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local rec=d.api.pending(d.player)[1];local originalNow=now;now+=86400
    d.reset();eq(d.api.snapshot(200).epoch,1);eq(d.player:GetAttribute("Found_porto"),0)
    local retained=d.api.pending(d.player)[1]
    eq(retained.epoch,0);eq(retained.day,rec.day);eq(retained.claimId,rec.claimId)
    now=originalNow
end)

test("Reset discards an uncommitted attempt when its finds were never saved",function()
    local d=environment(save(43));d.load();d.store.failWrite=true
    d.collect("porto_squirrel_44");d.drain();d.store.failWrite=false;d.reset()
    eq(#d.store.data.u200.found,0);eq(#d.api.pending(d.player),0)
    assert(d.api.save(d.player));eq(size(d.store.data.u200.italyAttempts),0)
end)

test("A loser must reset and recollect before producing a later-day intent",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local ds=fakeStore({first=legacy});local api=adapter(ds);eq(api.claim(candidate(201)),"won")
    local original=d.api.pending(d.player)[1];eq(api.claim(original),"late")
    d.api.ack(d.player,original.claimId);assert(d.api.save(d.player))
    local originalNow=now;now+=86400
    local rejoin=environment(d.store.data.u200);rejoin.load();eq(#rejoin.events,0)
    rejoin.reset();for i=1,44 do rejoin.collect("porto_squirrel_"..i)end;rejoin.drain()
    local fresh=rejoin.api.pending(rejoin.player)[1]
    eq(fresh.epoch,1);eq(fresh.day,original.day+1);assert(fresh.claimId~=original.claimId)
    eq(api.claim(fresh),"won");now=originalNow
end)

test("Concurrent autosave never commits the final find without its intent",function()
    local d=environment(save(43));d.load()
    d.store.hook=function()d.collect("porto_squirrel_44")end
    assert(d.api.save(d.player));d.drain()
    eq(#d.store.history,2)
    for _,commit in ipairs(d.store.history) do
        local count=Core.count(table.concat(commit.value.found,","),all,italy)
        if count==44 then assert(commit.value.italyAttempts["0"])
        else eq(count,43);eq(commit.value.italyAttempts["0"],nil) end
    end
end)

test("First persisted generation ID wins over a competing session ID",function()
    local first=Epoch.newAttempt(200,"Test","Test",0,now,9,"first")
    local second=Epoch.newAttempt(200,"Test","Test",0,now+1,9,"second")
    local merged=Epoch.mergeAttempts({["0"]=first},{["0"]=second},{})
    eq(merged["0"].claimId,"first");eq(first.claimId,"first")
end)

test("Recovery emits valid generations in ascending order and ignores malformed records",function()
    local data=save(44);data.findsEpoch=2
    data.italyAttempts={
        ["2"]=Epoch.newAttempt(200,"Test","Test",2,now,9,"second"),
        ["0"]=Epoch.newAttempt(200,"Test","Test",0,now-86400,9,"first"),
        ["1"]=Epoch.newAttempt(201,"Other","Other",1,now,9,"wrong-user"),
        ["3"]=Epoch.newAttempt(200,"Test","Test",3,now,9,"future-generation"),
        malformed={total=44},
    }
    local d=environment(data);d.load();local attempts=d.api.pending(d.player)
    eq(#attempts,2);eq(attempts[1].epoch,0);eq(attempts[2].epoch,2)
end)


local runtimeFactory=require("./runtime_fixture")
local clientFactory=require("./client_fixture")
local function keeper(d,ds)
    local k={Players=d.Players,task=d.task,os=d.os,warn=d.warn,persistence=adapter(ds),messages={},broadcasts={},renders={},acks={},titleWrites={}}
    function k.Players:GetPlayers()return {d.player}end
    k.F={GetAttribute=function()return nil end,FindFirstChild=function(_,name)
        if (name=="Figure" and k.figure) or (name=="Key" and k.key) then return {} end
    end}
    k.Enum={CreatorType={User="User"}}
    k.game={CreatorId=9611145467,CreatorType="User"}
    k.BadgeService={UserHasBadgeAsync=function()error("unexpected badge access")end}
    k.MessagingService={PublishAsync=function()k.publishes=(k.publishes or 0)+1 end}
    k.ev={FireClient=function(_,player,kind,rec)table.insert(k.messages,{kind=kind,rec=Core.copy(rec)})end,
        FireAllClients=function(_,kind,rec)table.insert(k.broadcasts,{kind=kind,rec=Core.copy(rec)})end}
    k.getAttempts={Invoke=function(_,player)return d.api.pending(player)end}
    k.acknowledge={Fire=function(_,player,id)table.insert(k.acks,id);if not k.dropAck then d.api.ack(player,id)end end}
    k.collected={Event={Connect=function(_,fn)k.onCollected=fn end}}
    k.renderer=Core.renderer(function(rec)
        table.insert(k.renders,rec and rec.uid or 0);k.figure=rec~=nil;k.key=rec==nil;return true
    end,d.task.spawn)
    k.api=runtimeFactory(k)
    return k
end

test("Actual runtime retries outage, keeps generation order, and releases its lock",function()
    local data=save(44);data.findsEpoch=1
    data.italyAttempts={
        ["0"]=Epoch.newAttempt(200,"Test","Test",0,now-86400,9,"old"),
        ["1"]=Epoch.newAttempt(200,"Test","Test",1,now,9,"new"),
    }
    local d=environment(data);d.load();local ds=fakeStore({first=legacy});local k=keeper(d,ds)
    ds.failWrite=true;k.api.process(d.player);k.api.process(d.player);d.drain()
    eq(#k.acks,0);eq(ds.writes,0);eq(#k.messages,1);eq(k.messages[1].kind,"unavailable")
    ds.failWrite=false;k.api.process(d.player);d.drain()
    eq(k.acks[1],"old");eq(k.acks[2],"new");eq(ds.data[Core.KEY].winners["200"].claimId,"old")
    eq(ds.data[Core.KEY].days[tostring(Core.day(now,9))],nil)
    eq(#k.broadcasts,0);eq(d.player:GetAttribute("PortoKeeperTitle"),"Guardian of the Harbour")
end)

test("Historical queue recovery leaves today's displayed winner unchanged",function()
    local data=save(44);data.italyAttempts={["0"]=Epoch.newAttempt(200,"Test","Test",0,now-86400,9,"historical")}
    local d=environment(data);d.load();local ds=fakeStore({first=legacy});local k=keeper(d,ds)
    eq(k.persistence.claim(candidate(201)),"won");k.api.render();eq(k.renders[#k.renders],201)
    k.api.process(d.player);d.drain()
    eq(k.renders[#k.renders],201);eq(#k.renders,1);eq(#k.broadcasts,0)
    eq(k.messages[1].kind,"recovered");eq(k.messages[1].rec.day,Core.day(now,9)-1)
    eq(ds.data[Core.KEY].days[tostring(Core.day(now,9))].uid,201)
end)

test("Historical queue recovery leaves today available to its eligible winner",function()
    local data=save(44);data.italyAttempts={["0"]=Epoch.newAttempt(200,"Test","Test",0,now-86400,9,"historical")}
    local d=environment(data);d.load();local ds=fakeStore({first=legacy});local k=keeper(d,ds)
    k.api.process(d.player);d.drain();eq(k.renders[#k.renders],0)
    eq(k.persistence.claim(candidate(201)),"won");k.api.render();eq(k.renders[#k.renders],201)
    eq(size(ds.data[Core.KEY].days),2);eq(#k.broadcasts,0)
end)

test("Runtime legacy44 makes no claim and stale reset generation cannot create an intent",function()
    local d=environment(save(44));d.load();local ds=fakeStore({first=legacy});local k=keeper(d,ds)
    k.api.process(d.player);eq(ds.writes,0);eq(ds.reads,0)
    d.store.data.u200=Epoch.reset(d.store.data.u200,0,now,"external")
    assert(not d.api.save(d.player));k.api.process(d.player);eq(ds.writes,0)
end)

test("Lost ledger response and lost ack repeat a coherent dated loss receipt",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local ds=fakeStore({first=legacy});local k=keeper(d,ds);eq(k.persistence.claim(candidate(201)),"won")
    ds.loseResponse=true;k.dropAck=true;k.api.process(d.player);d.drain()
    eq(k.messages[1].kind,"late");eq(k.messages[1].rec.day,Core.day(now,9));eq(ds.writes,2)
    k.api.process(d.player);d.drain();eq(k.messages[2].kind,"late");eq(ds.writes,2)
    eq(k.messages[2].rec.claimId,k.messages[1].rec.claimId)
end)

test("Queue recovers unexpected delivery exception without consuming the outbox",function()
    local d=environment(save(43));d.load();d.collect("porto_squirrel_44");d.drain()
    local ds=fakeStore({first=legacy});local k=keeper(d,ds)
    k.api.markFresh(d.player,d.api.pending(d.player)[1]) -- this test exercises a fresh-session announcement
    local send=k.ev.FireAllClients;k.ev.FireAllClients=function()error("delivery failed")end
    k.api.process(d.player);d.drain();eq(#k.acks,0);eq(ds.writes,1)
    k.ev.FireAllClients=send;k.api.process(d.player);d.drain();eq(#k.acks,1);eq(ds.writes,1);eq(#k.broadcasts,1)
end)

test("Future-dated durable intent waits without being acknowledged or lost",function()
    local data=save(44);data.italyAttempts={["0"]=Epoch.newAttempt(200,"Test","Test",0,now+10,9,"future")}
    local d=environment(data);d.load();local ds=fakeStore({first=legacy});local k=keeper(d,ds)
    k.api.process(d.player);d.drain();eq(#k.acks,0);eq(ds.writes,0)
    now+=10;k.api.process(d.player);d.drain();eq(#k.acks,1);eq(ds.writes,1);now-=10
end)

test("Client deduplicates dated recovered/loss receipts without a current-statue banner",function()
    local output,banners={},{};local handler
    clientFactory({ev={OnClientEvent={Connect=function(_,fn)handler=fn end}},player={UserId=200},workspace={},
        os={date=function(_,at)return "day "..math.floor(at/86400)end},
        chat=function(s)table.insert(output,s)end,banner=function(...)table.insert(banners,{...})end})
    handler("recovered",{claimId="old-win",day=99})
    handler("recovered",{claimId="old-win",day=99})
    eq(#output,1);eq(#banners,0);assert(output[1]:find("day 99",1,true))
    handler("late",{claimId="old-loss",day=99,name="Other"})
    handler("late",{claimId="old-loss",day=99,name="Other"})
    eq(#output,2);assert(output[2]:find("for day 99",1,true));eq(#banners,0)
end)

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

print("ALL "..passed.." TESTS PASSED")
