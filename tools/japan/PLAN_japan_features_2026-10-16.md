# Japan features plan (Oct 16 2026) - Shannon's list, how each would be built, and a suggested order

Shannon: "apart from housekeeping to make the map look good, here are some plans for the Japan map: build out the Cat Cafe with cute
meshy animated cats; a kimono store that is already built out but where you can choose your fabric and buy a wearable kimono;
photographer who takes your photo with the volcano in the backdrop, the photo can be saved and hung in your treehouse; feed the koi in
the pond by the palace (it makes the water rumble and all of the koi rush the side of the pond in a feeding frenzy); shoot a bow and
arrow at the targets by the palace; a bamboo maze like a corn maze, but with bamboo."

Standing rules apply to all of it: meshes not Roblox-part builds for scenery (Blender for hard shapes, Meshy for creatures), saves
only through RS.AwardItems / RS.AwardAcorns, look tests with pictures before anything is installed, she publishes.

## 1. Feed the koi (palace pond)  - SMALL, first
- Where: the palace koi pond (JP_Koi_Pond_Shore, now colour-fixed). 8-10 of her Meshy koi swimming slow meanders there (the canal's
  CanalLife client motion, a second instance).
- Play: a koi-food stand by the pond (a mesh tub + ProximityPrompt): "Koi food - 5 acorns". Buying gives a handful (Item_koifood 3);
  at the pond's edge, E throws a pinch into the water in front of you.
- The frenzy: the server fires "KoiFeed" with the spot; every client runs the frenzy for ~12 s - the koi break their loops and race
  to the spot, circle it tightly with splashes (particles + ripple rings), the water "rumbles" (a low rumble sound + a camera shake for
  players within 20 studs + the surface churned with particle foam), then they drift back to their loops. One frenzy at a time.
- Save: nothing beyond the food count. A small reward the first time each day (acorns via RS.AwardAcorns) to make it a daily habit.
- Needs: her koi (have), a food tub mesh (Blender), two sounds (she picks or the library), the pond's layout from a runner survey.

