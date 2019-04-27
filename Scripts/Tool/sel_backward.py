flow = comp.CurrentFrame.FlowView
valid_types = ['Image', 'Particles', 'Mask', 'Datatype3d']


def recurse_select_backward(t):
    # if the current tool has image inputs, select them, otherwise pass
    flow.Select(t)
    for inp in t.GetInputList().values():
        try:
            if inp.GetAttrs()['INPS_DataType'] in valid_types:
                output = inp.GetConnectedOutput()
                if output:
                    recurse_select_backward(output.GetTool())
        except KeyError:
            pass


flow.Select()
recurse_select_backward(tool)
