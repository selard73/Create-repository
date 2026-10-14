from pathlib import Path
import sys,json,hashlib,datetime as dt
r=Path(__file__).resolve().parent
from studio_live import connect,execute
baseline=r/'before';baseline.mkdir(exist_ok=True)
def norm(s):return s.replace('\r\n','\n')
def sha(s):return hashlib.sha256(norm(s).encode('utf-8')).hexdigest()
prior=r.parent/'private-test-setup'/'celebration-fix'
paths={k:v['path'] for k,v in json.loads((prior/'preflight.json').read_text(encoding='utf-8'))['sources'].items()}
paths.update(KeeperCelebration='Workspace.PortoKeeper.KeeperCelebration',SquirrelRegistry='Workspace.SquirrelScripts.SquirrelRegistry',GiftsClient='Workspace.Gifts.GiftsClient',ReceiptRouter='Workspace.Receipts.ReceiptRouter')
report={'startedUtc':dt.datetime.now(dt.timezone.utc).isoformat(),'sources':{},'differences':[]}
c,sid=connect();report['studioId']=sid
try:
 report['identity']=execute(c,sid,'return game:GetService("HttpService"):JSONEncode({universeId=game.GameId,placeId=game.PlaceId,placeVersion=game.PlaceVersion,name=game.Name,creatorId=game.CreatorId})')
 print(json.dumps(report['identity']),flush=True)
 for name,path in paths.items():
  expr='game'+''.join('['+json.dumps(v)+']' for v in path.split('.'))
  item=execute(c,sid,'local ok,x=pcall(function()return '+expr+' end);if not ok or not x then return game:GetService("HttpService"):JSONEncode({missing=true})end;return game:GetService("HttpService"):JSONEncode({source=x.Source,class=x.ClassName,enabled=x:IsA("BaseScript") and x.Enabled or nil})')
  row={'path':path}
  if item.get('missing'):row['missing']=True
  else:
   source=norm(item['source']);(baseline/(name+'.lua')).write_text(source,encoding='utf-8')
   row.update(sha256=sha(source),className=item['class'],enabled=item.get('enabled'))
   row['knownVersions']=[]
   for base in (prior/'baseline',prior/'readback',r.parent/'italy-daily-work'/'recovery-verification',r.parent/'italy-daily-work',r.parent/'private-test-setup'/'italy-entry'):
    for suffix in ('.lua','.baseline.lua'):
     f=base/(name+suffix)
     if f.exists() and sha(f.read_text(encoding='utf-8'))==row['sha256']:row['knownVersions'].append(str(f))
  report['sources'][name]=row
 settings=json.loads((r.parent/'private-test-setup'/'isolation-spec.json').read_text(encoding='utf-8'))['settings']
 inspections=[]
 for row in settings:
  expr='game'+''.join('['+json.dumps(v)+']' for v in row['path'].split('.'))
  inspections.append('{path='+json.dumps(row['path'])+',key='+json.dumps(row['key'])+',value='+expr+':GetAttribute('+json.dumps(row['key'])+')}')
 scene='''local forbidden={"PrivateItalyRetest","PrivateTestItalyCart","PrivateTestEntry","preparePrivateItalyRetest","10770742370","123976106520186","8119732427","10770759635","130796034221607","italy-celebration-20261014-01"}
local artifacts={};local scripts={};local backups={}
for _,x in ipairs(game:GetDescendants())do
 if x.Name:find("PrivateTest",1,true) or x.Name:find("PrivateItalyRetest",1,true)then table.insert(artifacts,x:GetFullName())end
 if x:IsA("LuaSourceContainer")then for _,marker in ipairs(forbidden)do if x.Source:find(marker,1,true)then table.insert(scripts,{path=x:GetFullName(),marker=marker})end end end
end
for _,x in ipairs(game.ServerStorage:GetChildren())do if x.Name:find("Porto",1,true)then table.insert(backups,{name=x.Name,children=#x:GetChildren()})end end
return game:GetService("HttpService"):JSONEncode({settings={'''+','.join(inspections)+'''},giftsEnabled=workspace.Gifts.GiftsClient.Enabled,receiptsEnabled=workspace.Receipts.ReceiptRouter.Enabled,privateTestArtifacts=artifacts,testMarkersInSources=scripts,backups=backups,keeperAttributes=workspace.PortoKeeper:GetAttributes(),dailyAttributes=workspace.Daily:GetAttributes(),workspaceAttributes=workspace:GetAttributes()})'''
 (r/'inspect_scene.lua').write_text(scene,encoding='utf-8')
 report['scene']=execute(c,sid,scene)
 tools=c.request('tools/list',{}).get('tools',[])
 report['publishingTools']=[x['name'] for x in tools if 'publish' in x['name'] or 'save_place' in x['name']]
finally:c.close()
report['checkedUtc']=dt.datetime.now(dt.timezone.utc).isoformat()
(r/'preflight.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({**report,'sources':{k:{a:b for a,b in v.items() if a!='knownVersions'} for k,v in report['sources'].items()}},indent=2))
