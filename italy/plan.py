import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon, FancyArrowPatch
f, ax = plt.subplots(figsize=(8, 11))
ax.add_patch(Rectangle((-1024,-1024),2048,2048,fc="#cfe8b0",ec="#7a9",lw=1))
ax.text(-1000,990,"Baseplate: flat grass, x/z ±1024\n(outside the play area today)",fontsize=8,va="top")
# edge ring
ax.add_patch(Rectangle((-450,-560),1450,850,fc="none",ec="#6b8e4e",lw=10,alpha=.35))
ax.text(1010,-560,"proposed hill / forest ring",fontsize=8,color="#476b2e",ha="right",va="top")
ax.add_patch(Rectangle((-150,-251),850,301,fc="#f3e0b5",ec="#b58",lw=1.5))
ax.text(275,-100,"PLAY AREA\nforest · village · domaine\nx -150..700  z -251..50",ha="center",va="center",fontsize=8)
# river channel
ax.plot([160,158,150,165,155,160],[680,300,50,-205,-600,-900],color="#3a8ad8",lw=3)
ax.plot([160,160],[-900,-1024],color="#3a8ad8",lw=3,ls=":")
ax.text(185,400,"existing river channel\n(terrain, runs z 680..-900)",fontsize=7,color="#1b5c99")
# gorge
ax.add_patch(Polygon([(110,-251),(70,-560),(250,-560),(210,-251)],fc="#a0785a",alpha=.6,ec="#6b4a33"))
ax.text(270,-420,"GORGE (step 2)\ncliffs close in; autopilot\nstarts at rim wall z -205",fontsize=8,color="#5a3a22")
ax.plot(157,-157,"s",color="#556b2f",ms=7); ax.annotate("jetty + boat",xy=(157,-157),xytext=(-600,-380),fontsize=7,arrowprops=dict(arrowstyle="-",color="#556b2f"))
# transition
ax.add_patch(FancyArrowPatch((160,-620),(160,-2050),arrowstyle="-|>",mutation_scale=18,ls="--",color="#555"))
ax.text(190,-1400,"map card + fade\n(no geometry here;\nplayer is moved under the fade)",fontsize=8,color="#444")
# Italy
ax.add_patch(Rectangle((-450,-3350),1200,1250,fc="#bfe3f5",ec="#3a8ad8",lw=1.5))
ax.add_patch(Polygon([(-450,-2100),(750,-2100),(750,-2450),(420,-2600),(100,-2520),(-200,-2650),(-450,-2500)],fc="#f2d9a0",ec="#b0894a"))
ax.text(150,-2250,"PORTO NOCCIOLA (land)\nhills + back of town face home",ha="center",fontsize=8)
ax.plot(100,-2530,"o",color="#c0392b"); ax.text(60,-2700,"Harbour Front quay\n(arrival, phase 1)",fontsize=8,color="#8e2a1e")
ax.text(-430,-2380,"Hillside Town\n(phase 2)",fontsize=7,color="#555")
ax.text(520,-2330,"Lighthouse Point\n(phase 3)",fontsize=7,color="#555")
ax.text(150,-3050,"OPEN SEA faces away from home\n(terrain water to the edge + skybox islands)",ha="center",fontsize=8,color="#1b5c99")
ax.annotate("",xy=(900,-251),xytext=(900,-2100),arrowprops=dict(arrowstyle="<->",color="#888"))
ax.text(910,-1180,"~1,850 studs",fontsize=8,color="#666",rotation=90,va="center")
ax.set_xlim(-1100,1100); ax.set_ylim(-3450,1100); ax.set_aspect("equal")
ax.set_xlabel("x (studs)"); ax.set_ylabel("z (studs)   ↓ south = -z, the way the river flows")
ax.set_title("1001 Squirrels — Italy placement proposal (top-down, north up)",fontsize=10)
ax.grid(alpha=.2); plt.tight_layout(); plt.savefig("placement_plan.png",dpi=110)
