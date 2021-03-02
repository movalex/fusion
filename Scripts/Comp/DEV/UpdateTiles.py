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
comp = fu.GetCurrentComp()
print("{}\n{}".format(MESSAGE, "-" * len(MESSAGE)))

# Tool types to be updated
TOOL_IDS = ["Loader", "TextPlus", "Background"]

tools = comp.GetToolList(True)

if not tools:
    tools = comp.GetToolList(False)

time = comp.CurrentTime
count = 0

for tool in tools.values():
    if tool.ID in TOOL_IDS:
        output = tool.FindMainOutput(1)
        if output and not tool.GetAttrs(["TOOLB_PathThrough"]):
            print("Updating {} tile".format(tool.Name))
            if tool.ID == "Loader":
                comp.CurrentTime = tool.GlobalIn[1]
            output.GetValue()
            count = count + 1

comp.CurrentTime = time
if count == 0:
    print("No tools updated.")

print("-"*len(MESSAGE))

