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
"""

VERSION = "1.0"
MESSAGE = "Update Tiles script v" + VERSION
comp = fu.GetCurrentComp()

print("{}\n{}".format(MESSAGE, "-" * len(MESSAGE)))

# Tool types to be updated
TOOL_IDS = ["Loader", "TextPlus", "Background"]

tools = comp.GetToolList(False)

count = 0
for tool in tools.values():
    if tool.ID in TOOL_IDS:
        output = tool.FindMainOutput(1)
        if output and not tool.GetAttrs()["TOOLB_PathThrough"]:
            print("Updating {} tile".format(tool.Name))
            tool.SetAttrs({"TOOLB_PassThrough": True})
            tool.SetAttrs({"TOOLB_PassThrough": False})
            output.GetValue()
            count = count + 1

if count == 0:
    print("No tools updated.")

print("-"*len(MESSAGE), "\n")

