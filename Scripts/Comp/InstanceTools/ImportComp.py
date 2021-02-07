import os
import tkinter as tk
from tkinter import filedialog

comp = fu.GetCurrentComp()
comp_name = comp.GetAttrs()["COMPS_FileName"]
root = tk.Tk()
root.withdraw()

file_path = filedialog.askopenfilename(filetypes=[("Fusion Comp", ".comp")])

# use AskUser dialogue if you prefer native file browser:

# dialogue = {1:{1:"Select .comp file", 2: "FileBrowse"}}
# file_path = comp.AskUser("Open comp", dialogue)["Select .comp file"]


def main(filepath=None):
    if not filepath:
        return
    if not os.path.exists(filepath):
        print("Comp file not found")
        return
    comp_load = fu.LoadComp(filepath, True)
    tools = comp_load.GetToolList(False)
    flow = comp_load.CurrentFrame.FlowView
    for tool in tools.values():
        flow.Select(tool)
    comp_load.Copy()
    flow.Select()
    # comp_load.Close()
    fu.LoadComp(comp_name, True)
    comp.Paste()
    fu.SetData("SourceComp", filepath)


if __name__ == "__main__":
    main(file_path)
