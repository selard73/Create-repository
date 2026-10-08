# Area 51 Cartoon Props

## Mesh cactus (current version)

`gen_mesh.py` builds a smooth cactus mesh with a painted texture. This is the version that
matches the reference picture. Files it writes:

| File | What it is |
|---|---|
| `cactus.obj` + `cactus.mtl` | The mesh: Trunk, ArmL, ArmR, Ground, Rock1-3, Petals1-3, Core1-3 |
| `cactus_texture.png` | 1024x1024 texture atlas. Repaint it in any image editor. |
| `preview3d.html` | 3D preview. Serve the folder (`python -m http.server 8765`) and open it. |

### Import into Studio

1. Open a place. On the **Home** tab click **Import 3D** (also under Avatar > Import 3D).
2. Choose `cactus.obj`. Keep `cactus.mtl` and `cactus_texture.png` in the same folder; Studio reads the texture through the .mtl.
3. In the import window leave Scale Unit as Studs. Tick **Upload to Roblox** if asked about the texture. Click **Import**.
4. Studio creates a Model containing one MeshPart per object, all textured. Tick Anchored in the import window.
   Then select the model and paste `cactus_setup.lua` into the command bar: the ridge lines become glowing
   Neon fading toward the bottom, a green light sits in the trunk, and the faint green aura returns.
5. Share the model exactly like before: right-click it > Save to Roblox (Creator Store) or Save to File.

### Repainting the texture yourself

Open `cactus_texture.png` in Paint.NET, Photoshop, GIMP, Krita, or similar. The atlas is laid out as:

```
top-left     512x512  trunk       (top of picture = top of cactus; the bright lines are the ridges)
top-right    512x512  ground      (red clay)
middle       full width, 256 tall: left half = left arm, right half = right arm (tip at the top)
bottom row   white flower | pink/yellow flower | red center (small) | rock
```

Save it with the same name and re-import, or in Studio select a MeshPart, click its TextureID property and upload the new PNG.

### Getting the glow

The lines are painted, so they need bloom to actually shine. In Studio select Lighting: set ClockTime to about 19, Technology to Future, and add a BloomEffect (Intensity 0.8, Size 32, Threshold 0.75). The bright ridge lines and white petals will bloom; the olive body will not.

## Area 51 neon sign

`gen_sign.py` builds `area51_sign.obj` + `.mtl`, `area51_sign_texture.png`, `sign_neon_setup.lua`
and `preview_sign.html`. The board, posts, and every neon tube are separate objects so the tubes
can be real Roblox Neon.

1. Home tab > **Import 3D** > `area51_sign.obj`. In the import window leave **Merge Meshes off**
   so the neon pieces stay separate. Import.
2. Click the new model in Explorer so it is selected.
3. View tab > **Command Bar**. Open `sign_neon_setup.lua` in Notepad, copy all of it, paste into the
   command bar, press Enter. It switches every `Neon*` piece to Neon with the right color, makes the
   `*Haze` slabs a soft transparent glow, anchors everything, adds pink and cyan PointLights, and
   sets Lighting to dusk with bloom so the neon shines. Nothing else to configure.

Letters are solid extruded glyphs cut from Segoe UI Black with rounded corners (`FONT` and `TEXT`
at the top of `gen_sign.py`). Change `TEXT` and rerun to make a different sign.

Pieces are named by color so you can recolor them yourself: `NeonPink_Outline`, `NeonIce_Letter1..N`
(one per letter), `NeonCyan_SaucerRim`, `NeonPink_SaucerBand`, `NeonWhite_Dome`, `NeonYellow_Window1-3`,
`NeonPink_UfoLight1/3`, `NeonYellow_UfoLight2`, `NeonPink_ZipL1..R2` (motion arcs). Select any and change Color.
The script also creates two transparent Neon glow slabs, `TextGlow` and `PinkWash`; delete them if you prefer a cleaner look.

## Satellite dish bunker

`gen_dish.py` builds `dish.obj` + `.mtl`, `dish_texture.png`, `dish_setup.lua`, `preview_dish.html`.
Old reddish rusty metal throughout, with grey steel trims. Import with Home > Import (Import 3D),
select the model, paste `dish_setup.lua` into the command bar: the door, control lights and the
feed tip become Neon and get lights. Pieces: `Bunker`, `Dish`, `DishRim`, `Mast`, `NeonLime_Door`,
`NeonGreen_FeedTip`, `NeonOrange/Green/Cyan_Light*`. Rust colours live in `rust()` in the script.

## UFO with tractor beam and landing pad

`gen_ufo.py` builds `ufo.obj` + `.mtl`, `ufo_texture.png`, `ufo_setup.lua`, `preview_ufo.html`.
Import with Home > Import (tick Anchored), select the model, paste `ufo_setup.lua` into the command
bar, Enter. The script sets matte metal, glass dome, glowing green beam, blinking lamps with lights,
and adds three scripts inside the model: `LampBlinker`, `UfoHover` (bob + slow spin) and
`TractorBeam`. The beam idles off; when a player or an unanchored object is on the pad's green circle it
powers up (click + machinery wind-up, generator rumble loop, beeping), fades in with its sparkles and light,
lifts what is there, and winds down when the circle is empty. All three scripts only run in Run/Play.
Sounds are built-in Roblox clips on the `Beam` part (`BeamClick`, `BeamStart`, `BeamHum`, `BeamBeep`,
`BeamStop`); swap any SoundId for a Toolbox audio id for a fancier clip.

