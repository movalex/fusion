"""
  Incremental Save script
  by Alex Bogomolov
  
  Based on IncrementalSave lua script by S.Neve / House of Secrets
"""
import platform
import os
from pathlib import Path

comp = fu.GetCurrentComp()

# if platform.system() == "Windows":
#     pass
# elif platform.system() in ["Darwin", "Linux"]:
#     pass

PATHENV = comp.MapPath(os.getenv("INCREMENT_SAVE_PATH"))

comp_attrs = comp.GetAttrs()

def get_save_path(path_env):
    if path_env:
        path_env = Path(path_env)
        print(f"env: {path_env}")
        if not path_env.exists():
            print("no save directory found, creating now")
            path_env.mkdir(exist_ok=True)
        return path_env / comp_attrs["COMPS_Name"]
    else:
        rootSaveFolder = "IncrementSave"
        comp_path = Path(comp.MapPath(comp.GetAttrs()["COMPS_FileName"]))
        return comp_path.parent / rootSaveFolder / comp_path.stem

if __name__ == "__main__":
    if comp_attrs["COMPS_FileName"] == "":
        comp.Save()
    path = get_save_path(PATHENV)
    print(path)


def main():
    comp_path = get_save_path(PATHENV)
    pf = bmd.parseFilename(comp_path)
    if not bmd.direxists(pf.Path + rootSaveFolder):
        print("creating dir: " + pf.Path + rootSaveFolder + split_path + pf.Name)
        os.execute(
            "mkdir " + mkdir_recursive + pf.Path + rootSaveFolder + split_path + pf.Name
        )
    if not bmd.direxists(pf.Path + rootSaveFolder + split_path + pf.Name):
        print("creating dir: " + pf.Path + rootSaveFolder + split_path + pf.Name)
        os.execute(
            "mkdir " + mkdir_recursive + pf.Path + rootSaveFolder + split_path + pf.Name
        )
        # search inc saves
        pathSearch = (
            pf.Path + rootSaveFolder + split_path + pf.Name + split_path + "*.comp"
        )
        dir = bmd.readdir(pathSearch)
        num = len(dir)
        currentVersion = 0
        for i in range(num):
            if not dir.is_dir():
                fileExtension = string.gsub(dir[i].Name, "[.][^.]+$", "")
                fileNumberString = string.sub(
                    fileExtension, string.find(fileExtension, "(%d+)$", 0)
                )
                fileNumber = tonumber(fileNumberString)
                if currentVersion < fileNumber:
                    currentVersion = fileNumber
        currentVersionString = "000" + tostring(currentVersion + 1)
        currentVersionString = string.sub(
            currentVersionString,
            string.len(currentVersionString) - 3,
            string.len(currentVersionString),
        )
    src = comp.GetAttrs().COMPS_FileName
    dest = (
        pf.Path
        + rootSaveFolder
        + split_path
        + pf.Name
        + split_path
        + pf.Name
        + "."
        + currentVersionString
        + ".comp"
    )
    os.rename(src, dest)
    comp.Save(src)
