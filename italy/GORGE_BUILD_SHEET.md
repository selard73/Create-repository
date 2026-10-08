# South gorge + south edge: build sheet (Sep 30 2026)

**SHANNON'S PICKS (Sep 30 ~12:35):**
- Cliffs: cream layered sandstone like the Sandstone Climb, with pines and cypress on top.
- Landmark: yes, an old stone aqueduct arch over the gorge.
- Trip start: a "Sail to Italy?" card (Yes / Not yet) at the rim.
- Haze: NO. Keep today's lighting; the ridge alone hides the edge.

Nothing here is built yet. Survey data: `tools/italy_survey1_out.txt`, `tools/gorge_probe1_out.txt`.
Pictures: `italy/gorge_sketch.png`, `italy/placement_plan.png`, plus two Studio views of today's south edge.

## What is there today (measured, read-only)
- The village's invisible rim wall is at z -205. Low green terrain mounds (8-14 studs high) run just outside it.
- The river is ALREADY terrain water past the rim, winding in S-bends all the way to z -900:
  - 16-28 studs wide, bed about -8, a thin sand/grass strip on each bank.
  - Beyond that is the flat Baseplate grass right out to its edge, which you can see from high up.
- `Village.Props` has 61 parts along that outside stretch (x 95..217, z -822..-297), probably riverside trees and rocks from the old kit.
  - Keep them (no deleting); ask before moving or hiding any.
- Sandstone Climb, the hang glider and the basket lift sit at the south edge, x 441..592.
- Lighting: Atmosphere density 0.3, haze 0, FogEnd 1100, ClockTime 14.5.

## Proposal
1. **South ridge:** a continuous band of layered cliffs and hills across the whole south edge.
   - It runs from about z -230 to -560 and joins the existing mounds and the Sandstone Climb.
   - From anywhere in the map you then see hills, not the flat plain or the Baseplate edge.
2. **The gorge** is cut through the ridge on the EXISTING channel (no re-routing):
   - Cliffs rise from about 30 studs high at the mouth to 45 studs at the narrows.
   - The water narrows to about 20 wide; the boat is 4 wide.
   - Cliff style (pick one): layered cream sandstone like the Sandstone Climb, grey limestone, or green hills with rock.
   - Secondary detail: ledges, ferns and moss at the waterline, a small waterfall trickling in, pines and cypress along the tops, rocks in the shallows at the banks.
3. **Landmark:** an old stone aqueduct arch spans the gorge at z ~-345, a nod to Italy.
   - The boat passes under it, with at least 10 studs clearance.
4. **Trip flow:**
   - At the rim, a "Sail to Italy?" card appears (Yes / Not yet).
   - Yes: autopilot follows the channel (about 15 s), under the arch, to the bend at z ~-420.
   - There: fade, then the map card (Rue de Noisette -> Porto Nocciola, a little boat on a dotted line), then fade in on the Italy approach.
   - Other players see the boat sail away into the gorge.
5. **Walkers:** the rim wall stays, so the gorge is boat-only. There could be a viewpoint on the rim.
6. **Current:** extend the drifting leaves and streaks into the gorge.
7. **Haze (optional, affects the whole map):** a light haze so the distant ridge fades softly. Ask first.

## Order and publishing
- Build the ridge, gorge and arch, then the autopilot up to the fade (tested in Play).
- Then the Harbour Front arrival.
- The trip stays switched off, and everything waits unpublished, until Harbour Front is done. Publish it all together on Shannon's word, turning the boat prompt back on.

## Quality checklist before showing
- Low-angle renders and dead-level side views from the boat's eye height.
- No floating or sunk rocks and trees: raycast every prop onto the terrain.
- One ground material family where the gorge meets the existing mounds, with no seam.
- Sand/mud band at the waterline, no grass straight into the water.
- Cliffs checked from the rim, from the boat, and from the hang-glider height.
- Phone test for the "Sail to Italy?" card and the map card: no overlaps.
