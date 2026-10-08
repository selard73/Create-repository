"""Builds the Porto squirrel batch picture page (index.html + img/*.jpg) from SECTIONS below.
Run: python build_page.py   -> writes porto_batch.html and img/ next to this file."""
import os, html
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SQ = r"C:\Users\slard\roblox-props\squirrels"
os.makedirs(os.path.join(HERE, "img"), exist_ok=True)

def jpg(src, name, w=700):
    im = Image.open(src).convert("RGB")
    if im.size[0] > w: im = im.resize((w, int(im.size[1] * w / im.size[0])), Image.LANCZOS)
    im.save(os.path.join(HERE, "img", name), quality=86)
    return "img/" + name

# newest first; status: "ok" (approved/done), "wait" (needs her), "work" (in progress)
SECTIONS = [
    {
        "id": "worldmap", "area": "The map", "no": "new chart",
        "title": "The whole of Porto Nocciola on the map", "status": ("wait", "Drawn, not in the game yet. Your OK?"),
        "imgs": [(r"C:\Users\slard\roblox-props\italy\map\world_chart2.png", "world_chart2_s.jpg", "The new chart (same parchment style): France at the bottom unchanged, the gorge and falls, then the harbour, the hillside town with Piazza del Limone and its fountain, the church, the funicular, the lemon and olive terraces, the olive grove, the meadow, the watchtower, the pebble cove and the lighthouse at the tip. No writing on it: the game puts the name plates and counts on top"),
                 (os.path.join(HERE, "img", "drone_fixed.jpg"), "drone_fixed_s.jpg", "Your fix: the drone now hovers about 4 studs in front of the Drone Flyer, a little above his head (Studio view)")],
        "facts": [("In the game", "Each area gets its own name plate and count: The Harbour 15, Via della Piazza 15, The Groves 14; a '?' covers an area until you can go there; the 'You are here' dot works everywhere in Porto"),
                  ("Fixed tonight", "Feet: every squirrel now stands exactly where it was placed (the keeper and his wife were 0.2 studs into the stone). The count: 88 / 88 (Pogo, the Baker, the Sassy Shopper and Pizza Delivery had '_2' ids; old finds now count). Butterfly Catcher: head still, no pulling. Butterflies: rounded front and back wings that sweep up and down. Drone: in front of him"),
                  ("Checked", "Play test: all four fixes measured; 88 squirrels, Porto 44; the drone 4.2 studs in front, 1.4 above his head")],
        "notes": ["Next after your OK: upload the chart (two halves, Roblox's 1024-pixel limit), switch the map to it, add the three area plates, then a phone check of the map."],
    },
    {
        "id": "butterfly", "area": "The Groves", "no": "14 of 15",
        "title": "Butterfly Catcher Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "butterfly_placed.jpg"), "butterfly_placed_s.jpg", "Placed (your spot): running through the windflower patch with her net up, the keeper's cottage on the left (Studio view, drawn small in Edit mode; the butterflies show as thin slivers here because they only flap in play)"),
                 (os.path.join(SQ, "butterfly_squirrel", "turn_q34.png"), "butterfly_q34.jpg", "Head turned, three-quarter view: the net, hoop and handle stay in her paws; hat and face turn together")],
        "facts": [("Name", "Butterfly Catcher Squirrel"),
                  ("Bio", "Has never caught a single butterfly. Her net has caught three hats and a sandwich."),
                  ("Spot", "The windflower patch of the meadow, between the Drone Flyer and the keeper's cottage, facing the meadow path"),
                  ("Butterflies", "Blue, orange and yellow, flapping and looping round the top of her net at head height. Play-tested: all three move (the first version stood still because the game loads them a moment after the script starts; fixed)")],
        "notes": ["Calico fur, green bucket hat with a daisy, floral shirt, green shorts, a satchel with a butterfly on it, a big butterfly net."],
    },
    {
        "id": "guitar", "area": "The Groves", "no": "13 of 15",
        "title": "Guitarist Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "guitar_placed_back.jpg"), "guitar_placed_back_s.jpg", "Placed (your spot): in the olive grove, mid-hop, playing toward the Olive Picker on his crate (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "guitar_placed_front.jpg"), "guitar_placed_front_s.jpg", "From the front: eyes closed, playing"),
                 (os.path.join(SQ, "guitarist_squirrel", "turn_q34.png"), "guitar_q34.jpg", "Head turned, three-quarter view: the guitar stays in his paws, the hat turns with his head")],
        "facts": [("Name", "Guitarist Squirrel"),
                  ("Bio", "Knows one song. He plays it very well, and very often."),
                  ("Spot", "The olive grove shade, about 6 studs from the Olive Picker, playing to him")],
        "notes": ["Wide black hat with a feather, red neckerchief, white shirt and dark waistcoat, eyes closed, mid-hop with a small guitar."],
    },
    {
        "id": "glass", "area": "The Groves", "no": "12 of 15",
        "title": "Sea Glass Collector Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "glass_placed.jpg"), "glass_placed_s.jpg", "Placed and turned (your fix): on the sand at the bottom of the Beach steps, facing people as they step off the stairs, sea glass held up to the light (Studio view, drawn small in Edit mode)"),
                 (os.path.join(SQ, "seaglass_squirrel", "turn_q34.png"), "glass_q34.jpg", "Head turned, three-quarter view: the sea glass and basket stay in her paws")],
        "facts": [("Name", "Sea Glass Collector Squirrel"),
                  ("Bio", "Has a jar of sea glass for every colour of the sea. She is still looking for the purple one."),
                  ("Spot", "The sandy north end of the pebble cove, beside the bottom of the Beach steps")],
        "notes": ["Teal knotted top, khaki shorts, sandals with a little flower, a woven basket of sea glass, one green piece held up to the light."],
    },
    {
        "id": "drone", "area": "The Groves", "no": "11 of 15",
        "title": "Drone Flyer Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "drone_placed.jpg"), "drone_placed_s.jpg", "Placed (your spot): the open middle of the meadow, controller in his paws, his drone hovering above and in front of him (Studio view, drawn small in Edit mode). Play-tested: the drone bobs and drifts about 2.2 to 2.9 studs above his head, no errors"),
                 (os.path.join(SQ, "droneflyer_squirrel", "turn_q34.png"), "drone_q34.jpg", "Head turned, three-quarter view: the controller stays in his paws")],
        "facts": [("Name", "Drone Flyer Squirrel"),
                  ("Bio", "His drone has been to the top of the lighthouse more often than the lighthouse keeper."),
                  ("Spot", "The open middle of the Prato dei Fiori meadow, facing people coming down from the town"),
                  ("Drone", "Your Meshy drone, 1.8 studs wide, can't be clicked or bumped into; it only animates when a player is within 160 studs")],
        "notes": ["Gray fur, teal cap with a drone badge, teal jacket, white T-shirt, black cargo shorts, teal sneakers, a remote controller."],
    },
    {
        "id": "photo", "area": "The Groves", "no": "10 of 15",
        "title": "Photographer Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "photo_placed_back.jpg"), "photo_placed_back_s.jpg", "Placed (your pick): on the grassy rise of the meadow, camera aimed at the lighthouse with the keeper by its door in the shot (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "photo_placed_front.jpg"), "photo_placed_front_s.jpg", "From the lighthouse side: he is taking your picture; the keeper's wife by her cottage behind him"),
                 (os.path.join(SQ, "photographer_squirrel", "rest_close.png"), "photo_rest.jpg", "Close-up: one eye to the camera, the other winking. His head stays still (NoHeadAnim) so the camera never leaves his eye; his tail still sways")],
        "facts": [("Name", "Photographer Squirrel"),
                  ("Bio", "Always says one more. It is never one more."),
                  ("Spot", "The grassy rise of the meadow north of the lighthouse, shooting the lighthouse and its keeper")],
        "notes": ["Khaki safari vest and cargo shorts, hiking shoes, a big black camera with a red strap, a camera bag at his hip."],
    },
    {
        "id": "wife", "area": "The Groves", "no": "9 of 15",
        "title": "The Lighthouse Keeper's Wife", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "wife_placed.jpg"), "wife_placed_s.jpg", "Placed: on the cottage's stone path with her laundry basket, facing people coming up the path. Note: she is on the window side of the door (left as you look at the house), not the right as I wrote; the right side is narrower and drops to grass. Say if you want her moved (Studio view, drawn small in Edit mode)"),
                 (os.path.join(SQ, "keeperswife_squirrel", "turn_q34.png"), "wife_q34.jpg", "Head turned, three-quarter view: the laundry basket, apron and dress stay put"),
                 (os.path.join(SQ, "keeperswife_squirrel", "turn_close.png"), "wife_close.jpg", "Close-up, head turned: bandana, ears and whiskers move together")],
        "facts": [("Name", "The Lighthouse Keeper's Wife"),
                  ("Bio", "Married the lighthouse keeper for the view. Stayed for the laundry. There is a lot of laundry."),
                  ("Spot", "The keeper's cottage by the lighthouse, on the stone path beside the green front door")],
        "notes": ["Red anchor-print bandana, blue dress, cream apron with an anchor, a basket of folded laundry."],
    },
    {
        "id": "keeper", "area": "The Groves", "no": "8 of 15",
        "title": "Lighthouse Keeper Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "keeper_placed.jpg"), "keeper_placed_s.jpg", "Placed (your spot): on the round stone base of the Faro di Porto Nocciola beside the green door, lantern in hand, facing the meadow path (Studio view, drawn small in Edit mode)"),
                 (os.path.join(SQ, "lighthousekeeper_squirrel", "turn_q34.png"), "keeper_q34.jpg", "Head turned, three-quarter view: the lantern, binoculars and coat stay put"),
                 (os.path.join(SQ, "lighthousekeeper_squirrel", "turn_close.png"), "keeper_close.jpg", "Close-up, head turned: cap, ears and whiskers move together; the raised paw keeps hold of the lantern")],
        "facts": [("Name", "Lighthouse Keeper Squirrel"),
                  ("Bio", "Has kept the light burning for forty years. Carries a lantern anyway, in case the lighthouse forgets."),
                  ("Spot", "The lighthouse's round stone base, just right of the door, facing the meadow path")],
        "notes": ["White captain's cap with a lighthouse badge, navy coat with brass buttons, striped jumper, binoculars, a lantern."],
    },
    {
        "id": "treasure", "area": "The Groves", "no": "7 of 15",
        "title": "Treasure Hunter Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "treasure_placed.jpg"), "treasure_placed_s.jpg", "Placed (your spot): on the pebble beach, sweeping his detector toward the water (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "treasure_beach.jpg"), "treasure_beach_s.jpg", "From the Beach steps: the snorkeler at the water's edge (left) and the treasure hunter (right), both well clear of the cave"),
                 (os.path.join(SQ, "treasurehunter_squirrel", "turn_q34.png"), "treasure_q34.jpg", "Head turned, three-quarter view: the detector, backpack and tail stay put; whiskers turn with his head")],
        "facts": [("Name", "Treasure Hunter Squirrel"),
                  ("Bio", "Has found forty-two bottle caps, a spoon and someone's car keys. The treasure is still out there."),
                  ("Spot", "The pebble beach near the foot of the Beach steps, sweeping toward the water")],
        "notes": ["Safari hat with a brass buckle, Hawaiian shirt, cargo shorts, flip-flops, a khaki backpack and a metal detector."],
    },
    {
        "id": "star", "area": "The Groves", "no": "6 of 15",
        "title": "Stargazer Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "star_placed_side.jpg"), "star_placed_side_s.jpg", "Placed (your spot): on the open grass at the meadow's west edge, eye to the telescope, aimed up and south-west over the sea (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "star_placed_back.jpg"), "star_placed_back_s.jpg", "From the meadow path: looking out to sea through his telescope"),
                 (os.path.join(SQ, "stargazer_squirrel", "turn_q34.png"), "star_q34.jpg", "Head turned, three-quarter view: the telescope and tripod stay put")],
        "facts": [("Name", "Stargazer Squirrel"),
                  ("Bio", "Has discovered three new stars. Two of them were the lighthouse."),
                  ("Spot", "The open grass at the west edge of the Prato dei Fiori meadow, above the sea")],
        "notes": ["Navy cap and fleece vest, binoculars, a small canvas bag, a brass-trimmed telescope on a wooden tripod."],
    },
    {
        "id": "diver", "area": "The Groves", "no": "5 of 15",
        "title": "Cliff Diver Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "diver_placed_front.jpg"), "diver_placed_front_s.jpg", "Placed (your spot): on the east point, at the end of the flat rock by the olive tree, ready to dive, the lighthouse behind (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "diver_placed_back.jpg"), "diver_placed_back_s.jpg", "From the land side: he faces straight out to sea over the 58-stud drop"),
                 (os.path.join(HERE, "img", "diver_cliff_sea.jpg"), "diver_cliff_sea_s.jpg", "The cliff from the sea"),
                 (os.path.join(SQ, "cliffdiver_squirrel", "turn_q34.png"), "diver_q34.jpg", "Head turned, three-quarter view: goggles, ears and whiskers move with his head; arms stay swept back")],
        "facts": [("Name", "Cliff Diver Squirrel"),
                  ("Bio", "Scores his own dives out of ten. They have all been tens."),
                  ("Spot", "The rocky point on the east side of The Groves, above a sheer drop into deep water")],
        "notes": ["Leaning forward, arms swept back, goggles on his forehead, striped swim shorts.",
                  "The olive tree beside him floats about 2 studs above the rock (it was like that before). Say if you want it set down."],
    },
    {
        "id": "hiker", "area": "The Groves", "no": "4 of 15",
        "title": "Hiker Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "hiker_placed.jpg"), "hiker_placed_s.jpg", "Placed (your spot): on the grass where the tower path leaves the main path, the Torre di Guardia beside him, facing people coming down from the town (Studio view, drawn small in Edit mode)"),
                 (os.path.join(SQ, "hiker_squirrel", "turn_q34.png"), "hiker_q34.jpg", "Head turned, three-quarter view: walking stick, backpack and tail stay put"),
                 (os.path.join(SQ, "hiker_squirrel", "turn_close.png"), "hiker_close.jpg", "Close-up, head turned: hat, ears and face move together; the backpack strap and map stay on his back")],
        "facts": [("Name", "Hiker Squirrel"),
                  ("Bio", "Packed for a three-day trek. The watchtower is a four-minute walk."),
                  ("Spot", "The grass corner where the tower path leaves the main path, just inside The Groves")],
        "notes": ["Ranger hat with a mountain badge, green vest, cargo shorts, hiking boots, a walking stick, a backpack with a rolled map and a water bottle."],
    },
    {
        "id": "snorkel", "area": "The Groves", "no": "3 of 15",
        "title": "Snorkel Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "snorkel_placed_front.jpg"), "snorkel_placed_front_s.jpg", "Placed (your spot): on the pebble beach at the water's edge, fins flat on the stones, facing the sea; the Beach steps behind him (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "snorkel_placed_steps.jpg"), "snorkel_placed_steps_s.jpg", "Coming down the Beach steps: he is at the waterline looking out to sea"),
                 (os.path.join(SQ, "snorkel_squirrel", "turn_q34.png"), "snorkel_q34.jpg", "Head turned, three-quarter view: mask and snorkel turn with his head, paws stay on the straps"),
                 (os.path.join(SQ, "snorkel_squirrel", "turn_close.png"), "snorkel_close.jpg", "Close-up, head turned away: the snorkel stays on the mask")],
        "facts": [("Name", "Snorkel Squirrel"),
                  ("Bio", "Has seen every fish in the bay. He has named all of them Gerald."),
                  ("Spot", "Spiaggia dei Ciottoli, the pebble cove under the west cliffs: at the water's edge near the foot of the Beach steps, facing the sea, well away from the cave")],
        "notes": ["Mask on his forehead, blue snorkel, orange-strapped backpack, shark-print swim shorts, orange and black fins.",
                  "The cave stays free for the octopus and the captured squirrels."],
    },
    {
        "id": "olive", "area": "The Groves", "no": "2 of 15",
        "title": "Olive Picker Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "olive_placed_west.jpg"), "olive_placed_west_s.jpg", "Turned to face the grove path (your fix): on his crate under the small olive tree, reaching up into it (Studio view, drawn small in Edit mode; in play his fist ends just under the tree's pair of olives)"),
                 (os.path.join(SQ, "olivepicker_squirrel", "turn_q34.png"), "olive_q34.jpg", "Head turned, three-quarter view: the raised arm and the basket stay put"),
                 (os.path.join(SQ, "olivepicker_squirrel", "turn_close.png"), "olive_close.jpg", "Close-up, head turned: cap, ears and whiskers move with his head, the arm stays clean")],
        "facts": [("Name", "Olive Picker Squirrel"),
                  ("Bio", "Picks one olive for the basket and one for himself. The basket is still empty."),
                  ("Spot", "The olive grove in The Groves, under the small tree nearest the path, facing the path, standing on a crate (a copy of the terraces' orchard crate, on its side, 1.7 high)"),
                  ("Reach", "In the game his fist ends about 0.2 studs under the tree's own pair of olives")],
        "notes": ["Grey-brown fur, green cap and overalls, cream shirt, a tea towel at his belt, an empty basket."],
    },
    {
        "id": "lemon", "area": "The Groves", "no": "1 of 15",
        "title": "Lemon Seller Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "lemon_placed.jpg"), "lemon_placed_s.jpg", "Placed (your spot A): seen from the top of the Salita degli Ulivi stairs. He stands beside the crate of lemons, facing the stairs, the olive tree behind him (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "lemon_placed_close.jpg"), "lemon_placed_close_s.jpg", "Closer: straw hat, basket of lemons, both feet flat on the grass (ground under his feet differs by under 0.1 stud)"),
                 (os.path.join(SQ, "lemonseller_squirrel", "turn_q34.png"), "lemon_q34.jpg", "Head turned, three-quarter view"),
                 (os.path.join(SQ, "lemonseller_squirrel", "turn_close.png"), "lemon_close.jpg", "Close-up, head turned: hat, ears and face move together; the basket stays in his paws")],
        "facts": [("Name", "Lemon Seller Squirrel"),
                  ("Bio", "Swears every lemon in his basket came off the tree behind him. The tree behind him is an olive tree."),
                  ("Spot", "Top terrace of the lemon and olive terraces, beside the crate of lemons at the top of the Salita degli Ulivi stairs, facing people as they come up"),
                  ("Zone", "The terraces (x 617 to 800, z -949 to -756) are now a Groves zone, so standing by him shows The Groves list. The rest of Via della Piazza is unchanged")],
        "notes": ["Straw hat, green overalls and apron, a big basket of lemons.",
                  "The lowest terrace (the one with the lemon trees) has its own crate and LIMONETO sign buried in the rock at its north end. Say if you want them dug out."],
    },
    {
        "id": "postcard", "area": "Via della Piazza", "no": "15 of 15",
        "title": "Postcard Squirrel", "status": ("wait", "Placed in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "post_placed.jpg"), "post_placed_s.jpg", "Placed halfway up the Sentiero del Faro, moved 1.3 studs off the sea railing (your note), facing people coming up from the harbour (Studio view, drawn small in Edit mode)"),
                 (os.path.join(SQ, "postcard_squirrel", "turn_q34.png"), "post_q34.jpg", "Head turned, three-quarter view"),
                 (os.path.join(SQ, "postcard_squirrel", "rest_close.png"), "post_rest.jpg", "Close-up, head straight"),
                 (os.path.join(SQ, "postcard_squirrel", "turn_close.png"), "post_close.jpg", "Same camera, head turned: the postcard fan stays in his paw, his cheek turns with his head")],
        "facts": [("Name", "Postcard Squirrel"),
                  ("Bio", "Sells postcards of the view to people standing in front of the view. Business is excellent."),
                  ("Spot", "Halfway up the Sentiero del Faro, the stone path by the water to the lighthouse: on its sea-side edge at about y -17, facing people coming up from the harbour (inside Via della Piazza's coastal zone, so he counts there)")],
        "notes": ["Flat cap, green waistcoat, a satchel of postcards, a fan of cards in one paw and a display board of six in the other.",
                  "To import: postcard_squirrel_color.fbx and postcard_squirrel_gray.fbx (roblox-props\\squirrels\\postcard_squirrel)."],
    },
    {
        "id": "clockmaker", "area": "Via della Piazza", "no": "14 of 15",
        "title": "Clock Keeper Squirrel", "status": ("wait", "On his balcony in Studio, not published"),
        "imgs": [(os.path.join(HERE, "img", "clock_placed.jpg"), "clock_placed_s.jpg", "On his new balcony under the west clock (a copy of the town's balconies, flower box taken off so he shows), drawn here at his game size"),
                 (os.path.join(SQ, "clockmaker_squirrel", "turn_q34.png"), "clock_q34.jpg", "Head turned, three-quarter view"),
                 (os.path.join(SQ, "clockmaker_squirrel", "rest_close.png"), "clock_rest.jpg", "Close-up, head straight"),
                 (os.path.join(SQ, "clockmaker_squirrel", "turn_close.png"), "clock_close.jpg", "Same camera, head turned: glasses, whiskers and face move together; the key stays in his paw")],
        "facts": [("Name", "Clock Keeper Squirrel"),
                  ("Bio", "Winds the town clock every morning at seven. It runs ten minutes fast, and so does he."),
                  ("Spot", "A new balcony under the clock on the Torre dell'Orologio, facing the fountain; clickable from the foot of the tower (32-stud reach)")],
        "notes": ["Standing, with a brass winding key, an oil can, round glasses and a flat cap.",
                  "Rig: the key was picked out as its own piece (a gold-colour filter caught his glasses' gold arm and smeared it), so his whiskers and glasses stay with his head.",
                  "To import: clockmaker_squirrel_color.fbx and clockmaker_squirrel_gray.fbx (roblox-props\\squirrels\\clockmaker_squirrel)."],
    },
    {
        "id": "churchmouse", "area": "Via della Piazza", "no": "13 of 15",
        "title": "The Church Mouse's Cousin", "status": ("wait", "Placed in Studio. Try it in a play test"),
        "imgs": [(os.path.join(HERE, "img", "mouse_placed.jpg"), "mouse_placed_s.jpg", "Placed in front of the Chiesa di Santa Marina, beside the arched doors and the bench, facing the forecourt (Studio view, drawn small in Edit mode)"),
                 (os.path.join(SQ, "church_mouse_cousin", "turn_q34.png"), "mouse_q34.jpg", "Head turned, three-quarter view"),
                 (os.path.join(SQ, "church_mouse_cousin", "rest_close.png"), "mouse_rest.jpg", "Close-up, head straight"),
                 (os.path.join(SQ, "church_mouse_cousin", "turn_close.png"), "mouse_close.jpg", "Same camera, head turned: cap, ears and face move together")],
        "facts": [("Name", "The Church Mouse's Cousin (the French one is The Church Mouse, at the Chateau's chapel)"),
                  ("Bio", "Quiet as a church mouse. No one has had the heart to tell him he isn't a squirrel."),
                  ("Spot", "In front of the Chiesa di Santa Marina doors, a little to one side, facing the forecourt")],
        "notes": ["An actual mouse: big round ears, flat cap, waistcoat, a red prayer book held to his chest, a thin pink tail.",
                  "The prayer book and paws are pinned to his chest; the tail bones only take the tail.",
                  "To import: church_mouse_cousin_color.fbx and church_mouse_cousin_gray.fbx (roblox-props\\squirrels\\church_mouse_cousin)."],
    },
    {
        "id": "pizzamaker", "area": "Via della Piazza", "no": "12 of 15",
        "title": "Chef Nutmeg, the Pizza Maker", "status": ("wait", "Placed in Studio. Try it in a play test"),
        "imgs": [(os.path.join(HERE, "img", "table_pizza.jpg"), "table_pizza_s.jpg", "Pizzeria table 1, beside him: a pizza on a wooden board with two slices cut out, one on each plate, the espresso cup between them"),
                 (os.path.join(HERE, "img", "chef_dough.jpg"), "chef_dough_s.jpg", "Placed at the pizzeria front with his pizza dough: a plain pale base with a puffy rim, no toppings, flying above his raised paw (Studio view, drawn small in Edit mode). In play each toss lands back on his paw and flies about 3 studs up, spinning, every 1.5 s"),
                 (os.path.join(SQ, "pizzamaker_squirrel", "turn_q34.png"), "chef_q34.jpg", "Head turned, three-quarter view"),
                 (os.path.join(SQ, "pizzamaker_squirrel", "rest_close.png"), "chef_rest.jpg", "Close-up, head straight"),
                 (os.path.join(SQ, "pizzamaker_squirrel", "turn_close.png"), "chef_close.jpg", "Same camera, head turned away: the orange band is his own cheek fluff seen side-on, not a stretch")],
        "facts": [("Name", "Chef Nutmeg (Meshy's name for him)"),
                  ("Bio", "Spins every pizza over his head before it goes in the oven. Most of them come back down."),
                  ("Spot", "In front of the Pizzeria della Piazza shopfront, just south of its café table, facing the fountain"),
                  ("Dough", "Plain pizza dough (no toppings) floating above his raised paw, spinning and tossed up and down")],
        "notes": ["Both paws are pinned to his chest; the raised paw was picked out as one connected piece so his cheek next to it still turns with his head.",
                  "To import: pizzamaker_squirrel_color.fbx and pizzamaker_squirrel_gray.fbx (roblox-props\\squirrels\\pizzamaker_squirrel)."],
    },
    {
        "id": "accordion", "area": "Via della Piazza", "no": "11 of 15",
        "title": "Nino, the Accordion Player", "status": ("wait", "Placed in Studio. Try it in a play test"),
        "imgs": [(os.path.join(HERE, "img", "duo_lemon.jpg"), "duo_lemon_s.jpg", "Your lemon tree: potted, in the corner where the yellow wall ends, close to the edge"),
                 (os.path.join(HERE, "img", "duo_fixed.jpg"), "duo_fixed_s.jpg", "Your fix: Nino and the Fat Lady both face straight out into the square, each about 0.8 studs farther from the wall (Studio view, drawn small in Edit mode)"),
                 (os.path.join(SQ, "accordion_squirrel", "turn_q34.png"), "acc_q34.jpg", "Head turned, three-quarter view"),
                 (os.path.join(SQ, "accordion_squirrel", "turn_close.png"), "acc_close.jpg", "Close-up with the head turned away")],
        "facts": [("Name", "Nino the Accordion Player"),
                  ("Bio", "Has played for the Fat Lady for thirty years. He has never once heard the end of a song."),
                  ("Spot", "Beside the Fat Lady at the yellow pizzeria wall in Piazza del Limone, both facing the square")],
        "notes": ["The accordion, straps and both paws are pinned to his chest; the face stays clean on a head turn.",
                  "Style: this model came from the furry 9:40 picture, so he has textured fur and longer legs than the flat-style squirrels. The flat cutout (Downloads\\accordion_squirrel_for_meshy.png) is there if you want a matching remake.",
                  "To import: accordion_squirrel_color.fbx and accordion_squirrel_gray.fbx (roblox-props\\squirrels\\accordion_squirrel)."],
    },
    {
        "id": "broomseller", "area": "Via della Piazza", "no": "10 of 15",
        "title": "Broomtail Squirrel, the Broom Seller", "status": ("wait", "Moved up the steps. Your look?"),
        "imgs": [(os.path.join(HERE, "img", "scopa_up.jpg"), "scopa_up_s.jpg", "Moved one story up (your spot): the walkway at the top of the Scalinata dei Fiori by the lilac house, cart along the edge with its sign to the stairs, walkway left open (Studio view, drawn small in Edit mode)"),
                 (os.path.join(HERE, "img", "scopa_placed.jpg"), "scopa_placed_s.jpg", "Placed (Studio view; he is drawn smaller in Edit mode and grows to game size in play): lilac house, right of door 27, cart on his left with the lettered sign"),
                 (os.path.join(SQ, "broomseller_squirrel", "turn_q34.png"), "broom_q34.jpg", "Head turned, three-quarter view"),
                 (os.path.join(SQ, "broomseller_squirrel", "turn_close.png"), "broom_close.jpg", "Close-up with the head turned away"),
                 (r"C:\Users\slard\roblox-props\props\broomcart\light_q34.png", "cart_q34.jpg", "His cart (Meshy, 18k triangles). The scribbled sign gets real lettering in Studio"),
                 (r"C:\Users\slard\roblox-props\props\broomcart\light_front.png", "cart_side.jpg", "Cart from the side"),
],
        "facts": [("Name", "Broomtail Squirrel (renamed from Signor Scopa)"),
                  ("Bio", "Every broom comes with a free demonstration. So does your doorstep, whether you asked or not."),
                  ("Spot", "Top of the Scalinata dei Fiori (one story up from the lilac-house street), on the walkway near the upper street")],
        "notes": ["The broom and both paws are pinned to his chest, so they stay put when he turns his head.",
                  "Colours sharpened the same way as the harbour squirrels.",
                  "To import: broomseller_squirrel_color.fbx and broomseller_squirrel_gray.fbx (roblox-props\\squirrels\\broomseller_squirrel) and broomcart.fbx (roblox-props\\props\\broomcart)."],
    },
]
EXTRA = """
<section class="sq" id="calf">
  <header class="sq-head">
    <p class="eyebrow">The bay · your idea</p>
    <h2>The whale calf</h2>
    <span class="chip chip-wait">In Studio, not published</span>
  </header>
  <div class="figs"><figure><img src="img/whale_calf_s.jpg" alt="The mama whale and her calf side by side in the bay, seen from behind" loading="lazy"><figcaption>Mama and calf from behind: her big flukes in front, the calf's small back and tail beside her</figcaption></figure></div>
  <dl class="facts">
    <dt>Size</dt><dd>A copy of the mama at 0.42 scale: about 25 studs long (she is 60).</dd>
    <dt>Swims</dt><dd>On her route, 14 studs to her side (the open-sea side, away from the shore) and 1.2 s behind her; they stop side by side at the blow stations.</dd>
    <dt>Spout</dt><dd>A smaller spout a beat after hers, and a higher, softer blow sound.</dd>
    <dt>Checked</dt><dd>Play test: side gap 14.0 studs at the blow stop and while swimming, no errors.</dd>
  </dl>
</section>
<section class="sq" id="phonehud">
  <header class="sq-head">
    <p class="eyebrow">Phones · your notes</p>
    <h2>Squirrel panel, cards and the title pill</h2>
    <span class="chip chip-wait">Fixed in Studio, measured on a 666 x 374 phone, not published yet</span>
  </header>
  <dl class="facts">
    <dt>Windows</dt><dd>The album and the card start just under the top icons (y 64 instead of 114) and end above the tool bar where they did; they sit on top of everything, covering the Hint button.</dd>
    <dt>Card</dt><dd>Measured: card y 76 to 281, name y 120 to 158, bio y 167 to 245 (no overlap), bio text about 19 px on screen (was about 12), both arrows and the close button fully on screen.</dd>
    <dt>Panel</dt><dd>The panel was 10 px too narrow, so each row wrapped one tile early and the last squirrel hung out of the box. Measured: 15 harbour tiles, the last row ends at y 227, the Album button starts at 235.</dd>
    <dt>Title pill</dt><dd>It now fits the real gap between the Roblox buttons and the four icons. Measured: x 216 to 430 (Roblox buttons end at 208, Passport starts at 440), "Squirrel Maestro" at full size.</dd>
    <dt>Hint</dt><dd>Top left under the Roblox menu, x 12 to 116, y 64 to 104.</dd>
  </dl>
</section>"""

