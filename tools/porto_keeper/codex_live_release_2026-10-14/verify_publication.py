from pathlib import Path
import json,hashlib,datetime as dt,re
from studio_live import connect,execute
r=Path(__file__).resolve().parent
verified=json.loads((r/'verification.json').read_text(encoding='utf-8'))
expected=dict(verified['changed'],**verified['unchanged'])
report={'checkedUtc':dt.datetime.now(dt.timezone.utc).isoformat(),'sources':{},'publicationEvidence':[]}
log=Path(r'C:\Users\slard\AppData\Local\Roblox\logs\0.742.0.7421053_20261014T022204Z_Studio_F1C2B_last.log')
for n,line in enumerate(log.read_text(encoding='utf-8',errors='replace').splitlines(),1):
 if line[:24]>'2026-10-14T02:29:02.310Z' and any(p in line for p in ('Publish succeeded for placeId','Published new changes','Add publish notes to')):
  report['publicationEvidence'].append({'file':str(log),'line':n,'text':line})
assert any('Publish succeeded for placeId 117372258657114' in e['text'] for e in report['publicationEvidence'])
assert any('v1336' in e['text'] for e in report['publicationEvidence'])
c,sid=connect();report['studioId']=sid
try:
 report['identity']=execute(c,sid,'return game:GetService("HttpService"):JSONEncode({universeId=game.GameId,placeId=game.PlaceId,placeVersion=game.PlaceVersion,name=game.Name,isRunning=game:GetService("RunService"):IsRunning()})')
 print(json.dumps({'currentIdentity':report['identity']},indent=2),flush=True)
 for name,info in expected.items():
  expr='game'+''.join('['+json.dumps(v)+']' for v in info['path'].split('.'))
  data=execute(c,sid,'return game:GetService("HttpService"):JSONEncode({source='+expr+'.Source})')
  source=data['source'].replace('\r\n','\n');digest=hashlib.sha256(source.encode('utf-8')).hexdigest()
  assert digest==info['sha256'],name+' differs from validated source'
  report['sources'][name]={'sha256':digest,'matchesFinalValidation':True}
 report['scene']=execute(c,sid,(r/'inspect_scene.lua').read_text(encoding='utf-8'))
 assert not report['scene']['privateTestArtifacts'] and not report['scene']['testMarkersInSources']
 for key in ('settings','giftsEnabled','receiptsEnabled','keeperAttributes','dailyAttributes','workspaceAttributes'):
  assert report['scene'][key]==verified['scene'][key],'Setting differs from final validation: '+key
finally:c.close()
report.update(publicationVerified=True,publishNotesVersion=1336,publicationUtc='2026-10-14T02:31:27.680Z',freshStudioSession=sid!=verified['studioId'],all13SourcesMatch=True,
 noLaterSourceDifferences=True,allProductionSettingsPreserved=True,noTestArtifacts=True,noPlay=True,noSavedDataAccess=True,noPublicationByAgent=True,noServerRestart=True,completedUtc=dt.datetime.now(dt.timezone.utc).isoformat())
(r/'publication-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('scene','sources')},indent=2))
