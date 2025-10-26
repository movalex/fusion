"""
Update tiles script
Run the script to update or show tiles on all supported tools: 
    Loader
    Text+
    Background
Based on pvxUpdateTilePictures.lua script
author: Alexey Bogomolov, mail@abogomolov.com
version: 1.0, 01.29.2021

Requirements: Python

v 1.0 (01.29.2021):
    - initial release
v 1.1 (08.02.2021):
    - temporarily set current time to GlobalIn for Loaders 
    - update all or only selected tools
    - skip disabled tools

Copyright © 2022 Alexey Bogomolov

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
