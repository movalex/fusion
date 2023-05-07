import re
from pathlib import Path

EXT = "..exr"


def parse_comp_name(comp_name: str):
    parent_folder = ""
    comp_path = Path(comp_name)
    file_name = comp_path.stem
    parent_search = re.match("^\d+_\w", file_name)
    if parent_search:
        parent_folder = parent_search.group()
    return parent_folder, file_name


comp_name = comp.GetAttrs()["COMPS_FileName"]
saver = comp.ActiveTool or comp.GetToolList(True, "Saver")[1]

parent_folder, file_name = parse_comp_name(comp_name)

saver_path = Path(comp.MapPath(saver.Clip[1]))

saver_parent = saver_path.parent.parent

comp.StartUndo("Saver Rename")
saver.Clip[1] = Path(saver_parent, parent_folder, file_name + EXT).as_posix()
comp.EndUndo()

print(saver.Clip[1])
