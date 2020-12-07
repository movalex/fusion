#!/usr/bin/env python
# -*- coding: utf-8 -*-

#  Written by Wheatfield Media INC [vfxgrace29@gmail.com], October 2019
#  Updated from v 1.5 to 1.7 by Alexey Bogomolov [mail@abogomolov.com], November 2020
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
#  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
#  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
#  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
#  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

VERSION = 1.7

"""
  Script Name:  AssetsManager
  Created by:   Wheatfield Media INC     [vfxgrace29@gmail.com]
  Description:  Manage assets used in Fusion projects
  Version:      1.7
"""

import os
import subprocess
import re
import platform
# from pprint import pprint as pp


comp = fu.GetCurrentComp()

isDeleted = False
index = 0
childItem_list = []
category_dict = {
    "Video": {"Title": "Video", "TreeItem": None, "Expanded": False},
    "Image": {"Title": "Image", "TreeItem": None, "Expanded": False},
    "Model": {"Title": "Model", "TreeItem": None, "Expanded": False},
    "Audio": {"Title": "Audio", "TreeItem": None, "Expanded": False},
    "LUT": {"Title": "LUT", "TreeItem": None, "Expanded": False},
}


# =====================================================================================


def windowClose(ev):
    disp.ExitLoop()


def showWarningDialog(tittle, msg, show_button):
    msg = "\n" + msg
    dlg = disp.AddWindow(
        {
            "ID": "InfoDialog",
            "WindowTitle": tittle,
            "Geometry": [400, 400, 460, 150],
            "WindowFlags": {
                "Window": True,
                "WindowStaysOnTopHint": True,
                "WindowCloseButtonHint": True,
            },
        },
        [
            ui.VGroup(
                {"Spacing": 7},
                [
                    ui.TextEdit(
                        {
                            "ID": "InfoText",
                            "Text": msg,
                            "ReadOnly": True,
                            "Font": ui.Font({"PixelSize": 15}),
                            "Weight": 0.7,
                        }
                    ),
                    ui.HGroup(
                        {"Spacing": 10, "Weight": 0, "ID": "BtnGroup", },
                        [
                            ui.HGap(0, 2),
                            ui.Button(
                                {
                                    "Spacing": 33,
                                    "ID": "Confirmed",
                                    "Font": ui.Font({"PixelSize": 13}),
                                    "Text": "OK",
                                    "Alignment": {"AlignHCenter": True, },
                                    "Visible": False,
                                }
                            ),
                            ui.Button(
                                {
                                    "Spacing": 33,
                                    "ID": "Canceled",
                                    "Font": ui.Font({"PixelSize": 13}),
                                    "Text": "Cancel",
                                    "Alignment": {"AlignHCenter": True, },
                                }
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

    def close(ev):
        disp.ExitLoop()

    def confirmClicked(ev):
        global isDeleted
        isDeleted = True
        disp.ExitLoop()

    if show_button:
        dlg.GetItems()["Confirmed"].Visible = True

    dlg.On.InfoDialog.Close = close
    dlg.On.Canceled.Clicked = close
    dlg.On.Confirmed.Clicked = confirmClicked
    dlg.Show()
    disp.RunLoop()
    dlg.Hide()


# ==============================================================================================


def getNode(tool_name):
    return comp.FindTool(tool_name)


def getFilePath(tool):
    tool_id = tool.ID
    if tool_id == "Loader":
        return tool.GetAttrs()["TOOLST_Clip_Name"][1]
    elif tool_id == "FileLUT":
        return tool.GetInput("LUTFile")
    elif tool_id == "SurfaceAlembicMesh":
        return tool.GetInput("Filename")
    elif tool_id == "FBXMesh3D":
        return tool.GetInput("ImportFile")


def refreshAllClicked(ev):
    refreshAssetsClicked(0)
    refreshInvalidClicked(0)
    refreshFusesClicked(0)


# =====================================================================================

def refreshFusionPreview(TreeItem=None, Node=None):
    current_node = None
    if TreeItem and TreeItem.Parent():
        current_node = comp.FindTool(TreeItem.GetText(1))
    elif Node:
        current_node = Node
    if itm["ShowInPreviewWin"].Checked and current_node:
        comp.CurrentFrame.ViewOn(current_node, int(itm["WindowNum"].Value))


def showInPreviewWinClicked(ev):
    itm["WindowNum"].SetEnabled(ev["On"])
    refreshFusionPreview(itm["AssetsTree"].CurrentItem())


# =====================================================================================


def changeColor(key, color=None):
    tools = comp.GetToolList(True)
    for tool in tools.values():
        tool[key] = color


def changBgColorClicked(ev):
    changeColor("TileColor", itm["UserColor"].Color)


def resetBgColorClicked(ev):
    changeColor("TileColor")


# =====================================================================================


def refreshInvalidClicked(ev):
    itm["NodeTree"].Clear()
    getInvalidNodes()
    if ev != 0 and itm["NodeTree"].TopLevelItemCount() == 0:
        showWarningDialog("Prompt：", "No invalid nodes", False)


def nodeTreeIndexChangedEvent(ev):
    try:
        current_node = getNode(ev["item"].Text[1])
    except AttributeError:
        return
    refreshFusionPreview(Node=current_node)
    if current_node:
        while current_node.ParentTool:
            current_node = current_node.ParentTool
    comp.SetActiveTool(current_node)


def generateNodeTreeHeaders():
    global itm
    itm["NodeTree"].ColumnCount = 2
    itm["NodeTree"].ColumnWidth[0] = 100
    itm["NodeTree"].ColumnWidth[1] = 200
    itm["NodeTree"].SetHeaderLabels({1: "Node Type", 2: "Node Name"})


def nodeTreeDoubleClickEvent(ev):
    global isDeleted
    showWarningDialog("Prompt: Delete node", "Are you sure delete this node?", True)
    if isDeleted:
        isDeleted = False
        current_node = getNode(ev["item"].Text[1])
        if not current_node:
            return
        nid = current_node.ID
        current_node.Delete()

        row = itm["NodeTree"].IndexOfTopLevelItem(ev["item"])
        itm["NodeTree"].TakeTopLevelItem(row)
        if nid in (
                "Loader",
                "SurfaceFBXMesh",
                "SurfaceAlembicMesh",
                "FileLUT",
                "GroupOperator",
        ):
            getNodesInfo()


def isInvalidNode(tool):
    if tool.GetAttrs()["TOOLB_PassThrough"]:
        return True
    if tool.ID == "Saver":
        if tool.Input.GetConnectedOutput():
            return False
        else:
            return True
    if tool.ID in ("BezierSpline", "PolyPath", "Underlay", "Note"):
        return False

    i = 1
    outputs = []
    while True:
        out = tool.FindMainOutput(i)
        if out:
            i += 1
            outputs.append(out)
        else:
            break

    for out in outputs:
        if out.GetConnectedInputs():
            return False

    return True


def getInvalidNodes():
    global itm
    node_list = comp.GetToolList()
    for tool in node_list.values():
        if tool.ParentTool:
            continue
        elif isInvalidNode(tool):
            new_item = itm["NodeTree"].NewItem()
            new_item.Text[0] = tool.ID
            new_item.Text[1] = tool.Name
            itm["NodeTree"].AddTopLevelItem(new_item)


def deleteAllClicked(ev):
    global isDeleted
    showWarningDialog(
        "Prompt: Delete node", "Are you sure delete all invalid nodes?", True
    )
    if isDeleted:
        isDeleted = False
        comp.SaveCopyAs()
        comp.CurrentFrame.ViewOn(None)
        comp.Lock()
        flag = True
        while flag:
            flag = False
            node_list = comp.GetToolList()
            for tool in node_list.values():
                if tool.ParentTool:
                    continue
                elif isInvalidNode(tool):
                    flag = True
                    tool.Delete()

        itm["NodeTree"].Clear()
        refreshAssetsClicked(0)
        refreshFusesClicked(0)
        comp.Unlock()
        showWarningDialog("Prompt", "Invalid nodes has been deleted", False)


# ======================================================================================


def generateFuseTreeHeaders():
    global itm
    itm["FuseTree"].ColumnCount = 2
    itm["FuseTree"].ColumnWidth[0] = 130
    itm["FuseTree"].ColumnWidth[1] = 20
    itm["FuseTree"].SetHeaderLabels(
        {1: "Fuse Reg Name", 2: "Times Used"}
    )


def getThirdFuses():
    global itm
    nodeList = comp.GetToolList()
    dic_fusesCount = {}
    fuses_list = []

    internal = {
        "SetMetaData",
        "LUTCubeCreator",
        "SetMetaDataTC",
        "ExternalMatteSaver",
        "FrameAverage",
        "Duplicate",
        "LUTCubeApply",
        "LUTCubeAnalyzer",
        "Wireless",
        "OCLRays",
        "FLS_CopyMetadata",
    }
    for tool in nodeList.values():
        tool_id = tool.ID
        if tool_id.startswith("Fuse.") and tool_id[5:] not in internal:
            if dic_fusesCount.get(tool_id):
                dic_fusesCount[tool_id] += 1
            else:
                dic_fusesCount[tool_id] = 1
                fuses_list.append(tool)

    return fuses_list, dic_fusesCount


def refreshFusesClicked(ev):
    global itm
    itm["FuseTree"].Clear()
    fuses_list, dic_fusesCount = getThirdFuses()
    for fuse in fuses_list:
        id = fuse.ID
        newItem = itm["FuseTree"].NewItem()
        # newItem.Text[0] = id
        newItem.Text[0] = fu.GetRegAttrs(id)["REGS_Name"]
        newItem.Text[1] = str(dic_fusesCount[id])
        itm["FuseTree"].AddTopLevelItem(newItem)


# ========================================================================================
def refreshAssetsClicked(ev):
    getNodesInfo()


def assetsDoubleClickEvent(ev):
    if not ev["item"].Parent():
        return
    if platform.system() == "Windows":
        file_path = comp.MapPath(getFilePath(getNode(ev["item"].Text[1])))
        file_path = file_path.replace("/", "\\").replace("\\\\", "\\")
        if os.path.exists(file_path):
            subprocess.run(["explorer.exe", "/select,", file_path])
        else:
            showWarningDialog(
                "Prompt: File open failed", "Invalid path or file does not exist!", False
            )


def assetsIndexChangedEvent(ev):
    current_item = None
    if "item" in ev:
        current_item = ev["item"]
    try:
        current_node = getNode(current_item.Text[1])
    except AttributeError:
        return
    if current_node:
        while current_node.ParentTool:
            current_node = current_node.ParentTool
        comp.SetActiveTool(current_node)
        refreshFusionPreview(current_item)


def generateTableStructure():
    global itm
    itm["AssetsTree"].ColumnCount = 6
    itm["AssetsTree"].ColumnWidth[0] = 130
    itm["AssetsTree"].ColumnWidth[1] = 100
    itm["AssetsTree"].ColumnWidth[2] = 470
    itm["AssetsTree"].ColumnWidth[3] = 60
    itm["AssetsTree"].ColumnWidth[4] = 60
    itm["AssetsTree"].ColumnWidth[5] = 30

    newItem = itm["AssetsTree"].NewItem()
    newItem.Text[0] = "Node Type"
    newItem.Text[1] = "Name / Amount"
    newItem.Text[2] = "File Path"
    newItem.Text[3] = "Trim"
    newItem.Text[4] = "Frames"
    newItem.Text[5] = "Asset Status"
    itm["AssetsTree"].SetHeaderItem(newItem)


def getAssetsNodes():
    node_list = []
    comp = fu.GetCurrentComp()
    for node in comp.GetToolList(False).values():
        if node.ID in ["Loader", "FileLUT", "SurfaceAlembicMesh", "SurfaceFBXMesh"]:
            node_list.append(node)
    return node_list


def treeItemExpanded(item, is_expanded=None):
    if not is_expanded:
        return
    category_item = category_dict[item]
    category_item["TreeItem"].SetExpanded(category_item["Expanded"])


def getFullPath():
    if itm["ShowFullPath"].Checked:
        return lambda a: a
    else:
        return lambda a: os.path.basename(a)


def getNodesInfo(is_expanded=True):
    global itm
    global category_dict

    if category_dict["Video"]["TreeItem"]:
        for key in category_dict:
            category_dict[key]["Expanded"] = category_dict[key][
                "TreeItem"
            ].GetExpanded()

    # for item in itm["AssetsTree"].SelectedItems().values():
    #     print(itm["AssetsTree"].GetTreePosition(item))

    itm["AssetsTree"].Clear()
    childItem_list.clear()
    get_path = getFullPath()
    node_list = getAssetsNodes()
    video_count = pic_count = sound_count = mx_count = lutfile_count = 0

    for key in category_dict:
        tree_item = itm["AssetsTree"].NewItem()
        tree_item.Text[0] = category_dict[key]["Title"]
        itm["AssetsTree"].AddTopLevelItem(tree_item)
        category_dict[key]["TreeItem"] = tree_item

    video = category_dict["Video"]["TreeItem"]
    image = category_dict["Image"]["TreeItem"]
    model = category_dict["Model"]["TreeItem"]
    audio = category_dict["Audio"]["TreeItem"]
    lut = category_dict["LUT"]["TreeItem"]

    for tool in node_list:
        new_item = itm["AssetsTree"].NewItem()
        new_item.Text[1] = tool.Name
        new_item.Text[3] = "N/A"
        new_item.Text[4] = "N/A"
        childItem_list.append(new_item)
        cur_file_path = ""

        if tool.ID == "Loader":
            node_attr = tool.GetAttrs()
            new_item.Text[0] = "Loader"
            if node_attr["TOOLST_Clip_Name"]:
                cur_file_path = node_attr["TOOLST_Clip_Name"][1]
                new_item.Text[2] = get_path(cur_file_path)
                start_frame = tool.ClipTimeStart[1]
                end_frame = tool.ClipTimeEnd[1]
                total_frames = node_attr["TOOLIT_Clip_Length"][1]
                new_item.Text[3] = "[%d-%d]" % (start_frame, end_frame)
                new_item.Text[4] = str(int(total_frames))
                if (
                        new_item.Text[2]
                                .lower()
                                .endswith(("mp4", "mov", "avi", "mkv", "mpg", "mpeg", "wmv"))
                ):
                    video.AddChild(new_item)
                    video_count += 1
                    treeItemExpanded("Video", is_expanded)
                elif (
                        new_item.Text[2]
                                .lower()
                                .endswith(("mp3", "aac", "wav", "wma", "ape", "flac", "ogg"))
                ):
                    audio.AddChild(new_item)
                    sound_count += 1
                    treeItemExpanded("Audio", is_expanded)
                else:
                    image.AddChild(new_item)
                    pic_count += 1
            else:
                image.AddChild(new_item)
                pic_count += 1
            treeItemExpanded("Image", is_expanded)

        elif tool.ID == "FileLUT":
            new_item.Text[0] = "FileLUT"
            cur_file_path = tool.GetInput("LUTFile")
            new_item.Text[2] = get_path(cur_file_path)
            lut.AddChild(new_item)
            lutfile_count += 1
            treeItemExpanded("LUT", is_expanded)

        elif tool.ID == "SurfaceAlembicMesh":
            new_item.Text[0] = "AlembicMesh3D"
            cur_file_path = tool.GetInput("Filename")
            new_item.Text[2] = get_path(cur_file_path)
            model.AddChild(new_item)
            mx_count += 1
            treeItemExpanded("Model", is_expanded)

        elif tool.ID == "SurfaceFBXMesh":
            new_item.Text[0] = "FBXMesh3D"
            cur_file_path = tool.GetInput("ImportFile")
            new_item.Text[2] = get_path(cur_file_path)
            model.AddChild(new_item)
            mx_count += 1
            treeItemExpanded("Model", is_expanded)

        if new_item.Text[2]:
            if not os.path.exists(comp.MapPath(cur_file_path)):
                new_item.Text[5] = "Lost"
                new_item.Text[4] = ""
                new_item.Text[3] = ""
            else:
                new_item.Text[5] = "Ok"
        audio.Text[1] = str(sound_count)
        image.Text[1] = str(pic_count)
        video.Text[1] = str(video_count)
        model.Text[1] = str(mx_count)
        lut.Text[1] = str(lutfile_count)


def changeShowFullPath(ev):
    if ev["On"]:
        for item in childItem_list:
            item.Text[2] = getFilePath(getNode(item.Text[1]))
    else:
        for item in childItem_list:
            item.Text[2] = os.path.basename(item.Text[2])


# ===================================================================================


def lockAndUnlock(isLock):
    node_list = comp.GetToolList()
    for tool in node_list.values():
        tool.SetAttrs({"TOOLB_Locked": isLock})


# ====================================================================================


def replaceAssetsClicked(ev):
    if itm["ShowFullPath"].Checked:
        set_filepath = lambda a: a
    else:
        set_filepath = lambda a: os.path.basename(a)

    selected_items = itm["AssetsTree"].SelectedItems()
    if not selected_items:
        showWarningDialog(
            "Prompt", "Please select a asset node in the Asset List first.", False
        )
        return

    file = fu.RequestFile()
    if not file:
        return
    comp.Lock()
    flag = False
    for item in selected_items.values():
        if not item.Parent():
            continue
        tool = getNode(item.Text[1])
        if tool:
            if tool.ID == "Loader":
                global_in = tool.GlobalIn[0]
                global_out = tool.GlobalOut[0]
                trim_in = tool.ClipTimeStart[0]
                trim_out = tool.ClipTimeEnd[0]
                tool.Clip = file
                tool.GlobalIn[0] = global_in
                tool.GlobalOut[0] = global_out
                tool.ClipTimeStart[0] = trim_in
                tool.ClipTimeEnd[0] = trim_out
            elif tool.ID == "SurfaceAlembicMesh":
                tool.Filename = file
            elif tool.ID == "FileLUT":
                tool.LUTFile = file
            else:
                tool.ImportFile = file

            item.Text[2] = set_filepath(file)
            item.Text[4] = "Ok"
            flag = True

    if not flag:
        showWarningDialog(
            "Invalid asset node: ",
            "Please select at least one valid asset in the Asset List.",
            False,
        )

    comp.Unlock()

# CONVERT ABSOLUTE TO RELATIVE PATH
# ========================================================================


def verifyAndConvertToRelative(originPath, parentPath):
    if not originPath:
        return False
    if originPath.startswith(parentPath):
        return originPath.replace(parentPath, "Comp:")
    return False


def convertToRelativeClicked(ev):
    comp_path = comp.GetAttrs()["COMPS_FileName"]
    if not comp_path:
        showWarningDialog("Prompt", "Please save the composition first!", False)
        return

    comp_dir = os.path.dirname(comp_path)
    node_list = getAssetsNodes()
    flag = False
    comp.Lock()
    for tool in node_list:
        if tool.ID == "Loader" and tool.GetAttrs()["TOOLST_Clip_Name"]:
            key = "Clip"
        elif tool.ID == "FileLUT":
            key = "LUTFile"
        elif tool.ID == "SurfaceAlembicMesh":
            key = "Filename"
        else:
            key = "ImportFile"

        path = verifyAndConvertToRelative(tool.GetInput(key), comp_dir)

        if path:
            tool[key] = path
            flag = True

    if flag:
        getNodesInfo()
    comp.Unlock()
    # showWarningDialog("Prompt", "Asset path change completed", False)


# ====================================================================================


def linkAssetsClicked(ev):

    folder = fu.RequestDir()
    if not folder:
        showWarningDialog("Prompt", "No valid path selected", False)
        return
    folder = folder[:-1]
    files = {}
    for dirpath, _, filenames in os.walk(folder):
        for f in filenames:
            files[f] = dirpath
    comp.Lock()
    node_list = getAssetsNodes()
    flag = False
    count = 0
    for tool in node_list:
        if tool.ID == "Loader":
            if tool.GetAttrs()["TOOLST_Clip_Name"]:
                key = "Clip"
            else:
                continue
        elif tool.ID == "FileLUT":
            key = "LUTFile"
        elif tool.ID == "SurfaceAlembicMesh":
            key = "Filename"
        else:
            key = "ImportFile"

        if key == "Clip":
            file_path = tool.GetAttrs()["TOOLST_Clip_Name"][1]
        else:
            file_path = tool.GetInput(key)
        file_path = comp.MapPath(file_path)
        base_filename = os.path.basename(file_path)
        f, ext = os.path.splitext(base_filename)
        if not os.path.exists(file_path):
            if ext.lower() in [".exr", ".tga", ".png", ".tiff", ".dpx", ".jpg"]:
                seq = re.compile(r"(\d{3,})$")
                target_file = re.sub(seq, '', f)
                for file, parent_dir in files.items():
                    if file.startswith(target_file):
                        tool[key] = os.path.join(parent_dir, file)
                        print(f"image sequence found in [{parent_dir}]")
                        flag = True
                        count += 1
                        break
            else:
                name = os.path.basename(file_path)
                check = files.get(name)
                if check:
                    tool[key] = os.path.join(check, name)
                    count += 1
                    flag = True
    if flag:
        getNodesInfo()
    comp.Unlock()
    showWarningDialog("Prompt", f"{count} files relinked", False)


# ========================================================================


def firstKeyFrameClicked(ev):
    tool = comp.ActiveTool or comp.GetToolList(True)[1]
    if not tool:
        showWarningDialog("Prompt", "Please activate a node first", False)
        return
    inputs = tool.GetInputList().values()
    min_key = 99999999
    for inp in inputs:
        keys = inp.GetKeyFrames()
        if keys and inp.GetConnectedOutput().GetTool().ID in (
                "BezierSpline",
                "PolyPath",
        ):
            if keys[1] != -1000000000:
                if keys[1] < min_key:
                    min_key = keys[1]
            elif keys[2] < min_key:
                min_key = keys[2]

    if min_key == 99999999:
        comp.CurrentTime = comp.GetAttrs()["COMPN_RenderStart"]
    else:
        comp.CurrentTime = min_key


def lastKeyFrameClicked(ev):
    tool = comp.ActiveTool or comp.GetToolList(True)[1]
    if not tool:
        showWarningDialog("Prompt", "Please activate a node first", False)
        return
    inputs = tool.GetInputList().values()
    max_key = -99999
    for inp in inputs:
        keys = inp.GetKeyFrames()
        if keys and inp.GetConnectedOutput().GetTool().ID in (
                "BezierSpline",
                "PolyPath",
        ):
            if keys[len(keys)] > max_key:
                max_key = keys[len(keys)]
    if max_key == -99999:
        comp.CurrentTime = comp.GetAttrs()["COMPN_RenderEnd"]
    else:
        comp.CurrentTime = max_key


# ==============================================================================================
def detectImageSequence(tool):
    import glob
    attrs = tool.GetAttrs()
    if attrs["TOOLIT_Clip_Length"][1] > 1:
        file_path = comp.MapPath(attrs["TOOLST_Clip_Name"][1])
        (name, ext) = os.path.splitext(file_path)
        i = 0
        while name[-1].isdigit():
            name = name[:-1]
            i += 1
        if i == 0:
            return None
        images = glob.glob(f'{name}{"[0-9]" * i}{ext}')
        images.sort()
        return images[-1]


def exportAssetListClicked(ev):
    comp_path = comp.GetAttrs()["COMPS_FileName"]
    if not comp_path:
        showWarningDialog("Prompt", "Please save the composition first!", False)
        return
    txt_file = os.path.splitext(comp_path)[0] + "_AssetsList.txt"
    nodes = {}
    for k in ["Video", "Audio", "Image", "LUT", "ABC", "FBX"]:
        nodes[k] = set()

    node_list = getAssetsNodes()
    for tool in node_list:
        if tool.ID == "Loader":
            node_attr = tool.GetAttrs()
            if node_attr["TOOLST_Clip_Name"]:
                file_path = comp.MapPath(node_attr["TOOLST_Clip_Name"][1])
                if file_path.lower().endswith(
                        ("mp4", "mov", "avi", "mkv", "mpg", "mpeg", "wmv", "mxf")
                ):
                    nodes["Video"].add(file_path)
                elif file_path.lower().endswith(
                        ("mp3", "aac", "wav", "wma", "ape", "flac", "ogg")
                ):
                    nodes["Audio"].add(file_path)
                else:
                    images = detectImageSequence(tool)
                    if images:
                        nodes["Image"].add((file_path, images))
                    else:
                        nodes["Image"].add(file_path)

        elif tool.ID == "FileLUT":
            if tool.GetInput("LUTFile"):
                nodes["LUT"].add(comp.MapPath(tool.GetInput("LUTFile")))
        elif tool.ID == "SurfaceAlembicMesh":
            if tool.GetInput("Filename"):
                nodes["ABC"].add(comp.MapPath(tool.GetInput("Filename")))
        else:  # tool.ID == "SurfaceFBXMesh"
            if tool.GetInput("ImportFile"):
                nodes["FBX"].add(comp.MapPath(tool.GetInput("ImportFile")))

    total = 0
    missing = 0
    lines = ["", ""]
    with open(txt_file, "w", encoding="utf-8") as txt:
        for key in nodes:
            if nodes[key]:
                tmp = []
                total += len(nodes[key])
                lines.append(f"{len(nodes[key])} assets of type {key}:\n")
                for file in nodes[key]:
                    prefix = ""
                    last = ""
                    if isinstance(file, tuple):
                        last = f'{"-" * 7}{os.path.basename(file[1])}'
                        file = file[0]

                    if not os.path.exists(file):
                        prefix = "[Lost]"
                        missing += 1
                    tmp.append(f"{prefix}{os.path.basename(file)}{last}\n")

                tmp.sort()
                lines.extend(tmp)
                lines.append(f'\n{"*" * 77}\n\n')

        lines[0] = f"{total} assets used in total, {missing} assets have been lost\n"
        lines[1] = f'{"*" * 77}\n\n'
        fuses_list, _ = getThirdFuses()

        if len(fuses_list) > 0:
            lines.append(f"{len(fuses_list)} third-party fuses used in total:\n")

        tmp = []
        for fuse in fuses_list:
            tmp.append(f'{fu.GetRegAttrs(fuse.ID)["REGS_Name"]}\n')

        tmp.sort()
        lines.extend(tmp)
        txt.writelines(lines)
        showWarningDialog("Prompt", "Exported Assets List is complete.", False)


# ======================================================================================
def main():
    win.On.AssetsManager.Close = windowClose
    win.On.AssetsTree.ItemDoubleClicked = assetsDoubleClickEvent
    win.On.AssetsTree.CurrentItemChanged = assetsIndexChangedEvent
    win.On.NodeTree.ItemDoubleClicked = nodeTreeDoubleClickEvent
    win.On.NodeTree.CurrentItemChanged = nodeTreeIndexChangedEvent
    win.On.ChangBgColor.Clicked = changBgColorClicked
    win.On.ResetBgColor.Clicked = resetBgColorClicked
    win.On.ReplaceAssets.Clicked = replaceAssetsClicked
    win.On.ConvertToRelative.Clicked = convertToRelativeClicked
    win.On.DeleteAll.Clicked = deleteAllClicked
    win.On.RefreshAll.Clicked = refreshAllClicked
    win.On.RefreshAssets.Clicked = refreshAssetsClicked
    win.On.RefreshInvalid.Clicked = refreshInvalidClicked
    win.On.RefreshFuses.Clicked = refreshFusesClicked
    win.On.LinkAssets.Clicked = linkAssetsClicked
    win.On.FirstKeyFrame.Clicked = firstKeyFrameClicked
    win.On.LastKeyFrame.Clicked = lastKeyFrameClicked
    win.On.ShowFullPath.Clicked = changeShowFullPath
    win.On.ShowInPreviewWin.Clicked = showInPreviewWinClicked
    win.On.ExportAssetList.Clicked = exportAssetListClicked

    generateTableStructure()
    generateNodeTreeHeaders()
    generateFuseTreeHeaders()
    refreshAssetsClicked(0)
    refreshFusesClicked(0)
    win.Show()
    disp.RunLoop()
    win.Hide()


ui = fu.UIManager
disp = bmd.UIDispatcher(ui)
win = disp.AddWindow(
    {
        "ID": "AssetsManager",
        "WindowTitle": f"Assets Manager {VERSION}",
        "Geometry": [600, 500, 1000, 600],
        "Spacing": 0,
    },
    [
        ui.HGroup(
            {"Spacing": 3},
            [
                ui.VGroup(
                    {"Spacing": 7, "Weight": 0.7,},
                    [
                        ui.VGroup(
                            {"Spacing": 7, "Weight": 0.3,},
                            [
                                ui.HGroup(
                                    {"Spacing": 11, "Weight": 0,},
                                    [
                                        ui.Label(
                                            {
                                                "Text": "Assets List",
                                            }
                                        ),
                                        ui.SpinBox(
                                            {
                                                "ID": "WindowNum",
                                                "Value": 1,
                                                "Maximum": 99,
                                                "Minimum": 1,
                                                "Weight": 0,
                                                "Enabled": False,
                                            }
                                        ),
                                        ui.CheckBox(
                                            {
                                                "ID": "ShowInPreviewWin",
                                                "Text": "Preview in specified window",
                                                "Checked": False,
                                                "Weight": 0,
                                            }
                                        ),
                                        ui.CheckBox(
                                            {
                                                "ID": "ShowFullPath",
                                                "Text": "Show Full Path",
                                                "Checked": True,
                                                "Weight": 0,
                                            }
                                        ),
                                        ui.Label({"Text": "    ", "Weight": 0}),
                                        ui.Button(
                                            {
                                                "Text": "Refresh Assets List",
                                                "ID": "RefreshAssets",
                                                "Weight": 0,
                                            }
                                        ),
                                        ui.Button(
                                            {
                                                "Text": "Refresh All",
                                                "ID": "RefreshAll",
                                                "Weight": 0,
                                            }
                                        ),
                                        ui.Button(
                                            {
                                                "Text": "Export Assets List",
                                                "ID": "ExportAssetList",
                                                "Weight": 0,
                                            }
                                        ),
                                    ],
                                ),
                                ui.Tree(
                                    {
                                        "ID": "AssetsTree",
                                        "Weight": 0.5,
                                        "Spacing": 0,
                                        "SelectionMode": "ExtendedSelection",
                                        "SortingEnabled": True,
                                        "Events": {
                                            "ItemDoubleClicked": True,
                                            "CurrentItemChanged": True,
                                        },
                                    }
                                ),
                                ui.VGap(1),
                            ],
                        ),
                        ui.HGroup(
                            {"Spacing": 12, "Weight": 0.16,},
                            [
                                ui.VGroup(
                                    {"Spacing": 7, "Weight": 1,},
                                    [
                                        ui.HGroup(
                                            {"Spacing": 11, "Weight": 0,},
                                            [
                                                ui.Label(
                                                    {
                                                        "Text": "Invalid Nodes List",
                                                    }
                                                ),
                                                ui.Button(
                                                    {
                                                        "Text": "Refresh Nodes List",
                                                        "ID": "RefreshInvalid",
                                                        "Weight": 0,
                                                    }
                                                ),
                                            ],
                                        ),
                                        ui.Tree(
                                            {
                                                "ID": "NodeTree",
                                                "Weight": 0.25,
                                                "Spacing": 0,
                                                "SortingEnabled": True,
                                                "Events": {
                                                    "ItemDoubleClicked": True,
                                                    "CurrentItemChanged": True,
                                                },
                                            }
                                        ),
                                        ui.VGap(1),
                                    ],
                                ),
                                ui.VGroup(
                                    {"Spacing": 7, "Weight": 1,},
                                    [
                                        ui.HGroup(
                                            {"Spacing": 11, "Weight": 0,},
                                            [
                                                ui.Label(
                                                    {
                                                        "Text": (
                                                            "Third-party Fuses List"
                                                        ),
                                                        "Weight": 1,
                                                    }
                                                ),
                                                ui.Button(
                                                    {
                                                        "Text": "Refresh Fuses List",
                                                        "ID": "RefreshFuses",
                                                        "Weight": 0,
                                                    }
                                                ),
                                            ],
                                        ),
                                        ui.Tree(
                                            {
                                                "ID": "FuseTree",
                                                "Weight": 0.25,
                                                "Spacing": 0,
                                                "SortingEnabled": True,
                                                "Events": {
                                                    "ItemDoubleClicked": True,
                                                    "CurrentItemChanged": True,
                                                },
                                            }
                                        ),
                                        ui.VGap(1),
                                    ],
                                ),

                                ui.VGroup(
                                    {"Spacing": 7, "Weight": 1,},
                                    [
                                        ui.HGroup(
                                            {"Spacing": 7, "Weight": 0,},
                                            [
                                                ui.Button(
                                                    {
                                                        "Text": "Link missing assets",
                                                        "ID": "LinkAssets",
                                                    }
                                                ),
                                            ],
                                        ),
                                        ui.HGroup(
                                            {"Spacing": 11, "Weight": 0,},
                                            [],
                                        ),

                                        ui.HGroup(
                                            {"Spacing": 11, "Weight": 0,},
                                            [
                                                ui.Button(
                                                    {
                                                        "Text": "Delete all invalid nodes",
                                                        "ID": "DeleteAll",
                                                    }
                                                ),
                                                ui.Button(
                                                    {
                                                        "Text": "Replace Assets",
                                                        "ID": "ReplaceAssets",
                                                    }
                                                ),
                                            ],
                                        ),
                                        ui.HGroup(
                                            {"Spacing": 11, "Weight": 0,},
                                            [
                                                ui.Button(
                                                    {
                                                        "Text": "To the starting keyframe",
                                                        "ID": "FirstKeyFrame",
                                                    }
                                                ),
                                                ui.Button(
                                                    {
                                                        "Text": "To the end keyframe",
                                                        "ID": "LastKeyFrame",
                                                    }
                                                ),
                                            ],
                                        ),
                                        # ui.Button(
                                        #     {
                                        #         "Weight": 0,
                                        #         "Text": "Absolute path changed to Relative path",
                                        #         "ID": "ConvertToRelative",
                                        #         "Visible": False,
                                        #     }
                                        # ),
                                        ui.ColorPicker(
                                            {
                                                "ID": "UserColor",
                                                "Text": "Node color",
                                                "Weight": 0,
                                            }
                                        ),
                                        ui.HGroup(
                                            {"Spacing": 11, "Weight": 0,},
                                            [
                                                ui.Button(
                                                    {
                                                        "Text": "Change node BG color",
                                                        "ID": "ChangBgColor",
                                                    }
                                                ),
                                                ui.Button(
                                                    {
                                                        "Text": "Default node BG color",
                                                        "ID": "ResetBgColor",
                                                    }
                                                ),
                                            ],
                                        ),
                                        ui.VGap(1),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )
    ],
)

itm = win.GetItems()
main()
