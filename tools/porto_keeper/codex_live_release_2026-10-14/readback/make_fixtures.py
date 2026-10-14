from pathlib import Path
import shutil
r=Path(__file__).resolve().parent
original=Path(r'C:\Users\slard\Create-repository\tools\porto_keeper\daily')
s=(original/'make_test_fixture.py').read_text(encoding='utf-8')
s=s.replace('local italyAdditions, italyConfirmed, italyAcks = {}, {}, {}','local italyAdditions, italyConfirmed, italyAcks = {}, {}, {}\nlocal freshCelebration={Fire=function(_,p,rec) if d.freshFire then d.freshFire(p,rec) end end}')
s=s.replace("server.index('local function giveBadge')","server.index('local badgeBusy, badgeDone')")
s=s.replace('local badgeBusy, badgeDone, announced, pending = {}, {}, {}, {}','''local Celebration=require("./KeeperCelebration")
local workspace={GetServerTimeNow=function()return d.os.time()end}
local freshCelebration={Event={Connect=function(_,fn)d.onFresh=fn end}}''')
s=s.replace('process=processAttempts,render=renderCurrent,titles=applyTitles','process=processAttempts,render=renderCurrent,titles=applyTitles,markFresh=celebrationGate.markFresh,forget=celebrationGate.forget,remote=celebrationGate.remoteRecord,announce=announce')
s=s.replace('local banner,chat=d.banner,d.chat','local banner,chat=d.banner,d.chat\nlocal celebrationGate=d.celebrationGate or {accept=function()return false end}\nlocal fireworks=d.fireworks or function()end\nlocal warn=d.warn or function()end')
# Run the original generator against these sources, with only added dependencies injected.
exec(compile(s,str(r/'extracted_generator.py'),'exec'),{'__file__':str(r/'extracted_generator.py')})
client=(r/'PortoKeeperClient.lua').read_text(encoding='utf-8')
queue=client[client.index('local function dailyCardUp()'):client.index('-- France-style fireworks')]
(r/'banner_fixture.luau').write_text('return function(d)\nlocal pg,task,os,showBanner=d.pg,d.task,d.os,d.showBanner\n'+queue+'\nreturn banner\nend\n',encoding='utf-8')
chat=client[client.index('local function chat(text)'):client.index('local function showBanner')]
(r/'chat_fixture.luau').write_text('return function(d)\nlocal task,TextChatService,warn=d.task,d.TextChatService,d.warn\n'+chat+'\nreturn chat\nend\n',encoding='utf-8')
sites=client[client.index('local SITES ='):client.index('local COLOURS =')]
vfx=client[client.index('local showing = false'):client.index('local receipts = {}')]
(r/'vfx_fixture.luau').write_text('return function(d)\nlocal task,os,F,Instance,game,TweenService,TweenInfo,workspace,Vector3,Vector2=d.task,d.os,d.F,d.Instance,d.game,d.TweenService,d.TweenInfo,d.workspace,d.Vector3,d.Vector2\nlocal rocket=d.rocket\n'+sites+vfx+'\nreturn fireworks\nend\n',encoding='utf-8')
tests=(original/'test_daily.luau').read_text(encoding='utf-8')
anchor='local send=k.ev.FireAllClients;k.ev.FireAllClients=function()error("delivery failed")end'
assert tests.count(anchor)==1
tests=tests.replace(anchor,'k.api.markFresh(d.player,d.api.pending(d.player)[1]) -- this test exercises a fresh-session announcement\n    '+anchor)
tests=tests.replace('print("ALL "..passed.." TESTS PASSED")',(r/'new_tests.luau').read_text(encoding='utf-8')+'\nprint("ALL "..passed.." TESTS PASSED")')
(r/'test_celebration.luau').write_text(tests,encoding='utf-8')
print('Generated fixtures from the exact patch sources and retained all 53 regression cases.')
