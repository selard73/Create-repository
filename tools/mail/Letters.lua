-- Letters (workspace.Mail; mail3, Oct 22 2026): the letters the squirrels send to your treehouse mailbox, in order. One a day
-- (the daily card's day, 09:00 UTC), and only from a squirrel you have found - except the welcome letter (always = true),
-- which arrives the moment your mailbox appears. Shannon edits these. Fields:
--   id     a stable key (saved as Item_mail_<id> once delivered - never rename one that has gone out)
--   from   the sender's squirrel id (SquirrelRegistry); the letter is signed with that squirrel's name
--   always true = no need to have found the sender first
--   text   the body ("Dear <your name>," is added above it); {name} becomes the player's name
--   sign   the sign-off line above the squirrel's name
--   gift   acorns tucked in the envelope (0 = none)
-- ADD NEW LETTERS AT THE END ONLY and never reorder: the waiting letter is saved by its number in this list.
return {
	{id = "welcome", from = "ranger_squirrel", always = true, gift = 15, sign = "Your neighbour on the trail,",
	 text = "Welcome to your new treehouse! As Forest Ranger I checked the ladder twice and the rope three times. Rule number one: always climb facing the ladder. Rule number two: check this mailbox every day. The squirrels LOVE writing letters.\n\nP.S. I tucked a few acorns in the envelope. Every new home needs a little something."},
	{id = "betty1", from = "baking_betty_squirrel", gift = 10, sign = "Sprinkles and hugs,",
	 text = "I baked you a welcome-home cupcake with extra frosting and a little acorn on top. Then I ate it. Quality control, you understand. I will bake you another one tomorrow. Probably.\n\nP.S. Here are some acorns instead. They are crunchier."},
	{id = "holmes1", from = "detective_squirrel", gift = 0, sign = "Discreetly yours,",
	 text = "I have been watching your treehouse for three days. Purely for investigative reasons. My conclusion: somebody lives there, and that somebody is you. Case closed. I will send my bill in the morning. (There is no bill. I just like saying that.)"},
	{id = "gordo1", from = "gordo_squirrel", gift = 10, sign = "Your hungry friend,",
	 text = "Do you have any snacks in your treehouse? I am asking for a friend. The friend is me. If you ever find an acorn under your rug, it is mine. Please keep it safe until I come over for a nap.\n\nP.S. I put some acorns in here for you. It was very, very hard."},
	{id = "fairy1", from = "fairy_squirrel", gift = 20, sign = "Twinkles,",
	 text = "It is Tuesday somewhere, so I am granting you one small wish. I wished you a really good acorn, and then a few more because I sneezed. Sorry about the glitter on the envelope. And on the mailbox. And on the tree."},
	{id = "buccaneer1", from = "squirrel_buccaneer", gift = 0, sign = "Arr and ahoy,",
	 text = "Ahoy, {name}! I found a treasure map that leads straight to your treehouse. I followed it all morning and ended up at the bakery. Twice. If you spot a big X anywhere near your ladder, send word at once. The map may have been upside down."},
	{id = "scientifico1", from = "squirrel_scientist", gift = 0, sign = "For science,",
	 text = "I measured your treehouse with my Acornometer. Results: one hundred percent cozy, zero percent explosions. Very disappointing for science, very good for you. I have attached my findings. They are this letter."},
	{id = "surfer1", from = "surfing_squirrel", gift = 0, sign = "Hang ten, dude,",
	 text = "Duuude! Your treehouse is SO high up. If it rains enough, do you think the whole forest turns into one giant wave? Asking for science. And surfing. Mostly surfing. If it happens, I call the first ride."},
	{id = "birds1", from = "birdwatch_squirrel", gift = 0, sign = "Binoculars up,",
	 text = "A bird landed on your roof this morning. I wrote it down. It was a brown one. Page five of my bird list is now all about your treehouse. I hope you do not mind. Please wave next time. The bird will not, but I will."},
	{id = "rainy1", from = "rainy_day_squirrel", gift = 10, sign = "Stay dry,",
	 text = "The clouds over your treehouse look suspicious. I have sent you a spare umbrella in this envelope. It is very small because it had to fit. Also my spare-spare umbrella. Also some acorns, in case the umbrellas do not work."},
}
