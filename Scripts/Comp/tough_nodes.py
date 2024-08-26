tools = comp.GetToolList(True)
result = {}
for tool in tools.values():
    time_last_frame = tool.GetAttrs("TOOLN_LastFrameTime")
    result[tool.Name] = time_last_frame

sorted_tools = sorted(result.items(), key=lambda x: x[1], reverse=True)

TILE_COLORS = {
    'orange': {'G': 0.43, 'R': 0.92, 'B': 0},
    'apricot': {'G': 0.66, 'R': 1.0, 'B': 0.2},
    'yellow': {'G': 0.66, 'R': 0.89, 'B': 0.11},
    'lime': {'G': 0.78, 'R': 0.62, 'B': 0.08},
    'olive': {'G': 0.6, 'R': 0.37, 'B': 0.13},
    'green': {'G': 0.56, 'R': 0.25, 'B': 0.40},
    'teal': {'G': 0.60, 'R': 0, 'B': 0.6},
    'navy': {'G': 0.38, 'R': 0.08, 'B': 0.52},
    'blue': {'G': 0.66, 'R': 0.47, 'B': 0.82},
    'purple': {'G': 0.45, 'R': 0.6, 'B': 0.63},
    'violet': {'G': 0.29, 'R': 0.58, 'B': 0.80},
    'pink': {'G': 0.55, 'R': 0.91, 'B': 0.71},
    'tan': {'G': 0.69, 'R': 0.73, 'B': 0.59},
    'beige': {'G': 0.63, 'R': 0.78, 'B': 0.47},
    'brown': {'G': 0.4, 'R': 0.6, 'B': 0},
    'chocolate': {'G': 0.35, 'R': 0.55, 'B': 0.25}
}


# Get top 10 tools
top_10_tools = sorted_tools[:10]
print("Top 10 Tools by Last Frame Time:")
print("========================")
for i, (tool_name, time_last_frame) in enumerate(top_10_tools, start=1):
    print(f"{i}. Tool: {tool_name} | Last Frame Time: {time_last_frame:.4f} seconds")

# Get top 3 tools
top_3_tools = sorted_tools[:3]
print("\nTop 3 Tools by Last Frame Time:")
print("========================")
flow = comp.CurrentFrame.FlowView
flow.Select()
tools_selected = []
for i, (tool_name, time_last_frame) in enumerate(top_3_tools, start=1):
    print(f"{i}. Tool: {tool_name} | Last Frame Time: {time_last_frame:.4f} seconds")
    tool = comp.FindTool(tool_name)
    tool.TileColor = TILE_COLORS["violet"]
    tools_selected.append(tool)
flow.Select(tools_selected)
