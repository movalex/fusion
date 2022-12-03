import platform
from subprocess import Popen, PIPE
from pathlib import Path

tool = comp.ActiveTool or comp.GetToolList(True)[1]

def run_osascript(scr, args=None):
    if args is None:
        args = []
    p = Popen(
        ["osascript", "-"] + args,
        stdin=PIPE,
        stdout=PIPE,
        stderr=PIPE,
        encoding="utf-8",
        universal_newlines=True,
    )
    stdout, stderr = p.communicate(scr)
    print(stderr)


def mac_reveal():
    if tool.ID in ["Loader", "Saver"]:
        path = comp.MapPath(tool.GetAttrs()["TOOLST_Clip_Name"][1])
        path = Path(path)
        print(f"opening file: {path.name}")
        # call(["open", path])
        script_text = f""" 
        property the_path : "{path.parent}"
        set the_folder to (POSIX file the_path) as alias
        set the_file to "{path.name}"
        try
                tell application "Finder"
                        if not (exists Finder window 1) or (get collapsed of the front Finder window) then
                                make new Finder window
                        end if
                        set frontmost to true
                        set target of front Finder window to the_folder
                        select file the_file of the_folder
                end tell
        end try
        """
        run_osascript(script_text)

if __name__ == "__main__":
    if platform.system() == "Darwin":
        mac_reveal()

