--[[
tool script to get tool's ID. Useful if you do expressions
or use a Reactor 'Slash For' script a lot
and you don't want to keep in memory, that Resize tool is actually a 'BetterResize',
and MaskPaint is actually a 'PaintMask'.
Tool ID will be copied to the clipboard, and printed in the console
]]--
tool_name = tool.ID
bmd.setclipboard(tool_name)
print(tool_name)
