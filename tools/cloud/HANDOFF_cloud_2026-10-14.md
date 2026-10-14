# 1001 Squirrels: cloud handoff, Oct 14 2026 (for the new cloud thread and a new Studio runner)

Shannon (selard73, Roblox SelBell / @oodlesofpoodlesyay, user 9611145467) runs the Roblox game "1001 Squirrels" (universe
10766369535, place 117372258657114). This repo is selard73/Create-repository, branch claude/epic-hawking-188q4l. The cloud
thread designs and writes installers; a Studio runner session on her PC fetches them from commit-SHA raw GitHub URLs and runs
them in Roblox Studio. The previous cloud thread was "Cloud session handoff" (session_01Gwhv9KoRg69mUkZf5xktZw); its full
notes are tools/cloud/HANDOFF_cloud_2026-10-09.md (read its "Runner 4" rules and "Runner 6" section) and tools/cloud/JOB.md
(every job, result and her words, jobs 72-92; read from job 87 down).

## Standing rules (verbatim in effect)
- The runner asks Shannon before every Studio edit; read-only surveys and play-test PREVIEWS (an installer's body run on the
  test server, discarded on stop, Edit mode checked unchanged afterwards) need no ask. Never publish: she presses Alt+P.
- Never write DataStores. Installers are exact-string patches with length/anchor guards, every anchor counted before anything
  changes, an ABORT leaves nothing changed; originals backed up to ServerStorage.HudBackup.*; QQ lines reported unchanged.
- Nothing may overlap on a phone screen (measure rects in a play test on the iPhone 7 emulator 667x375 AND the real screen:
  the Studio capture leaves CoreGui out - the tool hotbar y 305..375, the capture bar x 557..601 y 125..249, the jump button).
  A modal card sits on top of everything (DisplayOrder 100) until closed. PlayerGui attribute OpenPanel = the open panel.
- Keep messages short; one install per runner round where possible; pictures to tools/<job>/shots (git add -f, jpg ignored).
- Her Desktop is C:\Users\slard\OneDrive\Desktop. HttpEnabled stays false (the runner turns it on for the one fetch and back).
- Lessons from this week: show her a picture with the GAME's own camera before changing anything visual (a camera rig behind
  her avatar made good bubbles look wrong and cost a whole feature); she wants her existing look kept, "just refined"; no
  spoilers for the waterfall; the mice and squirrels speak only through the ORIGINAL SquirrelBubble (unchanged).

## Live game (published v1327+ ; games API "updated" 13:04Z Oct 14; 497 visits, 10 favourites)
- The Gifts card (workspace.Gifts, tools/gifts): like/star/notifications -> the Backpack, join community 969906332 -> 150
  acorns, invite a friend -> double acorns; shows ~5 s after the first squirrel found or at 180 s; gold glinting buttons; on
  phones the HUD squares stack down the right edge (Passport, Purse, Squirrels, Map), the gift box top row 20 px left of the
  Passport, the squirrel list and the map open left of the column (right edge 549, scaled to clear the Hint button); the phone
  interact pill tries the head's left side (PromptClient 30763 = tools/prompts/src/PromptClient_pill2.lua).
- One click to the boat (workspace.BoatInvite + RS.BoatTake, tools/boatinvite): after the 44th French squirrel a card "All 44
  found! The boat to Italy is waiting at the river dock" [Take the boat] = fade, jetty, aboard; the parachute is packed for
  everyone with all 44 at boarding; the jetty prompt reads "Take the boat" / "Bateau"; the sign's "See Sky Diving Squirrel
  first." line dropped; the Sky Diving Squirrel lends nothing and his lines keep the waterfall a surprise; the Passport's boat
  outings reworded. BoatServer 41494, BoatClient 21020, Passport.Catalogue 11390 (backups HudBackup.*_pre_invite1).
- Darkknight's Guardian of the Harbour statue stands (PortoKeeperServer 11893: waits for Champion.MakeStatue, retries 3x in
  the first minute). Portrait gallery slots are ModelStreamingMode Persistent (job 91; NOT the fix for the blink, harmless).