## Martian environment: rocks, scatter, ground and sky

`gen_rocks.py` builds six standalone props that share `rocks_texture.png`: `rock_mesa.obj`,
`rock_spire.obj`, `rock_boulders.obj`, `rock_ledge.obj`, `barrel_cactus.obj`, `pebbles.obj`.
Import each with Home > Import (tick Anchored); no setup script needed. Scale them freely with the
Scale tool. `mars_environment.lua` (paste into the command bar once) recolours every terrain
material to rust reds, turns the Baseplate into red sand, and warms the sky and light while keeping
daytime. Paint hills with the Terrain Editor afterwards and they come out red.

## Tube light fixture

`gen_tube_light.py [length] [suffix]` builds `tube_light.obj` (6 studs by default): a capsule glass tube
with rounded ends, dark end caps and brackets, on a rusty wall plate (wall side is -Z). Import with
Anchored ticked, select it, paste `tube_light_setup.lua`: the tube becomes translucent Neon with a
soft SurfaceLight + PointLight. `LIGHT_COLOR` and an optional `FLICKER` flag sit at the top of the
script. Rotate the model 90 degrees for a vertical mount.

## Old hound dog

`gen_hound.py` builds `hound.obj`, `hound_texture.png`, `hound_setup.lua`, `preview_hound.html`: a cartoon
classic hound standing (faces +X, about 5 studs tall). Built from blended smooth surfaces (signed distance
fields + marching cubes, needs numpy + scikit-image): HoundBody, HoundHead, HoundTail plus eyes, nose, tongue,
collar. Coat is painted as a side view in `hound_texture.png`. Import with Anchored ticked, select it, paste
`hound_setup.lua`: matte fur, glossy nose and eyes, and a `HoundIdle` script that breathes, wags the tail,
looks around and lifts his head to howl every 12-25 s while the game runs. Everything moves relative to
the `HoundBody` part, so move or rotate the model freely.

## Parts cactus (older version)

Props for a cute, cartoony Area 51 scene in Roblox. Each prop is generated as a
`.rbxmx` model file by `gen_props.py`.

## Files

| File | What it is |
|---|---|
| `gen_props.py` | Builds every prop in the `PROPS` list into its own `.rbxmx` |
| `Cactus.rbxmx` | The cactus model, ready for Studio |
| `preview.py` | Makes a flat front-view `.svg` of a model to sanity-check proportions |

Regenerate after editing:

```bash
python gen_props.py
```

## Put a prop in Roblox Studio

1. Open Roblox Studio and open any place (a Baseplate is fine).
2. In the Explorer panel, right-click **Workspace** and choose **Insert from File...**
3. Pick `Cactus.rbxmx`. The model appears at the origin, resting on Y = 0.
4. Move it with the Move tool. Everything is anchored, so it stays put.

## Share it, option A: Creator Store (anyone can insert it from the Toolbox)

1. In Explorer, right-click the **Cactus** model and choose **Save to Roblox...**
2. Fill in Name and Description. Pick a genre if asked.
3. Tick **Distribute on Creator Store**. Roblox needs your account to be
   ID- or phone-verified for public distribution. If the box is greyed out,
   verify at roblox.com > Settings > Account Info, then try again.
4. Click **Submit**. Moderation usually takes a few minutes for plain parts.
5. Share the link from create.roblox.com > Creator Store > your model, or send
   the asset ID. Friends find it in Studio under Toolbox > Creator Store.

## Share it, option B: send the file

1. In Explorer, right-click the **Cactus** model and choose **Save to File...**
2. Save as `Cactus.rbxm` (Roblox binary) and send that file.
3. The receiver uses Workspace > **Insert from File...** exactly like step 2 above.

You can also send the `.rbxmx` straight from this folder. Studio opens both formats.

## Getting the glow to show

The cactus uses Neon parts, a Highlight outline, and PointLights. They only glow properly when:

- **Lighting > Technology** is `Future` or `ShadowMap` (select Lighting in Explorer, check Properties).
- Lighting has a **Bloom** child. New baseplates include one; if not, right-click Lighting > Insert Object > BloomEffect (Intensity 0.6, Size 24, Threshold 0.9 is a good start).
- The scene is dusk or night. Set **Lighting > ClockTime** to about 19.5 for a sunset like the reference. Neon barely shows at noon.

## Tweaking

- Colors live at the top of `gen_props.py` in the "Cartoon palette" block.
- `cactus(show_face=True)` adds a face. `cactus(show_flowers=False)` removes the flowers. `cactus(glow=False)` turns everything back to plain matte parts.
- Sizes are in studs. A Roblox character is about 5 studs tall; the cactus is about 11.
