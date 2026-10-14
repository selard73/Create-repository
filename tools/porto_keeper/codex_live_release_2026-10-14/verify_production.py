from pathlib import Path
import json,hashlib,datetime as dt,shutil,subprocess,sys
from studio_live import connect,execute
r=Path(__file__).resolve().parent
out=r/'readback';out.mkdir(exist_ok=True)
pre=json.loads((r/'preflight.json').read_text(encoding='utf-8'))
manifest=json.loads((r/'source-manifest.json').read_text(encoding='utf-8'))
def read(p):return p.read_text(encoding='utf-8').replace('\r\n','\n')
def sha(s):return hashlib.sha256(s.replace('\r\n','\n').encode('utf-8')).hexdigest()
report={'startedUtc':dt.datetime.now(dt.timezone.utc).isoformat(),'changed':{},'unchanged':{},'backups':[]}
def save(): (r/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
c,sid=connect();report['studioId']=sid
try:
 assert sid==pre['studioId'],'Different live session; inspect first'
 report['identity']=execute(c,sid,'return game:GetService("HttpService"):JSONEncode({universeId=game.GameId,placeId=game.PlaceId,placeVersion=game.PlaceVersion,name=game.Name,isStudio=game:GetService("RunService"):IsStudio(),isRunning=game:GetService("RunService"):IsRunning()})')
 assert report['identity']['placeVersion']==pre['identity']['placeVersion'],'Publication/version changed during installation'
 for name,info in pre['sources'].items():
  expr='game'+''.join('['+json.dumps(v)+']' for v in info['path'].split('.'))
  result=execute(c,sid,'local x='+expr+';return game:GetService("HttpService"):JSONEncode({source=x.Source,class=x.ClassName,enabled=x:IsA("BaseScript") and x.Enabled or nil})')
  source=result['source'].replace('\r\n','\n');digest=sha(source)
  if name in manifest:
   assert digest==manifest[name]['after'],name+' installed source mismatch'
   report['changed'][name]={'path':info['path'],'sha256':digest,'exactReadback':True}
  else:
   assert digest==info['sha256'],name+' unrelated source changed'
   report['unchanged'][name]={'path':info['path'],'sha256':digest}
  if name!='KeeperCelebration':assert result.get('enabled')==info.get('enabled'),name+' enabled state changed'
  (out/(name+'.lua')).write_text(source,encoding='utf-8')
 for name in ('SquirrelSetup','PortoKeeperServer','PortoKeeperClient'):
  backup=execute(c,sid,'local b=game.ServerStorage.PortoCelebrationBackup_20261014['+json.dumps(name)+'];return game:GetService("HttpService"):JSONEncode({path=b:GetFullName(),source=b.Source,disabled=not b.Enabled})')
  assert backup['disabled'] and sha(backup['source'])==pre['sources'][name]['sha256'],'Backup mismatch'
  report['backups'].append({'path':backup['path'],'disabled':True,'exactOriginal':True,'sha256':sha(backup['source'])})
 report['scene']=execute(c,sid,read(r/'inspect_scene.lua'))
 assert not report['scene']['privateTestArtifacts'] and not report['scene']['testMarkersInSources'],'Private test artifacts found'
 for key in ('settings','giftsEnabled','receiptsEnabled','keeperAttributes','dailyAttributes','workspaceAttributes'):
  assert report['scene'][key]==pre['scene'][key],'Production settings changed: '+key
 report['exactReadbacksVerifiedUtc']=dt.datetime.now(dt.timezone.utc).isoformat();save()
finally:c.close()
# The only additions to the complete player persistence script are the transient fresh-find signal.
setup=read(out/'SquirrelSetup.lua').replace('''-- Transient proof of a find made in this session; never stored or used for award eligibility.
local freshCelebration = ReplicatedStorage:FindFirstChild("ItalyCelebrationFresh") or Instance.new("BindableEvent")
assert(freshCelebration:IsA("BindableEvent"), "ItalyCelebrationFresh must be server-only")
freshCelebration.Name = "ItalyCelebrationFresh"; freshCelebration.Parent = ReplicatedStorage
''','').replace('            freshCelebration:Fire(player, italyAdditions[uid][tostring(epoch)])\n','')
assert setup==read(r/'before'/'SquirrelSetup.lua'),'Save behavior changed beyond transient signal'
report['saveProtocolCompatibility']={'baselinePlaceVersion':1334,'DailyKeeperCoreUnchanged':True,'DailyKeeperStoreUnchanged':True,'FindsEpochUnchanged':True,'fullSquirrelSetupUnchangedAfterRemovingTransientSignal':True,'requiresRestartForThisUpdateDataCompatibility':False,'activeServerVersionsNotInventoried':True,'oldServersRetainOldCelebrationBehavior':True}
prior=r.parent/'private-test-setup'/'celebration-fix'
for name in ('make_fixtures.py','new_tests.luau'):shutil.copyfile(prior/name,out/name)
log=[]
def run(args):
 result=subprocess.run(args,capture_output=True,text=True,encoding='utf-8')
 log.append('COMMAND: '+' '.join(args)+'\n'+result.stdout+result.stderr)
 (r/'test-results.txt').write_text('\n'.join(log),encoding='utf-8');result.check_returncode();return result
run([sys.executable,str(out/'make_fixtures.py')])
luau=Path(r'C:\Users\slard\AppData\Local\Temp\codex-luau-0.742')
tests=run([str(luau/'luau.exe'),str(out/'test_celebration.luau')])
assert 'ALL 74 TESTS PASSED' in tests.stdout
names=('SquirrelSetup','PortoKeeperServer','PortoKeeperClient','KeeperCelebration','DailyKeeperCore','DailyKeeperStore','FindsEpoch','SquirrelRegistry')
run([str(luau/'luau-compile.exe'),'--null']+[str(out/(n+'.lua')) for n in names])
run([str(luau/'luau-analyze.exe')]+[str(out/(n+'.lua')) for n in ('KeeperCelebration','DailyKeeperCore','DailyKeeperStore','FindsEpoch')])
report.update(functionalTestsPassed=74,existingAwardSaveResetRecoveryCases=53,celebrationCases=21,compilePassed=8,pureModuleAnalysisPassed=4,
 testsAgainstExactProductionReadbacks=True,allProductionSettingsPreserved=True,noTestArtifacts=True,productionTravelUnchanged=True,productionCommerceUnchanged=True,
 publishedByAgent=False,publicationVerified=False,noPlay=True,noAPISettingsChanges=True,noSavedDataAccess=True,noServerRestarts=True,readyForUserPublish=True,verifiedUtc=dt.datetime.now(dt.timezone.utc).isoformat())
save()
print(json.dumps(report,indent=2))
