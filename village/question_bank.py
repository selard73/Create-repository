# -*- coding: utf-8 -*-
"""The Question of the Day bank. Shannon (Sep 25 2026): "a daily question or riddle, must submit the answer at the post
office by 6pm est" ... "the questions could be about the stories of the squirrels, a riddle or just a trivia question,
different every day" ... "but mostly about the game story and info. rewarding players for knowing the game" ... "for
instance, What is squirrel Margaux's profession?" ... "Questions about the squirrels' back stories".

Every answer here comes straight from the game: the squirrel bios (squirrels/make_squirrel_scripts.py REGISTRY), the three
books in the Librairie (village/build_bookshop.lua), and the maps. The FIRST answer is always the right one; the game
shuffles the four for each player and never sends the client which one is right.

Run:  python question_bank.py   -> village/question_bank.lua (the ModuleScript source, ASCII with byte escapes)
                                  -> question_list.html next to it (for Shannon to read through)
"""
import io, os, random, html

# (id, kind, question, right answer, wrong, wrong, wrong)
Q = [
    # ---------------------------------------------------------------- The Great Acorn Forest ----
    ("holmes", "Back story", "Mr. Holmes Squirrel is investigating the Case of the Missing Acorn. What happened to the acorn?", "He ate it", "A crow took it", "It rolled into the river", "It is buried under the fountain"),
    ("rainy", "Back story", "What is Rainy Day Squirrel never caught without?", "Her umbrella", "Her rain boots", "Her raincoat", "Her lucky acorn"),
    ("buccaneer", "Back story", "Why does the Buccaneer Squirrel never find his buried acorns?", "He reads his treasure map upside down", "His parrot ate the map", "He buried them at sea", "He forgot his shovel"),
    ("scientist", "Back story", "El Scientifico holds three degrees in Acorn Physics, and one in what?", "Explosions", "Cooking", "Ballet", "Painting"),
    ("scientist2", "Back story", "What does El Scientifico say at the end of every experiment?", "Well, THAT was interesting.", "Eureka!", "Back to the drawing board.", "Nobody panic."),
    ("surfer", "Back story", "The Surfer Dude Squirrel rides the gnarliest waves in the forest. What are they, mostly?", "Puddles", "The river", "Waterfalls", "Bathtubs"),
    ("nacho", "Back story", "Nacho Libre Squirrel is the masked defender of the forest. What is his weakness?", "Nachos", "Spiders", "Thunderstorms", "Heights"),
    ("gordo", "Back story", "What are Gordo Squirrel's hobbies?", "Napping, snacking, and napping after snacking", "Surfing and skiing", "Painting and poetry", "Kite flying and fishing"),
    ("fairy", "Back story", "On which day of the week does the Fairy Squirrel grant wishes?", "Tuesday", "Monday", "Friday", "Sunday"),
    ("ski", "Back story", "What happens every time Ski-a-roo Squirrel skis down a hill?", "He ends up hugging a tree", "He lands in a puddle", "He wins a gold medal", "He loses a ski"),
    ("ballerina", "Back story", "Where does the Ballerina Squirrel practise her pirouettes?", "On tree branches", "On the fountain", "On the cafe tables", "On the windmill"),
    ("betty", "Back story", "Baking Betty bakes forty cupcakes a day. How many does she eat for quality control?", "Thirty-nine", "Forty", "Twenty", "One"),
    ("kite", "Back story", "What does the Kite Flyer Squirrel do when there is no wind?", "Runs the whole forest to make his own", "Stays home and naps", "Borrows a fan", "Ties the kite to a bird"),
    ("skydive", "Back story", "Who packs the Sky Diving Squirrel's parachute?", "He packs it himself", "The Forest Ranger", "The Fairy Squirrel", "Nobody does"),
    ("birdwatch", "Back story", "The Bird Watching Squirrel's list of birds runs to four pages. What do two of the entries say?", "Brown one", "Pigeon", "Very big bird", "Crow, probably"),
    ("ranger", "Back story", "How many times has the Forest Ranger Squirrel given his safety talk?", "Four hundred", "Ten", "Forty-four", "A million"),
    # ---------------------------------------------------------------- Rue de Noisette ----
    ("gerard", "Back story", "How long has Gérard the Mailman Squirrel been delivering the mail?", "Thirty-one years", "Three years", "Eleven years", "Fifty years"),
    ("gerard2", "Back story", "Gérard buries an acorn in which flowerpots?", "Every third flowerpot", "Every flowerpot", "Only the red ones", "None of them"),
    ("philosopher", "Back story", "Where does the Philosopher Squirrel spend his days?", "At the café", "At the bookshop", "On the bridge", "Up the windmill"),
    ("waiter", "Back story", "What does the French Waiter Squirrel do while he brings your café au lait?", "Sighs very dramatically", "Sings", "Juggles croissants", "Tells jokes"),
    ("mime", "Back story", "Since when has Marcel the Mime been trapped inside his invisible box?", "Since 1987", "Since last Tuesday", "Since 2001", "Since breakfast"),
    ("cyclist", "Back story", "Which race is the Cyclist Squirrel training for?", "The Tour de France", "The Great Acorn Relay", "The Paris Marathon", "The Forest Race"),
    ("cyclist2", "Back story", "What is the Cyclist Squirrel still working on?", "Actually riding the bike", "Finding a helmet", "Finding the start line", "Pedalling backwards"),
    ("glam", "Back story", "What does the Glam Squirrel never leave home without?", "Her pearls and sunglasses", "Her umbrella", "Her tutu", "Her kite"),
    ("birdfeeder", "Back story", "The fountain pigeons started a fan club for the Bird Feeder Squirrel. What did they start next?", "A union", "A band", "A bakery", "A football team"),
    ("firefighter", "Back story", "How many cats has the Firefighter Squirrel rescued from trees?", "Nine", "Two", "Forty", "A hundred"),
    ("dale", "Back story", "Where is Dale the Tourist Squirrel from?", "Tulsa", "Paris", "London", "Tokyo"),
    ("dale2", "Back story", "How did Dale the Tourist Squirrel get to France?", "In somebody's carry-on bag", "On a bicycle", "In a hot-air balloon", "He swam"),
    ("dale3", "Back story", "What does Dale think the Eiffel Tower is?", "The tallest tree in France", "A giant acorn", "A lighthouse", "A windmill"),
    ("painter", "Back story", "How many times has the French Painter Squirrel painted the town fountain?", "Three hundred", "Three", "Thirty", "Just once"),
    ("florist", "Back story", "What does the Florist Squirrel swear the tulips do?", "Talk back", "Dance", "Sing at night", "Grow overnight"),
    ("spy", "Back story", "What does the International Spy Squirrel keep forgetting?", "His code name, his hideout and his handshake", "His beret", "The way home", "His sunglasses"),
    ("margaux", "Back story", "What is Margaux's job?", "Fashion designer", "Florist", "Baker", "Painter"),
    ("margaux2", "Back story", "Margaux keeps a pencil behind each ear. Where does she keep the third one?", "In her tail", "In her pocket", "In her hat", "In her teeth"),
    ("margaux3", "Back story", "Margaux's glasses are not prescription. What are they?", "A statement", "A disguise", "A present", "Borrowed"),
    ("fishing", "Back story", "How many fish has the Fishing Squirrel caught?", "Exactly one", "None", "Hundreds", "Seven"),
    # ---------------------------------------------------------------- Chateau de l'Acorn ----
    ("gardener", "Back story", "What does the Gardener Squirrel call his favourite pumpkin?", "The big fellow", "Mr. Orange", "Pumpy", "The champion"),
    ("church", "Back story", "What does the Church Mouse have ready for every day of the year?", "A sermon", "A cake", "A song", "A riddle"),
    ("vintner", "Back story", "How many barrels are in the Vintner Squirrel's cellar?", "One", "Twelve", "A hundred", "None"),
    ("lucie", "Back story", "What does Lavender Lucie spray on anything that stands still long enough?", "Lavender perfume", "Water", "Glitter", "Paint"),
    ("beekeeper", "Back story", "What have the bees said to the Beekeeper Squirrel so far?", "Bzz", "Hello", "Bonjour", "Nothing at all"),
    ("fernand", "Back story", "Why is Farmer Fernand up before the rooster?", "To remind the rooster", "To milk the goat", "To drive the tractor", "To pick sunflowers"),
    ("scarecrow", "Back story", "What happened when the Scarecrow Squirrel took the job of scaring crows?", "He made friends with every one of them", "He scared them all away", "He got scared himself", "He fell asleep"),
    ("toto", "Back story", "Tractor Toto has never driven the tractor, but he named it. What is its name?", "Toto", "Big Red", "Fernand", "Pierre"),
    ("sunflower", "Back story", "Why does the Sunflower Squirrel get a stiff neck every evening?", "She turns to face the sun all day", "She watches for crows", "She sleeps on the hay", "She climbs the windmill"),
    ("gigi", "Back story", "What colour have Grape Stomper Gigi's feet been since that harvest she will not name?", "Purple", "Green", "Blue", "Orange"),
    ("shepherd", "Back story", "What does the Shepherd Squirrel guard with tremendous seriousness?", "One lamb", "A hundred sheep", "The windmill", "The château gate"),
    ("chevre", "Back story", "Where does the Chèvre Squirrel keep her goat cheese cool?", "Down the well", "In the river", "In the cellar", "Under a hay bale"),
    ("truffle", "Back story", "From how far away can the Truffle Hunter's pig find a truffle?", "Forty paces", "Four paces", "A mile", "Across the river"),
    ("pierre", "Back story", "What did Picnic Pierre take up the windmill with him?", "A baguette", "A ladder", "An umbrella", "A kite"),
    ("sylvain", "Back story", "Who gave up on waking Sleepy Sylvain years ago?", "Farmer Fernand, and the rooster", "The bees", "The Shepherd", "Picnic Pierre"),
    # ---------------------------------------------------------------- the books in the Librairie ----
    ("book_crumbs", "Book", "In The Spy Who Came In From the Crumbs, what was under the French Waiter's silver dome?", "One warm croissant", "A secret map", "A spy camera", "A cheese"),
    ("book_crumbs2", "Book", "In The Spy Who Came In From the Crumbs, where is the Spy's secret hideout?", "The third bench on the left", "Under the bridge", "In the bookshop", "Up the windmill"),
    ("book_tortue", "Book", "In La Tortue, who turns out to be La Tortue, the most feared fashion critic in France?", "Gérard the mailman", "Margaux", "Dale", "The French Waiter"),
    ("book_tortue2", "Book", "In La Tortue, what was Margaux's new collection called?", "PERDUE (Lost)", "BONJOUR", "TULSA", "LA TORTUE"),
    ("book_tortue3", "Book", "In La Tortue, what was in Dale's lost suitcase?", "More bathrobes, visors, one boot and one flip-flop", "A tuxedo", "A thousand acorns", "A map of Paris"),
    ("book_tortue4", "Book", "In La Tortue, how many houses are in the village of Saint-Bidule?", "Eleven", "One hundred", "Three", "Forty-four"),
    ("book_pierre", "Book", "In Picnic Pierre Will Not Come Down, who rode the windmill sail up to deliver Pierre's postcard?", "Gérard the mailman", "Farmer Fernand", "Grape Stomper Gigi", "The rooster"),
    ("book_pierre2", "Book", "In Picnic Pierre Will Not Come Down, who slept through the whole thing?", "Sleepy Sylvain", "Picnic Pierre", "The lamb", "The Beekeeper"),
    # ---------------------------------------------------------------- the game ----
    ("forest15", "The game", "How many squirrels are hiding in The Great Acorn Forest?", "15", "10", "44", "100"),
    ("street", "The game", "What is the name of the village street, across the bridge from the forest?", "Rue de Noisette", "Rue de Paris", "Acorn Avenue", "Rue du Château"),
    ("all44", "The game", "The game is called 1001 Squirrels. How many squirrels are really hiding in it?", "44", "1001", "100", "15"),
    # ---------------------------------------------------------------- riddles ----
    ("riddle_acorn", "Riddle", "I wear a little cap but have no head, and one day I may grow into a mighty tree. What am I?", "An acorn", "A mushroom", "A pinecone", "A hat"),
    ("riddle_piano", "Riddle", "What has keys but cannot open a single lock?", "A piano", "A map", "A mailbox", "A tree"),
    ("riddle_steps", "Riddle", "The more of these you take, the more you leave behind. What are they?", "Footsteps", "Acorns", "Letters", "Photos"),
    ("riddle_clock", "Riddle", "What has hands but can never clap?", "A clock", "A squirrel", "A tree", "A river"),
    # ---------------------------------------------------------------- the forest itself (board #1) ----
    ("toadstools", "The game", "What do the big red toadstools in the forest do?", "Bounce you sky high", "Give you acorns", "Make you shrink", "Sing when you touch them"),
    ("race", "The game", "In the Forest Race, what are you racing to do?", "Find all 15 forest squirrels", "Climb the tower", "Cross the river", "Collect 100 acorns"),
    ("bridge10", "The game", "How many forest squirrels must you find before the bridge to the Rue de Noisette opens?", "10", "5", "15", "44"),
    ("gray", "The game", "What happens to a squirrel when you find it?", "It turns from gray to full colour", "It runs away", "It falls asleep", "It disappears"),
    ("zipline", "The game", "Where does the zipline from the top of the forest tower take you?", "Out over the farm", "Into the river", "Back to the spawn", "Up to the moon"),
    ("slingshot", "The game", "What do you aim for with the slingshot in the forest?", "A hoop - sink an acorn and win three", "Pinecones", "Crows", "The tower bell"),
    # ---------------------------------------------------------------- the village (board #2) ----
    ("coffee", "The game", "Where can you drink a coffee that makes you run faster?", "At the café tables on the Rue de Noisette", "At the bookshop", "Up the windmill", "At the fountain"),
    ("postbox", "The game", "What can you send from the yellow post box outside La Poste?", "A letter to the dev", "A postcard to Paris", "An acorn", "A pigeon"),
    ("keeper", "The game", "Who becomes the Grand Keeper of the Day?", "The first player to find all 44 squirrels that day", "The mayor of the village", "The oldest squirrel", "Whoever has the most acorns"),
]

