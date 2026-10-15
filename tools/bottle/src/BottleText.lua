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
-- the message cards: text with two blanks, the choices for each, and the reply's first line that answers them
T.CARDS = {
	{text = "Ahoy! I hope you have enough {A}. I'm sending you {B}.",
	 A = {"snacks", "sunscreen", "friends", "socks", "adventure", "acorns"},
	 B = {"a hug", "a joke", "a map", "good luck", "a sandwich", "a tiny boat"},
	 echo = {"You sent me {B}? Nobody has ever sent me {B} before!", "Enough {A}? I never have enough {A}. How did you know?"}},
	{text = "Today I found {A} in Porto. It was very {B}.",
	 A = {"a squirrel", "a crab", "gelato", "a seashell", "a whale", "a lemon"},
	 B = {"sticky", "shiny", "loud", "suspicious", "delicious", "wonderful"},
	 echo = {"You found {A} and it was {B}? That is the best news I've had all week.", "I once found {A} too. Mine was not {B}. Yours sounds better."}},
	{text = "Do you like {A}? I like {B} the most.",
	 A = {"gelato", "boats", "the beach", "mysteries", "napping", "pizza"},
	 B = {"lemons", "sunsets", "waves", "acorns", "spaghetti", "singing"},
	 echo = {"{B}? Me too! Well, {A} a little bit. But mostly {B}.", "We should start a club for everyone who likes {B}."}},
	{text = "Help! A {A} stole my {B}!",
	 A = {"seagull", "crab", "squirrel", "pelican", "wave", "cat"},
	 B = {"hat", "gelato", "sandwich", "shoe", "map", "acorns"},
	 echo = {"Oh no, a {A} took your {B}? I will keep an eye out for a {A} with a {B}.", "I saw a {A} go past this morning with a {B}. It looked very pleased with itself."}},
	{text = "If you come to Porto, bring {A} and we can {B}.",
	 A = {"a kite", "a pizza", "your friends", "a boat", "an umbrella", "a song"},
	 B = {"go swimming", "eat gelato", "find squirrels", "race scooters", "watch the whale", "build a sandcastle"},
	 echo = {"Bring {A}? Done. I've wanted to {B} for ages.", "I'm packing {A} right now. Save me a spot and we can {B}."}},
	{text = "Greetings from the beach! The weather is {A} and I feel {B}.",
	 A = {"sunny", "windy", "splashy", "perfect", "too hot", "mysterious"},
	 B = {"happy", "sleepy", "brave", "hungry", "silly", "fancy"},
	 echo = {"{A} and feeling {B}? That sounds like a perfect beach day.", "It's {A} here too! Well, it's wet. I'm feeling a bit {B} as well."}},
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
function T.valid(to, card, a, b)
	local c = T.CARDS[card]
	return T.TO[to] ~= nil and c ~= nil and c.A[a] ~= nil and c.B[b] ~= nil
end
function T.message(to, card, a, b)                        -- what the player sent
	local c = T.CARDS[card]
	return "To " .. T.TO[to].label .. ":\n" .. fill(c.text, c.A[a], c.B[b])
end
function T.reply(to, card, a, b, seed)                    -- the answer: an echo of what they picked + the sender's voice + the signature
	local c = T.CARDS[card]
	local e = c.echo[(seed % #c.echo) + 1]
	local v = T.VOICE[to][(math.floor(seed / 7) % #T.VOICE[to]) + 1]
	return fill(e, c.A[a], c.B[b]) .. " " .. v, T.TO[to].sign
end
return T
