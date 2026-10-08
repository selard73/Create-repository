assert(not game:GetService("RunService"):IsRunning(),"Edit only; tests never access player DataStores")
local F=workspace.Passport
local Cat=assert(loadstring(F.Catalogue.Source))()
local J=assert(loadstring(F.Journal.Source:gsub("require%(script.Parent.Catalogue%)","(...)")))(Cat)
local Rules=assert(loadstring(F.Rules.Source))()
local H=game:GetService("HttpService")
local registry={maps={{id="forest",name="Great Acorn Forest"}},squirrels={{id="detective",map="forest",name="Mr. Holmes Squirrel"}}}
local all=function(e)return not e.bonus end
local forest=function(e)return e.area=="forest" and not e.bonus end
local function records(data)local out={};for id,d in pairs(data)do out[id]={at=1,data=d}end;return out end
local old={SaveLoaded=true,SquirrelsFound=44,FoundIds="detective",Found_forest=16,Found_village=14,Found_domaine=14,
 Item_q_round_forest=20700,Item_croc_rescues=2,Item_race_best=6200,Item_climb_best=9900,Item_baskets=17,
 Item_daily_gold=20699,Item_gassy=1700000000,Item_bubbles=2,Item_portrait=1,Item_hat_beret_1=1,
 Item_book_crumbs=1,Item_ziphandle=1,Item_glider=1,Acorns=500,Item_passport_outings=2,Item_passport_outing_last=20700}
