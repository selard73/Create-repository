from pathlib import Path
import json,numpy as np,matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
D=Path(__file__).resolve().parent
cats=json.loads((D/'inspection.json').read_text())
for axes,name in [((1,2),'side'),((0,2),'front'),((0,1),'top')]:
    fig,axs=plt.subplots(2,3,figsize=(16,10),layout='constrained')
    for ax,c in zip(axs.flat,cats):
        p=np.load(D/c['name']/'points.npy');a,b=axes
        ax.scatter(p[:,a],p[:,b],s=.5,c=p[:,0] if name=='side' else p[:,1],cmap='viridis',rasterized=True)
        ax.set_title(c['name']);ax.set_aspect('equal');ax.grid(alpha=.5);ax.set_xlabel('XYZ'[a]);ax.set_ylabel('XYZ'[b])
        ax.set_xticks(np.arange(np.floor(p[:,a].min()*4)/4,p[:,a].max()+.25,.25),minor=True)
        ax.set_yticks(np.arange(np.floor(p[:,b].min()*4)/4,p[:,b].max()+.25,.25),minor=True);ax.grid(which='minor',alpha=.15)
    fig.savefig(D/(name+'_geometry.png'),dpi=120);plt.close(fig)
