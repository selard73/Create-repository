from pathlib import Path
import sys,json,time
r=Path(__file__).resolve().parent
sys.path.insert(0,str(r.parent/'italy-statue-audit'))
from read_only_audit import StudioClient
GUARD='''assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Live Edit mode required")
assert(game.GameId==10766369535 and game.PlaceId==117372258657114,"Exact LIVE universe/place required")
assert(workspace:GetAttribute("PrivateTestCopy")~=true,"Private TEST copy prohibited")
'''
def parsed(raw):
 x=json.loads(raw);return json.loads(x) if isinstance(x,str) else x
def connect():
 c=StudioClient()
 for attempt in range(3):
  data=parsed(c.tool('list_roblox_studios',{}))
  found=[x for x in data.get('studios',[]) if '(placeId: 117372258657114)' in (x.get('name') or '')]
  if len(found)==1:
   sid=found[0]['id']
   assert 'Current Studio Mode: Edit' in c.tool('get_studio_state',{'studio_id':sid})
   execute(c,sid,'return game:GetService("HttpService"):JSONEncode({verified=true})')
   return c,sid
  if attempt<2:time.sleep(1)
 c.close();raise RuntimeError('Exact live Studio not available: '+json.dumps(data))
def execute(c,sid,code):return parsed(c.tool('execute_luau',{'studio_id':sid,'datamodel_type':'Edit','code':GUARD+code}))
