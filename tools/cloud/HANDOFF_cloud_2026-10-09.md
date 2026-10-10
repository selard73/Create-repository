# Cloud-session handoff: 1001 Squirrels, Oct 9 2026

For a new cloud Claude session taking over from "GitHub free credit eligibility" (session_01LfciYHk748d9UkpWpohC4v).
Read this, then `tools/cloud/JOB.md`, then the Oct 8 handoff (HANDOFF_2026-10-08_EVENING.md) for the game's rules.

## How the work gets into Studio (the bridge)
- This cloud session cannot reach Roblox Studio. Shannon runs a LOCAL Claude Code session on her PC (Claude Desktop,
  `/remote-control` on, Roblox Studio MCP tools). It appears here only as an inbound messenger: it can SendMessage to the
  cloud session (which shows in ITS ListAgents under the cloud conversation's title), the cloud session CAN message it back with
  mcp__claude-code-remote__send_message to the runner's session id (the bridge:session_... id on its messages); give it
  commit-SHA raw URLs, since the branch raw URL is CDN-cached for minutes.
- Jobs travel through the repo: the cloud session appends numbered jobs to `tools/cloud/JOB.md` (raw GitHub URL, branch
  claude/epic-hawking-188q4l); Shannon types `next` in the local thread; it fetches the file (curl to
  raw.githubusercontent.com/selard73/Create-repository is allowed in her settings), runs the lowest unfinished job, and
  sends the Output lines (all prefixed `QQ <TAG>`) back as a cross-session message.
- Rules the local runner follows: ask Shannon before every Studio edit; READ-ONLY / DRY scripts just run; never publish
  (Alt+P is hers); never write DataStores. Her local thread is in Manual permission mode.
- Every Studio script is exact-string patching with length guards + loadstring compile checks, or new instances;
  originals go to ServerStorage.HudBackup.* (scripts) or ServerStorage.CSGBackup_* (cut parts). Scripts are syntax-checked
  here with the luau CLI (scratchpad/luau/luau-compile) before pushing.
- If a new cloud session is started, tell Shannon its conversation title so she can re-point the runner's prompt (the
  starter prompt is in the Oct 9 chat; the key line is the SendMessage target name).

## Done today (all in Studio; Shannon publishes)
1. Square floor flicker: 15 parts CSG-cut (square_fix1 passes 1-2), stacked points 13432 -> 32. Published, VR confirmed.
2. Town-wide floor flicker: town_fix1, 560 floor parts cut / 12 retired, stacked points 175183 -> 16793. Published,
   Shannon: "the glitchy ground IS fixed". Second round not yet run (would catch newly exposed pairs + rail piers,
   church rocky foundation, retaining walls via ALLOW_LOWER). town_undo1 walks everything back.
3. Camera patch 1 (vraim): VR aim from the controller, beam + ring that fills in when the shutter would accept.
   Camera patch 2 (vrzoom): right-stick zoom + viewfinder, ground/sea tiles and far whale in photos. Both live.
   Local copy italy/camera/CameraClient_v3.lua = Studio (65257 chars). Shannon: "good enough for now".
4. Phone: Roblox hotbar has 3 slots on phones; 4 tools. phone_slots_patch (StowServer 3444, ShopClient 34513 chars):
   equip past the slots stores the oldest other tool; "fit" on arrival. In Studio, not yet published/tested on phone.
5. Diver (snorkel squirrel) seated then moved 3 studs back onto flat sand (attr FlatOct9OrigCF). Groves music ->
   1848102847 (MapMusic attr porto_groves; old id in OldSoundId_Oct9).
6. Built, awaiting install (job 17): tools/porto/install_italy.lua = Italy passport outings (11 entries) + Bella's beach
   game (workspace.SeaGlass). Sources in tools/porto/src; generator make_install_italy.py.

## Open items
- Job 17 install + play test, then publish; then Shannon's feedback on the beach game and the Porto passport tab.
- Terrain pairs still flicker in VR (funicular track bed on grass 1026 pts, lighthouse apron 708, rail piers 514):
  cannot be cut; the fix is to raise those parts ~0.3 or reshape the terrain under them. Not started.
- Funicular cars' vertical panel/post gaps (0.06) flicker in VR: a separate small pass (merge coplanar panels or push 0.3).
- Opera outing uses sound 9042832054 (attr OperaSoundId on workspace.PortoPassport). Passport art for the Porto outings
  reuses French PassportArt models (map in PassportVisuals); Porto-specific art is a later job.
