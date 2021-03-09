"""
Update tiles script
Run the script to update or show tiles on all supported tools: 
    Loader
    Text+
    Background
Based on pvxUpdateTilePictures.lua script
author: Alexey Bogomolov, mail@abogomolov.com
version: 1.0, 01.29.2021
donate: https://paypal.me/aabogomolov/3usd
Requirements: Python

v 1.0 (01.29.2021):
    - initial release
v 1.1 (08.02.2021):
    - temporarily set current time to GlobalIn for Loaders 
    - update all or only selected tools
    - skip disabled tools
"""

import time


VERSION = "1.1"
MESSAGE = "\nUpdate Tiles script v" + VERSION
# Tool types to be updated
TOOL_IDS = ["Loader", "TextPlus", "Background", "MediaIn", "Saver"]

comp = fu.GetCurrentComp()
print("{}\n{}".format(MESSAGE, "-" * len(MESSAGE)))

tools = comp.GetToolList(True)
if not tools:
    tools = comp.GetToolList(False)


def move_playhead(loader):
    if comp.CurrentTime < loader.GlobalIn[1] or comp.CurrentTime > loader.GlobalOut[1]:
        comp.CurrentTime = loader.GlobalIn[1]


def main(tools=None):
    if not tools:
        print("no tools to update")
        return
    time = comp.CurrentTime
    count = 0
    for tool in tools.values():
        if tool.ID in TOOL_IDS:
            output = tool.FindMainOutput(1)
            if output and not tool.GetAttrs(["TOOLB_PathThrough"]):
                print("Updating tile: {}".format(tool.Name))
                if tool.ID == "Loader":
                    move_playhead(tool)
                output.GetValue()
                count = count + 1
    comp.CurrentTime = time
    if count == 0:
        print("No tools updated.")


if __name__ == "__main__":
    main(tools)
    print("-" * len(MESSAGE))
