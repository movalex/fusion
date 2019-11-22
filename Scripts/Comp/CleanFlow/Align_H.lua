-- The script to align nodes vertically
-- Based on original script by DC Turner StackSelectedTools.lua
-- Change List:
-- code refactoring
-- floor node positioning check
-- added Fu16 compatibility by Alex Bogomolov (mail@abogomolov.com)
-- configuration file to launch the script with ALT+H
--
-- Known issue: if the Node is set to Arrange to grid, and Y pos is less then 0, aligned position will shift to 1 on Y axis


flow = comp.CurrentFrame.FlowView

comp:StartUndo("Align Tools Horizontally")
selected_tools = comp:GetToolList(true)
active_tool = comp.ActiveTool

if not active_tool then
	active_tool = selected_tools[1]
end

active_X, active_Y = flow:GetPos(active_tool)
-- print(active_X.." - ".. active_Y)

if fu.Version >= 16 then
    active_Y = math.floor(active_Y)
    flow:SetPos(active_tool, active_X, active_Y)
end

for num, tool in pairs(selected_tools) do
	TEMP_X, _TEMP_Y = flow:GetPos(tool)
	if tool ~= active_tool then
		-- check if nodes have the same X value
		-- floor the values for switching between horiz and vertical allignment
		if math.floor(TEMP_X) == math.floor(active_X) then
			newpos = TEMP_X + (num - 1)
		else
			newpos = TEMP_X
		end
		flow:SetPos(tool, newpos, active_Y)
	end
end
comp:EndUndo()
