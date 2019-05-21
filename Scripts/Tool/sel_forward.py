flow = comp.CurrentFrame.FlowView
valid_types = ['Image', 'Number', 'Point', 'Gradient', 'Text', 'Mask', 'DataType3D']

if not tool:
    tool = comp.ActiveTool


def recurse_select_forward(t):
    flow.Select(t)
    out = t.GetOutputList()[1]
    next_inp = out.GetConnectedInputs()
    for inp in next_inp.values():
        try:
            # if the node added to the viewer, inp will be null
            # print(inp.GetAttrs()['INPS_DataType'])
            if inp.GetAttrs()['INPS_DataType'] in valid_types:
                recurse_select_forward(inp.GetTool())
        # passes if the node is loaded to the viewer (it has empty key)
        except KeyError:
            pass


flow.Select()
recurse_select_forward(tool)
