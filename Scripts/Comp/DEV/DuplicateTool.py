# Duplicate Tool script
# Copy and paste tools in Fusion and Resolve Fusion and keep connections. Also works with wireless nodes.
# This script is based on hos_Duplicate.lua tool written by Sven Neve in 2013.
# Copyright 2020 Alexey Bogomolov (mail@abogomolov.com)
# License MIT
# v 1.2 11.24.2020
# -- Fix inputs for multi-input tools, like Merge3D or Replicate3D, if some inputs were disconnected.


def fix_number_of_inputs(dup_tool, inputs_list):
    if dup_tool.ID in [
        "Merge3D",
        "Replicate3D",
        "Fuse.Switch",
        "Fuse.SwitchElse",
    ]:
        count = 1
        for inp in inputs_list:
            if inp.GetConnectedOutput():
                dup_input = dup_tool.FindMainInput(count)
                count += 1
                if dup_input and not dup_input.GetAttrs()["INPB_Connected"]:
                    dup_input.ConnectTo(inp)


def duplicate(orig_tool_list, dup_tool_list):
    for i, tool in orig_tool_list.items():
        dup_tool = dup_tool_list[i]
        inputs_to_connect = []
        for j, original_input in tool.GetInputList().items():
            if original_input.GetAttrs()["INPB_Connected"]:
                inputs_to_connect.append(original_input)
                try:
                    duplicate_input = dup_tool.GetInputList()[j]
                    if not duplicate_input.GetAttrs()["INPB_Connected"]:
                        duplicate_input.ConnectTo(original_input.GetConnectedOutput())
                except KeyError:
                    pass
        fix_number_of_inputs(dup_tool, inputs_to_connect)


if __name__ == "__main__":
    comp = fu.GetCurrentComp()
    original_tool_list = comp.GetToolList(True)

    if len(original_tool_list) > 0:
        flow = comp.CurrentFrame.FlowView
        comp.Copy(original_tool_list)
        flow.Select()
        comp.StartUndo("Duplicate Tool")
        comp.Paste()
        duplicate_tool_list = comp.GetToolList(True)

        duplicate(original_tool_list, duplicate_tool_list)
        comp.EndUndo()
    else:
        print("no tools to duplicate")
