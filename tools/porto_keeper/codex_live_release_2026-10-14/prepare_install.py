from pathlib import Path
import json,difflib,hashlib,shutil
r=Path(__file__).resolve().parent
prior=r.parent/'private-test-setup'/'celebration-fix'
out=r/'after';out.mkdir(exist_ok=True)
pre=json.loads((r/'preflight.json').read_text(encoding='utf-8'))
def read(p):return p.read_text(encoding='utf-8').replace('\r\n','\n')
def sha(s):return hashlib.sha256(s.encode('utf-8')).hexdigest()
def literal(s):
 assert ']====]' not in s
 return '[====['+s+']====]'
changed=('SquirrelSetup','PortoKeeperServer','PortoKeeperClient')
for n in changed:
 assert read(r/'before'/(n+'.lua'))==read(prior/'baseline'/(n+'.lua')),n+' current production differs; integrate rather than replace'
 assert pre['sources'][n]['enabled'] is True
for n in ('DailyKeeperCore','DailyKeeperStore','FindsEpoch'):
 assert read(r/'before'/(n+'.lua'))==read(prior/'readback'/(n+'.lua')),n+' persistence protocol differs'
assert pre['sources']['KeeperCelebration'].get('missing')
assert not pre['scene']['privateTestArtifacts'] and not pre['scene']['testMarkersInSources']
rows=[];diff=[];manifest={}
for n in changed:
 before=read(r/'before'/(n+'.lua'));after=read(prior/'readback'/(n+'.lua'))
 (out/(n+'.lua')).write_text(after,encoding='utf-8')
 path=pre['sources'][n]['path']
 rows.append('{name='+json.dumps(n)+',path='+json.dumps(path)+',before='+literal(before)+',after='+literal(after)+'}')
 diff+=list(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile=path+' production before',tofile=path+' production after'))
 manifest[n]={'path':path,'before':sha(before),'after':sha(after)}
module=read(prior/'readback'/'KeeperCelebration.lua');(out/'KeeperCelebration.lua').write_text(module,encoding='utf-8')
manifest['KeeperCelebration']={'path':'Workspace.PortoKeeper.KeeperCelebration','after':sha(module),'newModule':True}
for n in ('DailyKeeperCore','DailyKeeperStore','FindsEpoch','SquirrelRegistry'):
 shutil.copyfile(r/'before'/(n+'.lua'),out/(n+'.lua'))
for p in out.glob('*.lua'):
 text=read(p)
 for forbidden in ('PrivateItalyRetest','PrivateTest','8119732427','10770742370','123976106520186','10770759635','130796034221607','italy-celebration-20261014-01','ready87'):
  assert forbidden not in text,(p.name,forbidden)
# Exact save-persistence proof: these are the only additions to SquirrelSetup.
setup=read(out/'SquirrelSetup.lua').replace('''-- Transient proof of a find made in this session; never stored or used for award eligibility.
local freshCelebration = ReplicatedStorage:FindFirstChild("ItalyCelebrationFresh") or Instance.new("BindableEvent")
assert(freshCelebration:IsA("BindableEvent"), "ItalyCelebrationFresh must be server-only")
freshCelebration.Name = "ItalyCelebrationFresh"; freshCelebration.Parent = ReplicatedStorage
''','').replace('            freshCelebration:Fire(player, italyAdditions[uid][tostring(epoch)])\n','')
assert setup==read(r/'before'/'SquirrelSetup.lua')
body=read(prior/'install_body.lua')
old='assert(game.GameId==10770742370 and game.PlaceId==123976106520186,"Private TEST only")'
assert body.count(old)==1
body=body.replace(old,'assert(game.GameId==10766369535 and game.PlaceId==117372258657114,"Exact LIVE universe/place required")')
body=body.replace('assert(workspace:GetAttribute("PrivateTestCopy")==true,"Missing private test marker")','assert(workspace:GetAttribute("PrivateTestCopy")~=true,"Private test copy prohibited")')
body=body.replace('PrivateTestItalyCelebrationBackup_20261014','PortoCelebrationBackup_20261014')
code='local rows={'+','.join(rows)+'}\nlocal moduleSource='+literal(module)+'\n'+body
(r/'install-production.lua').write_text(code,encoding='utf-8')
(r/'production.patch').write_text(''.join(diff),encoding='utf-8')
(r/'source-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Prepared exact production-only celebration patch. Existing save persistence is unchanged; all private-test markers excluded.')
