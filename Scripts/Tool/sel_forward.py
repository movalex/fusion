flow = comp.CurrentFrame.FlowView
valid_types = ['Image', 'Number', 'Point', 'Gradient', 'Text']

tool = comp.ActiveTool


def recurse_select_forward(t):
    flow.Select(t)
    out = t.GetOutputList()[1]
    inp = out.GetConnectedInputs()
    # print(inp.GetAtrrs()['INPS_DataType'])
    for i in inp.values():
        try:
            if i.GetAttrs()['INPS_DataType'] in valid_types:
                recurse_select_forward(i.GetTool())
        except KeyError:
            pass


flow.Select()
recurse_select_forward(tool)
