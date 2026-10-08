# Handoff: 1001 Squirrels, Oct 8 2026 afternoon -> next chat

**Starter prompt for the new chat:**
> Read C:\Users\slard\roblox-props\HANDOFF_2026-10-08_NEXT.md and continue 1001 Squirrels: first make the trees and mountainsides solid so you cannot walk through them. Check weekly usage first (stop at 70%). Use the Roblox_Studio MCP tools. Ask before new Studio edits (flagged fixes: just do + show). Never launch Studio; publishing is my Alt+P.

Detail of everything built on Oct 7-8: HANDOFF_2026-10-08_GATES.md (gates, walls, map v2, railings, notes, lemons, music, rocks, Belvedere end, lessons). Report page: https://claude.ai/artifact/Qop2N4FErNU43z3AbWrTSv (source italy/gates/page/porto_gates.html).

## Rules (unchanged)
- Ask before every NEW Studio edit; fixes of something she flagged: do + show. Publish only on her word; she presses Alt+P. Never write her DataStores; API access stays OFF in play tests (the log shows "StudioAccessToApisNotAllowed").
- Phone UI: nothing may overlap, ever - measure rects in her Device Simulator (666x374) via a play test before publishing.
- Railings solid, never invisible blockers on them (memory railings-solid-no-blocks). Grotta Azzurra (450,-51,-1110) reserved.
- Studio: studio_id changes when she reopens Studio (call list_roblox_studios). screen_capture that times out leaves the editor camera moved - restore hers: CFrame.new(554.400024, 5.5999999, -1102, 1,0,0, 0,0.658503056,0.75257802, 0,-0.75257802,0.658503056).
- require() of SquirrelRegistry from execute_luau can be a stale cached copy: require a fresh ModuleScript clone of its Source.
- Lua long strings: use [==[ ]==] when the text can contain "]]" (t[a[b]] broke a [[ ]] string once).

## State: everything below is in Studio, NOT published (Studio PlaceVersion read 1197 this morning)
Gates + walls (7 gates, 2 wall lines, note card on screen, safety net), map v2, all Porto railings + windmill gallery railing solid, Chef Nutmeg moved, coming-soon wall gone, floating coastal rocks attached to cliffs, Belvedere track end finished, lemons (8 acorns at the Lemon Seller, badge on the purse, saved via AwardItems "lemon"), Porto music: harbour 1839408249 / Via della Piazza "88626279253226,106835352549879" (Camminata Mattutina then The Piattino and the Coin, a loop) / The Groves 136760872157595, quiet bands 9 studs round each gate, Italy find sound = bell chime 9116394876 (vol 2.2).
- workspace.PortoGates.StudioFreshPorto = true (Studio-only: owner test starts with France found, Porto not; untick for the 88/88 preview). Enabled = kill switch for gates/walls.

## NEXT 1 (her ask, Oct 8): "a lot of the trees and mountain sides you can walk through, can you make sure everything is solid so you cannot walk through it?"
Suggested approach:
1. Survey (read-only) BaseParts with CanCollide = false in workspace.PortoNocciola (and the France maps if she means everywhere - ask once), grouped by name/model: tree trunks / foliage / crowns, rock and cliff MeshParts (e.g. "Hillside" rocks, "Layered coastal rock" are Parts and already solid?), the SouthGorge rock (gorge built with CanCollide false on purpose for the boat ride - the boat runs down the gorge; keep the water channel clear), kit trees (ForestKit/DomaineKit clones placed by scripts with CanCollide false), Groves trees.
2. Rules: trunks solid (CanCollide true, CollisionFidelity Hull or Box - not PreciseConvexDecomposition on hundreds of meshes), leaves/canopies NOT solid (players snag and stand on them) unless she says so; rock/cliff meshes solid with Default/Hull fidelity (PreciseConvexDecomposition only for big walkable ones); never make solid: decorative small props in walkways, water/foam/mist, squirrels, signs over paths.
3. Before switching: check nothing solid would block a path or stair (the walkway probe used for the railings: rays down onto route floor parts; and boxes of each candidate vs the route parts), and that the boat ride / funicular / glider routes stay clear.
4. Mark each switched part with an attribute (e.g. SolidOct8) so it can be undone; play-test walking into a tree and a cliff on the phone sim; capture.

## NEXT 2: The Groves squirrels spread - waiting for her go on the proposal (page top): move Olive Picker -> (655,48,-880) olive terrace; Butterfly Catcher -> (632,36,-930) lower lemon terrace (her butterflies follow via CentreLocal; update the folder's Rest attr); Photographer -> (730,90,-880) hilltop; Guitarist -> (575,12,-1024) foot of the Torre di Guardia; Treasure Hunter -> (645,16,-980) grassy strip by the east point. Move like the installers (feet seating with the spread score, facing via the Tail2 bone, keep NoHeadAnim), registry unchanged.

## NEXT 3: publish (her Alt+P) after her look; then verify PlaceVersion / "Published" in the Output.

## Later ideas from her: perfume making in France with the lemons (no system yet); sea shell / glass craft game; octopus + captured squirrels story in the Grotta Azzurra.
