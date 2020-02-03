import os
import re

comp.Lock()
toollist = list(comp.GetToolList(True).values())
for tool in toollist:
    if (tool.GetAttrs()["TOOLS_RegID"]) == "Loader" and (
        tool.GetAttrs()["TOOLB_PassThrough"]) == False:

        pathfilename = tool.GetAttrs()["TOOLST_Clip_Name"][1]

        print(pathfilename)
        fpath, fname = os.path.split(pathfilename)
        root_version = os.path.split(fpath)[1]

        print('root', root_version)
        version = re.search(r'v\d{3,}', pathfilename, re.IGNORECASE)

        print(version)
    if not version:
        raise NameError('No version number (vXXX) found in file path!')
    print(version.group())
    print(version.start())
    print(version.end())
    name, ext = os.path.splitext(fname)

    if check == 1:
        tool.Clip = "%s%s" % (versionfilepath, latestFile[0])
        tool.SetAttrs({"TOOLB_PassThrough": True})
        tool.SetAttrs({"TOOLB_PassThrough": False})
    # os.path.exists(file_path)

    print("done")
comp.Unlock()
