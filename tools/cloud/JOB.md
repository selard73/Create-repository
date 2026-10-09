# Job 5: town-wide stacked-floor survey, DRY RUN only (READ-ONLY)

Shannon's VR check after the square cut: the flicker is "all over, where two things are layered" (the quay at the
spawn, the paths, the funicular). This is the town-wide version of the square survey. It only reports.

1. Fetch and read:
   https://raw.githubusercontent.com/selard73/Create-repository/claude/epic-hawking-188q4l/tools/flicker/town_fix1.lua
2. Run it in Studio, Edit mode, with execute_luau, exactly as it is: `DRY = true` is set at the top, so it surveys
   the whole Porto box (x 250..800, z -1250..-500, about 1.5 million grid columns) and prints the plan. It changes
   nothing. Do not set DRY to false. It can take up to about 2 minutes; let it finish.
3. Send ONE message to the cloud session "GitHub free credit eligibility" with every Output line that starts with
   `QQ TWN`, unchanged (about 100 lines). If it errors or aborts, send that text instead.
4. Do not analyse or fix anything.
