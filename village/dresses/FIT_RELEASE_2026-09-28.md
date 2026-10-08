# Boutique fit and first collection — 2026-09-28

Saved to Roblox as an unpublished draft at 12:25:44 UTC. No live publish performed.

Current clothing designs: Petal party (`jardin`), Golden acorn gown (`soiree`), Acorn adventurer (`adventurer`), Moonlit magician (`moonmagician`). Three colorways each; existing sunglasses and necklaces remain offered. There are 24 available product IDs. All 48 historical definitions/ownership IDs are retained. `Catalogue.lua`'s `M.release` controls clothing availability; the server rejects unavailable purchases, while older owned styles remain wearable. Shop mannequins and window displays reflect the current collection.

Fit changes: a fuller jacket shoulder mesh plus rounded sleeve caps; one continuous flower skirt with a surface-aligned garland; separate seated skirt/hem meshes activated by Humanoid.Sit, with the standing shape restored when rising. Seated skirts cover the lap and boutique pouf. Original body/clothing restoration is preserved. Simplified the golden gown trim to avoid floating rigid strips when seated.

Validation in Studio's iPhone 7 landscape emulator: both launch dresses sitting in the actual PoufSeat and returning to standing; front/side/rear inspection of the flower dress; both launch trouser outfits' shoulders; 288 walk/run/jump animation frames across the four clothing styles with covered-body checks; original clothing/body restoration; 24 product previews; unavailable purchase rejected; exact installed/source equality; four clothing designs across six mannequins/window displays. All temporary QA scripts removed before saving. Live player data APIs stayed disabled. This does not establish fit for every Roblox avatar bundle or every chair shape.

Geometry: original 15 meshes plus seven in `BoutiqueFit.obj`. `gen_fit_kit.py` generates the additional meshes and merges their metadata into `dress_kit.json`; run it after `gen_dress_kit.py` if rebuilding all geometry. Then run `prepare.py` to regenerate `DressCatalogue.lua`, `build_dressshop.lua`, and `run_install.lua`. Import both mesh sets before a fresh shop build. `assets.json` includes the uploaded mesh IDs.

Pre-change sources backed up in `backups/codex_20260928_boutique_fit_release`.