- French zipline and glider outings never fire (pre-existing).
- Sea glass v2 ideas (hers): the All Things Bella shop window items, the parfum shop in France (bottle + lemon, lavender).
- Shannon is budget-conscious ($250 cloud credit): short messages, no background review workflows unless asked,
  one job at a time with a "publish and look" checkpoint. She found the camera patch review and the town review useful
  but expensive; the camera review's last agent hung and never finished.

## Later on Oct 9 (session "Cloud session handoff")
- Job 18 (italy_fix1): sea glass off the seabed, Bella's panel scaled on phones, Porto Outings listed. Job 19 (opera_hush1):
  map music off while the opera singer sings, back 2 s after. Both verified in a play test; not yet published.
- The harbour bell works: prompts only show when on screen; job 17's camera faced away.
- Balloon field (far shore, centre ~106,-48,-648, grass, nothing built): Shannon's Meshy balloon cleaned in Blender ->
  tools/balloon/model_meshy/balloon_meshy.fbx (blender/meshy_clean.py; bpy 5.2 venv in the scratchpad). Flight she wants:
  up for a view, a gust blows it out to sea, storm fog + lightning, sign 'To Be Continued'. Her own balloon unlocks at 44/44
  Porto squirrels; 3 show balloons. Next: job 23 (import + check), then the field installer.
- Shannon's VR bug list (Oct 9 evening): passport pages per map (job 25, tools/passport), Keeper statue once per player
  on France's 44 (job 26, tools/champion), gallery portraits blink in VR -> bust pictures in VR (job 27, tools/portraits),
  Porto Guardian "not working" = owner excluded by design (Oct 7), Bella's prompt did nothing in VR (cause unknown; asked
  her what she saw). Generators read their anchors from the build files; Studio texts confirmed via job 24 before running.

## State at the end of the Oct 9 cloud session ("Cloud session handoff"; Shannon's cloud credit nearly spent)
Installed in Studio and PUBLISHED by Shannon (Oct 9 evening): jobs 17-32, 34, 35, 38, 39 (passport pages per map,
Keeper once, VR gallery portraits, Guardian on arrival, Porto music fixes, Groves music, both beaches, Bella's reveal +
pearl + shell box (sells 150), Daily auto-collect, Piazza Race + its passport outing).
Sent to the runner, waiting for Shannon's yes / not yet published: 37c (race gate+board on the piazza's west edge at
431.5,-12,-812 / -824, 60%, facing in), 41 (Bella's panel at the right of the screen + hidden 6 s during the reveal,
reveal left/lower), 43 (store row "Parfum bottle" once owned), 40 (VR window: pop-ups on a panel 38 deg right of the body;
HUD/shop screens stay on Roblox's panel; test in the headset), 33 (balloon field + the finale flight; the imported
balloon_meshy is the template; attributes on workspace.BalloonField tune everything: GustDir, RiseHeight, DriftCenter...).
Known open items: the Wardrobe tab inside the Passport will not build on the VR window (WardrobeClient waits on
PassportGui.Page); VRWindow legibility/size (Width/Distance attributes) to be judged in the headset; passport outing for
the balloon flight (none yet; Item_balloon_flights records the first flight); the "porto_balloon" moment has no sound ids
(WindSoundId/ThunderSoundId = 0); the race's music key is the forest "race" track by design.
Every Studio change has a backup under ServerStorage.HudBackup.*_pre_<job>. Generators live beside each script
(tools/<area>/make_*.py); the luau CLI for syntax checks is downloaded into the scratchpad (see tools/cloud/JOB.md top).
The runner: send_message to its session id (bridge:session_01FmVm5n3mKMAfYwLsZWtahf as of Oct 9), commit-SHA raw URLs.

## Saved for later (Shannon, Oct 9 evening)
- Dresses from the French map on her new avatar: "that avatar had no arms when I put on the dress". Revisit the dress
  shop's wear code (village/dresses/build_dressshop.lua: what it hides or replaces on the character) against other body
  types / bundles; make sure nothing looks weird on any avatar. Not started; she said "save that idea for later".
- VR UI (Shannon, Oct 9 night): the head-following VR window "is not a good technique". Done so far: the balloon's notes and
  the squirrel bubbles are world things in VR (jobs 54, 55). To do: make the VR window / panels grabbable with the
  controller (point + grip to drag; stays where put; re-grab to move), so the picker and the rest sit where she wants them.

