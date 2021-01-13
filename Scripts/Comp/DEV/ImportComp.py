import tkinter as tk
from tkinter import filedialog

comp = fu.GetCurrentComp()

root = tk.Tk()
root.withdraw()

file_path = filedialog.askopenfilename(filetypes=[("Fusion Comp", ".comp")])


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
