# Japan feature surveys (runner 7, Oct 16 2026, Studio EDIT, read-only)

For the cloud's plan (tools/japan/PLAN_japan_features_2026-10-16.md): the church, the bamboo maze, koi feeding, the kimono.
No edits anywhere. Pictures in this folder.

## 1. Church site (about 34 x 20 plus a path)

**A. The lawn past the canal's south end, behind the new falls (recommended).**
- Area x 6060..6140, z -285..-242. Ground is a flat 0.00 everywhere: the part floor "Japan land foundation basin cut", Grass. No terrain.
- Within 25 studs:
  - the canal falls (6101, 4, -228), 27 x 9 x 21
  - one stepping slab pair east of the falls (6125..6127, -221..-226)
  - three Blender trees on the far edge: a vermilion maple at (6080, -294), an ivory blossom at (6052, -293), a vermilion maple at (6161, -296)
  - the hidden "River end foundation closure" walking support under the lawn at z -226
- Beyond about z -320 the terrain rises: 3.9 at z -340, 11.8 at -360, 24 at -380. It's the green hill with Fuji behind.
- Front: facing NORTH (+z), toward the canal and the garden bridge at z -203. Players arrive along the canal and see it framed by the
  falls, with the hill and Fuji behind.
- Footprint: centred about (6101, -262), 34 across x by 20 deep z. That leaves about 15 between the falls' rocks (z -238) and the
  church front (z -252), room for a gravel forecourt and a short path that splits around the falls from the canal's east and west
  sides.
- Picture: church_A_first_view_from_garden_bridge.jpg, from the garden bridge's crown. The church would stand where the falls' rocks
  meet the trees.

**B. The rise near the station (x 5960..6060, z 160..230)**: not recommended. The railway runs through it (ballast and the station
roof, 0..16.4), plus the 85 iris clusters' strip at z 140..146 and the platform. No clear 34 x 20.

**C. The lawn by the arrival court (x 6080..6200, z 180..260)**: not recommended. "Arrival court" (112 x 75 at y 0) and the
"Japan arrivals" building (6145, 259) fill it, the rail crosses at z 181, and the taxi and walkways are there.

**Others looked at:**
- the north coast behind the canal: the same lawn as A, ending at z -320 where the hill begins
- the south coast past the station: the ground drops to -4 (the sea floor) at z 320+
- west of the market: a narrow lawn strip at x 5800..5900 between the market and the coast terrain (4.7)
A is the only roomy, quiet, flat site with a view.

## 2. Bamboo maze site: the far end of the tea field by the volcano

- **There's already a "Bamboo grove maze"**: JapanMap.TeaHills."Bamboo grove maze", a Model of 102 "Bamboo clump" Models (no other
  children). Each clump is about 33 parts: 13 "Bamboo lanceolate leaves", 3 "Solid bamboo culm", 9 "Bamboo twig", 8 "Bamboo node", all
  plain Parts. 3,506 parts in total. Bbox centre (5445, 9, -184), 127 x 43 x 173.
- The clumps stand in loose ROWS, not a real maze (see maze_from_above.jpg):
  - two long lines at x about 5425 and 5479, z -100..-280
  - a short cross row at z -275..-285 and another at z -190
  - a line at x about 5470 down the east edge
- **Flat ground:** x about 5375..5470, z about -330..-60. It's the part lawn, y 0.00 ("Japan land foundation basin cut", Grass).
  The terrain coast lip is at x 5360..5370 (1.8-2.0). East of x about 5470 the terrain rises into the tea rows / volcano foot: 3-6 at
  x 5470, 15-28 at x 5490..5560.
- **Borders:**
  - WEST: the sea cliff (JP_Island_Cliffs_West, the black faceted line in the pictures).
  - EAST: the tea rows on the rising slope (TeaHills tea bushes, at 5490+).
  - NORTH (z -330..-380): the slope up toward the volcano (2 -> 13 -> 23).
  - SOUTH: open lawn to z -60, where the Walkway (5530, -68) runs.
  - RIGHT THROUGH IT: "Volcano overlook" (5425, 7, -200), 37 x 14 x 242. It's the boardwalk / lookout ramp with its "Walkway" at 6.2 and
    a "Volcano lookout deck" at 10.0 around (5420..5425, -290..-305). In the pictures it's the long brown path.
- **What fits:** the flat strip is about 95 wide (x 5375..5470) and about 270 long (z -330..-60). A 110 x 110 maze doesn't fit
  the width as is. Options:
  - 95 x 110 at x 5375..5470, z -290..-180, if the overlook boardwalk is moved or the maze is built around it
  - 90 x 120 south of the boardwalk's turn
  - cut 15 into the slope on the east (terrain, ground 3-6 at x 5470..5485)
  The existing 102 clumps sit inside that strip, so they can be thinned, reused as maze walls, or retired.
- Pictures: maze_from_the_tea_field.jpg (from the tea rows looking west, the volcano behind), maze_from_above.jpg.

## 3. Palace koi pond

