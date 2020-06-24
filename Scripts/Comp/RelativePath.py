from pathlib import Path
import platform
comp = fu.GetCurrentComp()
comp_name = comp.GetAttrs()["COMPS_FileName"]
rev_path = comp.ReverseMapPath(comp_name)
comp_parent = Path(rev_path).parent
comp.StartUndo("RelativePath script")
if platform.system() in ["Darwin", "Linux"]:
    delimeter = "/"
else:
    delimeter = "\\"
for tool in comp.GetToolList(True, "Loader").values():
    if tool.Clip[0][:5].lower() == "comp:": # already relative
        continue
    G_In = tool.GlobalIn[0]
    G_Out = tool.GlobalOut[0]
    Start = tool.ClipTimeStart[0]
    End = tool.ClipTimeEnd[0]
    PA = tool.PixelAspect[0]
    CPA = tool.CustomPixelAspect[0]
    tool_parent = Path(tool.Clip[0]).parent
    if str(tool_parent)[:len(str(comp_parent))] == str(comp_parent):
        # print("downstream footage")
        tool.Clip = tool.Clip[0].replace(str(comp_parent), "Comp:")
    else:
        # print("upstream footage")
        prefix = "..{}".format(delimeter)
        a = comp_parent.parts
        b = tool_parent.parts
        intersection_parts = [x for x in a if x in b]
        if not intersection_parts:
            print("no relative paths found")
            continue
        common_path = delimeter.join(intersection_parts).replace("//", "/")
        if platform.system() == "Windows":
            common_path = Path(common_path)
        diff = abs(len(a) - len(intersection_parts))
        prefix *= diff
        new_tool_path = tool.Clip[0].replace(str(common_path), "Comp:" + prefix)
        tool.Clip[0] = new_tool_path
    if tool.ID == "Loader":
        tool.GlobalIn = G_In
        tool.GlobalOut = G_Out
        tool.ClipTimeStart = Start
        tool.ClipTimeEnd = End
        tool.PixelAspect = PA
        tool.CustomPixelAspect = CPA
    print("set relative file path to {}".format(tool.Clip[0]))
comp.EndUndo()
