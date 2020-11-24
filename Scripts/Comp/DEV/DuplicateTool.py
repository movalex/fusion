# 1.08.2014 initial lua tool release for Fusion 7 by Sven Neve (House of Secrets) http.//www.svenneve.com/?p=922
# 11.24.2020 Rewritten in Python by Alexey Bogomolov (mail@abogomolov.com).
# This version properly fixes inputs for Merge3D in case some inputs were disconnected or rearranged.
import sys


def fix_number_of_inputs(dup_tool, data):
    count = 0
    for inp in data:
        if inp.GetConnectedOutput():
            count += 1
            dup_input = dup_tool.FindMainInput(count)
            if dup_input and not dup_input.GetAttrs()["INPB_Connected"]:
                dup_input.ConnectTo(inp)


comp = fu.GetCurrentComp()
original_tool_list = comp.GetToolList(True)
flow = comp.CurrentFrame.FlowView
comp.Copy(original_tool_list)
flow.Select()
comp.StartUndo("Duplicate Tool")
comp.Paste()
duplicate_tool_list = comp.GetToolList(True)
data = []

if len(duplicate_tool_list) == 0:
    print("cannot create duplicate")
    sys.exit()

if len(duplicate_tool_list) == 1 and duplicate_tool_list[1].ID in [
    "Merge3D",
    "Replicate3D",
]:
    dup_tool = duplicate_tool_list[1]
    tool = original_tool_list[1]
    for original_input in tool.GetInputList().values():
        if original_input.GetAttrs()["INPB_Connected"]:
            data.append(original_input)
    fix_number_of_inputs(dup_tool, data)
else:
    for i, tool in original_tool_list.items():
        dup_tool = duplicate_tool_list[i]
        for j, original_input in tool.GetInputList().items():
            if original_input.GetAttrs()["INPB_Connected"]:
                try:
                    duplicate_input = dup_tool.GetInputList()[j]
                    if not duplicate_input.GetAttrs()["INPB_Connected"]:
                        duplicate_input.ConnectTo(original_input.GetConnectedOutput())
                except KeyError:
                    pass
comp.EndUndo("")