- In JapanMap.PalaceGrounds."Koi pond set piece":
  - "Vermilion moon bridge" (6322, 6.4, 22), 9 x 30 x 83: a long red arched bridge right across the middle, running north-south
  - "Koi fish", 8 small part koi (Koi 0..7, about 3 x 1 x 4) at y 4.1, i.e. ON the water surface
- **Water:** terrain Water with its surface at **3.9**. It's a round pond about 56 across: x about 6290..6354, z about -11..53
  (a circle, centre about (6322, 21)).
- **Depth:** 1.9 at the rim, -2 to -6 a ring in, -9 to -10.5 across the middle. Up to about 14 deep.
- **Shore:** JP_Koi_Pond_Shore (rebuilt today without the black vertex colours, Rock + JM_PhotographicRock), 97.4 x 2.85 x 96 at
  (6322, 3.22, 21.5): a rounded rock rim, top about 4.6, about 6-8 wide.
- **Where a player stands:** on the rim (about 3.0-3.5 terrain/part around it) or on the moon bridge (deck about 6-14 over the
  middle). The pond sits in a gravel court between two lawns in front of the palace.
- Pictures: pond_from_above.jpg, pond_from_the_edge.jpg.
- Note: the 8 old part koi float ON the surface (y 4.1, water 3.9). For feeding, the Meshy koi (kit koi_meshy) swimming 0.2 under,
  as in the canal, would match. The pond is deep enough.

## 4. The wardrobe (how French dresses and hats are worn and saved)

Sources as they are in the place today: wardrobe_sources/ (DressServer, DressClient, WardrobeClient, DressKit.Catalogue,
HatKit.Catalogue, Passport.Catalogue, plus Kits_tree.txt, DressShop_top.txt, Kimono_shops.txt).

- **Ownership and wearing are player ATTRIBUTES saved through the existing ledger.** Nothing here writes DataStores directly.
  - Owned: `Item_dress_<id>` > 0.
  - Worn: `Item_dresswear_<id>` > 0.
  - Changed only by firing `ReplicatedStorage.AwardItems` (BindableEvent, server) with ("dress_<id>", +1) or ("dresswear_<id>", ±n).
  - Purchase: `AwardAcorns` with a negative amount.
  - The ids are style + colour, e.g. "rue_Buttercup" (see DressKit.Catalogue `M.byId`, `M.order`).
- **Slots:** Catalogue `M.slots = {'dress','eyewear','necklace'}`, each with one worn Model on the character:
  `models = {dress='WornDress', eyewear='WornSunglasses', necklace='WornNecklace'}`. Wearing an item clears the other worn items
  of the same slot.
- **How an outfit is applied: NOT HumanoidDescription, Accessories or Shirts.**
  - `Cat.attach(kit, id, char, name)` clones MeshParts from ReplicatedStorage.DressKit (Bodice_/Skirt_/Hem_/Belt_/Collar_ + style
    mesh, and Seated* variants) into a Model on the character, coloured from the style's colours and welded with WeldConstraints to
    the body parts.
  - `cover(char,id)` hides covered body parts (Transparency 1, the old value kept in `BoutiqueWas_<slot>`), recolours skin
    (`BoutiqueSkinWas`) and blanks the character's Shirt/Pants templates (`DressClothingWas`).
  - `uncover` restores them.
  - DressServer re-dresses on CharacterAdded (+1.2 s), CharacterAppearanceLoaded, any `Item_dress*` attribute change and
    `SaveLoaded`.
- **Hats** have the same shape in ReplicatedStorage.HatKit (Hat_<style>, Band_<style> MeshParts + Catalogue), handled the same way.
- **The shop:** workspace.DressShop (attributes Spot/In/Out XYZ, InsideZoom, FadeSeconds, Price_<styleId>).
  - A Room interior (663 descendants) with a "Try on outfits & accessories" prompt on the mirror Glass and a "Go outside" door; a
    DoorPad "Go inside" outside.
  - Remotes `DressShopAction` (RemoteFunction: buy / wear / off / original) and `DressShopEvent` (fade / unfade / mirror).
  - Buying requires being within 14 of the Spot and `SaveLoaded`.
- **The Wardrobe** is the suitcase tab in the Passport (`WardrobeContent`, shown when the PlayerGui attribute `HasWardrobe` is true),
  listing owned dresses/hats to wear anywhere.
- **The kimono shops today:**
  - "Kimono shop" (6022, 12.2, -38), 35 x 24 x 26, 341 parts, and "Kimono atelier" (5978, 12.1, -65), 296 parts, both in
    JapanMap."Outdoor market revision".
  - They're decorative only: no prompts, no scripts, no mirror.
  - The shop has a kimono on a display mannequin (kimono_geom, torso_geom, arm_geoms), folded obi sashes, textile bolts, a garment
    rail and a wrapping counter. The atelier has hanging indigo fabric and shelves.
- **To plug the kimono in:** add kimono styles to DressKit.Catalogue (slot 'dress', kind 'outfit' or a new 'kimono' detail, with
  meshes Bodice_kimono / Skirt_kimono... in DressKit), a `Price_<styleId>` attribute, and a try-on point. Either a second DressShop-style
  mirror prompt at the Kimono shop (DressServer checks the distance to `Spot`, so a second spot needs a small server change), or one
  shared shop.