- Thank-you gifts (workspace.Thanks, tools/thanks): 1000 acorns each to mentallyunstable_xo (dakota), blizzy_1718, bdawg_012,
  paid on their next join through RS.AwardAcorns, flagged Item_thanks_note1; the card "A thank-you from the mayor". Future
  gifts: a StringValue under workspace.Thanks.Gifts (Name = username, Value = acorns, attribute Id), no code.
- Also live from last week: VR interact pills, upright Club Rana frogs, the funicolare PersistentPerPlayer, the cliff backing
  and lip clumps. Cancelled at her word: job 88 (squirrel chatter + church mice); tools/chatter and tools/bubble/*vr2* unused.

## This week, in her order (event Oct 18: "Porto Nocciola Opens!"; everything Italian finished first)
1. The Italian Hall of Fame: a monument of all past Guardians of the Harbour in Porto Nocciola, like the French
   workspace.HallOfFame (HallServer builds each entry with Champion.MakeStatue; the French one is in domaine/build_halloffame.lua;
   PortoKeeper_v1 "first" holds the Guardian record - a list of past Guardians does not exist yet, so the monument starts
   with the current one and a store of past ones is designed with her). Ask where it stands and how it looks before building.
2. The onboarding funnel report (Roblox AnalyticsService LogOnboardingFunnelStepEvent): spawned / first squirrel / fifth
   squirrel / map opened / second area / all 44 / reached Italy, first-session players; shows in the Creator Dashboard. Her
   stats: 33 % still playing at 5 min, 20 % at 10 min; she cannot watch new players herself. Also retention by device.
3. The phone camera "not working again" (live; first ask her what she saw: missing from the tools, or no photo). Last fix:
   tools/shop/src/ShopClient.lua ~line 175 (a phone's hotbar shows 3 tools; the bar is trimmed).
4. The portraits blink on phones and VR, the CHARACTER only, "slow, every few seconds" (the frame, easel and background stay):
   a client diagnostic first (log each rebuild of the sitter image / viewport; her F9 log on the phone), then the fix. The
   client is the CLIENT string in village/build_portraits.lua + tools/portraits/vr1.lua (bust image in VR). The easel
   streaming change (job 91) did not fix it.
5. The look pass, settings only, her words "just refined", no time-of-day or haze change, previewed on desktop + phone, each a
   one-line undo: Terrain grass decoration on (the French floor is Terrain Grass) + grass length ~0.7 + a slightly deeper
   grass colour; water reflectance 0.8-0.9 / transparency 0.6-0.7 / wave size 0.1; Bloom threshold ~1.2 (lantern glow);
   ColorCorrection contrast +0.06 / saturation +0.08; a cloud skybox she picks from the Toolbox (two or three candidates).
   Survey values in JOB.md "Look survey". Props later (tree colour variation, bevels, motes, birds).
6. The message in a bottle game (not built; a bottle stand on a Porto beach, like La Poste; design chat first).
7. The French clothing rebuild (village/dresses; ask which issues she saw).
8. Cosmetics: the dark patch on the grass hill west of the limestone outcrop (x < 8), the tan lumps at the cliff's notch.
On hold: the Last Chance Ranch dog game (a cute Interrogation [AI]; her premise in HANDOFF_cloud_2026-10-09.md "Saved for
later") - after Oct 18, when she says.

## How the threads talk
- The Studio runner is a Claude Code session on her PC with the Roblox Studio MCP. It reads this file + JOB.md, pulls the
  branch, sends "runner 7 ready" to the cloud thread as a cross-session message, then one short message per job with the QQ
  lines unchanged. The cloud thread answers to the bridge:session_... id the runner's messages carry
  (mcp__claude-code-remote__send_message with that session id). Runner 6 (session_01TQwZKeCYsD9TwPfGwTDoud) is inactive.
- The cloud thread: write the installer (Python generator -> .lua in tools/<job>/), compile-check with the luau CLI, review
  adversarially (Workflow) before any install, commit + push, send the commit-SHA raw URL and a test plan. Log every result
  in JOB.md and keep a "State at" line in this file.