# Board #1 stands at the forest entrance, so its questions are the ones a brand-new player can find the answers to:
# the forest squirrels' own stories, the forest itself, and riddles. Everything else is for board #2 at La Poste.
FOREST_EXTRA = {"forest15", "all44", "street", "riddle_acorn", "riddle_piano", "riddle_steps", "riddle_clock",
                "toadstools", "race", "bridge10", "gray", "zipline", "slingshot"}
FOREST_BIOS = {"holmes", "rainy", "buccaneer", "scientist", "scientist2", "surfer", "nacho", "gordo", "fairy", "ski",
               "ballerina", "betty", "kite", "skydive", "birdwatch", "ranger"}


def board_of(qid):
    return "forest" if (qid in FOREST_EXTRA or qid in FOREST_BIOS) else "poste"


def lua_str(s):
    """a Lua string literal, ASCII only: anything else as decimal UTF-8 byte escapes"""
    out = ['"']
    for ch in s:
        if ch == '"':
            out.append('\\"')
        elif ch == "\\":
            out.append("\\\\")
        elif ord(ch) < 128:
            out.append(ch)
        else:
            out.append("".join("\\%d" % b for b in ch.encode("utf-8")))
    out.append('"')
    return "".join(out)


def main():
    ids = [q[0] for q in Q]
    assert len(ids) == len(set(ids)), "duplicate ids"
    for q in Q:
        assert len(q) == 7, q[0]
        assert len(set(q[3:])) == 4, ("answers not distinct", q[0])
    boards = {"forest": [], "poste": []}
    for q in Q:
        boards[board_of(q[0])].append(q)
    for b, seed in (("forest", 1001), ("poste", 2002)):          # a fixed shuffle each, so neighbouring days differ
        random.Random(seed).shuffle(boards[b])
    here = os.path.dirname(os.path.abspath(__file__))
    lines = ["-- QuestionBank: the Questions of the Day, one a day per board in this order (generated by village/question_bank.py - edit there).",
             "-- forest = board #1 at the forest entrance, poste = board #2 outside LA POSTE.",
             "-- a[1] is the right answer; the server shuffles the four for each player and never tells the client which is right.",
             "return {"]
    for b in ("forest", "poste"):
        lines.append("\t%s = {" % b)
        for q in boards[b]:
            lines.append("\t\t{id = %s, kind = %s, q = %s, a = {%s}}," % (lua_str(q[0]), lua_str(q[1]), lua_str(q[2]), ", ".join(lua_str(a) for a in q[3:])))
        lines.append("\t},")
    lines.append("}")
    src = "\n".join(lines) + "\n"
    assert all(ord(c) < 128 for c in src)
    io.open(os.path.join(here, "question_bank.lua"), "w", encoding="ascii", newline="\n").write(src)
    # the list for Shannon
    sections = []
    for b, title, where in (("forest", "Question of the Day #1", "the board at the forest entrance, by the spawn"),
                            ("poste", "Question of the Day #2", "the board outside La Poste on the Rue de Noisette")):
        rows = []
        for n, q in enumerate(boards[b], 1):
            rows.append("<tr><td class=n>%d</td><td class=k>%s</td><td>%s</td><td class=r>%s</td><td class=w>%s</td></tr>" % (
                n, html.escape(q[1]), html.escape(q[2]), html.escape(q[3]), html.escape(" / ".join(q[4:]))))
        sections.append("<h2>%s: %d questions</h2><p>On %s.</p><div class=wrap><table><tr><th>#</th><th>Type</th><th>Question</th><th>Right answer</th><th>Wrong answers</th></tr>\n%s\n</table></div>"
                        % (title, len(boards[b]), where, "\n".join(rows)))
    page = """<!doctype html><html lang=en><head><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>Question of the Day list</title>
<style>
:root{--bg:#fbf7ee;--ink:#2e2418;--dim:#7a6a55;--line:#e3d8c3;--ok:#2f7a3a;--head:#3a2d50}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#1d1a24;--ink:#efe8da;--dim:#b3a78f;--line:#3a3446;--ok:#7fd48a;--head:#e8d9ff}}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 system-ui,Segoe UI,sans-serif}
main{max-width:1100px;margin:0 auto;padding:20px 16px 40px}
h1{font-size:22px;margin:0 0 4px;color:var(--head)} h2{font-size:18px;margin:26px 0 2px;color:var(--head)} p{margin:0 0 12px;color:var(--dim)}
.wrap{overflow-x:auto} table{border-collapse:collapse;width:100%;min-width:720px}
th,td{padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top;text-align:left}
th{font-size:13px;color:var(--dim);font-weight:600} .n{color:var(--dim);width:28px} .k{white-space:nowrap;color:var(--dim)}
.r{color:var(--ok);font-weight:600;min-width:150px} .w{color:var(--dim)}
</style></head><body><main>
<h1>Questions of the Day</h1>
<p>Two a day, one on each board, in this order, then each list starts again. Green is the right answer; players see the four in a shuffled order.</p>
{{SECTIONS}}
</main></body></html>
""".replace("{{SECTIONS}}", "\n".join(sections))
    io.open(os.path.join(here, "question_list.html"), "w", encoding="utf-8", newline="\n").write(page)
    print("forest %d, poste %d" % (len(boards["forest"]), len(boards["poste"])))


if __name__ == "__main__":
    main()
