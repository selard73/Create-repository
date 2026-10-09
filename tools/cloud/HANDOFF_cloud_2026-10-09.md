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
