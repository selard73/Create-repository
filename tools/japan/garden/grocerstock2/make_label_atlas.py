from pathlib import Path
import json,sys,math
from PIL import Image,ImageDraw,ImageFont

layout=Path(sys.argv[1]);dest=Path(sys.argv[2]);rows=json.loads(layout.read_text())
im=Image.new('RGB',(2048,2048),(242,230,196));draw=ImageDraw.Draw(im)
font=Path(r'C:\Windows\Fonts\segoeuib.ttf')
for i,row in enumerate(rows):
    x=(i%8)*256+12;y=(i//8)*320+12
    w=232;h=min(288,round(w*row['h']/row['w']))
    assert h>=24 and y+h<2048
    ink=(55,43,31);accent=(81,107,70) if row['tea'] else (130,85,44)
    draw.rectangle((x+2,y+2,x+w-3,y+h-3),outline=accent,width=2)
    title={'SOY':'SOY\nSAUCE','SESAME':'SESAME\nOIL','VINEGAR':'RICE\nVINEGAR','RED MISO':'RED\nMISO'}.get(row['text'],row['text'])
    for fs in range(72,9,-1):
        f=ImageFont.truetype(str(font),fs)
        box=draw.multiline_textbbox((0,0),title,font=f,spacing=1,align='center')
        if box[2]-box[0]<w*.88 and box[3]-box[1]<h*.76:break
    tw=box[2]-box[0];th=box[3]-box[1]
    draw.multiline_text((x+(w-tw)/2-box[0],y+(h-th)/2-box[1]),title,font=f,fill=ink,spacing=1,align='center')
    row['uv']=[(x+.5)/2048,1-(y+h-.5)/2048,(x+w-.5)/2048,1-(y+.5)/2048]
    row['pixelRect']=[x,y,w,h]
im.save(dest)
layout.write_text(json.dumps(rows,indent=2))
print('LABEL_ATLAS_READY',len(rows),dest)
