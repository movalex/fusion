import re
import os
from pathlib import Path

comp = fu.GetCurrentComp()
comp.StartUndo("Unlink Loaders")
count = 0
for loader in comp.GetToolList(True, "Loader").values():
    file_path = loader.Clip[0]
    first_letter = re.match("^([a-zA-Z@])", str(file_path)).group(1)
    print(first_letter)
    new_path = file_path.replace(first_letter, "@", 1)
    # new_path = os.path.join(root, "\\".join(parts[1:]))
    loader.Clip[0] = new_path
    count += 1

print(f"unlinked {count} files")
comp.EndUndo()
