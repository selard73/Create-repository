from pathlib import Path
import zipfile,json
base=Path(__file__).resolve().parent
names=['Whisker_Wonder_1017152321','Emerald_Eyed_Tabby_Ki_1017152351','Tuxedo_Kitten_1017152410','Ginger_Whiskers_1017152421','Curious_Little_Tabby_1017152441','Blush_Eared_Kitten_1017152457']
out=[]
for i,n in enumerate(names):
    archive=Path('C:/Users/slard/Downloads')/('Meshy_AI_'+n+'_texture_fbx.zip')
    dest=(base/'src'/n).resolve(); dest.mkdir(parents=True,exist_ok=True)
    rows=[]
    with zipfile.ZipFile(archive) as z:
        for m in z.infolist():
            target=(dest/m.filename).resolve()
            if not target.is_relative_to(dest): raise ValueError('Unsafe archive path')
            rows.append({'file':m.filename,'bytes':m.file_size})
        z.extractall(dest)
    out.append({'index':i,'name':n,'source':str(archive),'directory':str(dest),'files':rows})
    print(json.dumps(out[-1]))
(base/'archives.json').write_text(json.dumps(out,indent=2))
