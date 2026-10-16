# Japan restyle plan (job 125, Oct 16 2026): keep / upgrade / new, garden first

Shannon: "I want us to build our own styled off of these ... we will combine this with some of what we already have".
References: tools/japan/reference_2026-10-16 (ref_01..09). Nothing is copied from that game; we build our own pieces.

**REVISED (Shannon, Oct 16): "I don't want it too realistic, on same par with the italy and france maps, just same elements as in the
photos".** So: the ELEMENTS from the pictures, built in OUR style - the same look and finish as Rue de Noisette and Porto Nocciola
(our own parts and meshes, the game's normal light, Roblox's built-in materials with our colours). No photographic textures, no
overcast/haze grade, no realism pass. The light item (U1) and the photographic ground variants are dropped.

## The elements to bring in (from the pictures)

- Garden: a river fed by a waterfall over rocks, a red arched bridge, a torii behind it, autumn maples, one twisted pine, stone
  lanterns, tufts of tall grass and flower clumps along the edges, a stepping-slab path, a raked-gravel bed.
- Town: two-storey wooden shopfronts with open fronts, wooden tubs and crates of produce with little price tags, A-frame signs,
  strings of round paper lanterns across the street, white-plaster-and-timber houses, a temple with red railings, a big torii over
  the street, stone stairs with rails, trees in planters.

## KEEP AS IS

- The Shinkansen and railway, its three stations and the train ride.
- The palace architecture and its interiors, Fuji and the volcano, the lake and the horizon sea.
- The balloon landing and the airport taxi, the private-preview gate (with Shademade as a guest), and the music zones.
- The shop interiors (the cat cafe, sushi bar and kimono shop) and their gameplay (seats, food).
- The squirrel spots, and everything already fixed in jobs 105-106.

## UPGRADE (existing parts, new look)

**Garden-first upgrades**
- ~~U1. Light~~ - dropped (the revision): Japan keeps the game's normal light, like France and Italy.
- **U2. Ground, in our style.** Lantern Street's flat white paving becomes grey stone slabs (Roblox's Slate/Cobblestone with our
  colours, laid as slabs with joints - as Porto's piazza is), garden paths cobble with inset stepping slabs, rocks along the canal and
  lake edges. The duplicated JapanMoss / JM_Photographic variants are tidied.
- **U3. Planting along the edges.** Tufts of tall grass and flower clumps (our own low-poly clumps, the same kind of thing as the
  French flower beds; one asset each, reused) along paths, canal banks and building feet; boulders where ground meets wall.
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

- **Hero pieces** come from your Meshy pipeline (in the same stylised look as our Porto squirrels' props, not realistic) (Meshy, then Blender, then Roblox, as with the pelican and gull), cut down for phones: stone lantern, taiko bridge, autumn maple, black pine, torii, wooden tub, produce crate, paper lantern, machiya front. Studio's generate_mesh and generate_texture can fill in small pieces.
- **Materials** are PBR MaterialVariants applied to parts we already have, so no new parts.
- **Phone budget:** Japan has 20,422 parts today. Every step reports its before and after counts. Hero meshes are reused across many spots, and wherever a mesh replaces a stack of blocks, the blocks go, so the net count should fall. StreamingEnabled stays on.
- **Order:**
  1. A **look test** first: one 40 x 40 patch near the bridge with the ground, planting, a lantern and a maple in our style. Previewed in play, with pictures beside ref_01 AND beside Rue de Noisette, so you can check it sits on a par with France and Italy.
  2. Then the full garden (N1, U4, U5).
  3. Then the town (U6 to U9, N2).
- Every step is previewed with pictures before anything is installed, and you publish.

## Your choices

1. Tick the items you want from KEEP, UPGRADE and NEW, or say "all of it".
2. Where the garden goes: around the canal and bridge (my suggestion), or another spot. You can stand there in Studio, as we did for the treehouse.
3. Grass: our own grass tufts in Japan (my suggestion), or Roblox's terrain grass across the whole game.
4. Meshy: will you generate the hero props? I can write the prompts for each one.

## Her answers (Oct 16)
- "I don't want to make the pieces in meshy, but I will if that's what we have to do" -> NO Meshy: the cloud thread builds every piece
  from parts in code (as the Homebase treehouse and the bottle kiosk were), in the France/Italy finish; a simple Blender-made mesh only
  where parts cannot do it, and then only as a one-click import for her.
- "I do not want to change the grass, we should keep consistent as is now" -> the grass stays exactly as it is (no grass tufts, no
  terrain decoration). U3 becomes: shrubs, hydrangea / flower clumps and rocks only where the garden needs them.
- "our current Japan map is TERRIBLE and needs fixing" -> all of it, garden first, around the canal and red bridge (~6100, -215).
Next: runner 7 surveys the canal area (read-only), then the garden look test is designed from that survey.
