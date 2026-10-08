# Mode et Style — dress shop review draft

September 27, 2026. The approved Passport/HUD update is live as Roblox version 618. This boutique is a separate, unpublished Studio draft, saved to Roblox on September 27 at 9:23 PM EDT.

Enter **MODE ET STYLE** on the Rue, then use the mirror. The flow follows the hat shop: tap a color to try it on, buy with acorns, wear an owned dress again for free, or take it off to restore the original outfit.

| Collection | Colors | Draft price |
|---|---|---:|
| Rue sundress | Buttercup, Rose, Pine | 60 acorns |
| Cafe day dress | Rust, Blueberry, Honey | 90 acorns |
| Chateau evening | Midnight, Burgundy, Ivory | 140 acorns |

The interior includes dress displays, fabric swatches, a gold mirror, wood floors, rust rugs, ribbon spools and warm lighting. The cream-and-gold phone panel leaves the avatar visible beside it; the existing HUD returns when the mirror closes.

## Checked

- Studio iPhone 7 landscape layout, scrolling, selection, purchase, take-off and closing the mirror.
- Server rejection of purchases away from the boutique, invalid items, insufficient acorns and unowned outfits.
- Correct charge, ownership, duplicate-purchase protection, and free re-equipping.
- Original shirt, pants and body visibility restored after taking the dress off.
- Equipped dress restored after respawn.
- All nine variants attach safely; R6 attachment structure checked using a test torso. Full animated R6 and unusual avatar packages still need visual checks.
- Studio API access remained off. No live player saves were changed. Cross-session saving uses the existing item ledger; it has not been tested against live data.

## Before publishing the boutique

Review the silhouettes, palette and prices. The shorter skirts still show occasional knee clipping on the test avatar during idle animation; their fit needs another pass before release. These are rigid mesh garments, so unusual body proportions and animations need additional fitting checks. Classic clothing textures, including shoes drawn onto classic pants, are hidden while a dress is worn; separate shoe accessories remain.

## Development handoff

Sources and original meshes are in `C:\Users\slard\roblox-props\village\dresses`. `prepare.py` generates the isolated builder and `run_install.lua`. In Studio Edit mode, the runner rebuilds only `Workspace.DressShop` and its catalogue, using `ReplicatedStorage.DressKit`; it does not rebuild the Rue or HatShop. The imported mesh identifiers are recorded in `assets.json`.

The room uses the existing SkyRoom hiding system. Purchases use AwardAcorns/AwardItems with `dress_*` ownership and `dresswear_*` equipment keys. No additional DataStore was introduced. `qa_server.lua`, `qa_respawn.lua`, and `qa_visual_setup.lua` are Studio Play-server tests only; their temporary acorns and gate bypass are never installed in the published scripts.

The original handoff's instruction to enable Studio API access for publishing is unnecessary: version 618 published successfully with access off. Keep it off during testing.