## Housekeeping for later (Shannon, Oct 10 ~05:00 UTC, before signing off)
1. Waterfall cliff: "some blemished places on the cliff front where the waterfall comes down" need fixing. Start from
   HANDOFF_2026-09-30_FALLS.md (workspace.SouthGorge.Rock, SouthCliff_W01..W04 / E01..E04 / L01 with _Lo halves;
   generators italy/gorge_real/*.py and italy/falls/gen_falls2.py). First job: a Studio survey + screenshots of the
   cliff face either side of the sheet so she can point at the blemishes.
2. French clothing: "revisit clothing in the French section; some issues with the way the clothing was built". Code is
   village/dresses/ (build_dressshop.lua, DressClient/DressServer, WardrobeClient, dress_kit.json, FIT_RELEASE_2026-09-28.md).
   Ties in with the earlier note below about dresses on her new avatar (no arms). Ask her which issues she saw before building.
3. Message in a bottle game: not built yet. The Porto cast list in HANDOFF_2026-10-01_CHATGPT_PORTO_NOCCIOLA.md has a
   "bottle finder" squirrel; nothing else exists. Needs a design chat with her first (where bottles wash up, what is in
   them, reward).
4. Italy squirrels should randomly talk more to passers-by. Speech bubbles live in tools/bubble (sayVR for VR, job 55);
   Porto activities in tools/porto/src/PortoActivities.lua / install_italy.lua. Idea: an ambient-chatter module with a
   per-squirrel line pool, triggered when a player walks within a few studs, cooldowns so it is not spammy.

## Runner restart (Oct 10, after the "Remote control" runner thread was archived with its memory nearly full)
The old runner's last report was jobs 53-55 (applied). Jobs waiting, in this order, each after asking Shannon (no publish):
- Job 56: https://raw.githubusercontent.com/selard73/Create-repository/8b21dcf/tools/balloon/install_field1.lua — BalloonClient
  only, in place (32702 chars; server unchanged; back up the old client to HudBackup first). Report the `QQ FIELD` line.
- Job 57: https://raw.githubusercontent.com/selard73/Create-repository/8b21dcf/tools/porto/seaglass11.lua — report `QQ SG11`.
- Job 58: https://raw.githubusercontent.com/selard73/Create-repository/8b21dcf/tools/film/vrtest_remove1.lua — report `QQ VRT`.
Send every report to the cloud session "Cloud session handoff" (session_01Gwhv9KoRg69mUkZf5xktZw) as one short
cross-session message, starting with "runner 3 ready" on the first contact. The cloud session answers the runner by
send_message to the bridge:session_... id its messages carry (runner 3, Oct 10: session_01VuPQ6z5X4cxTdME7EDPUCf,
title "Studio runner for 1001 Squirrels"). The lowest unfinished job is always the next one; JOB.md
holds the full list and every result so far.
- Shannon's Desktop is C:\Users\slard\OneDrive\Desktop (the Windows known folder), not %USERPROFILE%\Desktop - files for
  her go there (runner 3, Oct 10).

## State at Oct 10 04:45 UTC (all published unless noted)
- Live: balloon finale (smooth flight, VR stand-off camera, film tour "Balloon flight" in F8, world notes), Bella's game on
  phone/desktop/VR, VR speech bubbles beside the head, the piazza race, the Acorn Store's "Fountain magic" row (Club Rana,
  Petals; 25 acorns, two minutes, one at a time), the Club Rana frog resort and the petal fountain, the opera spotlight
  (OperaLights; round two with brighter spots, a gentler dim, the Listen prompt hidden while she sings), the phone slingshot
  and binoculars (PreferredInput; HOLD button at (1,-115,1,-45) 100 px; away from the hoops the acorn goes where you look).
- Dropped: the spaghetti fountain (Shannon: "too hard to pull off"). Its code is gone from FountainModeClient; the sauce
  helpers (tintWater/untintWater) remain unused.
- Runner 3 (session_01VuPQ6z5X4cxTdME7EDPUCf) is idle in Edit mode; it caches installer pieces by checksum.
- Open: grabbable VR panels (the VR window follows the head; Shannon dislikes it); dresses on her new avatar (no arms);
  Bella's reveal in VR is "good enough" after job 62; the PromptTouch stack can cover the slingshot's note on a phone.
- Numbers to tune live as attributes: workspace.FountainModes (Petals*, Minutes, SignText, DeckAngle, FrogSoundId),
  workspace.OperaLights (Spot*, Dim*, Fade*), workspace.Hoop.HoopRange, workspace.BalloonField (VRCam*, sounds).
