from pathlib import Path

comp = fu.GetCurrentComp()
comp_name = comp.GetAttrs()["COMPS_FileName"]
rev_path = comp.ReverseMapPath(comp_name)
comp_parent = Path(rev_path).parent
comp.StartUndo("RelativePath script")
comp.Lock()
for tool in comp.GetToolList(True, ["Loader", "Saver"]).values():
    if tool.Clip[0][:5].lower() == "comp:": # already relative
        continue
    tool_parent = Path(tool.Clip[0]).parent
    # print("tp", tool_parent)
    # print("cp", comp_parent)
    if str(tool_parent)[:len(str(comp_parent))] == str(comp_parent): # if footage is downstream
        print("downstream")
        tool.Clip = tool.Clip[0].replace(str(comp_parent), "Comp:")
    else:
        print("upstream")
        prefix = "../"
        a = comp_parent.parts
        b = tool_parent.parts
        intersection_parts = [x for x in a if x in b]
        if not intersection_parts:
            continue
        common_path = "/".join(intersection_parts).replace("//", "/") # remove double slashes in masOS paths
        diff = abs(len(a) - len(intersection_parts))
        prefix *= diff
        new_tool_path = tool.Clip[0].replace(str(common_path), "Comp:" + prefix)
        tool.Clip[0] = new_tool_path
    print("set relative file path to {}".format(tool.Clip[0]))
comp.EndUndo()
comp.Unlock()
