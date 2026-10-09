-- Tours (workspace.FilmMode): Shannon's scenic camera tours for TikTok (Oct 8 2026), framed for a 9:16 portrait window -
-- every key keeps its subject in the middle. Each key = {camera position, point it looks at}; the camera glides through
-- them on a smooth curve at an even pace, easing in and out. secs = length at 1x; fov = the camera's (vertical) field of view.
-- kind "whale" follows the whale; kind "drone" is the free-fly camera.
local V = Vector3.new
return {
	{id = "sea", name = "Porto from the sea", secs = 26, fov = 72, keys = {
		{V(110, -46, -805), V(195, -28, -560)},          -- low over the bay, the falls ahead
		{V(140, -45, -760), V(200, -30, -565)},
		{V(170, -43, -720), V(232, -32, -600)},
		{V(195, -40, -692), V(262, -30, -610)},          -- toward the pastel waterfront
		{V(212, -32, -684), V(286, -22, -622)},
		{V(222, -20, -692), V(300, -12, -640)},          -- rising over the harbour
	}},
	{id = "square", name = "The square", secs = 30, fov = 70, keys = {
		{V(455.5, -8.6, -783.5), V(451.1, -9.4, -776.5)}, -- Chef Nutmeg tossing his pizza
		{V(453, -8.2, -790), V(446, -9.8, -784)},
		{V(447.5, -8.6, -798.5), V(441.3, -10.2, -792.3)},-- the opera singer and the accordion player
		{V(455, -6.8, -802), V(464, -7, -794)},           -- the fountain
		{V(452, -4.5, -780), V(468, -4, -806)},
		{V(452, -3, -768), V(470, -2, -808)},             -- fountain and clock tower
		{V(450, 5, -758), V(476, 10, -812)},              -- rising, the Torre dell'Orologio
	}},
	{id = "whale", name = "Whale chase", kind = "whale", fov = 70},
	{id = "lighthouse", name = "Lighthouse + blue cave", secs = 36, fov = 74, keys = {
		{V(425, -12, -1240), V(515, 32, -1178)},          -- the lighthouse from the sea
		{V(440, -10, -1228), V(516, 30, -1178)},
		{V(408, -30, -1195), V(470, -10, -1150)},         -- round the headland, out over the water
		{V(410, -42, -1145), V(462, -48, -1112)},         -- the cave mouth
		{V(430, -44.6, -1113), V(470, -49, -1112)},
		{V(451, -45.4, -1112), V(473, -49.5, -1112)},     -- in: Polpo Brontolone (over the rock lip at the mouth)
		{V(462, -45.8, -1112), V(474, -50, -1112)},
		{V(467, -45.6, -1110), V(503, -49, -1112)},       -- the cages at the back
	}},
	{id = "funicular", name = "Funicular ride", secs = 32, fov = 74, keys = {
		{V(343, -40, -613), V(420, -20, -622)},
		{V(430, -16, -627), V(520, 8, -640)},
		{V(530, 12, -644), V(620, 40, -655)},
		{V(640, 45, -661), V(690, 58, -664)},
		{V(684, 76, -668), V(460, -20, -705)},            -- the top: rise over the station, turn to the view over town and sea
		{V(690, 92, -678), V(380, -40, -770)},
	}},
	{id = "france", name = "French village + Chateau", secs = 38, fov = 74, keys = {
		{V(160, 11, -112), V(250, 8, -90)},               -- the Rue de Noisette from the bridge
		{V(200, 9.5, -102), V(280, 7, -84)},
		{V(245, 10, -93), V(305, 8, -82)},
		{V(288, 29, -97), V(360, 10, -125)},               -- (higher: clears the roof)
		{V(350, 36, -145), V(450, 4, -172)},              -- over the gate to the lavender
		{V(420, 26, -190), V(520, 12, -130)},
		{V(482, 24, -150), V(588, 27, -62)},              -- the windmill
		{V(532, 26, -108), V(588, 30, -62)},
	}},
	{id = "balloon", name = "Balloon flight", kind = "balloon", fov = 72},   -- climb aboard after pressing it; filmed from liftoff to landing (Oct 9)
	{id = "drone", name = "Drone camera", kind = "drone", fov = 72},
}
