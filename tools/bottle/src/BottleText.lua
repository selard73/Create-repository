-- BottleText (ModuleScript in workspace.Bottles): every word of the message-in-a-bottle game. Shared by BottleServer and BottleClient;
-- only INDEXES travel over the network and onto the save, so no player-typed text exists anywhere. Shannon (Oct 6 / Oct 15 2026):
-- fill-in-the-blank notes sent TO someone at sea; the next day a reply washes up that answers what you picked; silly bottles wash up too.
local T = {}
-- who the bottle is for (the reply is signed by them)
T.TO = {
	{label = "a stranded pirate", sign = "Captain Barnacle, on a very small island"},
	{label = "the lighthouse keeper", sign = "Old Lucia, keeper of the lighthouse"},
	{label = "the big whale", sign = "Balena, the big whale"},
	{label = "a crab on the rocks", sign = "Granchio, a crab of few words"},
	{label = "the grumpy squid", sign = "The Squid (still grumpy)"},
	{label = "whoever finds this", sign = "Someone who found your bottle"},
	{label = "a squirrel far, far away", sign = "Hana, a squirrel very far to the east"},
}
-- the message cards: text with two blanks, the choices for each, and the reply's first line that answers them.
-- (round 3, Shannon: "the fill in the blank is nonsensical" - every option in a blank is the same kind of word, and EVERY pairing of
-- blank 1 with blank 2 reads as a sensible (silly) sentence; the echo lines work for every pairing and every recipient)
T.CARDS = {
	{text = "Ahoy! Do you have enough {A} out there? I'm sending you {B}.",
	 A = {"snacks", "sunscreen", "socks", "friends", "books", "games"},
	 B = {"a sandwich", "a joke", "a map", "a tiny umbrella", "a lucky acorn", "a drawing of a squirrel"},
	 echo = {"Thank you for {B}! I definitely do not have enough {A}.", "Nobody has ever sent me {B} before. Now I just need more {A}."}},
	{text = "Today in Porto I ate {A}. It was {B}!",
	 A = {"a giant gelato", "a slice of pizza", "a lemon", "a bowl of spaghetti", "a fish sandwich", "a whole watermelon"},
	 B = {"delicious", "too big", "very sticky", "the best ever", "a little sour", "gone in one bite"},
	 echo = {"You ate {A} and it was {B}? Now I'm hungry.", "I've never tried {A}. Was it really {B}?"}},
	{text = "Help! A {A} stole my {B}!",
	 A = {"seagull", "crab", "pelican", "sneaky squirrel", "big wave", "cat"},
	 B = {"hat", "gelato", "sandwich", "flip-flop", "sunglasses", "towel"},
	 echo = {"Oh no! I'll keep an eye out for a {A} with a {B}.", "I saw a {A} go past this morning with a {B}. It looked very pleased with itself."}},
	{text = "If you come to Porto, bring {A} and we can {B}.",
	 A = {"a kite", "a picnic", "a beach ball", "a boat", "a swimsuit", "a camera"},
	 B = {"go swimming", "eat gelato", "look for squirrels", "watch the whale", "build a sandcastle", "ride the funicular"},
	 echo = {"I'll bring {A}! I've always wanted to {B}.", "Packing {A} right now. Save me a spot so we can {B}."}},
	{text = "Greetings from the beach! It's {A} today and I'm feeling {B}.",
	 A = {"sunny", "windy", "rainy", "very hot", "cloudy", "perfect"},
	 B = {"happy", "sleepy", "brave", "hungry", "silly", "fancy"},
	 echo = {"It's {A} here too! I'm feeling a bit {B} as well.", "{A} and {B}? That sounds like a great beach day."}},
	{text = "My best friend is a {A} who loves {B}.",
	 A = {"squirrel", "crab", "seagull", "dolphin", "lighthouse keeper", "pirate"},
	 B = {"dancing", "singing", "napping", "telling jokes", "collecting shells", "eating acorns"},
	 echo = {"A {A} who loves {B}? Please introduce me!", "Tell your {A} I love {B} too."}},
}
-- (round 3, Shannon: "we should be able to personalize it more, otherwise, no sense in the anticipation of coming back the next day")
-- a question to ask - and each recipient answers it in their own voice (same order as T.TO)
T.QUESTIONS = {"What's your favourite food?", "What do you do all day?", "Do you have any pets?", "What's the best thing about the sea?", "Can you keep a secret?", "What should I do in Porto?"}
T.ANSWER = {
	{"Coconuts. Only coconuts. It's coconuts or nothing on this island.", "I count waves. Yesterday there were 4,000. Or 12. I lost count.", "A crab named Gerald. He doesn't know he's my pet.", "The best thing about the sea is that it brought me your bottle.", "Arr, I can! I've kept one for years. I just can't remember what it is.", "Eat a gelato for me. Two, if they're small."},
	{"Toast with lemon jam, by the light of the big lamp.", "I polish the lamp, wave at the boats, and tell the seagulls off.", "A cat called Faro. She sleeps right next to the light.", "The sunsets. From up here, every one is the best I've ever seen.", "Of course. A lighthouse shines on the sea, never on secrets.", "Climb up to the lighthouse and wave. I'll wave back!"},
	{"Krill. Millions of them. Is that greedy? It feels greedy.", "I swim, I sing, and I splash the fishing boats by accident.", "A little fish follows me everywhere. I think he thinks I'm a rock.", "It's very big, like me. We get along.", "I'm a whale. Everything I say is very, very loud. But I'll try.", "Look out to sea from the beach. A big splash is me saying hi."},
	{"Seaweed. Crunchy seaweed. Click click.", "I walk sideways. Then I walk sideways back.", "A pebble. His name is Pebble. He is a very good pebble.", "The rocks. Also the sea. Mostly the rocks.", "Yes. Crabs never tell. We just pinch.", "Try the crab game. But please don't catch me."},
	{"Spaghetti. Don't laugh. All eight of my arms like spaghetti.", "Mostly I sulk in my cave. It's a very good cave for sulking.", "No. Pets are for happy squids. ...A starfish, maybe. Just one.", "Nobody bothers me down here. Well, nobody until your bottle.", "I keep everyone's secrets. Then I forget them. Squid brain.", "Don't come into my cave. Unless you bring spaghetti."},
	{"Pizza, today. Tomorrow? Also pizza.", "I walk on the beach and pick up bottles. Mostly yours, it turns out.", "A goldfish called Captain. He's very brave for a goldfish.", "Finding bottles like yours. It's like getting mail from the waves.", "I can! My lips are sealed. Like a bottle.", "Find all the squirrels. I'm still looking for one in a tiny hat."},
	{"Mochi! Soft, sweet and a little bit chewy.", "I sweep the temple steps and watch the cherry blossoms fall.", "A koi fish named Sunny. He lives in the garden pond.", "It carries bottles all the way to me. Like yours!", "Yes. Here we fold secrets into paper cranes.", "Ride the funicular to the top, then look east. That's where I am!"},
}
-- the second line of a reply, in each sender's own voice (same order as T.TO)
T.VOICE = {
	{"I've been on this island for 300 days. Or 3. I lost count.", "Send more bottles. I'm building a raft out of them.", "Arr. That means thank you.", "P.S. If you see my ship, tell it to come back."},
	{"The light is on, the kettle is on, and now I have a letter. Lovely day.", "Wave at the lighthouse tonight. I'll blink back.", "The seagulls here read over my shoulder. Rude.", "I keep every bottle on a shelf. Yours is next to the one with a sock in it."},
	{"BLUB. (That means hello.)", "I tried to write back, but my flippers are very big. A fish helped.", "I'll swim past the harbour later. Look for the big splash.", "I sang your letter to my friends. They loved it."},
	{"Click click. Good letter.", "I read it sideways. Crabs read everything sideways.", "Do not tell the seagulls where I live.", "I have pinched your bottle as a souvenir. Sorry. Not sorry."},
	{"Hmph. I suppose that was... nice. Don't tell anyone.", "I have eight arms, and none of them wanted to write back. But here we are.", "This changes nothing. I am still grumpy. Slightly less grumpy.", "I am keeping the bottle. It's shiny."},
	{"I found your bottle while looking for my other shoe. Still no shoe, but this was better.", "Your bottle bonked me on the head. Worth it.", "I'm writing back from a very wet beach. Hi!", "I'm going to send one too. Watch out for it!"},
	{"Your bottle floated all the way to me! The sea is very big.", "Here we have cherry trees and very fast trains. Come visit one day.", "I'm drinking tea and reading your letter. Perfect.", "Konnichiwa! That means hello. Your turn to say it."},
}
-- silly bottles that wash up on their own (anyone can find them)
T.BEACH = {
	{"Whoever finds this: the gelato shop is open. RUN.", "A seagull who has already been"},
	{"If found, please return this bottle. It is my favourite bottle.", "Somebody, somewhere"},
	{"Day 4 on the raft. Still no snacks. Morale: medium.", "Captain Barnacle"},
	{"Roses are red, the sea is blue, I lost my sandwich, have you seen it too?", "A hungry pelican"},
	{"This is a test bottle. If you are reading this, the test worked.", "The Porto Bottle Company"},
	{"The fish say hello. I don't know why they told me. I'm a crab.", "Granchio"},
	{"Do NOT go into the cave. Unless you want to. It's quite nice actually.", "The Squid"},
	{"Seen today: one whale, two boats, three squirrels in sunglasses.", "Old Lucia at the lighthouse"},
	{"I wrote this upside down. Please turn your head.", "A very silly squirrel"},
	{"Lost: one flip-flop, left foot. Reward: the right flip-flop.", "A beach squirrel"},
	{"Is this thing on? Hello? HELLO?", "Balena, the big whale"},
	{"The waves are doing a lot today. Too much, if you ask me.", "Granchio"},
	{"Note to self: do not let the crab hold the map.", "Captain Barnacle"},
	{"Greetings from far away! The cherry trees say hi.", "Hana, a squirrel very far to the east"},
	{"Your hair looks great today. (I can't see you. I'm a bottle.)", "The bottle"},
	{"Free hugs. Some assembly required.", "An octopus who is NOT the squid"},
}
local function fill(s, a, b) return (s:gsub("{A}", a):gsub("{B}", b)) end
function T.valid(to, card, a, b, q)
	local c = T.CARDS[card]
	return T.TO[to] ~= nil and c ~= nil and c.A[a] ~= nil and c.B[b] ~= nil and (q == nil or q == 0 or T.QUESTIONS[q] ~= nil)
