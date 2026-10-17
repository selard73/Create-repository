"""Render a single view in a fresh Blender process to bound memory usage.
Run with run_blender.py out/render_<view>.log GROCERSTOCK1_RENDER render_one.py <view>.
The generator supports --geometry-only for rebuilding without batch rendering.
"""
from pathlib import Path
import bpy,sys,traceback
d=Path(__file__).resolve().parent
ns={'__file__':str(d/'gen_grocerstock1.py'),'__name__':'render_helpers'}
exec((d/'gen_grocerstock1.py').read_text().split('\ntry:\n')[0],ns)
name=sys.argv[sys.argv.index('--')+1]
assert name in ['grocer_shelf_overview','grocer_tea_detail','grocer_pantry_detail','grocer_dry_goods_detail']
ns['LOG']=d/'out'/('render_'+name+'.log')
ns['LOG'].write_text('')
try:
    bpy.ops.wm.open_mainfile(filepath=str(d/'out/grocerstock1_shelf_review.blend'))
    ns['render_review'](name)
    bpy.ops.wm.save_as_mainfile(filepath=str(d/'out'/('review_'+name+'.blend')))
    ns['log']('GROCERSTOCK1_RENDER_DONE')
except Exception:
    ns['log'](traceback.format_exc());ns['log']('GROCERSTOCK1_RENDER_FAILED')
