all_tools = comp.GetToolList()

all_abc = comp.GetToolList(False, "SurfaceAlembicMesh")
all_fbx = comp.GetToolList(False, "SurfaceFBXMesh")

for fbx in all_fbx.values():
    path = fbx.ImportFile[1]
    fbx.ImportFile[1] = comp.ReverseMapPath(path)
for abc in all_abc.values():
    path = abc.Filename[1]
    abc.Filename[1] = comp.ReverseMapPath(path)

# for tool in all_tools.values():
#     if tool.ID == "SurfaceFBXMesh":
#         path = tool.ImportFile[1]
#         tool.ImportFile[1] = comp.ReverseMapPath(path)
#     elif tool.ID == "SurfaceAlembicMesh":
#         path = tool.Filename[1]
#         tool.Filename[1] = comp.ReverseMapPath(path)
#     else:
#         pass

