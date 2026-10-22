-- Lines (workspace.Gordo; gordo1, Oct 22 2026): what Gordo says once he has moved into your treehouse to "watch the house
-- while you are away". Shannon edits these. {name} becomes the player's name.
return {
	-- the note that pops up in Italy after about a minute there (once ever)
	italy = "Psst, it's Gordo! Since you're off in Italy, I moved into your treehouse to watch the house while you're away. Don't worry about your snacks. They are very safe. In my tummy.",
	-- the first time you come home after he moved in
	firstGreet = "Welcome home, {name}! I'm your new house-sitter. The house is safe. The snacks, less so.",
	-- (wall1) when you evict him from the Treehouse tab (if he is in sight), and his greeting when you invite him back
	evicted = "Fine! I'm going. I'm taking the snacks. All of them.",
	welcomeBack = "I knew you'd miss me! I brought snacks. I ate them on the way.",
	-- whenever you come home after that (one of these)
	greets = {
		"{name}! You're back! Nothing happened. Ignore the crumbs.",
		"Oh, hi {name}! I was definitely awake. Guarding. With my eyes closed.",
		"Welcome home, {name}! I kept your spot warm.",
		"{name}! Did you bring snacks? I'm only asking for guarding reasons.",
	},
	-- now and then while you are home (in a shuffled order, no repeats until all have been said)
	chatter = {
		"I checked every corner for burglars. I found three crumbs and ate the evidence.",
		"This floor is perfect for naps. I have tested it eleven times.",
		"Was that a knock at the door? No. Just my tummy.",
		"Guard report: zero burglars, one mug, many naps.",
		"Remember the sign that said a squirrel was going to live here? Hi. It was me.",
		"I would help you decorate, but I might eat the rug.",
		"How was Italy? Did you bring back pizza? A tiny pizza? One crumb of pizza?",
		"If the mug moved, it wasn't me. If the mug is empty, also not me.",
		"Have you met the other Gordo out in the forest? Very handsome fellow.",
		"I'm not hungry. My tummy is. We don't always agree.",
		"I check your mailbox every day. Still no pizza in there.",
		"Guarding is hard work. That's why I need so many snacks.",
	},
}
