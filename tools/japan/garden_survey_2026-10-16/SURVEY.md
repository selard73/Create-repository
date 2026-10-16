# Garden site survey (runner 7, Oct 16 2026, Studio EDIT, read-only)

Centre (6100, -215), radius 70. Pictures in this folder.

## 1. The canal
- It runs along +z. The water is between the stone banks at x 6086 and x 6116 (LanternStreet."Canal stone bank" x 2, at x 6086 / 6116,
  y 1.1, 5 x 2 x 326, centred z -60). Water Bank walking supports: "Shallow river bank" x 2 at x 6084 / 6118, and underwater shore
  ramps at x 6090 / 6112.
- Terrain water surface: y 1.3 (y 0.8 at z -218, where it ends).
- Bed: -2.8 at z -210, -6.0 at -200, -10.0 at -180, and about -10.2 from -150 on north.
- Its END is the weir at z -221..-224: Canal weir."Weir" (6101, -0.6, -222) 34 x 5 x 3, "Weir lip" (6101, 2.3, -221) 34 x 1 x 1, six
  "Weir stone" caps at y 2.5, x 6088..6114.
- Beyond the weir: "River end foundation closure" (6101, -1.7, -226) 32 x 4 x 10 (Plastic, top 0.3), then flat ground.
- Water Bank walking supports."Continuous shallow river exit" (6101, -1.9, -212) 32 x 0 x 33.

## 2. The red bridge (the one at the canal's end)
- LanternStreet."Canal footbridge" (there are three with the same name; the others are at z -75 and z 80). This one: box centre
  (6100.9, 7.3, -215), 38.3 long across the canal (x 6082..6120), 9 wide, 5.1 tall. Pivot faces -X.
- 120 parts, 0 meshes. Wood x 100 at (179, 54, 31) vermilion: "Curved vermilion handrail" 40, "Bridge lower rail" 40, "Bridge post" 20.
  WoodPlanks x 20 at (103, 72, 48): "Bridge deck" 20.
- Deck top: 6.1..6.7 over the water, 4.8 / 5.2 at its ends.
- LanternStreet."Northern bridge approach steps" (6101, 2.6, -215) 59 x 5.2 x 9, 16 parts, white (255, 255, 255). "Bridge stone
  approach tread" is Rock.
- The walkway that crosses it: LanternStreet."Walkway" (Pavement) at z -215, y 1.0..2.0, from x 6030 to about 6140.

## 3. Things within 70 (JapanMap, 2-3 levels deep)
- LanternStreet:
  - "Canal footbridge" (above)
  - "Northern bridge approach steps"
  - "Walkway" (6131, 1.0, -215) 9 x 18, and (6039, 1.0, -215) 9 x 78
  - two standing paper lanterns at x 6078..6080, z -205 and z -169. Each is about 15 parts: "Lantern post", "Lantern plinth",
    "Lantern arm", "Pleated paper lantern", "Black lantern cap" x 2, and many "Paper rib".
- Blender maple and blossom groves, "Vermilion maple - individual Blender leaves" (each 1 part, plus a "Solid branching trunk"):
  - (6125, 7, -205) 19 x 14 x 19
  - (6125, 7.1, -169) 20 x 14 x 20
  - (6160, 11.6, -204) 32 x 24 x 32
  - (6080, 10.9, -294) 30 x 22 x 30
  - (6170, 9.7, -260) 27 x 20 x 27
- Outdoor market revision."Rice and provisions" (6022, 6.6, -194) 27 x 15 x 26, 137 parts: the market starts about 80 west.
- Canal weir and Water bank walking supports (above).
- Big ground parts, under everything: Water basin collision supports."Japan land foundation basin cut", 306 x 24 x 4 slabs at
  y -12 (top 0.0), x 5779..6085.
- No prompts, seats, train track or squirrels within 70. The railway and the market are farther out.

## 4. Ground on a 10-stud grid (first hit from above; y, then a surface code)
```
   z\x   6030   6040   6050   6060   6070   6080   6090   6100   6110   6120   6130   6140   6150   6160   6170
  -285       .      .      .      .      .      .      .   0.0A      .      .      .      .      .      .      .
  -275       .      .      .      .   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A      .      .      .      .
  -265       .      .      .   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A      .      .      .
  -255       .      .   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A      .      .
  -245       .   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A      .
  -235       .   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A   0.0A      .
  -225       .   0.0A   0.0A   0.0A   0.0A   0.0A   0.3B   0.3B   0.3B   0.0A   0.0A   0.0A   0.0A   0.0A      .
  -215    1.0C   1.3C   1.5C   1.8C   2.0C   4.8D   6.1E   6.7E   6.3E   5.2E   2.6D   0.3C   0.0A   0.0A   0.0A
  -205       .   0.0A   0.0A   0.0A   0.0A   0.0A   0.8F   1.3F   0.8F   0.0A   0.0A   0.0A   0.0A   9.9G      .
  -195       .   0.0A   0.0A   0.0A   0.0A   0.0A   0.8F   1.3F   0.8F   0.0A   0.0A   0.0A   0.0A   0.0A      .
  -185       .   0.0A   0.0A   0.0A   0.0A   0.0A   0.8F   1.3F   0.8F   0.0A   0.0A   0.0A   0.0A   0.0A      .
  -175       .      .   0.0A   0.0A   0.0A   0.0A   0.8F   1.3F   0.8F   0.0A   0.0A   0.0A   0.0A      .      .
  -165       .      .      .   0.0A   0.0A   0.0A   0.8F   1.3F   0.8F   0.0A   0.0A   0.0A      .      .      .
  -155       .      .      .      .   0.0A   0.0A   0.8F   1.3F   0.8F   0.0A   0.0A      .      .      .      .
  -145       .      .      .      .      .      .      .   1.3F      .      .      .      .      .      .      .
```
Legend:
- A = "Japan land foundation basin cut" (Grass material, a PART)
- B = "River end foundation closure" (Plastic)
- C = "Walkway" (Pavement)
- D = "Bridge stone approach tread" (Rock)
- E = "Bridge deck" (WoodPlanks)
- F = terrain Water
- G = a maple trunk

## 5. Open space
- The ground around the canal is one dead-flat green part floor at y 0.0. It is "Japan land foundation basin cut", Grass material,
  not terrain. That is why it reads as a flat lawn (see the pictures).
- Clear and flat: the whole lawn PAST THE WEIR, x about 6040..6160, z -230..-285 (about 120 x 55; only the maple at (6170, -260)
  near its corner). That is where a waterfall head can feed the canal's end, with a gravel bed beside it.
- Also clear: both sides of the canal, x 6040..6080 and x 6125..6160, z -150..-210 (40 x 60 each). The maples at (6125, -205),
  (6125, -169) and (6160, -204) are there.

## 6. Pictures
- g1_bridge_eye_level_from_canal: from the water's middle, looking at the bridge, with Fuji behind.
- g2_from_above
- g3_from_minus_x_minus_z (past the weir, from the west)
- g4_from_plus_x_minus_z (past the weir, from the east)
- style_rue_de_noisette (France, for the style match)

What reads poorly by eye:
- The flat green lawn: no ground variation, no planting.
- The white approach steps and the grey concrete-like weir box.
- The canal is a straight concrete channel.
- The bridge is fine in colour, but its rails are thin parts.
- The maples are flat red-leaf discs on black trunks.
