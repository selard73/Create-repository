from pathlib import Path
import json,datetime as dt
from studio_live import connect,execute
r=Path(__file__).resolve().parent
pre=json.loads((r/'preflight.json').read_text(encoding='utf-8'))
assert (dt.datetime.now(dt.timezone.utc)-dt.datetime.fromisoformat(pre['checkedUtc'])).total_seconds()<900,'Preflight stale'
c,sid=connect()
try:
 assert sid==pre['studioId'],'Live session changed; inspect before proceeding'
 result=execute(c,sid,(r/'install-production.lua').read_text(encoding='utf-8'))
 assert result.get('installed') or result.get('alreadyInstalled')
finally:c.close()
result.update(studioId=sid,installedUtc=dt.datetime.now(dt.timezone.utc).isoformat(),publishedByAgent=False,noPlay=True,noSavedDataAccess=True)
(r/'install-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
