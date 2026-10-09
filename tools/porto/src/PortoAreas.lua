-- PortoAreas (ReplicatedStorage): the Porto Nocciola passport outings' shared tables (Oct 9 2026). The three "find all"
-- outings use the registry ids of each area (SquirrelRegistry map porto: harbour, borgo = Via della Piazza, groves).
-- Keep this in step with the registry when squirrels are added.
return {
	lists = {
		harbour = {"customs_squirrel", "fishmonger_squirrel", "deckhand_squirrel", "netmender_squirrel", "gelato_squirrel", "boatpainter_squirrel",
			"realtor_squirrel", "italytourist_squirrel", "tightrope_squirrel", "seacaptain_squirrel", "sunbather_squirrel", "crabcatcher_squirrel",
			"conductor_squirrel", "lifeguard_squirrel", "octopus_squirrel"},
		borgo = {"sassyshopper_squirrel", "pogo_squirrel", "pizzadelivery_squirrel", "baker_squirrel", "giulia_market_squirrel",
			"officer_acorn_police_squirrel", "goldenyears_squirrel", "goodneighbor_squirrel", "operasinger_squirrel", "broomseller_squirrel",
			"accordion_squirrel", "pizzamaker_squirrel", "church_mouse_cousin", "clockmaker_squirrel", "postcard_squirrel"},
		groves = {"lemonseller_squirrel", "olivepicker_squirrel", "snorkel_squirrel", "hiker_squirrel", "cliffdiver_squirrel", "stargazer_squirrel",
			"treasurehunter_squirrel", "lighthousekeeper_squirrel", "keeperswife_squirrel", "photographer_squirrel", "droneflyer_squirrel",
			"seaglass_squirrel", "guitarist_squirrel", "butterfly_squirrel"},
	},
	outing = {harbour = "porto_harbour", borgo = "porto_borgo", groves = "porto_groves"},
	names = {harbour = "the harbour", borgo = "the Via della Piazza", groves = "the Groves"},
	-- Bella's beach finds: the item ids (Item_<id> on the player), in the order the panel shows them
	beachKinds = {"seaglass_green", "seaglass_brown", "seaglass_white", "seaglass_blue", "seaglass_purple", "shell_scallop", "shell_spiral", "shell_cowrie"},
}
