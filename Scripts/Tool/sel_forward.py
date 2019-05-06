flow = comp.CurrentFrame.FlowView
valid_types = ['Image', 'Number', 'Point', 'Gradient', 'Text', 'Mask', 'DataType3D']

tool = comp.ActiveTool


def recurse_select_forward(t):
    flow.Select(t)
    out = t.GetOutputList()[1]
    inp = out.GetConnectedInputs()
    for i in inp.values():
        try:
            print(i.GetAttrs()['INPS_DataType'])
            if i.GetAttrs()['INPS_DataType'] in valid_types:
                recurse_select_forward(i.GetTool())
        except KeyError:
            pass


flow.Select()
recurse_select_forward(tool)
