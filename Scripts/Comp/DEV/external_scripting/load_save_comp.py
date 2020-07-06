from pathlib import Path
import BlackmagicFusion as bmd

fusion = bmd.scriptapp('Fusion', 'localhost')
path = Path("~/Desktop/p_01250a_cannon_hits.comp")
comp = fusion.LoadComp(str(path.expanduser()), True, True)
print(comp.GetAttrs()['COMPS_FileName'])
new_name = f"{path.expanduser().parent}/{path.name}_001.comp"
comp.Save(new_name)
