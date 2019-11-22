-- The script to align nodes vertically
-- Based on original script by DC Turner LineSelectedTools.lua
-- Change List by Alex Bogomolov (mail@abogomolov.com):
--  code refactoring
--  floor node positioning check
--  added Fu16 compatibility 
--  configuration file to launch the script with ALT+V
--
-- Known issue: if the Node is set to Arrange to grid, and Y pos is less then 0, aligned position will shift to 1 on Y axis


flow = comp.CurrentFrame.FlowView

comp:StartUndo("Align Tools Vertically")
selected_tools = comp:GetToolList(true)
active_tool = comp.ActiveTool

if active_tool == nil then
    active_tool = selected_tools[1]
end

active_X, active_Y = flow:GetPos(active_tool)
-- print(active_X.." - ".. active_Y)

if fu.Version >= 16 then
    active_Y = math.floor(active_Y)
    flow:SetPos(active_tool, active_X, active_Y)
end

for num, tool in pairs(selected_tools) do
    _TEMP_X, TEMP_Y = flow:GetPos(tool)
    if tool ~= active_tool then
        -- check if nodes have the same Y value
        -- floor the values for switching between horiz and vertical allignment
        if math.floor(TEMP_Y) == math.floor(active_Y) then 
            newpos = TEMP_Y + (num-1)
        else
            newpos = TEMP_Y
        end
        flow:SetPos(tool, active_X, newpos)
    end
end
comp:EndUndo()
