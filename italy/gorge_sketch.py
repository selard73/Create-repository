import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Rectangle
import numpy as np
# measured water centre (gorge_probe1): z -> x
zs=[-180,-200,-220,-240,-260,-280,-300,-320,-340,-360,-380,-400,-420,-440,-460,-480,-500,-520]
xs=[156,158,172,182,194,188,174,150,132,116,110,114,128,148,170,186,198,198]
hw=[8,8,8,10,10,12,10,14,12,12,10,10,8,8,10,10,10,14]
f,ax=plt.subplots(figsize=(9.5,8.5))
ax.add_patch(Rectangle((-60,-560),500,420,fc="#cfe8b0"))
# existing play area
ax.add_patch(Rectangle((-60,-205),500,70,fc="#f3e0b5",ec="#b58"))
ax.text(20,-160,"PLAY AREA (village / lagoon)\ninvisible rim wall z -205 stays",fontsize=8)
ax.plot(157,-157,"s",color="#556b2f",ms=8); ax.text(166,-152,"jetty + boat",fontsize=8)
# ridge across the south edge
ridge=[(-60,-230),(60,-235),(140,-228),(250,-232),(440,-236),(440,-560),(-60,-560)]
ax.add_patch(Polygon(ridge,fc="#b7a27c",alpha=.55,ec="#7a6446"))
ax.text(-50,-545,"SOUTH RIDGE: layered cliffs + hills, pines/cypress on top,\njoins the existing mounds and the Sandstone Climb to the east",fontsize=8,color="#5a4630")
# gorge channel: cut through ridge
L=[(x-h-6,z) for x,z,h in zip(xs,zs,hw)]; R=[(x+h+6,z) for x,z,h in zip(xs,zs,hw)]
ax.add_patch(Polygon(L+R[::-1],fc="#cfe8b0",ec="none"))
W=[(x-h,z) for x,z,h in zip(xs,zs,hw)]+[(x+h,z) for x,z,h in zip(xs,zs,hw)][::-1]
ax.add_patch(Polygon(W,fc="#4a9be0",ec="#2c6fb0"))
ax.plot([p[0] for p in L],[p[1] for p in L],color="#6b4a33",lw=3); ax.plot([p[0] for p in R],[p[1] for p in R],color="#6b4a33",lw=3)
def mark(z,txt,c,dx=40):
    x=np.interp(-z,[-v for v in zs],xs); ax.plot([x-30,x+30],[z,z],color=c,lw=2.5,ls="--"); ax.text(x+dx,z,txt,fontsize=8,color=c,va="center")
mark(-203,"① autopilot takes over (after 'Sail to Italy?' Yes)","#c0392b")
mark(-300,"② cliffs close in: 30→45 studs high, water ~20 wide","#6b4a33",45)
mark(-345,"③ old stone aqueduct arch spans the gorge (boat passes under)","#555",45)
mark(-420,"④ bend hides the way ahead: fade + map card here","#8e44ad",40)
ax.annotate("current →",xy=(180,-250),xytext=(215,-265),fontsize=8,color="#1b5c99")
ax.text(190,-505,"channel continues (already terrain water to z -900),\nhidden behind the ridge",fontsize=7,color="#1b5c99")
ax.set_xlim(-60,440); ax.set_ylim(-560,-140); ax.set_aspect("equal")
ax.set_xlabel("x (studs)"); ax.set_ylabel("z (studs), south = down")
ax.set_title("South gorge sketch (top-down), built on the river channel as measured today",fontsize=10)
plt.tight_layout(); plt.savefig("gorge_sketch.png",dpi=110)