def chip(st):
    k, t = st
    return f'<span class="chip chip-{k}">{html.escape(t)}</span>'

def section(s):
    figs = "".join(
        f'<figure><img src="{jpg(src, name)}" alt="{html.escape(cap)}" loading="lazy"><figcaption>{html.escape(cap)}</figcaption></figure>'
        for src, name, cap in s["imgs"])
    facts = "".join(f"<dt>{html.escape(k)}</dt><dd>{html.escape(v)}</dd>" for k, v in s["facts"])
    notes = "".join(f"<li>{html.escape(n)}</li>" for n in s.get("notes", []))
    return f"""
<section class="sq" id="{s['id']}">
  <header class="sq-head">
    <p class="eyebrow">{html.escape(s['area'])} · squirrel {html.escape(s['no'])}</p>
    <h2>{html.escape(s['title'])}</h2>
    {chip(s['status'])}
  </header>
  <div class="figs">{figs}</div>
  <dl class="facts">{facts}</dl>
  {f'<ul class="notes">{notes}</ul>' if notes else ''}
</section>"""

page = f"""<title>Porto Squirrel Batch</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600&family=Nunito+Sans:opsz,wght@6..12,400;6..12,600&display=swap">
<style>
/* layout: one column of squirrel sheets, newest first; renders side by side, stacking on phones */
:root {{
  --bg: #f3f1ea; --paper: #fffdf7; --ink: #2b2433; --muted: #6c6474; --line: #e2dccd;
  --sea: #1f6f8b; --lemon: #e8b931; --ok: #3f8f5a; --wait: #b7791f; --work: #1f6f8b;
  --display: "Fredoka", "Trebuchet MS", system-ui, sans-serif;
  --body: "Nunito Sans", "Segoe UI", system-ui, sans-serif;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
  --bg: #1b1a22; --paper: #24222d; --ink: #f1ece2; --muted: #a9a2b2; --line: #39364a;
  --sea: #6fb7d1; --lemon: #f0c94e; --ok: #6cc28a; --wait: #e2a94a; --work: #6fb7d1; color-scheme: dark }} }}
:root[data-theme="dark"] {{
  --bg: #1b1a22; --paper: #24222d; --ink: #f1ece2; --muted: #a9a2b2; --line: #39364a;
  --sea: #6fb7d1; --lemon: #f0c94e; --ok: #6cc28a; --wait: #e2a94a; --work: #6fb7d1; color-scheme: dark }}
body {{ background: var(--bg); color: var(--ink); font-family: var(--body); font-size: 16px; line-height: 1.55; }}
.wrap {{ max-width: 980px; margin: 0 auto; padding-inline: 16px; padding-block: 28px 56px; display: grid; gap: 28px; }}
.top h1 {{ font-family: var(--display); font-weight: 600; font-size: clamp(28px, 5vw, 40px); margin: 0; text-wrap: balance; }}
.top p {{ margin: 6px 0 0; color: var(--muted); max-width: 62ch; }}
.tally {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 14px; }}
.tally span {{ font-family: var(--display); font-weight: 500; font-size: 15px; padding: 4px 12px; border-radius: 999px; background: var(--paper); border: 1px solid var(--line); font-variant-numeric: tabular-nums; }}
.sq {{ background: var(--paper); border: 1px solid var(--line); border-radius: 18px; padding: 20px; display: grid; gap: 16px; }}
.sq-head {{ display: grid; gap: 4px; justify-items: start; }}
.eyebrow {{ margin: 0; font-size: 13px; letter-spacing: .06em; text-transform: uppercase; color: var(--sea); font-weight: 600; }}
.sq h2 {{ font-family: var(--display); font-weight: 600; font-size: 28px; margin: 0; }}
.chip {{ font-size: 14px; font-weight: 600; padding: 3px 12px; border-radius: 999px; border: 1.5px solid currentColor; }}
.chip-ok {{ color: var(--ok); }} .chip-wait {{ color: var(--wait); }} .chip-work {{ color: var(--work); }}
.figs {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 14px; }}
figure {{ margin: 0; display: grid; gap: 6px; }}
figure img {{ width: 100%; border-radius: 12px; border: 1px solid var(--line); background: #eef0f3; }}
figcaption {{ font-size: 13px; color: var(--muted); }}
.facts {{ display: grid; grid-template-columns: max-content 1fr; gap: 6px 16px; margin: 0; }}
.facts dt {{ font-weight: 600; color: var(--muted); }}
.facts dd {{ margin: 0; min-width: 0; }}
.notes {{ margin: 0; padding-left: 20px; color: var(--muted); display: grid; gap: 4px; }}
@media (max-width: 520px) {{ .facts {{ grid-template-columns: 1fr; }} .facts dd {{ margin-bottom: 6px; }} }}
</style>
<main class="wrap">
  <div class="top">
    <h1>Porto Squirrel Batch</h1>
    <p>The last 21 Porto Nocciola squirrels, one at a time. Newest at the top. Nothing goes into Studio until you say so.</p>
    <div class="tally"><span>Via della Piazza 15 / 15 in Studio</span><span>The Groves 14 / 15 in Studio</span></div>
  </div>
  {''.join(section(s) for s in SECTIONS)}
  {EXTRA}
</main>
"""
open(os.path.join(HERE, "porto_batch.html"), "w", encoding="utf-8").write(page)
print("ok", [s["id"] for s in SECTIONS])
