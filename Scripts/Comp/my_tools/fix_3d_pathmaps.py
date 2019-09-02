# Use this script to fix pathmaps for imported fbx and alembic files
# MIT License
# Alex Bogomolov, mail@abogomolov.com
# 29-08-2019

all_tools = comp.GetToolList()

all_abc = comp.GetToolList(False, "SurfaceAlembicMesh")
all_fbx = comp.GetToolList(False, "SurfaceFBXMesh")

for fbx in all_fbx.values():
    path = fbx.ImportFile[1]
    fbx.ImportFile[1] = comp.ReverseMapPath(path)
for abc in all_abc.values():
    path = abc.Filename[1]
    abc.Filename[1] = comp.ReverseMapPath(path)