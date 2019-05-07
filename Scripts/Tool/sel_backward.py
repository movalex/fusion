flow = comp.CurrentFrame.FlowView
valid_types = ['Image', 'Particles', 'Mask', 'DataType3D']


def recurse_select_backward(t):
    # if the current tool has image inputs, select them, otherwise pass
    flow.Select(t)
    for inp in t.GetInputList().values():
        if inp.GetAttrs()['INPS_DataType'] in valid_types:
            next_out = inp.GetConnectedOutput()
            if next_out:
                recurse_select_backward(next_out.GetTool())
        pass


flow.Select()
recurse_select_backward(tool)
