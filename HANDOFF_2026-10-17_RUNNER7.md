# Handoff - 1001 Squirrels, Japan map (Oct 17 2026, ~08:00 UTC) - runner 7, single session

Shannon (selard73; Studio account CozyGameMode / SelBell, user id 9611145467) builds "1001 Squirrels" on Roblox. Since Oct 16 she works
with ONE session on her PC: it designs, builds (Blender), previews in Studio play tests with pictures, and installs in Studio Edit on her
word. Read HANDOFF_2026-10-16_RUNNER7.md for the standing rules and where things are; this file is what changed on Oct 17.

## Rules re-learned today (hers - follow exactly)
- Preview first with pictures; install only on her yes; she publishes (Alt+P) and restarts servers. Ask before every Studio edit.
- Take CLOSE, LOW pictures of the exact thing ("I can't see properly from your screenshots"). Judge every picture yourself first, as she
  would, and fix before she has to say so. Never call a look "fixed".
- Find the CAUSE, not the symptom (the floating walkways were a floating lawn sheet; the rocks floated on it).
- A fix must match the thing's OWN style and the real-world form (the moon bridge's arch runs to the ground; a taiko bridge's giboshi
  sit on the heavy foot posts). When she sends references, build to them. Each shop back must differ ("the rear for each should vary").
- Kit pieces: pivot at the GROUND LINE (not the lowest vertex); the facing: R_y(+90) sends local +z to world +x; add a side check.
- Set CollisionFidelity on the PLACED parts in a separate call after an install (set in the installer it stays Default).
- Import 3D leaves parts unanchored in workspace: anchor + move into ServerStorage.JapanGardenKit BEFORE any play test.
- Her usage rule (70 %): tell her the numbers; she decides ("Keep going ... I'm fine with the usage" at Fable 80 %).

## Published today (all LIVE)
canal falls r3 + bridge ends; the palace pond (pondfix1); the bamboo maze (bamboomaze1) + its daily exit reward (mazereward1, 25
acorns); the moon bridge ends round 3 (moonbridgeend3); wayfinding (wayfinding1: 4 fingerposts, map board, 6 station banners); the
floating ground (islandbase1 + propground1 + walkfix1).

## In Edit, NOT yet published
- Shop backs round 2 (shopbacks2 = GitHub 394403d + the window-spots patch = cc7b8c3; kit20). JapanMap.ShopBacks, 164 pieces.

## Next (her order)
1. The Mikan greengrocer FRONT from her photo (tools/japan/reference_2026-10-17/SHOPFRONTS.md #2): a big grey-tiled awning over the
   whole front on a timber frame with posts on the lane, a carved wooden sign on the front beam, shelves of jars at the back wall,
   baskets of goods on low benches outside, lanterns under the eave (exist), dark side banners with a crest, potted bamboo, a standing
   lantern sign. The front today: canvas awning panels 15 out over the lane (retire), counters with vegetables, noren, 2 paper lanterns,
   front x 6011..6013, z -173..-143, lane at x 6000, ground 0.46 (Continuous market floor).
2. The other shop fronts the same way (Takayama dark-timber reference saved as a file).
3. Option 3 for "the map feels too big": koi feeding at the pond (PondLife koi exist), photographer on the west lawn, archery on the
   palace court, cat cafe in the market (her Meshy cats); then trim the south strip + north margin to sea/cliff (terrain).
4. Maybe: denser slats on the lattice panels (they can read as a fence at a distance).

## Where things are (new today)
tools/japan/garden: gen_pond.py / pondfix1.lua; gen_bamboo.py / bamboomaze1.lua / mazereward1.lua; gen_moonbridge_end3.py /
moonbridgeend3.lua; gen_wayfinding.py / wayfinding1.lua; gen_shop_back2.py / shopbacks2.lua (+ check_*.py renders). tools/japan:
islandbase1.lua, propground1.lua, walkfix1.lua. Kits 11..20 in out_* folders (FBX in git with -f). Pictures in tools/japan/garden/shots_*
and C:\Users\slard\Create-repository-shots. Every result is in tools/cloud/JOB.md with QQ lines.
Install pattern: fetch the raw GitHub file at a SHA on the Server / Edit datamodel (HttpEnabled on, GetAsync, off), adler32 check, run
in a ModuleScript wrapper with a collecting print; the same code is the play-test preview. Her kit folder: OneDrive\Desktop\Japan garden kit.
GOTCHA: GitHub pushes can fail on this PC when it is low on memory (git's credential prompt will not start) - commit locally, push later.

## Oct 17 ~08:30Z addendum
- Mikan greengrocer front INSTALLED in Edit (shopfront_mikan1 at 30d5769, kit21), unpublished with the shop backs. Next: the other fronts, each from a reference; then option-3 features; then the margins.
