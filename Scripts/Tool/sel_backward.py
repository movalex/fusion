flow = comp.CurrentFrame.FlowView
valid_types = ['Image', 'Particles', 'Mask', 'DataType3D']


def recurse_select_backward(t):
    # if the current tool has image inputs, select them, otherwise pass
    flow.Select(t)
    inp_list = (inp for inp in t.GetInputList().values()
            if inp.GetAttrs()['INPS_DataType'] in valid_types)
    for inp in inp_list:
        next_out = inp.GetConnectedOutput()
        if next_out:
            tool = next_out.GetTool()
            recurse_select_backward(tool)


flow.Select()
recurse_select_backward(tool)
