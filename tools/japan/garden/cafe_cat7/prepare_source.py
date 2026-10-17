from pathlib import Path
import zipfile,json,shutil
D=Path(__file__).resolve().parent
name='Adorable_Tabby_Kitten_1017152518';archive=Path('C:/Users/slard/Downloads')/('Meshy_AI_'+name+'_texture_fbx.zip');dest=(D/'src'/name).resolve();dest.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(archive) as z:
    files=[{'file':m.filename,'bytes':m.file_size} for m in z.infolist()]
    for m in z.infolist():
        if not (dest/m.filename).resolve().is_relative_to(dest):raise ValueError('Unsafe archive member')
    z.extractall(dest)
(D/'archives.json').write_text(json.dumps([{'index':6,'name':name,'source':str(archive),'directory':str(dest),'files':files}],indent=2))
for name in ['inspect_cats.py','rig_cats.py','plot_geometry.py']:shutil.copy2(D.parent/'cafe_cats1'/name,D/name)
print(json.dumps(files,indent=2))