end
function T.message(to, card, a, b, q, from)                -- what the player sent
	local c = T.CARDS[card]
	local m = "To " .. T.TO[to].label .. ":\n" .. fill(c.text, c.A[a], c.B[b])
	if q and T.QUESTIONS[q] then m ..= " " .. T.QUESTIONS[q] end
	if from then m ..= "\nFrom " .. from end
	return m
end
function T.reply(to, card, a, b, seed, q, info, name)    -- (round 3b, Shannon: "the replies ... should be short goofy one liners"):
	local c = T.CARDS[card]                                  -- Dear <name>, then ONE line - their own answer to the question asked;
	local line                                               -- a bottle sent before round 3 (no question) gets its echo line
	if q and T.ANSWER[to] and T.ANSWER[to][q] then line = T.ANSWER[to][q]
	else
		line = fill(c.echo[(seed % #c.echo) + 1], c.A[a], c.B[b])
		line = line:sub(1, 1):upper() .. line:sub(2)
	end
	local body = (name and ("Dear " .. name .. ",\n") or "") .. line
	if type(info) == "table" and info.hintName then body ..= "\nP.S. I spotted " .. info.hintName .. (info.hintWhere and (" in " .. info.hintWhere) or "") .. "!" end   -- (only when the folder's ReplyHints is on)
	return body, T.TO[to].sign
end
return T
