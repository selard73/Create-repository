import base64, io
from pathlib import Path
from PIL import Image
D = Path(r"C:\Users\slard\roblox-props\italy\whale")
OUT = Path(__file__).resolve().parent / "whale_page.html"
def b64(name, crop=None):
    im = Image.open(D / name).convert("RGB")
    if crop: im = im.crop(crop)
    bg = Image.new("RGB", im.size, (235, 242, 247))
    # workbench renders have a flat grey background; keep as is but lighten edges: composite over page water tone
    buf = io.BytesIO(); im.save(buf, "JPEG", quality=86, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
figs = [
    ("pose_rest.png", "Resting pose, three-quarter view", None),
    ("pose_tailup.png", "Flukes up, flippers down: the start of a dive", None),
    ("pose_taildown.png", "Flukes down: the other half of a tail stroke", None),
    ("pose_bend.png", "Seen from above, bending into a turn", None),
]
route = b64("route_map.jpg")
cards = "\n".join(f'<figure><img src="{b64(f, c)}" alt="{cap}"><figcaption>{cap}</figcaption></figure>' for f, cap, c in figs)
html = f"""<title>Porto Nocciola Whale</title>
<style>
/* layout: one reading column, a 2x2 render grid, numbered build steps only where order matters */
:root {{
  --bg: #f1f5f8; --fg: #14202b; --muted: #55677a; --panel: #ffffff; --line: #d3dde6;
  --accent: #1f5fa8; --water: #dcebf7; --foam: #eef5fb;
  --display: "Nunito", "Segoe UI", system-ui, sans-serif;
  --body: "Atkinson Hyperlegible", "Segoe UI", system-ui, sans-serif;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
  --bg: #0f1a24; --fg: #e7eef5; --muted: #9fb2c4; --panel: #172634; --line: #2a3b4b;
  --accent: #7ab8f5; --water: #16324a; --foam: #1b2d3d; color-scheme: dark }} }}
:root[data-theme="dark"] {{
  --bg: #0f1a24; --fg: #e7eef5; --muted: #9fb2c4; --panel: #172634; --line: #2a3b4b;
  --accent: #7ab8f5; --water: #16324a; --foam: #1b2d3d; color-scheme: dark }}
body {{ background: var(--bg); color: var(--fg); font-family: var(--body); font-size: 16px; line-height: 1.55; padding-block: 0 48px; padding-inline: 16px; }}
main {{ max-width: 860px; margin: 0 auto; }}
header {{ padding-block: 36px 20px; border-bottom: 2px solid var(--line); margin-bottom: 28px; }}
.eyebrow {{ font-family: var(--display); font-weight: 800; font-size: 12px; letter-spacing: 0.12em; text-transform: uppercase; color: var(--accent); }}
h1 {{ font-family: var(--display); font-weight: 900; font-size: clamp(30px, 5vw, 44px); line-height: 1.05; margin: 6px 0 10px; text-wrap: balance; }}
h2 {{ font-family: var(--display); font-weight: 800; font-size: 22px; margin: 36px 0 12px; text-wrap: balance; }}
p {{ max-width: 64ch; margin: 0 0 12px; }}
.lead {{ font-size: 18px; color: var(--muted); }}
.grid {{ display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }}
@media (max-width: 640px) {{ .grid {{ grid-template-columns: 1fr; }} }}
figure {{ margin: 0; background: var(--water); border-radius: 10px; overflow: hidden; min-width: 0; }}
figure img {{ display: block; width: 100%; max-width: 100%; height: auto; }}
figcaption {{ font-size: 13.5px; color: var(--muted); padding: 8px 12px 10px; }}
.facts {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; margin: 14px 0 6px; }}
.fact {{ background: var(--foam); border: 1px solid var(--line); border-radius: 8px; padding: 10px 12px; min-width: 0; }}
.fact b {{ display: block; font-family: var(--display); font-weight: 800; font-size: 20px; font-variant-numeric: tabular-nums; }}
.fact span {{ font-size: 13px; color: var(--muted); }}
ol.steps {{ counter-reset: s; list-style: none; padding: 0; margin: 0; max-width: 64ch; }}
ol.steps li {{ counter-increment: s; position: relative; padding-left: 40px; margin-bottom: 12px; }}
ol.steps li::before {{ content: counter(s); position: absolute; left: 0; top: 1px; width: 26px; height: 26px; border-radius: 50%; background: var(--accent); color: #fff; font-family: var(--display); font-weight: 800; font-size: 13px; display: grid; place-items: center; }}
ul.ask {{ padding-left: 20px; max-width: 64ch; }}
ul.ask li {{ margin-bottom: 10px; }}
.note {{ background: var(--panel); border-left: 4px solid var(--accent); padding: 12px 14px; border-radius: 0 8px 8px 0; max-width: 64ch; margin: 16px 0; }}
</style>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@800;900&family=Atkinson+Hyperlegible:wght@400;700&display=swap">
<main>
<header>
  <div class="eyebrow">1001 Squirrels &middot; Porto Nocciola &middot; Oct 7 2026 &middot; updated after the sea survey</div>
  <h1>The whale, rigged and ready for the sea</h1>
  <p class="lead">Your Meshy blue whale, rigged and ready. The sea has been measured and his route is drawn below. Four picks from you and he goes in.</p>
</header>

<h2>What he looks like with bones in</h2>
<div class="grid">
{cards}
</div>
<div class="facts">
  <div class="fact"><b>12,000</b><span>triangles, down from 392,000</span></div>
  <div class="fact"><b>8 bones</b><span>head, body, 3 tail joints, flukes, 2 flippers</span></div>
  <div class="fact"><b>1 texture</b><span>sharpened to 1024 px, colours boosted like the squirrels</span></div>
  <div class="fact"><b>0 tears</b><span>in the bend checks (tail up, tail down, side bend)</span></div>
</div>

<h2>How he will behave</h2>
<p>He swims a closed loop out at sea: from the mouth of the bay out and across to the cave and back. Cruising, his back and the little dorsal fin ride just above the water, so from the promenade and the beach you see a blue shape cutting the surface and the tail moving under it.</p>
<p>About every three minutes (wherever you put a blow station on the route) he slows, stops, rises a touch, and <b>blows</b>: a white spout of mist about a third of his length high, with a sound. Then the classic dive: nose down, flukes lifting clear of the water, and he slides under. He travels submerged for half a minute, then rises and cruises on.</p>
<p>Every player sees the same whale at the same spot at the same time, because his position is worked out from the server clock, not from each phone. Nothing is heavy: one mesh, one script, one particle emitter.</p>

<h2>The sea, measured</h2>
<p>The read-only survey ran three passes on the live place (version 1135). The water surface is at -53 and the sea bed is flat sand at -62 everywhere outside the harbour: <b>the whole sea is 9 studs deep</b>. The cave is a model called Grotta Azzurra at the foot of the cliff below the lighthouse, with its round boulders in front of it; the pebble beach (Spiaggia dei Ciottoli) is just north of it, and the lighthouse stands on the headland beyond.</p>
<div class="facts">
  <div class="fact"><b>9 studs</b><span>sea depth, everywhere along the route</span></div>
  <div class="fact"><b>-53</b><span>water surface (the bed is at -62)</span></div>
  <div class="fact"><b>1,100 studs</b><span>length of the proposed loop</span></div>
  <div class="fact"><b>90 studs</b><span>from station B to the cave mouth</span></div>
</div>

<h2>The route</h2>
<figure><img src="{route}" alt="Top-down view of the Porto sea with the whale's loop, two blow stations and place labels"><figcaption>Straight-down capture from Studio. White line: his loop, arrows show direction. A and B are the blow stations. The shaded band is the whale lane (see below). Whale drawn to scale: 60 studs.</figcaption></figure>
<p>He leaves the bay mouth heading out to sea, swings wide to the south-west, comes back along the lighthouse headland, pauses off the pebble beach with the cave in front of him, then runs back up the coast to the bay. He never comes closer than 60 studs to any shore, and he passes in full view of the promenade, the cove, the sailing club, the beach, the cave path and the lighthouse.</p>
<p>At 7 studs a second a lap takes about 3 minutes including the two 12-second blows. With both stations on, each spot sees him blow every 3 minutes and he blows somewhere every 90 seconds. If you want the blow rarer, keep only station B (the cave): one blow every 3 minutes.</p>

<h2>Depth: the one decision</h2>
<p>A 60-stud whale is 20 studs tall. Cruising with his back out of the water he needs 16 studs below the surface, and the dive needs about 25. The sea has 9. Three ways to handle it:</p>
<ul class="ask">
  <li><b>Dig a whale lane (recommended).</b> Deepen the sea bed along the loop: a channel 60 studs wide, floor at -80, sloped sides, as the shaded band in the picture. From the cliffs it reads as a dark-blue deep-water channel, which is what a real whale would follow. It is one terrain edit; I copy the terrain region into ServerStorage first so it can be put back exactly.</li>
  <li><b>Leave the sea as it is.</b> He swims with his belly inside the sand. From above the water it looks right, because the sea bed hides what is below it. Anyone who swims out and looks underwater sees his lower half cut off by the sand.</li>
  <li><b>Smaller whale, no dive.</b> At 45 studs he needs 12 below the surface; still 3 more than the sea has. He could be kept from sinking below the bed, but then he rides high like a beached whale, and the dive would be shallow.</li>
</ul>

<h2>Your picks</h2>
<ul class="ask">
  <li><b>Route.</b> OK as drawn, or move a station or a corner (tell me where in words: "closer to the beach", "wider out to sea").</li>
  <li><b>Depth.</b> Dig the lane, or leave the sea as it is.</li>
  <li><b>Blows.</b> Both stations (A and B), or the cave only (B).</li>
  <li><b>Speed.</b> 7 studs a second as planned, or slower (5 makes a lap 4 minutes).</li>
</ul>

<div class="note"><b>Done so far:</b> look approved, size 60, blow sound chosen, survey complete, route drawn. Nothing is in Studio yet except the three read-only probes, which removed themselves.</div>

<h2>Order of work</h2>
<ol class="steps">
  <li>You answer the four picks above.</li>
  <li>If digging: the lane goes in with a backup first, and you see it from the cliff before anything else.</li>
  <li>You import the whale (Import 3D of whale_color.fbx), I run the installer with the route and stations. It checks every point of the loop is in water before it parks him.</li>
  <li>Play test together. Tune speed, how much of him shows, spout height, sound.</li>
  <li>Publish when you say so.</li>
</ol>
</main>
"""
OUT.write_text(html, encoding="utf-8")
print(OUT, len(html) // 1024, "KB")
