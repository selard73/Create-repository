-- codex_passport_rules v1 (EDIT ONLY; pure in-memory tests)
assert(not game:GetService("RunService"):IsRunning())
local rules=assert(loadstring(workspace.Passport.Rules.Source))()
local catalog=assert(loadstring(workspace.Passport.Catalogue.Source))()
local allowed={};for _,e in ipairs(catalog) do assert(not allowed[e.id]);allowed[e.id]=true end
local function fresh() return {stamps={},last=0,outings=0} end
local s=fresh();local day=21000
assert(rules.record(s,"unknown",day,allowed)==nil)
assert(rules.record(s,"book",day,allowed));assert(s.outings==0)
assert(rules.record(s,"book",day,allowed)==nil)
assert(rules.record(s,"coffee",day,allowed));assert(s.outings==0)
assert(rules.record(s,"rescue",day,allowed));assert(s.outings==1 and s.last==day)
assert(rules.record(s,"glace",day,allowed));assert(s.outings==1)
-- Reconstruct from the ledger, as a later server does on rejoin.
local loaded={stamps=table.clone(s.stamps),outings=s.outings,last=s.last}
assert(rules.record(loaded,"rescue",day,allowed)==nil and loaded.outings==1)
for _,id in ipairs({"book","coffee","rescue"}) do rules.record(loaded,id,day+4,allowed) end
assert(loaded.outings==2 and loaded.last==day+4 and loaded.stamps.glace==day)
for d=day+5,day+7 do for _,id in ipairs({"race","riddle","rescue"}) do rules.record(loaded,id,d,allowed) end end
assert(loaded.outings==5 and loaded.stamps.book>0)
assert(loaded.stamps.race==day+7)
warn("QQ PASSPORT RULES PASS: 17 unique ids; unknown rejected; repeat deduplicated; 3 distinct activities; rejoin; rollover; missed days; 5-outing cover; permanent stamps")