local historic=J.history(old,registry,{beret_1="Beret - Pine green"})
assert(historic.find.foundCount==44 and historic.find.name=="Mr. Holmes Squirrel")
assert(historic.riddle and historic.rescue and historic.race.cs==6200 and historic.hoop.baskets==17)
assert(historic.climb and historic.gold and historic.cheese and historic.bubbles and historic.portrait and historic.hat)
assert(not historic.book and not historic.zipline and not historic.glider and not historic.coffee,"ownership must not invent use")
assert(next(J.history({},registry,{}))==nil,"new accounts have no borrowed history")
local journal=records(historic)
local stale={ids="find,riddle,rescue,race,hoop",done="",seen="find,riddle,rescue,race,hoop",cycle=1}
local fixed=J.reconcileBatch(stale,all,journal)
assert(#J.ids(fixed.ids)==5 and fixed.done=="")
for _,id in ipairs(J.ids(fixed.ids))do assert(not journal[id] and id~="keeper")end
assert(J.reconcileBatch(fixed,all,journal).ids==fixed.ids,"repair is idempotent")
local partial=records({riddle={historical=true},find={name="Modern",visited=1777777777}})
partial.find.at=1777777777
local repaired=J.reconcileBatch(stale,all,partial)
assert(table.find(J.ids(repaired.done),"find") and not table.find(J.ids(repaired.ids),"riddle"))
assert(table.find(J.ids(repaired.ids),"rescue") and #J.ids(repaired.ids)==5)
local modern={find={at=1777777777,data={name="Modern"}}}
local ordinary=J.reconcileBatch(stale,all,modern)
assert(ordinary.ids==stale.ids and ordinary.done=="find","ordinary completion does not refill endlessly")
local empty=J.reconcileBatch(stale,forest,journal)
assert(empty.ids=="","fewer eligible unfinished activities cannot force repeats")
assert(#J.ids(J.reconcileBatch(empty,all,journal).ids)==5,"unlocking areas fills empty pages")
local locked=J.reconcileBatch({ids="baguette,book",done="",seen="baguette,book"},forest,{})
assert(not table.find(J.ids(locked.ids),"baguette") and not table.find(J.ids(locked.ids),"book"))
local complete={};for _,e in ipairs(Cat)do if not e.bonus then complete[e.id]={at=1,data={historical=true}}end end
assert(J.reconcileBatch(stale,all,complete).ids=="","all complete remains empty")
assert(J.describe("race",journal.race):find("saved personal best",1,true))
assert(not J.describe("race",journal.race):find("first recorded",1,true))
assert(not J.describe("riddle",journal.riddle):find("tomorrow",1,true))
assert(J.describe("hoop",journal.hoop):find("17 baskets",1,true))
assert(not J.describe("hoop",journal.hoop):find("in a row",1,true))
assert(J.describe("rescue",journal.rescue,"SelBell"):find("SelBell saves the day!",1,true))
assert(J.clean("find",journal.find).data.foundCount==44)
assert(J.merge(modern,journal).find.data.name=="Modern","richer recent record wins save merge")

-- Execute the real server source against two isolated in-memory accounts.
-- Signals, save writes and awards are fakes; no Players or DataStore mutations.
local function signal()return {Connect=function()return {Disconnect=function()end}end}end
local accounts={};local saves,awards={},{}
local players={PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers()return accounts end
local function account(attrs)
 local p={attrs=table.clone(attrs),Parent=players,CharacterAdded=signal(),AttributeChanged=signal()}
 function p:GetAttribute(k)return self.attrs[k]end
 function p:SetAttribute(k,v)self.attrs[k]=v end
 function p:GetAttributes()return table.clone(self.attrs)end
 function p:GetAttributeChangedSignal()return signal()end
 accounts[#accounts+1]=p;return p
end
old.PassportJournal=H:JSONEncode({_batch={at=100,data=stale}})
local veteran=account(old);local newcomer=account({SaveLoaded=true})
local function event(fn)return {Event=signal(),Fire=fn or function()end}end
local rs={
 AwardItems=event(function(_,p,id,n)awards[#awards+1]={p=p,id=id,n=n}end),
 PassportActivity=event(),
 PassportSave=event(function(_,p,id,record)saves[#saves+1]={p=p,id=id,record=record}end)
}
function rs:WaitForChild(k)return assert(self[k],k)end
function rs:FindFirstChild(k)return self[k]end
local function attrs(a)return {GetAttribute=function(_,k)return a[k]end}end
local world={Boundary=attrs({Need=10}),Daily=attrs({DayOffsetHours=9,GoldArea="Forest"}),Baguette=attrs({MinPlayers=2}),
 SquirrelScripts={WaitForChild=function()return registry end},GetServerTimeNow=function()return 1800000000 end}
function world:FindFirstChild(k)return self[k]end
function world:WaitForChild(k)return assert(self[k])end
local services={Players=players,ReplicatedStorage=rs,HttpService=H}
local fakeGame={GetService=function(_,k)return assert(services[k],"Unexpected service "..k)end}
local folder={Catalogue=Cat,Journal=J,Rules=Rules,PassportAction={}}
function folder:WaitForChild(k)return assert(self[k])end
local execute=assert(loadstring("local game,workspace,script,require=...\n"..F.PassportServer.Source))
execute(fakeGame,world,{Parent=folder},function(v)return v end)
task.wait(.2)
assert(veteran.attrs.PassportReady and newcomer.attrs.PassportReady)
local v=H:JSONDecode(veteran.attrs.PassportJournal)
local n=H:JSONDecode(newcomer.attrs.PassportJournal)
assert(v.find and v.riddle and v.race and v.hoop and #J.ids(v._batch.data.ids)==5)
for _,id in ipairs(J.ids(v._batch.data.ids))do assert(not v[id])end
assert(not n.find and not n.riddle and n._batch.data.ids==stale.ids,"per-account challenge selection")
assert(#awards==0 and veteran.attrs.Acorns==500 and veteran.attrs.Item_passport_outings==2,"no reward replay")
local savedCount=#saves
execute(fakeGame,world,{Parent=folder},function(value)return value end)
task.wait(.2)
assert(#saves==savedCount,"rejoining does not rewrite completed history")
warn("QQ RETURNING TEST PASS: historical backfill; 44-found veteran; answered question; fresh account isolation; stale-page repair; no repeats; idempotent reconnect; no reward replay; truthful descriptions")