## 2. Bamboo maze  - MEDIUM, mostly placement
- Where: a flat 110 x 110 pocket (runner survey for a site; the lawn past the canal's south end is 120 x 55 - too narrow; maybe the
  ground behind the station or near the volcano's foot).
- Pieces (Blender): a bamboo "hedge" segment (a dense row of culms with node rings and leaf tufts at the top, 8 long, 9 tall - a hard
  shape, reads well faceted), a corner post, an entrance torii-lite gate, a centre pavilion / prize stone.
- Layout: a real maze (recursive backtracker) on an 11 x 11 grid of 8-stud cells, one entrance, a prize at the centre; the layout is
  seeded by the DAY so it is the same for everyone that day and changes tomorrow (a reason to come back).
- Play: enter, find the centre, touch the prize stone -> acorns once per day (RS.AwardAcorns), a timer on the HUD; a "lost?" hint
  after 3 minutes (a bird flies toward the exit). Streaming: hedge segments as one Model per wall run.
- Budget: ~200 wall segments (one mesh, instanced) + gates - about 220 parts.

## 3. Photographer (volcano backdrop) + the treehouse photo  - MEDIUM, a nice tie-in
- Where: a photo spot on the lawn with Fuji/the volcano behind (runner picks the best sightline), a photographer NPC squirrel with a
  tripod camera (Blender), a ProximityPrompt "Photo - 10 acorns".
- Roblox cannot take a real screenshot into the game, so the "photo" is RE-RENDERED: a ViewportFrame shows a clone of the player's
  avatar (its HumanoidDescription) in the chosen pose in front of a painted volcano backdrop image, inside a wooden frame. The take
  itself is staged: the camera swings to the photographer's view, "3, 2, 1", a flash, the shutter sound, and the framed photo pops up.
- Saved as Item_photo_<poseId> (the pose; the avatar is always the player's current look - or we store the HumanoidDescription's key
  pieces if she wants the outfit of the day kept). Hung in the treehouse: a photo frame spot on the room wall (one, or up to three)
  shows the saved photo; "Hang photo" at the frame.
- Needs: a backdrop image (I render the volcano backdrop from the actual map in a play test as a reference, then paint/render a
  version she uploads), the tripod camera mesh, 4-6 poses (Roblox's built-in emote animations can pose the clone).

## 4. Bow and arrow at the palace targets  - MEDIUM-LARGE
- Where: the palace grounds; targets (Blender: straw-roll targets on stands, 3 at 20 / 30 / 40 studs).
- Play: a fixed archery STATION rather than a hotbar tool (no tool ownership, no griefing): step on the mark, E to take the bow, the
  camera goes over-the-shoulder, hold to draw (power), release; the arrow flies a real arc (server-simulated, raycast per step), sticks
  in the target or the ground, rings score 1 / 3 / 5 / 10 (bullseye). 5 arrows a round; a scoreboard sign shows the day's top 5;
  acorns for the round's score (capped per day via RS.AwardAcorns); a "Kyudo" badge item for a first bullseye.
- Needs: bow + arrow + target meshes (Blender), the draw/release sounds, a small server script with the arc math and anti-cheat (the
  server owns the arrow).

## 5. Kimono store (fabric choice, a wearable kimono)  - MEDIUM, asset uploads
- The store exists. Add: a fabric wall (6-8 bolts, Blender) each with a ProximityPrompt "Try on", a mirror spot, "Buy - N acorns".
- Wearable: the dependable route is CLASSIC CLOTHING - a Shirt + Pants pair per fabric (a kimono printed on the shirt/pants templates:
  the crossed collar, the obi sash, the sleeves on the arm panels). I draw the templates (one per fabric), she uploads them (8 shirts +
  8 pants = 16 assets, moderation), the store applies them to the Humanoid; the player's own clothing is restored when they take it
  off. A 3D layered-clothing kimono would look better but needs rigging and fitting we don't have.
- Save: Item_kimono_<fabric> (owned) and Item_kimono_worn (which one is on) through RS.AwardItems; re-applied on join by a small
  server script.

## 6. Cat Cafe with Meshy animated cats  - LARGE, last (or in parallel while she makes cats)
- The cafe interior exists (seats, food). Add 5-6 cats: Shannon generates them in Meshy (sitting, loafing, standing, stretching - a
  pose each, 2-3 breeds), runner decimates (~2k tris each).
- "Animated" without rigging: each cat is a Model that LIVES - it moves between 8-10 spots (cushions, the counter, a window sill) by
  gliding slowly with a tail-sway (the tail as a separate small mesh, swung by a tween) and swaps to its sitting/loafing pose mesh when it
  arrives; blinks (two eye meshes scaled); occasionally stretches (the stretch pose for 2 s). Pet a cat (ProximityPrompt): it purrs
  (sound), hearts, and it follows you around the cafe for 30 s. Treats at the counter (acorns) make a cat come to you.
- Save: a "cats petted" tally -> the cafe loyalty card item (Item_catcafe_card) at 20 pets; a hat reward later.
- Needs: Meshy cats (hers), sounds, a runner survey of the cafe interior for the spots.

## 7. Sushi memory match (the sushi bar)  - SMALL, pure UI, first or second
- Shannon: "maybe a mini game at the sushi shop where you match sushi cards? like the memory matching game with cards?"
- Where: the sushi bar's counter - a lacquer tray on the counter (Blender) with a ProximityPrompt "Sushi match - 3 acorns" (or free
  once a day, then 3 acorns a go).
- Play: a card panel (the bottle game's panel style): 4 x 4 face-down cards (8 pairs: tuna nigiri, salmon, tamago, ebi, maki roll,
  temaki, uni, a wasabi joker) drawn as flat sushi icons (I draw them as ImageLabels from one uploaded sprite sheet, or as pure
  Frame/UIStroke shapes so no upload is needed); flip two, a match stays up with a little "yum" sound, a miss flips back after 0.8 s; a
  move counter and a 60 s timer. Clear the board -> acorns by moves (16 moves perfect = 15 acorns, down to 5), a "Sushi master" item
  at 3 perfect boards; the day's best moves on a small sign by the tray (per player, saved as Item_sushi_best).
- Fits phones (the bottle panel already does), no new assets but the tray mesh and the card art, a client script + a tiny server
  validator for the award. A daily free go is the comeback hook.

## 8. A church (one on every map; here it must blend in)  - MEDIUM, a Blender building
- Shannon: "we need a church building somewhere on the map, because we will have one on every map, it needs to blend in, but it will
  be a church." Not odd for Japan: the Goto Islands and Nagasaki have 150-year-old churches that look exactly like this brief - white
  wood or plaster walls with dark timber, a Japanese TILED roof (the same kawara tiles as the houses), arched windows, a small square
  bell tower with a cross (Egami, Kashiragashima, Tabira). Blended, and still a church.
- Build (Blender, our finish): a nave ~30 x 16, 11 high to the ridge; white plaster with dark timber framing (Lantern Street's palette);
  a steep tiled roof with up-turned eaves; six arched windows with simple coloured glass panes (Glass + a soft Neon frame at dusk); a
  wooden double door up three stone steps; a 22-tall bell tower at the front corner with louvred openings, a bronze bell inside and a
  cross on top. Interior: pews (automatic sit), a plain altar with a cross, a lectern, candles (PointLights). A bell rope: ProximityPrompt
  "Ring the bell" -> the bell swings (tween) and tolls (sound), once a minute per player.
- Site: a runner survey - candidates: the quiet lawn past the canal's south end (behind the falls), the rise near the station, or the
  lawn by the arrival court. Footprint ~34 x 20 with a path and two stone lanterns at the gate.
- Shared with every map: the same interior kit (pews, altar, bell) and whatever the church DOES in the game (her call: a quiet place,
  the bell, a daily blessing, weddings?), with each map's own exterior (Italy: a Romanesque stone chapel with a campanile; France: a
  village church with a slate spire). The kit is built once, the shells per map.
- Budget: ~12 meshes for the shell + the interior kit; one import.

## Suggested order
1. Sushi memory match (small, no site work, a daily hook) -> 2. Koi feeding (small, uses what we have, by the palace where archery
also goes) -> 3. Bamboo maze -> 4. Photographer + treehouse photo -> 5. Archery -> 6. Kimono store -> 7. Cat cafe (her Meshy cats can
be made any time; the build waits for them).
Each one: a design note with her choices, a runner survey of the site, a look test with pictures, then the install.

## Her choices needed
- The order (or "do them in the order you suggest").
- Koi feeding: price of a handful (5 acorns?), the daily first-feed reward.
- Maze: the site (runner proposes two), the daily prize.
- Photo: how many frames in the treehouse (1 or 3), keep the outfit of the day or always the current look, the price.
- Archery: a fixed station (my suggestion) or a hotbar bow; the daily acorn cap.
- Kimono: how many fabrics, patterns she wants (I'd propose 8: indigo wave, cherry blossom, crane, hemp leaf, plum, gold chrysanthemum,
  tortoiseshell, black with red obi), the price, classic clothing OK.
- Cats: how many and which breeds; whether cats also wander outside the cafe.
- Church: what it does on every map (the bell only, a daily blessing, weddings, a memorial wall...), the site (runner proposes), and the
  look: A. the Goto-island wooden church (white walls, dark timber, tiled roof, small cross tower - my suggestion) or B. Nagasaki's Oura
  style (white Gothic stone, pointed arches).
- Sushi match: free once a day then 3 acorns a go (my suggestion), the 8 sushi kinds, whether the card art may be drawn in UI shapes
  (no upload) or she wants real pictures (one sprite sheet to upload).
