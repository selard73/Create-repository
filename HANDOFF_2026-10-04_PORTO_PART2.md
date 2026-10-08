# Handoff: Porto Nocciola, part 2 (Oct 4 2026, ~12:40)

**Starter prompt for the new chat:**
> Read C:\Users\slard\roblox-props\HANDOFF_2026-10-04_PORTO_PART2.md and continue adding Italian squirrels and details to 1001 Squirrels the same way. Ask me before every Studio edit (fixes of something I just flagged: just do them and show me).

## Where things stand
- **Live: v1005** (published Oct 4 12:36 EDT). Nothing unpublished.
- Porto Nocciola has **11 squirrels**, registry total **55** (44 French + 11 porto). Registry order: Timbro, Beppe, Gino, Nonno Reti, Giulia, Vito, Signora Chiave, Penny, Tito, Capitano Remo, Sandro (each new entry is inserted after the previous one's last bio words).

| id | name | spot |
|---|---|---|
| boatpainter_squirrel | Vito the Boat Painter | on the EAST oak barrel in the boatyard (lid 274.8,-44.64,-695.0), facing the Nuova Alba's hull |
| realtor_squirrel | Signora Chiave | LEFT (south) of Casa Salvia's door (296.9,-46.8,-679.0), face + purse toward the street |
| italytourist_squirrel | Penny the Tourist | causeway NORTH end (309.1,-46.8,-721.0), facing west over the beach; plain sunglasses (lens texels repainted) |
| tightrope_squirrel | Tito the Tightrope Walker | standing foot on the MIDDLE clothesline (z -651, x 287.9) in the Azzurra/Rosa alley, facing west along the rope |
| seacaptain_squirrel | Capitano Remo | on the Azzurra (boat out on the water) deck forward of the cabin (202.76,-52.53,-668.69), facing town |
| sunbather_squirrel | Sandro the Sunbather | beach (278.23,-48.13,-727.64), facing SSW to the water |

- **Natural tide pools** by the sandy cove replaced Codex's ring basins (backups: ServerStorage.TidePoolBackup.OldRingPools / Round2 / terrain copies). Mesh shelf + pools + water from `roblox-props/italy/tidepools` (gen_tidepools.py, make_place_lua.py, swap_template.lua, obj2fbx.py). Folder: PortoNocciola['14 Lighthouse coast']['Cala della Sabbia and tide pools']['Natural tide pools'] (TidePoolShelf, TidePoolWater [CanQuery on, no collision], Sea life). Shannon removed my parts-built crab; she liked the rest.
- **Wading + crabs**: LocalScript `StarterPlayer.StarterPlayerScripts.TidePoolLife` (source `italy/tidepools/TidePoolLife.client.lua`): within 140 studs of the cove, 4 client-side crabs (template `ReplicatedStorage.TidePoolCrab`, rig `italy/crab/rig_crab.py`: Root, LegsLF/LB/RF/RB, ClawL/R) scuttle sideways; in a pool you slow to 0.75x, ripples, droplets, splash sound.
- Meshy prompts were given for a **crab catcher** (grizzled adult, grey rubber bib overalls, square crab trap) - she has not sent the model yet.

## Pipeline (works - see the first handoff HANDOFF_2026-10-04_PORTO_SQUIRRELS.md for details)
1. Unzip Meshy zip to `squirrels/<id>/src/` (CHECK the id is free first - `tourist_squirrel` and `painter_squirrel` are French; I once prepped into Dale's folder by mistake).
2. `prep_squirrel.py ... 7000 2.4 0` -> look at ref_front -> `run_rig_batch.py <id>` or `rig_squirrel.py` with overrides `<tail_xmax> [body_x] [head_zmax] [tail_zmax] [head_ymax] [head_zmin]` for off-centre/upright heads -> audit -> `fix_weights.py` (head_zcut ~ neck start; region boxes for props near the head; NOTE it saves over `_rigged.blend`, restore from `.blend1` before re-running) -> `render_turned_view.py` -> `feet_probe.py`.
3. Studio: Import Queue folder icon -> FBX (color + gray). Installer as .rbxmx PatchModule (File > Import Roblox Model), runner typed in <=15-char chunks, Run, read `warn` tags from `%LOCALAPPDATA%\Roblox\logs\*Studio*_last.log`.
4. Facing: use the mesh's own forward axis `R*(0,0,-sz)` (install_captain/tightrope/sunbather.lua), NOT the head-bone offset; `sx = 1` always (the old tail-side mirror guess is wrong for tails on +x).
5. Name + bio: offer 3-5 short options; she picks. She likes a gentle twist about the place itself (Remo: steers by the smell of the bakery; Sandro: Porto Nocciola is a very calm harbour); tourists follow Dale's pattern (species, hometown, how they came, outfit, one mix-up).
6. Show one view; publish only on her word (click 3D view, Alt+P, confirm "Published new changes" + version in the log).

## Gotchas learned today
- "Where my character is standing": in a Studio play test read `game.Players.LocalPlayer.Character.HumanoidRootPart` in the command bar (Client tab), then STOP the test before editing (edits in a test are not kept).
- Studio window is now smaller: File (134,88), Import Roblox Model (185,216), Import 3D (158,198), file-name box (550,437), command bar (700,716), Run (1368,716), Import Queue folder (137,565), Play (207,110), Stop (266,110). ALWAYS zoom-check that the menu/dialog opened before typing a path (twice the keys went into the 3D view; verify with `ChangeHistoryService:GetCanUndo()` name).
- computer-use `type` over 15 chars goes through the CLIPBOARD (overwrites hers). Keep chunks <=15.
- If Edge/Snipping Tool/desktop is "frontmost", click Studio's title bar (700,8) (File Explorer + Snipping Tool click grants exist); Edge needs her to click Studio.
- Import Queue silently ignores .obj -> convert to FBX in Blender (`italy/tidepools/obj2fbx.py`).
- Roblox lights textures far brighter than Blender (darken baked textures ~20%).
- Terrain voxels are 4 studs: no small pools; raycasts right after terrain edits are stale (use ReadVoxels).
- Auto-mode classifier once blocked an installer run; Shannon said I have permission.
- Stop at 70% weekly usage (rest is for Ethan).
