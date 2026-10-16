# Japan restyle plan (job 125, Oct 16 2026): keep / upgrade / new, garden first

Shannon: "I want us to build our own styled off of these ... we will combine this with some of what we already have".
References: tools/japan/reference_2026-10-16 (ref_01..09). Nothing is copied from that game; we build our own pieces.

## What actually makes the references look real

Comparing ref_01 / ref_04 with our canal bridge (shots106/after_canal_north_end) and Lantern Street (fight_Walkway_vs_Lantern_Street_paving):
1. **Textured surfaces.** Their paving has joints, wear and depth. Ours is flat white SmoothPlastic and plain Slate, so it reads as plastic.
2. **Dense planting.** Knee-high grass, shrubs and flowers line every edge. Our ground is flat bright-green terrain, ending at hard edges.
3. **Soft light.** Slightly overcast, hazy, warm and low-contrast. Ours is noon-bright, saturated and sharp-shadowed.
4. **Organic hero shapes.** Their maples are layered leaf cards, and their rocks, lanterns and bridge are real meshes. Ours are blocky parts.

So the biggest gains come from surfaces, planting and light. Those touch the parts we already have, and they are cheap on phones. The hero meshes come after.

## KEEP AS IS

- The Shinkansen and railway, its three stations and the train ride.
- The palace architecture and its interiors, Fuji and the volcano, the lake and the horizon sea.
- The balloon landing and the airport taxi, the private-preview gate (with Shademade as a guest), and the music zones.
- The shop interiors (the cat cafe, sushi bar and kimono shop) and their gameplay (seats, food).
- The squirrel spots, and everything already fixed in jobs 105-106.

## UPGRADE (existing parts, new look)

**Garden-first upgrades**
- **U1. Light inside Japan only.** Through JapanAtmosphere, so France and Porto are untouched: soft overcast, gentle haze, a warm colour grade with slightly lower contrast. One script change, zero parts. The cheapest big win.
- **U2. Ground materials.** New PBR MaterialVariants on the parts we already have:
  - grey stone slabs with joints for Lantern Street, replacing the flat white;
  - cobble with inset slabs for garden paths;
  - mossy wet rock for the canal and lake edges.
  - Also clean up the duplicated JapanMoss / JM_Photographic variants.
- **U3. Planting along every edge.** Tall-grass and hydrangea clump meshes (one asset each, reused) along paths, canal banks and building feet; mossy boulders where ground meets wall.
  - Note: Roblox's terrain grass setting covers the whole place, France and Porto included. So Japan gets grass meshes, unless you want terrain grass everywhere.
- **U4. The red bridge over the canal** becomes a proper arched taiko bridge (a hero mesh), with wet rocks at its feet.
- **U5. The maple and blossom groves:** layered leaf-card maples in autumn orange and red, replacing the leaf balls, plus one twisted black pine near the bridge.

**Town upgrades (after the garden)**
- **U6. Building materials:** dark timber and white plaster, PBR roof tiles and cedar boards on the Lantern Street fronts.
- **U7. Lantern Street's lanterns:** strings of round cream paper lanterns with a red crest, hung on wires across the street, glowing at dusk.
- **U8. The market:** rope-bound wooden tubs with paper price tags, slatted produce crates, and chalk A-frame signs (hero meshes, reused). The stalls stay where they are.
- **U9. The temple hall:** red railings and gold bracket details on the existing palace and temple buildings.

## NEW

- **N1. The Momiji Garden, phase 1.** A garden pocket built around the existing canal and red bridge (x ~6100, z -215), unless you want it elsewhere:
  - a waterfall over mossy rocks at its head feeding the slow canal;
  - the taiko bridge (U4) and a torii behind it;
  - autumn maples and the black pine, tall grass and hydrangeas;
  - a raked white-gravel bed, and a stepping-slab path with stone lanterns (toro) and low path lights.
- **N2. Lantern Street, phase 2.** Two-storey machiya shopfronts with open fronts, counters and noren curtains, as one kit reused along the street. Plus a big torii over the street, stone stairs with metal rails, trees in planters, and bollards.
  - Their streets are empty. Ours stay full, with our shops and squirrels.

## How we build it

- **Hero meshes** come from your Meshy pipeline (Meshy, then Blender, then Roblox, as with the pelican and gull), cut down for phones: stone lantern, taiko bridge, autumn maple, black pine, torii, wooden tub, produce crate, paper lantern, machiya front. Studio's generate_mesh and generate_texture can fill in small pieces.
- **Materials** are PBR MaterialVariants applied to parts we already have, so no new parts.
- **Phone budget:** Japan has 20,422 parts today. Every step reports its before and after counts. Hero meshes are reused across many spots, and wherever a mesh replaces a stack of blocks, the blocks go, so the net count should fall. StreamingEnabled stays on.
- **Order:**
  1. A **look test** first: one 40 x 40 patch near the bridge with U1, U2, U3 and a lantern and a maple. Previewed in play, with pictures beside ref_01, and you pick what you like.
  2. Then the full garden (N1, U4, U5).
  3. Then the town (U6 to U9, N2).
- Every step is previewed with pictures before anything is installed, and you publish.

## Your choices

1. Tick the items you want from KEEP, UPGRADE and NEW, or say "all of it".
2. Where the garden goes: around the canal and bridge (my suggestion), or another spot. You can stand there in Studio, as we did for the treehouse.
3. Grass: meshes in Japan only (my suggestion), or terrain grass across the whole game.
4. Meshy: will you generate the hero props? I can write the prompts for each one.
