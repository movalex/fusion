selected_tools = comp.GetToolList(True)
flow = comp.CurrentFrame.FlowView
for tool in selected_tools.values():
    pos_x, pos_y = flow.GetPosTable(tool).values()
    comp.SetActiveTool(tool)
    comp.AddTool('Transform', -32768, -32768)
    flow.SetPos(tool, pos_x, pos_y-1)

