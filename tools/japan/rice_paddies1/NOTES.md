# Rice paddies grounded1 — installed, saved to Roblox, awaiting Shannon's publication

Shannon explicitly authorized overnight repairs on Oct 17, 2026. Preserve field dimensions, water and rice plants. Her authorization covered installation after self-reviewed Play tests; no additional approval requested. Solo work.

## Cause and repair
- Original JP_Rice_Berm_1..3 were open thin ribbons with baked RGB vertex tints ~0.149–0.290. White Part.Color could not remove that multiplication. The material itself was valid.
- Original banks span worldY1.15–2.05; lawn top is approximately-.04 and central water level2.25. They floated above the ground and sat below the water.
- Reconstructed the same X/Z outlines,59x52 each, from original mesh geometry. Welded seven FBX seam pairs (offset.0105–.0132), closed the underside, recomputed normals and removed vertex tint. Ground toeY-.20, crownY2.85, new bounding centerY1.325/height3.05.
- Kept JM_PhotographicEarth and white Color. Persistent asset125379819144461 has1680 triangles; imported UV/normal splits give1696 vertices, all1696 stored colors are white.
- Changed792 existing Rock solid-material cells to Mud inside the three paddy footprints. Did not change any solid or liquid occupancy. Compared all2880 bounded-region cells, including exact liquid equality. Water appearance and all3 center heights2.25 retained.
- Whole-ring PreciseConvexDecomposition created invisible surfaces over water. Rejected that collision. Built12 closed sections per bank,36 invisible real MeshParts total, with precise collision. Render banks remain noncollidable and nonqueryable.
- FBX importer flips X/Z. Measured imported section centers are the negatives of source centerX/Z; installer accounts for this. An initial collision placement exposed6 missed crown rays; corrected before installation.

## Installed locations
- Render banks: workspace.JapanMap.BlenderScenery[\"Sculpted terrain\"].JP_Rice_Berm_1..3
- Collision model: workspace.JapanMap.RiceBankCollision1,36 invisible anchored MeshParts.
- Version: Sculpted terrain.RicePaddiesRepairVersion = grounded1.
- Sources: ServerStorage.JapanGardenKit.rice_bank_grounded1 and rice_bank_collision1;13 anchored source meshes.
- Originals: ServerStorage.HudBackup.RicePaddies_pre_grounded1;3 original MeshParts and3 TerrainRegions with PasteCorner attributes.
- Bank centersX5496/5556/5616,Z83. Only bank elevation/profile changes; original plan dimensions/positions retained.
- Blender source files remain in the local work/rice_paddies1 folder; generators, original geometry and both FBXs are tracked here.

## Validation
- Three render meshes plus36 collision pieces exactly match the accepted self-reviewed39-part Play manifest.
- Both final preview and fresh saved-scene Play:360 crown rays hit;75 interior-opening rays clear. Server crown range2.8498125–2.85; client2.8498912–2.85.
- Actual client walking climbed from lawn onto the eastern bank, then followed its crown. Ground hits2.6970 and2.8410; Humanoid Running, within1.1 studs of both goals.
- All client collision assets loaded successfully.
-315 rice-seedling parts and18258 other Japan BaseParts checked unchanged, including transforms, sizes, appearance and physical flags; boats, paths, lawn and unrelated shops retained.
- Blender bank and12 collision sections are closed manifold meshes with positive volume. Render bank840 welded vertices/1680 triangles before import; collision sections77 vertices/150 triangles each.
- Actual Play close, low edge and overview inspected; no visible under-bank water or exposed gray rock strips. Final installed close and overview saved in shots.
- Temporary camera/HUD/avatar overrides removed and Studio stopped.
- Used Studio File > Save to Roblox, not Publish. Log03:23:16 UTC Oct18 confirms StudioSavePlaceToCloud and \"Saved new changes in 1001 Squirrels to Roblox.\" Internal publish-state labels also occur during this save; CreatorOutput confirms save operation. Shannon publishes.

## Reproduction and rollback
- build_bank.py reads original_bank_mesh.json and produces the repaired bank.
- build_collision.py reads repaired_bank_mesh.json and produces12 collision sections.
- Standard Studio FBX importer used after direct asset API reported unavailable. Meshes anchored and moved to ServerStorage before Play. No API/security settings changed.
- install.lua is guarded and one-shot. Do not rerun on installed scene.
- rollback.lua requires explicit RICE_PADDIES1_ALLOW_ROLLBACK and restores only this repair from the six saved originals.
- No game publication, direct DataStore write or unrelated preview installation. Other pending shop/maze work retains its own approval requirements.
