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
        version = re.search(r"v\d{3,}", pathfilename, re.IGNORECASE)

        print(version)
    if not version:
        raise NameError("No version number (vXXX) found in file path!")
    print(version.group())
    print(version.start())
    print(version.end())
    name, ext = os.path.splitext(fname)

    artist = filename[version.end() + 1 : version.end() + 4]
    print(artist)

    for i, item in enumerate(reversed(versionfolder)):
        versionfilepath = "{}{}".format(versionpath, item)
        if versionfilepath == pathname:
            print("no new version found")
            check = 0
            break
        print(versionfilepath)
        versionfiles = os.listdir(versionfilepath)
        # versionfiles.sort()
        # print versionfiles
        # print len(versionfiles)
        laenge = len(versionfiles)
        x = 0
        for x in range(laenge):
            try:
                versionfiles[x][-4]
                if versionfiles[x][-4] == ".":
                    # print 'del item'
                    versionfilesnofolder.append(versionfiles[x])
            except:
                pass

            x = x + 1
        # versionfiless = [f for j, f in enumerate(versionfiles) if (versionfiles[j][-4] == ".")]
        print(versionfilesnofolder)
        print(len(versionfilesnofolder))

        latestFile = [f for j, f in enumerate(versionfilesnofolder)
            if (re.search(anyVersionArtistPattern,
                          versionfilesnofolder[j], re.IGNORECASE))]
        check = 1
        if len(latestFile) > 0:
            break

    if check == 1:
        # print versionfiles
        print(latestFile)

        tool.Clip = "%s%s" % (versionfilepath, latestFile[0])
        tool.SetAttrs({"TOOLB_PassThrough": True})
        tool.SetAttrs({"TOOLB_PassThrough": False})
    # os.path.exists(file_path)

    print("done")
comp.Unlock()
