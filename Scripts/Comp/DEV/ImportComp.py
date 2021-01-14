import tkinter as tk
from tkinter import filedialog

comp = fu.GetCurrentComp()

root = tk.Tk()
root.withdraw()

file_path = filedialog.askopenfilename(filetypes=[("Fusion Comp", ".comp")])

# use AskUser dialogue if you prefer native file browser:

# dialogue = {1:{1:"Select .comp file", 2: "FileBrowse"}}
# file_path = comp.AskUser("Open comp", dialogue)["Select .comp file"]


def main(filepath=None):
    if not filepath:
        return
    comp_load = fu.LoadComp(filepath, True)

    tools = comp_load.GetToolList(False)

    flow = comp_load.CurrentFrame.FlowView

    for tool in tools.values():
        flow.Select(tool)

    comp_load.Copy()

    flow.Select()

    comp_load.Close()

    comp.Paste()


if __name__ == "__main__":
    main(file_path)
